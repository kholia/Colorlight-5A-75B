import numpy as np

def generate_sine_verilog():
    # 4096 points, 16-bit amplitude (+- 32767)
    DEPTH = 4096
    WIDTH = 16
    x = np.linspace(0, 2*np.pi, DEPTH, endpoint=False)
    y = np.sin(x)
    max_val = (2**(WIDTH-1)) - 1
    y_int = (y * max_val).astype(int)

    print(f"Generating synchronous sine_rom.v ({DEPTH}x{WIDTH})...")

    with open("sine_rom.v", "w") as f:
        f.write(f"module sine_rom (input clk, input [{int(np.log2(DEPTH))-1}:0] addr, output reg signed [{WIDTH-1}:0] data);\n")
        f.write("    always @(posedge clk) begin\n")
        f.write("        case(addr)\n")
        for i, val in enumerate(y_int):
            if val < 0:
                f.write(f"            {int(np.log2(DEPTH))}'d{i}: data <= -{WIDTH}'sd{abs(val)};\n")
            else:
                f.write(f"            {int(np.log2(DEPTH))}'d{i}: data <= {WIDTH}'sd{val};\n")
        f.write("            default: data <= 0;\n")
        f.write("        endcase\n")
        f.write("    end\n")
        f.write("endmodule\n")

if __name__ == "__main__":
    generate_sine_verilog()
