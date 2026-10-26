// Data memory supporting RV32I byte, halfword and word accesses.
module data_mem #(
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 32,
    MEM_SIZE = 64
) (
    input clk,
    input wr_en,
    input [2:0] funct3,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [ADDR_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data_mem
);

reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];

wire [ADDR_WIDTH-1:0] word_addr =
    (wr_addr[DATA_WIDTH-1:2] % MEM_SIZE);

integer i;
initial begin
    for (i = 0; i < MEM_SIZE; i = i + 1)
        data_ram[i] = {DATA_WIDTH{1'b0}};
end

// Stores: SB, SH, SW
always @(posedge clk) begin
    if (wr_en) begin
        case (funct3)
            3'b000: begin // SB
                case (wr_addr[1:0])
                    2'b00: data_ram[word_addr][7:0]   <= wr_data[7:0];
                    2'b01: data_ram[word_addr][15:8]  <= wr_data[7:0];
                    2'b10: data_ram[word_addr][23:16] <= wr_data[7:0];
                    2'b11: data_ram[word_addr][31:24] <= wr_data[7:0];
                endcase
            end

            3'b001: begin // SH
                if (wr_addr[1] == 1'b0)
                    data_ram[word_addr][15:0] <= wr_data[15:0];
                else
                    data_ram[word_addr][31:16] <= wr_data[15:0];
            end

            3'b010: data_ram[word_addr] <= wr_data; // SW
            default: ;
        endcase
    end
end

// Loads: LB, LH, LW, LBU, LHU
always @(*) begin
    case (funct3)
        3'b000: begin // LB
            case (wr_addr[1:0])
                2'b00: rd_data_mem = {{24{data_ram[word_addr][7]}}, data_ram[word_addr][7:0]};
                2'b01: rd_data_mem = {{24{data_ram[word_addr][15]}}, data_ram[word_addr][15:8]};
                2'b10: rd_data_mem = {{24{data_ram[word_addr][23]}}, data_ram[word_addr][23:16]};
                2'b11: rd_data_mem = {{24{data_ram[word_addr][31]}}, data_ram[word_addr][31:24]};
            endcase
        end

        3'b001: begin // LH
            if (wr_addr[1] == 1'b0)
                rd_data_mem = {{16{data_ram[word_addr][15]}}, data_ram[word_addr][15:0]};
            else
                rd_data_mem = {{16{data_ram[word_addr][31]}}, data_ram[word_addr][31:16]};
        end

        3'b010: rd_data_mem = data_ram[word_addr]; // LW

        3'b100: begin // LBU
            case (wr_addr[1:0])
                2'b00: rd_data_mem = {24'b0, data_ram[word_addr][7:0]};
                2'b01: rd_data_mem = {24'b0, data_ram[word_addr][15:8]};
                2'b10: rd_data_mem = {24'b0, data_ram[word_addr][23:16]};
                2'b11: rd_data_mem = {24'b0, data_ram[word_addr][31:24]};
            endcase
        end

        3'b101: begin // LHU
            if (wr_addr[1] == 1'b0)
                rd_data_mem = {16'b0, data_ram[word_addr][15:0]};
            else
                rd_data_mem = {16'b0, data_ram[word_addr][31:16]};
        end

        default: rd_data_mem = 32'b0;
    endcase
end

endmodule
