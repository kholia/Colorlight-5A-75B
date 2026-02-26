module uart_rx #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 4000000
)(
    input  wire clk,
    input  wire rx,
    output reg [7:0] data,
    output reg valid
);
    localparam WAIT_STATES = CLK_FREQ / BAUD_RATE;
    reg [31:0] count = 0;
    reg [3:0] bit_idx = 0;
    reg rx_sync, rx_reg;
    always @(posedge clk) begin rx_sync <= rx; rx_reg <= rx_sync; end

    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state = IDLE;

    always @(posedge clk) begin
        valid <= 0;
        case (state)
            IDLE: begin
                if (rx_reg == 0) begin
                    state <= START;
                    count <= WAIT_STATES / 2;
                end
            end
            START: begin
                if (count == 0) begin
                    state <= DATA;
                    count <= WAIT_STATES - 1;
                    bit_idx <= 0;
                end else count <= count - 1;
            end
            DATA: begin
                if (count == 0) begin
                    data[bit_idx] <= rx_reg;
                    count <= WAIT_STATES - 1;
                    if (bit_idx == 7) state <= STOP;
                    else bit_idx <= bit_idx + 1;
                end else count <= count - 1;
            end
            STOP: begin
                if (count == 0) begin
                    valid <= 1;
                    state <= IDLE;
                end else count <= count - 1;
            end
        endcase
    end
endmodule
