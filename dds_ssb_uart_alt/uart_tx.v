module uart_tx #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 4000000
)(
    input  wire clk,
    input  wire [7:0] data,
    input  wire start,
    output reg tx = 1,
    output wire ready
);
    localparam WAIT_STATES = CLK_FREQ / BAUD_RATE;
    reg [31:0] count = 0;
    reg [3:0] bit_idx = 0;
    reg [7:0] data_reg = 0;

    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state = IDLE;
    assign ready = (state == IDLE);

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx <= 1;
                if (start) begin
                    data_reg <= data;
                    state <= START;
                    count <= WAIT_STATES - 1;
                end
            end
            START: begin
                tx <= 0;
                if (count == 0) begin
                    state <= DATA;
                    count <= WAIT_STATES - 1;
                    bit_idx <= 0;
                end else count <= count - 1;
            end
            DATA: begin
                tx <= data_reg[bit_idx];
                if (count == 0) begin
                    if (bit_idx == 7) state <= STOP;
                    else bit_idx <= bit_idx + 1;
                    count <= WAIT_STATES - 1;
                end else count <= count - 1;
            end
            STOP: begin
                tx <= 1;
                if (count == 0) state <= IDLE;
                else count <= count - 1;
            end
        endcase
    end
endmodule
