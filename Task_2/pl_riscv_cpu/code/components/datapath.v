module datapath (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output [2:0]  funct3,
    output reg [31:0] PCW, ALUResultW, WriteDataW
);

// ============================================================
// FETCH STAGE
// ============================================================
wire [31:0] PCPlus4F;
wire [31:0] PCNext;
wire [31:0] InstrD, PCD, PCPlus4D;

assign PCPlus4F = PC + 32'd4;

// ============================================================
// DECODE STAGE
// ============================================================
wire [1:0] ResultSrcD, ImmSrcD;
wire MemWriteD, ALUSrcD, RegWriteD;
wire BranchD, JumpD, JalrD;
wire [3:0] ALUControlD;

controller c (
    InstrD[6:0],
    InstrD[14:12],
    InstrD[30],
    ResultSrcD,
    MemWriteD,
    ALUSrcD,
    RegWriteD,
    BranchD,
    JumpD,
    JalrD,
    ImmSrcD,
    ALUControlD
);

wire [31:0] RD1D, RD2D, ImmExtD;
wire [31:0] ResultW;

// Declare these before their first use.
reg [4:0] RdW;
reg RegWriteW;
reg [4:0] Rs1E, Rs2E, RdE;

reg_file rf (
    clk,
    RegWriteW,
    InstrD[19:15],
    InstrD[24:20],
    RdW,
    ResultW,
    RD1D,
    RD2D
);

imm_extend immD (
    InstrD[31:7],
    ImmSrcD,
    ImmExtD
);

// ============================================================
// HAZARD DETECTION
// ============================================================
wire StallF, StallD, FlushD, FlushE;
wire MemReadE;
wire RedirectE;
reg [1:0] ResultSrcE;

assign MemReadE = (ResultSrcE == 2'b01);

hazard_unit hu (
    InstrD[19:15],
    InstrD[24:20],
    RdE,
    MemReadE,
    RedirectE,
    StallF,
    StallD,
    FlushD,
    FlushE
);

// IF/ID: StallD=1 holds; reset or FlushD clears.
pl_reg_fd if_id (
    clk,
    StallD,
    reset || FlushD,
    Instr,
    PC,
    PCPlus4F,
    InstrD,
    PCD,
    PCPlus4D
);

// PC register: StallF=1 holds the fetch address.
reset_ff #(32) pc_reg (
    clk,
    reset,
    StallF,
    PCNext,
    PC
);

// ============================================================
// ID/EX PIPELINE REGISTER
// ============================================================
reg [31:0] InstrE;
reg [31:0] RD1E, RD2E, ImmExtE;
reg [31:0] PCE, PCPlus4E, UImmE;
reg [2:0] funct3E;
reg MemWriteE, ALUSrcE, RegWriteE;
reg BranchE, JumpE, JalrE;
reg [3:0] ALUControlE;

