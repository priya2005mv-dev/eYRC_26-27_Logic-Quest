module forwarding_unit (
    input [4:0] rs1E,
    input [4:0] rs2E,
    input [4:0] rdM,
    input [4:0] rdW,
    input RegWriteM,
    input RegWriteW,
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE
);

always @(*) begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;

    if (RegWriteM && (rdM != 0) && (rdM == rs1E))
        ForwardAE = 2'b10;
    else if (RegWriteW && (rdW != 0) && (rdW == rs1E))
        ForwardAE = 2'b01;

    if (RegWriteM && (rdM != 0) && (rdM == rs2E))
        ForwardBE = 2'b10;
    else if (RegWriteW && (rdW != 0) && (rdW == rs2E))
        ForwardBE = 2'b01;
end

endmodule
