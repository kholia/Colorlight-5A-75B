module top (
    input  wire clk_i,   // 25 MHz
    output wire rf_out,  // 1-bit RF
    output wire led_o
);

    // --- Audio Clock (8 kHz) ---
    reg [11:0] sample_cnt = 0;
    reg [14:0] addr = 0;
    always @(posedge clk_i) begin
        if (sample_cnt >= 12'd3124) begin
            sample_cnt <= 0;
            if (addr >= 15'd30700) addr <= 0; // 3 seconds
            else addr <= addr + 1;
        end else begin
            sample_cnt <= sample_cnt + 1;
        end
    end

    // --- 32-bit Memory (24,000 samples) ---
    // reg [31:0] audio_mem [0:23999];
    reg [31:0] audio_mem [0:30700];
    initial $readmemh("audio_8k.mem", audio_mem);

    reg [31:0] audio_data_reg;
    always @(posedge clk_i) audio_data_reg <= audio_mem[addr];

    // --- Single NCO ---
    reg [31:0] phase_acc = 0;
    localparam [31:0] CARRIER = 32'd2439541424; // 14.200 MHz

    always @(posedge clk_i) begin
        // Directly add the deviation to the carrier
        phase_acc <= phase_acc + CARRIER + audio_data_reg;
    end

    assign rf_out = phase_acc[31];
    assign led_o = addr[14];

endmodule