always @(posedge clk) begin
    if (reset || FlushE) begin
        InstrE      <= 32'b0;
        RD1E        <= 32'b0;
        RD2E        <= 32'b0;
        ImmExtE     <= 32'b0;
        PCE         <= 32'b0;
        PCPlus4E    <= 32'b0;
        UImmE       <= 32'b0;
        Rs1E        <= 5'b0;
        Rs2E        <= 5'b0;
        RdE         <= 5'b0;
        funct3E     <= 3'b0;
        ResultSrcE  <= 2'b0;
        MemWriteE   <= 1'b0;
        ALUSrcE     <= 1'b0;
        RegWriteE   <= 1'b0;
        BranchE     <= 1'b0;
        JumpE       <= 1'b0;
        JalrE       <= 1'b0;
        ALUControlE <= 4'b0;
    end else begin
        InstrE      <= InstrD;
        RD1E        <= RD1D;
        RD2E        <= RD2D;
        ImmExtE     <= ImmExtD;
        PCE         <= PCD;
        PCPlus4E    <= PCPlus4D;
        UImmE       <= {InstrD[31:12], 12'b0};
        Rs1E        <= InstrD[19:15];
        Rs2E        <= InstrD[24:20];
        RdE         <= InstrD[11:7];
        funct3E     <= InstrD[14:12];
        ResultSrcE  <= ResultSrcD;
        MemWriteE   <= MemWriteD;
        ALUSrcE     <= ALUSrcD;
        RegWriteE   <= RegWriteD;
        BranchE     <= BranchD;
        JumpE       <= JumpD;
        JalrE       <= JalrD;
        ALUControlE <= ALUControlD;
    end
end

// ============================================================
// EXECUTE STAGE AND FORWARDING
// ============================================================
reg [31:0] ALUResultM, WriteDataM, PCPlus4M, PCM;
reg [4:0] RdM;
reg [2:0] funct3M;
reg [1:0] ResultSrcM;
reg RegWriteM, MemWriteM;

wire [1:0] ForwardAE, ForwardBE;
wire [31:0] ResultM;
wire [31:0] ForwardedAE, ForwardedBE;
wire [31:0] ALUInputBE;
wire [31:0] ALUResultRawE, ALUResultE;
wire ZeroE;
wire BranchConditionE;
wire [31:0] PCTargetE;

forwarding_unit fu (
    Rs1E,
    Rs2E,
    RdM,
    RdW,
    RegWriteM,
    RegWriteW,
    ForwardAE,
    ForwardBE
);

assign ForwardedAE =
    (ForwardAE == 2'b10) ? ResultM :
    (ForwardAE == 2'b01) ? ResultW :
                           RD1E;

assign ForwardedBE =
    (ForwardBE == 2'b10) ? ResultM :
    (ForwardBE == 2'b01) ? ResultW :
                           RD2E;

assign ALUInputBE = ALUSrcE ? ImmExtE : ForwardedBE;

alu aluE (
    ForwardedAE,
    ALUInputBE,
    ALUControlE,
    ALUResultRawE,
    ZeroE
);

// LUI and AUIPC produce their U-type result in Execute.
assign ALUResultE =
    (InstrE[6:0] == 7'b0110111) ? UImmE :
    (InstrE[6:0] == 7'b0010111) ? (PCE + UImmE) :
                                  ALUResultRawE;

branching_unit branchE (
    funct3E,
    ForwardedAE,
    ForwardedBE,
    BranchConditionE
);

assign RedirectE =
    (BranchE && BranchConditionE) || JumpE || JalrE;

assign PCTargetE =
    JalrE ? ((ForwardedAE + ImmExtE) & 32'hffff_fffe) :
            (PCE + ImmExtE);

assign PCNext = RedirectE ? PCTargetE : PCPlus4F;

// ============================================================
// EX/MEM PIPELINE REGISTER
// ============================================================
always @(posedge clk) begin
    if (reset) begin
        ALUResultM <= 32'b0;
        WriteDataM <= 32'b0;
        PCPlus4M   <= 32'b0;
        PCM        <= 32'b0;
        RdM        <= 5'b0;
        funct3M    <= 3'b0;
        ResultSrcM <= 2'b0;
        RegWriteM  <= 1'b0;
        MemWriteM  <= 1'b0;
    end else begin
        ALUResultM <= ALUResultE;
        WriteDataM <= ForwardedBE;
        PCPlus4M   <= PCPlus4E;
        PCM        <= PCE;
        RdM        <= RdE;
        funct3M    <= funct3E;
        ResultSrcM <= ResultSrcE;
        RegWriteM  <= RegWriteE;
        MemWriteM  <= MemWriteE;
    end
end

// MEM-stage result is also used for forwarding.
assign ResultM =
    (ResultSrcM == 2'b01) ? ReadData :
    (ResultSrcM == 2'b10) ? PCPlus4M :
                            ALUResultM;

// External memory interface belongs to the MEM stage.
assign MemWrite   = MemWriteM;
assign Mem_WrAddr = ALUResultM;
assign Mem_WrData = WriteDataM;
assign funct3     = funct3M;

// ============================================================
// MEM/WB PIPELINE REGISTER
// ============================================================
reg [31:0] ReadDataW;
reg [31:0] PCPlus4W;
reg [1:0] ResultSrcW;

always @(posedge clk) begin
    if (reset) begin
        ReadDataW  <= 32'b0;
        PCPlus4W   <= 32'b0;
        PCW        <= 32'b0;
        ALUResultW <= 32'b0;
        WriteDataW <= 32'b0;
        RdW        <= 5'b0;
        ResultSrcW <= 2'b0;
        RegWriteW  <= 1'b0;
    end else begin
        ReadDataW  <= ReadData;
        PCPlus4W   <= PCPlus4M;
        PCW        <= PCM;
        ALUResultW <= ALUResultM;
        WriteDataW <= WriteDataM;
        RdW        <= RdM;
        ResultSrcW <= ResultSrcM;
        RegWriteW  <= RegWriteM;
    end
end

assign ResultW =
    (ResultSrcW == 2'b01) ? ReadDataW :
    (ResultSrcW == 2'b10) ? PCPlus4W :
                            ALUResultW;

assign Result = ResultW;

endmodule
