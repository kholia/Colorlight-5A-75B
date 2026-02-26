
module top (
    input  wire clk_i,   // 25 MHz external oscillator
    output wire rf_out,  // 1-bit RF output
    output wire led_o    // LED output
);

    // Power-on reset generator
    reg [15:0] rst_cnt = 0;
    reg reset_n = 0;
    always @(posedge clk_i) begin
        if (rst_cnt < 16'hFFFF) begin
            rst_cnt <= rst_cnt + 1;
            reset_n <= 0;
        end else begin
            reset_n <= 1;
        end
    end

    // Frequency increments for 14.2 MHz + 700 Hz and 14.2 MHz + 1900 Hz
    localparam [31:0] INC_700  = 32'd2439661683;
    localparam [31:0] INC_1900 = 32'd2439867841;

    // Two independent phase accumulators
    reg [31:0] phase700  = 0;
    reg [31:0] phase1900 = 0;

    always @(posedge clk_i) begin
        if (!reset_n) begin
            phase700  <= 0;
            phase1900 <= 0;
        end else begin
            phase700  <= phase700  + INC_700;
            phase1900 <= phase1900 + INC_1900;
        end
    end

    // Rapid toggle (12.5 MHz)
    reg toggle = 0;
    always @(posedge clk_i) toggle <= ~toggle;

    // Interleave the phases into the NCO pipeline.
    // Because the NCO is a pure feed-forward pipeline,
    // it will process the interleaved phases independently.
    wire [31:0] nco_input_phase = toggle ? phase1900 : phase700;

    // Instantiate NCO from the NCO folder
    wire [31:0] nco_dat;
    nco nco_inst (
        .clk(clk_i),
        .reset_n(reset_n),
        .t_angle_dat(nco_input_phase),
        .t_angle_req(reset_n),
        .t_angle_ack(),
        .i_nco_dat(nco_dat),
        .i_nco_req(),
        .i_nco_ack(1'b1)
    );

    // Output the MSB of the real component.
    // The output stream will alternate between samples of the two frequencies.
    assign rf_out = nco_dat[15];

    // Heartbeat LED
    reg [23:0] led_cnt = 0;
    always @(posedge clk_i) led_cnt <= led_cnt + 1;
    assign led_o = led_cnt[23];

endmodule
