// {"dataWidth":16,"addrWidth":4,"betaWidth":16,"nCordics":9,"corrector":0,"scale":0.999838,"top":"nco"}
module nco (
    // per node (target / initiator)
    input              clk,
    input              reset_n,
    input       [31:0] t_angle_dat,
    input              t_angle_req,
    output             t_angle_ack,
    output      [31:0] i_nco_dat,
    output             i_nco_req,
    input              i_nco_ack
);
wire      [31:0] dat0, dat0_nxt, dat11;
wire      [67:0] dat1, dat1_nxt, dat2, dat2_nxt, dat3, dat3_nxt, dat4, dat4_nxt, dat5, dat5_nxt, dat6, dat6_nxt, dat7, dat7_nxt, dat8, dat8_nxt, dat9, dat9_nxt, dat10, dat10_nxt;
// per node
assign dat0_nxt = t_angle_dat; // node:0 is target port
// node:1 macro nco_lut

// Look-Up stage
/*
{JSON.stringify(lut, null, 4)}
*/

reg [31:0] ncolut;

always @*
casez (node1_addr)
0 : ncolut = {16'd1608, 16'd65504};
1 : ncolut = {16'd4820, 16'd65347};
2 : ncolut = {16'd8020, 16'd65031};
3 : ncolut = {16'd11202, 16'd64559};
4 : ncolut = {16'd14356, 16'd63932};
5 : ncolut = {16'd17476, 16'd63151};
6 : ncolut = {16'd20553, 16'd62217};
7 : ncolut = {16'd23581, 16'd61133};
8 : ncolut = {16'd26553, 16'd59903};
9 : ncolut = {16'd29460, 16'd58528};
10 : ncolut = {16'd32296, 16'd57012};
11 : ncolut = {16'd35055, 16'd55358};
12 : ncolut = {16'd37729, 16'd53571};
13 : ncolut = {16'd40312, 16'd51656};
14 : ncolut = {16'd42798, 16'd49615};
15 : ncolut = {16'd45181, 16'd47455};
endcase

wire [31:0] node1_angle;
wire [2:0] node1_phase;
wire [3:0] node1_addr;
wire [17:0] node1_reSwap;
wire [17:0] node1_imSwap;


assign node1_angle = dat0;
assign node1_phase = node1_angle[31:29]; //3 bit phase
assign node1_addr = node1_phase[0]?~node1_angle[28:25]:node1_angle[28:25];
//re = 15:0  im = 31:16
assign node1_reSwap[17:16]=2'b0;
assign node1_imSwap[17:16]=2'b0;
assign node1_reSwap[15:0] = node1_phase[0]^node1_phase[1] ? ncolut[31:16]:ncolut[15:0];
assign node1_imSwap[15:0] = node1_phase[0]^node1_phase[1] ? ncolut[15:0]:ncolut[31:16];

assign dat1_nxt[17:0] = node1_phase[2]^node1_phase[1]?~node1_reSwap:node1_reSwap;
assign dat1_nxt[35:18] = node1_phase[2]?~node1_imSwap:node1_imSwap;
assign dat1_nxt[60:36] = node1_angle[24:0];

// node:2 macro nco_cordic

// CORDIC stage 0
/*
{
    "sigma": 20839,
    "shift": 6
}
*/

wire [24:0] beta0;
wire [24:0] beta_calc0;
wire [17:0] re0,im0,re_shift0,im_shift0;


assign  beta0 = dat1[24:0];

assign re0=dat1[17:0];
assign im0=dat1[35:18];

//assign re_shift0={{6{re0[17]}},re0 >> 6};
//assign im_shift0={{6{im0[17]}},im0 >> 6};

assign re_shift0=$signed(re0) >> 6;
assign im_shift0=$signed(im0) >> 6;

assign beta_calc0 = beta0[24]?beta0+20839:beta0-20839;
assign dat2_nxt[17:0] = beta0[24]?re0-im_shift0 : re0+im_shift0;
assign dat2_nxt[35:18] = beta0[24]?im0+re_shift0 : im0-re_shift0;
assign dat2_nxt[60:36] = beta_calc0;


// node:3 macro nco_cordic

// CORDIC stage 1
/*
{
    "sigma": 10420,
    "shift": 7
}
*/

wire [24:0] beta1;
wire [24:0] beta_calc1;
wire [17:0] re1,im1,re_shift1,im_shift1;


assign  beta1 = dat2[24:0];

