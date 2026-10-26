// Five-stage pipelined RISC-V CPU wrapper.
module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output [2:0]  funct3,
    output [31:0] PCW, ALUResultW, WriteDataW
);

datapath dp (
    clk,
    reset,
    PC,
    Instr,
    MemWrite,
    Mem_WrAddr,
    Mem_WrData,
    ReadData,
    Result,
    funct3,
    PCW,
    ALUResultW,
    WriteDataW
);

endmodule
