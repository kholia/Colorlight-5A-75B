ECP5 FPGA Usage Report:

```
Info: Logic utilisation before packing:
Info:     Total LUT4s:       477/24288     1%
Info:         logic LUTs:    309/24288     1%
Info:         carry LUTs:    168/24288     0%
Info:           RAM LUTs:      0/ 3036     0%
Info:          RAMW LUTs:      0/ 6072     0%

Info:      Total DFFs:       289/24288     1%

Info: Packing IOs..
Info: pin 'uart_rx_i$tr_io' constrained to Bel 'X6/Y50/PIOA'.
Info: pin 'rf_out$tr_io' constrained to Bel 'X72/Y44/PIOB'.
Info: pin 'led_o$tr_io' constrained to Bel 'X4/Y50/PIOA'.
Info: pin 'clk_i$tr_io' constrained to Bel 'X0/Y47/PIOC'.
Info: Packing constants..
Info: Packing carries...
Info: Packing LUTs...
Info: Packing LUT5-7s...
Info: Packing FFs...
Info:     144 FFs paired with LUTs.
Info: Generating derived timing constraints...
Info:     Input frequency of PLL 'pll_inst' is constrained to 25.0 MHz
Info: Promoting globals...
Info:     promoting clock net clk_100 to global network
Info: Checksum: 0x8a948d32

Info: Device utilisation:
Info: 	          TRELLIS_IO:       4/    197     2%
Info: 	                DCCA:       1/     56     1%
Info: 	              DP16KD:       2/     56     3%
Info: 	          MULT18X18D:       0/     28     0%
Info: 	              ALU54B:       0/     14     0%
Info: 	             EHXPLLL:       1/      2    50%
Info: 	             EXTREFB:       0/      1     0%
Info: 	                DCUA:       0/      1     0%
Info: 	           PCSCLKDIV:       0/      2     0%
Info: 	             IOLOGIC:       0/    128     0%
Info: 	            SIOLOGIC:       0/     69     0%
Info: 	                 GSR:       0/      1     0%
Info: 	               JTAGG:       0/      1     0%
Info: 	                OSCG:       0/      1     0%
Info: 	               SEDGA:       0/      1     0%
Info: 	                 DTR:       0/      1     0%
Info: 	             USRMCLK:       0/      1     0%
Info: 	             CLKDIVF:       0/      4     0%
Info: 	           ECLKSYNCB:       0/     10     0%
Info: 	             DLLDELD:       0/      8     0%
Info: 	              DDRDLL:       0/      4     0%
Info: 	             DQSBUFM:       0/      8     0%
Info: 	     TRELLIS_ECLKBUF:       0/      8     0%
Info: 	        ECLKBRIDGECS:       0/      2     0%
Info: 	                DCSC:       0/      2     0%
Info: 	          TRELLIS_FF:     289/  24288     1%
Info: 	        TRELLIS_COMB:     523/  24288     2%
Info: 	        TRELLIS_RAMW:       0/   3036     0%
```
