module hazard_unit (
    input  [4:0] rs1D,
    input  [4:0] rs2D,
    input  [4:0] rdE,
    input        MemReadE,
    input        BranchTakenE,
    output reg   StallF,
    output reg   StallD,
    output reg   FlushD,
    output reg   FlushE
);

wire LoadUseHazard;

assign LoadUseHazard =
    MemReadE &&
    (rdE != 5'd0) &&
    ((rdE == rs1D) || (rdE == rs2D));

always @(*) begin
    StallF = LoadUseHazard && !BranchTakenE;
    StallD = LoadUseHazard && !BranchTakenE;
    FlushD = BranchTakenE;
    FlushE = LoadUseHazard || BranchTakenE;
end

endmodule