assign re1=dat2[17:0];
assign im1=dat2[35:18];

//assign re_shift1={{7{re1[17]}},re1 >> 7};
//assign im_shift1={{7{im1[17]}},im1 >> 7};

assign re_shift1=$signed(re1) >> 7;
assign im_shift1=$signed(im1) >> 7;

assign beta_calc1 = beta1[24]?beta1+10420:beta1-10420;
assign dat3_nxt[17:0] = beta1[24]?re1-im_shift1 : re1+im_shift1;
assign dat3_nxt[35:18] = beta1[24]?im1+re_shift1 : im1-re_shift1;
assign dat3_nxt[60:36] = beta_calc1;


// node:4 macro nco_cordic

// CORDIC stage 2
/*
{
    "sigma": 5210,
    "shift": 8
}
*/

wire [24:0] beta2;
wire [24:0] beta_calc2;
wire [17:0] re2,im2,re_shift2,im_shift2;


assign  beta2 = dat3[24:0];

assign re2=dat3[17:0];
assign im2=dat3[35:18];

//assign re_shift2={{8{re2[17]}},re2 >> 8};
//assign im_shift2={{8{im2[17]}},im2 >> 8};

assign re_shift2=$signed(re2) >> 8;
assign im_shift2=$signed(im2) >> 8;

assign beta_calc2 = beta2[24]?beta2+5210:beta2-5210;
assign dat4_nxt[17:0] = beta2[24]?re2-im_shift2 : re2+im_shift2;
assign dat4_nxt[35:18] = beta2[24]?im2+re_shift2 : im2-re_shift2;
assign dat4_nxt[60:36] = beta_calc2;


// node:5 macro nco_cordic

// CORDIC stage 3
/*
{
    "sigma": 2605,
    "shift": 9
}
*/

wire [24:0] beta3;
wire [24:0] beta_calc3;
wire [17:0] re3,im3,re_shift3,im_shift3;


assign  beta3 = dat4[24:0];

assign re3=dat4[17:0];
assign im3=dat4[35:18];

//assign re_shift3={{9{re3[17]}},re3 >> 9};
//assign im_shift3={{9{im3[17]}},im3 >> 9};

assign re_shift3=$signed(re3) >> 9;
assign im_shift3=$signed(im3) >> 9;

assign beta_calc3 = beta3[24]?beta3+2605:beta3-2605;
assign dat5_nxt[17:0] = beta3[24]?re3-im_shift3 : re3+im_shift3;
assign dat5_nxt[35:18] = beta3[24]?im3+re_shift3 : im3-re_shift3;
assign dat5_nxt[60:36] = beta_calc3;


// node:6 macro nco_cordic

// CORDIC stage 4
/*
{
    "sigma": 1303,
    "shift": 10
}
*/

wire [24:0] beta4;
wire [24:0] beta_calc4;
wire [17:0] re4,im4,re_shift4,im_shift4;


assign  beta4 = dat5[24:0];

assign re4=dat5[17:0];
assign im4=dat5[35:18];

//assign re_shift4={{10{re4[17]}},re4 >> 10};
//assign im_shift4={{10{im4[17]}},im4 >> 10};

assign re_shift4=$signed(re4) >> 10;
assign im_shift4=$signed(im4) >> 10;

assign beta_calc4 = beta4[24]?beta4+1303:beta4-1303;
assign dat6_nxt[17:0] = beta4[24]?re4-im_shift4 : re4+im_shift4;
assign dat6_nxt[35:18] = beta4[24]?im4+re_shift4 : im4-re_shift4;
assign dat6_nxt[60:36] = beta_calc4;


// node:7 macro nco_cordic

// CORDIC stage 5
/*
{
    "sigma": 651,
    "shift": 11
}
*/

wire [24:0] beta5;
wire [24:0] beta_calc5;
wire [17:0] re5,im5,re_shift5,im_shift5;


assign  beta5 = dat6[24:0];

assign re5=dat6[17:0];
assign im5=dat6[35:18];

//assign re_shift5={{11{re5[17]}},re5 >> 11};
//assign im_shift5={{11{im5[17]}},im5 >> 11};

assign re_shift5=$signed(re5) >> 11;
assign im_shift5=$signed(im5) >> 11;

