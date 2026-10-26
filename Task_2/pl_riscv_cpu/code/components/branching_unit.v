// Branch comparison unit for RV32I conditional branches.
module branching_unit (
    input      [2:0]  funct3,
    input      [31:0] a,
    input      [31:0] b,
    output reg        Branch
);

always @(*) begin
    case (funct3)
        3'b000: Branch = (a == b);                  // BEQ
        3'b001: Branch = (a != b);                  // BNE
        3'b100: Branch = ($signed(a) < $signed(b)); // BLT
        3'b101: Branch = ($signed(a) >= $signed(b));// BGE
        3'b110: Branch = (a < b);                   // BLTU
        3'b111: Branch = (a >= b);                  // BGEU
        default: Branch = 1'b0;
    endcase
end

endmodule
