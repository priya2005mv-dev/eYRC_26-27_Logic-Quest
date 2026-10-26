// ALU decoder for RV32I operations.
module alu_decoder (
    input            opb5,
    input      [2:0] funct3,
    input            funct7b5,
    input      [1:0] ALUOp,
    output reg [3:0] ALUControl
);

always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 4'b0000; // ADD: loads, stores, address calculations
        2'b01: ALUControl = 4'b0001; // SUB: branch comparison
        default: begin
            case (funct3)
                3'b000: begin
                    if (opb5 && funct7b5)
                        ALUControl = 4'b0001; // SUB
                    else
                        ALUControl = 4'b0000; // ADD / ADDI
                end
                3'b001: ALUControl = 4'b0111; // SLL / SLLI
                3'b010: ALUControl = 4'b0100; // SLT / SLTI
                3'b011: ALUControl = 4'b0101; // SLTU / SLTIU
                3'b100: ALUControl = 4'b0110; // XOR / XORI
                3'b101: begin
                    if (funct7b5)
                        ALUControl = 4'b1001; // SRA / SRAI
                    else
                        ALUControl = 4'b1000; // SRL / SRLI
                end
                3'b110: ALUControl = 4'b0011; // OR / ORI
                3'b111: ALUControl = 4'b0010; // AND / ANDI
                default: ALUControl = 4'b0000;
            endcase
        end
    endcase
end

endmodule