assign beta_calc5 = beta5[24]?beta5+651:beta5-651;
assign dat7_nxt[17:0] = beta5[24]?re5-im_shift5 : re5+im_shift5;
assign dat7_nxt[35:18] = beta5[24]?im5+re_shift5 : im5-re_shift5;
assign dat7_nxt[60:36] = beta_calc5;


// node:8 macro nco_cordic

// CORDIC stage 6
/*
{
    "sigma": 326,
    "shift": 12
}
*/

wire [24:0] beta6;
wire [24:0] beta_calc6;
wire [17:0] re6,im6,re_shift6,im_shift6;


assign  beta6 = dat7[24:0];

assign re6=dat7[17:0];
assign im6=dat7[35:18];

//assign re_shift6={{12{re6[17]}},re6 >> 12};
//assign im_shift6={{12{im6[17]}},im6 >> 12};

assign re_shift6=$signed(re6) >> 12;
assign im_shift6=$signed(im6) >> 12;

assign beta_calc6 = beta6[24]?beta6+326:beta6-326;
assign dat8_nxt[17:0] = beta6[24]?re6-im_shift6 : re6+im_shift6;
assign dat8_nxt[35:18] = beta6[24]?im6+re_shift6 : im6-re_shift6;
assign dat8_nxt[60:36] = beta_calc6;


// node:9 macro nco_cordic

// CORDIC stage 7
/*
{
    "sigma": 163,
    "shift": 13
}
*/

wire [24:0] beta7;
wire [24:0] beta_calc7;
wire [17:0] re7,im7,re_shift7,im_shift7;


assign  beta7 = dat8[24:0];

assign re7=dat8[17:0];
assign im7=dat8[35:18];

//assign re_shift7={{13{re7[17]}},re7 >> 13};
//assign im_shift7={{13{im7[17]}},im7 >> 13};

assign re_shift7=$signed(re7) >> 13;
assign im_shift7=$signed(im7) >> 13;

assign beta_calc7 = beta7[24]?beta7+163:beta7-163;
assign dat9_nxt[17:0] = beta7[24]?re7-im_shift7 : re7+im_shift7;
assign dat9_nxt[35:18] = beta7[24]?im7+re_shift7 : im7-re_shift7;
assign dat9_nxt[60:36] = beta_calc7;


// node:10 macro nco_cordic

// CORDIC stage 8
/*
{
    "sigma": 81,
    "shift": 14
}
*/

wire [24:0] beta8;
wire [24:0] beta_calc8;
wire [17:0] re8,im8,re_shift8,im_shift8;


assign  beta8 = dat9[24:0];

assign re8=dat9[17:0];
assign im8=dat9[35:18];

//assign re_shift8={{14{re8[17]}},re8 >> 14};
//assign im_shift8={{14{im8[17]}},im8 >> 14};

assign re_shift8=$signed(re8) >> 14;
assign im_shift8=$signed(im8) >> 14;

assign beta_calc8 = beta8[24]?beta8+81:beta8-81;
assign dat10_nxt[17:0] = beta8[24]?re8-im_shift8 : re8+im_shift8;
assign dat10_nxt[35:18] = beta8[24]?im8+re_shift8 : im8-re_shift8;
assign dat10_nxt[60:36] = beta_calc8;


// node:11 macro saturation

wire [17:0] recalc11,imcalc11;
wire [15:0] redata11,imdata11;

assign recalc11=dat10[17:0];
assign imcalc11=dat10[35:18];

assign dat11[15:0]=^recalc11[17:16]?{recalc11[17],{15{~recalc11[17]}}}:{recalc11[17],recalc11[15:1]};

assign dat11[31:16]=^imcalc11[17:16]?{imcalc11[17],{15{~imcalc11[17]}}}:{imcalc11[17],imcalc11[15:1]};

assign redata11 = dat11[15:0];
assign imdata11 = dat11[31:16];


assign i_nco_dat = dat11; // node:12 is initiator port
// per edge
wire en0; // edge:0 EB1
reg [31:0] dat0_r;
always @(posedge clk) if (en0) dat0_r <= dat0_nxt;
assign dat0 = dat0_r;

wire en1; // edge:1 EB1
reg [67:0] dat1_r;
always @(posedge clk) if (en1) dat1_r <= dat1_nxt;
assign dat1 = dat1_r;

wire en2; // edge:2 EB1
reg [67:0] dat2_r;
always @(posedge clk) if (en2) dat2_r <= dat2_nxt;
assign dat2 = dat2_r;

