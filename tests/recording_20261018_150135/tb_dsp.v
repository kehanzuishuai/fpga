`timescale 1ns/1ps
module tb_dsp;
reg clk_12m288=0; always #5 clk_12m288=~clk_12m288;
wire GND=1'b0,VCC=1'b1,n1237_8=1'b1; reg n290_6=1;
reg [11:0] level_q=1700,lv_a=1800,lv_b=1850;
reg [19:0] ratio_q=32800,ratio_a=32816;
reg [1:0] note_c=0; wire [8:0] ratio_addr=0;
wire [47:0] DOUT_1,DOUT_2,DOUT_3,CASO_0,CASO_1,CASO_2;
wire [26:0] SOA_0,SOA_1,SOA_2;
wire [15:2] mp_lo,mp_hi; wire [21:2] mr;
GSR GSR(.GSRI(1'b1));
integer k;
initial begin
repeat(5) @(negedge clk_12m288); n290_6=0;
for(k=0;k<4;k=k+1) begin
note_c=k; repeat(4) @(negedge clk_12m288);
$display("PROBE ap=%0d ratio_delta_quarter=%0d expected=%0d level_delta_quarter=%0d expected=%0d",k,$signed(mr),(-16*k)>>>2,$signed(mp_lo),(-100*k)>>>2);
end
$finish; end
  MULTALU27X18 mp_lo_0_s (
    .DOUT({DOUT_1[47:16],mp_lo[15:2],DOUT_1[1:0]}),
    .CASO(CASO_0[47:0]),
    .SOA(SOA_0[26:0]),
    .A({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,level_q[11:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,ratio_addr[8],note_c[1:0]}),
    .C({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .D({VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,lv_a[11:0]}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,n1237_8}),
    .RESET({GND,n290_6}) 
);
defparam mp_lo_0_s.MULT_RESET_MODE="ASYNC";
defparam mp_lo_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam mp_lo_0_s.ACCSEL_IREG_CE="CE0";
defparam mp_lo_0_s.ACCSEL_IREG_RESET="RESET0";
defparam mp_lo_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam mp_lo_0_s.ADDSUB0_IREG_CE="CE0";
defparam mp_lo_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam mp_lo_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam mp_lo_0_s.ADDSUB1_IREG_CE="CE0";
defparam mp_lo_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam mp_lo_0_s.FB_PREG_EN="FALSE";
defparam mp_lo_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam mp_lo_0_s.ACCSEL_PREG_CE="CE0";
defparam mp_lo_0_s.ACCSEL_PREG_RESET="RESET0";
defparam mp_lo_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam mp_lo_0_s.ADDSUB0_PREG_CE="CE0";
defparam mp_lo_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam mp_lo_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam mp_lo_0_s.ADDSUB1_PREG_CE="CE0";
defparam mp_lo_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam mp_lo_0_s.OREG_CLK="BYPASS";
defparam mp_lo_0_s.OREG_CE="CE0";
defparam mp_lo_0_s.OREG_RESET="RESET0";
defparam mp_lo_0_s.PRE_LOAD=48'h000000000000;
defparam mp_lo_0_s.CASI_SEL=1'b0;
defparam mp_lo_0_s.AREG_CLK="CLK0";
defparam mp_lo_0_s.AREG_CE="CE0";
defparam mp_lo_0_s.AREG_RESET="RESET0";
defparam mp_lo_0_s.BREG_CLK="BYPASS";
defparam mp_lo_0_s.BREG_CE="CE0";
defparam mp_lo_0_s.BREG_RESET="RESET0";
defparam mp_lo_0_s.DREG_CLK="BYPASS";
defparam mp_lo_0_s.DREG_CE="CE0";
defparam mp_lo_0_s.DREG_RESET="RESET0";
defparam mp_lo_0_s.PREG_CLK="BYPASS";
defparam mp_lo_0_s.PREG_CE="CE0";
defparam mp_lo_0_s.PREG_RESET="RESET0";
defparam mp_lo_0_s.SOA_PREG_EN="FALSE";
defparam mp_lo_0_s.DYN_P_SEL="FALSE";
defparam mp_lo_0_s.P_SEL=1'b1;
defparam mp_lo_0_s.DYN_P_ADDSUB="FALSE";
defparam mp_lo_0_s.P_ADDSUB=1'b1;
defparam mp_lo_0_s.ACC_SEL=1'b0;
defparam mp_lo_0_s.ADD_SUB_0=1'b0;
defparam mp_lo_0_s.ADD_SUB_1=1'b0;
defparam mp_lo_0_s.A_SEL=1'b0;
defparam mp_lo_0_s.CASISEL_IREG_CE="CE0";
defparam mp_lo_0_s.CASISEL_IREG_CLK="BYPASS";
defparam mp_lo_0_s.CASISEL_IREG_RESET="RESET0";
defparam mp_lo_0_s.CASISEL_PREG_CE="CE0";
defparam mp_lo_0_s.CASISEL_PREG_CLK="BYPASS";
defparam mp_lo_0_s.CASISEL_PREG_RESET="RESET0";
defparam mp_lo_0_s.CSEL_IREG_CE="CE0";
defparam mp_lo_0_s.CSEL_IREG_CLK="BYPASS";
defparam mp_lo_0_s.CSEL_IREG_RESET="RESET0";
defparam mp_lo_0_s.CSEL_PREG_CE="CE0";
defparam mp_lo_0_s.CSEL_PREG_CLK="BYPASS";
defparam mp_lo_0_s.CSEL_PREG_RESET="RESET0";
defparam mp_lo_0_s.C_IREG_CE="CE0";
defparam mp_lo_0_s.C_IREG_CLK="BYPASS";
defparam mp_lo_0_s.C_IREG_RESET="RESET0";
defparam mp_lo_0_s.C_PREG_CE="CE0";
defparam mp_lo_0_s.C_PREG_CLK="BYPASS";
defparam mp_lo_0_s.C_PREG_RESET="RESET0";
defparam mp_lo_0_s.C_SEL=1'b0;
defparam mp_lo_0_s.DYN_ACC_SEL="FALSE";
defparam mp_lo_0_s.DYN_ADD_SUB_0="FALSE";
defparam mp_lo_0_s.DYN_ADD_SUB_1="FALSE";
defparam mp_lo_0_s.DYN_A_SEL="FALSE";
defparam mp_lo_0_s.DYN_CASI_SEL="FALSE";
defparam mp_lo_0_s.DYN_C_SEL="FALSE";
defparam mp_lo_0_s.MULT12X12_EN="FALSE";
defparam mp_lo_0_s.PADDSUB_IREG_CE="CE0";
defparam mp_lo_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam mp_lo_0_s.PADDSUB_IREG_RESET="RESET0";
defparam mp_lo_0_s.PSEL_IREG_CE="CE0";
defparam mp_lo_0_s.PSEL_IREG_CLK="BYPASS";
defparam mp_lo_0_s.PSEL_IREG_RESET="RESET0";
  MULTALU27X18 mp_hi_0_s (
    .DOUT({DOUT_2[47:16],mp_hi[15:2],DOUT_2[1:0]}),
    .CASO(CASO_1[47:0]),
    .SOA(SOA_1[26:0]),
    .A({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,level_q[11:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,ratio_addr[8],note_c[1:0]}),
    .C({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .D({VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,VCC,lv_b[11:0]}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,n1225_13}),
    .RESET({GND,n290_6}) 
);
defparam mp_hi_0_s.MULT_RESET_MODE="ASYNC";
defparam mp_hi_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam mp_hi_0_s.ACCSEL_IREG_CE="CE0";
defparam mp_hi_0_s.ACCSEL_IREG_RESET="RESET0";
defparam mp_hi_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam mp_hi_0_s.ADDSUB0_IREG_CE="CE0";
defparam mp_hi_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam mp_hi_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam mp_hi_0_s.ADDSUB1_IREG_CE="CE0";
defparam mp_hi_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam mp_hi_0_s.FB_PREG_EN="FALSE";
defparam mp_hi_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam mp_hi_0_s.ACCSEL_PREG_CE="CE0";
defparam mp_hi_0_s.ACCSEL_PREG_RESET="RESET0";
defparam mp_hi_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam mp_hi_0_s.ADDSUB0_PREG_CE="CE0";
defparam mp_hi_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam mp_hi_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam mp_hi_0_s.ADDSUB1_PREG_CE="CE0";
defparam mp_hi_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam mp_hi_0_s.OREG_CLK="BYPASS";
defparam mp_hi_0_s.OREG_CE="CE0";
defparam mp_hi_0_s.OREG_RESET="RESET0";
defparam mp_hi_0_s.PRE_LOAD=48'h000000000000;
defparam mp_hi_0_s.CASI_SEL=1'b0;
defparam mp_hi_0_s.AREG_CLK="CLK0";
defparam mp_hi_0_s.AREG_CE="CE0";
defparam mp_hi_0_s.AREG_RESET="RESET0";
defparam mp_hi_0_s.BREG_CLK="BYPASS";
defparam mp_hi_0_s.BREG_CE="CE0";
defparam mp_hi_0_s.BREG_RESET="RESET0";
defparam mp_hi_0_s.DREG_CLK="BYPASS";
defparam mp_hi_0_s.DREG_CE="CE0";
defparam mp_hi_0_s.DREG_RESET="RESET0";
defparam mp_hi_0_s.PREG_CLK="BYPASS";
defparam mp_hi_0_s.PREG_CE="CE0";
defparam mp_hi_0_s.PREG_RESET="RESET0";
defparam mp_hi_0_s.SOA_PREG_EN="FALSE";
defparam mp_hi_0_s.DYN_P_SEL="FALSE";
defparam mp_hi_0_s.P_SEL=1'b1;
defparam mp_hi_0_s.DYN_P_ADDSUB="FALSE";
defparam mp_hi_0_s.P_ADDSUB=1'b1;
defparam mp_hi_0_s.ACC_SEL=1'b0;
defparam mp_hi_0_s.ADD_SUB_0=1'b0;
defparam mp_hi_0_s.ADD_SUB_1=1'b0;
defparam mp_hi_0_s.A_SEL=1'b0;
defparam mp_hi_0_s.CASISEL_IREG_CE="CE0";
defparam mp_hi_0_s.CASISEL_IREG_CLK="BYPASS";
defparam mp_hi_0_s.CASISEL_IREG_RESET="RESET0";
defparam mp_hi_0_s.CASISEL_PREG_CE="CE0";
defparam mp_hi_0_s.CASISEL_PREG_CLK="BYPASS";
defparam mp_hi_0_s.CASISEL_PREG_RESET="RESET0";
defparam mp_hi_0_s.CSEL_IREG_CE="CE0";
defparam mp_hi_0_s.CSEL_IREG_CLK="BYPASS";
defparam mp_hi_0_s.CSEL_IREG_RESET="RESET0";
defparam mp_hi_0_s.CSEL_PREG_CE="CE0";
defparam mp_hi_0_s.CSEL_PREG_CLK="BYPASS";
defparam mp_hi_0_s.CSEL_PREG_RESET="RESET0";
defparam mp_hi_0_s.C_IREG_CE="CE0";
defparam mp_hi_0_s.C_IREG_CLK="BYPASS";
defparam mp_hi_0_s.C_IREG_RESET="RESET0";
defparam mp_hi_0_s.C_PREG_CE="CE0";
defparam mp_hi_0_s.C_PREG_CLK="BYPASS";
defparam mp_hi_0_s.C_PREG_RESET="RESET0";
defparam mp_hi_0_s.C_SEL=1'b0;
defparam mp_hi_0_s.DYN_ACC_SEL="FALSE";
defparam mp_hi_0_s.DYN_ADD_SUB_0="FALSE";
defparam mp_hi_0_s.DYN_ADD_SUB_1="FALSE";
defparam mp_hi_0_s.DYN_A_SEL="FALSE";
defparam mp_hi_0_s.DYN_CASI_SEL="FALSE";
defparam mp_hi_0_s.DYN_C_SEL="FALSE";
defparam mp_hi_0_s.MULT12X12_EN="FALSE";
defparam mp_hi_0_s.PADDSUB_IREG_CE="CE0";
defparam mp_hi_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam mp_hi_0_s.PADDSUB_IREG_RESET="RESET0";
defparam mp_hi_0_s.PSEL_IREG_CE="CE0";
defparam mp_hi_0_s.PSEL_IREG_CLK="BYPASS";
defparam mp_hi_0_s.PSEL_IREG_RESET="RESET0";
  MULTALU27X18 mr_0_s (
    .DOUT({DOUT_3[47:22],mr[21:2],DOUT_3[1:0]}),
    .CASO(CASO_2[47:0]),
    .SOA(SOA_2[26:0]),
    .A({GND,GND,GND,GND,GND,GND,GND,ratio_q[19:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,ratio_addr[8],note_c[1:0]}),
    .C({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .D({VCC,VCC,VCC,VCC,VCC,VCC,ratio_a[19:0]}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,VCC}),
    .RESET({GND,n290_6}) 
);
defparam mr_0_s.MULT_RESET_MODE="ASYNC";
defparam mr_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam mr_0_s.ACCSEL_IREG_CE="CE0";
defparam mr_0_s.ACCSEL_IREG_RESET="RESET0";
defparam mr_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam mr_0_s.ADDSUB0_IREG_CE="CE0";
defparam mr_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam mr_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam mr_0_s.ADDSUB1_IREG_CE="CE0";
defparam mr_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam mr_0_s.FB_PREG_EN="FALSE";
defparam mr_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam mr_0_s.ACCSEL_PREG_CE="CE0";
defparam mr_0_s.ACCSEL_PREG_RESET="RESET0";
defparam mr_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam mr_0_s.ADDSUB0_PREG_CE="CE0";
defparam mr_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam mr_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam mr_0_s.ADDSUB1_PREG_CE="CE0";
defparam mr_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam mr_0_s.OREG_CLK="BYPASS";
defparam mr_0_s.OREG_CE="CE0";
defparam mr_0_s.OREG_RESET="RESET0";
defparam mr_0_s.PRE_LOAD=48'h000000000000;
defparam mr_0_s.CASI_SEL=1'b0;
defparam mr_0_s.AREG_CLK="BYPASS";
defparam mr_0_s.AREG_CE="CE0";
defparam mr_0_s.AREG_RESET="RESET0";
defparam mr_0_s.BREG_CLK="BYPASS";
defparam mr_0_s.BREG_CE="CE0";
defparam mr_0_s.BREG_RESET="RESET0";
defparam mr_0_s.DREG_CLK="BYPASS";
defparam mr_0_s.DREG_CE="CE0";
defparam mr_0_s.DREG_RESET="RESET0";
defparam mr_0_s.PREG_CLK="BYPASS";
defparam mr_0_s.PREG_CE="CE0";
defparam mr_0_s.PREG_RESET="RESET0";
defparam mr_0_s.SOA_PREG_EN="FALSE";
defparam mr_0_s.DYN_P_SEL="FALSE";
defparam mr_0_s.P_SEL=1'b1;
defparam mr_0_s.DYN_P_ADDSUB="FALSE";
defparam mr_0_s.P_ADDSUB=1'b1;
defparam mr_0_s.ACC_SEL=1'b0;
defparam mr_0_s.ADD_SUB_0=1'b0;
defparam mr_0_s.ADD_SUB_1=1'b0;
defparam mr_0_s.A_SEL=1'b0;
defparam mr_0_s.CASISEL_IREG_CE="CE0";
defparam mr_0_s.CASISEL_IREG_CLK="BYPASS";
defparam mr_0_s.CASISEL_IREG_RESET="RESET0";
defparam mr_0_s.CASISEL_PREG_CE="CE0";
defparam mr_0_s.CASISEL_PREG_CLK="BYPASS";
defparam mr_0_s.CASISEL_PREG_RESET="RESET0";
defparam mr_0_s.CSEL_IREG_CE="CE0";
defparam mr_0_s.CSEL_IREG_CLK="BYPASS";
defparam mr_0_s.CSEL_IREG_RESET="RESET0";
defparam mr_0_s.CSEL_PREG_CE="CE0";
defparam mr_0_s.CSEL_PREG_CLK="BYPASS";
defparam mr_0_s.CSEL_PREG_RESET="RESET0";
defparam mr_0_s.C_IREG_CE="CE0";
defparam mr_0_s.C_IREG_CLK="BYPASS";
defparam mr_0_s.C_IREG_RESET="RESET0";
defparam mr_0_s.C_PREG_CE="CE0";
defparam mr_0_s.C_PREG_CLK="BYPASS";
defparam mr_0_s.C_PREG_RESET="RESET0";
defparam mr_0_s.C_SEL=1'b0;
defparam mr_0_s.DYN_ACC_SEL="FALSE";
defparam mr_0_s.DYN_ADD_SUB_0="FALSE";
defparam mr_0_s.DYN_ADD_SUB_1="FALSE";
defparam mr_0_s.DYN_A_SEL="FALSE";
defparam mr_0_s.DYN_CASI_SEL="FALSE";
defparam mr_0_s.DYN_C_SEL="FALSE";
defparam mr_0_s.MULT12X12_EN="FALSE";
defparam mr_0_s.PADDSUB_IREG_CE="CE0";
defparam mr_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam mr_0_s.PADDSUB_IREG_RESET="RESET0";
defparam mr_0_s.PSEL_IREG_CE="CE0";
defparam mr_0_s.PSEL_IREG_CLK="BYPASS";
defparam mr_0_s.PSEL_IREG_RESET="RESET0";
endmodule
