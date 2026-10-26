// Generic pipeline register for the five-stage RISC-V CPU.
// stall=1 holds the current value.
// flush=1 inserts a zero-valued bubble.
module pipeline_reg #(parameter WIDTH = 32) (
    input clk,
    input reset,
    input stall,
    input flush,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

initial q = {WIDTH{1'b0}};

always @(posedge clk) begin
    if (reset)
        q <= {WIDTH{1'b0}};
    else if (flush)
        q <= {WIDTH{1'b0}};
    else if (!stall)
        q <= d;
end

endmodule
