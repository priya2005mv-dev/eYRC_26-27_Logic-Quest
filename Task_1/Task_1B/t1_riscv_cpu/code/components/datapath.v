module datapath (
    input         clk, reset,
    input  [1:0]  ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input  [1:0]  ImmSrc,
    input  [2:0]  ALUControl,

    output        Zero,
    output [31:0] PC,

    input  [31:0] Instr,

    output [31:0] Mem_WrAddr,
    output [31:0] Mem_WrData,

    input  [31:0] ReadData,

    output [31:0] Result
);

wire [31:0] PCNext;
wire [31:0] PCPlus4;
wire [31:0] PCTarget;

wire [31:0] ImmExt;
wire [31:0] SrcA;
wire [31:0] SrcB;
wire [31:0] WriteData;
wire [31:0] ALUResult;

wire [31:0] UImm;

wire [31:0] ALUSrcA;
wire [31:0] ALUSrcB;

wire is_auipc;
wire is_jalr;

assign is_auipc = (Instr[6:0] == 7'b0010111);
assign is_jalr  = (Instr[6:0] == 7'b1100111);


// ================================================================
// PROGRAM COUNTER
// ================================================================

reset_ff #(32) pcreg(
    clk,
    reset,
    PCNext,
    PC
);

adder pcadd4(
    PC,
    32'd4,
    PCPlus4
);

adder pcaddbranch(
    PC,
    ImmExt,
    PCTarget
);


// ================================================================
// REGISTER FILE
// ================================================================

reg_file rf(
    clk,
    RegWrite,
    Instr[19:15],
    Instr[24:20],
    Instr[11:7],
    Result,
    SrcA,
    WriteData
);


// ================================================================
// IMMEDIATE EXTENSION
// ================================================================

imm_extend ext(
    Instr[31:7],
    ImmSrc,
    ImmExt
);


// ================================================================
// U-TYPE IMMEDIATE
// LUI / AUIPC
//
// imm[31:12] << 12
// ================================================================

assign UImm = {
    Instr[31:12],
    12'b0
};


// ================================================================
// ALU INPUT A
//
// Normal instructions:
//     SrcA = register rs1
//
// AUIPC:
//     SrcA = PC
// ================================================================

assign ALUSrcA = is_auipc ? PC : SrcA;


// ================================================================
// ALU INPUT B
//
// AUIPC:
//     UImm
//
// Other instructions:
//     register or immediate according to ALUSrc
// ================================================================

assign ALUSrcB = is_auipc
               ? UImm
               : (ALUSrc ? ImmExt : WriteData);


// ================================================================
// ALU
// ================================================================

alu alu(
    ALUSrcA,
    ALUSrcB,
    ALUControl,
    ALUResult,
    Zero
);


// ================================================================
// JALR TARGET
//
// JALR target:
//
//     rs1 + sign_extended(imm)
//
// then clear bit 0.
//
// ALUResult already contains rs1 + immediate
// for JALR.
// ================================================================

wire [31:0] JALRTarget;

assign JALRTarget = {
    ALUResult[31:1],
    1'b0
};


// ================================================================
// NEXT PC TARGET
//
// JAL:
//     PC + J-immediate
//
// JALR:
//     (rs1 + I-immediate) & ~1
// ================================================================

wire [31:0] NextTarget;

assign NextTarget = is_jalr
                  ? JALRTarget
                  : PCTarget;


// ================================================================
// PC MUX
// ================================================================

mux2 #(32) pcmux(
    PCPlus4,
    NextTarget,
    PCSrc,
    PCNext
);


// ================================================================
// WRITEBACK RESULT
//
// ResultSrc:
//
// 00 = ALUResult
// 01 = ReadData
// 10 = PCPlus4
// 11 = UImm
//
// LUI   -> UImm
// AUIPC -> ALUResult
// JAL   -> PCPlus4
// JALR  -> PCPlus4
// ================================================================

mux4 #(32) resultmux(
    ALUResult,
    ReadData,
    PCPlus4,
    UImm,
    ResultSrc,
    Result
);


// ================================================================
// DATA MEMORY OUTPUTS
// ================================================================

assign Mem_WrData = WriteData;

assign Mem_WrAddr = ALUResult;

endmodule