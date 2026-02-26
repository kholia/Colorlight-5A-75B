// HD Direct Digital SSB Synthesizer - Restored Stable Engine V8.2
(* blackbox *)
module EHXPLLL (
    input CLKI, input CLKFB, input PHASESEL1, input PHASESEL0, input PHASEDIR,
    input PHASESTEP, input PHASELOADREG, input STDBY, input PLLWAKESYNC,
    input RST, input ENCLKOP,
    output CLKOP, output LOCK
);
    parameter CLKI_DIV = 1;
    parameter CLKFB_DIV = 1;
    parameter CLKOP_DIV = 8;
    parameter CLKOP_ENABLE = "ENABLED";
    parameter FEEDBK_PATH = "CLKOP";
endmodule

module top (
    input  wire clk_i,       // 25 MHz external
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire hub75_oe,    // V8.2 Output Enable
    (* IOB="TRUE" *) output reg rf_out,
    (* IOB="TRUE" *) output reg led_o
);

    // Drive HUB75 Output Enable LOW to activate 74HC245 buffers
    assign hub75_oe = 1'b0;

    // --- PLL: 25 MHz -> 100 MHz ---
    wire clk_100;
    wire pll_locked;
    EHXPLLL #(
        .CLKI_DIV(1), .CLKFB_DIV(4), .CLKOP_DIV(6),
        .CLKOP_ENABLE("ENABLED"), .FEEDBK_PATH("CLKOP")
    ) pll_inst (
        .CLKI(clk_i), .CLKFB(clk_100), .CLKOP(clk_100), .LOCK(pll_locked),
        .PHASESEL0(1'b0), .PHASESEL1(1'b0), .PHASEDIR(1'b0),
        .PHASESTEP(1'b0), .PHASELOADREG(1'b0), .STDBY(1'b0), .PLLWAKESYNC(1'b0),
        .RST(1'b0), .ENCLKOP(1'b1)
    );

    // --- UART (2 Mbps) ---
    wire [7:0] rx_byte;
    wire rx_valid;
    uart_rx #(.CLK_FREQ(100000000), .BAUD_RATE(2000000)) rx_inst (
        .clk(clk_100), .rx(uart_rx_i), .data(rx_byte), .valid(rx_valid)
    );

    reg [7:0] tx_byte = 8'h06; // ACK
    reg tx_start = 0;
    wire tx_ready;
    uart_tx #(.CLK_FREQ(100000000), .BAUD_RATE(2000000)) tx_inst (
        .clk(clk_100), .data(tx_byte), .start(tx_start), .tx(uart_tx_o), .ready(tx_ready)
    );

    // --- PACKET UNPACKER (4 Bytes: Frequency only) ---
    reg [31:0] uart_word;
    reg [1:0] byte_cnt = 0;
    reg fifo_wr_en = 0;
    reg [19:0] uart_sync_timer = 0;

    always @(posedge clk_100) begin
        fifo_wr_en <= 0;
        tx_start <= 0;
        if (rx_valid) begin
            uart_sync_timer <= 0;
            case (byte_cnt)
                2'd0: uart_word[7:0]   <= rx_byte;
                2'd1: uart_word[15:8]  <= rx_byte;
                2'd2: uart_word[23:16] <= rx_byte;
                2'd3: begin
                    uart_word[31:24] <= rx_byte;
                    fifo_wr_en <= 1;
                    tx_start <= 1; // Send ACK
                end
            endcase
            byte_cnt <= byte_cnt + 1;
        end else begin
            if (uart_sync_timer < 20'd100000) uart_sync_timer <= uart_sync_timer + 1;
            else byte_cnt <= 0;
        end
    end

    // --- FIFO ---
    wire [31:0] fifo_dout;
    wire fifo_empty;
    reg fifo_rd_en = 0;
    fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(10)) audio_fifo (
        .clk(clk_100), .rst(!pll_locked), .din(uart_word), .wr_en(fifo_wr_en),
        .dout(fifo_dout), .rd_en(fifo_rd_en), .empty(fifo_empty)
    );

    // --- TRANSMIT CONTROL (VOX) ---
    reg [24:0] hang_timer = 0;
    reg is_transmitting = 0;
    always @(posedge clk_100) begin
        if (!fifo_empty) begin
            hang_timer <= 25'd20_000_000;
            is_transmitting <= 1'b1;
        end else if (hang_timer > 0) begin
            hang_timer <= hang_timer - 1;
        end else begin
            is_transmitting <= 1'b0;
        end
        led_o <= !is_transmitting; // Active Low LED
    end

    // --- INTERPOLATOR (Stable Engine) ---
    reg [31:0] audio_data_curr = 0;
    reg [31:0] audio_data_next = 0;
    reg [47:0] interp_acc = 0;
    reg signed [31:0] interp_val_reg = 0;
    reg [11:0] sample_cnt = 0;
    reg fifo_rd_en_d = 0;
    reg [31:0] fifo_dout_reg = 0;
    reg signed [31:0] p1_diff = 0;
    reg signed [31:0] p2_step = 0;
    reg signed [31:0] active_step = 0;

    always @(posedge clk_100) begin
        fifo_rd_en <= 0;
        fifo_dout_reg <= fifo_dout;
        p1_diff <= $signed(fifo_dout_reg) - $signed(audio_data_next);
        p2_step <= ($signed(p1_diff) * 32'sd31465) >>> 26;

        if (sample_cnt >= 12'd2082) begin
            sample_cnt <= 0;
            audio_data_curr <= audio_data_next;
            interp_acc <= {audio_data_next, 16'b0};
            active_step <= p2_step;
            if (!fifo_empty) fifo_rd_en <= 1;
        end else begin
            sample_cnt <= sample_cnt + 1;
            interp_acc <= $signed(interp_acc) + $signed(active_step);
        end
        interp_val_reg <= $signed(interp_acc[47:16]);
        fifo_rd_en_d <= fifo_rd_en;
        if (fifo_rd_en_d) audio_data_next <= fifo_dout;
    end

    // --- PIPELINED NCO ---
    reg [31:0] phase_acc = 0;
    reg signed [31:0] nco_inc = 0;
    localparam [31:0] CARRIER = 32'd609885356;

    always @(posedge clk_100) begin
        nco_inc <= $signed(CARRIER) + interp_val_reg;
        phase_acc <= phase_acc + nco_inc;
        if (is_transmitting) rf_out <= phase_acc[31];
        else rf_out <= 1'b0;
    end

endmodule