wire en3; // edge:3 EB1
reg [67:0] dat3_r;
always @(posedge clk) if (en3) dat3_r <= dat3_nxt;
assign dat3 = dat3_r;

wire en4; // edge:4 EB1
reg [67:0] dat4_r;
always @(posedge clk) if (en4) dat4_r <= dat4_nxt;
assign dat4 = dat4_r;

wire en5; // edge:5 EB1
reg [67:0] dat5_r;
always @(posedge clk) if (en5) dat5_r <= dat5_nxt;
assign dat5 = dat5_r;

wire en6; // edge:6 EB1
reg [67:0] dat6_r;
always @(posedge clk) if (en6) dat6_r <= dat6_nxt;
assign dat6 = dat6_r;

wire en7; // edge:7 EB1
reg [67:0] dat7_r;
always @(posedge clk) if (en7) dat7_r <= dat7_nxt;
assign dat7 = dat7_r;

wire en8; // edge:8 EB1
reg [67:0] dat8_r;
always @(posedge clk) if (en8) dat8_r <= dat8_nxt;
assign dat8 = dat8_r;

wire en9; // edge:9 EB1
reg [67:0] dat9_r;
always @(posedge clk) if (en9) dat9_r <= dat9_nxt;
assign dat9 = dat9_r;

wire en10; // edge:10 EB1
reg [67:0] dat10_r;
always @(posedge clk) if (en10) dat10_r <= dat10_nxt;
assign dat10 = dat10_r;


nco_ctrl uctrl (
    .clk(clk),
    .reset_n(reset_n),
    .t_angle_req(t_angle_req),
    .t_angle_ack(t_angle_ack),
    .i_nco_req(i_nco_req),
    .i_nco_ack(i_nco_ack),
    .en0(en0),
    .en1(en1),
    .en2(en2),
    .en3(en3),
    .en4(en4),
    .en5(en5),
    .en6(en6),
    .en7(en7),
    .en8(en8),
    .en9(en9),
    .en10(en10)
);
endmodule // nco

module nco_ctrl (
    // per node (target / initiator)
    input              clk,
    input              reset_n,
    input              t_angle_req,
    output             t_angle_ack,
    output             i_nco_req,
    input              i_nco_ack,
    output             en0,
    output             en1,
    output             en2,
    output             en3,
    output             en4,
    output             en5,
    output             en6,
    output             en7,
    output             en8,
    output             en9,
    output             en10
);
wire             req0, ack0, ack0_0, req0_0, req1, ack1, ack1_0, req1_0, req2, ack2, ack2_0, req2_0, req3, ack3, ack3_0, req3_0, req4, ack4, ack4_0, req4_0, req5, ack5, ack5_0, req5_0, req6, ack6, ack6_0, req6_0, req7, ack7, ack7_0, req7_0, req8, ack8, ack8_0, req8_0, req9, ack9, ack9_0, req9_0, req10, ack10, ack10_0, req10_0, req11, ack11, ack11_0, req11_0;
// node:t_angle target
assign req0 = t_angle_req;
assign t_angle_ack = ack0;
// edge:0 EB1
wire ack0m;
reg req0m;
assign en0 = req0 & ack0;
assign ack0 = ~req0m | ack0m;
always @(posedge clk or negedge reset_n) if (~reset_n) req0m <= 1'b0; else req0m <= ~ack0 | req0;

// edge:0 fork
assign req0_0 = req0m;
assign ack0m = ack0_0;
// edge:1 EB1
wire ack1m;
reg req1m;
assign en1 = req1 & ack1;
assign ack1 = ~req1m | ack1m;
always @(posedge clk or negedge reset_n) if (~reset_n) req1m <= 1'b0; else req1m <= ~ack1 | req1;

// edge:1 fork
assign req1_0 = req1m;
assign ack1m = ack1_0;
// edge:2 EB1
wire ack2m;
reg req2m;
assign en2 = req2 & ack2;
assign ack2 = ~req2m | ack2m;
always @(posedge clk or negedge reset_n) if (~reset_n) req2m <= 1'b0; else req2m <= ~ack2 | req2;

// edge:2 fork
assign req2_0 = req2m;
assign ack2m = ack2_0;
// edge:3 EB1
wire ack3m;
reg req3m;
assign en3 = req3 & ack3;
assign ack3 = ~req3m | ack3m;
always @(posedge clk or negedge reset_n) if (~reset_n) req3m <= 1'b0; else req3m <= ~ack3 | req3;

