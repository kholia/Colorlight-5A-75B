module fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input  wire clk,
    input  wire rst,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire wr_en,
    output wire full,
    output reg [DATA_WIDTH-1:0] dout,
    input  wire rd_en,
    output wire empty,
    output reg [ADDR_WIDTH:0] count
);

    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] wr_ptr = 0;
    reg [ADDR_WIDTH-1:0] rd_ptr = 0;

    assign full = (count == (2**ADDR_WIDTH));
    assign empty = (count == 0);

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                2'b01: begin
                    dout <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
                2'b11: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1;
                    dout <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                end
            endcase
        end
    end

endmodule