// edge:3 fork
assign req3_0 = req3m;
assign ack3m = ack3_0;
// edge:4 EB1
wire ack4m;
reg req4m;
assign en4 = req4 & ack4;
assign ack4 = ~req4m | ack4m;
always @(posedge clk or negedge reset_n) if (~reset_n) req4m <= 1'b0; else req4m <= ~ack4 | req4;

// edge:4 fork
assign req4_0 = req4m;
assign ack4m = ack4_0;
// edge:5 EB1
wire ack5m;
reg req5m;
assign en5 = req5 & ack5;
assign ack5 = ~req5m | ack5m;
always @(posedge clk or negedge reset_n) if (~reset_n) req5m <= 1'b0; else req5m <= ~ack5 | req5;

// edge:5 fork
assign req5_0 = req5m;
assign ack5m = ack5_0;
// edge:6 EB1
wire ack6m;
reg req6m;
assign en6 = req6 & ack6;
assign ack6 = ~req6m | ack6m;
always @(posedge clk or negedge reset_n) if (~reset_n) req6m <= 1'b0; else req6m <= ~ack6 | req6;

// edge:6 fork
assign req6_0 = req6m;
assign ack6m = ack6_0;
// edge:7 EB1
wire ack7m;
reg req7m;
assign en7 = req7 & ack7;
assign ack7 = ~req7m | ack7m;
always @(posedge clk or negedge reset_n) if (~reset_n) req7m <= 1'b0; else req7m <= ~ack7 | req7;

// edge:7 fork
assign req7_0 = req7m;
assign ack7m = ack7_0;
// edge:8 EB1
wire ack8m;
reg req8m;
assign en8 = req8 & ack8;
assign ack8 = ~req8m | ack8m;
always @(posedge clk or negedge reset_n) if (~reset_n) req8m <= 1'b0; else req8m <= ~ack8 | req8;

// edge:8 fork
assign req8_0 = req8m;
assign ack8m = ack8_0;
// edge:9 EB1
wire ack9m;
reg req9m;
assign en9 = req9 & ack9;
assign ack9 = ~req9m | ack9m;
always @(posedge clk or negedge reset_n) if (~reset_n) req9m <= 1'b0; else req9m <= ~ack9 | req9;

// edge:9 fork
assign req9_0 = req9m;
assign ack9m = ack9_0;
// edge:10 EB1
wire ack10m;
reg req10m;
assign en10 = req10 & ack10;
assign ack10 = ~req10m | ack10m;
always @(posedge clk or negedge reset_n) if (~reset_n) req10m <= 1'b0; else req10m <= ~ack10 | req10;

// edge:10 fork
assign req10_0 = req10m;
assign ack10m = ack10_0;
// edge:11 EB0
wire ack11m, req11m;
assign req11m = req11;
assign ack11 = ack11m;

// edge:11 fork
assign req11_0 = req11m;
assign ack11m = ack11_0;
// node:1 join nco_lut
// join:1, fork:1
assign req1 = req0_0;
assign ack0_0 = ack1;
// node:2 join nco_cordic
// join:1, fork:1
assign req2 = req1_0;
assign ack1_0 = ack2;
// node:3 join nco_cordic
// join:1, fork:1
assign req3 = req2_0;
assign ack2_0 = ack3;
// node:4 join nco_cordic
// join:1, fork:1
assign req4 = req3_0;
assign ack3_0 = ack4;
// node:5 join nco_cordic
// join:1, fork:1
assign req5 = req4_0;
assign ack4_0 = ack5;
// node:6 join nco_cordic
// join:1, fork:1
assign req6 = req5_0;
assign ack5_0 = ack6;
// node:7 join nco_cordic
// join:1, fork:1
assign req7 = req6_0;
assign ack6_0 = ack7;
// node:8 join nco_cordic
// join:1, fork:1
assign req8 = req7_0;
assign ack7_0 = ack8;
// node:9 join nco_cordic
// join:1, fork:1
assign req9 = req8_0;
assign ack8_0 = ack9;
// node:10 join nco_cordic
// join:1, fork:1
assign req10 = req9_0;
assign ack9_0 = ack10;
// node:11 join saturation
// join:1, fork:1
assign req11 = req10_0;
assign ack10_0 = ack11;
// node:12 initiator
assign i_nco_req = req11_0;
assign ack11_0 = i_nco_ack;
endmodule // nco_ctrl
