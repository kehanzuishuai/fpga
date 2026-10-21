module piano_level_rom (
  clk_12m288,
  level_addr,
  level_q
)
;
input clk_12m288;
input [14:0] level_addr;
output [11:0] level_q;
wire q_11_41;
wire q_11_42;
wire q_11_43;
wire q_11_44;
wire q_11_45;
wire q_11_46;
wire q_11_47;
wire q_11_48;
wire q_11_49;
wire q_11_50;
wire q_10_41;
wire q_10_42;
wire q_10_43;
wire q_10_44;
wire q_10_45;
wire q_10_46;
wire q_10_47;
wire q_10_48;
wire q_10_49;
wire q_10_50;
wire q_9_41;
wire q_9_42;
wire q_9_43;
wire q_9_44;
wire q_9_45;
wire q_9_46;
wire q_9_47;
wire q_9_48;
wire q_9_49;
wire q_9_50;
wire q_8_41;
wire q_8_42;
wire q_8_43;
wire q_8_44;
wire q_8_45;
wire q_8_46;
wire q_8_47;
wire q_8_48;
wire q_8_49;
wire q_8_50;
wire q_7_41;
wire q_7_42;
wire q_7_43;
wire q_7_44;
wire q_7_45;
wire q_7_46;
wire q_7_47;
wire q_7_48;
wire q_7_49;
wire q_7_50;
wire q_6_41;
wire q_6_42;
wire q_6_43;
wire q_6_44;
wire q_6_45;
wire q_6_46;
wire q_6_47;
wire q_6_48;
wire q_6_49;
wire q_6_50;
wire q_5_41;
wire q_5_42;
wire q_5_43;
wire q_5_44;
wire q_5_45;
wire q_5_46;
wire q_5_47;
wire q_5_48;
wire q_5_49;
wire q_5_50;
wire q_4_41;
wire q_4_42;
wire q_4_43;
wire q_4_44;
wire q_4_45;
wire q_4_46;
wire q_4_47;
wire q_4_48;
wire q_4_49;
wire q_4_50;
wire q_3_41;
wire q_3_42;
wire q_3_43;
wire q_3_44;
wire q_3_45;
wire q_3_46;
wire q_3_47;
wire q_3_48;
wire q_3_49;
wire q_3_50;
wire q_2_41;
wire q_2_42;
wire q_2_43;
wire q_2_44;
wire q_2_45;
wire q_2_46;
wire q_2_47;
wire q_2_48;
wire q_2_49;
wire q_2_50;
wire q_1_41;
wire q_1_42;
wire q_1_43;
wire q_1_44;
wire q_1_45;
wire q_1_46;
wire q_1_47;
wire q_1_48;
wire q_1_49;
wire q_1_50;
wire q_0_41;
wire q_0_42;
wire q_0_43;
wire q_0_44;
wire q_0_45;
wire q_0_46;
wire q_0_47;
wire q_0_48;
wire q_0_49;
wire q_0_50;
wire level_q_11_4;
wire level_q_10_4;
wire level_q_9_4;
wire level_q_8_4;
wire level_q_7_4;
wire level_q_6_4;
wire level_q_5_4;
wire level_q_4_4;
wire level_q_3_4;
wire level_q_2_4;
wire level_q_1_4;
wire level_q_0_4;
wire level_q_11_5;
wire q_11_52;
wire q_11_54;
wire q_11_56;
wire q_11_58;
wire q_11_60;
wire q_10_52;
wire q_10_54;
wire q_10_56;
wire q_10_58;
wire q_10_60;
wire q_9_52;
wire q_9_54;
wire q_9_56;
wire q_9_58;
wire q_9_60;
wire q_8_52;
wire q_8_54;
wire q_8_56;
wire q_8_58;
wire q_8_60;
wire q_7_52;
wire q_7_54;
wire q_7_56;
wire q_7_58;
wire q_7_60;
wire q_6_52;
wire q_6_54;
wire q_6_56;
wire q_6_58;
wire q_6_60;
wire q_5_52;
wire q_5_54;
wire q_5_56;
wire q_5_58;
wire q_5_60;
wire q_4_52;
wire q_4_54;
wire q_4_56;
wire q_4_58;
wire q_4_60;
wire q_3_52;
wire q_3_54;
wire q_3_56;
wire q_3_58;
wire q_3_60;
wire q_2_52;
wire q_2_54;
wire q_2_56;
wire q_2_58;
wire q_2_60;
wire q_1_52;
wire q_1_54;
wire q_1_56;
wire q_1_58;
wire q_1_60;
wire q_0_52;
wire q_0_54;
wire q_0_56;
wire q_0_58;
wire q_0_60;
wire q_11_62;
wire q_11_64;
wire q_10_62;
wire q_10_64;
wire q_9_62;
wire q_9_64;
wire q_8_62;
wire q_8_64;
wire q_7_62;
wire q_7_64;
wire q_6_62;
wire q_6_64;
wire q_5_62;
wire q_5_64;
wire q_4_62;
wire q_4_64;
wire q_3_62;
wire q_3_64;
wire q_2_62;
wire q_2_64;
wire q_1_62;
wire q_1_64;
wire q_0_62;
wire q_0_64;
wire q_11_66;
wire q_10_66;
wire q_9_66;
wire q_8_66;
wire q_7_66;
wire q_6_66;
wire q_5_66;
wire q_4_66;
wire q_3_66;
wire q_2_66;
wire q_1_66;
wire q_0_66;
wire [4:0] sel;
wire [11:0] q19;
wire [11:0] q20;
wire [11:0] q18;
wire [11:0] q16;
wire [11:0] q17;
wire [11:0] q15;
wire [11:0] q13;
wire [11:0] q14;
wire [11:0] q12;
wire [11:0] q10;
wire [11:0] q11;
wire [11:0] q9;
wire [11:0] q7;
wire [11:0] q8;
wire [11:0] q6;
wire [11:0] q4;
wire [11:0] q5;
wire [11:0] q3;
wire [11:0] q1;
wire [11:0] q2;
wire [11:0] q0;
wire [35:18] DO;
wire [35:18] DO_0;
wire [35:18] DO_1;
wire [35:18] DO_2;
wire [35:18] DO_3;
wire [35:18] DO_4;
wire [35:18] DO_5;
wire [35:18] DO_6;
wire [35:18] DO_7;
wire [35:18] DO_8;
wire [35:18] DO_9;
wire [35:18] DO_10;
wire [35:18] DO_11;
wire [35:18] DO_12;
wire VCC;
wire GND;
  LUT3 q_11_s58 (
    .F(q_11_41),
    .I0(q0[11]),
    .I1(q1[11]),
    .I2(sel[0]) 
);
defparam q_11_s58.INIT=8'hCA;
  LUT3 q_11_s59 (
    .F(q_11_42),
    .I0(q2[11]),
    .I1(q3[11]),
    .I2(sel[0]) 
);
defparam q_11_s59.INIT=8'hCA;
  LUT3 q_11_s60 (
    .F(q_11_43),
    .I0(q4[11]),
    .I1(q5[11]),
    .I2(sel[0]) 
);
defparam q_11_s60.INIT=8'hCA;
  LUT3 q_11_s61 (
    .F(q_11_44),
    .I0(q6[11]),
    .I1(q7[11]),
    .I2(sel[0]) 
);
defparam q_11_s61.INIT=8'hCA;
  LUT3 q_11_s62 (
    .F(q_11_45),
    .I0(q8[11]),
    .I1(q9[11]),
    .I2(sel[0]) 
);
defparam q_11_s62.INIT=8'hCA;
  LUT3 q_11_s63 (
    .F(q_11_46),
    .I0(q10[11]),
    .I1(q11[11]),
    .I2(sel[0]) 
);
defparam q_11_s63.INIT=8'hCA;
  LUT3 q_11_s64 (
    .F(q_11_47),
    .I0(q12[11]),
    .I1(q13[11]),
    .I2(sel[0]) 
);
defparam q_11_s64.INIT=8'hCA;
  LUT3 q_11_s65 (
    .F(q_11_48),
    .I0(q14[11]),
    .I1(q15[11]),
    .I2(sel[0]) 
);
defparam q_11_s65.INIT=8'hCA;
  LUT3 q_11_s66 (
    .F(q_11_49),
    .I0(q16[11]),
    .I1(q17[11]),
    .I2(sel[0]) 
);
defparam q_11_s66.INIT=8'hCA;
  LUT3 q_11_s67 (
    .F(q_11_50),
    .I0(q18[11]),
    .I1(q19[11]),
    .I2(sel[0]) 
);
defparam q_11_s67.INIT=8'hCA;
  LUT3 q_10_s58 (
    .F(q_10_41),
    .I0(q0[10]),
    .I1(q1[10]),
    .I2(sel[0]) 
);
defparam q_10_s58.INIT=8'hCA;
  LUT3 q_10_s59 (
    .F(q_10_42),
    .I0(q2[10]),
    .I1(q3[10]),
    .I2(sel[0]) 
);
defparam q_10_s59.INIT=8'hCA;
  LUT3 q_10_s60 (
    .F(q_10_43),
    .I0(q4[10]),
    .I1(q5[10]),
    .I2(sel[0]) 
);
defparam q_10_s60.INIT=8'hCA;
  LUT3 q_10_s61 (
    .F(q_10_44),
    .I0(q6[10]),
    .I1(q7[10]),
    .I2(sel[0]) 
);
defparam q_10_s61.INIT=8'hCA;
  LUT3 q_10_s62 (
    .F(q_10_45),
    .I0(q8[10]),
    .I1(q9[10]),
    .I2(sel[0]) 
);
defparam q_10_s62.INIT=8'hCA;
  LUT3 q_10_s63 (
    .F(q_10_46),
    .I0(q10[10]),
    .I1(q11[10]),
    .I2(sel[0]) 
);
defparam q_10_s63.INIT=8'hCA;
  LUT3 q_10_s64 (
    .F(q_10_47),
    .I0(q12[10]),
    .I1(q13[10]),
    .I2(sel[0]) 
);
defparam q_10_s64.INIT=8'hCA;
  LUT3 q_10_s65 (
    .F(q_10_48),
    .I0(q14[10]),
    .I1(q15[10]),
    .I2(sel[0]) 
);
defparam q_10_s65.INIT=8'hCA;
  LUT3 q_10_s66 (
    .F(q_10_49),
    .I0(q16[10]),
    .I1(q17[10]),
    .I2(sel[0]) 
);
defparam q_10_s66.INIT=8'hCA;
  LUT3 q_10_s67 (
    .F(q_10_50),
    .I0(q18[10]),
    .I1(q19[10]),
    .I2(sel[0]) 
);
defparam q_10_s67.INIT=8'hCA;
  LUT3 q_9_s58 (
    .F(q_9_41),
    .I0(q0[9]),
    .I1(q1[9]),
    .I2(sel[0]) 
);
defparam q_9_s58.INIT=8'hCA;
  LUT3 q_9_s59 (
    .F(q_9_42),
    .I0(q2[9]),
    .I1(q3[9]),
    .I2(sel[0]) 
);
defparam q_9_s59.INIT=8'hCA;
  LUT3 q_9_s60 (
    .F(q_9_43),
    .I0(q4[9]),
    .I1(q5[9]),
    .I2(sel[0]) 
);
defparam q_9_s60.INIT=8'hCA;
  LUT3 q_9_s61 (
    .F(q_9_44),
    .I0(q6[9]),
    .I1(q7[9]),
    .I2(sel[0]) 
);
defparam q_9_s61.INIT=8'hCA;
  LUT3 q_9_s62 (
    .F(q_9_45),
    .I0(q8[9]),
    .I1(q9[9]),
    .I2(sel[0]) 
);
defparam q_9_s62.INIT=8'hCA;
  LUT3 q_9_s63 (
    .F(q_9_46),
    .I0(q10[9]),
    .I1(q11[9]),
    .I2(sel[0]) 
);
defparam q_9_s63.INIT=8'hCA;
  LUT3 q_9_s64 (
    .F(q_9_47),
    .I0(q12[9]),
    .I1(q13[9]),
    .I2(sel[0]) 
);
defparam q_9_s64.INIT=8'hCA;
  LUT3 q_9_s65 (
    .F(q_9_48),
    .I0(q14[9]),
    .I1(q15[9]),
    .I2(sel[0]) 
);
defparam q_9_s65.INIT=8'hCA;
  LUT3 q_9_s66 (
    .F(q_9_49),
    .I0(q16[9]),
    .I1(q17[9]),
    .I2(sel[0]) 
);
defparam q_9_s66.INIT=8'hCA;
  LUT3 q_9_s67 (
    .F(q_9_50),
    .I0(q18[9]),
    .I1(q19[9]),
    .I2(sel[0]) 
);
defparam q_9_s67.INIT=8'hCA;
  LUT3 q_8_s58 (
    .F(q_8_41),
    .I0(q0[8]),
    .I1(q1[8]),
    .I2(sel[0]) 
);
defparam q_8_s58.INIT=8'hCA;
  LUT3 q_8_s59 (
    .F(q_8_42),
    .I0(q2[8]),
    .I1(q3[8]),
    .I2(sel[0]) 
);
defparam q_8_s59.INIT=8'hCA;
  LUT3 q_8_s60 (
    .F(q_8_43),
    .I0(q4[8]),
    .I1(q5[8]),
    .I2(sel[0]) 
);
defparam q_8_s60.INIT=8'hCA;
  LUT3 q_8_s61 (
    .F(q_8_44),
    .I0(q6[8]),
    .I1(q7[8]),
    .I2(sel[0]) 
);
defparam q_8_s61.INIT=8'hCA;
  LUT3 q_8_s62 (
    .F(q_8_45),
    .I0(q8[8]),
    .I1(q9[8]),
    .I2(sel[0]) 
);
defparam q_8_s62.INIT=8'hCA;
  LUT3 q_8_s63 (
    .F(q_8_46),
    .I0(q10[8]),
    .I1(q11[8]),
    .I2(sel[0]) 
);
defparam q_8_s63.INIT=8'hCA;
  LUT3 q_8_s64 (
    .F(q_8_47),
    .I0(q12[8]),
    .I1(q13[8]),
    .I2(sel[0]) 
);
defparam q_8_s64.INIT=8'hCA;
  LUT3 q_8_s65 (
    .F(q_8_48),
    .I0(q14[8]),
    .I1(q15[8]),
    .I2(sel[0]) 
);
defparam q_8_s65.INIT=8'hCA;
  LUT3 q_8_s66 (
    .F(q_8_49),
    .I0(q16[8]),
    .I1(q17[8]),
    .I2(sel[0]) 
);
defparam q_8_s66.INIT=8'hCA;
  LUT3 q_8_s67 (
    .F(q_8_50),
    .I0(q18[8]),
    .I1(q19[8]),
    .I2(sel[0]) 
);
defparam q_8_s67.INIT=8'hCA;
  LUT3 q_7_s58 (
    .F(q_7_41),
    .I0(q0[7]),
    .I1(q1[7]),
    .I2(sel[0]) 
);
defparam q_7_s58.INIT=8'hCA;
  LUT3 q_7_s59 (
    .F(q_7_42),
    .I0(q2[7]),
    .I1(q3[7]),
    .I2(sel[0]) 
);
defparam q_7_s59.INIT=8'hCA;
  LUT3 q_7_s60 (
    .F(q_7_43),
    .I0(q4[7]),
    .I1(q5[7]),
    .I2(sel[0]) 
);
defparam q_7_s60.INIT=8'hCA;
  LUT3 q_7_s61 (
    .F(q_7_44),
    .I0(q6[7]),
    .I1(q7[7]),
    .I2(sel[0]) 
);
defparam q_7_s61.INIT=8'hCA;
  LUT3 q_7_s62 (
    .F(q_7_45),
    .I0(q8[7]),
    .I1(q9[7]),
    .I2(sel[0]) 
);
defparam q_7_s62.INIT=8'hCA;
  LUT3 q_7_s63 (
    .F(q_7_46),
    .I0(q10[7]),
    .I1(q11[7]),
    .I2(sel[0]) 
);
defparam q_7_s63.INIT=8'hCA;
  LUT3 q_7_s64 (
    .F(q_7_47),
    .I0(q12[7]),
    .I1(q13[7]),
    .I2(sel[0]) 
);
defparam q_7_s64.INIT=8'hCA;
  LUT3 q_7_s65 (
    .F(q_7_48),
    .I0(q14[7]),
    .I1(q15[7]),
    .I2(sel[0]) 
);
defparam q_7_s65.INIT=8'hCA;
  LUT3 q_7_s66 (
    .F(q_7_49),
    .I0(q16[7]),
    .I1(q17[7]),
    .I2(sel[0]) 
);
defparam q_7_s66.INIT=8'hCA;
  LUT3 q_7_s67 (
    .F(q_7_50),
    .I0(q18[7]),
    .I1(q19[7]),
    .I2(sel[0]) 
);
defparam q_7_s67.INIT=8'hCA;
  LUT3 q_6_s58 (
    .F(q_6_41),
    .I0(q0[6]),
    .I1(q1[6]),
    .I2(sel[0]) 
);
defparam q_6_s58.INIT=8'hCA;
  LUT3 q_6_s59 (
    .F(q_6_42),
    .I0(q2[6]),
    .I1(q3[6]),
    .I2(sel[0]) 
);
defparam q_6_s59.INIT=8'hCA;
  LUT3 q_6_s60 (
    .F(q_6_43),
    .I0(q4[6]),
    .I1(q5[6]),
    .I2(sel[0]) 
);
defparam q_6_s60.INIT=8'hCA;
  LUT3 q_6_s61 (
    .F(q_6_44),
    .I0(q6[6]),
    .I1(q7[6]),
    .I2(sel[0]) 
);
defparam q_6_s61.INIT=8'hCA;
  LUT3 q_6_s62 (
    .F(q_6_45),
    .I0(q8[6]),
    .I1(q9[6]),
    .I2(sel[0]) 
);
defparam q_6_s62.INIT=8'hCA;
  LUT3 q_6_s63 (
    .F(q_6_46),
    .I0(q10[6]),
    .I1(q11[6]),
    .I2(sel[0]) 
);
defparam q_6_s63.INIT=8'hCA;
  LUT3 q_6_s64 (
    .F(q_6_47),
    .I0(q12[6]),
    .I1(q13[6]),
    .I2(sel[0]) 
);
defparam q_6_s64.INIT=8'hCA;
  LUT3 q_6_s65 (
    .F(q_6_48),
    .I0(q14[6]),
    .I1(q15[6]),
    .I2(sel[0]) 
);
defparam q_6_s65.INIT=8'hCA;
  LUT3 q_6_s66 (
    .F(q_6_49),
    .I0(q16[6]),
    .I1(q17[6]),
    .I2(sel[0]) 
);
defparam q_6_s66.INIT=8'hCA;
  LUT3 q_6_s67 (
    .F(q_6_50),
    .I0(q18[6]),
    .I1(q19[6]),
    .I2(sel[0]) 
);
defparam q_6_s67.INIT=8'hCA;
  LUT3 q_5_s58 (
    .F(q_5_41),
    .I0(q0[5]),
    .I1(q1[5]),
    .I2(sel[0]) 
);
defparam q_5_s58.INIT=8'hCA;
  LUT3 q_5_s59 (
    .F(q_5_42),
    .I0(q2[5]),
    .I1(q3[5]),
    .I2(sel[0]) 
);
defparam q_5_s59.INIT=8'hCA;
  LUT3 q_5_s60 (
    .F(q_5_43),
    .I0(q4[5]),
    .I1(q5[5]),
    .I2(sel[0]) 
);
defparam q_5_s60.INIT=8'hCA;
  LUT3 q_5_s61 (
    .F(q_5_44),
    .I0(q6[5]),
    .I1(q7[5]),
    .I2(sel[0]) 
);
defparam q_5_s61.INIT=8'hCA;
  LUT3 q_5_s62 (
    .F(q_5_45),
    .I0(q8[5]),
    .I1(q9[5]),
    .I2(sel[0]) 
);
defparam q_5_s62.INIT=8'hCA;
  LUT3 q_5_s63 (
    .F(q_5_46),
    .I0(q10[5]),
    .I1(q11[5]),
    .I2(sel[0]) 
);
defparam q_5_s63.INIT=8'hCA;
  LUT3 q_5_s64 (
    .F(q_5_47),
    .I0(q12[5]),
    .I1(q13[5]),
    .I2(sel[0]) 
);
defparam q_5_s64.INIT=8'hCA;
  LUT3 q_5_s65 (
    .F(q_5_48),
    .I0(q14[5]),
    .I1(q15[5]),
    .I2(sel[0]) 
);
defparam q_5_s65.INIT=8'hCA;
  LUT3 q_5_s66 (
    .F(q_5_49),
    .I0(q16[5]),
    .I1(q17[5]),
    .I2(sel[0]) 
);
defparam q_5_s66.INIT=8'hCA;
  LUT3 q_5_s67 (
    .F(q_5_50),
    .I0(q18[5]),
    .I1(q19[5]),
    .I2(sel[0]) 
);
defparam q_5_s67.INIT=8'hCA;
  LUT3 q_4_s58 (
    .F(q_4_41),
    .I0(q0[4]),
    .I1(q1[4]),
    .I2(sel[0]) 
);
defparam q_4_s58.INIT=8'hCA;
  LUT3 q_4_s59 (
    .F(q_4_42),
    .I0(q2[4]),
    .I1(q3[4]),
    .I2(sel[0]) 
);
defparam q_4_s59.INIT=8'hCA;
  LUT3 q_4_s60 (
    .F(q_4_43),
    .I0(q4[4]),
    .I1(q5[4]),
    .I2(sel[0]) 
);
defparam q_4_s60.INIT=8'hCA;
  LUT3 q_4_s61 (
    .F(q_4_44),
    .I0(q6[4]),
    .I1(q7[4]),
    .I2(sel[0]) 
);
defparam q_4_s61.INIT=8'hCA;
  LUT3 q_4_s62 (
    .F(q_4_45),
    .I0(q8[4]),
    .I1(q9[4]),
    .I2(sel[0]) 
);
defparam q_4_s62.INIT=8'hCA;
  LUT3 q_4_s63 (
    .F(q_4_46),
    .I0(q10[4]),
    .I1(q11[4]),
    .I2(sel[0]) 
);
defparam q_4_s63.INIT=8'hCA;
  LUT3 q_4_s64 (
    .F(q_4_47),
    .I0(q12[4]),
    .I1(q13[4]),
    .I2(sel[0]) 
);
defparam q_4_s64.INIT=8'hCA;
  LUT3 q_4_s65 (
    .F(q_4_48),
    .I0(q14[4]),
    .I1(q15[4]),
    .I2(sel[0]) 
);
defparam q_4_s65.INIT=8'hCA;
  LUT3 q_4_s66 (
    .F(q_4_49),
    .I0(q16[4]),
    .I1(q17[4]),
    .I2(sel[0]) 
);
defparam q_4_s66.INIT=8'hCA;
  LUT3 q_4_s67 (
    .F(q_4_50),
    .I0(q18[4]),
    .I1(q19[4]),
    .I2(sel[0]) 
);
defparam q_4_s67.INIT=8'hCA;
  LUT3 q_3_s58 (
    .F(q_3_41),
    .I0(q0[3]),
    .I1(q1[3]),
    .I2(sel[0]) 
);
defparam q_3_s58.INIT=8'hCA;
  LUT3 q_3_s59 (
    .F(q_3_42),
    .I0(q2[3]),
    .I1(q3[3]),
    .I2(sel[0]) 
);
defparam q_3_s59.INIT=8'hCA;
  LUT3 q_3_s60 (
    .F(q_3_43),
    .I0(q4[3]),
    .I1(q5[3]),
    .I2(sel[0]) 
);
defparam q_3_s60.INIT=8'hCA;
  LUT3 q_3_s61 (
    .F(q_3_44),
    .I0(q6[3]),
    .I1(q7[3]),
    .I2(sel[0]) 
);
defparam q_3_s61.INIT=8'hCA;
  LUT3 q_3_s62 (
    .F(q_3_45),
    .I0(q8[3]),
    .I1(q9[3]),
    .I2(sel[0]) 
);
defparam q_3_s62.INIT=8'hCA;
  LUT3 q_3_s63 (
    .F(q_3_46),
    .I0(q10[3]),
    .I1(q11[3]),
    .I2(sel[0]) 
);
defparam q_3_s63.INIT=8'hCA;
  LUT3 q_3_s64 (
    .F(q_3_47),
    .I0(q12[3]),
    .I1(q13[3]),
    .I2(sel[0]) 
);
defparam q_3_s64.INIT=8'hCA;
  LUT3 q_3_s65 (
    .F(q_3_48),
    .I0(q14[3]),
    .I1(q15[3]),
    .I2(sel[0]) 
);
defparam q_3_s65.INIT=8'hCA;
  LUT3 q_3_s66 (
    .F(q_3_49),
    .I0(q16[3]),
    .I1(q17[3]),
    .I2(sel[0]) 
);
defparam q_3_s66.INIT=8'hCA;
  LUT3 q_3_s67 (
    .F(q_3_50),
    .I0(q18[3]),
    .I1(q19[3]),
    .I2(sel[0]) 
);
defparam q_3_s67.INIT=8'hCA;
  LUT3 q_2_s58 (
    .F(q_2_41),
    .I0(q0[2]),
    .I1(q1[2]),
    .I2(sel[0]) 
);
defparam q_2_s58.INIT=8'hCA;
  LUT3 q_2_s59 (
    .F(q_2_42),
    .I0(q2[2]),
    .I1(q3[2]),
    .I2(sel[0]) 
);
defparam q_2_s59.INIT=8'hCA;
  LUT3 q_2_s60 (
    .F(q_2_43),
    .I0(q4[2]),
    .I1(q5[2]),
    .I2(sel[0]) 
);
defparam q_2_s60.INIT=8'hCA;
  LUT3 q_2_s61 (
    .F(q_2_44),
    .I0(q6[2]),
    .I1(q7[2]),
    .I2(sel[0]) 
);
defparam q_2_s61.INIT=8'hCA;
  LUT3 q_2_s62 (
    .F(q_2_45),
    .I0(q8[2]),
    .I1(q9[2]),
    .I2(sel[0]) 
);
defparam q_2_s62.INIT=8'hCA;
  LUT3 q_2_s63 (
    .F(q_2_46),
    .I0(q10[2]),
    .I1(q11[2]),
    .I2(sel[0]) 
);
defparam q_2_s63.INIT=8'hCA;
  LUT3 q_2_s64 (
    .F(q_2_47),
    .I0(q12[2]),
    .I1(q13[2]),
    .I2(sel[0]) 
);
defparam q_2_s64.INIT=8'hCA;
  LUT3 q_2_s65 (
    .F(q_2_48),
    .I0(q14[2]),
    .I1(q15[2]),
    .I2(sel[0]) 
);
defparam q_2_s65.INIT=8'hCA;
  LUT3 q_2_s66 (
    .F(q_2_49),
    .I0(q16[2]),
    .I1(q17[2]),
    .I2(sel[0]) 
);
defparam q_2_s66.INIT=8'hCA;
  LUT3 q_2_s67 (
    .F(q_2_50),
    .I0(q18[2]),
    .I1(q19[2]),
    .I2(sel[0]) 
);
defparam q_2_s67.INIT=8'hCA;
  LUT3 q_1_s58 (
    .F(q_1_41),
    .I0(q0[1]),
    .I1(q1[1]),
    .I2(sel[0]) 
);
defparam q_1_s58.INIT=8'hCA;
  LUT3 q_1_s59 (
    .F(q_1_42),
    .I0(q2[1]),
    .I1(q3[1]),
    .I2(sel[0]) 
);
defparam q_1_s59.INIT=8'hCA;
  LUT3 q_1_s60 (
    .F(q_1_43),
    .I0(q4[1]),
    .I1(q5[1]),
    .I2(sel[0]) 
);
defparam q_1_s60.INIT=8'hCA;
  LUT3 q_1_s61 (
    .F(q_1_44),
    .I0(q6[1]),
    .I1(q7[1]),
    .I2(sel[0]) 
);
defparam q_1_s61.INIT=8'hCA;
  LUT3 q_1_s62 (
    .F(q_1_45),
    .I0(q8[1]),
    .I1(q9[1]),
    .I2(sel[0]) 
);
defparam q_1_s62.INIT=8'hCA;
  LUT3 q_1_s63 (
    .F(q_1_46),
    .I0(q10[1]),
    .I1(q11[1]),
    .I2(sel[0]) 
);
defparam q_1_s63.INIT=8'hCA;
  LUT3 q_1_s64 (
    .F(q_1_47),
    .I0(q12[1]),
    .I1(q13[1]),
    .I2(sel[0]) 
);
defparam q_1_s64.INIT=8'hCA;
  LUT3 q_1_s65 (
    .F(q_1_48),
    .I0(q14[1]),
    .I1(q15[1]),
    .I2(sel[0]) 
);
defparam q_1_s65.INIT=8'hCA;
  LUT3 q_1_s66 (
    .F(q_1_49),
    .I0(q16[1]),
    .I1(q17[1]),
    .I2(sel[0]) 
);
defparam q_1_s66.INIT=8'hCA;
  LUT3 q_1_s67 (
    .F(q_1_50),
    .I0(q18[1]),
    .I1(q19[1]),
    .I2(sel[0]) 
);
defparam q_1_s67.INIT=8'hCA;
  LUT3 q_0_s58 (
    .F(q_0_41),
    .I0(q0[0]),
    .I1(q1[0]),
    .I2(sel[0]) 
);
defparam q_0_s58.INIT=8'hCA;
  LUT3 q_0_s59 (
    .F(q_0_42),
    .I0(q2[0]),
    .I1(q3[0]),
    .I2(sel[0]) 
);
defparam q_0_s59.INIT=8'hCA;
  LUT3 q_0_s60 (
    .F(q_0_43),
    .I0(q4[0]),
    .I1(q5[0]),
    .I2(sel[0]) 
);
defparam q_0_s60.INIT=8'hCA;
  LUT3 q_0_s61 (
    .F(q_0_44),
    .I0(q6[0]),
    .I1(q7[0]),
    .I2(sel[0]) 
);
defparam q_0_s61.INIT=8'hCA;
  LUT3 q_0_s62 (
    .F(q_0_45),
    .I0(q8[0]),
    .I1(q9[0]),
    .I2(sel[0]) 
);
defparam q_0_s62.INIT=8'hCA;
  LUT3 q_0_s63 (
    .F(q_0_46),
    .I0(q10[0]),
    .I1(q11[0]),
    .I2(sel[0]) 
);
defparam q_0_s63.INIT=8'hCA;
  LUT3 q_0_s64 (
    .F(q_0_47),
    .I0(q12[0]),
    .I1(q13[0]),
    .I2(sel[0]) 
);
defparam q_0_s64.INIT=8'hCA;
  LUT3 q_0_s65 (
    .F(q_0_48),
    .I0(q14[0]),
    .I1(q15[0]),
    .I2(sel[0]) 
);
defparam q_0_s65.INIT=8'hCA;
  LUT3 q_0_s66 (
    .F(q_0_49),
    .I0(q16[0]),
    .I1(q17[0]),
    .I2(sel[0]) 
);
defparam q_0_s66.INIT=8'hCA;
  LUT3 q_0_s67 (
    .F(q_0_50),
    .I0(q18[0]),
    .I1(q19[0]),
    .I2(sel[0]) 
);
defparam q_0_s67.INIT=8'hCA;
  LUT4 level_q_11_s (
    .F(level_q[11]),
    .I0(sel[3]),
    .I1(level_q_11_4),
    .I2(q_11_66),
    .I3(sel[4]) 
);
defparam level_q_11_s.INIT=16'hEEF0;
  LUT4 level_q_10_s (
    .F(level_q[10]),
    .I0(sel[3]),
    .I1(level_q_10_4),
    .I2(q_10_66),
    .I3(sel[4]) 
);
defparam level_q_10_s.INIT=16'hEEF0;
  LUT4 level_q_9_s (
    .F(level_q[9]),
    .I0(sel[3]),
    .I1(level_q_9_4),
    .I2(q_9_66),
    .I3(sel[4]) 
);
defparam level_q_9_s.INIT=16'hEEF0;
  LUT4 level_q_8_s (
    .F(level_q[8]),
    .I0(sel[3]),
    .I1(level_q_8_4),
    .I2(q_8_66),
    .I3(sel[4]) 
);
defparam level_q_8_s.INIT=16'hEEF0;
  LUT4 level_q_7_s (
    .F(level_q[7]),
    .I0(sel[3]),
    .I1(level_q_7_4),
    .I2(q_7_66),
    .I3(sel[4]) 
);
defparam level_q_7_s.INIT=16'hEEF0;
  LUT4 level_q_6_s (
    .F(level_q[6]),
    .I0(sel[3]),
    .I1(level_q_6_4),
    .I2(q_6_66),
    .I3(sel[4]) 
);
defparam level_q_6_s.INIT=16'hEEF0;
  LUT4 level_q_5_s (
    .F(level_q[5]),
    .I0(sel[3]),
    .I1(level_q_5_4),
    .I2(q_5_66),
    .I3(sel[4]) 
);
defparam level_q_5_s.INIT=16'hEEF0;
  LUT4 level_q_4_s (
    .F(level_q[4]),
    .I0(sel[3]),
    .I1(level_q_4_4),
    .I2(q_4_66),
    .I3(sel[4]) 
);
defparam level_q_4_s.INIT=16'hEEF0;
  LUT4 level_q_3_s (
    .F(level_q[3]),
    .I0(sel[3]),
    .I1(level_q_3_4),
    .I2(q_3_66),
    .I3(sel[4]) 
);
defparam level_q_3_s.INIT=16'hEEF0;
  LUT4 level_q_2_s (
    .F(level_q[2]),
    .I0(sel[3]),
    .I1(level_q_2_4),
    .I2(q_2_66),
    .I3(sel[4]) 
);
defparam level_q_2_s.INIT=16'hEEF0;
  LUT4 level_q_1_s (
    .F(level_q[1]),
    .I0(sel[3]),
    .I1(level_q_1_4),
    .I2(q_1_66),
    .I3(sel[4]) 
);
defparam level_q_1_s.INIT=16'hEEF0;
  LUT4 level_q_0_s (
    .F(level_q[0]),
    .I0(sel[3]),
    .I1(level_q_0_4),
    .I2(q_0_66),
    .I3(sel[4]) 
);
defparam level_q_0_s.INIT=16'hEEF0;
  LUT4 level_q_11_s0 (
    .F(level_q_11_4),
    .I0(q20[11]),
    .I1(level_q_11_5),
    .I2(q_11_60),
    .I3(sel[2]) 
);
defparam level_q_11_s0.INIT=16'hBBF0;
  LUT4 level_q_10_s0 (
    .F(level_q_10_4),
    .I0(q20[10]),
    .I1(level_q_11_5),
    .I2(q_10_60),
    .I3(sel[2]) 
);
defparam level_q_10_s0.INIT=16'hBBF0;
  LUT4 level_q_9_s0 (
    .F(level_q_9_4),
    .I0(q20[9]),
    .I1(level_q_11_5),
    .I2(q_9_60),
    .I3(sel[2]) 
);
defparam level_q_9_s0.INIT=16'hBBF0;
  LUT4 level_q_8_s0 (
    .F(level_q_8_4),
    .I0(q20[8]),
    .I1(level_q_11_5),
    .I2(q_8_60),
    .I3(sel[2]) 
);
defparam level_q_8_s0.INIT=16'hBBF0;
  LUT4 level_q_7_s0 (
    .F(level_q_7_4),
    .I0(q20[7]),
    .I1(level_q_11_5),
    .I2(q_7_60),
    .I3(sel[2]) 
);
defparam level_q_7_s0.INIT=16'hBBF0;
  LUT4 level_q_6_s0 (
    .F(level_q_6_4),
    .I0(q20[6]),
    .I1(level_q_11_5),
    .I2(q_6_60),
    .I3(sel[2]) 
);
defparam level_q_6_s0.INIT=16'hBBF0;
  LUT4 level_q_5_s0 (
    .F(level_q_5_4),
    .I0(q20[5]),
    .I1(level_q_11_5),
    .I2(q_5_60),
    .I3(sel[2]) 
);
defparam level_q_5_s0.INIT=16'hBBF0;
  LUT4 level_q_4_s0 (
    .F(level_q_4_4),
    .I0(q20[4]),
    .I1(level_q_11_5),
    .I2(q_4_60),
    .I3(sel[2]) 
);
defparam level_q_4_s0.INIT=16'hBBF0;
  LUT4 level_q_3_s0 (
    .F(level_q_3_4),
    .I0(q20[3]),
    .I1(level_q_11_5),
    .I2(q_3_60),
    .I3(sel[2]) 
);
defparam level_q_3_s0.INIT=16'hBBF0;
  LUT4 level_q_2_s0 (
    .F(level_q_2_4),
    .I0(q20[2]),
    .I1(level_q_11_5),
    .I2(q_2_60),
    .I3(sel[2]) 
);
defparam level_q_2_s0.INIT=16'hBBF0;
  LUT4 level_q_1_s0 (
    .F(level_q_1_4),
    .I0(q20[1]),
    .I1(level_q_11_5),
    .I2(q_1_60),
    .I3(sel[2]) 
);
defparam level_q_1_s0.INIT=16'hBBF0;
  LUT4 level_q_0_s0 (
    .F(level_q_0_4),
    .I0(q20[0]),
    .I1(level_q_11_5),
    .I2(q_0_60),
    .I3(sel[2]) 
);
defparam level_q_0_s0.INIT=16'hBBF0;
  LUT2 level_q_11_s1 (
    .F(level_q_11_5),
    .I0(sel[1]),
    .I1(sel[0]) 
);
defparam level_q_11_s1.INIT=4'h1;
  DFFCE sel_3_s0 (
    .Q(sel[3]),
    .D(level_addr[13]),
    .CLK(clk_12m288),
    .CLEAR(GND),
    .CE(VCC) 
);
  DFFCE sel_2_s0 (
    .Q(sel[2]),
    .D(level_addr[12]),
    .CLK(clk_12m288),
    .CLEAR(GND),
    .CE(VCC) 
);
  DFFCE sel_1_s0 (
    .Q(sel[1]),
    .D(level_addr[11]),
    .CLK(clk_12m288),
    .CLEAR(GND),
    .CE(VCC) 
);
  DFFCE sel_0_s0 (
    .Q(sel[0]),
    .D(level_addr[10]),
    .CLK(clk_12m288),
    .CLEAR(GND),
    .CE(VCC) 
);
  DFFCE sel_4_s0 (
    .Q(sel[4]),
    .D(level_addr[14]),
    .CLK(clk_12m288),
    .CLEAR(GND),
    .CE(VCC) 
);
  pROMX9 q20_0_s1 (
    .DO({DO[35:18],q19[5:0],q20[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s1.BIT_WIDTH=18;
defparam q20_0_s1.INIT_RAM_00=288'h8FFF8EFFE8FFFB9FFEE3FFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFE83FEF6FFA87FE22;
defparam q20_0_s1.INIT_RAM_01=288'hFBB33ECCEFAFE7EB79FA69BE8FCFA69BE7D2FA7EFE97BFA3F207A7D9B4CC6D3DDAA388FC;
defparam q20_0_s1.INIT_RAM_02=288'hE3D2CEE77939DFAEA19B68BBCF89B68A7CCE477DFCB79F748E8FFE4FFFBEFFEF7FFA7FA0;
defparam q20_0_s1.INIT_RAM_03=288'h33FFB7FFE2FBDB7EA1E3D2E3F768BFFB9FFE93FFB9FFEE7FFBEFFEFBFF8BFFE33FFB7FFE;
defparam q20_0_s1.INIT_RAM_04=288'h33FF8BFFE87FFB6FFE87FFA1FFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE2FFFB5FFE;
defparam q20_0_s1.INIT_RAM_05=288'hD7FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFED7FD75FCB33FF8BFFE;
defparam q20_0_s1.INIT_RAM_06=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7FFFEFFFFBFFBEFFE2FFFB5FFE;
defparam q20_0_s1.INIT_RAM_07=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s1.INIT_RAM_08=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s1.INIT_RAM_09=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_0A=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_0B=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_0C=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_0D=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_0E=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_0F=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_10=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_11=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_12=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_13=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_14=288'hFED3FFAFAFEB3FFAA5FEE93FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_15=288'hEBFFA5FFEEBFF90FFE3FFFBFFFEFFFFBFFFEFFFFBFFF5FFBDBFDCDFF48FFC79FF093FBA4;
defparam q20_0_s1.INIT_RAM_16=288'hFB737EB79FA743E9D0F9FF3E752F9E9FE5D4F9752052A856A7857F391564480395FCF6D3;
defparam q20_0_s1.INIT_RAM_17=288'h933E10CCE9B28E6BCE4A9428A7AF669BFAFA4EBEA9951FE3F2BFFE03FFAAFFEABFFBDEA1;
defparam q20_0_s1.INIT_RAM_18=288'h377364E228F33A4C2496FE7BCF83BFFBAFFE47FFA6FFE47FFBEFFEFBFFBEFFE33FFB8F21;
defparam q20_0_s1.INIT_RAM_19=288'h8FBD8EFFE3BFFB9FFE93FF8DFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBF2F5F4B87FFB7DCD;
defparam q20_0_s1.INIT_RAM_1A=288'h8BFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBF2FEFFE2FD2CBEA18BA862EA1;
defparam q20_0_s1.INIT_RAM_1B=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFE1FFFDBFFB7FFEE3FFB8FFE;
defparam q20_0_s1.INIT_RAM_1C=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFF6FFF83FFCBFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s1.INIT_RAM_1D=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s1.INIT_RAM_1E=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_1F=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_20=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_21=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_22=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_23=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_24=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_25=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_26=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_27=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_28=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_29=288'hFE3F3F8A7FE1F3F852FE547FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s1.INIT_RAM_2A=288'hF3FFA7FFEF3FF92FFE47FFBFFFEFFFFBFFFEFFF2FFDA2FF28FFB79FEB3FFA25FE743F951;
defparam q20_0_s1.INIT_RAM_2B=288'hF8003E000F8003E000F8003E000F8003E0002C002300090003A000400026000440011000;
defparam q20_0_s1.INIT_RAM_2C=288'hF80035000D40020000DC00370008C002300038003900040002400098000F000980025000;
defparam q20_0_s1.INIT_RAM_2D=288'hF8003E000F800350002C000B000F80036000D400350002C003E000F8003E000F80035000;
defparam q20_0_s1.INIT_RAM_2E=288'hF8003E000D40035000F8003E000F8003E000F8003E000F8003E000F8003E000F8003E000;
defparam q20_0_s1.INIT_RAM_2F=288'hFC003E000F8003E000F8003E000F8003E000F8003E000F8003E000F8003E000F80035000;
defparam q20_0_s1.INIT_RAM_30=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_31=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_32=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_33=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_34=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_35=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_36=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_37=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_38=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_39=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_3A=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_3B=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_3C=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_3D=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_3E=288'hFC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.INIT_RAM_3F=288'h34003800034002300088003F000FC003F000FC003F000FC003F000FC003F000FC003F000;
defparam q20_0_s1.READ_MODE=1'b0;
defparam q20_0_s1.RESET_MODE="SYNC";
  pROMX9 q20_0_s2 (
    .DO({DO_0[35:18],q18[11:0],q19[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s2.BIT_WIDTH=18;
defparam q20_0_s2.INIT_RAM_00=288'hFFFD3FFF3FFFCBFFF1FFFD7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_01=288'hDF7FF68BFD78FF537FE4CFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFEFFFF9FFFDFFFF5;
defparam q20_0_s2.INIT_RAM_02=288'hFFECFFFAFFFEC3FFABFFE93FFA5FFE93FFA0FFE97FFA1FFE77FF9CFCB6FC859ECC6F9322;
defparam q20_0_s2.INIT_RAM_03=288'hBF9EEF3B79A6FE69B98FCCE3F347D2E25EEF7D2BA14B1926C649BF7A7FDFF3F7A7EDB4F7;
defparam q20_0_s2.INIT_RAM_04=288'hEA1EF7DFDDA2F368BDCCEEBB33CD78FF1E7FC79FEF3BFBF9FFFFBFFFEFFFFBFF4BFF68BF;
defparam q20_0_s2.INIT_RAM_05=288'hF21FFFD7FEF6FFC87FE22FF9DFFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFCBEF9DFD;
defparam q20_0_s2.INIT_RAM_06=288'hFF5FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7F;
defparam q20_0_s2.INIT_RAM_07=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7FFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_08=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7FFFEFFFFBFFFEFFFD7FFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_09=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_0A=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_0B=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_0C=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_0D=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_0E=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_0F=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_10=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_11=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_12=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_13=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_14=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_15=288'hFFFAFFFEAFFFA7FFE9FFFB7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_16=288'hB24FEB3FFAA5FE9EBFB79FFFFFFFFFFFFFFFFFFFFFFFEFFFEBFFF5FFFCFFFF0FFFBFFFED;
defparam q20_0_s2.INIT_RAM_17=288'hFFEBBFFA9FFE9BFFA4FFE77FF9CFFE77FF95FFE6FF2D6ECC4F6890CF8431392BF952DE5B;
defparam q20_0_s2.INIT_RAM_18=288'h926D629F07FCD18A6C5A9A17FA7455BD3FE93D58D2AA65D495753F3D5FCF57F301ECAB35;
defparam q20_0_s2.INIT_RAM_19=288'hA7ACAA973AFAC67EF187CC1F4B78FCFDCA3F752FE1F3F728FFFFBFFFEFFFFBFC24F30937;
defparam q20_0_s2.INIT_RAM_1A=288'hB4FE2897FA7AFEBEBFAA5FE7EFFFFEFFFFBFFFEFFFFBFFFEFFFD7FECCFF3E3DDA2E2FE76;
defparam q20_0_s2.INIT_RAM_1B=288'hC79FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFF5E3AD78EF3E39BF9D69EB5;
defparam q20_0_s2.INIT_RAM_1C=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFF4BFFFFBFCF8FF28FDCF8FBC87DB79FEBEBFCA3FEE93F;
defparam q20_0_s2.INIT_RAM_1D=288'hFFEFFFFBFFFEFFFD7FF4BFFB33FFCBFF933FE77FF33BFD78FF88BFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_1E=288'hFFEFFF2FFFFEFFBDBFFFEFFD2FFF21FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_1F=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_20=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_21=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_22=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_23=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_24=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_25=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_26=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_27=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_28=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_29=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_2A=288'hFFF87FFE0FFF7FFFDFFFF8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_2B=288'h6FDFDAA3F67EFD94FF752FFFFFFFFFFFFFFFFFFF7FFF4FFFC3FFEBFFFA7FFE6FFF97FFE3;
defparam q20_0_s2.INIT_RAM_2C=288'hFFEFFFFBFFFEFFFFBEFFEE7FFB9FFED3FFB2DCDCEE92DAA5A65EF08D19A09ED7D291D4A8;
defparam q20_0_s2.INIT_RAM_2D=288'hFF5FF9DFFEF6FF3E3FC4EFF3E3DC4EFEBEBBBA4FED3FFAFAFE897F8A7FE3F3F8D1FE9EBF;
defparam q20_0_s2.INIT_RAM_2E=288'hFFEFFE83FFFEFFDDBFEF6FFDDBFF21FF933FE77FF7DFFFA0FFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_2F=288'hFFEFFFD7FFFEFFFFBFFA0FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_30=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7F;
defparam q20_0_s2.INIT_RAM_31=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_32=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_33=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s2.INIT_RAM_34=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_35=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_36=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_37=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_38=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_39=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_3A=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_3B=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_3C=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_3D=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_3E=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.INIT_RAM_3F=288'hFFFDFFFF5FFFD7FFF4FFFE3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s2.READ_MODE=1'b0;
defparam q20_0_s2.RESET_MODE="SYNC";
  pROMX9 q20_0_s3 (
    .DO({DO_1[35:18],q16[5:0],q17[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s3.BIT_WIDTH=18;
defparam q20_0_s3.INIT_RAM_00=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_01=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_02=288'hFF28FFC4EFF093FBF9FF3E3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_03=288'h93FF8FFFE97FFBAFFEE7FFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFF21FF9DFFDCDFF5E3FCF8;
defparam q20_0_s3.INIT_RAM_04=288'hFABEBE9FBFA347E7D2FA29FEA50F9BF7E67EF99F8B5FE318A625A9E1550E5A9E54AB95D4;
defparam q20_0_s3.INIT_RAM_05=288'h9FFFBCC4EF728E7C4E4B3E13CA352FE54CF856FE55ACF575E15FFEABFFBFFFEA7737EC24;
defparam q20_0_s3.INIT_RAM_06=288'h3BDDB8FF53F9DE5F2197A850FFE9BFFA5FFE97FFBAFFE43FFA6FFEE3FF8BFFE97BDA5CF8;
defparam q20_0_s3.INIT_RAM_07=288'hE3D2CDFFEE7FFB9FFE8FFF8CFFEFBFFBEFFEFBFFBEFFEFBFFB6FFEDFFF8CF4BDBDDB9F21;
defparam q20_0_s3.INIT_RAM_08=288'hDFFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEF7683FD7EF2133B30CF4BDBF2F6FFE37FD78DA2;
defparam q20_0_s3.INIT_RAM_09=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEDBC860FFEFBFFBEFCBD7FFA0FFE87FFB7FFE;
defparam q20_0_s3.INIT_RAM_0A=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFED7FFBEFFEFBFFBEFFEDBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_0B=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_0C=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBF2FEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_0D=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_0E=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_0F=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_10=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_11=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_12=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_13=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_14=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_15=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_16=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_17=288'hFE547F8FCFE347F8A7FE69BFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_18=288'h9FFF92FFE9FFFBCFFEF3FFBFFFEFFFFBFFFEFFFFBFDF7FF3E3FBCEFEC93FA7AFE897F9A6;
defparam q20_0_s3.INIT_RAM_19=288'hFA3F3E7D2F994FE57FF95FFE7D2F9203E3D5D8F54D38038D5A432BE8C050301ECB5BC32B;
defparam q20_0_s3.INIT_RAM_1A=288'hA289548A7AA547F87CFE09D57A7AE896C951B1DF6C752B1B4ECEF60B7DD7CF85AE92B9FB;
defparam q20_0_s3.INIT_RAM_1B=288'h9B0911CA3F6D3D2BF94F093FB7953FF94FFEFBFF93FFE4FFF92F76933E24B4FF2D3D29A6;
defparam q20_0_s3.INIT_RAM_1C=288'hEED3FBFFE3BFF90FFE9FFFA6FFEFBFFBEFFEFBFD77EA1DBBD8FFFE437DFBDCDEF3392BCE;
defparam q20_0_s3.INIT_RAM_1D=288'h97FFBEFFEFBFFBEFA0FBB33EDF72F88B7C4E8BFD4EC79E6E90DBA43B33A4DF7971390BCE;
defparam q20_0_s3.INIT_RAM_1E=288'hFBFFBEFFEFBFFBEFCB8B7DCEDCD3B88B9E22E77379E77935E39E4C3BFFB7FFE97FFBBFF5;
defparam q20_0_s3.INIT_RAM_1F=288'h2FFD77FCB8BE83EF21E7930EE4CE73E24FFE8FFFA3FFEE7FF8EFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_20=288'hDB9335F7633FF8CFFEE3FF8DFFE37FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_21=288'hE3FFB8FFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFA0FFE;
defparam q20_0_s3.INIT_RAM_22=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFED7FFBEFFE83FFBEFFE2FFFB7FFE;
defparam q20_0_s3.INIT_RAM_23=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFF8BFFEFBFF8CFFE87FFB7FFEDBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_24=288'hFBFFFEFFFFBFFFEFFEFBFFA0FFEFBFF8BFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_25=288'hFBFFF5FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_26=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_27=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7FFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_28=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_29=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_2A=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_2B=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_2C=288'hFDBF7F6A8FD9FBF653FDD4BFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_2D=288'hFBFFA9FFEFFFF94FFE4FFFBFFFEFFFFBFFFEFF737FBA4FEA97F97BFE347F827FDF4BF752;
defparam q20_0_s3.INIT_RAM_2E=288'hFBA87EECCFB28FEE22FB13BEBF9FAD3FED233B0925CCE9A9EBCC4E4A69A8C244EBE93AA5;
defparam q20_0_s3.INIT_RAM_2F=288'h8BB337FFEDFC84FFCB8F7DE4DA2939DFAE77438890D78EF68A6FFE9FFFBBFF5F3DD90FFE;
defparam q20_0_s3.INIT_RAM_30=288'h83D2E2FF5E3FF8DFFE8BFFB7F4BE3FFA2FFEE3FFA3FFE8FFFBEFFEFBFFBEFFEDBFFA1FCB;
defparam q20_0_s3.INIT_RAM_31=288'hFBFFBEFFEFBFFB5FFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFA1FFE;
defparam q20_0_s3.INIT_RAM_32=288'h83FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_33=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFF8BFFEDBFF8CFFEDBFF8BFFE;
defparam q20_0_s3.INIT_RAM_34=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_35=288'hFBFFBEFF5FBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_36=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBF2FEFFE;
defparam q20_0_s3.INIT_RAM_37=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFEFBFFBEFFE;
defparam q20_0_s3.INIT_RAM_38=288'hFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_39=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFF;
defparam q20_0_s3.INIT_RAM_3A=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_3B=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_3C=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_3D=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_3E=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.INIT_RAM_3F=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s3.READ_MODE=1'b0;
defparam q20_0_s3.RESET_MODE="SYNC";
  pROMX9 q20_0_s4 (
    .DO({DO_2[35:18],q15[11:0],q16[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s4.BIT_WIDTH=18;
defparam q20_0_s4.INIT_RAM_00=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_01=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_02=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBF;
defparam q20_0_s4.INIT_RAM_03=288'hFFFB3FFEBFFFABFFE9FFFB7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s4.INIT_RAM_04=288'hB79FEC93FAFAFEB3FFBCEFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFF6FFFCFFFF1FFFBFFFED;
defparam q20_0_s4.INIT_RAM_05=288'hFFE8BFFA1FFE77FF9EFFE7FFF9BFFE5FFF95FFE4FFF93F214F7DD3D4D4B28D3C4E5AF399;
defparam q20_0_s4.INIT_RAM_06=288'h8FCCE54737FCB5F4A88A7A21F278A79A09E8827A1F4A9752A57FB652ACD5FFD554A13FE8;
defparam q20_0_s4.INIT_RAM_07=288'hBA4D6E935CA3C713B1BF9CADE79AA5FEB3FFC4EFEB3FFBCEFFA8BBD78E713B9CCEEE7EEF;
defparam q20_0_s4.INIT_RAM_08=288'hBF9DEDE7FB79FEF3BFC24FEB3FFFFEFFFFBFFFEFBFFBFEF6EFB339DCDF71E7DCCEDF7375;
defparam q20_0_s4.INIT_RAM_09=288'hE22FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFDCDF7737ED23FEF3BFC24FF13BEB79EAD3F7;
defparam q20_0_s4.INIT_RAM_0A=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFF76FFC87FEA1FF88BFE22EF737FDCDFF9DFFDCDFF737F;
defparam q20_0_s4.INIT_RAM_0B=288'hFFEFFFFBFFFEFFFFBFFFEFFE83FFA0FFFFBFFFEFFC87FF21FFDDBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_0C=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_0D=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_0E=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_0F=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_10=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_11=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_12=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_13=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_14=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_15=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_16=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_17=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBF;
defparam q20_0_s4.INIT_RAM_18=288'hFFF8BFFE1FFF83FFDFFFF8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s4.INIT_RAM_19=288'h8D1FE1F3F852FE09FF926FFFFFFFFFFFFFFFFFFF7FFF5FFFC7FFECFFFA7FFE7FFF97FFE3;
defparam q20_0_s4.INIT_RAM_1A=288'hFFE6BFF97FFE53FF93FFE57FF91FFE33FF8AFA0235E08C7922D3C8AA5227EC99A62E498E;
defparam q20_0_s4.INIT_RAM_1B=288'h7A791D4A567E758A5F65365F4955D4555FD75D45D551940064F56F380B1156C3807EE91F;
defparam q20_0_s4.INIT_RAM_1C=288'h8D19DD4A567EBD94E76A88994E6653FD94FF629FD7FB9F4BF734ADC24A6FE659A69E09E1;
defparam q20_0_s4.INIT_RAM_1D=288'h8FCA214BF926FE49BF752FFFFBFFFEFFE839DF7DB7373BA4C6897597BCE3F2C7A7AA5467;
defparam q20_0_s4.INIT_RAM_1E=288'hFFEFFFFBFFFEFFFFBFFFEDBBDB3D4DCF5E31C24BF13ADAFAB2942FA25CEC93997BAA3467;
defparam q20_0_s4.INIT_RAM_1F=288'hFFEFFF2F7FA0DB68BFFFEC70931B24BF48F0B4FD2B3F29A6BE69AF9A6FE743FAFAFE743F;
defparam q20_0_s4.INIT_RAM_20=288'hCCEEF13BFC79E73E39C24D6D3F5CF8DEDE7FA7AFE943FAFAFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_21=288'hF21D7A873DCDFFD2FFC24FF093FFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFCBFF68BE;
defparam q20_0_s4.INIT_RAM_22=288'hB79FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFCBFBA87FE77FFDDB7;
defparam q20_0_s4.INIT_RAM_23=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFCBFFFD7BDA2EB9DF9DA2F7737FC4EFEFE7F;
defparam q20_0_s4.INIT_RAM_24=288'hFFEFFFFBFFFEFFD2FFFFEFFA87EECCFF68BFDF7FF5E3FD4DFF933FFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_25=288'hFFEFFFFBFFFEFFBDBFE22FF537FCA3FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_26=288'hEA1FFBDBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_27=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFE83F;
defparam q20_0_s4.INIT_RAM_28=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_29=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFCBFFFD7FFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_2A=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_2B=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_2C=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBF;
defparam q20_0_s4.INIT_RAM_2D=288'hFFF5FFFD6FFF57FFD5FFF67FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s4.INIT_RAM_2E=288'h752FDBF7F6D3FDAA3F7A7FFFFFFFFFFFFFFFFFFCFFFEAFFF9BFFE1FFF7FFFDCFFF6FFFD9;
defparam q20_0_s4.INIT_RAM_2F=288'hFFEDBFFB7FFEE7FFADFFECBFFACFFEBBFFABE229EFE67AFA9674249268A1F2582785E9E7;
defparam q20_0_s4.INIT_RAM_30=288'hB4FFAA97697BD669B7A25DA54778D1D61F367A7D5E9F47A7D1CA3F728FDE9FF8FCF65EFA;
defparam q20_0_s4.INIT_RAM_31=288'hDF7FF7DFFCCEFEF3BFBA4FEDE7FB4FFED3FFBCEFEFE7FCCEFFC97FE77FFF2FFC4EFF093A;
defparam q20_0_s4.INIT_RAM_32=288'hE77FBBDBFEA1FFB33FF21FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFE83FFFEFF737F;
defparam q20_0_s4.INIT_RAM_33=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBDFFEF7FFBBECCEFA87D;
defparam q20_0_s4.INIT_RAM_34=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_35=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_36=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_37=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_38=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_39=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_3A=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_3B=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_3C=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_3D=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_3E=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s4.INIT_RAM_3F=288'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
defparam q20_0_s4.READ_MODE=1'b0;
defparam q20_0_s4.RESET_MODE="SYNC";
  pROMX9 q20_0_s5 (
    .DO({DO_3[35:18],q13[5:0],q14[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s5.BIT_WIDTH=18;
defparam q20_0_s5.INIT_RAM_00=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_01=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_02=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_03=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_04=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_05=288'hFA69BE951FA49BE8FCFA7EFEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_06=288'h9FFF92FFE9FFFBCFFEF3FFBEFFEFBFFBEFFEFBFFBEE4CFB537EC24FADE7EACFFA9EBE9FB;
defparam q20_0_s5.INIT_RAM_07=288'hF9FF3E9A6F99FBE629F9CA3E77DF97FBE554D9354D4D53935644AAE93FD04D5ED157C87C;
defparam q20_0_s5.INIT_RAM_08=288'h4B1392E2252E929A25A6BEAA9FBAE9416951AE6981AA5068956DCC5AF3AB9D0AE5EEB8D1;
defparam q20_0_s5.INIT_RAM_09=288'h9F6892E22A388BDBF9A36893BA4F7FF93FFEA3FF92FFE4BE82AEA1F37DD1D4DF73E3CC79;
defparam q20_0_s5.INIT_RAM_0A=288'h9F0927FFE97FFA5FFE9BFFA7FFEEFFF8DFA08B933BDA297FFBBD78EF68A5E779F68BCCA3;
defparam q20_0_s5.INIT_RAM_0B=288'hEFFFBEFFEFBFFBEFFEDBD2CDDCDE7537AD4DE748CFD23971E7AC79EAF3BBB79EED3FBAA5;
defparam q20_0_s5.INIT_RAM_0C=288'hFBFF8DFA037FFB8F4B3BA863FF53BFFA3FCB93DD90FFE97F2E5F2197FFBAFFEEBFFA4FFE;
defparam q20_0_s5.INIT_RAM_0D=288'hE7FF8EFFE3BFFA4FFE93E839FFE93FFA4FFEE7FF8FFFE97FF90FFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_0E=288'hEBFFBAFFE3FFFA5FFEEBFF8FFFEE7FFBEFFEFBFFBEFFEFBFFBEFFEFBFF8DFFEE3FFB6FFE;
defparam q20_0_s5.INIT_RAM_0F=288'h93FFB9FFEFBFFBEFFEFBFFBEFFEFBFFBEFFE2FFF8BFFE8BFFB7FFE8FFF8EFFE3BFFA4FFE;
defparam q20_0_s5.INIT_RAM_10=288'hFBFFBEFFEFBFFBEFFE83FFBEFFE33FF8CFFE87FFA2FFEE3FFB9FFE3BFF8EFFE3FFFB9FFE;
defparam q20_0_s5.INIT_RAM_11=288'hFBFFA0FFEFBFFBEFFE2FFFA0FFED7FFA2FFE33FFB7FFE37FF8DFFEDBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_12=288'hFBFFBEFFEFBFFB5FFEFBFFA0FFEFBFF8CFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_13=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_14=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_15=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_16=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_17=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_18=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_19=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_1A=288'hF9FF3E7A7F9DF7E752FA14BEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_1B=288'h4FFFBEFFE53FFA9FFEA3FFBEFFEFBFFBEFFEFBB33ECA3FAE93EA7AFA743E926FA347E852;
defparam q20_0_s5.INIT_RAM_1C=288'hF97FBE67EF9203E3D5F92ABE6A8F8F57E3018CAB3A281ECA0512AC9CAB3D1D7A0CAE8ACF;
defparam q20_0_s5.INIT_RAM_1D=288'hA6149472801E9C067EADBF566295D4A826D35DDF4262963B318B7A627EC287CB1D4AC6D3;
defparam q20_0_s5.INIT_RAM_1E=288'hF609D497BFDCA2A8D155DF55FFEFFFDBFECC536894BF9A6C93CAA59E4992926FA7ED26A8;
defparam q20_0_s5.INIT_RAM_1F=288'hA3FF93FFE9FFFBCFFEA3F2D4EF68B338EB4FEB5351ACF9E547CB244A29D29D04E7428852;
defparam q20_0_s5.INIT_RAM_20=288'h4FFFBEECCFB9320E22E33E23BCE42A9518A7EE29E7926F234678A7F229D17A749BF526A8;
defparam q20_0_s5.INIT_RAM_21=288'h8B1E79B243EA965A253A7EFB9D04269BC8FCEA5EE797BF67412FFEA3FF92FFE4BFFA7FFE;
defparam q20_0_s5.INIT_RAM_22=288'h96B3D0AA59A9425AFA3F537BACFF3FFBCFFE9FFF92FFEF7FF93FFEFBFFBEFFEFB7377D4D;
defparam q20_0_s5.INIT_RAM_23=288'h4669BCFFEF3FFBDFFEF7FFBCFFE47FFBEFFEFBFFBEFFED7D2F7E4CE79323BCE42C90FB24;
defparam q20_0_s5.INIT_RAM_24=288'h9FFFA7FFEFBFFBEFFEFBFFBEECCD733A1CCE8F13A3B4F3EBE8FDF7430926BA442897C9D0;
defparam q20_0_s5.INIT_RAM_25=288'hFBFF8BFF52FB339DA29348CFEA13B537AE4CEFBDBAC4E46A967AA59FFFA7FFE4BFFBCFFE;
defparam q20_0_s5.INIT_RAM_26=288'h8B688ED23E71E64C24E6D3FAB7992DE50FFE97FFBBFFE9BFFA5FFE43FFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_27=288'h975E3AD4D43FF90FFEEFFFA6FFE9BFFA6FFEFBFFBEFFEFBFFBEFFEFBB33EF4BFB933EECC;
defparam q20_0_s5.INIT_RAM_28=288'h93FFA4FFEE7FFBEFFEFBFFBEFFEFBFFBEFFEFBFF8BFFE87FFB7FFE3BDD8EDF7E748FACA3;
defparam q20_0_s5.INIT_RAM_29=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBDDBEFFE87BDB7ECC8F9338DF737C864FFEE7FFA3FFE;
defparam q20_0_s5.INIT_RAM_2A=288'hFBFFBEFF5FBFD7EF76FBB30CDCDE3888BECC37FFA3FFE3BFFA3FFEE3FFA4FFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_2B=288'h33BDB8E4C3BD2E2FFE8FFF8EFFEE3FFB9FFEE7FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_2C=288'h93FF8EFFEE3FFB8FFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFB5FFEFBFFA2FFE;
defparam q20_0_s5.INIT_RAM_2D=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFB5F212FA861FF5FBDD8DF4B3BFF8EFFE;
defparam q20_0_s5.INIT_RAM_2E=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFB6FFE87FF8DFFE37FFB8FFE8FFFB8FFE37FFBEFFE;
defparam q20_0_s5.INIT_RAM_2F=288'hF95FFE52AF93FFE4D5F97521FFEDBFFA1FFEDBFF8CFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_30=288'h57FF80FFE57FFABFFEABFFBEFFEFBFFBEFFEFB13BEA25FA49BE7FCF9D4BE6A8F994FE5D4;
defparam q20_0_s5.INIT_RAM_31=288'hFA9EBEA50FA547E97BFA5EFE926FA29CB8A79229FB87CF289528A7A1E9FE7A7A5F4AA7A7;
defparam q20_0_s5.INIT_RAM_32=288'h47930FD23F31E52C2446FE51BF99EF393BCEFB1E53CCE4F3E29EFAFB933EDCDFBB329BA4;
defparam q20_0_s5.INIT_RAM_33=288'h8FFFB7EA1D7FFA3F76379DF8F4B33FFA4FFE8FFFA3FFE93FFBEFCBDFFFB9EA1EB6890DA2;
defparam q20_0_s5.INIT_RAM_34=288'h2FFFB6FFE33FFA2FFE33FFA2FFEFBFFBEFFEFBFFBEF76FBBDBEEA133FFA2FFE8BFD4DFCB;
defparam q20_0_s5.INIT_RAM_35=288'hE3FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFED7FFBEFFE83FFB6FFE87FFA1FFE33FF8DFF5;
defparam q20_0_s5.INIT_RAM_36=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFA1FFEDFFF8CFFE8BFFB7FFE8BFFB8FFE;
defparam q20_0_s5.INIT_RAM_37=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_38=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_39=288'h2FFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_3A=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_3B=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_3C=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_3D=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_3E=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.INIT_RAM_3F=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s5.READ_MODE=1'b0;
defparam q20_0_s5.RESET_MODE="SYNC";
  pROMX9 q20_0_s6 (
    .DO({DO_4[35:18],q12[11:0],q13[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s6.BIT_WIDTH=18;
defparam q20_0_s6.INIT_RAM_00=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_01=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_02=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_03=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_04=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_05=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_06=288'hFFE8BFFA1FFE83FF9FFFE8FFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_07=288'h852FDFF3F7D2FDE9FF8A7FFFFBFFFEFFFFBFFFEF7FFB5FFEC7FFACFFEA7FFA7FFE97FFA3;
defparam q20_0_s6.INIT_RAM_08=288'hFFE87FF9DFFE5FFF96FFE5BFF92FFE3BFF8DF21333E0CBF932B3CBA252E5ECC9263A29D0;
defparam q20_0_s6.INIT_RAM_09=288'h62989AA1D6FD716A5B4AA690ADB3AB6CE01B32B70C05D3567CCAE63808CF5654556D4AA3;
defparam q20_0_s6.INIT_RAM_0A=288'h87C89FF227FCA1F4A87A799E9E07A7E5F4B777DD9FF2787CA25FE78D1963F287D281B4E1;
defparam q20_0_s6.INIT_RAM_0B=288'h8279609FF852FE14BF8A7EE7437D51BF28EBC24C6896DAFAAA49A99D0AE3F279FB963F27;
defparam q20_0_s6.INIT_RAM_0C=288'hACFFFFFB7F76DFA873C24CED3F2BA4BE9432AA5B28969B79A2BEA8951A23F298A7AE14AC;
defparam q20_0_s6.INIT_RAM_0D=288'hFCBC79331DCDCF3E2EE22BB9DEDDF7B3932CDA2B6DE6BBCEA2DE67B79FED3FFACFFE943F;
defparam q20_0_s6.INIT_RAM_0E=288'hD4DAF932BC79AF092AB4FA6C92BAA5B69EBFA50FE897FA25FE9EBFFFEFFFFB7FFECFFFBD;
defparam q20_0_s6.INIT_RAM_0F=288'hD78BB33ADCF8FF1E7FCA3FF13BFBA4FFFFBFFFEF7FFBFEF6DB7DF7C79CB88B3C24CF33AC;
defparam q20_0_s6.INIT_RAM_10=288'hEA1FFD2FFFFEFFFFBFFFEFBFFBFFFEE7DDB9FFEEB7DF6F4BCFB331DF7BFB32FDF7B75E2D;
defparam q20_0_s6.INIT_RAM_11=288'hFFEFFFFBEFFEFFFFBFFFEF7FFBEF76FFFD76FA0E7D2F7EA1DFA875EA1EFB33FE22FF7DFF;
defparam q20_0_s6.INIT_RAM_12=288'hFFEFFFFBFFA0FFFFBFFCBFFB33EE77FF9339E4CFF88BFE22FF933FECCFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_13=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_14=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_15=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_16=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_17=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_18=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_19=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_1A=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_1B=288'hFFE67FF97FFE5FFF96FFE6BFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_1C=288'h653FD7FBF5D4FD6A7F6A8FFFFBFFFEFFFFBFFFED3FFABFFE9FFFA3FFE83FF9DFFE73FF9A;
defparam q20_0_s6.INIT_RAM_1D=288'hFFE63FF97FFE4BFF92FFE43FF8DFFE27FF88D231EBE869FB16344582715DF4672821AA0A;
defparam q20_0_s6.INIT_RAM_1E=288'h42B6D0AD76A85500142AC4C8B131AD4C609310354361512D6040E312D806B5D2575CC05D;
defparam q20_0_s6.INIT_RAM_1F=288'h5D4696A5B57F89552357F7155174D5D955314D5AD5FE35D481F59F72875CA1F67E6D4A9A;
defparam q20_0_s6.INIT_RAM_20=288'h4556D157F480FD203E4FFCD8A74B24A689659269634628278DB4E2752857FA56FD7D9FA1;
defparam q20_0_s6.INIT_RAM_21=288'h6D3E3FFADEF6B6FE689A6BE3F27A25A5FF236FDAD9F9E6FD759F9D52A712A9D4807D155E;
defparam q20_0_s6.INIT_RAM_22=288'hBCEAA9EA7ACF923F2AA25AE3F259A68DF4A17A7899F9F6536D9F9B629FD8A7F5D4FD5FF9;
defparam q20_0_s6.INIT_RAM_23=288'h77D8DFF1F7527DAA1D5FE75751F57F8D4ABF554FD4ABF57FFD8A77FFEC7FFB2E4CA728ED;
defparam q20_0_s6.INIT_RAM_24=288'h8A781DF60728FDAA3F67EFD9FBF67EFFFFBAFFECBDDB2D4DAEA96D8D1A6C9249519DF4A3;
defparam q20_0_s6.INIT_RAM_25=288'h926FE7EFFFFEF7FFB1FFEC3B32DF76BEBEA9B249E7429C249629E28D18269A097B7E09DF;
defparam q20_0_s6.INIT_RAM_26=288'hFFEDBFFB1E4CBF0930C79B733A9BCEBAD3E99FBA269A59D09A7EE8A50A6547F926FE347F;
defparam q20_0_s6.INIT_RAM_27=288'hA7AA29EA9AA5A67429A7A9DF4A677D99CA246D3FDBF7F6FDFDB4FF728FFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_28=288'hA25B289709D0BE7EFF9A6FE49BFA7AFE5EFFFFEFFFFBDFFEEBFFB9F4BCF092FC4EB6B3EB;
defparam q20_0_s6.INIT_RAM_29=288'hBA4FEB3FFB24FFFFBFFFEFFFFBFFFEFFFFBFFA0F3A879DA2D388B5D4DDEFE70AFAB6A972;
defparam q20_0_s6.INIT_RAM_2A=288'hFFEFFFFBFFFEFFFFBFFFEFF9339DF7D75E3FC4ED713B2C4EC6C932BCECF28EEC24FEFE7F;
defparam q20_0_s6.INIT_RAM_2B=288'hC79EF3E33D4DCF33B6BA4D2B3F1A25D669B1951C649BF8FCFE347F8D1FE49BFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_2C=288'hD78C31E73D78CED3F5B4FFF33BFB4FFE9EBFAFAFFFFBFFFEFFFFBFFFEFFFFBFFCBFFE838;
defparam q20_0_s6.INIT_RAM_2D=288'h9FBFE69BF951FE547FFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFF537ADCDFF5377E4CC768B1;
defparam q20_0_s6.INIT_RAM_2E=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFD78FF9DFBF4BEB5E37BF9D6D3F3B4FD2D3F3C24D6F3BF;
defparam q20_0_s6.INIT_RAM_2F=288'hFFEFF68BFE4CFF5E3FCCEFF88BCEA1EF933ABCEF6BEB9AA5FE9EBFAA5FEB3FFBA4FFFFBF;
defparam q20_0_s6.INIT_RAM_30=288'hF4B4F7352DA2479310CF85313BFCA3FF1E7FC4EFF48FFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_31=288'h42BFCF57F3ABFCE03F480FFFFBFFFEFFFFBFFFEBBFFA5FFE87FF9DDCD6BFF97FFE5BFF94;
defparam q20_0_s6.INIT_RAM_32=288'hFFE97FFABFFE7FFF9FFFE8FFFA5FFE7BC85BAFA6634597D265AA185FE6555194FF5D2018;
defparam q20_0_s6.INIT_RAM_33=288'hACFD27EF7827FDF4B47A7D5BF735FEED6A705A9D1553252AC14ABF52ADD5FED5FEAD9FA9;
defparam q20_0_s6.INIT_RAM_34=288'hCA3F748FBCCEE728F8C4EEF13B8C24FEDE7FC4EFF28FFBF9FED4FFAA5EEE9388FCE30937;
defparam q20_0_s6.INIT_RAM_35=288'hEA1D79DFFFFEFFDDBFCCEFF737FFFEFFE83FFFEFF9DFFF4BFBD2FBEF6EB5E3CD23E733B7;
defparam q20_0_s6.INIT_RAM_36=288'hDF7FFFFBFFFEFFFFBFFFEFFFFBFFFEFFF2FFFFEFFE83CFA0E7E839FFEE3FFB7FF5DBBDB5;
defparam q20_0_s6.INIT_RAM_37=288'hFFEFFFFBFFFEFFFFBFFF5FFFD7FFFEFFFFBFF4BFF88BFE22FF7DFFE22FFA87FF21FFB33F;
defparam q20_0_s6.INIT_RAM_38=288'hFFEFFFD7FFF5FFF2FFFA0FFFFBFFFEFFFD7FFCBFFB33FEA1FF737FFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_39=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_3A=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_3B=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_3C=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_3D=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_3E=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.INIT_RAM_3F=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s6.READ_MODE=1'b0;
defparam q20_0_s6.RESET_MODE="SYNC";
  pROMX9 q20_0_s7 (
    .DO({DO_5[35:18],q10[5:0],q11[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s7.BIT_WIDTH=18;
defparam q20_0_s7.INIT_RAM_00=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_01=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_02=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_03=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_04=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_05=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_06=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_07=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_08=288'hFA29FE852FA09FE7FCFA3F3EFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_09=288'h9BFF91FFE9BFFBCFFEEFFFBEFFEFBFFBEFFEFBDDBED4DFB13BEB24FA9EBE9D0FA5EFE8FC;
defparam q20_0_s7.INIT_RAM_0A=288'hFA5EFE728F96A7E4FFF9157E400F8EAFE380F8D58C32B34D5A43ABE4E00F42BE9157B4D5;
defparam q20_0_s7.INIT_RAM_0B=288'hE9BF5167E9D94FD5FEF57F93629F994E9629516A7E5FEFDBF7FA54FE69BE9D04E6994951;
defparam q20_0_s7.INIT_RAM_0C=288'h9DFF127A79DD4A77FC9DCA3B6D34333BDBF9FAC913A7A4A7427A25E6743E8D19609E577D;
defparam q20_0_s7.INIT_RAM_0D=288'hFA347EE7B4F737DDCDA2E912ACF4AD3E4B79E674108FC9A1F3B82799F4BB7A799E9E67A7;
defparam q20_0_s7.INIT_RAM_0E=288'h4B28D2B7992B3CFAFAE6B3D0951EE29FB8A79E14A77FCF5FF127FCA1F4BD7FC4DFF137A7;
defparam q20_0_s7.INIT_RAM_0F=288'hE689509A6965ED0926423F11926463F278FCF23452A254A347C8D1F3FFBDFFE9FB327D4D;
defparam q20_0_s7.INIT_RAM_10=288'h3DDF5077D41DF6677DEDDF5177D9A09D1FFEF3FD7BF2147933BD4D32F3B8BF99328F7B24;
defparam q20_0_s7.INIT_RAM_11=288'hEE897BAA5EFFF90FA09BB33BD4D9788BEB4F2E9423AA5DE8978926921F0E7FC39F48E77D;
defparam q20_0_s7.INIT_RAM_12=288'h93FFB9F21FB88BED4DFBA84DBF98E9EB8A253A7EF69FB8E940FA7A96B3FBACF429EBBAFA;
defparam q20_0_s7.INIT_RAM_13=288'h8B888BC24E2D3CDAA58E94239FBE674399A6925ECF97B3E698F9D03E9EA4FFE97FFA4FFE;
defparam q20_0_s7.INIT_RAM_14=288'h875E22D4DE35E38D4DE75E24CA33B28CED23E7FFB9FFEE7FF8FFFE8FFFBEF21FBE83ECCE;
defparam q20_0_s7.INIT_RAM_15=288'hDFE821E22337DE1FFEDFFF8CFFE37FFBEFFEFBFFBEFFEFBFFBEFFED7E83EE4CDB7361DCD;
defparam q20_0_s7.INIT_RAM_16=288'h8BFF8BFFED7FFBEFFEFBFFBEFFEFBFFBEFFEFBFD7EF21FBD2FEF21FBFF8BFFEDBBDB6EA1;
defparam q20_0_s7.INIT_RAM_17=288'hFBFFBEFFEFBFFBEF4BFBA87EE22FB737EDCDFB734BDCDDB7361D788748F7DA287FF8CFFE;
defparam q20_0_s7.INIT_RAM_18=288'hFBF2FEF76FBBDBEE4CFB9DF5ECCFBBDA0F2133A876FFE87FF8CFFE33FF8CFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_19=288'hDB3E21CCE8728E1D23DBFFB6FFE2FFFA1FFEDBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_1A=288'hFBFFB5FFE83FFA0FFEFBFFBEFFEFBFFBEFFEFBFFBEFA0FBC87EE77FB88BEE4CD73E20D4D;
defparam q20_0_s7.INIT_RAM_1B=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEF4BFBB33EE4CFB88BEDF7FB68BEDA2FB68BEFFE;
defparam q20_0_s7.INIT_RAM_1C=288'hFBFFBEFFEFBFD7EFA0FBD2FEF76FBD2FEEF6FBDDA0F4BDBFFA0FFE2FFF8BFFE83FFBEFFE;
defparam q20_0_s7.INIT_RAM_1D=288'hF994FE5FEF9753E5A9D5AA35FFEFBFFBEFFED7FF8BFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_1E=288'hF3FFA7FFEF3FF92FFE47FFBEFFEFBFFBEFFEFB48FEAFAFA7EFE8D1FA09FE77DF9CA3E6A8;
defparam q20_0_s7.INIT_RAM_1F=288'hFA09FE5A9F9003E32BF895FE202F875FE1AD2C60A31589060BA1AD406B6622C44A05132B;
defparam q20_0_s7.INIT_RAM_20=288'h453FD2455F90AFF40055001540054F56B400ACD58042B013FD690002148087C0209D57D2;
defparam q20_0_s7.INIT_RAM_21=288'hA55FE957FA54ABF57F512ABD4AA4F0915AA5AE49AA852A5E9D47FC99DF4E6A8F194D157F;
defparam q20_0_s7.INIT_RAM_22=288'h01B4EBC2756DE40AFAAA499487C523F268D195BF7C6299D5FD252A4935514809D2ABE4D5;
defparam q20_0_s7.INIT_RAM_23=288'hA6BEBE97B423F269263E49A77529DD4A76FD4D9FBE629FD8A6A5D455752A5FE018A405FE;
defparam q20_0_s7.INIT_RAM_24=288'hE5CA276A89D9FBC5FEF575135FE4D753F5A9A96A7F6D3A97FAA5FEABFF95FCBFF33BFBA4;
defparam q20_0_s7.INIT_RAM_25=288'hA12013480F92013480F9203E4AAA55513FA1FB8893CA34EE93DACF4A54649A6967EFB7FC;
defparam q20_0_s7.INIT_RAM_26=288'hA5BF7E7FCFBFFA9E22A6DE53B79A2894B926E209E58A739DF4F5FEF1553C4FFED2AA7480;
defparam q20_0_s7.INIT_RAM_27=288'h9F9327BF92EFE77A508EE9109A6EE09FB7A7E9D4B9752EDFF1287CA214BE7D2A5E9FE7D2;
defparam q20_0_s7.INIT_RAM_28=288'hE69EA287CEDFF2677D45CA3B6A8459F926299D8A525D4498A68629A1B4FDFFEF7FFA8E77;
defparam q20_0_s7.INIT_RAM_29=288'h41E9D27D29DFF127D24A09E875249F4A87D2F7FF93FFE4FE829F219F8890C4E8AF3BE9A6;
defparam q20_0_s7.INIT_RAM_2A=288'hF1DF7C77DF214A7FFE9FFFBCFFEF7FF8FEA13F68A1DA2FB3E23DF7929423951EA29FA827;
defparam q20_0_s7.INIT_RAM_2B=288'hF7FFBDFFEF3FD7EDF7FB5E3EA7A8674229D03A740E9513E1F237D291F48F7D295F4917A7;
defparam q20_0_s7.INIT_RAM_2C=288'hFB138CC4EDEF3B7BF9EA9EA5A7A3A5EE59514654679514A3F3C8D14A1F279519FFFBDFFE;
defparam q20_0_s7.INIT_RAM_2D=288'hE6698E9FB32698E87CEA09FA7FC9609E5827EE9426FFE43FFBCFFE9FFFA6FF5FBD2FEFFE;
defparam q20_0_s7.INIT_RAM_2E=288'h4614917FC9DD4A77A79FFFBCFFEF3FF91FFEEFFFBEFFEFB68BEDA282DE61B7932F3A3BCE;
defparam q20_0_s7.INIT_RAM_2F=288'hF3FF91FFE9FFFBBFFEFBDDBEE22FB5E3ECA32F9337E77369EB99513E29FA82742149177D;
defparam q20_0_s7.INIT_RAM_30=288'hFBFFBEEA1FB33BEC7986F3A1AA5DE7438951DE14B98D1EA09FA7D23E09D07D241DF51FFE;
defparam q20_0_s7.INIT_RAM_31=288'h3694399A6E6498E8A73E29CF8D13A3F2687C463F128FC4BFFBCFFE4BFFBCFFE9FFFBEFFE;
defparam q20_0_s7.INIT_RAM_32=288'h8D202442B9500103D5ED357BFFE9BFFBBFFE43FF91FFEFBFD7EECCFB68BECCE8713B8C79;
defparam q20_0_s7.INIT_RAM_33=288'h4FFFBEFFE53FFA9FFEA3FFBEFFEFBFFBEF76FAD3FE926FA09E16FD8994F85A991550E4D5;
defparam q20_0_s7.INIT_RAM_34=288'hFA09FE8D1FA1F3E752F99FBE5FEF96A7E57F8D3FFA4FFED4A9152A9D553D5A9A18A686FD;
defparam q20_0_s7.INIT_RAM_35=288'hE3093BB794ADE68B4FFADE69B2452F3A9C24FF28FFC24FEDE54B7D52B3E9B244E547D8D1;
defparam q20_0_s7.INIT_RAM_36=288'h3B28F9D2393537AD4D437DD0DF743FFBBFFEEFBDA6FCB43737DDF73F5E0ECF8E748CFD23;
defparam q20_0_s7.INIT_RAM_37=288'h3B88A3FFEE7FFA3FFE93FF8EFA0EFFF8DFFE8FD2E3FF5E77DE4D783B48F9CF83F28F9CA3;
defparam q20_0_s7.INIT_RAM_38=288'h37FFBEFFEFBFFBEF2187E80CFFEDBD2F6F2137C84DE77E3BDA3E223B88A3EA13B7378D78;
defparam q20_0_s7.INIT_RAM_39=288'hFBFFBEFFE2FFFBEFFEFBE822F7637DDB8F21E3C84EEA13BD2CEECC3BFFA3FFE3BFFB9FFE;
defparam q20_0_s7.INIT_RAM_3A=288'h2FFFBEFF583DD8CF2133A861F212FFFA1FFEDBFFBEFFEDFFFA1FFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_3B=288'h8FFFB8FFE8FFFA3FFE8FFF8DFFE8BFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFF5;
defparam q20_0_s7.INIT_RAM_3C=288'hDBFF8BFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFF8BFFEDFFF8DFFEE3FFA3FFE;
defparam q20_0_s7.INIT_RAM_3D=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFF8BFFE83FF8BFFEDBFF8BFFE87FFA1FFE;
defparam q20_0_s7.INIT_RAM_3E=288'hFBFFBEFFEFBFFBEFFEFBFF8BFFE2FFFB5FFE2FFFA1FFEDBFFB5FFED7FFBEFFEFBFFBEFFE;
defparam q20_0_s7.INIT_RAM_3F=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s7.READ_MODE=1'b0;
defparam q20_0_s7.RESET_MODE="SYNC";
  pROMX9 q20_0_s8 (
    .DO({DO_6[35:18],q9[11:0],q10[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s8.BIT_WIDTH=18;
defparam q20_0_s8.INIT_RAM_00=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_01=288'hFFEFFFFBFFFEFFFFBFFF5FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_02=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_03=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_04=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_05=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_06=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_07=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_08=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_09=288'hFFE9BFFA5FFE93FFA3FFE9FFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_0A=288'h8FCFE29FF87CFE14BF951FFFFBFFFEFFFFBFFFEFFFFB9FFED7FFB0FFEB7FFABFFEA7FFA7;
defparam q20_0_s8.INIT_RAM_0B=288'hFFEA7FFA5FFE83FF9DFFE6FFF9BFFE5FFF98FCB5F6899CA356DE55ACF5689599D0665457;
defparam q20_0_s8.INIT_RAM_0C=288'h92689F4A16A8817FA057F814AA54AA9D201B48065201B48085203042BB52ABF57FA994EA;
defparam q20_0_s8.INIT_RAM_0D=288'h5FE6575195D46D751B5D4719FA167EBDD4AC852B629E78FC9ABFA5A50927EE5AFA9A9424;
defparam q20_0_s8.INIT_RAM_0E=288'h827863F3197BBA7EED9A6C63469CCE96D3E79D08A1F2087C7609DD82771F49B7286D94DB;
defparam q20_0_s8.INIT_RAM_0F=288'h926BFA8A9D78A313A9D239EBEA5AFA8E89609A67E545F8A77E149F7FC7DFF1D7A779F49E;
defparam q20_0_s8.INIT_RAM_10=288'hC24AE94299519E54669519629E585291FF257D28DF4A57D295E9E77A7DDFF338A7C23F37;
defparam q20_0_s8.INIT_RAM_11=288'h7FC95E9E577D95D4A772899CA276FDA1CA3F752F5DF747D2DE29F3ECDC333AFACFCEC931;
defparam q20_0_s8.INIT_RAM_12=288'h97BC269ADA25FE69BFA7AFEB3F7B24CB8873D4DCF1E7BBF9D2BEADBF9AB0927A259E3465;
defparam q20_0_s8.INIT_RAM_13=288'hA50E3093FFFECFE835EA1CB28F2CF8BF736DCF8B3092BAFAAE896B9D0AE5EEC97BAA5EEC;
defparam q20_0_s8.INIT_RAM_14=288'hECCF30938D4DD70933BF9C6A9709D0C669B197BBE5EEF97BB669AD9A6CA743FA50FE943F;
defparam q20_0_s8.INIT_RAM_15=288'hD23E71E7AC4EEF1E7AC4EE713B9C4EDF33BFCCEFF48FFC4EFF33BFCF8FFFFBFF76F7933A;
defparam q20_0_s8.INIT_RAM_16=288'hD23E333BDCA3FF13BFC4EFF093FBCEFF48FFFFEFFFFBFFFEFFFFBFFFEFFC87FE77EF7DFB;
defparam q20_0_s8.INIT_RAM_17=288'hE4CFF933FFF5FFFFBFFFEFFFFBFFFEFFFFBFF4BFF88BFFFEEF933CDF7EB7DF9D23EB88B9;
defparam q20_0_s8.INIT_RAM_18=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFD2FEF21EFFFBBFFEF3F2F9ECCE7A87BECCFFA87F;
defparam q20_0_s8.INIT_RAM_19=288'hEF6F768BCD78F3933CECCEFA87DE77F788BCDCDF7737FD4DFF7DFFE4CFF7DFFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_1A=288'hE4CFF7DFFDF7FB68BEDCDFF737FE77FFD2FFFFEFFFFBFFFEFFFFBFFFEFFFFBFFCBFFFFBE;
defparam q20_0_s8.INIT_RAM_1B=288'hF4BFFFFBFFCBFFC87FFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFD2FFF76FF9DFFF4BFFD2FF;
defparam q20_0_s8.INIT_RAM_1C=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBEFCBF7D2FEECCFFA87FE77FBD2FF;
defparam q20_0_s8.INIT_RAM_1D=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFF4BFFFD7FEF6FFFFBFF4BFFFFBFECCFF933FECCFFFFBF;
defparam q20_0_s8.INIT_RAM_1E=288'hFCB87C860F217FBD9FF218FC87FEF6FFC87FF76FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_1F=288'h6FDFDAA3F67EFD94FF752FFFFBFFFEFFFFBFFFEF7FFB4FFEC3FFABFFEA7FFA6FFE97FFA3;
defparam q20_0_s8.INIT_RAM_20=288'hFFE97FF9DFFE5FFF95FFE4FFF93FFE3FFF90DCD3AE912AA53A5ECD8D13A09D27D249D48F;
defparam q20_0_s8.INIT_RAM_21=288'h728616A5645558EAD532B5CC05B2816C95D322C408B1222C608B292029895EF32B8D1563;
defparam q20_0_s8.INIT_RAM_22=288'h38040D59032B44C05232B48E0173D5A53FE65A9A19F9F62982555F8A77E29E387C79F499;
defparam q20_0_s8.INIT_RAM_23=288'h5A959AA2967E9DCA266FDAD7FA09D07A34627D26D8A57629557F945FE4D551248048F552;
defparam q20_0_s8.INIT_RAM_24=288'h629BEF4A0B2482A963A5076345BA256614957A751CA1367E518A545D4515FD357F4D5FD3;
defparam q20_0_s8.INIT_RAM_25=288'h85271DF5B6D365B4D967E657F9957F614A994D55D35594D565355B4D5BD4AAC5FEA98A65;
defparam q20_0_s8.INIT_RAM_26=288'h52A5935574805D0AD842B610019400690AFD42BCD202A4D5BD6A6BC248E7EE37D2968960;
defparam q20_0_s8.INIT_RAM_27=288'h629798A606D3FD94F96FDD1DF697A79EF3E7AA5A65EED9A69DFF1F7FC7209D9752618A57;
defparam q20_0_s8.INIT_RAM_28=288'h67EB5FF38FF69F88A6C4E968967CA3968961A507AA95D8FC75FF1C77D71CA1D6FD6DB4DC;
defparam q20_0_s8.INIT_RAM_29=288'hAA59E3F21A2581F49F7FC7DF49C6A87594DC5FE6D751B6296594D867E8194FB6D3E19FBF;
defparam q20_0_s8.INIT_RAM_2A=288'h87C8DF4A177D85E9E07A781FF1F77D7609EB8D1FDF4BC728FDE9F287CB37DF4CA3A6D3E9;
defparam q20_0_s8.INIT_RAM_2B=288'h97B75D49D6D38DAA3F6FDFD9FBF653F1F4B6F20BF9333D78B73E32AFAB29EABA25A25EE5;
defparam q20_0_s8.INIT_RAM_2C=288'h8D1FE547B7FCDFFFB7FFEA7D2EAC24BEFE68951967EE287C86499F7A77E09DE7D279F49D;
defparam q20_0_s8.INIT_RAM_2D=288'hDF7BF3E2FC24E6FE71A50AEE92BA7AA214A88279E09E687C9E09E385289FF268D1FE3F3F;
defparam q20_0_s8.INIT_RAM_2E=288'hA508E34638A78A3F229A68A9423A7A8E69A58FC9E3F3F852FE5EFF852FA14BAFFEE7FD74;
defparam q20_0_s8.INIT_RAM_2F=288'h9268614A382789FF257D2FE09FF8FCFE943FA7AF7FFB7F4BDF88AFCF8AEDE69B4FA733A5;
defparam q20_0_s8.INIT_RAM_30=288'h926FE49BF8FCFE29FFFFEF3FFBAF4BDF68B3EF6DF092DB4FAED3EBAFAAE7EE9A7A9E8965;
defparam q20_0_s8.INIT_RAM_31=288'hFFEDFC86DD4DBF28F3B4FAEC92BACFBE9426CA38E94218D1861F1F8277E149F87C82897F;
defparam q20_0_s8.INIT_RAM_32=288'hE4CCAC92EAFAAA89699D09E54679269A29E79269E3F258FCFE547F827FE09FF9A6F3FFB3;
defparam q20_0_s8.INIT_RAM_33=288'h8276609D77FC5DFF167FC6A09FF827FE14BF852FE3F3FFFEFFFFBCFFEE3DDB3DF7C3092F;
defparam q20_0_s8.INIT_RAM_34=288'h4D5FD203F455FD0AFF52AFFFFBFFFEFFFFBFEA1D3A86BC249EF3A3ACF82741DA5072A95A;
defparam q20_0_s8.INIT_RAM_35=288'hFFED7FFA5FFE7FFF9CFFE67FF98FFE5FF2D6BA4565ED587C55D4976A85D7F985A9654A9B;
defparam q20_0_s8.INIT_RAM_36=288'hCCEBE942D97BB23469852A609E9752A5DF656FD95F4A46D39DAA2F6D3B5DF6F7A7B5BF6B;
defparam q20_0_s8.INIT_RAM_37=288'hB4FC6E934AFABEBEB2AA5C35373C4EE649B7926D229F4A50BF34B0C24C748EDBA4B6D3ED;
defparam q20_0_s8.INIT_RAM_38=288'h97BDE5EFF9D0FE7EFFA25F2B3FBD7CF733BBD23DEE935B24CEBEB2AA5CE9EB2AA5CEBEB3;
defparam q20_0_s8.INIT_RAM_39=288'hBA4FF747FD23FF7DFFD78FF68B8C79D713B3B79CEC933AA5CE9433A25CE74329D0CE7431;
defparam q20_0_s8.INIT_RAM_3A=288'hE4CFF9DFFE77FB933BDA2E768BAD23F7093CBCEEEE93FB79E6E93AB79FEC93FB24FED3FF;
defparam q20_0_s8.INIT_RAM_3B=288'hFFED3FFB3FFED3FFB4FA0D3C875EF6DBC87FFFEFFFFBFF21FFFFBFFFEFFFFBFECCFFA87F;
defparam q20_0_s8.INIT_RAM_3C=288'hF76F7B33FE77FFB33FE4CFFBDBFF76FFFFBFFFEFFFFBFFCBFFFFBFFFEE7FFB7FFED7FFB4;
defparam q20_0_s8.INIT_RAM_3D=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFF5FFF2FFFFEFBFFBFFFEF7FFBDFFEF3BDBC;
defparam q20_0_s8.INIT_RAM_3E=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEF7FFBCFFEF7FFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.INIT_RAM_3F=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s8.READ_MODE=1'b0;
defparam q20_0_s8.RESET_MODE="SYNC";
  pROMX9 q20_0_s9 (
    .DO({DO_7[35:18],q7[5:0],q8[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s9.BIT_WIDTH=18;
defparam q20_0_s9.INIT_RAM_00=288'h93FFB9FFE97FFB7FFE87FFB9FFEDFFF8EFFE93FFA5FA043DDBBFFE43F2D0FFE43E83BFFE;
defparam q20_0_s9.INIT_RAM_01=288'hDFFFA3FFE3BFF8EFFE3BFFB9FFE3FFF8FFFE3FFF8FFFE3FFF8FFFEE7FFA4FFEE7FFB9FFE;
defparam q20_0_s9.INIT_RAM_02=288'h33FFA2FFE37FF8DFFE8FFFB8FFE8BFF8DFFE37FFA3FFE8FFFB7FFEE3FFBEFFE2FFF8CFFE;
defparam q20_0_s9.INIT_RAM_03=288'h8FFF8DFFE37FF8DFFEE3FFB7FFEDFFFB7FFEFBFFBEFFEFBFFBEFFE2FFFB6FFE87FF8BFFE;
defparam q20_0_s9.INIT_RAM_04=288'hFBFF8BFFEFBFFBEFFEFBFFBEFFEFBFFA0FFE2FFFA1FFE83FF8CFFE8BFFA3FFE37FFA3FFE;
defparam q20_0_s9.INIT_RAM_05=288'hFBFFBEFFEFBFFBEFFEFBFFA0FFEDBFFB5FFED7FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s9.INIT_RAM_06=288'h83FF8CFFE37FF8DFFEDFFFA2FFE8BFF8CFFEDFFF8CFFE33FFB6FFEDBFFBEFFEFBFFBEFFE;
defparam q20_0_s9.INIT_RAM_07=288'hDBFFA1FFE87FFA1FFE87FFB6FFE87FFA1FFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFB5FFE;
defparam q20_0_s9.INIT_RAM_08=288'hD7FFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEDBFFB6FFEDBFFB6FFE;
defparam q20_0_s9.INIT_RAM_09=288'hFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s9.INIT_RAM_0A=288'hFBFFBEFFEFBFF8BFFE2FFFB6FFE83FFBEFFED7FFBEFFEFBFFB5FFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s9.INIT_RAM_0B=288'hFAA97EA50FA897E9FBFABEBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFEFBFFBEFFE;
defparam q20_0_s9.INIT_RAM_0C=288'hEFFFA6FFEF3FF91FFE43FFBEFFEFBFFBEFFEFBFFBEF4BFB933ED23FB1E7EBCEFADE7EAFA;
defparam q20_0_s9.INIT_RAM_0D=288'hFA347E8A7FA1F3E87CFA1F3E87CFA3F3E87CF9D4A28D18E69B97FC3DD4A577D418A50752;
defparam q20_0_s9.INIT_RAM_0E=288'h9D6A7D5544D4ABE52AA54AA9554517FBE5A9F96A7F6A8A63469A29A65ED49D0A2743C926;
defparam q20_0_s9.INIT_RAM_0F=288'h51B4D56D355CA3F7D2FEB3FF8FC52FE3FACFA669A897B4AD3E3BA4925465752959F905D4;
defparam q20_0_s9.INIT_RAM_10=288'hFA14BECA7F6FE7BC794A69BBB249E7439A253E94268D1F1F49177D9DBF686D34DBF69728;
defparam q20_0_s9.INIT_RAM_11=288'hEE743E8D142346685245F4BB7A7EDE9D17D249D4A8752A1DF7E7D2A5DF7E752F9D494752;
defparam q20_0_s9.INIT_RAM_12=288'hEE09FA8273DFF3C7D249E9D27A7F5E9E88524A54688FCA2547D97B4ADF7EACFA2A967AA5;
defparam q20_0_s9.INIT_RAM_13=288'h4A1F28827F609FD87CF629D28D14A5452FF5F768BCB4FF2943C9519E5479951921F24852;
defparam q20_0_s9.INIT_RAM_14=288'hA2FE68AA5A35F28CCE4F093DB24EEBE93CA396C93ABF946A94E97B9A346587C9E1492827;
defparam q20_0_s9.INIT_RAM_15=288'hF313BBB24E2F3A3BA43AA950A5042A951AFA9AD3E6AFAF29E92A7AF6BE93B794E897E97B;
defparam q20_0_s9.INIT_RAM_16=288'hEB093CBA4EAE93BB249AC927B24F2BEBCAA54AA967AA5F6BEA7BCEF2DE7CE504B68A7D4D;
defparam q20_0_s9.INIT_RAM_17=288'hE69EBAA50EE897C9D0467411A2546D3FCBCE47FF92FFE9BE83BF769BD2CEFFE933E3AC4E;
defparam q20_0_s9.INIT_RAM_18=288'h4ADE7CBF9F31392FFE9FE812EF69FD2D0C79EF48CDB79DEF3A2CA392C90DACFEAA964A7A;
defparam q20_0_s9.INIT_RAM_19=288'hE7FFBAF4B3FC877DCDE3BDB9ECC3BFFA4DF7977365E4C975E3AC24471392C24F2FE52B24;
defparam q20_0_s9.INIT_RAM_1A=288'hE2DE4EBCEE748CEB793EBE8EACFE6A965AA542A966ACF9AA950A7A9AB3D0BA497FF8FFFE;
defparam q20_0_s9.INIT_RAM_1B=288'hE73E24C79EF28E6C24F30911C2447093CBF9F328FCFFE9BFF91FF5EF9339D23FB1E76DCD;
defparam q20_0_s9.INIT_RAM_1C=288'h9B1E66C24430926D239BFFA6FFEEFFF90FCBE7A87EDCD8768A2C4E8B3E0EFFE3F9DF8CF8;
defparam q20_0_s9.INIT_RAM_1D=288'h97FF90FFE97FF8EEF6FBFF8BDCDFBA861DA2E33E39CF83B3E39D788FC87ACA3EFBDA6C79;
defparam q20_0_s9.INIT_RAM_1E=288'hFBDD8CDCD339337FFE37C84EDA23F28F9C4EE728E5C79433390E2297A850FFE43E825FFE;
defparam q20_0_s9.INIT_RAM_1F=288'hDF3E24CCE8F48E5D4D9B48FBE779BB326E779B88BBDA297FFBBFFE97FFA3FFE93DDBEE77;
defparam q20_0_s9.INIT_RAM_20=288'hE5FF227A7E5DF63752EA14A4FFEEBFFA4FFE3BFF8EFFEFBFFBEEA1FBB338DA28FA878D4D;
defparam q20_0_s9.INIT_RAM_21=288'h9FFF92FFEA3FFBDFFEF3FFBEFFEFBFFBEFFE2FB322CA336E90DA7AE6740D926E63464852;
defparam q20_0_s9.INIT_RAM_22=288'hF9CA3E728F9BF7E6D3F9CA3E752F9E9FE752DDBF4E6533DD4A5653ED4A915D4F12ABC653;
defparam q20_0_s9.INIT_RAM_23=288'hA1003E3D5FCEAD43D5FCEAFF3D555202A42B550AD552AADF4AA8D5FE09D587C5209FD7A7;
defparam q20_0_s9.INIT_RAM_24=288'h014A8052A596A4067EAE5EEB752026A958FC0229FE8274A9E8F92641FF115D4ED3FD142B;
defparam q20_0_s9.INIT_RAM_25=288'h559F94C274EDE67BCEF61F119519229CF852EA7EFC7FC9DAA12629497514554FD5FD557F;
defparam q20_0_s9.INIT_RAM_26=288'h9E1F3F75245E9D26FD49AA12629497F915D4495FD3554A55FD45A9A95FFF57F5575155D4;
defparam q20_0_s9.INIT_RAM_27=288'h9DAA3C629397FA75A9496A535A9F96A69629F9D4A96D3F9CA3E7D2FA95149A6FE54538D1;
defparam q20_0_s9.INIT_RAM_28=288'hF9AA14653519F946A8A5AA3E6D351DF69DCCA6F3A89D0F649927D249FF24852E9CA236FD;
defparam q20_0_s9.INIT_RAM_29=288'hA67EFF852FF3F3FC4EA6E929A509E7EFFA7A4649BBA504ABE908A79DF4BC7289DBF686A8;
defparam q20_0_s9.INIT_RAM_2A=288'hF71392A25E28979AFAEA743C926F229D18FC4A897B8FC9E14A89264E29FE87CFA1F297A7;
defparam q20_0_s9.INIT_RAM_2B=288'h46D3FD9A64249A78FCF629FD8A74E1F297FCFA14BE7A7F9E9FE9FB4E347EE264F5E3ED4D;
defparam q20_0_s9.INIT_RAM_2C=288'h99F49077DF1CA286A8F5AA3D728F609E88FC4FFFBEFF54B9DD2DF74BA863C249713A7B79;
defparam q20_0_s9.INIT_RAM_2D=288'hFA14BE8D1FA5ED4ED0A78893DA2A368A7AA5FB1E4B926363F399D036B3CFA509249A5827;
defparam q20_0_s9.INIT_RAM_2E=288'h9388A7CCE9AF38DB79E6BEA5C24435E3CAFA9E743C8FC4A69BC8A74A29E88A74E14A9827;
defparam q20_0_s9.INIT_RAM_2F=288'h3A3F269264269908D19A14A67D239DF7C77D9DDF5277D49DF7D728F5DF678524BFF91F21;
defparam q20_0_s9.INIT_RAM_30=288'h9A54509A69E743D951A249BD9514E5EFD8FCF6547DFFEA3FD52D4D4B13BBB244ABEA4A25;
defparam q20_0_s9.INIT_RAM_31=288'h4A29D28524A1F289D0A3FF92FFEF7D2FDE229B338CB7936F38EA25929EA5AFA9E7EE597B;
defparam q20_0_s9.INIT_RAM_32=288'hF3FFBCEF6F348D0BF9DF1E4DACF8EB3CFAFA969E909A6923F119A6EE9EA787C4A3F127FC;
defparam q20_0_s9.INIT_RAM_33=288'hFB888EA25329E8EB7992743B97B9A3F118A79A3F128FCF23F2797B9E743D8FCF269A7FFE;
defparam q20_0_s9.INIT_RAM_34=288'hEE14BB827961F3C87C4A14BD9A6F65EE797BF654528D14BFFBDFFE9FBD91D23F3093EB24;
defparam q20_0_s9.INIT_RAM_35=288'hED9FA7629F57FA75D4F5B4FCFFEF7FFA7FFE9BA851D78FB33B69A632D3E19A692B3D09FB;
defparam q20_0_s9.INIT_RAM_36=288'hA7FF94FFEA7FFBFFFEFBFFBEFFEFBFFB7FFEE75365B2492897A8FC9A14917A795D4916D3;
defparam q20_0_s9.INIT_RAM_37=288'hFAB3FE9A6FA1F3E7FCF9D4BE6FDF99FBE653E18A4F6534194E7653F18A52653F5BF7E7D2;
defparam q20_0_s9.INIT_RAM_38=288'h96547B926EE499095142547B9D0EE7EFBA50EF0910B2442FE7BCA7F2FE7AB4F4AFE52CF8;
defparam q20_0_s9.INIT_RAM_39=288'hF30927CA3F36892E224B9DE7C794BFFA7EA14AF391B4F96BEA79A6E65EE49D03E7ECF9A6;
defparam q20_0_s9.INIT_RAM_3A=288'h973E3BFA497BD8FE4C3BD2E3F764B9DE4EA1E77DE4DA29328CFC4EEAFE65BCEEEE911BA4;
defparam q20_0_s9.INIT_RAM_3B=288'h3BFFBCDF73B338DCF88F48F9C4EE6F38FBA492DE77B7992DE7AB79EADE65BCE4313BAC79;
defparam q20_0_s9.INIT_RAM_3C=288'h3B5363CF8E328F9C4E3F138FC243F090FC4E3F13A4C793B33A4DA293FFA4FFEE7930EDF7;
defparam q20_0_s9.INIT_RAM_3D=288'h37FD61FF5DFFFA3FCBE7FF8EFFE3BFFB9FFE3BFF8DFF5DFDDA0F4BEF888DE2237688BDA2;
defparam q20_0_s9.INIT_RAM_3E=288'hE7FF8EFFE93FF8EFFE8FFFA3FFE8FFF8FFFE87FF8CFFEE3FFA3F768FC84EFCBE7FF8EFFE;
defparam q20_0_s9.INIT_RAM_3F=288'hFBFFA1FFEFBFFB5FFE2FFFA2FFE87FF8DFFE8BF2F8FF537F2E3FFEE3FFA3FFEE7FFB9FFE;
defparam q20_0_s9.READ_MODE=1'b0;
defparam q20_0_s9.RESET_MODE="SYNC";
  pROMX9 q20_0_s10 (
    .DO({DO_8[35:18],q6[11:0],q7[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s10.BIT_WIDTH=18;
defparam q20_0_s10.INIT_RAM_00=288'hB4FC2D3F1B79EAE937B79EAD3EFB79E7DEB1ECCC3DDAADCDA79327ECC9F5E27CF89F33A5;
defparam q20_0_s10.INIT_RAM_01=288'hAFAE6D3F4FF9C7D2F1FFEBF932DE77B7FD6DE77B75E2DD23B728EDC79B713AEBCEBEF3AF;
defparam q20_0_s10.INIT_RAM_02=288'hEA1E77378EF6DF48F5BF9D2E935B4FDAC935AFAD6BEB4ACFD2B3F7ACFD6B3FFACFF6B3F9;
defparam q20_0_s10.INIT_RAM_03=288'hEF6D39335DF7D77375E22D77DF7E22DF68B9DF7FF7DFFE4CFF933FE77FFE93BEF6F3933F;
defparam q20_0_s10.INIT_RAM_04=288'hFFEFFFD7FF76FFB33FEF6FFC87FFCBFFFFBEFFEF7FFBAFFEFBFFB9FFEDBFFB4FCBD7BDB4;
defparam q20_0_s10.INIT_RAM_05=288'hE77FFA87FF4BFFFFBFFFEFFFFBEFFEF7FFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s10.INIT_RAM_06=288'hFFEFBFFB9FFEDFFFB7FFEDFFFB8FFEE3FFB9FA0E7C87BF76EFF2FBFA0F7C87FFCBFFBDBF;
defparam q20_0_s10.INIT_RAM_07=288'hFFEEFFFBCF76F3BDBCECCF3A87DE4CF3933CE4CFF9DFFE4CFF88BFE77FFC87FFFEFFFFBF;
defparam q20_0_s10.INIT_RAM_08=288'hECCFFA87FEA1FFA87FE4CFF933FE22FF933FF21FFFFBFFFEFFFFBFFFEF7FFBBF76EFFFBB;
defparam q20_0_s10.INIT_RAM_09=288'hFFEFFFFBFFF5FFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFC87FECCFFB33F;
defparam q20_0_s10.INIT_RAM_0A=288'hFFEFFFFBFFFEFFFFBDFFEF7FFBDFFEFBFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFD7F;
defparam q20_0_s10.INIT_RAM_0B=288'hFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s10.INIT_RAM_0C=288'hFFE97FFA4FFE8FFFA3FFE9FFFBFFFEFFFFBFFA0FFDDBFFFEFFFFBFFFEFFFFBFFFEFFFFBF;
defparam q20_0_s10.INIT_RAM_0D=288'h9FBFE69BF97BFE547FA50FFFFBFFFEFFFFBFFFEFFFFB8FFED3FFAFFFEB7FFAAFFEA7FFA7;
defparam q20_0_s10.INIT_RAM_0E=288'hFFE83FF9DFFE6FFF99FFE63FF98FFE5FFF99FFE5FA855DA25B1E56BCE62C917ACF6A9423;
defparam q20_0_s10.INIT_RAM_0F=288'h8FC561F137FC4DF4937A74DD49375255B4D56FD59BF5C67E857FB4653B9BF687A7AA9429;
defparam q20_0_s10.INIT_RAM_10=288'h52A5D3FD94D5754AA552A855527554C9752F5D4B5B4E68A78F9363D788B28DCAA5667416;
defparam q20_0_s10.INIT_RAM_11=288'h6A89D7FA95D49D7FA672896F3A592A9E1F259517E29DC7526994D95D4615FD75545D4A97;
defparam q20_0_s10.INIT_RAM_12=288'h92696B4E9A25B67423A2586C91F8FC75FF1C75275BF5C6A87194DD653759F9967E6994DE;
defparam q20_0_s10.INIT_RAM_13=288'hA7A76741C9A66E29DB8526DF49D77D75CA1D6FD7594DF653857FA1629C1BF6D6D3B9D4B0;
defparam q20_0_s10.INIT_RAM_14=288'h97B6A5EDA97B6AA95AB4F6EC91DA5096942D97BAA49AB9A696FE6FD7792F3AAA258AF39F;
defparam q20_0_s10.INIT_RAM_15=288'h7FC8609E787CE5FF34827BE14A79A6A7D325DCD9B13A4B797F1E5DBCE6EB3DB9FB6E7419;
defparam q20_0_s10.INIT_RAM_16=288'h7A7AE69A3CA7AEFE65CF892C922B4F7F735FB247E895E9D0765EDE9517E499F87C861F20;
defparam q20_0_s10.INIT_RAM_17=288'h9FBB65469A50965EE37FC8DDF637288DBF616D38DB4E16A891AA256D391AA336D3B9BF69;
defparam q20_0_s10.INIT_RAM_18=288'h9A67E545F9517E499F92682546197B8A69A99D0E67437926DE9EB6B24C2EA35AFAAE9EAC;
defparam q20_0_s10.INIT_RAM_19=288'hBCEBEC92B9FBB69EBB97BD6896FAA5BEBEAEE77AB5E28C79A3BDA9BCE8EFE61C247E941F;
defparam q20_0_s10.INIT_RAM_1A=288'h852CE546FACFB7FFB1F4BB7736FD78B71E68DA29F9DE6CCE9B0927BF99AE927BA4A2F3AB;
defparam q20_0_s10.INIT_RAM_1B=288'hC4EBEF3ACA50968964AA58E896397B8E3F238A78E29E387C9214A58279E14AF827FDFF3B;
defparam q20_0_s10.INIT_RAM_1C=288'hD239ABEA69FB9E69A69519A49A68FC9634678FCB63F3F8FCF254789D0DADE71F4CAF7373;
defparam q20_0_s10.INIT_RAM_1D=288'h97BA25EE99A6AA5471926FE547F97BFE9EBCBCED79431DA2C768ADD23CAD3E9A259E9EA6;
defparam q20_0_s10.INIT_RAM_1E=288'hAA5FE943BACFE768B7FFED7F2EFD4DB748EFC24BEE92AB4F9EB3E7A25A269A79A69E5EE8;
defparam q20_0_s10.INIT_RAM_1F=288'hFFEDFFFB0DA2CB28E8DCD9B68A5DF79AF3A6B249AC927AA5A289679FBA29EB2ACFBAA97F;
defparam q20_0_s10.INIT_RAM_20=288'hDCDBEFE76A50B65EF2926A6346C8D1AE346E8D1BE346F8A7FE29FF8A7FE5475BA4D3FFB5;
defparam q20_0_s10.INIT_RAM_21=288'hA257A5EDD97B72699B9FB7E743FA25FE49BF951FEC936F75DF9335D23C73E37BA4C6E92E;
defparam q20_0_s10.INIT_RAM_22=288'h7A7FDD4BF728FDBF7F7FCFFFFBFFCBFF9DFFDCDE733B1BA4B6FE68CCE971E63B4F86A95F;
defparam q20_0_s10.INIT_RAM_23=288'hFFE6BFF97FFE57FF95FFE4FFF93FFE4FFF94E77471391B4F42895297B4E345387C5DFF1D;
defparam q20_0_s10.INIT_RAM_24=288'h75241B4CE67E3594CE629398A4E5D44175115D4493FD752A752AAF4FFA575236539629E3;
defparam q20_0_s10.INIT_RAM_25=288'h3AB4CE01538064EAE03AB6CF565400C1202D480A55FE17287B3DDDB79767ED79514E1491;
defparam q20_0_s10.INIT_RAM_26=288'h4FF8920254558D202157F86742180085D4A37FC75D4995D4593555480510AD33D54CEAD3;
defparam q20_0_s10.INIT_RAM_27=288'h7A78A55638A7BE346092676A95B82765CA1862965751857F5D551752A5D4A954FF553559;
defparam q20_0_s10.INIT_RAM_28=288'h8525DF4977285D94D75FE595FD75545D4A9655461355A4D56D201D4AABD5FEC554A57532;
defparam q20_0_s10.INIT_RAM_29=288'h8A75A09D58A75694159515A941887C8209E77A795E9E78277EE927C247A942187C7A545A;
defparam q20_0_s10.INIT_RAM_2A=288'h6A86DB4E1728C5B4ED6FDA5BF637D28768A3C4E86BEA5A7A7AD3DAB796689579515E3F16;
defparam q20_0_s10.INIT_RAM_2B=288'h5FE8DFF1DB53A6A95EBF976545B9A66694188FC5E09D77D25DDF5777D65D4996FD6DD499;
defparam q20_0_s10.INIT_RAM_2C=288'h87C99F4A787C7DF49C6296D6A5B5546D4A9A4FF6D3FD94FF753FDF4FF75356E4FFA14AA2;
defparam q20_0_s10.INIT_RAM_2D=288'h7FC5DDF5777D5DDF5775261D49975269DF62827FE14BD752D614AD97BDE7FED951B23468;
defparam q20_0_s10.INIT_RAM_2E=288'h8A7BA09E27A7921F31752B614AA7FCA61F23D79830923ACF7F48E19FB76895AA7A6629D8;
defparam q20_0_s10.INIT_RAM_2F=288'h629BDCA268A79FFFA9E2292E924A7ACE7421AA57B689DC2476DE5DC7976B3DE9A68649A3;
defparam q20_0_s10.INIT_RAM_30=288'hB249269A982781FF1D8D171FF1B7286D9F9B6536D8A5B629718A5D5FE7D8A675FECD7530;
defparam q20_0_s10.INIT_RAM_31=288'hA25763F1D7FC75F49C77D71D49D7286DCA1D72891CA396FDD5D4B17A7B25EE8B7D8AB3EA;
defparam q20_0_s10.INIT_RAM_32=288'h6D37DAA1F6A8859FA7653EDAA376FDC9FF2D97BAB5467CA3C328E3B799E742287C7E345D;
defparam q20_0_s10.INIT_RAM_33=288'h7FCFE09F38A7E6F3B1FFEBBBDA5B249A942597B9A54619267E345E7D281D49D7287DBF60;
defparam q20_0_s10.INIT_RAM_34=288'hE779F48E5B4FA27EE1AA57EC91DAFA76699E85276149F8527DD49D8527A34658278E09FF;
defparam q20_0_s10.INIT_RAM_35=288'h9D096942282775CA206D36D9F9F653758A606299194E3629FD8A7D629EDB4FA8A7B3F2E9;
defparam q20_0_s10.INIT_RAM_36=288'h75261AA176A8599F9575265BF7F77DFD94F7653C5FF2AD24B30929B24929EA597BA23F23;
defparam q20_0_s10.INIT_RAM_37=288'h653FD7FBF5D4FD6A7F6A8FFFFBFEA1FEF3BFBCECE49AB8FC9E29E29A67E941D8FC6DFF19;
defparam q20_0_s10.INIT_RAM_38=288'hFFEA3FFA7FFE9FFFA7FFE9FFFA7FFE9FFFA7D2396BEA99FBA634658278DDF6B72885AA21;
defparam q20_0_s10.INIT_RAM_39=288'h9D0863F208527E09DF7D27DF4A077D85FF227A785D4A3752A1BF707FCB5DF6E77DB649AB;
defparam q20_0_s10.INIT_RAM_3A=288'h728A1AA276A8A1B4EB6FDBDB4F2728CDDF7077DB614AC9D0BB34ADC24AF13A8C7996DE63;
defparam q20_0_s10.INIT_RAM_3B=288'h827C61F3597BCEB3F5BCECAD3F1FFEB7BDADCCEC2DE77AA5BABEABB24A63F28827A5DF69;
defparam q20_0_s10.INIT_RAM_3C=288'hAFACEFF72B4FCEB3EFA7AB6C92DA50B669AD926B6346E87CBE1F30827C1FF307FCBDF4AF;
defparam q20_0_s10.INIT_RAM_3D=288'hBCED75E3ABA4DEA974A50C67EF19D0C67431A25CE7EF59D0DE9EBE9FBE65EF7926DE69BD;
defparam q20_0_s10.INIT_RAM_3E=288'h97BC65471951C2547197BCA69B29D0D2743D9FBEA9EB9B24CEB3F4FFED3BDB1CF8BF68B1;
defparam q20_0_s10.INIT_RAM_3F=288'h9A6FE69BC9A6FE5EFF9A6FE7EF8B4FF3A977DF7DB68B5BF9D70934C24CEDE72A25C669B1;
defparam q20_0_s10.READ_MODE=1'b0;
defparam q20_0_s10.RESET_MODE="SYNC";
  pROMX9 q20_0_s11 (
    .DO({DO_9[35:18],q4[5:0],q5[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s11.BIT_WIDTH=18;
defparam q20_0_s11.INIT_RAM_00=288'h3A9424A25EA897A9FBEA7EFA9FBEA69A49D0EAA97BBCE97090FC24EF3E51C2446D3FCB79;
defparam q20_0_s11.INIT_RAM_01=288'hEED3D1B4F470911E22435366C799B0911CFC471391DA2473391D239B5378BCE3AB3CEAA5;
defparam q20_0_s11.INIT_RAM_02=288'hF313BCC4E478990D78E7534EE223F6891E778FC878FA08F7DF9CCE3F48D0CF8431E66BCE;
defparam q20_0_s11.INIT_RAM_03=288'h3F930ECF88B3E38EA13B534FC4E3EE939B4F8ED3E5B4F96BEA6AA546C926ACF46D3FCBCE;
defparam q20_0_s11.INIT_RAM_04=288'hE37364D4D3F3E3ACF89733BACA3433E10D239728E5D23EF28FBC24EF1E65EA2435E0FC4E;
defparam q20_0_s11.INIT_RAM_05=288'hFB48CCD23E33E0DD23375378DA28B68A2DF78FF3CDF2133D2F7FA033FD4FF2187D2E1E22;
defparam q20_0_s11.INIT_RAM_06=288'h93734EE77E7DD8EFFE3BFD4EEF63BDD8EFFEFBBDBEFA0FBDDA0EA13388A2DA23368BED78;
defparam q20_0_s11.INIT_RAM_07=288'h93D2CFE4CE7FFBEE4CFB7DF6EA133FFB7F21877DFED78DB534DCF88F33A3CF8E73E39D78;
defparam q20_0_s11.INIT_RAM_08=288'hDBDDA0FFEDBFFA1F768BE80EFA0E7E824FF593C879F213BD2E4F4B93DDB9F763FFFA4FFE;
defparam q20_0_s11.INIT_RAM_09=288'h3BFFB7FA037FD4EFFE3BFFA4FFE3BFFA4FFEE7E80FFFEE7FF8EFFE3BFFA3FFE3FFFA1F21;
defparam q20_0_s11.INIT_RAM_0A=288'hDBB337ECC87B322F4BDBFFA2FFE37FFB8FFE37FFA5FFEDFFFB7FFE8FFFA2FFE8FFFB9FFE;
defparam q20_0_s11.INIT_RAM_0B=288'h87FFB7FFE33FFA1FFEFBFFBEFFEFBFFA0FFE83FFA1FFE33F2E1F2183D2FEEF6FBBD8BECC;
defparam q20_0_s11.INIT_RAM_0C=288'hDBFFBEFFEDBFF8CFFEDFFFB7FFE37FF8CFFEDBFFBEFFEFBFF8BFFE87FFB6FFEDBFFB6FFE;
defparam q20_0_s11.INIT_RAM_0D=288'h87FFA1FFEFBFFA0FFE33FF8CFFEDFFFB7FFEDFFFB7FFE37FFA2FFE33FFB7FFE87FFBEFFE;
defparam q20_0_s11.INIT_RAM_0E=288'hDA89609D0DA69B697B869E8BFFE87FF8BFFE83FFBEFFEFBFFBEFFEFBFFBEFFED7FFBEFFE;
defparam q20_0_s11.INIT_RAM_0F=288'hEBFFA5FFEEFFF90FFE3FFFBEFFEFBFFBEFFEFBFFBEECCFB737ECA3FAFE7EB4FFABE8BA7A;
defparam q20_0_s11.INIT_RAM_10=288'hF9DF7E728F9BF7E6D3F9AA3E6A8F98A7E6A8F98A615FE8975386A839BF647D23E544FB79;
defparam q20_0_s11.INIT_RAM_11=288'h3DFF267A7F1DF6877DA609FE9D05229FE67E4D9FBE77DA25468B24F6897C9269E14A67FC;
defparam q20_0_s11.INIT_RAM_12=288'h4E347E9A64DD493752A209FD9FB4EDF53ACFA2B3E7A509A5EE68A7E209F87FC8DF4A37D2;
defparam q20_0_s11.INIT_RAM_13=288'hFA7EFEAA94E7ED2BA4F269BC8D19E14B97FC91E9FC77D49D49075299D4926FD49FF3D728;
defparam q20_0_s11.INIT_RAM_14=288'h4313A58D19A09E77D245DF66752EDCA3C72849CA27728F5CA2877D4DDF687A74DF4BE8A7;
defparam q20_0_s11.INIT_RAM_15=288'h95FF117D245F4BC7D249F4BC7D249E9FC8274A7427A25469E92BA4F6F3FDAA54A5EE79D0;
defparam q20_0_s11.INIT_RAM_16=288'h4A29E8926A2A9529FB9E69929A64A9EA8AFEA29413B799E9EBCC4EF67ECF8FC9614A5827;
defparam q20_0_s11.INIT_RAM_17=288'hFA5EE9AFA4EFF65B4F9EDE7CBF946F3A8F21EAF38FA50EE74119519E3F279264A5EFD951;
defparam q20_0_s11.INIT_RAM_18=288'h9ABEBA9FB929EA5AFA9A49BC87C4609F97FC45FF3C7FCF5DF6877DF5E9E87D24E3F13951;
defparam q20_0_s11.INIT_RAM_19=288'h969EA69FB4A69A797B4A547D9514A69929264A69BD8FCF63F3D951F68968BCEF2B3FC9D0;
defparam q20_0_s11.INIT_RAM_1A=288'hE649A49263E5450926965EE69D096A97BCA39729CFBF93F1390CF8EB68BCC793B13B9AFA;
defparam q20_0_s11.INIT_RAM_1B=288'hF2A967D4DF3093CDCE4B1E67B2446FE50BF946DE63C79E2C90EA7AE67EE49D03E742297B;
defparam q20_0_s11.INIT_RAM_1C=288'h4ABE92AA59ADE51A258E9EB9BF9EAA97A97B923F0D87C9614907FC4614BC85246347C9A6;
defparam q20_0_s11.INIT_RAM_1D=288'h8F338DB4F92943AA25EE9426A7A469412A509E7EFCA504A9EBDAFAF70912D4DF7BDA8CF8;
defparam q20_0_s11.INIT_RAM_1E=288'hEADE7BAA5F2B3D2B249EC927BF9F77352BF9A3093DF259F9DE7DCDF31391B4FF2D3CEACF;
defparam q20_0_s11.INIT_RAM_1F=288'h9A743C9FB469426BA443FF91FFEF37367D239B88A7F76E79339D78EF28CEBCE46F3BCB4F;
defparam q20_0_s11.INIT_RAM_20=288'h4B7DD2DA2473390BF93F33A1C79D788A3CA336C924AA53E940E9FB327ECE9FBEA7EFA9FB;
defparam q20_0_s11.INIT_RAM_21=288'h8F28D0D23437DE6CA39B138EBCEEADE50B249EA952A7AF2897CA509E9412ACF4AE927EA5;
defparam q20_0_s11.INIT_RAM_22=288'h468966A259EA97CACF4A897D9FBF67EFDA254AD3FDC4E9FFFBCFFE4B6891DCD96FE76DF7;
defparam q20_0_s11.INIT_RAM_23=288'hF229D1852F209E67FCF23F26FCAEFBD90E22E77379C79DF1E63C243F33BBCA342D3FBAFA;
defparam q20_0_s11.INIT_RAM_24=288'h9FFF92FFE9FFFBCFFEF3FFA1FFE37FFB9FFE97DD8FD4D3B138EB24969EBB9D0465EE68FC;
defparam q20_0_s11.INIT_RAM_25=288'hF96A7E554F93FFE4D5F92ABE4AAF9203E480D90ACD3D538EAE4480E92A9052AED8A7C926;
defparam q20_0_s11.INIT_RAM_26=288'h45BF7C653F59FA95FEFDB4D572855AA2A4AAFD155452AFDB4E9A51FA3F127A749B4D1653;
defparam q20_0_s11.INIT_RAM_27=288'hFD9FAA951515FD4554FD753F7A7A675299265249A997B4A09F775235BF636D3DDAA246D3;
defparam q20_0_s11.INIT_RAM_28=288'hA9E9EA8D5FE09FE9A6F9FF3D6FD4D94E55FE415FE8554F53FD14FF493FFE52AF9AA2957F;
defparam q20_0_s11.INIT_RAM_29=288'h9E897B6A8F17FBD57F4955274FFF13FD24FFF93FD34D5A53FFE554A55514554FD5FEA653;
defparam q20_0_s11.INIT_RAM_2A=288'hF1B4E76D349AA2767E9D94FC629F5752762949FF3E7FC49E9FE87C52557F8A75209E87D2;
defparam q20_0_s11.INIT_RAM_2B=288'hF99FBE728FA1494852F9E9E877DA614BE9AA523F29BCE4E5467A7A523F267FCEDD4916FD;
defparam q20_0_s11.INIT_RAM_2C=288'h0209EA9A6FE9F909D04A7428AA54A7ED4BCE9AB3E69519A29FC827F5E9FD8D1FA5ED36FD;
defparam q20_0_s11.INIT_RAM_2D=288'h9E547C852A6347B92645E9E86FDA1AA116539D7FBE5A9F94AA94FF51553F57F55B4D57D2;
defparam q20_0_s11.INIT_RAM_2E=288'h99E9D2728A1BF7D6D3A1BF536D3F9B4FE6D351E9D4653A59FBF6FDFDF4A9B7AFA69BD7D2;
defparam q20_0_s11.INIT_RAM_2F=288'hE994E667E9DB4E76A89D9FA76FD9E1F278FC9E9FBC9D09A5467A25F2A97DA253E740F852;
defparam q20_0_s11.INIT_RAM_30=288'hF9F49387CA5FF29CA3A6BE939514E5EE7B244A7424A503A346485241DF51728EDD4B9728;
defparam q20_0_s11.INIT_RAM_31=288'h52347E7A74A89647A791FF24A25EDF4916A84194F85FE9975125A99D7F925D4F594D36FD;
defparam q20_0_s11.INIT_RAM_32=288'hEE347B8D1921F3C8274A09E8827A21F29852F9CA1477DA5F4BF7FCFE345497BFF9DEABA4;
defparam q20_0_s11.INIT_RAM_33=288'hF209D277D4DE9D48FCA65469B24A64994852AA29D5C79FEE929ACFA2DE7DA254DFF257FC;
defparam q20_0_s11.INIT_RAM_34=288'hF1D4A77289DD4928274B29E8BF94EE93D8FC4AB3D4BCE9ABE919D0F65ED18A74A14A87D2;
defparam q20_0_s11.INIT_RAM_35=288'hFAC93EB24F67ED29D0FA89619FB3AA97A92695FF117D241DF7A752E9CA26752F1DF5277D;
defparam q20_0_s11.INIT_RAM_36=288'hEE943CA7A9E54687FCF5E9FB7289DDF7D728F9DF537D251D49475251E9D4827FA3F14BD2;
defparam q20_0_s11.INIT_RAM_37=288'hA1CA3D6A8F9CA146D3A59F946535194D46A8A9E9EA951531F29BCEA7737D9514AC93A9FB;
defparam q20_0_s11.INIT_RAM_38=288'hF59FA8629A17F935D44DB4FDD78A2FE52A7AF25ED1827E23F3A8D1F333928D149F4927A7;
defparam q20_0_s11.INIT_RAM_39=288'h4BFFBDFFE4FFFA8FFE9FFF93FFE97FFB9FFEF35352B24EE897B8FCF214BC7A7F5D4A86D3;
defparam q20_0_s11.INIT_RAM_3A=288'hFABEBEAA5FA7EFE9A6FA69BE97BFA5EFE8D18A5EF9926EA1F1082799FF3C8279E346797B;
defparam q20_0_s11.INIT_RAM_3B=288'hF1D491728F1CA3C728F1D4A777D9DDF677A7F1FF278274A1F27FFE4BFFBCECCF3FD65CCE;
defparam q20_0_s11.INIT_RAM_3C=288'h4254668FC9A14BB8529A14A48D18EDF65ACF46E912A7A9E54638A79209E57D241E9FB752;
defparam q20_0_s11.INIT_RAM_3D=288'hEE698FCFCEB13A6BF9473E26FCBF2DE4EAA53A743997B3E5450926EE3F108FC9A49908D1;
defparam q20_0_s11.INIT_RAM_3E=288'h437DFCBF93AF3A2B4F3AB3E5A7A9689509FB467426951F23F3C8A7F229D19519A743C9A6;
defparam q20_0_s11.INIT_RAM_3F=288'h331E4FC4E971E66F4BEFA851CCE9B5366C799B33A6C7946FE51C4E47FFA6FFEEF1E66CCE;
defparam q20_0_s11.READ_MODE=1'b0;
defparam q20_0_s11.RESET_MODE="SYNC";
  pROMX9 q20_0_s12 (
    .DO({DO_10[35:18],q3[11:0],q4[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s12.BIT_WIDTH=18;
defparam q20_0_s12.INIT_RAM_00=288'h9D0BF89ACD78AF7DEBEA1AFFFABD78A728EEAFAAE896597BA2546D87C9609E37A78DDF63;
defparam q20_0_s12.INIT_RAM_01=288'h9D096742597B9649A58D19E1F268529A14A5852961F2387C8E29E58D1DA34738D1C649B1;
defparam q20_0_s12.INIT_RAM_02=288'h8D18629E18D18E3F278D1B6546F9FBB674359FBCA9433ACFCAC92DBFDAED3E9AFA9E9426;
defparam q20_0_s12.INIT_RAM_03=288'h9FBB6A96FB79EAC935A7AC6942BAA5AF09EFB79CAC92ABCEA30926A509674249518E3F23;
defparam q20_0_s12.INIT_RAM_04=288'hA7AD6BEB0CA7B6FE6BC24AB48E9C79A6DE69B24A2B3E8AA59E9EA7A509E9428A7AA6742B;
defparam q20_0_s12.INIT_RAM_05=288'h9A6FE5479AA5D709359FBD65EF5926DA3F368D1D234778D1E63479926E6547F9A6F2897A;
defparam q20_0_s12.INIT_RAM_06=288'hBCEC2DE6FB24BEB3EFACFBEA96FA7ABE89719FBFEA97FB4FFEFE7ECA3EEDF78ACFE6BEBF;
defparam q20_0_s12.INIT_RAM_07=288'hBA4B2D3EDBCEB6E93FB24FEBEBDB4FE6E937F25EB9DFFECCEFFFB7E4CD37372CA3C6F3B1;
defparam q20_0_s12.INIT_RAM_08=288'hC4EEEF3BEBF9EF943CDA2DB7DF3CA3C733B0DCDC3736FCCEBF13AEC24BB092DCA3B6FE6C;
defparam q20_0_s12.INIT_RAM_09=288'hF21CF48F7D23DF3E33CA3C70930BF9BEF3AEBA4BEE92DBF9B7092FC24C6FE72CA3FF68BC;
defparam q20_0_s12.INIT_RAM_0A=288'hCCEEF33B7C79F333B6CF8EF13B8B79D6D3F3B24D6D3FCB79E6F3B9BCED30936FA4D3BDB1;
defparam q20_0_s12.INIT_RAM_0B=288'hD78EBC879CF8E6FE7AB4FFEC93FB24FED3FEBCEFBFFBCFFEEFDDBCE4CFB737FD4DFF48FD;
defparam q20_0_s12.INIT_RAM_0C=288'hB4FF6E93FBF9F7093BFFEE7FFB7FFEDFFFB9FCBF7737FD78FF48FFCF8F333BDD4DF7737B;
defparam q20_0_s12.INIT_RAM_0D=288'hDCDF3A87CF4BFFBDBEC24EEE939AFADEB3F7AA5DEBEB7A7ADEA978AA5E6A979ACFF2B3FF;
defparam q20_0_s12.INIT_RAM_0E=288'hCCEF713BEBA4F6C93DAFAF2B3FDAFAF2BEBDAFAFABEBFAFAFEC93FB4FFEE93FC4EFF9EFF;
defparam q20_0_s12.INIT_RAM_0F=288'hCF8A73E28D4D9F5367D23AF3E3FCF8FF48FFDA2FF9DFFED0FF88BFDA2FF28FFC4EFF1E7F;
defparam q20_0_s12.INIT_RAM_10=288'hA50FE7EFF9D0FE69BFAA5FFD3FFEA1FF9DFFFF5FF933CEA1E388B3D4DC748EED4DB748EB;
defparam q20_0_s12.INIT_RAM_11=288'hFFEAFFFA4FFE7FFF9CFFE63FF97FFE5FFF97FFE67BD99DF76B339AC2476DE5FB248AA966;
defparam q20_0_s12.INIT_RAM_12=288'hA506E94199FB6E895BAA56AA95B9D06E545BD23721F1E87C91F4B6827CE3475A25D2DE72;
defparam q20_0_s12.INIT_RAM_13=288'h72865BF596A86DBF5D6A87D9FA16A8C1F4AD8FCBA34619268714A7BA49AE91FAFA769E9B;
defparam q20_0_s12.INIT_RAM_14=288'h5A99D752A629999FA27288E14A6CFC9713A1D4D7EB3DE97B761F1C7FC6DE9DA75265D499;
defparam q20_0_s12.INIT_RAM_15=288'h8A7A2DF65ACF8EE921F21873E1FBA47E94219A68629DE7D28DD49F6A86D7F9B5A9756A60;
defparam q20_0_s12.INIT_RAM_16=288'h7A775D49C6FD71AA1D67E7994DF6537594DC6536994DB67E79B4E36D3B5AA2B6FDA9DF6A;
defparam q20_0_s12.INIT_RAM_17=288'h6535D94D867E6D9FAA6A889BF6177D95D4AE7FCAE1F2B8D19E3F25B248A89609267E149D;
defparam q20_0_s12.INIT_RAM_18=288'h752921F298D1B9F4AA7A79A09E19268E7FED9519629DF9FB76499C77D6DBF5A6A8659F99;
defparam q20_0_s12.INIT_RAM_19=288'h852A25464A29865EE09A67E895D951761F1D85275FF1B7FC6DF49B7A76DE9DC7A77DCA21;
defparam q20_0_s12.INIT_RAM_1A=288'h752BDBF6C8A7AE5469752A1B4E667EA19FA7653A18A6B629AD8A69653A5AA3177DBDF4B1;
defparam q20_0_s12.INIT_RAM_1B=288'h8D1863F208527DFF1F7FC7DE9E07A78DCA2977DDE1F348FCD65EF3A25BE5FEC8D1B63F36;
defparam q20_0_s12.INIT_RAM_1C=288'h82775FF1F82791FF377D2D1FF318A7AE5EEBC52C2E937BCEAB1E67D7896B3E39A68E3F23;
defparam q20_0_s12.INIT_RAM_1D=288'h827CA1F35951BACA29A7A9EC9249FB8E9421B4F82D3DF9FB7E5EDD926763F1D9266E345C;
defparam q20_0_s12.INIT_RAM_1E=288'hB24A674279FB86699F9267A29DE87C76149D852721F1B8A77A29E08A7863F25CA3CE1F31;
defparam q20_0_s12.INIT_RAM_1F=288'h97B9A74239519674269A69E346382785F4A27D29A09F2852BE14AD8A7965EEFCCE96FE63;
defparam q20_0_s12.INIT_RAM_20=288'h9D07E9421951961F297FCFDF4BC7FCFE1F3297BD7DD6EDF7B71E6FB24E6B3F1A50AE7EE9;
defparam q20_0_s12.INIT_RAM_21=288'h827D21F298A79E5464C7C9AF3B1C4EAF5E27D238B13A1B797EFE5FB4F7A9E9FC247EB3DE;
defparam q20_0_s12.INIT_RAM_22=288'hAFA968964AA58A545F7D27DE9DD6FD75AA1D67E75DF5D67E79AA1F6FD85BF656D3A9CA3F;
defparam q20_0_s12.INIT_RAM_23=288'h8D18E5EE37FC8DD4A46FD8DB4E46FD95B4E96D3C5B4EF6D3E5CA327A7AE14A7926A6F3E5;
defparam q20_0_s12.INIT_RAM_24=288'h8FC8A34618D18229DF87C8E1F3A8A7D6546FA50AAA96BAFECE942F9D0AA3F277FC9649A4;
defparam q20_0_s12.INIT_RAM_25=288'h87CFE09FF7FCFDF4BF8D1FED4FFAA5FEB3FFA7AF69435ACFC6C92C9FBA65EE79519649A3;
defparam q20_0_s12.INIT_RAM_26=288'hFFE97FF9FFFE6FFF98FFE4FFF93FFE4FFF92F4B4F48D5C2456BE96A5066699D951863465;
defparam q20_0_s12.INIT_RAM_27=288'h97B56699497B565ED5BCE4E7ED5A7A5A1F16A7A5DDF586A87594FB6FDDDE9F287CDE49AC;
defparam q20_0_s12.INIT_RAM_28=288'h653517F945D45594D75D465551B5A9ADAA286FDA5BF5C7A76EF4A3B24869E999FB5E7416;
defparam q20_0_s12.INIT_RAM_29=288'h4D5813FE957F8D751D67E75DF60BFD86D3DDECC66699987C61DF5772859AA1567E4D94D4;
defparam q20_0_s12.INIT_RAM_2A=288'h8278EB4E2A2586BEA0FCB82FE5FA7A765EDE8FC7DFF1972875B4D96295D551552A5D355A;
defparam q20_0_s12.INIT_RAM_2B=288'h6A85D7F975D45D6A5757F65551A554615FD757F555FD65A965751E5FEA58A6665395BF65;
defparam q20_0_s12.INIT_RAM_2C=288'h5A9495FD25D45575275D4758A5C67E7DB4E97D299F4A67A791FF21A7A765EDB87C65CA19;
defparam q20_0_s12.INIT_RAM_2D=288'h6A879E9E37FCA1AA256D38DD49C827724AA587C81FF198D15E14966D35594D35FE4D7513;
defparam q20_0_s12.INIT_RAM_2E=288'h7A79229DF9557229DB8FC6A545987C5DFF177A75DDF5775259D49575255D4966FD6594DB;
defparam q20_0_s12.INIT_RAM_2F=288'h653A58A647A78A14A065381751E57F815FE0554894AA352A914AA25548D752F6A8B5BF6B;
defparam q20_0_s12.INIT_RAM_30=288'h75265D4996FD61AA186D3619F9967E6D8A6067ECDE9F0852CE3F2C9A6A62AA57FC95FF31;
defparam q20_0_s12.INIT_RAM_31=288'h72855BF576FD75B4F46D3C1CA2C7A7963465AFEA69433AA592F3A1B797A699D8D16DFF1B;
defparam q20_0_s12.INIT_RAM_32=288'h6FD9DDF67852B295219A67E895C8FC6A4998A255E94178FC5A14957FC55FF157A74DF494;
defparam q20_0_s12.INIT_RAM_33=288'hA7A8E3F1F8D16609D777D59CA166FD59B4D56D351CA1375255E9D877D6A09DD8D1ADCA28;
defparam q20_0_s12.INIT_RAM_34=288'h7A77DF49E75279F49F7A77DD49C6D36DAA1B6A87DBF6972899D4A57A7761F23BA876BE9C;
defparam q20_0_s12.INIT_RAM_35=288'hACF5EBE998D175DF61728FDB4FA6FDBDE9E98D1AB1F25BCE9EC92B97BAE49A48278609E1;
defparam q20_0_s12.INIT_RAM_36=288'h7A79DF4A17D28A1F1CB7D76B3E7AFA8B091DC4E671E59B245E9E97ACF5E5ED79A65E6997;
defparam q20_0_s12.INIT_RAM_37=288'h9D0725EDBA256614976FD59BF5562955751557F51AA14554555FD66536194DB5A9858A6D;
defparam q20_0_s12.INIT_RAM_38=288'h7A76E29DA6FD698A5B5FE6D751B5A971751F5A98D6A635A9BD8A696A88DDF5F87C7E9F9D;
defparam q20_0_s12.INIT_RAM_39=288'h77D75D49B7526DD49A72879CA2B7A7A214AF951867421A549669A592685F49F6D37609DC;
defparam q20_0_s12.INIT_RAM_3A=288'h7A7FDD4BF728FDBF7F7FCFE7FFF951FE69BF8FCE23F2F926AE546785291F4A177D81D49E;
defparam q20_0_s12.INIT_RAM_3B=288'hFFE8FFFA3FFE87FFA1FFE87FFA0FFE7BFFA0E777F139EB4F76895E97B86346187C8DFF28;
defparam q20_0_s12.INIT_RAM_3C=288'hCA39ED3E6A509229E77D299E9F07A7D1F4AA7FC8DFF2187C8A1F3087CB2346897B9E9425;
defparam q20_0_s12.INIT_RAM_3D=288'h9269E3F2B926A654668D1963F268D1D634738D1C63F2F926B77469D239F3E27D789B7DE7;
defparam q20_0_s12.INIT_RAM_3E=288'h8A7A61F3187CBE29F68FCBE69AAF4CA39DE7DA296D3E4B248F13A3CA38EA9639FB9A5EE3;
defparam q20_0_s12.INIT_RAM_3F=288'h9A6E77DEBC4EA2A966A7A96BEA5B4F929EA49A6925EE4926963F258A7961F268529614A6;
defparam q20_0_s12.READ_MODE=1'b0;
defparam q20_0_s12.RESET_MODE="SYNC";
  pROMX9 q20_0_s13 (
    .DO({DO_11[35:18],q1[5:0],q2[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s13.BIT_WIDTH=18;
defparam q20_0_s13.INIT_RAM_00=288'hF2A97CA259E5EFC951F25EFC9D0F2B4E6A259A9425A7AEA7ED19518E3F0C8D1DE29E38A7;
defparam q20_0_s13.INIT_RAM_01=288'hF25467CFCF313A7BF9F2DE7BBA492D3F6B242EBEB8ACF3AD3E5AFA9AD3D2AA59E9EBCA50;
defparam q20_0_s13.INIT_RAM_02=288'hEEF3A3AA5E6894F9A6425ED1951F25467951F249928FC9E3F3C8FC4A34528A74A34528FC;
defparam q20_0_s13.INIT_RAM_03=288'hF1F4A77D29DF4BC7D2F1FF127FC4A09D28524A1F2787CF229D28FC4B68E7CCE46FE51BF9;
defparam q20_0_s13.INIT_RAM_04=288'h465EE797B465ED197B465ED19A6467411AD3F28966A25EEDE50ACFA6547B8D19A14A6827;
defparam q20_0_s13.INIT_RAM_05=288'h96D3E6BA4EEF4BBB249AFE7BBA44294399A6925ECF951EE49A68FC463F268FCF23F11926;
defparam q20_0_s13.INIT_RAM_06=288'h43D2E5DA28F28CEC4EE6F3A5BCE96DE66B7946F3A6BCEF2BEBCAA59A9E91AA546B3D0AFA;
defparam q20_0_s13.INIT_RAM_07=288'hEB9325E22EF7DD0E4C9B9DFBEA1EF537BD4DEF48E6C79EF1391CA3EF3E11E7BEF7366E4C;
defparam q20_0_s13.INIT_RAM_08=288'hE313A3BA43AC923B4F3ADE4DBA48EE90EBA4E7FFA3FFE8BFFA2F4B8BB33CF4B3B9324E77;
defparam q20_0_s13.INIT_RAM_09=288'hE6740E9FB929439EA53B7DE3EF637BDB8E223F68A1D23DF48E2CA38B28E3CA33728F8CCE;
defparam q20_0_s13.INIT_RAM_0A=288'h8B3E38B7936BEA5A50DE894D9D0E2698E9A6E25EF897B3A5ECE97B3A698E97B3A698E9D0;
defparam q20_0_s13.INIT_RAM_0B=288'h8EDE64B24E6B3CEAA592A964AA5E6A94FAA5E69439A25927EE49FB92894EA508FE83EE4C;
defparam q20_0_s13.INIT_RAM_0C=288'h969425A7A969EBBA25968965A2596943AA7A96A97AE26E75E24CF8E2FE61C4E47DDA3C79;
defparam q20_0_s13.INIT_RAM_0D=288'h3EBEA5B2496D3CFB79EBFD64EA13F5364CCE9368BCD4D3B090EB4F92BE8FAA5EA9E90A7A;
defparam q20_0_s13.INIT_RAM_0E=288'hE77DCEDA28F9323EF69B68B8CF8E7138EBF992FE4FBA4EADE7AB793ED3CFB4F96BEA5AFA;
defparam q20_0_s13.INIT_RAM_0F=288'hDF13A3BF992FE64BF9EAFE7ABCE3EFE4FC243F090FC243EFE7ABF9EAFE7ABF93B0924EA5;
defparam q20_0_s13.INIT_RAM_10=288'h3F13BAC243F0925C24EB1390C2443093AC4E431E65CCE3FFFB9FFEE768B8CF8E33E0BC79;
defparam q20_0_s13.INIT_RAM_11=288'h3AA94EA50E689649FB3ABEB9FA4E7BDA3E773BA878F76EB930CDCDFB48F9CCE3B28F9C79;
defparam q20_0_s13.INIT_RAM_12=288'h97FF90FFE97FFBBFFEEBFF90FFE8BFF8DFFE33FF8DF4B3B9339D23931E79BCE3ADE4EAFA;
defparam q20_0_s13.INIT_RAM_13=288'hFB28FEC4EFAF3BEC4EFAD3FEC4EFAD3FECCEFAD3CBACF32BEA3A25E67ECEA50E6A97ABCE;
defparam q20_0_s13.INIT_RAM_14=288'h31CA236D3E1BF4E6A89194F867E8DB4CE7A73A14A39268A9423DFB375378CA38F734EC4E;
defparam q20_0_s13.INIT_RAM_15=288'hF629FD7FCA214928FCF69412B24F26A918FCEE34659513A347E7FCD9E9E277DF9D4A2728;
defparam q20_0_s13.INIT_RAM_16=288'hF65452B7D4AB3E7A7A469410A25EA894C9FB8A74249D0427EFCA25F27EE79514A49A88FC;
defparam q20_0_s13.INIT_RAM_17=288'h969EBA95196345087CF214A7827F1FF277FCF5E9E87A7A1E9FD728A1CA2877D4DF493852;
defparam q20_0_s13.INIT_RAM_18=288'h4994E7629F58A7D5FE4994D265349AA286D349BF7D752A1FF288D14AEA3CAFAF29EA6AFA;
defparam q20_0_s13.INIT_RAM_19=288'h9DE9FD7A79DE9E77D29E14A78FC9E7ED29009E14BC8524669BB951FDDF516FDF1AA2767E;
defparam q20_0_s13.INIT_RAM_1A=288'hF254679A69E8A5297B9EA9669A64229F87FC3DE9E677D9DD492752F1D49272849CA2777D;
defparam q20_0_s13.INIT_RAM_1B=288'h46E911ACF8E94249FB9674269D09E69A79A64A74279519E29E787C9E29D28D19E3F27926;
defparam q20_0_s13.INIT_RAM_1C=288'h9AE911BCEF30912BCE9F0927BCEF2C93CB4FF29EA7A7AF29EBCACFF2C93CCFC9F13BCDCD;
defparam q20_0_s13.INIT_RAM_1D=288'h925EF98D1923F399263E544E951925ECF9FB3FFFA2FCB33DDA3DF73B48FEC79431390C4E;
defparam q20_0_s13.INIT_RAM_1E=288'h41FF2587C96544FCA792FE64CA33F138FBCEEEC90DAFA3AB3CEA50929439A503A9EB9AA5;
defparam q20_0_s13.INIT_RAM_1F=288'hEA89648FCE614917D28DDF6475291CA396FDE9BF646D33DB4E56FD95BF4F728E9D4BA7A7;
defparam q20_0_s13.INIT_RAM_20=288'hEA345087C9614BB8274209E67FC9A09E6827EDDF6677D41E9D07D29609E48FCE308CFB24;
defparam q20_0_s13.INIT_RAM_21=288'h49DF527A749DF6775249DF527A7F1F491827F2347BBD242C924AFA9269B89D09EF3B99FB;
defparam q20_0_s13.INIT_RAM_22=288'h4609E787C9E347C9A69B1E3BB79EE9EBAA253ED3E89FBEA3F1085299FF3C7A79DE9FC77D;
defparam q20_0_s13.INIT_RAM_23=288'h96D3FAB4FEB68B9ACF4E74259269634668A7461F2687CF21F3C827461F117FC45F4917FC;
defparam q20_0_s13.INIT_RAM_24=288'h3E347A8A7EE29E68A74629E78D19E3F278D19E346787C9E1F118A746347C951967ED0BFD;
defparam q20_0_s13.INIT_RAM_25=288'hF21F2787CF214A787C9E1F3C87CF23F3C951F27411A7A9BA8BAC79EA940F97B3A54648FC;
defparam q20_0_s13.INIT_RAM_26=288'hEE347B87C9A14A6827EE49BBC5296E93AB243F0939BF94A896497BDE49908D1EE29E687C;
defparam q20_0_s13.INIT_RAM_27=288'h9BFF91FFE9BFFBCFFEEFFFBDFFE3FFFB9FFE3BE839D78971E50B4F42A9669FBEE69BB926;
defparam q20_0_s13.INIT_RAM_28=288'hFAF3BEAFAFA897EB79FA69BEB79FA743ECA3FA5ECC9A636546487CE61F0F8D1EA5EFBACF;
defparam q20_0_s13.INIT_RAM_29=288'h355FF8554DD5FF852A3935644D5954AA55FE359FA57529614A5C523EE93AC793F33A5ACF;
defparam q20_0_s13.INIT_RAM_2A=288'h51B4EA653A9AA1477D521F3E8FCA6203D7D2F5DF7C7D2EDDF7C67E398A4D5D4DD750D57F;
defparam q20_0_s13.INIT_RAM_2B=288'h5229D49D44E49BD8D14A29E68D1D6544D9D0967EFCACFA2743E9D04E742987C51D4BF7D2;
defparam q20_0_s13.INIT_RAM_2C=288'hF2699085299DF7C6FD49AA2867EF994E96295175145A9A9753F57FA96A6A629FDAA3F752;
defparam q20_0_s13.INIT_RAM_2D=288'hA53FFE4D5A52AA94AAFD2ABF4D5FD4A94554A55FE95D45194D4728A6AA539FBF669A7A25;
defparam q20_0_s13.INIT_RAM_2E=288'h517FA95FE517FA965351B4D47A7FA34537814DB4E86D39E09D2827018A525A94D551352A;
defparam q20_0_s13.INIT_RAM_2F=288'hA5E9FE8274E357D827F65ED27D299BF516539D8A7D5FEA1753E5D4A56A7E5A9F96A545FE;
defparam q20_0_s13.INIT_RAM_30=288'h4E9E929A64249918A74A14927FCF5E9E87D24DDF6977DF9B4FE6A8A5AA296D34DCA2877D;
defparam q20_0_s13.INIT_RAM_31=288'h4E743E9A6A6743E9D052941497BA67429926A63F148FCA6347F8FCA65469AFEA6943EACF;
defparam q20_0_s13.INIT_RAM_32=288'h45E9D16FD45CA2675299D4BB77D49F49287C4B5F11CCE97DD8FBCE3EC92AAA5F2943D9FB;
defparam q20_0_s13.INIT_RAM_33=288'h498A7C6D39DE9E7B289E9E92AFAF2A9519FB9E54798D13E29D087C961490827EE09D187C;
defparam q20_0_s13.INIT_RAM_34=288'hF2149175241AA1362995752557F41553B52A454ABB4FF453FE752A9D4AA75549D5FFC5D4;
defparam q20_0_s13.INIT_RAM_35=288'h9DBF676A8F19FA7629F58A52629498A52629496A525A9F5753D5FE499FBC752467EBC926;
defparam q20_0_s13.INIT_RAM_36=288'hA55FE95D4F96A5457F515FFE5D4A57F936534DBF68A54F269BC97BF1F490827FE5ED1827;
defparam q20_0_s13.INIT_RAM_37=288'hF98A5367EF9BF537A74EB3D29D04A347C852EE5EEA852F1CA3D6534D8A685D4F96A5357F;
defparam q20_0_s13.INIT_RAM_38=288'h4A5EFC9A6F2DE6692655FF2775249BF676A8F5AA2867EF5B4D3629A194D357FA16A685D4;
defparam q20_0_s13.INIT_RAM_39=288'h459F9267E499FBD67E4DAA286A8A1BF7E6FDF9B4D367EA19F9367E4DAA137284A09E8A29;
defparam q20_0_s13.INIT_RAM_3A=288'h4D94FE629A58A54629518A6A629A99FAA6FDA9DF7E8524F3DFCACF9E29E677DEDCA106A8;
defparam q20_0_s13.INIT_RAM_3B=288'hA5DF69728F9BF7E6D34DF493AA9A27EFD97BF2A9519FB5209E67A791CA126FDA1AA3E6A8;
defparam q20_0_s13.INIT_RAM_3C=288'h4BFFBDFFE4BFFA8FFE9FFFBFFFE47FFBCFFEF39310C244AC9279FBF654688A7FA14937D2;
defparam q20_0_s13.INIT_RAM_3D=288'hFB28FEC24FB093EBCEFAF3BEBF9FAF3BEBA4875379B24E69E909D09A5EFC9A69E8967ACF;
defparam q20_0_s13.INIT_RAM_3E=288'h36544E926E234768FC363F0C852DE29CD8FC8A544EA508EA978ED03B888ED789313A4CCE;
defparam q20_0_s13.INIT_RAM_3F=288'hF1DF677A749FF27827F21F129264B9427DA24B5367C4E46BE91AFA8E940D9D08E5EF8951;
defparam q20_0_s13.READ_MODE=1'b0;
defparam q20_0_s13.RESET_MODE="SYNC";
  pROMX9 q20_0_s14 (
    .DO({DO_12[35:18],q0[11:0],q1[11:6]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({level_addr[9:0],GND,GND,VCC,VCC}) 
);
defparam q20_0_s14.BIT_WIDTH=18;
defparam q20_0_s14.INIT_RAM_00=288'hE227F735FDCD835361DA2877363CF88F68A4E229B7DE8E77AF9DF7DA2D3737BDF7E788B4;
defparam q20_0_s14.INIT_RAM_01=288'hC247F1E60C7986F3A2CA38F13A5B79FAD3FBB79FEF3B5C24C7A968DF7937DE1DCD83689F;
defparam q20_0_s14.INIT_RAM_02=288'h87C9E1F348A7BE3F2B9519E7425CFC8F13A2BF98713A1BCE82FE5FBF986FE61BCE7EFE5F;
defparam q20_0_s14.INIT_RAM_03=288'h9268E8A6297B8A54618FC863F218D18634618A78629E28A78629E187C861F2287C8E1F25;
defparam q20_0_s14.INIT_RAM_04=288'h9268E34628A78E14A38278E09E38278E09E38528DF4A47D295F4A7827AA14A787C9A3464;
defparam q20_0_s14.INIT_RAM_05=288'h852A214A68529609E58529A14A787CA614B587CC21F2B8D19E49A6B7D96B3E4A508E5EE3;
defparam q20_0_s14.INIT_RAM_06=288'h7D29DFF28827D214B18A7B63F2A951A328A6BCE96BEA49FB8E5EE38FC9234658A7961F27;
defparam q20_0_s14.INIT_RAM_07=288'hBF9A6FE68BA89EBEA7A509A69A5951963F258D19634668A7961F258A79614A58A795FF26;
defparam q20_0_s14.INIT_RAM_08=288'hC4ECF0932C24CEFE72BCECEFE75BF9D2FE71C24C6F3B4BF9DB1E78BCEE2F3B1BF9BEFE6C;
defparam q20_0_s14.INIT_RAM_09=288'hC4EBED3F1B4FC2BEB1ACFCEBEB4B4FD6D3F5BA4FF28FCD4DE77378D78DB7474D23D73E33;
defparam q20_0_s14.INIT_RAM_0A=288'hA25E29435AA5D6B3FAB4FDEDE77BF9D728F3FFECFFFB3FCBCFBDB1E22C768B1CCEC733AF;
defparam q20_0_s14.INIT_RAM_0B=288'hB24CAC930B4FBF886FD4DBB1E6EBCEB6D3EDAFAB6A96DA50BA942EA25BA8971A25D2943F;
defparam q20_0_s14.INIT_RAM_0C=288'hD23A313A8BCEA2C927ACFA29EA8A50A289699FBAA742BA25B68970A7ACE9EBAACFDEBEB4;
defparam q20_0_s14.INIT_RAM_0D=288'hA7AAE942AA25AA7EEB9D0AE69AC97BB65EEE9D0C29433B24C7092FD23B333ABDFBA75369;
defparam q20_0_s14.INIT_RAM_0E=288'h8D1BE34718D1CA49B4951DA69B39FBC6896FA7ABBFFADFA0AF736BC79AEF3ABB24AAB3EA;
defparam q20_0_s14.INIT_RAM_0F=288'hA50DE9EB2AA5BABEACDA6AF3E2BCA3AEA96B9FBAE5EEB951AE3F2B8FCAE346B8D1BE29F0;
defparam q20_0_s14.INIT_RAM_10=288'hDF7B71E6BB79AEBEAAA7AA694299FBA674299D0A669AA9A6B669AF9D0C67EF39FBD6897D;
defparam q20_0_s14.INIT_RAM_11=288'hAA5BEA96FA7ABE9EB0A50C69431A50C68972A25CE9433A7AF6C93BB79FF0931D23BFDD6D;
defparam q20_0_s14.INIT_RAM_12=288'hA7AAA9EA9ACFA2BEA7AFAAEC939B4FDAE937BCEEF0937DFBCF5371CA3C2DE6FB24BEB3EF;
defparam q20_0_s14.INIT_RAM_13=288'hAA5FE943FA25FE7EFFAFAFF747FD23FF933FCF8FF093DB4FE6C934ACFC6A96FAA5B69EAB;
defparam q20_0_s14.INIT_RAM_14=288'hFFEE7FFB2FFED7FFB3FFEC3FFB3FFECBFFB3FFECFD2F2E4CDB48F4C79DEF3B3B79CABEB3;
defparam q20_0_s14.INIT_RAM_15=288'hE776F689BE2273735DECC77735FDA27F33A3D4D97BDAAFA0CFC87FEA1EFA876EA1FF9336;
defparam q20_0_s14.INIT_RAM_16=288'hACF6EB3DDA7A7EC920ACF8E69A797BEE7439A50DAB3F0B799FBEA1E4C7F7DDEDA277535C;
defparam q20_0_s14.INIT_RAM_17=288'h6FDA1CA2D77DA9FF2787C8E3F22C7C7EF39EB4F76D3DCB2472C91BAFA72BE9CAA56EB3DB;
defparam q20_0_s14.INIT_RAM_18=288'h87C7E7FDE95176345D8527609DD7D275E9DC77D75DF5D77D71D49C75275CA1F77D85DF64;
defparam q20_0_s14.INIT_RAM_19=288'h87C7A09DD82779FF1E7FC79F49E7D279F49F7A781FF2177D8DDF6577D95E9E37D285FF20;
defparam q20_0_s14.INIT_RAM_1A=288'h6D385B4E06D381AA216FD89AA246A89DB4EF728ADDF667D28A14A1B797E9E9F97B7E345E;
defparam q20_0_s14.INIT_RAM_1B=288'h7A78DDF657A7C1FF2C827A21F248D18A75209267E1F1E7D279DF5E75279CA1F6FD81B4E2;
defparam q20_0_s14.INIT_RAM_1C=288'h9519269A39D48649A18A78214A08277DFF1F7D27DE9E07A77DE9DF7A77DDF5F77D81DF61;
defparam q20_0_s14.INIT_RAM_1D=288'hA25BA742D9A6BA5EED951B6546F926B249AB926B669B69FBEE7434951CE49AB926A649A7;
defparam q20_0_s14.INIT_RAM_1E=288'h97BA6546A926AA346B8A7B2346C8FCB6546D9D0DE9435A50CE9431A50C2EA2FAFABE9EAD;
defparam q20_0_s14.INIT_RAM_1F=288'h97BAE742C9A6B65EF59FBCA9EB0AFABAE92DE26AF5E2CD4DAF092AB24AA9EABA25A67429;
defparam q20_0_s14.INIT_RAM_20=288'h9D0AE7EE9A50A334A7C249EDE66ACF9A9EA6A25967EE69A69E69A79A6A25EEC9A6CE69AD;
defparam q20_0_s14.INIT_RAM_21=288'hC24870921C4E8728E0C798713A1CA38713A3BF98F5365C79A6942CA25C328F5A25C269AD;
defparam q20_0_s14.INIT_RAM_22=288'h9518E49A28FC8A29E385291FF257D29DE9E9827B629EC97BA67427A5092B3E3CD28B0921;
defparam q20_0_s14.INIT_RAM_23=288'h87CA229E98FCAE3F2D8FCB63F2A926A254669A6975F24CCE8F7DE3BF98EBEA3A258E7423;
defparam q20_0_s14.INIT_RAM_24=288'h97BB67EE9AA596C924CA78EFE62B4F8AA962A508A69A29518A3F238D18E29E387CA214A7;
defparam q20_0_s14.INIT_RAM_25=288'hBA48EB3E29FB865EE0926823F1F8D17E29DF8A77E1F238D19A49A997BAE49AD8A7BE3470;
defparam q20_0_s14.INIT_RAM_26=288'h8A7961F258529A14A68529E09E7852A214A9827AE1F2D8D1CE49B097BE67EE9A7A971E64;
defparam q20_0_s14.INIT_RAM_27=288'hB4F9ABEA59FB929423ACF9EF3AFD23B733ADCA3C728EFAA9AA7EE99A69E69A6951963465;
defparam q20_0_s14.INIT_RAM_28=288'h97BFE49BF8FCFE347F9D0FF49FFC79FEF3BFBA4FEE939BCED6FE70BCEB6E92BBF9A6C927;
defparam q20_0_s14.INIT_RAM_29=288'hFFED7FFB5FFEDFFFB3FFEBFFFAEFFEABFFAAFFED788A8D23A2FE6AB4FB6A96BA50AE742A;
defparam q20_0_s14.INIT_RAM_2A=288'hCCE57F2D4BA45328D5D785EC917C4E62F39BDA276C921AFA96E935C79CF5375D23DF48F7;
defparam q20_0_s14.INIT_RAM_2B=288'h95156345787C66499B7FC7DD4A477DFDFF35852AA3F1F97B739419DA2676898CA35F3395;
defparam q20_0_s14.INIT_RAM_2C=288'h554856A6B65399AA2172875F49AAD35E89569D056699597B5249939265249948FC4E4993;
defparam q20_0_s14.INIT_RAM_2D=288'h77D62001775259B4D6653557F955D4556A5557F595FD657F555515554594A9957F6D551E;
defparam q20_0_s14.INIT_RAM_2E=288'h6D35DAA1667E5D94D66535D8A575FE5D8A595FE6D7F9C5A9796A615A9817F9D6536DAA19;
defparam q20_0_s14.INIT_RAM_2F=288'h4D5612A974AA652A9B4D5752AA14D5994AA75D48994DD6FD69FF1997C6229D77D25DCA17;
defparam q20_0_s14.INIT_RAM_30=288'h5A96D5FDD5A9A57FA565385AA1D7286E001A75265AA185FE5D6A57554614A984FF65355A;
defparam q20_0_s14.INIT_RAM_31=288'h77D6DF4997D661CA176D35D9F97653598A56629597F975FE597F955D45975165A9617519;
defparam q20_0_s14.INIT_RAM_32=288'h85295FF257A795DF6477D91D4A575285CA1F75285DF657FCA1E9ED728B5BF626FD7DCA1D;
defparam q20_0_s14.INIT_RAM_33=288'h72885B4E16D3819FA0653819FA16D385DF637D2C1E9ED7A7ADF4A97FCA27FE7951963465;
defparam q20_0_s14.INIT_RAM_34=288'h7FC8DE9E57289DDF6D87CAA3F289269E49A5CA78EFE65B4F8E94228FC8A09E27D281DF61;
defparam q20_0_s14.INIT_RAM_35=288'h7A789E9E07FC7ECA1EA7A76741D8FC761F1D82775FF1D7A775E9DD7A77DDF5F7A78DD4A3;
defparam q20_0_s14.INIT_RAM_36=288'hAA562C918B795EBE97A505E5ED797B623F199516E5EDC97B7DFF217D28E49A77A79DDF65;
defparam q20_0_s14.INIT_RAM_37=288'h72865BF596D3659F9B5FE6D751D5D47D752167E95B4E27527DE9DD7FC6E149AAFE669419;
defparam q20_0_s14.INIT_RAM_38=288'h6537D8A616538DAA266FD95DF627FC8629DE9A677339CBA46E9E9B8FC6A149B7A769DF5A;
defparam q20_0_s14.INIT_RAM_39=288'h7FC96346197B76699BAA96E7EDA9516A14997FC65D49972869B4D96A8659F9B67E7594DC;
defparam q20_0_s14.INIT_RAM_3A=288'h97B6629D77FC59DF5575255BF546D351B4D46D351AA176A86DB4DF6FD899FA467E9DBF69;
defparam q20_0_s14.INIT_RAM_3B=288'h6A8619F98653658A596536D94DB653718A5D6297DAA23728A5FF2687CBA545DA256A93D9;
defparam q20_0_s14.INIT_RAM_3C=288'h77D7DD49D7D2761F1C97B82B3E5B798ED3E1B4F8ED3E98D58609DE8276DFF1A75265B4D9;
defparam q20_0_s14.INIT_RAM_3D=288'h77DFDCA3F6FDFDB4FF7D2FECA3FA7AFE743F97BEA5EF19A6B6346987C9A1F238FC89E9E0;
defparam q20_0_s14.INIT_RAM_3E=288'hFFEDFFFB3FFED7FFBBFFED7FFB9FFEE7FFB7E4CDB092FB24D27EF5951C629EF852B9F4AE;
defparam q20_0_s14.INIT_RAM_3F=288'hDCD87FFA0E4C875E20F4B7F689FCF87F9320DF787D2E2E4C9788B7E4CD37DF5DCDD37373;
defparam q20_0_s14.READ_MODE=1'b0;
defparam q20_0_s14.RESET_MODE="SYNC";
  MUX2_LUT5 q_11_s54 (
    .O(q_11_52),
    .I0(q_11_41),
    .I1(q_11_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_11_s55 (
    .O(q_11_54),
    .I0(q_11_43),
    .I1(q_11_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_11_s56 (
    .O(q_11_56),
    .I0(q_11_45),
    .I1(q_11_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_11_s57 (
    .O(q_11_58),
    .I0(q_11_47),
    .I1(q_11_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_11_s48 (
    .O(q_11_60),
    .I0(q_11_49),
    .I1(q_11_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_10_s54 (
    .O(q_10_52),
    .I0(q_10_41),
    .I1(q_10_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_10_s55 (
    .O(q_10_54),
    .I0(q_10_43),
    .I1(q_10_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_10_s56 (
    .O(q_10_56),
    .I0(q_10_45),
    .I1(q_10_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_10_s57 (
    .O(q_10_58),
    .I0(q_10_47),
    .I1(q_10_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_10_s48 (
    .O(q_10_60),
    .I0(q_10_49),
    .I1(q_10_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_9_s54 (
    .O(q_9_52),
    .I0(q_9_41),
    .I1(q_9_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_9_s55 (
    .O(q_9_54),
    .I0(q_9_43),
    .I1(q_9_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_9_s56 (
    .O(q_9_56),
    .I0(q_9_45),
    .I1(q_9_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_9_s57 (
    .O(q_9_58),
    .I0(q_9_47),
    .I1(q_9_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_9_s48 (
    .O(q_9_60),
    .I0(q_9_49),
    .I1(q_9_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_8_s54 (
    .O(q_8_52),
    .I0(q_8_41),
    .I1(q_8_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_8_s55 (
    .O(q_8_54),
    .I0(q_8_43),
    .I1(q_8_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_8_s56 (
    .O(q_8_56),
    .I0(q_8_45),
    .I1(q_8_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_8_s57 (
    .O(q_8_58),
    .I0(q_8_47),
    .I1(q_8_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_8_s48 (
    .O(q_8_60),
    .I0(q_8_49),
    .I1(q_8_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_7_s54 (
    .O(q_7_52),
    .I0(q_7_41),
    .I1(q_7_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_7_s55 (
    .O(q_7_54),
    .I0(q_7_43),
    .I1(q_7_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_7_s56 (
    .O(q_7_56),
    .I0(q_7_45),
    .I1(q_7_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_7_s57 (
    .O(q_7_58),
    .I0(q_7_47),
    .I1(q_7_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_7_s48 (
    .O(q_7_60),
    .I0(q_7_49),
    .I1(q_7_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_6_s54 (
    .O(q_6_52),
    .I0(q_6_41),
    .I1(q_6_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_6_s55 (
    .O(q_6_54),
    .I0(q_6_43),
    .I1(q_6_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_6_s56 (
    .O(q_6_56),
    .I0(q_6_45),
    .I1(q_6_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_6_s57 (
    .O(q_6_58),
    .I0(q_6_47),
    .I1(q_6_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_6_s48 (
    .O(q_6_60),
    .I0(q_6_49),
    .I1(q_6_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_5_s54 (
    .O(q_5_52),
    .I0(q_5_41),
    .I1(q_5_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_5_s55 (
    .O(q_5_54),
    .I0(q_5_43),
    .I1(q_5_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_5_s56 (
    .O(q_5_56),
    .I0(q_5_45),
    .I1(q_5_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_5_s57 (
    .O(q_5_58),
    .I0(q_5_47),
    .I1(q_5_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_5_s48 (
    .O(q_5_60),
    .I0(q_5_49),
    .I1(q_5_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_4_s54 (
    .O(q_4_52),
    .I0(q_4_41),
    .I1(q_4_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_4_s55 (
    .O(q_4_54),
    .I0(q_4_43),
    .I1(q_4_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_4_s56 (
    .O(q_4_56),
    .I0(q_4_45),
    .I1(q_4_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_4_s57 (
    .O(q_4_58),
    .I0(q_4_47),
    .I1(q_4_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_4_s48 (
    .O(q_4_60),
    .I0(q_4_49),
    .I1(q_4_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_3_s54 (
    .O(q_3_52),
    .I0(q_3_41),
    .I1(q_3_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_3_s55 (
    .O(q_3_54),
    .I0(q_3_43),
    .I1(q_3_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_3_s56 (
    .O(q_3_56),
    .I0(q_3_45),
    .I1(q_3_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_3_s57 (
    .O(q_3_58),
    .I0(q_3_47),
    .I1(q_3_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_3_s48 (
    .O(q_3_60),
    .I0(q_3_49),
    .I1(q_3_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_2_s54 (
    .O(q_2_52),
    .I0(q_2_41),
    .I1(q_2_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_2_s55 (
    .O(q_2_54),
    .I0(q_2_43),
    .I1(q_2_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_2_s56 (
    .O(q_2_56),
    .I0(q_2_45),
    .I1(q_2_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_2_s57 (
    .O(q_2_58),
    .I0(q_2_47),
    .I1(q_2_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_2_s48 (
    .O(q_2_60),
    .I0(q_2_49),
    .I1(q_2_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_1_s54 (
    .O(q_1_52),
    .I0(q_1_41),
    .I1(q_1_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_1_s55 (
    .O(q_1_54),
    .I0(q_1_43),
    .I1(q_1_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_1_s56 (
    .O(q_1_56),
    .I0(q_1_45),
    .I1(q_1_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_1_s57 (
    .O(q_1_58),
    .I0(q_1_47),
    .I1(q_1_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_1_s48 (
    .O(q_1_60),
    .I0(q_1_49),
    .I1(q_1_50),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_0_s54 (
    .O(q_0_52),
    .I0(q_0_41),
    .I1(q_0_42),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_0_s55 (
    .O(q_0_54),
    .I0(q_0_43),
    .I1(q_0_44),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_0_s56 (
    .O(q_0_56),
    .I0(q_0_45),
    .I1(q_0_46),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_0_s57 (
    .O(q_0_58),
    .I0(q_0_47),
    .I1(q_0_48),
    .S0(sel[1]) 
);
  MUX2_LUT5 q_0_s48 (
    .O(q_0_60),
    .I0(q_0_49),
    .I1(q_0_50),
    .S0(sel[1]) 
);
  MUX2_LUT6 q_11_s52 (
    .O(q_11_62),
    .I0(q_11_52),
    .I1(q_11_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_11_s53 (
    .O(q_11_64),
    .I0(q_11_56),
    .I1(q_11_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_10_s52 (
    .O(q_10_62),
    .I0(q_10_52),
    .I1(q_10_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_10_s53 (
    .O(q_10_64),
    .I0(q_10_56),
    .I1(q_10_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_9_s52 (
    .O(q_9_62),
    .I0(q_9_52),
    .I1(q_9_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_9_s53 (
    .O(q_9_64),
    .I0(q_9_56),
    .I1(q_9_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_8_s52 (
    .O(q_8_62),
    .I0(q_8_52),
    .I1(q_8_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_8_s53 (
    .O(q_8_64),
    .I0(q_8_56),
    .I1(q_8_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_7_s52 (
    .O(q_7_62),
    .I0(q_7_52),
    .I1(q_7_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_7_s53 (
    .O(q_7_64),
    .I0(q_7_56),
    .I1(q_7_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_6_s52 (
    .O(q_6_62),
    .I0(q_6_52),
    .I1(q_6_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_6_s53 (
    .O(q_6_64),
    .I0(q_6_56),
    .I1(q_6_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_5_s52 (
    .O(q_5_62),
    .I0(q_5_52),
    .I1(q_5_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_5_s53 (
    .O(q_5_64),
    .I0(q_5_56),
    .I1(q_5_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_4_s52 (
    .O(q_4_62),
    .I0(q_4_52),
    .I1(q_4_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_4_s53 (
    .O(q_4_64),
    .I0(q_4_56),
    .I1(q_4_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_3_s52 (
    .O(q_3_62),
    .I0(q_3_52),
    .I1(q_3_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_3_s53 (
    .O(q_3_64),
    .I0(q_3_56),
    .I1(q_3_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_2_s52 (
    .O(q_2_62),
    .I0(q_2_52),
    .I1(q_2_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_2_s53 (
    .O(q_2_64),
    .I0(q_2_56),
    .I1(q_2_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_1_s52 (
    .O(q_1_62),
    .I0(q_1_52),
    .I1(q_1_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_1_s53 (
    .O(q_1_64),
    .I0(q_1_56),
    .I1(q_1_58),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_0_s52 (
    .O(q_0_62),
    .I0(q_0_52),
    .I1(q_0_54),
    .S0(sel[2]) 
);
  MUX2_LUT6 q_0_s53 (
    .O(q_0_64),
    .I0(q_0_56),
    .I1(q_0_58),
    .S0(sel[2]) 
);
  MUX2_LUT7 q_11_s51 (
    .O(q_11_66),
    .I0(q_11_62),
    .I1(q_11_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_10_s51 (
    .O(q_10_66),
    .I0(q_10_62),
    .I1(q_10_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_9_s51 (
    .O(q_9_66),
    .I0(q_9_62),
    .I1(q_9_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_8_s51 (
    .O(q_8_66),
    .I0(q_8_62),
    .I1(q_8_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_7_s51 (
    .O(q_7_66),
    .I0(q_7_62),
    .I1(q_7_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_6_s51 (
    .O(q_6_66),
    .I0(q_6_62),
    .I1(q_6_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_5_s51 (
    .O(q_5_66),
    .I0(q_5_62),
    .I1(q_5_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_4_s51 (
    .O(q_4_66),
    .I0(q_4_62),
    .I1(q_4_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_3_s51 (
    .O(q_3_66),
    .I0(q_3_62),
    .I1(q_3_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_2_s51 (
    .O(q_2_66),
    .I0(q_2_62),
    .I1(q_2_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_1_s51 (
    .O(q_1_66),
    .I0(q_1_62),
    .I1(q_1_64),
    .S0(sel[3]) 
);
  MUX2_LUT7 q_0_s51 (
    .O(q_0_66),
    .I0(q_0_62),
    .I1(q_0_64),
    .S0(sel[3]) 
);
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
endmodule
module piano_note_loader (
  clk_12m288,
  n290_6,
  n3804_5,
  n3804_5_83,
  n3804_5_84,
  n3804_5_85,
  n3804_5_86,
  n3804_5_87,
  n3804_5_88,
  n3804_5_89,
  n3804_5_90,
  n3804_5_91,
  n3804_5_92,
  n3804_5_93,
  n3804_5_94,
  n135_6,
  chosen_3_29,
  out_note_on_Z,
  n135_4,
  chosen_0,
  chosen_1,
  chosen_2,
  chosen_4,
  out_note_Z_0,
  out_note_Z_1,
  out_note_Z_2,
  out_note_Z_3,
  out_note_Z_5,
  out_note_Z_6,
  out_velocity_Z,
  eng,
  eng_95,
  eng_96,
  eng_97,
  eng_98,
  eng_99,
  eng_100,
  eng_101,
  eng_102,
  eng_103,
  eng_104,
  eng_105,
  eng_106,
  eng_107,
  vstate,
  eng_108,
  vstate_109,
  eng_110,
  vstate_111,
  eng_112,
  vstate_113,
  eng_114,
  vstate_115,
  eng_116,
  vstate_117,
  eng_118,
  vstate_119,
  eng_120,
  vstate_121,
  eng_122,
  vstate_123,
  eng_124,
  vstate_125,
  eng_126,
  vstate_127,
  vstate_128,
  eng_129,
  eng_130,
  vstate_131,
  eng_132,
  vstate_133,
  eng_134,
  vstate_135,
  eng_136,
  vstate_137,
  eng_138,
  vstate_139,
  vstate_140,
  eng_141,
  eng_142,
  vstate_143,
  n839_98,
  n839_102,
  n839_118,
  n839_120,
  n839_126,
  n839_135,
  n839_137,
  n839_139,
  n839_141,
  n839_143,
  n839_145,
  n839_147,
  n839_149,
  n839_151,
  n839_153,
  n839_155,
  n839_157,
  n839_159,
  n839_161,
  n839_163,
  n839_165,
  n839_167,
  n839_169,
  n839_171,
  n1450_15,
  state,
  \G_PARTIAL.ld_we ,
  \G_PARTIAL.ld_done ,
  \G_PARTIAL.ld_rel_slope ,
  \G_PARTIAL.ld_addr ,
  \G_PARTIAL.ld_data ,
  voice_r
)
;
input clk_12m288;
input n290_6;
input n3804_5;
input n3804_5_83;
input n3804_5_84;
input n3804_5_85;
input n3804_5_86;
input n3804_5_87;
input n3804_5_88;
input n3804_5_89;
input n3804_5_90;
input n3804_5_91;
input n3804_5_92;
input n3804_5_93;
input n3804_5_94;
input n135_6;
input chosen_3_29;
input out_note_on_Z;
input n135_4;
input chosen_0;
input chosen_1;
input chosen_2;
input chosen_4;
input out_note_Z_0;
input out_note_Z_1;
input out_note_Z_2;
input out_note_Z_3;
input out_note_Z_5;
input out_note_Z_6;
input [6:6] out_velocity_Z;
input [1:0] eng;
input [1:0] eng_95;
input [1:0] eng_96;
input [1:0] eng_97;
input [1:0] eng_98;
input [1:0] eng_99;
input [1:0] eng_100;
input [1:0] eng_101;
input [1:0] eng_102;
input [1:0] eng_103;
input [1:0] eng_104;
input [1:0] eng_105;
input [1:0] eng_106;
input [1:0] eng_107;
input [1:0] vstate;
input [1:0] eng_108;
input [1:0] vstate_109;
input [1:0] eng_110;
input [1:0] vstate_111;
input [1:0] eng_112;
input [1:0] vstate_113;
input [1:0] eng_114;
input [1:0] vstate_115;
input [1:0] eng_116;
input [1:0] vstate_117;
input [1:0] eng_118;
input [1:0] vstate_119;
input [1:0] eng_120;
input [1:0] vstate_121;
input [1:0] eng_122;
input [1:0] vstate_123;
input [1:0] eng_124;
input [1:0] vstate_125;
input [1:0] eng_126;
input [1:0] vstate_127;
input [1:0] vstate_128;
input [1:0] eng_129;
input [1:0] eng_130;
input [1:0] vstate_131;
input [1:0] eng_132;
input [1:0] vstate_133;
input [1:0] eng_134;
input [1:0] vstate_135;
input [1:0] eng_136;
input [1:0] vstate_137;
input [1:0] eng_138;
input [1:0] vstate_139;
input [1:0] vstate_140;
input [1:0] eng_141;
input [1:0] eng_142;
input [1:0] vstate_143;
output n839_98;
output n839_102;
output n839_118;
output n839_120;
output n839_126;
output n839_135;
output n839_137;
output n839_139;
output n839_141;
output n839_143;
output n839_145;
output n839_147;
output n839_149;
output n839_151;
output n839_153;
output n839_155;
output n839_157;
output n839_159;
output n839_161;
output n839_163;
output n839_165;
output n839_167;
output n839_169;
output n839_171;
output n1450_15;
output [4:0] state;
output [31:0] \G_PARTIAL.ld_we ;
output [31:0] \G_PARTIAL.ld_done ;
output [12:0] \G_PARTIAL.ld_rel_slope ;
output [8:0] \G_PARTIAL.ld_addr ;
output [27:0] \G_PARTIAL.ld_data ;
output [3:3] voice_r;
wire n974_3;
wire n839_65;
wire n839_67;
wire n839_69;
wire n839_71;
wire n839_73;
wire n839_75;
wire n839_77;
wire n839_79;
wire n839_81;
wire n839_83;
wire n839_85;
wire n839_87;
wire n839_89;
wire n839_91;
wire n839_93;
wire n839_95;
wire n1084_87;
wire n1178_59;
wire n1179_59;
wire n1180_59;
wire n1181_59;
wire n1182_59;
wire n1183_59;
wire n1184_59;
wire n1185_59;
wire n1186_59;
wire n1187_59;
wire n1188_59;
wire n1189_59;
wire n1190_43;
wire n1191_43;
wire n1192_43;
wire n1193_43;
wire n1194_43;
wire n1195_43;
wire n1196_43;
wire n1197_43;
wire n1198_43;
wire n1205_43;
wire n1206_43;
wire n1207_43;
wire n1208_43;
wire n1209_43;
wire n1210_43;
wire n1211_43;
wire n1212_43;
wire n1213_43;
wire n1214_43;
wire n1220_43;
wire n1221_43;
wire n1222_43;
wire n1223_43;
wire n1224_43;
wire n1225_43;
wire n1226_43;
wire n1227_43;
wire n1228_43;
wire n1229_43;
wire n1230_44;
wire n1235_43;
wire n1236_43;
wire n1237_43;
wire n1238_43;
wire n1239_43;
wire n1240_43;
wire n1241_43;
wire n1242_43;
wire n1243_43;
wire n1244_43;
wire n1245_43;
wire n1259_10;
wire n1300_8;
wire n1312_8;
wire n1324_9;
wire n1341_9;
wire n1388_9;
wire n1408_10;
wire n1428_10;
wire slot_3_9;
wire ld_addr_1_4;
wire state_4_8;
wire n1080_76;
wire n1258_48;
wire n1257_47;
wire n1256_47;
wire n1255_47;
wire n1254_46;
wire n1253_46;
wire n1252_46;
wire n1251_46;
wire n1250_46;
wire n1249_46;
wire n1248_46;
wire n1247_46;
wire n1246_46;
wire mp_hi_15_18;
wire mp_lo_15_18;
wire n867_7;
wire n866_7;
wire n865_7;
wire n864_7;
wire n863_7;
wire n862_7;
wire n861_7;
wire n860_7;
wire n859_7;
wire n858_7;
wire n857_7;
wire n856_7;
wire n855_7;
wire n854_7;
wire n853_7;
wire n852_7;
wire n851_7;
wire n850_7;
wire n849_7;
wire n1156_64;
wire n1157_64;
wire n1167_65;
wire n1165_65;
wire n1164_65;
wire n1153_66;
wire n1154_66;
wire n1155_67;
wire n173_4;
wire base0_7_3;
wire ratio_addr_4_5;
wire n974_4;
wire n974_5;
wire n974_6;
wire n974_7;
wire mp_lo_13_22;
wire mp_lo_12_23;
wire mp_lo_11_25;
wire mp_lo_10_25;
wire mp_lo_9_25;
wire mp_lo_8_25;
wire mp_lo_7_25;
wire mp_lo_6_25;
wire mp_lo_5_25;
wire mp_lo_4_25;
wire mp_lo_3_25;
wire mp_lo_2_25;
wire mp_hi_13_22;
wire mp_hi_12_22;
wire mp_hi_11_25;
wire mp_hi_10_25;
wire mp_hi_9_25;
wire mp_hi_8_25;
wire mp_hi_7_25;
wire mp_hi_6_25;
wire mp_hi_5_25;
wire mp_hi_4_25;
wire mp_hi_3_25;
wire mp_hi_2_25;
wire mr_21_26;
wire mr_20_22;
wire mr_19_25;
wire mr_18_25;
wire mr_17_25;
wire mr_16_25;
wire mr_15_25;
wire mr_14_25;
wire mr_13_25;
wire mr_12_25;
wire mr_11_25;
wire mr_10_25;
wire mr_9_25;
wire mr_8_25;
wire mr_7_25;
wire mr_6_25;
wire mr_5_25;
wire mr_4_25;
wire mr_3_25;
wire mr_2_25;
wire n839_96;
wire n839_100;
wire n839_106;
wire n839_108;
wire n839_110;
wire n839_114;
wire n839_116;
wire n839_122;
wire n1081_86;
wire n1081_87;
wire n1083_79;
wire n1084_89;
wire n1178_60;
wire n1178_61;
wire n1179_60;
wire n1180_60;
wire n1181_60;
wire n1182_60;
wire n1183_60;
wire n1184_60;
wire n1185_60;
wire n1186_60;
wire n1187_60;
wire n1188_60;
wire n1189_60;
wire n1190_44;
wire n1191_44;
wire n1192_44;
wire n1193_44;
wire n1194_44;
wire n1195_44;
wire n1196_44;
wire n1197_44;
wire n1199_44;
wire n1205_45;
wire n1206_44;
wire n1206_45;
wire n1207_45;
wire n1208_44;
wire n1208_45;
wire n1209_45;
wire n1210_45;
wire n1211_44;
wire n1211_45;
wire n1212_44;
wire n1212_45;
wire n1213_44;
wire n1214_44;
wire n1220_45;
wire n1221_44;
wire n1221_45;
wire n1222_44;
wire n1222_45;
wire n1223_45;
wire n1224_45;
wire n1225_44;
wire n1225_45;
wire n1226_44;
wire n1226_45;
wire n1227_44;
wire n1227_45;
wire n1228_44;
wire n1229_44;
wire n1235_45;
wire n1236_44;
wire n1236_45;
wire n1237_44;
wire n1237_45;
wire n1238_44;
wire n1238_45;
wire n1239_44;
wire n1239_45;
wire n1240_44;
wire n1240_45;
wire n1241_44;
wire n1241_45;
wire n1242_45;
wire n1244_44;
wire n1288_8;
wire n1428_11;
wire slot_3_11;
wire ld_addr_8_6;
wire ld_addr_8_7;
wire level_addr_14_10;
wire level_addr_14_11;
wire level_addr_13_10;
wire level_addr_13_11;
wire level_addr_12_10;
wire level_addr_12_11;
wire level_addr_11_10;
wire level_addr_11_11;
wire level_addr_10_10;
wire level_addr_10_11;
wire level_addr_9_11;
wire level_addr_9_12;
wire level_addr_8_11;
wire level_addr_8_12;
wire level_addr_7_11;
wire level_addr_7_12;
wire level_addr_6_11;
wire level_addr_6_12;
wire level_addr_5_11;
wire level_addr_5_12;
wire level_addr_4_11;
wire level_addr_4_12;
wire level_addr_3_11;
wire level_addr_3_12;
wire level_addr_2_11;
wire level_addr_2_12;
wire level_addr_1_11;
wire level_addr_1_12;
wire level_addr_0_11;
wire level_addr_0_12;
wire n1080_77;
wire n1255_48;
wire n1252_47;
wire n1250_47;
wire n1246_47;
wire mp_hi_15_19;
wire mp_hi_15_20;
wire n867_8;
wire nv_index_2_5;
wire nv_index_3_5;
wire nv_index_3_6;
wire n974_8;
wire n974_9;
wire n974_10;
wire n974_11;
wire n974_12;
wire n974_13;
wire n974_14;
wire n974_15;
wire n974_16;
wire n974_17;
wire n974_18;
wire n974_19;
wire n1178_62;
wire n1189_61;
wire n1199_46;
wire n1199_47;
wire n1205_46;
wire n1211_46;
wire n1225_46;
wire n1235_46;
wire n1238_46;
wire n1239_46;
wire n1240_46;
wire slot_3_12;
wire n1250_48;
wire n867_9;
wire n867_10;
wire n867_11;
wire n867_12;
wire n1189_62;
wire n1189_63;
wire n867_13;
wire n867_14;
wire n867_15;
wire n867_16;
wire n867_17;
wire n867_18;
wire n867_19;
wire n867_20;
wire n1189_64;
wire n1189_65;
wire n1189_66;
wire n1083_81;
wire n1208_48;
wire n1210_48;
wire n1245_46;
wire slot_3_14;
wire point_4_10;
wire n1081_90;
wire n1207_47;
wire n1235_48;
wire n1220_48;
wire n1205_49;
wire n1220_50;
wire n1224_47;
wire n1223_48;
wire n1134_63;
wire n1133_63;
wire n1136_63;
wire n1135_63;
wire n1138_63;
wire n1137_63;
wire n1145_63;
wire n1143_63;
wire n1141_63;
wire n1146_64;
wire n1144_64;
wire n1142_64;
wire n1148_66;
wire n1147_64;
wire n1140_64;
wire n1139_64;
wire n1200_49;
wire ratio_addr_6_7;
wire n1288_11;
wire n1081_92;
wire n1084_91;
wire level_addr_14_14;
wire n1082_85;
wire n1288_13;
wire n173_9;
wire n174_6;
wire n1117_60;
wire n1118_60;
wire n1119_60;
wire n1120_60;
wire n1121_60;
wire n1122_60;
wire n1123_60;
wire n1124_60;
wire n1125_60;
wire n1126_60;
wire n1127_60;
wire n1128_60;
wire n1129_60;
wire n1130_60;
wire n1131_60;
wire n1132_61;
wire n1133_65;
wire n1134_65;
wire n1135_65;
wire n1136_65;
wire n1137_65;
wire n1138_65;
wire n1139_66;
wire n1140_66;
wire n1141_65;
wire n1142_66;
wire n1143_65;
wire n1144_66;
wire n1145_65;
wire n1146_66;
wire n1147_66;
wire n1148_68;
wire state_3_12;
wire n1162_69;
wire n1163_69;
wire n1166_69;
wire n1168_69;
wire n1169_69;
wire n1170_69;
wire n1171_69;
wire n1172_69;
wire n1173_69;
wire n1174_69;
wire n1175_69;
wire n1176_69;
wire n1177_69;
wire mp_lo_12_25;
wire mr_2_27;
wire mr_3_27;
wire mr_4_27;
wire mr_5_27;
wire mr_6_27;
wire mr_7_27;
wire mr_8_27;
wire mr_9_27;
wire mr_10_27;
wire mr_11_27;
wire mr_12_27;
wire mr_13_27;
wire mr_14_27;
wire mr_15_27;
wire mr_16_27;
wire mr_17_27;
wire mr_18_27;
wire mr_19_27;
wire mr_20_24;
wire mp_hi_2_27;
wire mp_hi_3_27;
wire mp_hi_4_27;
wire mp_hi_5_27;
wire mp_hi_6_27;
wire mp_hi_7_27;
wire mp_hi_8_27;
wire mp_hi_9_27;
wire mp_hi_10_27;
wire mp_hi_11_27;
wire mp_hi_12_24;
wire mp_lo_2_27;
wire mp_lo_3_27;
wire mp_lo_4_27;
wire mp_lo_5_27;
wire mp_lo_6_27;
wire mp_lo_7_27;
wire mp_lo_8_27;
wire mp_lo_9_27;
wire mp_lo_10_27;
wire mp_lo_11_27;
wire mp_lo_12_27;
wire n848_9;
wire n1243_46;
wire n1209_47;
wire n1213_47;
wire n1228_47;
wire n1241_48;
wire n1242_47;
wire n1100_14;
wire n1099_11;
wire n1098_11;
wire n1097_11;
wire n1096_11;
wire n1095_11;
wire n1094_11;
wire n1093_11;
wire n1092_11;
wire n1091_11;
wire n1090_11;
wire n1089_11;
wire n1088_11;
wire n1087_11;
wire n1086_11;
wire n1085_14;
wire n1116_15;
wire n1115_11;
wire n1114_11;
wire n1113_11;
wire n1112_11;
wire n1111_11;
wire n1110_11;
wire n1109_11;
wire n1108_11;
wire n1107_11;
wire n1106_11;
wire n1105_11;
wire n1104_11;
wire n1103_11;
wire n1102_11;
wire n1101_11;
wire missing_r;
wire n172_1;
wire n172_2;
wire n171_1;
wire n171_2;
wire n170_1;
wire n170_2;
wire n169_1;
wire n169_2;
wire n168_1;
wire n168_0_COUT;
wire base0_8_2;
wire base0_9_2;
wire base0_10_2;
wire base0_11_2;
wire base0_12_2;
wire base0_13_2;
wire base0_14_0_COUT;
wire hi_w_0_3;
wire hi_w_1_3;
wire hi_w_2_3;
wire hi_w_3_3;
wire hi_w_4_3;
wire hi_w_5_3;
wire hi_w_6_3;
wire hi_w_7_3;
wire hi_w_8_3;
wire hi_w_9_3;
wire hi_w_10_3;
wire hi_w_11_3;
wire hi_w_12_3;
wire hi_w_13_0_COUT;
wire ratio_w_0_3;
wire ratio_w_1_3;
wire ratio_w_2_3;
wire ratio_w_3_3;
wire ratio_w_4_3;
wire ratio_w_5_3;
wire ratio_w_6_3;
wire ratio_w_7_3;
wire ratio_w_8_3;
wire ratio_w_9_3;
wire ratio_w_10_3;
wire ratio_w_11_3;
wire ratio_w_12_3;
wire ratio_w_13_3;
wire ratio_w_14_3;
wire ratio_w_15_3;
wire ratio_w_16_3;
wire ratio_w_17_3;
wire ratio_w_18_3;
wire dp_lo_0_3;
wire dp_lo_1_3;
wire dp_lo_2_3;
wire dp_lo_3_3;
wire dp_lo_4_3;
wire dp_lo_5_3;
wire dp_lo_6_3;
wire dp_lo_7_3;
wire dp_lo_8_3;
wire dp_lo_9_3;
wire dp_lo_10_3;
wire n301_13;
wire dp_hi_0_3;
wire dp_hi_1_3;
wire dp_hi_2_3;
wire dp_hi_3_3;
wire dp_hi_4_3;
wire dp_hi_5_3;
wire dp_hi_6_3;
wire dp_hi_7_3;
wire dp_hi_8_3;
wire dp_hi_9_3;
wire dp_hi_10_3;
wire n327_13;
wire n353_0_SUM;
wire n353_3;
wire n352_2;
wire n352_3;
wire n351_2;
wire n351_3;
wire n350_2;
wire n350_3;
wire n349_2;
wire n349_3;
wire n348_2;
wire n348_3;
wire n347_2;
wire n347_3;
wire n346_2;
wire n346_3;
wire n345_2;
wire n345_3;
wire n344_2;
wire n344_3;
wire n343_2;
wire n343_3;
wire n342_2;
wire n341_8;
wire n391_0_SUM;
wire n391_3;
wire n390_2;
wire n390_3;
wire n389_2;
wire n389_3;
wire n388_2;
wire n388_3;
wire n387_2;
wire n387_3;
wire n386_2;
wire n386_3;
wire n385_2;
wire n385_3;
wire n384_2;
wire n384_3;
wire n383_2;
wire n383_3;
wire n382_2;
wire n382_3;
wire n381_2;
wire n381_3;
wire n380_2;
wire n379_8;
wire dr_0_3;
wire dr_1_3;
wire dr_2_3;
wire dr_3_3;
wire dr_4_3;
wire dr_5_3;
wire dr_6_3;
wire dr_7_3;
wire dr_8_3;
wire dr_9_3;
wire dr_10_3;
wire dr_11_3;
wire dr_12_3;
wire dr_13_3;
wire dr_14_3;
wire dr_15_3;
wire dr_16_3;
wire dr_17_3;
wire dr_18_3;
wire n619_11;
wire n661_0_SUM;
wire n661_3;
wire n660_2;
wire n660_3;
wire n659_2;
wire n659_3;
wire n658_2;
wire n658_3;
wire n657_2;
wire n657_3;
wire n656_2;
wire n656_3;
wire n655_2;
wire n655_3;
wire n654_2;
wire n654_3;
wire n653_2;
wire n653_3;
wire n652_2;
wire n652_3;
wire n651_2;
wire n651_3;
wire n650_2;
wire n650_3;
wire n649_2;
wire n649_3;
wire n648_2;
wire n648_3;
wire n647_2;
wire n647_3;
wire n646_2;
wire n646_3;
wire n645_2;
wire n645_3;
wire n644_2;
wire n644_3;
wire n643_2;
wire n643_3;
wire n642_2;
wire n641_8;
wire lo_w_0_3;
wire lo_w_1_3;
wire lo_w_2_3;
wire lo_w_3_3;
wire lo_w_4_3;
wire lo_w_5_3;
wire lo_w_6_3;
wire lo_w_7_3;
wire lo_w_8_3;
wire lo_w_9_3;
wire lo_w_10_3;
wire lo_w_11_3;
wire lo_w_12_3;
wire lo_w_13_0_COUT;
wire xe_0_2;
wire xe_0_3;
wire xe_1_2;
wire xe_1_3;
wire xe_2_2;
wire xe_2_3;
wire xe_3_2;
wire xe_3_3;
wire xe_4_2;
wire xe_4_3;
wire xe_5_2;
wire xe_5_3;
wire xe_6_2;
wire xe_6_3;
wire xe_7_2;
wire xe_7_3;
wire xe_8_2;
wire xe_8_3;
wire xe_9_2;
wire xe_9_3;
wire xe_10_2;
wire xe_10_3;
wire xe_11_2;
wire xe_11_3;
wire xe_12_2;
wire xe_12_3;
wire xe_13_2;
wire xe_13_3;
wire xe_14_2;
wire xe_14_3;
wire xe_15_2;
wire xe_15_3;
wire xe_16_2;
wire xe_16_3;
wire xe_17_2;
wire xe_17_3;
wire xe_24_2;
wire xe_24_0_COUT;
wire xe_0_5;
wire xe_1_5;
wire xe_2_5;
wire xe_3_5;
wire xe_4_5;
wire xe_5_5;
wire xe_6_5;
wire xe_7_5;
wire xe_8_5;
wire xe_9_5;
wire xe_10_5;
wire xe_11_5;
wire xe_12_5;
wire xe_13_5;
wire xe_14_5;
wire xe_15_5;
wire xe_16_5;
wire xe_17_5;
wire xe_24_1_COUT;
wire n839_35;
wire n839_37;
wire n839_39;
wire n839_41;
wire n839_43;
wire n839_45;
wire n839_47;
wire n839_49;
wire n839_51;
wire n839_53;
wire n839_55;
wire n839_57;
wire n839_59;
wire n839_61;
wire n839_63;
wire n301_16;
wire n327_16;
wire n619_14;
wire soft_steps_3_8;
wire [8:4] ratio_addr;
wire [13:2] mp_lo;
wire [13:2] mp_hi;
wire [21:2] mr;
wire [14:0] level_addr;
wire [5:2] nv_index;
wire [4:0] voice_r_0;
wire [6:0] note_r;
wire [6:6] vel_r;
wire [11:0] lv_a;
wire [11:0] lv_b;
wire [11:0] lv_c;
wire [11:0] lv_d;
wire [13:0] lo_r;
wire [19:0] ratio_a;
wire [3:0] slot;
wire [4:0] point;
wire [14:0] ptr0;
wire [14:4] ptr1;
wire [14:5] ptr2;
wire [14:6] ptr3;
wire [30:0] inc0_r;
wire [46:19] inc_prod;
wire [24:8] mv;
wire [12:0] extra_att;
wire [13:5] av_prod;
wire [14:8] base0;
wire [13:0] hi_w;
wire [18:0] ratio_w;
wire [11:0] dp_lo;
wire [11:0] dp_hi;
wire [19:0] dr;
wire [13:0] lo_w;
wire [24:0] xe;
wire [11:0] level_q;
wire [19:0] ratio_q;
wire [12:0] note_q;
wire [31:31] DO;
wire [62:0] DOUT;
wire [47:0] DOUT_0;
wire [47:0] CASO;
wire [26:0] SOA;
wire [23:13] DOUT_1;
wire [23:0] DOUT_2;
wire VCC;
wire GND;
  LUT2 ratio_addr_8_s1 (
    .F(ratio_addr[8]),
    .I0(note_r[5]),
    .I1(note_r[6]) 
);
defparam ratio_addr_8_s1.INIT=4'h8;
  LUT3 ratio_addr_7_s1 (
    .F(ratio_addr[7]),
    .I0(ratio_addr[6]),
    .I1(note_r[6]),
    .I2(note_r[5]) 
);
defparam ratio_addr_7_s1.INIT=8'h1C;
  LUT4 ratio_addr_6_s1 (
    .F(ratio_addr[6]),
    .I0(ratio_addr_6_7),
    .I1(note_r[3]),
    .I2(note_r[5]),
    .I3(note_r[6]) 
);
defparam ratio_addr_6_s1.INIT=16'hAE10;
  LUT4 ratio_addr_5_s1 (
    .F(ratio_addr[5]),
    .I0(note_r[3]),
    .I1(note_r[5]),
    .I2(note_r[6]),
    .I3(ratio_addr_6_7) 
);
defparam ratio_addr_5_s1.INIT=16'h2BD4;
  LUT4 n974_s0 (
    .F(n974_3),
    .I0(n974_4),
    .I1(n974_5),
    .I2(n974_6),
    .I3(n974_7) 
);
defparam n974_s0.INIT=16'hFFFE;
  LUT4 mp_lo_12_s12 (
    .F(mp_lo[12]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[11]),
    .I2(mp_lo_12_27),
    .I3(mp_lo_12_23) 
);
defparam mp_lo_12_s12.INIT=16'hFFF8;
  LUT4 mp_lo_11_s13 (
    .F(mp_lo[11]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[10]),
    .I2(mp_lo_11_27),
    .I3(mp_lo_11_25) 
);
defparam mp_lo_11_s13.INIT=16'hFFF8;
  LUT4 mp_lo_10_s13 (
    .F(mp_lo[10]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[9]),
    .I2(mp_lo_10_27),
    .I3(mp_lo_10_25) 
);
defparam mp_lo_10_s13.INIT=16'hFFF8;
  LUT4 mp_lo_9_s13 (
    .F(mp_lo[9]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[8]),
    .I2(mp_lo_9_27),
    .I3(mp_lo_9_25) 
);
defparam mp_lo_9_s13.INIT=16'hFFF8;
  LUT4 mp_lo_8_s13 (
    .F(mp_lo[8]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[7]),
    .I2(mp_lo_8_27),
    .I3(mp_lo_8_25) 
);
defparam mp_lo_8_s13.INIT=16'hFFF8;
  LUT4 mp_lo_7_s13 (
    .F(mp_lo[7]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[6]),
    .I2(mp_lo_7_27),
    .I3(mp_lo_7_25) 
);
defparam mp_lo_7_s13.INIT=16'hFFF8;
  LUT4 mp_lo_6_s13 (
    .F(mp_lo[6]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[5]),
    .I2(mp_lo_6_27),
    .I3(mp_lo_6_25) 
);
defparam mp_lo_6_s13.INIT=16'hFFF8;
  LUT4 mp_lo_5_s13 (
    .F(mp_lo[5]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[4]),
    .I2(mp_lo_5_27),
    .I3(mp_lo_5_25) 
);
defparam mp_lo_5_s13.INIT=16'hFFF8;
  LUT4 mp_lo_4_s13 (
    .F(mp_lo[4]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[3]),
    .I2(mp_lo_4_27),
    .I3(mp_lo_4_25) 
);
defparam mp_lo_4_s13.INIT=16'hFFF8;
  LUT4 mp_lo_3_s13 (
    .F(mp_lo[3]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[2]),
    .I2(mp_lo_3_27),
    .I3(mp_lo_3_25) 
);
defparam mp_lo_3_s13.INIT=16'hFFF8;
  LUT4 mp_lo_2_s13 (
    .F(mp_lo[2]),
    .I0(mp_lo_12_25),
    .I1(dp_lo[1]),
    .I2(mp_lo_2_27),
    .I3(mp_lo_2_25) 
);
defparam mp_lo_2_s13.INIT=16'hFFF8;
  LUT4 mp_hi_12_s12 (
    .F(mp_hi[12]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[11]),
    .I2(mp_hi_12_24),
    .I3(mp_hi_12_22) 
);
defparam mp_hi_12_s12.INIT=16'hFFF8;
  LUT4 mp_hi_11_s13 (
    .F(mp_hi[11]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[10]),
    .I2(mp_hi_11_27),
    .I3(mp_hi_11_25) 
);
defparam mp_hi_11_s13.INIT=16'hFFF8;
  LUT4 mp_hi_10_s13 (
    .F(mp_hi[10]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[9]),
    .I2(mp_hi_10_27),
    .I3(mp_hi_10_25) 
);
defparam mp_hi_10_s13.INIT=16'hFFF8;
  LUT4 mp_hi_9_s13 (
    .F(mp_hi[9]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[8]),
    .I2(mp_hi_9_27),
    .I3(mp_hi_9_25) 
);
defparam mp_hi_9_s13.INIT=16'hFFF8;
  LUT4 mp_hi_8_s13 (
    .F(mp_hi[8]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[7]),
    .I2(mp_hi_8_27),
    .I3(mp_hi_8_25) 
);
defparam mp_hi_8_s13.INIT=16'hFFF8;
  LUT4 mp_hi_7_s13 (
    .F(mp_hi[7]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[6]),
    .I2(mp_hi_7_27),
    .I3(mp_hi_7_25) 
);
defparam mp_hi_7_s13.INIT=16'hFFF8;
  LUT4 mp_hi_6_s13 (
    .F(mp_hi[6]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[5]),
    .I2(mp_hi_6_27),
    .I3(mp_hi_6_25) 
);
defparam mp_hi_6_s13.INIT=16'hFFF8;
  LUT4 mp_hi_5_s13 (
    .F(mp_hi[5]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[4]),
    .I2(mp_hi_5_27),
    .I3(mp_hi_5_25) 
);
defparam mp_hi_5_s13.INIT=16'hFFF8;
  LUT4 mp_hi_4_s13 (
    .F(mp_hi[4]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[3]),
    .I2(mp_hi_4_27),
    .I3(mp_hi_4_25) 
);
defparam mp_hi_4_s13.INIT=16'hFFF8;
  LUT4 mp_hi_3_s13 (
    .F(mp_hi[3]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[2]),
    .I2(mp_hi_3_27),
    .I3(mp_hi_3_25) 
);
defparam mp_hi_3_s13.INIT=16'hFFF8;
  LUT4 mp_hi_2_s13 (
    .F(mp_hi[2]),
    .I0(mp_lo_12_25),
    .I1(dp_hi[1]),
    .I2(mp_hi_2_27),
    .I3(mp_hi_2_25) 
);
defparam mp_hi_2_s13.INIT=16'hFFF8;
  LUT4 mr_20_s12 (
    .F(mr[20]),
    .I0(mp_lo_12_25),
    .I1(dr[19]),
    .I2(mr_20_24),
    .I3(mr_20_22) 
);
defparam mr_20_s12.INIT=16'hFFF8;
  LUT4 mr_19_s13 (
    .F(mr[19]),
    .I0(mp_lo_12_25),
    .I1(dr[18]),
    .I2(mr_19_27),
    .I3(mr_19_25) 
);
defparam mr_19_s13.INIT=16'hFFF8;
  LUT4 mr_18_s13 (
    .F(mr[18]),
    .I0(mp_lo_12_25),
    .I1(dr[17]),
    .I2(mr_18_27),
    .I3(mr_18_25) 
);
defparam mr_18_s13.INIT=16'hFFF8;
  LUT4 mr_17_s13 (
    .F(mr[17]),
    .I0(mp_lo_12_25),
    .I1(dr[16]),
    .I2(mr_17_27),
    .I3(mr_17_25) 
);
defparam mr_17_s13.INIT=16'hFFF8;
  LUT4 mr_16_s13 (
    .F(mr[16]),
    .I0(mp_lo_12_25),
    .I1(dr[15]),
    .I2(mr_16_27),
    .I3(mr_16_25) 
);
defparam mr_16_s13.INIT=16'hFFF8;
  LUT4 mr_15_s13 (
    .F(mr[15]),
    .I0(mp_lo_12_25),
    .I1(dr[14]),
    .I2(mr_15_27),
    .I3(mr_15_25) 
);
defparam mr_15_s13.INIT=16'hFFF8;
  LUT4 mr_14_s13 (
    .F(mr[14]),
    .I0(mp_lo_12_25),
    .I1(dr[13]),
    .I2(mr_14_27),
    .I3(mr_14_25) 
);
defparam mr_14_s13.INIT=16'hFFF8;
  LUT4 mr_13_s13 (
    .F(mr[13]),
    .I0(mp_lo_12_25),
    .I1(dr[12]),
    .I2(mr_13_27),
    .I3(mr_13_25) 
);
defparam mr_13_s13.INIT=16'hFFF8;
  LUT4 mr_12_s13 (
    .F(mr[12]),
    .I0(mp_lo_12_25),
    .I1(dr[11]),
    .I2(mr_12_27),
    .I3(mr_12_25) 
);
defparam mr_12_s13.INIT=16'hFFF8;
  LUT4 mr_11_s13 (
    .F(mr[11]),
    .I0(mp_lo_12_25),
    .I1(dr[10]),
    .I2(mr_11_27),
    .I3(mr_11_25) 
);
defparam mr_11_s13.INIT=16'hFFF8;
  LUT4 mr_10_s13 (
    .F(mr[10]),
    .I0(mp_lo_12_25),
    .I1(dr[9]),
    .I2(mr_10_27),
    .I3(mr_10_25) 
);
defparam mr_10_s13.INIT=16'hFFF8;
  LUT4 mr_9_s13 (
    .F(mr[9]),
    .I0(mp_lo_12_25),
    .I1(dr[8]),
    .I2(mr_9_27),
    .I3(mr_9_25) 
);
defparam mr_9_s13.INIT=16'hFFF8;
  LUT4 mr_8_s13 (
    .F(mr[8]),
    .I0(mp_lo_12_25),
    .I1(dr[7]),
    .I2(mr_8_27),
    .I3(mr_8_25) 
);
defparam mr_8_s13.INIT=16'hFFF8;
  LUT4 mr_7_s13 (
    .F(mr[7]),
    .I0(mp_lo_12_25),
    .I1(dr[6]),
    .I2(mr_7_27),
    .I3(mr_7_25) 
);
defparam mr_7_s13.INIT=16'hFFF8;
  LUT4 mr_6_s13 (
    .F(mr[6]),
    .I0(mp_lo_12_25),
    .I1(dr[5]),
    .I2(mr_6_27),
    .I3(mr_6_25) 
);
defparam mr_6_s13.INIT=16'hFFF8;
  LUT4 mr_5_s13 (
    .F(mr[5]),
    .I0(mp_lo_12_25),
    .I1(dr[4]),
    .I2(mr_5_27),
    .I3(mr_5_25) 
);
defparam mr_5_s13.INIT=16'hFFF8;
  LUT4 mr_4_s13 (
    .F(mr[4]),
    .I0(mp_lo_12_25),
    .I1(dr[3]),
    .I2(mr_4_27),
    .I3(mr_4_25) 
);
defparam mr_4_s13.INIT=16'hFFF8;
  LUT4 mr_3_s13 (
    .F(mr[3]),
    .I0(mp_lo_12_25),
    .I1(dr[2]),
    .I2(mr_3_27),
    .I3(mr_3_25) 
);
defparam mr_3_s13.INIT=16'hFFF8;
  LUT4 mr_2_s13 (
    .F(mr[2]),
    .I0(mp_lo_12_25),
    .I1(dr[1]),
    .I2(mr_2_27),
    .I3(mr_2_25) 
);
defparam mr_2_s13.INIT=16'hFFF8;
  LUT4 n839_s130 (
    .F(n839_65),
    .I0(n3804_5),
    .I1(n839_96),
    .I2(n839_147),
    .I3(voice_r_0[0]) 
);
defparam n839_s130.INIT=16'hF088;
  LUT4 n839_s131 (
    .F(n839_67),
    .I0(n839_98),
    .I1(n3804_5_83),
    .I2(n839_161),
    .I3(voice_r_0[0]) 
);
defparam n839_s131.INIT=16'h88F0;
  LUT4 n839_s132 (
    .F(n839_69),
    .I0(n3804_5_84),
    .I1(n839_100),
    .I2(n839_165),
    .I3(voice_r_0[0]) 
);
defparam n839_s132.INIT=16'hF088;
  LUT4 n839_s133 (
    .F(n839_71),
    .I0(n839_102),
    .I1(n3804_5_85),
    .I2(n839_167),
    .I3(voice_r_0[0]) 
);
defparam n839_s133.INIT=16'hF088;
  LUT3 n839_s134 (
    .F(n839_73),
    .I0(n839_169),
    .I1(n839_171),
    .I2(voice_r_0[0]) 
);
defparam n839_s134.INIT=8'hCA;
  LUT4 n839_s135 (
    .F(n839_75),
    .I0(n3804_5_86),
    .I1(n839_106),
    .I2(n839_135),
    .I3(voice_r_0[0]) 
);
defparam n839_s135.INIT=16'hF088;
  LUT4 n839_s136 (
    .F(n839_77),
    .I0(n839_108),
    .I1(n3804_5_87),
    .I2(n839_137),
    .I3(voice_r_0[0]) 
);
defparam n839_s136.INIT=16'hF088;
  LUT4 n839_s137 (
    .F(n839_79),
    .I0(n839_110),
    .I1(n3804_5_88),
    .I2(n839_139),
    .I3(voice_r_0[0]) 
);
defparam n839_s137.INIT=16'h88F0;
  LUT3 n839_s138 (
    .F(n839_81),
    .I0(n839_141),
    .I1(n839_143),
    .I2(voice_r_0[0]) 
);
defparam n839_s138.INIT=8'hCA;
  LUT4 n839_s139 (
    .F(n839_83),
    .I0(n3804_5_89),
    .I1(n839_114),
    .I2(n839_145),
    .I3(voice_r_0[0]) 
);
defparam n839_s139.INIT=16'hF088;
  LUT4 n839_s140 (
    .F(n839_85),
    .I0(n839_116),
    .I1(n3804_5_90),
    .I2(n839_149),
    .I3(voice_r_0[0]) 
);
defparam n839_s140.INIT=16'hF088;
  LUT4 n839_s141 (
    .F(n839_87),
    .I0(n839_118),
    .I1(n3804_5_91),
    .I2(n839_151),
    .I3(voice_r_0[0]) 
);
defparam n839_s141.INIT=16'h88F0;
  LUT4 n839_s142 (
    .F(n839_89),
    .I0(n3804_5_92),
    .I1(n839_120),
    .I2(n839_153),
    .I3(voice_r_0[0]) 
);
defparam n839_s142.INIT=16'hF088;
  LUT4 n839_s143 (
    .F(n839_91),
    .I0(n3804_5_93),
    .I1(n839_122),
    .I2(n839_155),
    .I3(voice_r_0[0]) 
);
defparam n839_s143.INIT=16'h88F0;
  LUT3 n839_s144 (
    .F(n839_93),
    .I0(n839_157),
    .I1(n839_159),
    .I2(voice_r_0[0]) 
);
defparam n839_s144.INIT=8'hCA;
  LUT4 n839_s145 (
    .F(n839_95),
    .I0(n3804_5_94),
    .I1(n839_126),
    .I2(n839_163),
    .I3(voice_r_0[0]) 
);
defparam n839_s145.INIT=16'h88F0;
  LUT4 n1084_s63 (
    .F(n1084_87),
    .I0(n1084_91),
    .I1(state[0]),
    .I2(state[4]),
    .I3(n1084_89) 
);
defparam n1084_s63.INIT=16'h7303;
  LUT4 n1178_s47 (
    .F(n1178_59),
    .I0(n1178_60),
    .I1(inc_prod[30]),
    .I2(n1178_61),
    .I3(state[4]) 
);
defparam n1178_s47.INIT=16'h8F88;
  LUT4 n1179_s47 (
    .F(n1179_59),
    .I0(n1178_60),
    .I1(inc_prod[29]),
    .I2(n1179_60),
    .I3(state[4]) 
);
defparam n1179_s47.INIT=16'h8F88;
  LUT4 n1180_s47 (
    .F(n1180_59),
    .I0(n1178_60),
    .I1(inc_prod[28]),
    .I2(n1180_60),
    .I3(state[4]) 
);
defparam n1180_s47.INIT=16'h8F88;
  LUT4 n1181_s47 (
    .F(n1181_59),
    .I0(n1178_60),
    .I1(inc_prod[27]),
    .I2(n1181_60),
    .I3(state[4]) 
);
defparam n1181_s47.INIT=16'h8F88;
  LUT4 n1182_s47 (
    .F(n1182_59),
    .I0(n1178_60),
    .I1(inc_prod[26]),
    .I2(n1182_60),
    .I3(state[4]) 
);
defparam n1182_s47.INIT=16'h8F88;
  LUT4 n1183_s47 (
    .F(n1183_59),
    .I0(n1178_60),
    .I1(inc_prod[25]),
    .I2(n1183_60),
    .I3(state[4]) 
);
defparam n1183_s47.INIT=16'h8F88;
  LUT4 n1184_s47 (
    .F(n1184_59),
    .I0(n1178_60),
    .I1(inc_prod[24]),
    .I2(n1184_60),
    .I3(state[4]) 
);
defparam n1184_s47.INIT=16'h8F88;
  LUT4 n1185_s47 (
    .F(n1185_59),
    .I0(n1178_60),
    .I1(inc_prod[23]),
    .I2(n1185_60),
    .I3(state[4]) 
);
defparam n1185_s47.INIT=16'h8F88;
  LUT4 n1186_s47 (
    .F(n1186_59),
    .I0(n1178_60),
    .I1(inc_prod[22]),
    .I2(n1186_60),
    .I3(state[4]) 
);
defparam n1186_s47.INIT=16'h8F88;
  LUT4 n1187_s47 (
    .F(n1187_59),
    .I0(n1178_60),
    .I1(inc_prod[21]),
    .I2(n1187_60),
    .I3(state[4]) 
);
defparam n1187_s47.INIT=16'h8F88;
  LUT4 n1188_s47 (
    .F(n1188_59),
    .I0(n1178_60),
    .I1(inc_prod[20]),
    .I2(n1188_60),
    .I3(state[4]) 
);
defparam n1188_s47.INIT=16'h8F88;
  LUT4 n1189_s47 (
    .F(n1189_59),
    .I0(state[3]),
    .I1(inc_prod[19]),
    .I2(n1189_60),
    .I3(state[4]) 
);
defparam n1189_s47.INIT=16'h0F44;
  LUT3 n1190_s39 (
    .F(n1190_43),
    .I0(base0[14]),
    .I1(n1190_44),
    .I2(state[4]) 
);
defparam n1190_s39.INIT=8'hCA;
  LUT4 n1191_s39 (
    .F(n1191_43),
    .I0(base0[13]),
    .I1(ptr0[13]),
    .I2(n1191_44),
    .I3(state[4]) 
);
defparam n1191_s39.INIT=16'h3CAA;
  LUT4 n1192_s39 (
    .F(n1192_43),
    .I0(base0[12]),
    .I1(ptr0[12]),
    .I2(n1192_44),
    .I3(state[4]) 
);
defparam n1192_s39.INIT=16'h3CAA;
  LUT4 n1193_s39 (
    .F(n1193_43),
    .I0(base0[11]),
    .I1(ptr0[11]),
    .I2(n1193_44),
    .I3(state[4]) 
);
defparam n1193_s39.INIT=16'h3CAA;
  LUT4 n1194_s39 (
    .F(n1194_43),
    .I0(base0[10]),
    .I1(ptr0[10]),
    .I2(n1194_44),
    .I3(state[4]) 
);
defparam n1194_s39.INIT=16'h3CAA;
  LUT4 n1195_s39 (
    .F(n1195_43),
    .I0(base0[9]),
    .I1(ptr0[9]),
    .I2(n1195_44),
    .I3(state[4]) 
);
defparam n1195_s39.INIT=16'h3CAA;
  LUT4 n1196_s39 (
    .F(n1196_43),
    .I0(base0[8]),
    .I1(ptr0[8]),
    .I2(n1196_44),
    .I3(state[4]) 
);
defparam n1196_s39.INIT=16'h3CAA;
  LUT4 n1197_s39 (
    .F(n1197_43),
    .I0(n173_4),
    .I1(ptr0[7]),
    .I2(n1197_44),
    .I3(state[4]) 
);
defparam n1197_s39.INIT=16'h3CAA;
  LUT4 n1198_s39 (
    .F(n1198_43),
    .I0(n174_6),
    .I1(ptr0[6]),
    .I2(n1243_46),
    .I3(state[4]) 
);
defparam n1198_s39.INIT=16'h3CAA;
  LUT3 n1205_s39 (
    .F(n1205_43),
    .I0(n1205_49),
    .I1(n1205_45),
    .I2(state[4]) 
);
defparam n1205_s39.INIT=8'hCA;
  LUT4 n1206_s39 (
    .F(n1206_43),
    .I0(n1206_44),
    .I1(ptr1[13]),
    .I2(n1206_45),
    .I3(state[4]) 
);
defparam n1206_s39.INIT=16'h3CAA;
  LUT4 n1207_s39 (
    .F(n1207_43),
    .I0(n1207_47),
    .I1(ptr1[12]),
    .I2(n1207_45),
    .I3(state[4]) 
);
defparam n1207_s39.INIT=16'h3CAA;
  LUT4 n1208_s39 (
    .F(n1208_43),
    .I0(n1208_44),
    .I1(ptr1[11]),
    .I2(n1208_45),
    .I3(state[4]) 
);
defparam n1208_s39.INIT=16'h3CAA;
  LUT4 n1209_s39 (
    .F(n1209_43),
    .I0(n1209_47),
    .I1(ptr1[10]),
    .I2(n1209_45),
    .I3(state[4]) 
);
defparam n1209_s39.INIT=16'h3CAA;
  LUT4 n1210_s39 (
    .F(n1210_43),
    .I0(n1210_48),
    .I1(ptr1[9]),
    .I2(n1210_45),
    .I3(state[4]) 
);
defparam n1210_s39.INIT=16'h3C55;
  LUT4 n1211_s39 (
    .F(n1211_43),
    .I0(n1211_44),
    .I1(ptr1[8]),
    .I2(n1211_45),
    .I3(state[4]) 
);
defparam n1211_s39.INIT=16'h3CAA;
  LUT4 n1212_s39 (
    .F(n1212_43),
    .I0(n1212_44),
    .I1(ptr1[7]),
    .I2(n1212_45),
    .I3(state[4]) 
);
defparam n1212_s39.INIT=16'h3CAA;
  LUT4 n1213_s39 (
    .F(n1213_43),
    .I0(n1213_44),
    .I1(ptr1[6]),
    .I2(n1213_47),
    .I3(state[4]) 
);
defparam n1213_s39.INIT=16'h3C55;
  LUT4 n1214_s39 (
    .F(n1214_43),
    .I0(n1214_44),
    .I1(ptr1[5]),
    .I2(n1229_44),
    .I3(state[4]) 
);
defparam n1214_s39.INIT=16'h3CAA;
  LUT3 n1220_s39 (
    .F(n1220_43),
    .I0(n1220_48),
    .I1(n1220_45),
    .I2(state[4]) 
);
defparam n1220_s39.INIT=8'hCA;
  LUT4 n1221_s39 (
    .F(n1221_43),
    .I0(n1221_44),
    .I1(ptr2[13]),
    .I2(n1221_45),
    .I3(state[4]) 
);
defparam n1221_s39.INIT=16'h3CAA;
  LUT4 n1222_s39 (
    .F(n1222_43),
    .I0(n1222_44),
    .I1(ptr2[12]),
    .I2(n1222_45),
    .I3(state[4]) 
);
defparam n1222_s39.INIT=16'h3CAA;
  LUT4 n1223_s39 (
    .F(n1223_43),
    .I0(n1223_48),
    .I1(ptr2[11]),
    .I2(n1223_45),
    .I3(state[4]) 
);
defparam n1223_s39.INIT=16'h3CAA;
  LUT4 n1224_s39 (
    .F(n1224_43),
    .I0(n1224_47),
    .I1(ptr2[10]),
    .I2(n1224_45),
    .I3(state[4]) 
);
defparam n1224_s39.INIT=16'h3C55;
  LUT4 n1225_s39 (
    .F(n1225_43),
    .I0(n1225_44),
    .I1(ptr2[9]),
    .I2(n1225_45),
    .I3(state[4]) 
);
defparam n1225_s39.INIT=16'h3CAA;
  LUT4 n1226_s39 (
    .F(n1226_43),
    .I0(n1226_44),
    .I1(ptr2[8]),
    .I2(n1226_45),
    .I3(state[4]) 
);
defparam n1226_s39.INIT=16'h3CAA;
  LUT4 n1227_s39 (
    .F(n1227_43),
    .I0(n1227_44),
    .I1(ptr2[7]),
    .I2(n1227_45),
    .I3(state[4]) 
);
defparam n1227_s39.INIT=16'h3CAA;
  LUT4 n1228_s39 (
    .F(n1228_43),
    .I0(n1228_44),
    .I1(ptr2[6]),
    .I2(n1228_47),
    .I3(state[4]) 
);
defparam n1228_s39.INIT=16'h3C55;
  LUT4 n1229_s39 (
    .F(n1229_43),
    .I0(n1214_44),
    .I1(ptr2[5]),
    .I2(n1229_44),
    .I3(state[4]) 
);
defparam n1229_s39.INIT=16'h3C55;
  LUT4 n1230_s40 (
    .F(n1230_44),
    .I0(n1200_49),
    .I1(ptr1[4]),
    .I2(n1245_46),
    .I3(state[4]) 
);
defparam n1230_s40.INIT=16'h3C55;
  LUT3 n1235_s39 (
    .F(n1235_43),
    .I0(n1235_48),
    .I1(n1235_45),
    .I2(state[4]) 
);
defparam n1235_s39.INIT=8'hCA;
  LUT4 n1236_s39 (
    .F(n1236_43),
    .I0(n1236_44),
    .I1(ptr3[13]),
    .I2(n1236_45),
    .I3(state[4]) 
);
defparam n1236_s39.INIT=16'h3CAA;
  LUT4 n1237_s39 (
    .F(n1237_43),
    .I0(n1237_44),
    .I1(ptr3[12]),
    .I2(n1237_45),
    .I3(state[4]) 
);
defparam n1237_s39.INIT=16'h3CAA;
  LUT4 n1238_s39 (
    .F(n1238_43),
    .I0(n1238_44),
    .I1(ptr3[11]),
    .I2(n1238_45),
    .I3(state[4]) 
);
defparam n1238_s39.INIT=16'h3C55;
  LUT4 n1239_s39 (
    .F(n1239_43),
    .I0(n1239_44),
    .I1(ptr3[10]),
    .I2(n1239_45),
    .I3(state[4]) 
);
defparam n1239_s39.INIT=16'h3C55;
  LUT4 n1240_s39 (
    .F(n1240_43),
    .I0(n1240_44),
    .I1(ptr3[9]),
    .I2(n1240_45),
    .I3(state[4]) 
);
defparam n1240_s39.INIT=16'h3C55;
  LUT4 n1241_s39 (
    .F(n1241_43),
    .I0(n1241_44),
    .I1(ptr3[8]),
    .I2(n1241_45),
    .I3(state[4]) 
);
defparam n1241_s39.INIT=16'h3C55;
  LUT4 n1242_s39 (
    .F(n1242_43),
    .I0(n1242_47),
    .I1(ptr3[7]),
    .I2(n1242_45),
    .I3(state[4]) 
);
defparam n1242_s39.INIT=16'h3C55;
  LUT4 n1243_s39 (
    .F(n1243_43),
    .I0(n174_6),
    .I1(ptr3[6]),
    .I2(n1243_46),
    .I3(state[4]) 
);
defparam n1243_s39.INIT=16'h3C55;
  LUT4 n1244_s39 (
    .F(n1244_43),
    .I0(n1199_44),
    .I1(ptr0[5]),
    .I2(n1244_44),
    .I3(state[4]) 
);
defparam n1244_s39.INIT=16'h3CAA;
  LUT4 n1245_s39 (
    .F(n1245_43),
    .I0(n1200_49),
    .I1(ptr0[4]),
    .I2(n1245_46),
    .I3(state[4]) 
);
defparam n1245_s39.INIT=16'h3CAA;
  LUT2 n1259_s6 (
    .F(n1259_10),
    .I0(state[4]),
    .I1(n135_6) 
);
defparam n1259_s6.INIT=4'h8;
  LUT3 n1300_s4 (
    .F(n1300_8),
    .I0(state[0]),
    .I1(state[1]),
    .I2(n1288_11) 
);
defparam n1300_s4.INIT=8'h40;
  LUT3 n1312_s4 (
    .F(n1312_8),
    .I0(state[1]),
    .I1(state[0]),
    .I2(n1288_11) 
);
defparam n1312_s4.INIT=8'h40;
  LUT3 n1324_s5 (
    .F(n1324_9),
    .I0(state[0]),
    .I1(state[1]),
    .I2(n1288_11) 
);
defparam n1324_s5.INIT=8'h10;
  LUT4 n1341_s5 (
    .F(n1341_9),
    .I0(state[0]),
    .I1(state[1]),
    .I2(state[2]),
    .I3(n1178_60) 
);
defparam n1341_s5.INIT=16'h4000;
  LUT4 n1388_s5 (
    .F(n1388_9),
    .I0(state[1]),
    .I1(state[0]),
    .I2(state[2]),
    .I3(n1178_60) 
);
defparam n1388_s5.INIT=16'h4000;
  LUT4 n1408_s6 (
    .F(n1408_10),
    .I0(state[0]),
    .I1(state[1]),
    .I2(state[2]),
    .I3(n1178_60) 
);
defparam n1408_s6.INIT=16'h1000;
  LUT2 n1428_s6 (
    .F(n1428_10),
    .I0(state[4]),
    .I1(n1428_11) 
);
defparam n1428_s6.INIT=4'h4;
  LUT4 slot_3_s4 (
    .F(slot_3_9),
    .I0(slot_3_14),
    .I1(slot_3_11),
    .I2(state[4]),
    .I3(point_4_10) 
);
defparam slot_3_s4.INIT=16'h4F00;
  LUT4 ld_addr_8_s3 (
    .F(ld_addr_1_4),
    .I0(n1288_8),
    .I1(state[2]),
    .I2(ld_addr_8_6),
    .I3(ld_addr_8_7) 
);
defparam ld_addr_8_s3.INIT=16'hFF10;
  LUT4 state_3_s4 (
    .F(state_4_8),
    .I0(n1450_15),
    .I1(n839_35),
    .I2(state[1]),
    .I3(state_3_12) 
);
defparam state_3_s4.INIT=16'hCAFF;
  LUT2 level_addr_14_s5 (
    .F(level_addr[14]),
    .I0(level_addr_14_10),
    .I1(level_addr_14_11) 
);
defparam level_addr_14_s5.INIT=4'h7;
  LUT2 level_addr_13_s5 (
    .F(level_addr[13]),
    .I0(level_addr_13_10),
    .I1(level_addr_13_11) 
);
defparam level_addr_13_s5.INIT=4'h7;
  LUT2 level_addr_12_s5 (
    .F(level_addr[12]),
    .I0(level_addr_12_10),
    .I1(level_addr_12_11) 
);
defparam level_addr_12_s5.INIT=4'h7;
  LUT2 level_addr_11_s5 (
    .F(level_addr[11]),
    .I0(level_addr_11_10),
    .I1(level_addr_11_11) 
);
defparam level_addr_11_s5.INIT=4'h7;
  LUT2 level_addr_10_s5 (
    .F(level_addr[10]),
    .I0(level_addr_10_10),
    .I1(level_addr_10_11) 
);
defparam level_addr_10_s5.INIT=4'h7;
  LUT2 level_addr_9_s6 (
    .F(level_addr[9]),
    .I0(level_addr_9_11),
    .I1(level_addr_9_12) 
);
defparam level_addr_9_s6.INIT=4'h7;
  LUT2 level_addr_8_s6 (
    .F(level_addr[8]),
    .I0(level_addr_8_11),
    .I1(level_addr_8_12) 
);
defparam level_addr_8_s6.INIT=4'h7;
  LUT2 level_addr_7_s6 (
    .F(level_addr[7]),
    .I0(level_addr_7_11),
    .I1(level_addr_7_12) 
);
defparam level_addr_7_s6.INIT=4'h7;
  LUT2 level_addr_6_s6 (
    .F(level_addr[6]),
    .I0(level_addr_6_11),
    .I1(level_addr_6_12) 
);
defparam level_addr_6_s6.INIT=4'h7;
  LUT2 level_addr_5_s6 (
    .F(level_addr[5]),
    .I0(level_addr_5_11),
    .I1(level_addr_5_12) 
);
defparam level_addr_5_s6.INIT=4'h7;
  LUT2 level_addr_4_s6 (
    .F(level_addr[4]),
    .I0(level_addr_4_11),
    .I1(level_addr_4_12) 
);
defparam level_addr_4_s6.INIT=4'h7;
  LUT2 level_addr_3_s6 (
    .F(level_addr[3]),
    .I0(level_addr_3_11),
    .I1(level_addr_3_12) 
);
defparam level_addr_3_s6.INIT=4'h7;
  LUT2 level_addr_2_s6 (
    .F(level_addr[2]),
    .I0(level_addr_2_11),
    .I1(level_addr_2_12) 
);
defparam level_addr_2_s6.INIT=4'h7;
  LUT2 level_addr_1_s6 (
    .F(level_addr[1]),
    .I0(level_addr_1_11),
    .I1(level_addr_1_12) 
);
defparam level_addr_1_s6.INIT=4'h7;
  LUT2 level_addr_0_s6 (
    .F(level_addr[0]),
    .I0(level_addr_0_11),
    .I1(level_addr_0_12) 
);
defparam level_addr_0_s6.INIT=4'h7;
  LUT4 n1080_s58 (
    .F(n1080_76),
    .I0(n1288_8),
    .I1(ld_addr_8_6),
    .I2(state[2]),
    .I3(n1080_77) 
);
defparam n1080_s58.INIT=16'hFF80;
  LUT2 n1258_s42 (
    .F(n1258_48),
    .I0(slot[0]),
    .I1(state[4]) 
);
defparam n1258_s42.INIT=4'h4;
  LUT3 n1257_s41 (
    .F(n1257_47),
    .I0(slot[0]),
    .I1(slot[1]),
    .I2(state[4]) 
);
defparam n1257_s41.INIT=8'h60;
  LUT4 n1256_s41 (
    .F(n1256_47),
    .I0(slot[0]),
    .I1(slot[1]),
    .I2(slot[2]),
    .I3(state[4]) 
);
defparam n1256_s41.INIT=16'h7800;
  LUT3 n1255_s41 (
    .F(n1255_47),
    .I0(slot[3]),
    .I1(n1255_48),
    .I2(state[4]) 
);
defparam n1255_s41.INIT=8'h60;
  LUT3 n1254_s40 (
    .F(n1254_46),
    .I0(point[0]),
    .I1(slot_3_11),
    .I2(state[4]) 
);
defparam n1254_s40.INIT=8'h10;
  LUT3 n1253_s40 (
    .F(n1253_46),
    .I0(point[0]),
    .I1(point[1]),
    .I2(state[4]) 
);
defparam n1253_s40.INIT=8'h60;
  LUT4 n1252_s40 (
    .F(n1252_46),
    .I0(slot_3_11),
    .I1(point[2]),
    .I2(n1252_47),
    .I3(state[4]) 
);
defparam n1252_s40.INIT=16'h1400;
  LUT4 n1251_s40 (
    .F(n1251_46),
    .I0(point[2]),
    .I1(n1252_47),
    .I2(point[3]),
    .I3(state[4]) 
);
defparam n1251_s40.INIT=16'h7800;
  LUT2 n1250_s40 (
    .F(n1250_46),
    .I0(n1250_47),
    .I1(state[4]) 
);
defparam n1250_s40.INIT=4'h4;
  LUT2 n1249_s40 (
    .F(n1249_46),
    .I0(ptr0[0]),
    .I1(state[4]) 
);
defparam n1249_s40.INIT=4'h4;
  LUT3 n1248_s40 (
    .F(n1248_46),
    .I0(ptr0[1]),
    .I1(ptr0[0]),
    .I2(state[4]) 
);
defparam n1248_s40.INIT=8'h60;
  LUT4 n1247_s40 (
    .F(n1247_46),
    .I0(ptr0[1]),
    .I1(ptr0[0]),
    .I2(ptr0[2]),
    .I3(state[4]) 
);
defparam n1247_s40.INIT=16'h7800;
  LUT3 n1246_s40 (
    .F(n1246_46),
    .I0(ptr0[3]),
    .I1(n1246_47),
    .I2(state[4]) 
);
defparam n1246_s40.INIT=8'h60;
  LUT4 mp_hi_15_s10 (
    .F(mp_hi_15_18),
    .I0(ratio_addr[8]),
    .I1(mp_hi_15_19),
    .I2(mp_hi_15_20),
    .I3(n327_13) 
);
defparam mp_hi_15_s10.INIT=16'h00FE;
  LUT4 mp_lo_15_s10 (
    .F(mp_lo_15_18),
    .I0(ratio_addr[8]),
    .I1(mp_hi_15_19),
    .I2(mp_hi_15_20),
    .I3(n301_13) 
);
defparam mp_lo_15_s10.INIT=16'h00FE;
  LUT2 n867_s2 (
    .F(n867_7),
    .I0(ratio_w[0]),
    .I1(n867_8) 
);
defparam n867_s2.INIT=4'h8;
  LUT2 n866_s2 (
    .F(n866_7),
    .I0(ratio_w[1]),
    .I1(n867_8) 
);
defparam n866_s2.INIT=4'h8;
  LUT2 n865_s2 (
    .F(n865_7),
    .I0(ratio_w[2]),
    .I1(n867_8) 
);
defparam n865_s2.INIT=4'h8;
  LUT2 n864_s2 (
    .F(n864_7),
    .I0(ratio_w[3]),
    .I1(n867_8) 
);
defparam n864_s2.INIT=4'h8;
  LUT2 n863_s2 (
    .F(n863_7),
    .I0(ratio_w[4]),
    .I1(n867_8) 
);
defparam n863_s2.INIT=4'h8;
  LUT2 n862_s2 (
    .F(n862_7),
    .I0(ratio_w[5]),
    .I1(n867_8) 
);
defparam n862_s2.INIT=4'h8;
  LUT2 n861_s2 (
    .F(n861_7),
    .I0(ratio_w[6]),
    .I1(n867_8) 
);
defparam n861_s2.INIT=4'h8;
  LUT2 n860_s2 (
    .F(n860_7),
    .I0(ratio_w[7]),
    .I1(n867_8) 
);
defparam n860_s2.INIT=4'h8;
  LUT2 n859_s2 (
    .F(n859_7),
    .I0(ratio_w[8]),
    .I1(n867_8) 
);
defparam n859_s2.INIT=4'h8;
  LUT2 n858_s2 (
    .F(n858_7),
    .I0(ratio_w[9]),
    .I1(n867_8) 
);
defparam n858_s2.INIT=4'h8;
  LUT2 n857_s2 (
    .F(n857_7),
    .I0(ratio_w[10]),
    .I1(n867_8) 
);
defparam n857_s2.INIT=4'h8;
  LUT2 n856_s2 (
    .F(n856_7),
    .I0(ratio_w[11]),
    .I1(n867_8) 
);
defparam n856_s2.INIT=4'h8;
  LUT2 n855_s2 (
    .F(n855_7),
    .I0(ratio_w[12]),
    .I1(n867_8) 
);
defparam n855_s2.INIT=4'h8;
  LUT2 n854_s2 (
    .F(n854_7),
    .I0(ratio_w[13]),
    .I1(n867_8) 
);
defparam n854_s2.INIT=4'h8;
  LUT2 n853_s2 (
    .F(n853_7),
    .I0(ratio_w[14]),
    .I1(n867_8) 
);
defparam n853_s2.INIT=4'h8;
  LUT2 n852_s2 (
    .F(n852_7),
    .I0(ratio_w[15]),
    .I1(n867_8) 
);
defparam n852_s2.INIT=4'h8;
  LUT2 n851_s2 (
    .F(n851_7),
    .I0(ratio_w[16]),
    .I1(n867_8) 
);
defparam n851_s2.INIT=4'h8;
  LUT2 n850_s2 (
    .F(n850_7),
    .I0(ratio_w[17]),
    .I1(n867_8) 
);
defparam n850_s2.INIT=4'h8;
  LUT2 n849_s2 (
    .F(n849_7),
    .I0(ratio_w[18]),
    .I1(n867_8) 
);
defparam n849_s2.INIT=4'h8;
  LUT4 n1156_s50 (
    .F(n1156_64),
    .I0(n1083_79),
    .I1(ld_addr_8_6),
    .I2(state[4]),
    .I3(point[1]) 
);
defparam n1156_s50.INIT=16'hF888;
  LUT4 n1157_s50 (
    .F(n1157_64),
    .I0(state[0]),
    .I1(state[3]),
    .I2(point[0]),
    .I3(state[4]) 
);
defparam n1157_s50.INIT=16'hF044;
  LUT4 n1167_s51 (
    .F(n1167_65),
    .I0(inc_prod[41]),
    .I1(state[0]),
    .I2(state[4]),
    .I3(state[3]) 
);
defparam n1167_s51.INIT=16'h0C0A;
  LUT4 n1165_s51 (
    .F(n1165_65),
    .I0(inc_prod[43]),
    .I1(state[0]),
    .I2(state[4]),
    .I3(state[3]) 
);
defparam n1165_s51.INIT=16'h0C0A;
  LUT4 n1164_s51 (
    .F(n1164_65),
    .I0(inc_prod[44]),
    .I1(state[0]),
    .I2(state[4]),
    .I3(state[3]) 
);
defparam n1164_s51.INIT=16'h0C0A;
  LUT4 n1153_s50 (
    .F(n1153_66),
    .I0(point[2]),
    .I1(point[3]),
    .I2(point[4]),
    .I3(state[4]) 
);
defparam n1153_s50.INIT=16'h7800;
  LUT3 n1154_s50 (
    .F(n1154_66),
    .I0(point[2]),
    .I1(point[3]),
    .I2(state[4]) 
);
defparam n1154_s50.INIT=8'h60;
  LUT2 n1155_s51 (
    .F(n1155_67),
    .I0(point[2]),
    .I1(state[4]) 
);
defparam n1155_s51.INIT=4'h4;
  LUT3 n173_s0 (
    .F(n173_4),
    .I0(n173_9),
    .I1(nv_index[3]),
    .I2(n1199_44) 
);
defparam n173_s0.INIT=8'h96;
  LUT3 n173_s1 (
    .F(base0_7_3),
    .I0(n173_9),
    .I1(nv_index[3]),
    .I2(n1199_44) 
);
defparam n173_s1.INIT=8'hE8;
  LUT3 nv_index_2_s0 (
    .F(nv_index[2]),
    .I0(note_r[5]),
    .I1(nv_index_2_5),
    .I2(note_r[6]) 
);
defparam nv_index_2_s0.INIT=8'h18;
  LUT3 nv_index_3_s0 (
    .F(nv_index[3]),
    .I0(nv_index_3_5),
    .I1(note_r[3]),
    .I2(nv_index_3_6) 
);
defparam nv_index_3_s0.INIT=8'hF4;
  LUT4 nv_index_4_s0 (
    .F(nv_index[4]),
    .I0(note_r[3]),
    .I1(note_r[2]),
    .I2(note_r[6]),
    .I3(note_r[5]) 
);
defparam nv_index_4_s0.INIT=16'hFF10;
  LUT3 nv_index_5_s0 (
    .F(nv_index[5]),
    .I0(ratio_addr_4_5),
    .I1(note_r[3]),
    .I2(note_r[6]) 
);
defparam nv_index_5_s0.INIT=8'hD0;
  LUT3 ratio_addr_4_s2 (
    .F(ratio_addr_4_5),
    .I0(note_r[2]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam ratio_addr_4_s2.INIT=8'h17;
  LUT3 n974_s1 (
    .F(n974_4),
    .I0(n974_8),
    .I1(n974_9),
    .I2(n974_10) 
);
defparam n974_s1.INIT=8'h80;
  LUT3 n974_s2 (
    .F(n974_5),
    .I0(n974_11),
    .I1(n974_12),
    .I2(n974_13) 
);
defparam n974_s2.INIT=8'h80;
  LUT3 n974_s3 (
    .F(n974_6),
    .I0(n974_14),
    .I1(n974_15),
    .I2(n974_16) 
);
defparam n974_s3.INIT=8'h80;
  LUT3 n974_s4 (
    .F(n974_7),
    .I0(n974_17),
    .I1(n974_18),
    .I2(n974_19) 
);
defparam n974_s4.INIT=8'h80;
  LUT4 mp_lo_13_s14 (
    .F(mp_lo_13_22),
    .I0(n341_8),
    .I1(n301_13),
    .I2(mp_hi_15_19),
    .I3(mp_hi_15_20) 
);
defparam mp_lo_13_s14.INIT=16'h5CCF;
  LUT4 mp_lo_12_s15 (
    .F(mp_lo_12_23),
    .I0(n342_2),
    .I1(n301_13),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_12_s15.INIT=16'hA300;
  LUT4 mp_lo_11_s15 (
    .F(mp_lo_11_25),
    .I0(n343_2),
    .I1(dp_lo[11]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_11_s15.INIT=16'hAC00;
  LUT4 mp_lo_10_s15 (
    .F(mp_lo_10_25),
    .I0(n344_2),
    .I1(dp_lo[10]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_10_s15.INIT=16'hAC00;
  LUT4 mp_lo_9_s15 (
    .F(mp_lo_9_25),
    .I0(n345_2),
    .I1(dp_lo[9]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_9_s15.INIT=16'hAC00;
  LUT4 mp_lo_8_s15 (
    .F(mp_lo_8_25),
    .I0(n346_2),
    .I1(dp_lo[8]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_8_s15.INIT=16'hAC00;
  LUT4 mp_lo_7_s15 (
    .F(mp_lo_7_25),
    .I0(n347_2),
    .I1(dp_lo[7]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_7_s15.INIT=16'hAC00;
  LUT4 mp_lo_6_s15 (
    .F(mp_lo_6_25),
    .I0(n348_2),
    .I1(dp_lo[6]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_6_s15.INIT=16'hAC00;
  LUT4 mp_lo_5_s15 (
    .F(mp_lo_5_25),
    .I0(n349_2),
    .I1(dp_lo[5]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_5_s15.INIT=16'hAC00;
  LUT4 mp_lo_4_s15 (
    .F(mp_lo_4_25),
    .I0(n350_2),
    .I1(dp_lo[4]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_4_s15.INIT=16'hAC00;
  LUT4 mp_lo_3_s15 (
    .F(mp_lo_3_25),
    .I0(n351_2),
    .I1(dp_lo[3]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_3_s15.INIT=16'hAC00;
  LUT4 mp_lo_2_s15 (
    .F(mp_lo_2_25),
    .I0(n352_2),
    .I1(dp_lo[2]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_lo_2_s15.INIT=16'hAC00;
  LUT4 mp_hi_13_s14 (
    .F(mp_hi_13_22),
    .I0(n379_8),
    .I1(n327_13),
    .I2(mp_hi_15_19),
    .I3(mp_hi_15_20) 
);
defparam mp_hi_13_s14.INIT=16'h5CCF;
  LUT4 mp_hi_12_s14 (
    .F(mp_hi_12_22),
    .I0(n380_2),
    .I1(n327_13),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_12_s14.INIT=16'hA300;
  LUT4 mp_hi_11_s15 (
    .F(mp_hi_11_25),
    .I0(n381_2),
    .I1(dp_hi[11]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_11_s15.INIT=16'hAC00;
  LUT4 mp_hi_10_s15 (
    .F(mp_hi_10_25),
    .I0(n382_2),
    .I1(dp_hi[10]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_10_s15.INIT=16'hAC00;
  LUT4 mp_hi_9_s15 (
    .F(mp_hi_9_25),
    .I0(n383_2),
    .I1(dp_hi[9]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_9_s15.INIT=16'hAC00;
  LUT4 mp_hi_8_s15 (
    .F(mp_hi_8_25),
    .I0(n384_2),
    .I1(dp_hi[8]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_8_s15.INIT=16'hAC00;
  LUT4 mp_hi_7_s15 (
    .F(mp_hi_7_25),
    .I0(n385_2),
    .I1(dp_hi[7]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_7_s15.INIT=16'hAC00;
  LUT4 mp_hi_6_s15 (
    .F(mp_hi_6_25),
    .I0(n386_2),
    .I1(dp_hi[6]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_6_s15.INIT=16'hAC00;
  LUT4 mp_hi_5_s15 (
    .F(mp_hi_5_25),
    .I0(n387_2),
    .I1(dp_hi[5]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_5_s15.INIT=16'hAC00;
  LUT4 mp_hi_4_s15 (
    .F(mp_hi_4_25),
    .I0(n388_2),
    .I1(dp_hi[4]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_4_s15.INIT=16'hAC00;
  LUT4 mp_hi_3_s15 (
    .F(mp_hi_3_25),
    .I0(n389_2),
    .I1(dp_hi[3]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_3_s15.INIT=16'hAC00;
  LUT4 mp_hi_2_s15 (
    .F(mp_hi_2_25),
    .I0(n390_2),
    .I1(dp_hi[2]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mp_hi_2_s15.INIT=16'hAC00;
  LUT4 mr_21_s16 (
    .F(mr_21_26),
    .I0(n641_8),
    .I1(n619_11),
    .I2(mp_hi_15_19),
    .I3(mp_hi_15_20) 
);
defparam mr_21_s16.INIT=16'h5CCF;
  LUT4 mr_20_s14 (
    .F(mr_20_22),
    .I0(n642_2),
    .I1(n619_11),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_20_s14.INIT=16'hA300;
  LUT4 mr_19_s15 (
    .F(mr_19_25),
    .I0(n643_2),
    .I1(dr[19]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_19_s15.INIT=16'hAC00;
  LUT4 mr_18_s15 (
    .F(mr_18_25),
    .I0(n644_2),
    .I1(dr[18]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_18_s15.INIT=16'hAC00;
  LUT4 mr_17_s15 (
    .F(mr_17_25),
    .I0(n645_2),
    .I1(dr[17]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_17_s15.INIT=16'hAC00;
  LUT4 mr_16_s15 (
    .F(mr_16_25),
    .I0(n646_2),
    .I1(dr[16]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_16_s15.INIT=16'hAC00;
  LUT4 mr_15_s15 (
    .F(mr_15_25),
    .I0(n647_2),
    .I1(dr[15]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_15_s15.INIT=16'hAC00;
  LUT4 mr_14_s15 (
    .F(mr_14_25),
    .I0(n648_2),
    .I1(dr[14]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_14_s15.INIT=16'hAC00;
  LUT4 mr_13_s15 (
    .F(mr_13_25),
    .I0(n649_2),
    .I1(dr[13]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_13_s15.INIT=16'hAC00;
  LUT4 mr_12_s15 (
    .F(mr_12_25),
    .I0(n650_2),
    .I1(dr[12]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_12_s15.INIT=16'hAC00;
  LUT4 mr_11_s15 (
    .F(mr_11_25),
    .I0(n651_2),
    .I1(dr[11]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_11_s15.INIT=16'hAC00;
  LUT4 mr_10_s15 (
    .F(mr_10_25),
    .I0(n652_2),
    .I1(dr[10]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_10_s15.INIT=16'hAC00;
  LUT4 mr_9_s15 (
    .F(mr_9_25),
    .I0(n653_2),
    .I1(dr[9]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_9_s15.INIT=16'hAC00;
  LUT4 mr_8_s15 (
    .F(mr_8_25),
    .I0(n654_2),
    .I1(dr[8]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_8_s15.INIT=16'hAC00;
  LUT4 mr_7_s15 (
    .F(mr_7_25),
    .I0(n655_2),
    .I1(dr[7]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_7_s15.INIT=16'hAC00;
  LUT4 mr_6_s15 (
    .F(mr_6_25),
    .I0(n656_2),
    .I1(dr[6]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_6_s15.INIT=16'hAC00;
  LUT4 mr_5_s15 (
    .F(mr_5_25),
    .I0(n657_2),
    .I1(dr[5]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_5_s15.INIT=16'hAC00;
  LUT4 mr_4_s15 (
    .F(mr_4_25),
    .I0(n658_2),
    .I1(dr[4]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_4_s15.INIT=16'hAC00;
  LUT4 mr_3_s15 (
    .F(mr_3_25),
    .I0(n659_2),
    .I1(dr[3]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_3_s15.INIT=16'hAC00;
  LUT4 mr_2_s15 (
    .F(mr_2_25),
    .I0(n660_2),
    .I1(dr[2]),
    .I2(mp_hi_15_20),
    .I3(mp_hi_15_19) 
);
defparam mr_2_s15.INIT=16'hAC00;
  LUT2 n839_s62 (
    .F(n839_96),
    .I0(eng[0]),
    .I1(eng[1]) 
);
defparam n839_s62.INIT=4'h1;
  LUT2 n839_s64 (
    .F(n839_98),
    .I0(eng_95[0]),
    .I1(eng_95[1]) 
);
defparam n839_s64.INIT=4'h1;
  LUT2 n839_s66 (
    .F(n839_100),
    .I0(eng_96[0]),
    .I1(eng_96[1]) 
);
defparam n839_s66.INIT=4'h1;
  LUT2 n839_s68 (
    .F(n839_102),
    .I0(eng_97[0]),
    .I1(eng_97[1]) 
);
defparam n839_s68.INIT=4'h1;
  LUT2 n839_s72 (
    .F(n839_106),
    .I0(eng_98[0]),
    .I1(eng_98[1]) 
);
defparam n839_s72.INIT=4'h1;
  LUT2 n839_s74 (
    .F(n839_108),
    .I0(eng_99[0]),
    .I1(eng_99[1]) 
);
defparam n839_s74.INIT=4'h1;
  LUT2 n839_s76 (
    .F(n839_110),
    .I0(eng_100[0]),
    .I1(eng_100[1]) 
);
defparam n839_s76.INIT=4'h1;
  LUT2 n839_s80 (
    .F(n839_114),
    .I0(eng_101[0]),
    .I1(eng_101[1]) 
);
defparam n839_s80.INIT=4'h1;
  LUT2 n839_s82 (
    .F(n839_116),
    .I0(eng_102[0]),
    .I1(eng_102[1]) 
);
defparam n839_s82.INIT=4'h1;
  LUT2 n839_s84 (
    .F(n839_118),
    .I0(eng_103[0]),
    .I1(eng_103[1]) 
);
defparam n839_s84.INIT=4'h1;
  LUT2 n839_s86 (
    .F(n839_120),
    .I0(eng_104[0]),
    .I1(eng_104[1]) 
);
defparam n839_s86.INIT=4'h1;
  LUT2 n839_s88 (
    .F(n839_122),
    .I0(eng_105[0]),
    .I1(eng_105[1]) 
);
defparam n839_s88.INIT=4'h1;
  LUT2 n839_s92 (
    .F(n839_126),
    .I0(eng_106[0]),
    .I1(eng_106[1]) 
);
defparam n839_s92.INIT=4'h1;
  LUT4 n1081_s64 (
    .F(n1081_86),
    .I0(slot_3_11),
    .I1(state[2]),
    .I2(state[1]),
    .I3(state[4]) 
);
defparam n1081_s64.INIT=16'hFE3F;
  LUT2 n1081_s65 (
    .F(n1081_87),
    .I0(state[3]),
    .I1(state[0]) 
);
defparam n1081_s65.INIT=4'h4;
  LUT2 n1083_s51 (
    .F(n1083_79),
    .I0(state[0]),
    .I1(state[1]) 
);
defparam n1083_s51.INIT=4'h6;
  LUT3 n1084_s65 (
    .F(n1084_89),
    .I0(state[1]),
    .I1(state[2]),
    .I2(state[3]) 
);
defparam n1084_s65.INIT=8'h01;
  LUT2 n1178_s48 (
    .F(n1178_60),
    .I0(state[3]),
    .I1(state[4]) 
);
defparam n1178_s48.INIT=4'h1;
  LUT3 n1178_s49 (
    .F(n1178_61),
    .I0(xe[11]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1178_s49.INIT=8'hD0;
  LUT3 n1179_s48 (
    .F(n1179_60),
    .I0(xe[10]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1179_s48.INIT=8'hD0;
  LUT3 n1180_s48 (
    .F(n1180_60),
    .I0(xe[9]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1180_s48.INIT=8'hD0;
  LUT3 n1181_s48 (
    .F(n1181_60),
    .I0(xe[8]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1181_s48.INIT=8'hD0;
  LUT3 n1182_s48 (
    .F(n1182_60),
    .I0(xe[7]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1182_s48.INIT=8'hD0;
  LUT3 n1183_s48 (
    .F(n1183_60),
    .I0(xe[6]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1183_s48.INIT=8'hD0;
  LUT3 n1184_s48 (
    .F(n1184_60),
    .I0(xe[5]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1184_s48.INIT=8'hD0;
  LUT3 n1185_s48 (
    .F(n1185_60),
    .I0(xe[4]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1185_s48.INIT=8'hD0;
  LUT3 n1186_s48 (
    .F(n1186_60),
    .I0(xe[3]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1186_s48.INIT=8'hD0;
  LUT3 n1187_s48 (
    .F(n1187_60),
    .I0(xe[2]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1187_s48.INIT=8'hD0;
  LUT3 n1188_s48 (
    .F(n1188_60),
    .I0(xe[1]),
    .I1(xe[24]),
    .I2(n1178_62) 
);
defparam n1188_s48.INIT=8'hD0;
  LUT4 n1189_s48 (
    .F(n1189_60),
    .I0(xe[24]),
    .I1(xe[0]),
    .I2(n1189_61),
    .I3(missing_r) 
);
defparam n1189_s48.INIT=16'h00BF;
  LUT3 n1190_s40 (
    .F(n1190_44),
    .I0(ptr0[13]),
    .I1(n1191_44),
    .I2(ptr0[14]) 
);
defparam n1190_s40.INIT=8'h78;
  LUT2 n1191_s40 (
    .F(n1191_44),
    .I0(ptr0[12]),
    .I1(n1192_44) 
);
defparam n1191_s40.INIT=4'h8;
  LUT2 n1192_s40 (
    .F(n1192_44),
    .I0(ptr0[11]),
    .I1(n1193_44) 
);
defparam n1192_s40.INIT=4'h8;
  LUT2 n1193_s40 (
    .F(n1193_44),
    .I0(ptr0[10]),
    .I1(n1194_44) 
);
defparam n1193_s40.INIT=4'h8;
  LUT2 n1194_s40 (
    .F(n1194_44),
    .I0(ptr0[9]),
    .I1(n1195_44) 
);
defparam n1194_s40.INIT=4'h8;
  LUT2 n1195_s40 (
    .F(n1195_44),
    .I0(ptr0[8]),
    .I1(n1196_44) 
);
defparam n1195_s40.INIT=4'h8;
  LUT2 n1196_s40 (
    .F(n1196_44),
    .I0(ptr0[7]),
    .I1(n1197_44) 
);
defparam n1196_s40.INIT=4'h8;
  LUT2 n1197_s40 (
    .F(n1197_44),
    .I0(ptr0[6]),
    .I1(n1243_46) 
);
defparam n1197_s40.INIT=4'h8;
  LUT4 n1199_s40 (
    .F(n1199_44),
    .I0(note_r[6]),
    .I1(note_r[5]),
    .I2(n1199_46),
    .I3(n1199_47) 
);
defparam n1199_s40.INIT=16'h000E;
  LUT3 n1205_s41 (
    .F(n1205_45),
    .I0(ptr1[13]),
    .I1(n1206_45),
    .I2(ptr1[14]) 
);
defparam n1205_s41.INIT=8'h78;
  LUT3 n1206_s40 (
    .F(n1206_44),
    .I0(base0[12]),
    .I1(n1205_46),
    .I2(base0[13]) 
);
defparam n1206_s40.INIT=8'h78;
  LUT2 n1206_s41 (
    .F(n1206_45),
    .I0(ptr1[12]),
    .I1(n1207_45) 
);
defparam n1206_s41.INIT=4'h8;
  LUT2 n1207_s41 (
    .F(n1207_45),
    .I0(ptr1[11]),
    .I1(n1208_45) 
);
defparam n1207_s41.INIT=4'h8;
  LUT3 n1208_s40 (
    .F(n1208_44),
    .I0(base0[10]),
    .I1(n1208_48),
    .I2(base0[11]) 
);
defparam n1208_s40.INIT=8'h78;
  LUT2 n1208_s41 (
    .F(n1208_45),
    .I0(ptr1[10]),
    .I1(n1209_45) 
);
defparam n1208_s41.INIT=4'h8;
  LUT2 n1209_s41 (
    .F(n1209_45),
    .I0(ptr1[9]),
    .I1(n1210_45) 
);
defparam n1209_s41.INIT=4'h8;
  LUT2 n1210_s41 (
    .F(n1210_45),
    .I0(ptr1[8]),
    .I1(n1211_45) 
);
defparam n1210_s41.INIT=4'h8;
  LUT2 n1211_s40 (
    .F(n1211_44),
    .I0(base0[8]),
    .I1(n1211_46) 
);
defparam n1211_s40.INIT=4'h6;
  LUT2 n1211_s41 (
    .F(n1211_45),
    .I0(ptr1[7]),
    .I1(n1212_45) 
);
defparam n1211_s41.INIT=4'h8;
  LUT4 n1212_s40 (
    .F(n1212_44),
    .I0(nv_index[2]),
    .I1(n1200_49),
    .I2(n1199_44),
    .I3(nv_index[3]) 
);
defparam n1212_s40.INIT=16'h619E;
  LUT2 n1212_s41 (
    .F(n1212_45),
    .I0(ptr1[6]),
    .I1(n1213_47) 
);
defparam n1212_s41.INIT=4'h8;
  LUT3 n1213_s40 (
    .F(n1213_44),
    .I0(n1200_49),
    .I1(n1199_44),
    .I2(nv_index[2]) 
);
defparam n1213_s40.INIT=8'hD2;
  LUT2 n1214_s40 (
    .F(n1214_44),
    .I0(n1200_49),
    .I1(n1199_44) 
);
defparam n1214_s40.INIT=4'h6;
  LUT3 n1220_s41 (
    .F(n1220_45),
    .I0(ptr2[13]),
    .I1(n1221_45),
    .I2(ptr2[14]) 
);
defparam n1220_s41.INIT=8'h78;
  LUT3 n1221_s40 (
    .F(n1221_44),
    .I0(base0[12]),
    .I1(n1220_50),
    .I2(base0[13]) 
);
defparam n1221_s40.INIT=8'h78;
  LUT2 n1221_s41 (
    .F(n1221_45),
    .I0(ptr2[12]),
    .I1(n1222_45) 
);
defparam n1221_s41.INIT=4'h8;
  LUT2 n1222_s40 (
    .F(n1222_44),
    .I0(base0[12]),
    .I1(n1220_50) 
);
defparam n1222_s40.INIT=4'h6;
  LUT2 n1222_s41 (
    .F(n1222_45),
    .I0(ptr2[11]),
    .I1(n1223_45) 
);
defparam n1222_s41.INIT=4'h8;
  LUT2 n1223_s41 (
    .F(n1223_45),
    .I0(ptr2[10]),
    .I1(n1224_45) 
);
defparam n1223_s41.INIT=4'h8;
  LUT2 n1224_s41 (
    .F(n1224_45),
    .I0(ptr2[9]),
    .I1(n1225_45) 
);
defparam n1224_s41.INIT=4'h8;
  LUT2 n1225_s40 (
    .F(n1225_44),
    .I0(base0[9]),
    .I1(n1225_46) 
);
defparam n1225_s40.INIT=4'h6;
  LUT2 n1225_s41 (
    .F(n1225_45),
    .I0(ptr2[8]),
    .I1(n1226_45) 
);
defparam n1225_s41.INIT=4'h8;
  LUT4 n1226_s40 (
    .F(n1226_44),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(vel_r[6]),
    .I3(base0[8]) 
);
defparam n1226_s40.INIT=16'hFE01;
  LUT2 n1226_s41 (
    .F(n1226_45),
    .I0(ptr2[7]),
    .I1(n1227_45) 
);
defparam n1226_s41.INIT=4'h8;
  LUT4 n1227_s40 (
    .F(n1227_44),
    .I0(n1200_49),
    .I1(n1199_44),
    .I2(nv_index[2]),
    .I3(nv_index[3]) 
);
defparam n1227_s40.INIT=16'h926D;
  LUT2 n1227_s41 (
    .F(n1227_45),
    .I0(ptr2[6]),
    .I1(n1228_47) 
);
defparam n1227_s41.INIT=4'h8;
  LUT3 n1228_s40 (
    .F(n1228_44),
    .I0(n1200_49),
    .I1(n1199_44),
    .I2(nv_index[2]) 
);
defparam n1228_s40.INIT=8'hB4;
  LUT2 n1229_s40 (
    .F(n1229_44),
    .I0(ptr1[4]),
    .I1(n1245_46) 
);
defparam n1229_s40.INIT=4'h8;
  LUT3 n1235_s41 (
    .F(n1235_45),
    .I0(ptr3[13]),
    .I1(n1236_45),
    .I2(ptr3[14]) 
);
defparam n1235_s41.INIT=8'h78;
  LUT3 n1236_s40 (
    .F(n1236_44),
    .I0(base0[12]),
    .I1(n1235_46),
    .I2(base0[13]) 
);
defparam n1236_s40.INIT=8'h78;
  LUT2 n1236_s41 (
    .F(n1236_45),
    .I0(ptr3[12]),
    .I1(n1237_45) 
);
defparam n1236_s41.INIT=4'h8;
  LUT2 n1237_s40 (
    .F(n1237_44),
    .I0(base0[12]),
    .I1(n1235_46) 
);
defparam n1237_s40.INIT=4'h6;
  LUT2 n1237_s41 (
    .F(n1237_45),
    .I0(ptr3[11]),
    .I1(n1238_45) 
);
defparam n1237_s41.INIT=4'h8;
  LUT2 n1238_s40 (
    .F(n1238_44),
    .I0(base0[11]),
    .I1(n1238_46) 
);
defparam n1238_s40.INIT=4'h6;
  LUT2 n1238_s41 (
    .F(n1238_45),
    .I0(ptr3[10]),
    .I1(n1239_45) 
);
defparam n1238_s41.INIT=4'h8;
  LUT2 n1239_s40 (
    .F(n1239_44),
    .I0(base0[10]),
    .I1(n1239_46) 
);
defparam n1239_s40.INIT=4'h6;
  LUT2 n1239_s41 (
    .F(n1239_45),
    .I0(ptr3[9]),
    .I1(n1240_45) 
);
defparam n1239_s41.INIT=4'h8;
  LUT2 n1240_s40 (
    .F(n1240_44),
    .I0(base0[9]),
    .I1(n1240_46) 
);
defparam n1240_s40.INIT=4'h6;
  LUT2 n1240_s41 (
    .F(n1240_45),
    .I0(ptr3[8]),
    .I1(n1241_45) 
);
defparam n1240_s41.INIT=4'h8;
  LUT2 n1241_s40 (
    .F(n1241_44),
    .I0(base0[8]),
    .I1(n1241_48) 
);
defparam n1241_s40.INIT=4'h6;
  LUT2 n1241_s41 (
    .F(n1241_45),
    .I0(ptr3[7]),
    .I1(n1242_45) 
);
defparam n1241_s41.INIT=4'h8;
  LUT2 n1242_s41 (
    .F(n1242_45),
    .I0(ptr3[6]),
    .I1(n1243_46) 
);
defparam n1242_s41.INIT=4'h8;
  LUT2 n1244_s40 (
    .F(n1244_44),
    .I0(ptr0[4]),
    .I1(n1245_46) 
);
defparam n1244_s40.INIT=4'h8;
  LUT2 n1288_s4 (
    .F(n1288_8),
    .I0(state[0]),
    .I1(state[1]) 
);
defparam n1288_s4.INIT=4'h8;
  LUT4 n1428_s7 (
    .F(n1428_11),
    .I0(state[0]),
    .I1(state[2]),
    .I2(state[3]),
    .I3(state[1]) 
);
defparam n1428_s7.INIT=16'h0100;
  LUT3 slot_3_s6 (
    .F(slot_3_11),
    .I0(point[0]),
    .I1(point[4]),
    .I2(slot_3_12) 
);
defparam slot_3_s6.INIT=8'h40;
  LUT2 ld_addr_8_s4 (
    .F(ld_addr_8_6),
    .I0(state[4]),
    .I1(state[3]) 
);
defparam ld_addr_8_s4.INIT=4'h4;
  LUT4 ld_addr_8_s5 (
    .F(ld_addr_8_7),
    .I0(state[1]),
    .I1(state[2]),
    .I2(state[4]),
    .I3(n1081_87) 
);
defparam ld_addr_8_s5.INIT=16'h1800;
  LUT4 level_addr_14_s6 (
    .F(level_addr_14_10),
    .I0(ptr1[14]),
    .I1(n1324_9),
    .I2(ptr3[14]),
    .I3(n1300_8) 
);
defparam level_addr_14_s6.INIT=16'h0777;
  LUT4 level_addr_14_s7 (
    .F(level_addr_14_11),
    .I0(n1312_8),
    .I1(ptr2[14]),
    .I2(level_addr_14_14),
    .I3(ptr0[14]) 
);
defparam level_addr_14_s7.INIT=16'h7077;
  LUT4 level_addr_13_s6 (
    .F(level_addr_13_10),
    .I0(ptr1[13]),
    .I1(n1324_9),
    .I2(ptr3[13]),
    .I3(n1300_8) 
);
defparam level_addr_13_s6.INIT=16'h0777;
  LUT4 level_addr_13_s7 (
    .F(level_addr_13_11),
    .I0(n1312_8),
    .I1(ptr2[13]),
    .I2(level_addr_14_14),
    .I3(ptr0[13]) 
);
defparam level_addr_13_s7.INIT=16'h7077;
  LUT4 level_addr_12_s6 (
    .F(level_addr_12_10),
    .I0(ptr1[12]),
    .I1(n1324_9),
    .I2(ptr3[12]),
    .I3(n1300_8) 
);
defparam level_addr_12_s6.INIT=16'h0777;
  LUT4 level_addr_12_s7 (
    .F(level_addr_12_11),
    .I0(n1312_8),
    .I1(ptr2[12]),
    .I2(level_addr_14_14),
    .I3(ptr0[12]) 
);
defparam level_addr_12_s7.INIT=16'h7077;
  LUT4 level_addr_11_s6 (
    .F(level_addr_11_10),
    .I0(ptr1[11]),
    .I1(n1324_9),
    .I2(ptr3[11]),
    .I3(n1300_8) 
);
defparam level_addr_11_s6.INIT=16'h0777;
  LUT4 level_addr_11_s7 (
    .F(level_addr_11_11),
    .I0(n1312_8),
    .I1(ptr2[11]),
    .I2(level_addr_14_14),
    .I3(ptr0[11]) 
);
defparam level_addr_11_s7.INIT=16'h7077;
  LUT4 level_addr_10_s6 (
    .F(level_addr_10_10),
    .I0(ptr1[10]),
    .I1(n1324_9),
    .I2(ptr3[10]),
    .I3(n1300_8) 
);
defparam level_addr_10_s6.INIT=16'h0777;
  LUT4 level_addr_10_s7 (
    .F(level_addr_10_11),
    .I0(n1312_8),
    .I1(ptr2[10]),
    .I2(level_addr_14_14),
    .I3(ptr0[10]) 
);
defparam level_addr_10_s7.INIT=16'h7077;
  LUT4 level_addr_9_s7 (
    .F(level_addr_9_11),
    .I0(ptr1[9]),
    .I1(n1324_9),
    .I2(ptr3[9]),
    .I3(n1300_8) 
);
defparam level_addr_9_s7.INIT=16'h0777;
  LUT4 level_addr_9_s8 (
    .F(level_addr_9_12),
    .I0(n1312_8),
    .I1(ptr2[9]),
    .I2(level_addr_14_14),
    .I3(ptr0[9]) 
);
defparam level_addr_9_s8.INIT=16'h7077;
  LUT4 level_addr_8_s7 (
    .F(level_addr_8_11),
    .I0(ptr1[8]),
    .I1(n1324_9),
    .I2(ptr3[8]),
    .I3(n1300_8) 
);
defparam level_addr_8_s7.INIT=16'h0777;
  LUT4 level_addr_8_s8 (
    .F(level_addr_8_12),
    .I0(n1312_8),
    .I1(ptr2[8]),
    .I2(level_addr_14_14),
    .I3(ptr0[8]) 
);
defparam level_addr_8_s8.INIT=16'h7077;
  LUT4 level_addr_7_s7 (
    .F(level_addr_7_11),
    .I0(ptr1[7]),
    .I1(n1324_9),
    .I2(ptr3[7]),
    .I3(n1300_8) 
);
defparam level_addr_7_s7.INIT=16'h0777;
  LUT4 level_addr_7_s8 (
    .F(level_addr_7_12),
    .I0(n1312_8),
    .I1(ptr2[7]),
    .I2(level_addr_14_14),
    .I3(ptr0[7]) 
);
defparam level_addr_7_s8.INIT=16'h7077;
  LUT4 level_addr_6_s7 (
    .F(level_addr_6_11),
    .I0(ptr1[6]),
    .I1(n1324_9),
    .I2(ptr3[6]),
    .I3(n1300_8) 
);
defparam level_addr_6_s7.INIT=16'h0777;
  LUT4 level_addr_6_s8 (
    .F(level_addr_6_12),
    .I0(n1312_8),
    .I1(ptr2[6]),
    .I2(level_addr_14_14),
    .I3(ptr0[6]) 
);
defparam level_addr_6_s8.INIT=16'h7077;
  LUT4 level_addr_5_s7 (
    .F(level_addr_5_11),
    .I0(ptr1[5]),
    .I1(n1324_9),
    .I2(ptr0[5]),
    .I3(n1300_8) 
);
defparam level_addr_5_s7.INIT=16'h0777;
  LUT4 level_addr_5_s8 (
    .F(level_addr_5_12),
    .I0(n1312_8),
    .I1(ptr2[5]),
    .I2(level_addr_14_14),
    .I3(ptr0[5]) 
);
defparam level_addr_5_s8.INIT=16'h7077;
  LUT4 level_addr_4_s7 (
    .F(level_addr_4_11),
    .I0(ptr1[4]),
    .I1(n1324_9),
    .I2(ptr0[4]),
    .I3(n1300_8) 
);
defparam level_addr_4_s7.INIT=16'h0777;
  LUT4 level_addr_4_s8 (
    .F(level_addr_4_12),
    .I0(n1312_8),
    .I1(ptr1[4]),
    .I2(level_addr_14_14),
    .I3(ptr0[4]) 
);
defparam level_addr_4_s8.INIT=16'h7077;
  LUT4 level_addr_3_s7 (
    .F(level_addr_3_11),
    .I0(ptr0[3]),
    .I1(n1324_9),
    .I2(ptr0[3]),
    .I3(n1300_8) 
);
defparam level_addr_3_s7.INIT=16'h0777;
  LUT4 level_addr_3_s8 (
    .F(level_addr_3_12),
    .I0(n1312_8),
    .I1(ptr0[3]),
    .I2(level_addr_14_14),
    .I3(ptr0[3]) 
);
defparam level_addr_3_s8.INIT=16'h7077;
  LUT4 level_addr_2_s7 (
    .F(level_addr_2_11),
    .I0(ptr0[2]),
    .I1(n1324_9),
    .I2(ptr0[2]),
    .I3(n1300_8) 
);
defparam level_addr_2_s7.INIT=16'h0777;
  LUT4 level_addr_2_s8 (
    .F(level_addr_2_12),
    .I0(n1312_8),
    .I1(ptr0[2]),
    .I2(level_addr_14_14),
    .I3(ptr0[2]) 
);
defparam level_addr_2_s8.INIT=16'h7077;
  LUT4 level_addr_1_s7 (
    .F(level_addr_1_11),
    .I0(ptr0[1]),
    .I1(n1324_9),
    .I2(ptr0[1]),
    .I3(n1300_8) 
);
defparam level_addr_1_s7.INIT=16'h0777;
  LUT4 level_addr_1_s8 (
    .F(level_addr_1_12),
    .I0(n1312_8),
    .I1(ptr0[1]),
    .I2(level_addr_14_14),
    .I3(ptr0[1]) 
);
defparam level_addr_1_s8.INIT=16'h7077;
  LUT4 level_addr_0_s7 (
    .F(level_addr_0_11),
    .I0(ptr0[0]),
    .I1(n1324_9),
    .I2(ptr0[0]),
    .I3(n1300_8) 
);
defparam level_addr_0_s7.INIT=16'h0777;
  LUT4 level_addr_0_s8 (
    .F(level_addr_0_12),
    .I0(n1312_8),
    .I1(ptr0[0]),
    .I2(level_addr_14_14),
    .I3(ptr0[0]) 
);
defparam level_addr_0_s8.INIT=16'h7077;
  LUT4 n1080_s59 (
    .F(n1080_77),
    .I0(n1084_91),
    .I1(state[0]),
    .I2(state[4]),
    .I3(n1084_89) 
);
defparam n1080_s59.INIT=16'hB000;
  LUT3 n1255_s42 (
    .F(n1255_48),
    .I0(slot[0]),
    .I1(slot[1]),
    .I2(slot[2]) 
);
defparam n1255_s42.INIT=8'h80;
  LUT2 n1252_s41 (
    .F(n1252_47),
    .I0(point[0]),
    .I1(point[1]) 
);
defparam n1252_s41.INIT=4'h8;
  LUT4 n1250_s41 (
    .F(n1250_47),
    .I0(slot_3_12),
    .I1(n1250_48),
    .I2(point[0]),
    .I3(point[4]) 
);
defparam n1250_s41.INIT=16'hCA3F;
  LUT3 n1246_s41 (
    .F(n1246_47),
    .I0(ptr0[2]),
    .I1(ptr0[1]),
    .I2(ptr0[0]) 
);
defparam n1246_s41.INIT=8'h80;
  LUT3 mp_hi_15_s11 (
    .F(mp_hi_15_19),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(note_r[0]) 
);
defparam mp_hi_15_s11.INIT=8'h60;
  LUT3 mp_hi_15_s12 (
    .F(mp_hi_15_20),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(note_r[1]) 
);
defparam mp_hi_15_s12.INIT=8'h60;
  LUT4 n867_s3 (
    .F(n867_8),
    .I0(n867_9),
    .I1(n867_10),
    .I2(n867_11),
    .I3(n867_12) 
);
defparam n867_s3.INIT=16'h0777;
  LUT3 nv_index_2_s1 (
    .F(nv_index_2_5),
    .I0(vel_r[6]),
    .I1(note_r[3]),
    .I2(note_r[2]) 
);
defparam nv_index_2_s1.INIT=8'hB0;
  LUT4 nv_index_3_s1 (
    .F(nv_index_3_5),
    .I0(note_r[2]),
    .I1(note_r[6]),
    .I2(vel_r[6]),
    .I3(note_r[5]) 
);
defparam nv_index_3_s1.INIT=16'h007F;
  LUT4 nv_index_3_s2 (
    .F(nv_index_3_6),
    .I0(note_r[3]),
    .I1(note_r[2]),
    .I2(note_r[5]),
    .I3(note_r[6]) 
);
defparam nv_index_3_s2.INIT=16'hF100;
  LUT4 n974_s5 (
    .F(n974_8),
    .I0(lv_a[8]),
    .I1(lv_a[9]),
    .I2(lv_a[10]),
    .I3(lv_a[11]) 
);
defparam n974_s5.INIT=16'h8000;
  LUT4 n974_s6 (
    .F(n974_9),
    .I0(lv_a[4]),
    .I1(lv_a[5]),
    .I2(lv_a[6]),
    .I3(lv_a[7]) 
);
defparam n974_s6.INIT=16'h8000;
  LUT4 n974_s7 (
    .F(n974_10),
    .I0(lv_a[0]),
    .I1(lv_a[1]),
    .I2(lv_a[2]),
    .I3(lv_a[3]) 
);
defparam n974_s7.INIT=16'h8000;
  LUT4 n974_s8 (
    .F(n974_11),
    .I0(lv_c[8]),
    .I1(lv_c[9]),
    .I2(lv_c[10]),
    .I3(lv_c[11]) 
);
defparam n974_s8.INIT=16'h8000;
  LUT4 n974_s9 (
    .F(n974_12),
    .I0(lv_c[4]),
    .I1(lv_c[5]),
    .I2(lv_c[6]),
    .I3(lv_c[7]) 
);
defparam n974_s9.INIT=16'h8000;
  LUT4 n974_s10 (
    .F(n974_13),
    .I0(lv_c[0]),
    .I1(lv_c[1]),
    .I2(lv_c[2]),
    .I3(lv_c[3]) 
);
defparam n974_s10.INIT=16'h8000;
  LUT4 n974_s11 (
    .F(n974_14),
    .I0(lv_d[8]),
    .I1(lv_d[9]),
    .I2(lv_d[10]),
    .I3(lv_d[11]) 
);
defparam n974_s11.INIT=16'h8000;
  LUT4 n974_s12 (
    .F(n974_15),
    .I0(lv_d[4]),
    .I1(lv_d[5]),
    .I2(lv_d[6]),
    .I3(lv_d[7]) 
);
defparam n974_s12.INIT=16'h8000;
  LUT4 n974_s13 (
    .F(n974_16),
    .I0(lv_d[0]),
    .I1(lv_d[1]),
    .I2(lv_d[2]),
    .I3(lv_d[3]) 
);
defparam n974_s13.INIT=16'h8000;
  LUT4 n974_s14 (
    .F(n974_17),
    .I0(lv_b[8]),
    .I1(lv_b[9]),
    .I2(lv_b[10]),
    .I3(lv_b[11]) 
);
defparam n974_s14.INIT=16'h8000;
  LUT4 n974_s15 (
    .F(n974_18),
    .I0(lv_b[4]),
    .I1(lv_b[5]),
    .I2(lv_b[6]),
    .I3(lv_b[7]) 
);
defparam n974_s15.INIT=16'h8000;
  LUT4 n974_s16 (
    .F(n974_19),
    .I0(lv_b[0]),
    .I1(lv_b[1]),
    .I2(lv_b[2]),
    .I3(lv_b[3]) 
);
defparam n974_s16.INIT=16'h8000;
  LUT3 n1178_s50 (
    .F(n1178_62),
    .I0(n1189_61),
    .I1(xe[24]),
    .I2(missing_r) 
);
defparam n1178_s50.INIT=8'h0E;
  LUT4 n1189_s49 (
    .F(n1189_61),
    .I0(xe[12]),
    .I1(xe[13]),
    .I2(n1189_62),
    .I3(n1189_63) 
);
defparam n1189_s49.INIT=16'h0100;
  LUT4 n1199_s42 (
    .F(n1199_46),
    .I0(ratio_addr[8]),
    .I1(note_r[2]),
    .I2(vel_r[6]),
    .I3(note_r[3]) 
);
defparam n1199_s42.INIT=16'h5300;
  LUT4 n1199_s43 (
    .F(n1199_47),
    .I0(note_r[3]),
    .I1(note_r[2]),
    .I2(ratio_addr[8]),
    .I3(vel_r[6]) 
);
defparam n1199_s43.INIT=16'h00F4;
  LUT3 n1205_s42 (
    .F(n1205_46),
    .I0(base0[11]),
    .I1(base0[10]),
    .I2(n1208_48) 
);
defparam n1205_s42.INIT=8'h80;
  LUT4 n1211_s42 (
    .F(n1211_46),
    .I0(n1200_49),
    .I1(nv_index[2]),
    .I2(nv_index[3]),
    .I3(n1199_44) 
);
defparam n1211_s42.INIT=16'h799F;
  LUT4 n1225_s42 (
    .F(n1225_46),
    .I0(base0[8]),
    .I1(note_r[5]),
    .I2(note_r[6]),
    .I3(vel_r[6]) 
);
defparam n1225_s42.INIT=16'h0001;
  LUT2 n1235_s42 (
    .F(n1235_46),
    .I0(n1238_46),
    .I1(base0[11]) 
);
defparam n1235_s42.INIT=4'h4;
  LUT2 n1238_s42 (
    .F(n1238_46),
    .I0(base0[10]),
    .I1(n1239_46) 
);
defparam n1238_s42.INIT=4'h1;
  LUT2 n1239_s42 (
    .F(n1239_46),
    .I0(n1240_46),
    .I1(base0[9]) 
);
defparam n1239_s42.INIT=4'h4;
  LUT2 n1240_s42 (
    .F(n1240_46),
    .I0(base0[8]),
    .I1(n1241_48) 
);
defparam n1240_s42.INIT=4'h1;
  LUT3 slot_3_s7 (
    .F(slot_3_12),
    .I0(point[1]),
    .I1(point[3]),
    .I2(point[2]) 
);
defparam slot_3_s7.INIT=8'h10;
  LUT3 n1250_s42 (
    .F(n1250_48),
    .I0(point[1]),
    .I1(point[2]),
    .I2(point[3]) 
);
defparam n1250_s42.INIT=8'h80;
  LUT4 n867_s4 (
    .F(n867_9),
    .I0(n867_13),
    .I1(n867_14),
    .I2(n867_15),
    .I3(n867_16) 
);
defparam n867_s4.INIT=16'h8000;
  LUT4 n867_s5 (
    .F(n867_10),
    .I0(ratio_q[8]),
    .I1(ratio_q[9]),
    .I2(ratio_q[10]),
    .I3(ratio_q[11]) 
);
defparam n867_s5.INIT=16'h0001;
  LUT4 n867_s6 (
    .F(n867_11),
    .I0(n867_17),
    .I1(n867_18),
    .I2(n867_19),
    .I3(n867_20) 
);
defparam n867_s6.INIT=16'h8000;
  LUT4 n867_s7 (
    .F(n867_12),
    .I0(ratio_a[8]),
    .I1(ratio_a[9]),
    .I2(ratio_a[10]),
    .I3(ratio_a[11]) 
);
defparam n867_s7.INIT=16'h0001;
  LUT3 n1189_s50 (
    .F(n1189_62),
    .I0(n1189_64),
    .I1(n1189_65),
    .I2(n1189_66) 
);
defparam n1189_s50.INIT=8'h80;
  LUT4 n1189_s51 (
    .F(n1189_63),
    .I0(xe[14]),
    .I1(xe[15]),
    .I2(xe[16]),
    .I3(xe[17]) 
);
defparam n1189_s51.INIT=16'h0001;
  LUT4 n867_s8 (
    .F(n867_13),
    .I0(ratio_q[12]),
    .I1(ratio_q[13]),
    .I2(ratio_q[14]),
    .I3(ratio_q[15]) 
);
defparam n867_s8.INIT=16'h0001;
  LUT4 n867_s9 (
    .F(n867_14),
    .I0(ratio_q[4]),
    .I1(ratio_q[5]),
    .I2(ratio_q[6]),
    .I3(ratio_q[7]) 
);
defparam n867_s9.INIT=16'h0001;
  LUT4 n867_s10 (
    .F(n867_15),
    .I0(ratio_q[16]),
    .I1(ratio_q[17]),
    .I2(ratio_q[18]),
    .I3(ratio_q[19]) 
);
defparam n867_s10.INIT=16'h0001;
  LUT4 n867_s11 (
    .F(n867_16),
    .I0(ratio_q[0]),
    .I1(ratio_q[1]),
    .I2(ratio_q[2]),
    .I3(ratio_q[3]) 
);
defparam n867_s11.INIT=16'h0001;
  LUT4 n867_s12 (
    .F(n867_17),
    .I0(ratio_a[16]),
    .I1(ratio_a[17]),
    .I2(ratio_a[18]),
    .I3(ratio_a[19]) 
);
defparam n867_s12.INIT=16'h0001;
  LUT4 n867_s13 (
    .F(n867_18),
    .I0(ratio_a[0]),
    .I1(ratio_a[1]),
    .I2(ratio_a[2]),
    .I3(ratio_a[3]) 
);
defparam n867_s13.INIT=16'h0001;
  LUT4 n867_s14 (
    .F(n867_19),
    .I0(ratio_a[4]),
    .I1(ratio_a[5]),
    .I2(ratio_a[6]),
    .I3(ratio_a[7]) 
);
defparam n867_s14.INIT=16'h0001;
  LUT4 n867_s15 (
    .F(n867_20),
    .I0(ratio_a[12]),
    .I1(ratio_a[13]),
    .I2(ratio_a[14]),
    .I3(ratio_a[15]) 
);
defparam n867_s15.INIT=16'h0001;
  LUT4 n1189_s52 (
    .F(n1189_64),
    .I0(xe[7]),
    .I1(xe[8]),
    .I2(xe[9]),
    .I3(xe[10]) 
);
defparam n1189_s52.INIT=16'h8000;
  LUT4 n1189_s53 (
    .F(n1189_65),
    .I0(xe[3]),
    .I1(xe[4]),
    .I2(xe[5]),
    .I3(xe[6]) 
);
defparam n1189_s53.INIT=16'h8000;
  LUT3 n1189_s54 (
    .F(n1189_66),
    .I0(xe[1]),
    .I1(xe[2]),
    .I2(xe[11]) 
);
defparam n1189_s54.INIT=8'h80;
  LUT4 n1083_s52 (
    .F(n1083_81),
    .I0(point_4_10),
    .I1(state[4]),
    .I2(state[0]),
    .I3(state[1]) 
);
defparam n1083_s52.INIT=16'h0BB0;
  LUT3 n1208_s43 (
    .F(n1208_48),
    .I0(base0[8]),
    .I1(n1211_46),
    .I2(base0[9]) 
);
defparam n1208_s43.INIT=8'hB0;
  LUT3 n1210_s43 (
    .F(n1210_48),
    .I0(base0[9]),
    .I1(base0[8]),
    .I2(n1211_46) 
);
defparam n1210_s43.INIT=8'h9A;
  LUT4 n1245_s41 (
    .F(n1245_46),
    .I0(ptr0[3]),
    .I1(ptr0[2]),
    .I2(ptr0[1]),
    .I3(ptr0[0]) 
);
defparam n1245_s41.INIT=16'h8000;
  LUT4 slot_3_s8 (
    .F(slot_3_14),
    .I0(slot[3]),
    .I1(slot[0]),
    .I2(slot[1]),
    .I3(slot[2]) 
);
defparam slot_3_s8.INIT=16'h8000;
  LUT4 point_4_s4 (
    .F(point_4_10),
    .I0(state[1]),
    .I1(state[2]),
    .I2(state[3]),
    .I3(state[0]) 
);
defparam point_4_s4.INIT=16'h0100;
  LUT4 n1081_s67 (
    .F(n1081_90),
    .I0(n1081_86),
    .I1(state[3]),
    .I2(state[0]),
    .I3(n1081_92) 
);
defparam n1081_s67.INIT=16'hFF10;
  LUT4 n1207_s42 (
    .F(n1207_47),
    .I0(base0[12]),
    .I1(base0[11]),
    .I2(base0[10]),
    .I3(n1208_48) 
);
defparam n1207_s42.INIT=16'h6AAA;
  LUT4 n1235_s43 (
    .F(n1235_48),
    .I0(base0[13]),
    .I1(base0[12]),
    .I2(n1235_46),
    .I3(base0[14]) 
);
defparam n1235_s43.INIT=16'h7F80;
  LUT4 n1220_s43 (
    .F(n1220_48),
    .I0(base0[13]),
    .I1(base0[12]),
    .I2(n1220_50),
    .I3(base0[14]) 
);
defparam n1220_s43.INIT=16'h7F80;
  LUT4 n1205_s44 (
    .F(n1205_49),
    .I0(n1205_46),
    .I1(base0[13]),
    .I2(base0[12]),
    .I3(base0[14]) 
);
defparam n1205_s44.INIT=16'h7F80;
  LUT4 n1220_s44 (
    .F(n1220_50),
    .I0(base0[9]),
    .I1(n1225_46),
    .I2(base0[10]),
    .I3(base0[11]) 
);
defparam n1220_s44.INIT=16'hB000;
  LUT3 n1224_s42 (
    .F(n1224_47),
    .I0(base0[10]),
    .I1(base0[9]),
    .I2(n1225_46) 
);
defparam n1224_s42.INIT=8'h9A;
  LUT4 n1223_s43 (
    .F(n1223_48),
    .I0(base0[9]),
    .I1(n1225_46),
    .I2(base0[10]),
    .I3(base0[11]) 
);
defparam n1223_s43.INIT=16'h4FB0;
  LUT4 n1134_s45 (
    .F(n1134_63),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1134_s45.INIT=16'h0800;
  LUT4 n1133_s45 (
    .F(n1133_63),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1133_s45.INIT=16'h8000;
  LUT4 n1136_s45 (
    .F(n1136_63),
    .I0(voice_r_0[1]),
    .I1(voice_r_0[2]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1136_s45.INIT=16'h0400;
  LUT4 n1135_s45 (
    .F(n1135_63),
    .I0(voice_r_0[1]),
    .I1(voice_r_0[2]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1135_s45.INIT=16'h4000;
  LUT4 n1138_s45 (
    .F(n1138_63),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1138_s45.INIT=16'h0400;
  LUT4 n1137_s45 (
    .F(n1137_63),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1137_s45.INIT=16'h4000;
  LUT4 n1145_s45 (
    .F(n1145_63),
    .I0(voice_r[3]),
    .I1(voice_r_0[0]),
    .I2(voice_r_0[2]),
    .I3(voice_r_0[1]) 
);
defparam n1145_s45.INIT=16'h0400;
  LUT4 n1143_s45 (
    .F(n1143_63),
    .I0(voice_r[3]),
    .I1(voice_r_0[0]),
    .I2(voice_r_0[1]),
    .I3(voice_r_0[2]) 
);
defparam n1143_s45.INIT=16'h0400;
  LUT4 n1141_s45 (
    .F(n1141_63),
    .I0(voice_r[3]),
    .I1(voice_r_0[0]),
    .I2(voice_r_0[2]),
    .I3(voice_r_0[1]) 
);
defparam n1141_s45.INIT=16'h4000;
  LUT4 n1146_s46 (
    .F(n1146_64),
    .I0(voice_r_0[0]),
    .I1(voice_r[3]),
    .I2(voice_r_0[2]),
    .I3(voice_r_0[1]) 
);
defparam n1146_s46.INIT=16'h0100;
  LUT4 n1144_s46 (
    .F(n1144_64),
    .I0(voice_r_0[0]),
    .I1(voice_r[3]),
    .I2(voice_r_0[1]),
    .I3(voice_r_0[2]) 
);
defparam n1144_s46.INIT=16'h0100;
  LUT4 n1142_s46 (
    .F(n1142_64),
    .I0(voice_r_0[0]),
    .I1(voice_r[3]),
    .I2(voice_r_0[2]),
    .I3(voice_r_0[1]) 
);
defparam n1142_s46.INIT=16'h1000;
  LUT4 n1148_s48 (
    .F(n1148_66),
    .I0(voice_r_0[0]),
    .I1(voice_r[3]),
    .I2(voice_r_0[2]),
    .I3(voice_r_0[1]) 
);
defparam n1148_s48.INIT=16'h0001;
  LUT4 n1147_s46 (
    .F(n1147_64),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r[3]),
    .I3(voice_r_0[0]) 
);
defparam n1147_s46.INIT=16'h0100;
  LUT4 n1140_s46 (
    .F(n1140_64),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1140_s46.INIT=16'h0100;
  LUT4 n1139_s46 (
    .F(n1139_64),
    .I0(voice_r_0[2]),
    .I1(voice_r_0[1]),
    .I2(voice_r_0[0]),
    .I3(voice_r[3]) 
);
defparam n1139_s46.INIT=16'h1000;
  LUT4 n1200_s43 (
    .F(n1200_49),
    .I0(vel_r[6]),
    .I1(note_r[2]),
    .I2(note_r[5]),
    .I3(note_r[6]) 
);
defparam n1200_s43.INIT=16'h566A;
  LUT4 ratio_addr_6_s3 (
    .F(ratio_addr_6_7),
    .I0(note_r[2]),
    .I1(note_r[5]),
    .I2(note_r[6]),
    .I3(n1408_10) 
);
defparam ratio_addr_6_s3.INIT=16'hE800;
  LUT4 ratio_addr_4_s3 (
    .F(ratio_addr[4]),
    .I0(note_r[2]),
    .I1(note_r[5]),
    .I2(note_r[6]),
    .I3(n1408_10) 
);
defparam ratio_addr_4_s3.INIT=16'h17E8;
  LUT3 n1288_s6 (
    .F(n1288_11),
    .I0(state[2]),
    .I1(state[4]),
    .I2(state[3]) 
);
defparam n1288_s6.INIT=8'h20;
  LUT4 n1081_s68 (
    .F(n1081_92),
    .I0(n1288_8),
    .I1(state[2]),
    .I2(state[4]),
    .I3(state[3]) 
);
defparam n1081_s68.INIT=16'h0700;
  LUT4 n1084_s66 (
    .F(n1084_91),
    .I0(point[0]),
    .I1(point[4]),
    .I2(slot_3_12),
    .I3(slot_3_14) 
);
defparam n1084_s66.INIT=16'h4000;
  LUT3 level_addr_14_s9 (
    .F(level_addr_14_14),
    .I0(state[0]),
    .I1(state[1]),
    .I2(n1288_11) 
);
defparam level_addr_14_s9.INIT=8'h70;
  LUT4 n1082_s64 (
    .F(n1082_85),
    .I0(state[4]),
    .I1(state[2]),
    .I2(state[0]),
    .I3(state[1]) 
);
defparam n1082_s64.INIT=16'h1444;
  LUT3 n1288_s7 (
    .F(n1288_13),
    .I0(state[0]),
    .I1(state[1]),
    .I2(n1288_11) 
);
defparam n1288_s7.INIT=8'h80;
  LUT4 n173_s3 (
    .F(n173_9),
    .I0(n1200_49),
    .I1(note_r[5]),
    .I2(nv_index_2_5),
    .I3(note_r[6]) 
);
defparam n173_s3.INIT=16'h0280;
  LUT4 n174_s1 (
    .F(n174_6),
    .I0(n1200_49),
    .I1(note_r[5]),
    .I2(nv_index_2_5),
    .I3(note_r[6]) 
);
defparam n174_s1.INIT=16'hA96A;
  LUT3 n1117_s43 (
    .F(n1117_60),
    .I0(n1133_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1117_s43.INIT=8'h80;
  LUT3 n1118_s43 (
    .F(n1118_60),
    .I0(n1134_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1118_s43.INIT=8'h80;
  LUT3 n1119_s43 (
    .F(n1119_60),
    .I0(n1135_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1119_s43.INIT=8'h80;
  LUT3 n1120_s43 (
    .F(n1120_60),
    .I0(n1136_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1120_s43.INIT=8'h80;
  LUT3 n1121_s43 (
    .F(n1121_60),
    .I0(n1137_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1121_s43.INIT=8'h80;
  LUT3 n1122_s43 (
    .F(n1122_60),
    .I0(n1138_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1122_s43.INIT=8'h80;
  LUT3 n1123_s43 (
    .F(n1123_60),
    .I0(n1139_64),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1123_s43.INIT=8'h80;
  LUT3 n1124_s43 (
    .F(n1124_60),
    .I0(n1140_64),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1124_s43.INIT=8'h80;
  LUT3 n1125_s43 (
    .F(n1125_60),
    .I0(n1141_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1125_s43.INIT=8'h80;
  LUT3 n1126_s43 (
    .F(n1126_60),
    .I0(n1142_64),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1126_s43.INIT=8'h80;
  LUT3 n1127_s43 (
    .F(n1127_60),
    .I0(n1143_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1127_s43.INIT=8'h80;
  LUT3 n1128_s43 (
    .F(n1128_60),
    .I0(n1144_64),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1128_s43.INIT=8'h80;
  LUT3 n1129_s43 (
    .F(n1129_60),
    .I0(n1145_63),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1129_s43.INIT=8'h80;
  LUT3 n1130_s43 (
    .F(n1130_60),
    .I0(n1146_64),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1130_s43.INIT=8'h80;
  LUT3 n1131_s43 (
    .F(n1131_60),
    .I0(n1147_64),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1131_s43.INIT=8'h80;
  LUT3 n1132_s44 (
    .F(n1132_61),
    .I0(n1148_66),
    .I1(voice_r_0[4]),
    .I2(ld_addr_1_4) 
);
defparam n1132_s44.INIT=8'h80;
  LUT3 n1133_s46 (
    .F(n1133_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1133_63) 
);
defparam n1133_s46.INIT=8'h40;
  LUT3 n1134_s46 (
    .F(n1134_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1134_63) 
);
defparam n1134_s46.INIT=8'h40;
  LUT3 n1135_s46 (
    .F(n1135_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1135_63) 
);
defparam n1135_s46.INIT=8'h40;
  LUT3 n1136_s46 (
    .F(n1136_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1136_63) 
);
defparam n1136_s46.INIT=8'h40;
  LUT3 n1137_s46 (
    .F(n1137_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1137_63) 
);
defparam n1137_s46.INIT=8'h40;
  LUT3 n1138_s46 (
    .F(n1138_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1138_63) 
);
defparam n1138_s46.INIT=8'h40;
  LUT3 n1139_s47 (
    .F(n1139_66),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1139_64) 
);
defparam n1139_s47.INIT=8'h40;
  LUT3 n1140_s47 (
    .F(n1140_66),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1140_64) 
);
defparam n1140_s47.INIT=8'h40;
  LUT3 n1141_s46 (
    .F(n1141_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1141_63) 
);
defparam n1141_s46.INIT=8'h40;
  LUT3 n1142_s47 (
    .F(n1142_66),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1142_64) 
);
defparam n1142_s47.INIT=8'h40;
  LUT3 n1143_s46 (
    .F(n1143_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1143_63) 
);
defparam n1143_s46.INIT=8'h40;
  LUT3 n1144_s47 (
    .F(n1144_66),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1144_64) 
);
defparam n1144_s47.INIT=8'h40;
  LUT3 n1145_s46 (
    .F(n1145_65),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1145_63) 
);
defparam n1145_s46.INIT=8'h40;
  LUT3 n1146_s47 (
    .F(n1146_66),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1146_64) 
);
defparam n1146_s47.INIT=8'h40;
  LUT3 n1147_s47 (
    .F(n1147_66),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1147_64) 
);
defparam n1147_s47.INIT=8'h40;
  LUT3 n1148_s49 (
    .F(n1148_68),
    .I0(voice_r_0[4]),
    .I1(ld_addr_1_4),
    .I2(n1148_66) 
);
defparam n1148_s49.INIT=8'h40;
  LUT4 state_3_s6 (
    .F(state_3_12),
    .I0(state[0]),
    .I1(state[2]),
    .I2(state[3]),
    .I3(state[4]) 
);
defparam state_3_s6.INIT=16'h0001;
  LUT3 n1162_s52 (
    .F(n1162_69),
    .I0(inc_prod[46]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1162_s52.INIT=8'h02;
  LUT3 n1163_s52 (
    .F(n1163_69),
    .I0(inc_prod[45]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1163_s52.INIT=8'h02;
  LUT3 n1166_s52 (
    .F(n1166_69),
    .I0(inc_prod[42]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1166_s52.INIT=8'h02;
  LUT3 n1168_s52 (
    .F(n1168_69),
    .I0(inc_prod[40]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1168_s52.INIT=8'h02;
  LUT3 n1169_s52 (
    .F(n1169_69),
    .I0(inc_prod[39]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1169_s52.INIT=8'h02;
  LUT3 n1170_s52 (
    .F(n1170_69),
    .I0(inc_prod[38]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1170_s52.INIT=8'h02;
  LUT3 n1171_s52 (
    .F(n1171_69),
    .I0(inc_prod[37]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1171_s52.INIT=8'h02;
  LUT3 n1172_s52 (
    .F(n1172_69),
    .I0(inc_prod[36]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1172_s52.INIT=8'h02;
  LUT3 n1173_s52 (
    .F(n1173_69),
    .I0(inc_prod[35]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1173_s52.INIT=8'h02;
  LUT3 n1174_s52 (
    .F(n1174_69),
    .I0(inc_prod[34]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1174_s52.INIT=8'h02;
  LUT3 n1175_s52 (
    .F(n1175_69),
    .I0(inc_prod[33]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1175_s52.INIT=8'h02;
  LUT3 n1176_s52 (
    .F(n1176_69),
    .I0(inc_prod[32]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1176_s52.INIT=8'h02;
  LUT3 n1177_s52 (
    .F(n1177_69),
    .I0(inc_prod[31]),
    .I1(state[3]),
    .I2(state[4]) 
);
defparam n1177_s52.INIT=8'h02;
  LUT4 n839_s97 (
    .F(n839_135),
    .I0(eng_107[0]),
    .I1(eng_107[1]),
    .I2(vstate[0]),
    .I3(vstate[1]) 
);
defparam n839_s97.INIT=16'h0100;
  LUT4 n839_s98 (
    .F(n839_137),
    .I0(eng_108[0]),
    .I1(eng_108[1]),
    .I2(vstate_109[0]),
    .I3(vstate_109[1]) 
);
defparam n839_s98.INIT=16'h0100;
  LUT4 n839_s99 (
    .F(n839_139),
    .I0(eng_110[0]),
    .I1(eng_110[1]),
    .I2(vstate_111[0]),
    .I3(vstate_111[1]) 
);
defparam n839_s99.INIT=16'h0100;
  LUT4 n839_s100 (
    .F(n839_141),
    .I0(eng_112[0]),
    .I1(eng_112[1]),
    .I2(vstate_113[0]),
    .I3(vstate_113[1]) 
);
defparam n839_s100.INIT=16'h0100;
  LUT4 n839_s101 (
    .F(n839_143),
    .I0(eng_114[0]),
    .I1(eng_114[1]),
    .I2(vstate_115[0]),
    .I3(vstate_115[1]) 
);
defparam n839_s101.INIT=16'h0100;
  LUT4 n839_s102 (
    .F(n839_145),
    .I0(eng_116[0]),
    .I1(eng_116[1]),
    .I2(vstate_117[0]),
    .I3(vstate_117[1]) 
);
defparam n839_s102.INIT=16'h0100;
  LUT4 n839_s103 (
    .F(n839_147),
    .I0(eng_118[0]),
    .I1(eng_118[1]),
    .I2(vstate_119[0]),
    .I3(vstate_119[1]) 
);
defparam n839_s103.INIT=16'h0100;
  LUT4 n839_s104 (
    .F(n839_149),
    .I0(eng_120[0]),
    .I1(eng_120[1]),
    .I2(vstate_121[0]),
    .I3(vstate_121[1]) 
);
defparam n839_s104.INIT=16'h0100;
  LUT4 n839_s105 (
    .F(n839_151),
    .I0(eng_122[0]),
    .I1(eng_122[1]),
    .I2(vstate_123[0]),
    .I3(vstate_123[1]) 
);
defparam n839_s105.INIT=16'h0100;
  LUT4 n839_s106 (
    .F(n839_153),
    .I0(eng_124[0]),
    .I1(eng_124[1]),
    .I2(vstate_125[0]),
    .I3(vstate_125[1]) 
);
defparam n839_s106.INIT=16'h0100;
  LUT4 n839_s107 (
    .F(n839_155),
    .I0(eng_126[0]),
    .I1(eng_126[1]),
    .I2(vstate_127[0]),
    .I3(vstate_127[1]) 
);
defparam n839_s107.INIT=16'h0100;
  LUT4 n839_s108 (
    .F(n839_157),
    .I0(vstate_128[0]),
    .I1(vstate_128[1]),
    .I2(eng_129[0]),
    .I3(eng_129[1]) 
);
defparam n839_s108.INIT=16'h0004;
  LUT4 n839_s109 (
    .F(n839_159),
    .I0(eng_130[0]),
    .I1(eng_130[1]),
    .I2(vstate_131[0]),
    .I3(vstate_131[1]) 
);
defparam n839_s109.INIT=16'h0100;
  LUT4 n839_s110 (
    .F(n839_161),
    .I0(eng_132[0]),
    .I1(eng_132[1]),
    .I2(vstate_133[0]),
    .I3(vstate_133[1]) 
);
defparam n839_s110.INIT=16'h0100;
  LUT4 n839_s111 (
    .F(n839_163),
    .I0(eng_134[0]),
    .I1(eng_134[1]),
    .I2(vstate_135[0]),
    .I3(vstate_135[1]) 
);
defparam n839_s111.INIT=16'h0100;
  LUT4 n839_s112 (
    .F(n839_165),
    .I0(eng_136[0]),
    .I1(eng_136[1]),
    .I2(vstate_137[0]),
    .I3(vstate_137[1]) 
);
defparam n839_s112.INIT=16'h0100;
  LUT4 n839_s113 (
    .F(n839_167),
    .I0(eng_138[0]),
    .I1(eng_138[1]),
    .I2(vstate_139[0]),
    .I3(vstate_139[1]) 
);
defparam n839_s113.INIT=16'h0100;
  LUT4 n839_s114 (
    .F(n839_169),
    .I0(vstate_140[0]),
    .I1(vstate_140[1]),
    .I2(eng_141[0]),
    .I3(eng_141[1]) 
);
defparam n839_s114.INIT=16'h0004;
  LUT4 n839_s115 (
    .F(n839_171),
    .I0(eng_142[0]),
    .I1(eng_142[1]),
    .I2(vstate_143[0]),
    .I3(vstate_143[1]) 
);
defparam n839_s115.INIT=16'h0100;
  LUT4 mp_lo_12_s16 (
    .F(mp_lo_12_25),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(note_r[0]),
    .I3(mp_hi_15_20) 
);
defparam mp_lo_12_s16.INIT=16'h9F00;
  LUT3 mr_2_s16 (
    .F(mr_2_27),
    .I0(dr[0]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_2_s16.INIT=8'h80;
  LUT3 mr_3_s16 (
    .F(mr_3_27),
    .I0(dr[1]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_3_s16.INIT=8'h80;
  LUT3 mr_4_s16 (
    .F(mr_4_27),
    .I0(dr[2]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_4_s16.INIT=8'h80;
  LUT3 mr_5_s16 (
    .F(mr_5_27),
    .I0(dr[3]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_5_s16.INIT=8'h80;
  LUT3 mr_6_s16 (
    .F(mr_6_27),
    .I0(dr[4]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_6_s16.INIT=8'h80;
  LUT3 mr_7_s16 (
    .F(mr_7_27),
    .I0(dr[5]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_7_s16.INIT=8'h80;
  LUT3 mr_8_s16 (
    .F(mr_8_27),
    .I0(dr[6]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_8_s16.INIT=8'h80;
  LUT3 mr_9_s16 (
    .F(mr_9_27),
    .I0(dr[7]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_9_s16.INIT=8'h80;
  LUT3 mr_10_s16 (
    .F(mr_10_27),
    .I0(dr[8]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_10_s16.INIT=8'h80;
  LUT3 mr_11_s16 (
    .F(mr_11_27),
    .I0(dr[9]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_11_s16.INIT=8'h80;
  LUT3 mr_12_s16 (
    .F(mr_12_27),
    .I0(dr[10]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_12_s16.INIT=8'h80;
  LUT3 mr_13_s16 (
    .F(mr_13_27),
    .I0(dr[11]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_13_s16.INIT=8'h80;
  LUT3 mr_14_s16 (
    .F(mr_14_27),
    .I0(dr[12]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_14_s16.INIT=8'h80;
  LUT3 mr_15_s16 (
    .F(mr_15_27),
    .I0(dr[13]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_15_s16.INIT=8'h80;
  LUT3 mr_16_s16 (
    .F(mr_16_27),
    .I0(dr[14]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_16_s16.INIT=8'h80;
  LUT3 mr_17_s16 (
    .F(mr_17_27),
    .I0(dr[15]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_17_s16.INIT=8'h80;
  LUT3 mr_18_s16 (
    .F(mr_18_27),
    .I0(dr[16]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_18_s16.INIT=8'h80;
  LUT3 mr_19_s16 (
    .F(mr_19_27),
    .I0(dr[17]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_19_s16.INIT=8'h80;
  LUT3 mr_20_s15 (
    .F(mr_20_24),
    .I0(dr[18]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mr_20_s15.INIT=8'h80;
  LUT3 mp_hi_2_s16 (
    .F(mp_hi_2_27),
    .I0(dp_hi[0]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_2_s16.INIT=8'h80;
  LUT3 mp_hi_3_s16 (
    .F(mp_hi_3_27),
    .I0(dp_hi[1]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_3_s16.INIT=8'h80;
  LUT3 mp_hi_4_s16 (
    .F(mp_hi_4_27),
    .I0(dp_hi[2]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_4_s16.INIT=8'h80;
  LUT3 mp_hi_5_s16 (
    .F(mp_hi_5_27),
    .I0(dp_hi[3]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_5_s16.INIT=8'h80;
  LUT3 mp_hi_6_s16 (
    .F(mp_hi_6_27),
    .I0(dp_hi[4]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_6_s16.INIT=8'h80;
  LUT3 mp_hi_7_s16 (
    .F(mp_hi_7_27),
    .I0(dp_hi[5]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_7_s16.INIT=8'h80;
  LUT3 mp_hi_8_s16 (
    .F(mp_hi_8_27),
    .I0(dp_hi[6]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_8_s16.INIT=8'h80;
  LUT3 mp_hi_9_s16 (
    .F(mp_hi_9_27),
    .I0(dp_hi[7]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_9_s16.INIT=8'h80;
  LUT3 mp_hi_10_s16 (
    .F(mp_hi_10_27),
    .I0(dp_hi[8]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_10_s16.INIT=8'h80;
  LUT3 mp_hi_11_s16 (
    .F(mp_hi_11_27),
    .I0(dp_hi[9]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_11_s16.INIT=8'h80;
  LUT3 mp_hi_12_s15 (
    .F(mp_hi_12_24),
    .I0(dp_hi[10]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_hi_12_s15.INIT=8'h80;
  LUT3 mp_lo_2_s16 (
    .F(mp_lo_2_27),
    .I0(dp_lo[0]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_2_s16.INIT=8'h80;
  LUT3 mp_lo_3_s16 (
    .F(mp_lo_3_27),
    .I0(dp_lo[1]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_3_s16.INIT=8'h80;
  LUT3 mp_lo_4_s16 (
    .F(mp_lo_4_27),
    .I0(dp_lo[2]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_4_s16.INIT=8'h80;
  LUT3 mp_lo_5_s16 (
    .F(mp_lo_5_27),
    .I0(dp_lo[3]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_5_s16.INIT=8'h80;
  LUT3 mp_lo_6_s16 (
    .F(mp_lo_6_27),
    .I0(dp_lo[4]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_6_s16.INIT=8'h80;
  LUT3 mp_lo_7_s16 (
    .F(mp_lo_7_27),
    .I0(dp_lo[5]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_7_s16.INIT=8'h80;
  LUT3 mp_lo_8_s16 (
    .F(mp_lo_8_27),
    .I0(dp_lo[6]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_8_s16.INIT=8'h80;
  LUT3 mp_lo_9_s16 (
    .F(mp_lo_9_27),
    .I0(dp_lo[7]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_9_s16.INIT=8'h80;
  LUT3 mp_lo_10_s16 (
    .F(mp_lo_10_27),
    .I0(dp_lo[8]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_10_s16.INIT=8'h80;
  LUT3 mp_lo_11_s16 (
    .F(mp_lo_11_27),
    .I0(dp_lo[9]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_11_s16.INIT=8'h80;
  LUT3 mp_lo_12_s17 (
    .F(mp_lo_12_27),
    .I0(dp_lo[10]),
    .I1(note_r[5]),
    .I2(note_r[6]) 
);
defparam mp_lo_12_s17.INIT=8'h80;
  LUT4 mr_21_s17 (
    .F(mr[21]),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(dr[19]),
    .I3(mr_21_26) 
);
defparam mr_21_s17.INIT=16'h80FF;
  LUT4 mp_hi_13_s15 (
    .F(mp_hi[13]),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(dp_hi[11]),
    .I3(mp_hi_13_22) 
);
defparam mp_hi_13_s15.INIT=16'h80FF;
  LUT4 mp_lo_13_s15 (
    .F(mp_lo[13]),
    .I0(note_r[5]),
    .I1(note_r[6]),
    .I2(dp_lo[11]),
    .I3(mp_lo_13_22) 
);
defparam mp_lo_13_s15.INIT=16'h80FF;
  LUT2 n1450_s9 (
    .F(n1450_15),
    .I0(out_note_on_Z),
    .I1(n135_4) 
);
defparam n1450_s9.INIT=4'h8;
  LUT4 n848_s3 (
    .F(n848_9),
    .I0(ratio_a[19]),
    .I1(mr[21]),
    .I2(ratio_w_18_3),
    .I3(n867_8) 
);
defparam n848_s3.INIT=16'h9600;
  LUT3 n1243_s41 (
    .F(n1243_46),
    .I0(ptr0[5]),
    .I1(ptr0[4]),
    .I2(n1245_46) 
);
defparam n1243_s41.INIT=8'h80;
  LUT4 n1209_s42 (
    .F(n1209_47),
    .I0(base0[10]),
    .I1(base0[8]),
    .I2(n1211_46),
    .I3(base0[9]) 
);
defparam n1209_s42.INIT=16'h65AA;
  LUT3 n1213_s42 (
    .F(n1213_47),
    .I0(ptr1[5]),
    .I1(ptr1[4]),
    .I2(n1245_46) 
);
defparam n1213_s42.INIT=8'h80;
  LUT3 n1228_s42 (
    .F(n1228_47),
    .I0(ptr2[5]),
    .I1(ptr1[4]),
    .I2(n1245_46) 
);
defparam n1228_s42.INIT=8'h80;
  LUT4 n1241_s43 (
    .F(n1241_48),
    .I0(n173_9),
    .I1(nv_index[3]),
    .I2(n1199_44),
    .I3(n174_6) 
);
defparam n1241_s43.INIT=16'h9600;
  LUT4 n1242_s42 (
    .F(n1242_47),
    .I0(n173_9),
    .I1(nv_index[3]),
    .I2(n1199_44),
    .I3(n174_6) 
);
defparam n1242_s42.INIT=16'h9669;
  LUT4 n1100_s6 (
    .F(n1100_14),
    .I0(n1148_66),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1100_s6.INIT=16'h8000;
  LUT4 n1099_s4 (
    .F(n1099_11),
    .I0(n1147_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1099_s4.INIT=16'h8000;
  LUT4 n1098_s4 (
    .F(n1098_11),
    .I0(n1146_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1098_s4.INIT=16'h8000;
  LUT4 n1097_s4 (
    .F(n1097_11),
    .I0(n1145_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1097_s4.INIT=16'h8000;
  LUT4 n1096_s4 (
    .F(n1096_11),
    .I0(n1144_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1096_s4.INIT=16'h8000;
  LUT4 n1095_s4 (
    .F(n1095_11),
    .I0(n1143_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1095_s4.INIT=16'h8000;
  LUT4 n1094_s4 (
    .F(n1094_11),
    .I0(n1142_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1094_s4.INIT=16'h8000;
  LUT4 n1093_s4 (
    .F(n1093_11),
    .I0(n1141_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1093_s4.INIT=16'h8000;
  LUT4 n1092_s4 (
    .F(n1092_11),
    .I0(n1140_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1092_s4.INIT=16'h8000;
  LUT4 n1091_s4 (
    .F(n1091_11),
    .I0(n1139_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1091_s4.INIT=16'h8000;
  LUT4 n1090_s4 (
    .F(n1090_11),
    .I0(n1138_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1090_s4.INIT=16'h8000;
  LUT4 n1089_s4 (
    .F(n1089_11),
    .I0(n1137_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1089_s4.INIT=16'h8000;
  LUT4 n1088_s4 (
    .F(n1088_11),
    .I0(n1136_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1088_s4.INIT=16'h8000;
  LUT4 n1087_s4 (
    .F(n1087_11),
    .I0(n1135_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1087_s4.INIT=16'h8000;
  LUT4 n1086_s4 (
    .F(n1086_11),
    .I0(n1134_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1086_s4.INIT=16'h8000;
  LUT4 n1085_s7 (
    .F(n1085_14),
    .I0(n1133_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1085_s7.INIT=16'h8000;
  LUT4 n1116_s7 (
    .F(n1116_15),
    .I0(n1148_66),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1116_s7.INIT=16'h2000;
  LUT4 n1115_s4 (
    .F(n1115_11),
    .I0(n1147_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1115_s4.INIT=16'h2000;
  LUT4 n1114_s4 (
    .F(n1114_11),
    .I0(n1146_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1114_s4.INIT=16'h2000;
  LUT4 n1113_s4 (
    .F(n1113_11),
    .I0(n1145_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1113_s4.INIT=16'h2000;
  LUT4 n1112_s4 (
    .F(n1112_11),
    .I0(n1144_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1112_s4.INIT=16'h2000;
  LUT4 n1111_s4 (
    .F(n1111_11),
    .I0(n1143_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1111_s4.INIT=16'h2000;
  LUT4 n1110_s4 (
    .F(n1110_11),
    .I0(n1142_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1110_s4.INIT=16'h2000;
  LUT4 n1109_s4 (
    .F(n1109_11),
    .I0(n1141_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1109_s4.INIT=16'h2000;
  LUT4 n1108_s4 (
    .F(n1108_11),
    .I0(n1140_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1108_s4.INIT=16'h2000;
  LUT4 n1107_s4 (
    .F(n1107_11),
    .I0(n1139_64),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1107_s4.INIT=16'h2000;
  LUT4 n1106_s4 (
    .F(n1106_11),
    .I0(n1138_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1106_s4.INIT=16'h2000;
  LUT4 n1105_s4 (
    .F(n1105_11),
    .I0(n1137_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1105_s4.INIT=16'h2000;
  LUT4 n1104_s4 (
    .F(n1104_11),
    .I0(n1136_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1104_s4.INIT=16'h2000;
  LUT4 n1103_s4 (
    .F(n1103_11),
    .I0(n1135_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1103_s4.INIT=16'h2000;
  LUT4 n1102_s4 (
    .F(n1102_11),
    .I0(n1134_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1102_s4.INIT=16'h2000;
  LUT4 n1101_s4 (
    .F(n1101_11),
    .I0(n1133_63),
    .I1(voice_r_0[4]),
    .I2(state[4]),
    .I3(n1428_11) 
);
defparam n1101_s4.INIT=16'h2000;
  DFFCE state_1_s0 (
    .Q(state[1]),
    .D(n1083_81),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE voice_r_4_s0 (
    .Q(voice_r_0[4]),
    .D(chosen_4),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE voice_r_2_s0 (
    .Q(voice_r_0[2]),
    .D(chosen_2),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE voice_r_1_s0 (
    .Q(voice_r_0[1]),
    .D(chosen_1),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE voice_r_0_s0 (
    .Q(voice_r_0[0]),
    .D(chosen_0),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE note_r_6_s0 (
    .Q(note_r[6]),
    .D(out_note_Z_6),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE note_r_5_s0 (
    .Q(note_r[5]),
    .D(out_note_Z_5),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE note_r_3_s0 (
    .Q(note_r[3]),
    .D(out_note_Z_3),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE note_r_2_s0 (
    .Q(note_r[2]),
    .D(out_note_Z_2),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE note_r_1_s0 (
    .Q(note_r[1]),
    .D(out_note_Z_1),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE note_r_0_s0 (
    .Q(note_r[0]),
    .D(out_note_Z_0),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE vel_r_6_s0 (
    .Q(vel_r[6]),
    .D(out_velocity_Z[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1450_15) 
);
  DFFCE lv_a_11_s0 (
    .Q(lv_a[11]),
    .D(level_q[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_10_s0 (
    .Q(lv_a[10]),
    .D(level_q[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_9_s0 (
    .Q(lv_a[9]),
    .D(level_q[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_8_s0 (
    .Q(lv_a[8]),
    .D(level_q[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_7_s0 (
    .Q(lv_a[7]),
    .D(level_q[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_6_s0 (
    .Q(lv_a[6]),
    .D(level_q[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_5_s0 (
    .Q(lv_a[5]),
    .D(level_q[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_4_s0 (
    .Q(lv_a[4]),
    .D(level_q[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_3_s0 (
    .Q(lv_a[3]),
    .D(level_q[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_2_s0 (
    .Q(lv_a[2]),
    .D(level_q[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_1_s0 (
    .Q(lv_a[1]),
    .D(level_q[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_a_0_s0 (
    .Q(lv_a[0]),
    .D(level_q[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1324_9) 
);
  DFFCE lv_b_11_s0 (
    .Q(lv_b[11]),
    .D(level_q[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_10_s0 (
    .Q(lv_b[10]),
    .D(level_q[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_9_s0 (
    .Q(lv_b[9]),
    .D(level_q[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_8_s0 (
    .Q(lv_b[8]),
    .D(level_q[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_7_s0 (
    .Q(lv_b[7]),
    .D(level_q[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_6_s0 (
    .Q(lv_b[6]),
    .D(level_q[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_5_s0 (
    .Q(lv_b[5]),
    .D(level_q[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_4_s0 (
    .Q(lv_b[4]),
    .D(level_q[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_3_s0 (
    .Q(lv_b[3]),
    .D(level_q[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_2_s0 (
    .Q(lv_b[2]),
    .D(level_q[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_1_s0 (
    .Q(lv_b[1]),
    .D(level_q[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_b_0_s0 (
    .Q(lv_b[0]),
    .D(level_q[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1312_8) 
);
  DFFCE lv_c_11_s0 (
    .Q(lv_c[11]),
    .D(level_q[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_10_s0 (
    .Q(lv_c[10]),
    .D(level_q[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_9_s0 (
    .Q(lv_c[9]),
    .D(level_q[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_8_s0 (
    .Q(lv_c[8]),
    .D(level_q[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_7_s0 (
    .Q(lv_c[7]),
    .D(level_q[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_6_s0 (
    .Q(lv_c[6]),
    .D(level_q[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_5_s0 (
    .Q(lv_c[5]),
    .D(level_q[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_4_s0 (
    .Q(lv_c[4]),
    .D(level_q[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_3_s0 (
    .Q(lv_c[3]),
    .D(level_q[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_2_s0 (
    .Q(lv_c[2]),
    .D(level_q[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_1_s0 (
    .Q(lv_c[1]),
    .D(level_q[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_c_0_s0 (
    .Q(lv_c[0]),
    .D(level_q[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1300_8) 
);
  DFFCE lv_d_11_s0 (
    .Q(lv_d[11]),
    .D(level_q[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_10_s0 (
    .Q(lv_d[10]),
    .D(level_q[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_9_s0 (
    .Q(lv_d[9]),
    .D(level_q[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_8_s0 (
    .Q(lv_d[8]),
    .D(level_q[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_7_s0 (
    .Q(lv_d[7]),
    .D(level_q[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_6_s0 (
    .Q(lv_d[6]),
    .D(level_q[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_5_s0 (
    .Q(lv_d[5]),
    .D(level_q[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_4_s0 (
    .Q(lv_d[4]),
    .D(level_q[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_3_s0 (
    .Q(lv_d[3]),
    .D(level_q[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_2_s0 (
    .Q(lv_d[2]),
    .D(level_q[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_1_s0 (
    .Q(lv_d[1]),
    .D(level_q[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lv_d_0_s0 (
    .Q(lv_d[0]),
    .D(level_q[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1288_13) 
);
  DFFCE lo_r_13_s0 (
    .Q(lo_r[13]),
    .D(lo_w[13]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_12_s0 (
    .Q(lo_r[12]),
    .D(lo_w[12]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_11_s0 (
    .Q(lo_r[11]),
    .D(lo_w[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_10_s0 (
    .Q(lo_r[10]),
    .D(lo_w[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_9_s0 (
    .Q(lo_r[9]),
    .D(lo_w[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_8_s0 (
    .Q(lo_r[8]),
    .D(lo_w[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_7_s0 (
    .Q(lo_r[7]),
    .D(lo_w[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_6_s0 (
    .Q(lo_r[6]),
    .D(lo_w[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_5_s0 (
    .Q(lo_r[5]),
    .D(lo_w[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_4_s0 (
    .Q(lo_r[4]),
    .D(lo_w[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_3_s0 (
    .Q(lo_r[3]),
    .D(lo_w[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_2_s0 (
    .Q(lo_r[2]),
    .D(lo_w[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_1_s0 (
    .Q(lo_r[1]),
    .D(lo_w[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE lo_r_0_s0 (
    .Q(lo_r[0]),
    .D(lo_w[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE missing_r_s0 (
    .Q(missing_r),
    .D(n974_3),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1259_10) 
);
  DFFCE ratio_a_19_s0 (
    .Q(ratio_a[19]),
    .D(ratio_q[19]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_18_s0 (
    .Q(ratio_a[18]),
    .D(ratio_q[18]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_17_s0 (
    .Q(ratio_a[17]),
    .D(ratio_q[17]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_16_s0 (
    .Q(ratio_a[16]),
    .D(ratio_q[16]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_15_s0 (
    .Q(ratio_a[15]),
    .D(ratio_q[15]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_14_s0 (
    .Q(ratio_a[14]),
    .D(ratio_q[14]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_13_s0 (
    .Q(ratio_a[13]),
    .D(ratio_q[13]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_12_s0 (
    .Q(ratio_a[12]),
    .D(ratio_q[12]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_11_s0 (
    .Q(ratio_a[11]),
    .D(ratio_q[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_10_s0 (
    .Q(ratio_a[10]),
    .D(ratio_q[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_9_s0 (
    .Q(ratio_a[9]),
    .D(ratio_q[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_8_s0 (
    .Q(ratio_a[8]),
    .D(ratio_q[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_7_s0 (
    .Q(ratio_a[7]),
    .D(ratio_q[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_6_s0 (
    .Q(ratio_a[6]),
    .D(ratio_q[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_5_s0 (
    .Q(ratio_a[5]),
    .D(ratio_q[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_4_s0 (
    .Q(ratio_a[4]),
    .D(ratio_q[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_3_s0 (
    .Q(ratio_a[3]),
    .D(ratio_q[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_2_s0 (
    .Q(ratio_a[2]),
    .D(ratio_q[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_1_s0 (
    .Q(ratio_a[1]),
    .D(ratio_q[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ratio_a_0_s0 (
    .Q(ratio_a[0]),
    .D(ratio_q[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1408_10) 
);
  DFFCE ld_we_31_s0 (
    .Q(\G_PARTIAL.ld_we [31]),
    .D(n1117_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_30_s0 (
    .Q(\G_PARTIAL.ld_we [30]),
    .D(n1118_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_29_s0 (
    .Q(\G_PARTIAL.ld_we [29]),
    .D(n1119_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_28_s0 (
    .Q(\G_PARTIAL.ld_we [28]),
    .D(n1120_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_27_s0 (
    .Q(\G_PARTIAL.ld_we [27]),
    .D(n1121_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_26_s0 (
    .Q(\G_PARTIAL.ld_we [26]),
    .D(n1122_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_25_s0 (
    .Q(\G_PARTIAL.ld_we [25]),
    .D(n1123_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_24_s0 (
    .Q(\G_PARTIAL.ld_we [24]),
    .D(n1124_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_23_s0 (
    .Q(\G_PARTIAL.ld_we [23]),
    .D(n1125_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_22_s0 (
    .Q(\G_PARTIAL.ld_we [22]),
    .D(n1126_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_21_s0 (
    .Q(\G_PARTIAL.ld_we [21]),
    .D(n1127_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_20_s0 (
    .Q(\G_PARTIAL.ld_we [20]),
    .D(n1128_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_19_s0 (
    .Q(\G_PARTIAL.ld_we [19]),
    .D(n1129_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_18_s0 (
    .Q(\G_PARTIAL.ld_we [18]),
    .D(n1130_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_17_s0 (
    .Q(\G_PARTIAL.ld_we [17]),
    .D(n1131_60),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_16_s0 (
    .Q(\G_PARTIAL.ld_we [16]),
    .D(n1132_61),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_15_s0 (
    .Q(\G_PARTIAL.ld_we [15]),
    .D(n1133_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_14_s0 (
    .Q(\G_PARTIAL.ld_we [14]),
    .D(n1134_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_13_s0 (
    .Q(\G_PARTIAL.ld_we [13]),
    .D(n1135_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_12_s0 (
    .Q(\G_PARTIAL.ld_we [12]),
    .D(n1136_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_11_s0 (
    .Q(\G_PARTIAL.ld_we [11]),
    .D(n1137_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_10_s0 (
    .Q(\G_PARTIAL.ld_we [10]),
    .D(n1138_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_9_s0 (
    .Q(\G_PARTIAL.ld_we [9]),
    .D(n1139_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_8_s0 (
    .Q(\G_PARTIAL.ld_we [8]),
    .D(n1140_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_7_s0 (
    .Q(\G_PARTIAL.ld_we [7]),
    .D(n1141_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_6_s0 (
    .Q(\G_PARTIAL.ld_we [6]),
    .D(n1142_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_5_s0 (
    .Q(\G_PARTIAL.ld_we [5]),
    .D(n1143_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_4_s0 (
    .Q(\G_PARTIAL.ld_we [4]),
    .D(n1144_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_3_s0 (
    .Q(\G_PARTIAL.ld_we [3]),
    .D(n1145_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_2_s0 (
    .Q(\G_PARTIAL.ld_we [2]),
    .D(n1146_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_1_s0 (
    .Q(\G_PARTIAL.ld_we [1]),
    .D(n1147_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_we_0_s0 (
    .Q(\G_PARTIAL.ld_we [0]),
    .D(n1148_68),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_31_s0 (
    .Q(\G_PARTIAL.ld_done [31]),
    .D(n1085_14),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_30_s0 (
    .Q(\G_PARTIAL.ld_done [30]),
    .D(n1086_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_29_s0 (
    .Q(\G_PARTIAL.ld_done [29]),
    .D(n1087_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_28_s0 (
    .Q(\G_PARTIAL.ld_done [28]),
    .D(n1088_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_27_s0 (
    .Q(\G_PARTIAL.ld_done [27]),
    .D(n1089_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_26_s0 (
    .Q(\G_PARTIAL.ld_done [26]),
    .D(n1090_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_25_s0 (
    .Q(\G_PARTIAL.ld_done [25]),
    .D(n1091_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_24_s0 (
    .Q(\G_PARTIAL.ld_done [24]),
    .D(n1092_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_23_s0 (
    .Q(\G_PARTIAL.ld_done [23]),
    .D(n1093_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_22_s0 (
    .Q(\G_PARTIAL.ld_done [22]),
    .D(n1094_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_21_s0 (
    .Q(\G_PARTIAL.ld_done [21]),
    .D(n1095_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_20_s0 (
    .Q(\G_PARTIAL.ld_done [20]),
    .D(n1096_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_19_s0 (
    .Q(\G_PARTIAL.ld_done [19]),
    .D(n1097_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_18_s0 (
    .Q(\G_PARTIAL.ld_done [18]),
    .D(n1098_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_17_s0 (
    .Q(\G_PARTIAL.ld_done [17]),
    .D(n1099_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_16_s0 (
    .Q(\G_PARTIAL.ld_done [16]),
    .D(n1100_14),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_15_s0 (
    .Q(\G_PARTIAL.ld_done [15]),
    .D(n1101_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_14_s0 (
    .Q(\G_PARTIAL.ld_done [14]),
    .D(n1102_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_13_s0 (
    .Q(\G_PARTIAL.ld_done [13]),
    .D(n1103_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_12_s0 (
    .Q(\G_PARTIAL.ld_done [12]),
    .D(n1104_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_11_s0 (
    .Q(\G_PARTIAL.ld_done [11]),
    .D(n1105_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_10_s0 (
    .Q(\G_PARTIAL.ld_done [10]),
    .D(n1106_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_9_s0 (
    .Q(\G_PARTIAL.ld_done [9]),
    .D(n1107_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_8_s0 (
    .Q(\G_PARTIAL.ld_done [8]),
    .D(n1108_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_7_s0 (
    .Q(\G_PARTIAL.ld_done [7]),
    .D(n1109_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_6_s0 (
    .Q(\G_PARTIAL.ld_done [6]),
    .D(n1110_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_5_s0 (
    .Q(\G_PARTIAL.ld_done [5]),
    .D(n1111_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_4_s0 (
    .Q(\G_PARTIAL.ld_done [4]),
    .D(n1112_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_3_s0 (
    .Q(\G_PARTIAL.ld_done [3]),
    .D(n1113_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_2_s0 (
    .Q(\G_PARTIAL.ld_done [2]),
    .D(n1114_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_1_s0 (
    .Q(\G_PARTIAL.ld_done [1]),
    .D(n1115_11),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_done_0_s0 (
    .Q(\G_PARTIAL.ld_done [0]),
    .D(n1116_15),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
  DFFCE ld_rel_slope_12_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [12]),
    .D(note_q[12]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_11_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [11]),
    .D(note_q[11]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_10_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [10]),
    .D(note_q[10]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_9_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [9]),
    .D(note_q[9]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_8_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [8]),
    .D(note_q[8]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_7_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [7]),
    .D(note_q[7]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_6_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [6]),
    .D(note_q[6]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_5_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [5]),
    .D(note_q[5]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_4_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [4]),
    .D(note_q[4]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_3_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [3]),
    .D(note_q[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_2_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [2]),
    .D(note_q[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_1_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [1]),
    .D(note_q[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE ld_rel_slope_0_s0 (
    .Q(\G_PARTIAL.ld_rel_slope [0]),
    .D(note_q[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(n1428_10) 
);
  DFFCE state_3_s1 (
    .Q(state[3]),
    .D(n1081_90),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(state_4_8) 
);
defparam state_3_s1.INIT=1'b0;
  DFFCE state_2_s1 (
    .Q(state[2]),
    .D(n1082_85),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(state_4_8) 
);
defparam state_2_s1.INIT=1'b0;
  DFFCE state_0_s1 (
    .Q(state[0]),
    .D(n1084_87),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(state_4_8) 
);
defparam state_0_s1.INIT=1'b0;
  DFFCE slot_3_s1 (
    .Q(slot[3]),
    .D(n1255_47),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(slot_3_9) 
);
defparam slot_3_s1.INIT=1'b0;
  DFFCE slot_2_s1 (
    .Q(slot[2]),
    .D(n1256_47),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(slot_3_9) 
);
defparam slot_2_s1.INIT=1'b0;
  DFFCE slot_1_s1 (
    .Q(slot[1]),
    .D(n1257_47),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(slot_3_9) 
);
defparam slot_1_s1.INIT=1'b0;
  DFFCE slot_0_s1 (
    .Q(slot[0]),
    .D(n1258_48),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(slot_3_9) 
);
defparam slot_0_s1.INIT=1'b0;
  DFFCE point_4_s1 (
    .Q(point[4]),
    .D(n1250_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam point_4_s1.INIT=1'b0;
  DFFCE point_3_s1 (
    .Q(point[3]),
    .D(n1251_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam point_3_s1.INIT=1'b0;
  DFFCE point_2_s1 (
    .Q(point[2]),
    .D(n1252_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam point_2_s1.INIT=1'b0;
  DFFCE point_1_s1 (
    .Q(point[1]),
    .D(n1253_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam point_1_s1.INIT=1'b0;
  DFFCE point_0_s1 (
    .Q(point[0]),
    .D(n1254_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam point_0_s1.INIT=1'b0;
  DFFCE ptr0_14_s1 (
    .Q(ptr0[14]),
    .D(n1190_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_14_s1.INIT=1'b0;
  DFFCE ptr0_13_s1 (
    .Q(ptr0[13]),
    .D(n1191_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_13_s1.INIT=1'b0;
  DFFCE ptr0_12_s1 (
    .Q(ptr0[12]),
    .D(n1192_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_12_s1.INIT=1'b0;
  DFFCE ptr0_11_s1 (
    .Q(ptr0[11]),
    .D(n1193_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_11_s1.INIT=1'b0;
  DFFCE ptr0_10_s1 (
    .Q(ptr0[10]),
    .D(n1194_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_10_s1.INIT=1'b0;
  DFFCE ptr0_9_s1 (
    .Q(ptr0[9]),
    .D(n1195_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_9_s1.INIT=1'b0;
  DFFCE ptr0_8_s1 (
    .Q(ptr0[8]),
    .D(n1196_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_8_s1.INIT=1'b0;
  DFFCE ptr0_7_s1 (
    .Q(ptr0[7]),
    .D(n1197_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_7_s1.INIT=1'b0;
  DFFCE ptr0_6_s1 (
    .Q(ptr0[6]),
    .D(n1198_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_6_s1.INIT=1'b0;
  DFFCE ptr0_5_s1 (
    .Q(ptr0[5]),
    .D(n1244_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_5_s1.INIT=1'b0;
  DFFCE ptr0_4_s1 (
    .Q(ptr0[4]),
    .D(n1245_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_4_s1.INIT=1'b0;
  DFFCE ptr0_3_s1 (
    .Q(ptr0[3]),
    .D(n1246_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_3_s1.INIT=1'b0;
  DFFCE ptr0_2_s1 (
    .Q(ptr0[2]),
    .D(n1247_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_2_s1.INIT=1'b0;
  DFFCE ptr0_1_s1 (
    .Q(ptr0[1]),
    .D(n1248_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_1_s1.INIT=1'b0;
  DFFCE ptr0_0_s1 (
    .Q(ptr0[0]),
    .D(n1249_46),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr0_0_s1.INIT=1'b0;
  DFFCE ptr1_14_s1 (
    .Q(ptr1[14]),
    .D(n1205_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_14_s1.INIT=1'b0;
  DFFCE ptr1_13_s1 (
    .Q(ptr1[13]),
    .D(n1206_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_13_s1.INIT=1'b0;
  DFFCE ptr1_12_s1 (
    .Q(ptr1[12]),
    .D(n1207_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_12_s1.INIT=1'b0;
  DFFCE ptr1_11_s1 (
    .Q(ptr1[11]),
    .D(n1208_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_11_s1.INIT=1'b0;
  DFFCE ptr1_10_s1 (
    .Q(ptr1[10]),
    .D(n1209_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_10_s1.INIT=1'b0;
  DFFCE ptr1_9_s1 (
    .Q(ptr1[9]),
    .D(n1210_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_9_s1.INIT=1'b0;
  DFFCE ptr1_8_s1 (
    .Q(ptr1[8]),
    .D(n1211_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_8_s1.INIT=1'b0;
  DFFCE ptr1_7_s1 (
    .Q(ptr1[7]),
    .D(n1212_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_7_s1.INIT=1'b0;
  DFFCE ptr1_6_s1 (
    .Q(ptr1[6]),
    .D(n1213_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_6_s1.INIT=1'b0;
  DFFCE ptr1_5_s1 (
    .Q(ptr1[5]),
    .D(n1214_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_5_s1.INIT=1'b0;
  DFFCE ptr1_4_s1 (
    .Q(ptr1[4]),
    .D(n1230_44),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr1_4_s1.INIT=1'b0;
  DFFCE ptr2_14_s1 (
    .Q(ptr2[14]),
    .D(n1220_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_14_s1.INIT=1'b0;
  DFFCE ptr2_13_s1 (
    .Q(ptr2[13]),
    .D(n1221_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_13_s1.INIT=1'b0;
  DFFCE ptr2_12_s1 (
    .Q(ptr2[12]),
    .D(n1222_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_12_s1.INIT=1'b0;
  DFFCE ptr2_11_s1 (
    .Q(ptr2[11]),
    .D(n1223_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_11_s1.INIT=1'b0;
  DFFCE ptr2_10_s1 (
    .Q(ptr2[10]),
    .D(n1224_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_10_s1.INIT=1'b0;
  DFFCE ptr2_9_s1 (
    .Q(ptr2[9]),
    .D(n1225_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_9_s1.INIT=1'b0;
  DFFCE ptr2_8_s1 (
    .Q(ptr2[8]),
    .D(n1226_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_8_s1.INIT=1'b0;
  DFFCE ptr2_7_s1 (
    .Q(ptr2[7]),
    .D(n1227_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_7_s1.INIT=1'b0;
  DFFCE ptr2_6_s1 (
    .Q(ptr2[6]),
    .D(n1228_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_6_s1.INIT=1'b0;
  DFFCE ptr2_5_s1 (
    .Q(ptr2[5]),
    .D(n1229_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr2_5_s1.INIT=1'b0;
  DFFCE ptr3_14_s1 (
    .Q(ptr3[14]),
    .D(n1235_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_14_s1.INIT=1'b0;
  DFFCE ptr3_13_s1 (
    .Q(ptr3[13]),
    .D(n1236_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_13_s1.INIT=1'b0;
  DFFCE ptr3_12_s1 (
    .Q(ptr3[12]),
    .D(n1237_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_12_s1.INIT=1'b0;
  DFFCE ptr3_11_s1 (
    .Q(ptr3[11]),
    .D(n1238_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_11_s1.INIT=1'b0;
  DFFCE ptr3_10_s1 (
    .Q(ptr3[10]),
    .D(n1239_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_10_s1.INIT=1'b0;
  DFFCE ptr3_9_s1 (
    .Q(ptr3[9]),
    .D(n1240_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_9_s1.INIT=1'b0;
  DFFCE ptr3_8_s1 (
    .Q(ptr3[8]),
    .D(n1241_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_8_s1.INIT=1'b0;
  DFFCE ptr3_7_s1 (
    .Q(ptr3[7]),
    .D(n1242_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_7_s1.INIT=1'b0;
  DFFCE ptr3_6_s1 (
    .Q(ptr3[6]),
    .D(n1243_43),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(point_4_10) 
);
defparam ptr3_6_s1.INIT=1'b0;
  DFFCE ld_addr_8_s1 (
    .Q(\G_PARTIAL.ld_addr [8]),
    .D(slot[3]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
defparam ld_addr_8_s1.INIT=1'b0;
  DFFCE ld_addr_7_s1 (
    .Q(\G_PARTIAL.ld_addr [7]),
    .D(slot[2]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
defparam ld_addr_7_s1.INIT=1'b0;
  DFFCE ld_addr_6_s1 (
    .Q(\G_PARTIAL.ld_addr [6]),
    .D(slot[1]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
defparam ld_addr_6_s1.INIT=1'b0;
  DFFCE ld_addr_5_s1 (
    .Q(\G_PARTIAL.ld_addr [5]),
    .D(slot[0]),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
defparam ld_addr_5_s1.INIT=1'b0;
  DFFCE state_4_s1 (
    .Q(state[4]),
    .D(n1080_76),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(state_4_8) 
);
defparam state_4_s1.INIT=1'b0;
  DFFCE ld_addr_4_s1 (
    .Q(\G_PARTIAL.ld_addr [4]),
    .D(n1153_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_addr_3_s1 (
    .Q(\G_PARTIAL.ld_addr [3]),
    .D(n1154_66),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_addr_2_s1 (
    .Q(\G_PARTIAL.ld_addr [2]),
    .D(n1155_67),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_addr_1_s1 (
    .Q(\G_PARTIAL.ld_addr [1]),
    .D(n1156_64),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_addr_0_s1 (
    .Q(\G_PARTIAL.ld_addr [0]),
    .D(n1157_64),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_27_s1 (
    .Q(\G_PARTIAL.ld_data [27]),
    .D(n1162_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_26_s1 (
    .Q(\G_PARTIAL.ld_data [26]),
    .D(n1163_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_25_s1 (
    .Q(\G_PARTIAL.ld_data [25]),
    .D(n1164_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_24_s1 (
    .Q(\G_PARTIAL.ld_data [24]),
    .D(n1165_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_23_s1 (
    .Q(\G_PARTIAL.ld_data [23]),
    .D(n1166_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_22_s1 (
    .Q(\G_PARTIAL.ld_data [22]),
    .D(n1167_65),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_21_s1 (
    .Q(\G_PARTIAL.ld_data [21]),
    .D(n1168_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_20_s1 (
    .Q(\G_PARTIAL.ld_data [20]),
    .D(n1169_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_19_s1 (
    .Q(\G_PARTIAL.ld_data [19]),
    .D(n1170_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_18_s1 (
    .Q(\G_PARTIAL.ld_data [18]),
    .D(n1171_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_17_s1 (
    .Q(\G_PARTIAL.ld_data [17]),
    .D(n1172_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_16_s1 (
    .Q(\G_PARTIAL.ld_data [16]),
    .D(n1173_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_15_s1 (
    .Q(\G_PARTIAL.ld_data [15]),
    .D(n1174_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_14_s1 (
    .Q(\G_PARTIAL.ld_data [14]),
    .D(n1175_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_13_s1 (
    .Q(\G_PARTIAL.ld_data [13]),
    .D(n1176_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_12_s1 (
    .Q(\G_PARTIAL.ld_data [12]),
    .D(n1177_69),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_11_s1 (
    .Q(\G_PARTIAL.ld_data [11]),
    .D(n1178_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_10_s1 (
    .Q(\G_PARTIAL.ld_data [10]),
    .D(n1179_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_9_s1 (
    .Q(\G_PARTIAL.ld_data [9]),
    .D(n1180_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_8_s1 (
    .Q(\G_PARTIAL.ld_data [8]),
    .D(n1181_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_7_s1 (
    .Q(\G_PARTIAL.ld_data [7]),
    .D(n1182_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_6_s1 (
    .Q(\G_PARTIAL.ld_data [6]),
    .D(n1183_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_5_s1 (
    .Q(\G_PARTIAL.ld_data [5]),
    .D(n1184_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_4_s1 (
    .Q(\G_PARTIAL.ld_data [4]),
    .D(n1185_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_3_s1 (
    .Q(\G_PARTIAL.ld_data [3]),
    .D(n1186_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_2_s1 (
    .Q(\G_PARTIAL.ld_data [2]),
    .D(n1187_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_1_s1 (
    .Q(\G_PARTIAL.ld_data [1]),
    .D(n1188_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE ld_data_0_s1 (
    .Q(\G_PARTIAL.ld_data [0]),
    .D(n1189_59),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(ld_addr_1_4) 
);
  DFFCE voice_r_3_s1 (
    .Q(voice_r[3]),
    .D(chosen_3_29),
    .CLK(clk_12m288),
    .CLEAR(n290_6),
    .CE(VCC) 
);
defparam voice_r_3_s1.INIT=1'b0;
  pROM inc0_r_0_s1 (
    .DO({DO[31],inc0_r[30:0]}),
    .CLK(clk_12m288),
    .CE(n1450_15),
    .OCE(GND),
    .RESET(n290_6),
    .AD({GND,GND,out_note_Z_6,out_note_Z_5,out_note_Z_5,out_note_Z_3,out_note_Z_2,out_note_Z_1,out_note_Z_0,GND,VCC,VCC,VCC,VCC}) 
);
defparam inc0_r_0_s1.BIT_WIDTH=32;
defparam inc0_r_0_s1.INIT_RAM_00=256'h0010B9A3000FC953000EE681000E1069000D4656000C879A000BD393000B29A6;
defparam inc0_r_0_s1.INIT_RAM_01=256'h001A8CAC00190F340017A7260016534C001512860013E3C00012C5F90011B83C;
defparam inc0_r_0_s1.INIT_RAM_02=256'h002A250C0027C78100258BF20023707800217345001F92A7001DCD02001C20D3;
defparam inc0_r_0_s1.INIT_RAM_03=256'h0042E68B003F254E003B9A04003841A60035195800321E69002F4E4B002CA698;
defparam inc0_r_0_s1.INIT_RAM_04=256'h006A32B100643CD2005E9C9600594D3100544A17004F8F01004B17E50046E0F0;
defparam inc0_r_0_s1.INIT_RAM_05=256'h00A8942E009F1E0300962FC9008DC1E10085CD15007E4A9B007734070070834C;
defparam inc0_r_0_s1.INIT_RAM_06=256'h010B9A2B00FC953600EE680F00E1069700D4656200C879A300BD392D00B29A62;
defparam inc0_r_0_s1.INIT_RAM_07=256'h01A8CAC30190F347017A725A016534C30151285D013E3C06012C5F93011B83C2;
defparam inc0_r_0_s1.INIT_RAM_08=256'h02A250BA027C780B0258BF26023707830217345601F92A6D01DCD01D01C20D2F;
defparam inc0_r_0_s1.INIT_RAM_09=256'h042E68AC03F254D903B9A03A03841A5D035195860321E68D02F4E4B402CA6987;
defparam inc0_r_0_s1.INIT_RAM_0A=256'h06A32B0D0643CD1B05E9C9680594D30D0544A17304F8F01704B17E4B046E0F07;
defparam inc0_r_0_s1.INIT_RAM_0B=256'h0A8942E709F1E02D0962FC9608DC1E0D085CD15707E4A9B207734075070834BA;
defparam inc0_r_0_s1.INIT_RAM_0C=256'h10B9A2AF0FC953640EE680E90E1069740D46561A0C879A350BD392D00B29A61A;
defparam inc0_r_0_s1.INIT_RAM_0D=256'h1A8CAC34190F346A17A725A016534C35151285CE13E3C05A12C5F92C11B83C1A;
defparam inc0_r_0_s1.INIT_RAM_0E=256'h2A250B9C27C780B5258BF259237078352173455E1F92A6C81DCD01D31C20D2E8;
defparam inc0_r_0_s1.INIT_RAM_0F=256'h42E68ABC3F254D913B9A03A63841A5D135195868321E68D42F4E4B3F2CA6986A;
defparam inc0_r_0_s1.READ_MODE=1'b0;
defparam inc0_r_0_s1.RESET_MODE="ASYNC";
  MULT27X36 n919_s (
    .DOUT({DOUT[62:47],inc_prod[46:19],DOUT[18:0]}),
    .A({GND,GND,GND,GND,GND,GND,GND,n848_9,n849_7,n850_7,n851_7,n852_7,n853_7,n854_7,n855_7,n856_7,n857_7,n858_7,n859_7,n860_7,n861_7,n862_7,n863_7,n864_7,n865_7,n866_7,n867_7}),
    .B({GND,GND,GND,GND,GND,inc0_r[30:0]}),
    .D({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({n1341_9,n1388_9}),
    .RESET({GND,n290_6}),
    .PSEL(GND),
    .PADDSUB(GND) 
);
defparam n919_s.MULT_RESET_MODE="ASYNC";
defparam n919_s.OREG_CLK="CLK0";
defparam n919_s.OREG_CE="CE1";
defparam n919_s.OREG_RESET="RESET0";
defparam n919_s.AREG_CLK="CLK0";
defparam n919_s.AREG_CE="CE0";
defparam n919_s.AREG_RESET="RESET0";
defparam n919_s.BREG_CLK="BYPASS";
defparam n919_s.BREG_CE="CE0";
defparam n919_s.BREG_RESET="RESET0";
defparam n919_s.DREG_CLK="BYPASS";
defparam n919_s.DREG_CE="CE0";
defparam n919_s.DREG_RESET="RESET0";
defparam n919_s.PREG_CLK="BYPASS";
defparam n919_s.PREG_CE="CE0";
defparam n919_s.PREG_RESET="RESET0";
defparam n919_s.DYN_P_SEL="FALSE";
defparam n919_s.P_SEL=1'b0;
defparam n919_s.DYN_P_ADDSUB="FALSE";
defparam n919_s.P_ADDSUB=1'b0;
defparam n919_s.PADDSUB_IREG_CE="CE0";
defparam n919_s.PADDSUB_IREG_CLK="BYPASS";
defparam n919_s.PADDSUB_IREG_RESET="RESET0";
defparam n919_s.PSEL_IREG_CE="CE0";
defparam n919_s.PSEL_IREG_CLK="BYPASS";
defparam n919_s.PSEL_IREG_RESET="RESET0";
  MULTALU27X18 mv_0_s (
    .DOUT({DOUT_0[47:25],mv[24:8],DOUT_0[7:0]}),
    .CASO(CASO[47:0]),
    .SOA(SOA[26:0]),
    .A({hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13],hi_w[13:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({GND,GND,GND,GND,GND,GND,GND,GND,GND,av_prod[13:5]}),
    .C({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .D({lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13],lo_w[13:0]}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,n1259_10}),
    .RESET({GND,n290_6}) 
);
defparam mv_0_s.MULT_RESET_MODE="ASYNC";
defparam mv_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam mv_0_s.ACCSEL_IREG_CE="CE0";
defparam mv_0_s.ACCSEL_IREG_RESET="RESET0";
defparam mv_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam mv_0_s.ADDSUB0_IREG_CE="CE0";
defparam mv_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam mv_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam mv_0_s.ADDSUB1_IREG_CE="CE0";
defparam mv_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam mv_0_s.FB_PREG_EN="FALSE";
defparam mv_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam mv_0_s.ACCSEL_PREG_CE="CE0";
defparam mv_0_s.ACCSEL_PREG_RESET="RESET0";
defparam mv_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam mv_0_s.ADDSUB0_PREG_CE="CE0";
defparam mv_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam mv_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam mv_0_s.ADDSUB1_PREG_CE="CE0";
defparam mv_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam mv_0_s.OREG_CLK="BYPASS";
defparam mv_0_s.OREG_CE="CE0";
defparam mv_0_s.OREG_RESET="RESET0";
defparam mv_0_s.PRE_LOAD=48'h000000000000;
defparam mv_0_s.CASI_SEL=1'b0;
defparam mv_0_s.AREG_CLK="CLK0";
defparam mv_0_s.AREG_CE="CE0";
defparam mv_0_s.AREG_RESET="RESET0";
defparam mv_0_s.BREG_CLK="BYPASS";
defparam mv_0_s.BREG_CE="CE0";
defparam mv_0_s.BREG_RESET="RESET0";
defparam mv_0_s.DREG_CLK="CLK0";
defparam mv_0_s.DREG_CE="CE0";
defparam mv_0_s.DREG_RESET="RESET0";
defparam mv_0_s.PREG_CLK="BYPASS";
defparam mv_0_s.PREG_CE="CE0";
defparam mv_0_s.PREG_RESET="RESET0";
defparam mv_0_s.SOA_PREG_EN="FALSE";
defparam mv_0_s.DYN_P_SEL="FALSE";
defparam mv_0_s.P_SEL=1'b1;
defparam mv_0_s.DYN_P_ADDSUB="FALSE";
defparam mv_0_s.P_ADDSUB=1'b1;
defparam mv_0_s.ACC_SEL=1'b0;
defparam mv_0_s.ADD_SUB_0=1'b0;
defparam mv_0_s.ADD_SUB_1=1'b0;
defparam mv_0_s.A_SEL=1'b0;
defparam mv_0_s.CASISEL_IREG_CE="CE0";
defparam mv_0_s.CASISEL_IREG_CLK="BYPASS";
defparam mv_0_s.CASISEL_IREG_RESET="RESET0";
defparam mv_0_s.CASISEL_PREG_CE="CE0";
defparam mv_0_s.CASISEL_PREG_CLK="BYPASS";
defparam mv_0_s.CASISEL_PREG_RESET="RESET0";
defparam mv_0_s.CSEL_IREG_CE="CE0";
defparam mv_0_s.CSEL_IREG_CLK="BYPASS";
defparam mv_0_s.CSEL_IREG_RESET="RESET0";
defparam mv_0_s.CSEL_PREG_CE="CE0";
defparam mv_0_s.CSEL_PREG_CLK="BYPASS";
defparam mv_0_s.CSEL_PREG_RESET="RESET0";
defparam mv_0_s.C_IREG_CE="CE0";
defparam mv_0_s.C_IREG_CLK="BYPASS";
defparam mv_0_s.C_IREG_RESET="RESET0";
defparam mv_0_s.C_PREG_CE="CE0";
defparam mv_0_s.C_PREG_CLK="BYPASS";
defparam mv_0_s.C_PREG_RESET="RESET0";
defparam mv_0_s.C_SEL=1'b0;
defparam mv_0_s.DYN_ACC_SEL="FALSE";
defparam mv_0_s.DYN_ADD_SUB_0="FALSE";
defparam mv_0_s.DYN_ADD_SUB_1="FALSE";
defparam mv_0_s.DYN_A_SEL="FALSE";
defparam mv_0_s.DYN_CASI_SEL="FALSE";
defparam mv_0_s.DYN_C_SEL="FALSE";
defparam mv_0_s.MULT12X12_EN="FALSE";
defparam mv_0_s.PADDSUB_IREG_CE="CE0";
defparam mv_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam mv_0_s.PADDSUB_IREG_RESET="RESET0";
defparam mv_0_s.PSEL_IREG_CE="CE0";
defparam mv_0_s.PSEL_IREG_CLK="BYPASS";
defparam mv_0_s.PSEL_IREG_RESET="RESET0";
  MULT12X12 extra_att_0_s (
    .DOUT({DOUT_1[23:13],extra_att[12:0]}),
    .A({GND,GND,GND,GND,GND,GND,soft_steps_3_8,GND,soft_steps_3_8,GND,GND,GND}),
    .B({GND,GND,GND,GND,GND,GND,GND,VCC,VCC,GND,VCC,GND}),
    .CLK({GND,GND}),
    .CE({VCC,VCC}),
    .RESET({GND,GND}) 
);
defparam extra_att_0_s.MULT_RESET_MODE="SYNC";
defparam extra_att_0_s.OREG_CLK="BYPASS";
defparam extra_att_0_s.OREG_CE="CE0";
defparam extra_att_0_s.OREG_RESET="RESET0";
defparam extra_att_0_s.AREG_CLK="BYPASS";
defparam extra_att_0_s.AREG_CE="CE0";
defparam extra_att_0_s.AREG_RESET="RESET0";
defparam extra_att_0_s.BREG_CLK="BYPASS";
defparam extra_att_0_s.BREG_CE="CE0";
defparam extra_att_0_s.BREG_RESET="RESET0";
defparam extra_att_0_s.PREG_CLK="BYPASS";
defparam extra_att_0_s.PREG_CE="CE0";
defparam extra_att_0_s.PREG_RESET="RESET0";
  MULT12X12 av_prod_0_s (
    .DOUT({DOUT_2[23:14],av_prod[13:5],DOUT_2[4:0]}),
    .A({GND,GND,GND,GND,GND,GND,GND,vel_r[6],GND,vel_r[6],GND,GND}),
    .B({GND,GND,GND,GND,VCC,VCC,GND,GND,VCC,VCC,GND,VCC}),
    .CLK({GND,GND}),
    .CE({VCC,VCC}),
    .RESET({GND,GND}) 
);
defparam av_prod_0_s.MULT_RESET_MODE="SYNC";
defparam av_prod_0_s.OREG_CLK="BYPASS";
defparam av_prod_0_s.OREG_CE="CE0";
defparam av_prod_0_s.OREG_RESET="RESET0";
defparam av_prod_0_s.AREG_CLK="BYPASS";
defparam av_prod_0_s.AREG_CE="CE0";
defparam av_prod_0_s.AREG_RESET="RESET0";
defparam av_prod_0_s.BREG_CLK="BYPASS";
defparam av_prod_0_s.BREG_CE="CE0";
defparam av_prod_0_s.BREG_RESET="RESET0";
defparam av_prod_0_s.PREG_CLK="BYPASS";
defparam av_prod_0_s.PREG_CE="CE0";
defparam av_prod_0_s.PREG_RESET="RESET0";
  ALU n172_s (
    .SUM(n172_1),
    .COUT(n172_2),
    .I0(nv_index[2]),
    .I1(nv_index[4]),
    .I3(GND),
    .CIN(base0_7_3) 
);
defparam n172_s.ALU_MODE=0;
  ALU n171_s (
    .SUM(n171_1),
    .COUT(n171_2),
    .I0(nv_index[3]),
    .I1(nv_index[5]),
    .I3(GND),
    .CIN(n172_2) 
);
defparam n171_s.ALU_MODE=0;
  ALU n170_s (
    .SUM(n170_1),
    .COUT(n170_2),
    .I0(nv_index[4]),
    .I1(GND),
    .I3(GND),
    .CIN(n171_2) 
);
defparam n170_s.ALU_MODE=0;
  ALU n169_s (
    .SUM(n169_1),
    .COUT(n169_2),
    .I0(nv_index[5]),
    .I1(GND),
    .I3(GND),
    .CIN(n170_2) 
);
defparam n169_s.ALU_MODE=0;
  ALU n168_s (
    .SUM(n168_1),
    .COUT(n168_0_COUT),
    .I0(GND),
    .I1(GND),
    .I3(GND),
    .CIN(n169_2) 
);
defparam n168_s.ALU_MODE=0;
  ALU base0_8_s (
    .SUM(base0[8]),
    .COUT(base0_8_2),
    .I0(n174_6),
    .I1(nv_index[4]),
    .I3(GND),
    .CIN(base0_7_3) 
);
defparam base0_8_s.ALU_MODE=0;
  ALU base0_9_s (
    .SUM(base0[9]),
    .COUT(base0_9_2),
    .I0(n173_4),
    .I1(nv_index[5]),
    .I3(GND),
    .CIN(base0_8_2) 
);
defparam base0_9_s.ALU_MODE=0;
  ALU base0_10_s (
    .SUM(base0[10]),
    .COUT(base0_10_2),
    .I0(n172_1),
    .I1(GND),
    .I3(GND),
    .CIN(base0_9_2) 
);
defparam base0_10_s.ALU_MODE=0;
  ALU base0_11_s (
    .SUM(base0[11]),
    .COUT(base0_11_2),
    .I0(n171_1),
    .I1(GND),
    .I3(GND),
    .CIN(base0_10_2) 
);
defparam base0_11_s.ALU_MODE=0;
  ALU base0_12_s (
    .SUM(base0[12]),
    .COUT(base0_12_2),
    .I0(n170_1),
    .I1(GND),
    .I3(GND),
    .CIN(base0_11_2) 
);
defparam base0_12_s.ALU_MODE=0;
  ALU base0_13_s (
    .SUM(base0[13]),
    .COUT(base0_13_2),
    .I0(n169_1),
    .I1(GND),
    .I3(GND),
    .CIN(base0_12_2) 
);
defparam base0_13_s.ALU_MODE=0;
  ALU base0_14_s (
    .SUM(base0[14]),
    .COUT(base0_14_0_COUT),
    .I0(n168_1),
    .I1(GND),
    .I3(GND),
    .CIN(base0_13_2) 
);
defparam base0_14_s.ALU_MODE=0;
  ALU hi_w_0_s (
    .SUM(hi_w[0]),
    .COUT(hi_w_0_3),
    .I0(lv_b[0]),
    .I1(mp_hi[2]),
    .I3(GND),
    .CIN(GND) 
);
defparam hi_w_0_s.ALU_MODE=0;
  ALU hi_w_1_s (
    .SUM(hi_w[1]),
    .COUT(hi_w_1_3),
    .I0(lv_b[1]),
    .I1(mp_hi[3]),
    .I3(GND),
    .CIN(hi_w_0_3) 
);
defparam hi_w_1_s.ALU_MODE=0;
  ALU hi_w_2_s (
    .SUM(hi_w[2]),
    .COUT(hi_w_2_3),
    .I0(lv_b[2]),
    .I1(mp_hi[4]),
    .I3(GND),
    .CIN(hi_w_1_3) 
);
defparam hi_w_2_s.ALU_MODE=0;
  ALU hi_w_3_s (
    .SUM(hi_w[3]),
    .COUT(hi_w_3_3),
    .I0(lv_b[3]),
    .I1(mp_hi[5]),
    .I3(GND),
    .CIN(hi_w_2_3) 
);
defparam hi_w_3_s.ALU_MODE=0;
  ALU hi_w_4_s (
    .SUM(hi_w[4]),
    .COUT(hi_w_4_3),
    .I0(lv_b[4]),
    .I1(mp_hi[6]),
    .I3(GND),
    .CIN(hi_w_3_3) 
);
defparam hi_w_4_s.ALU_MODE=0;
  ALU hi_w_5_s (
    .SUM(hi_w[5]),
    .COUT(hi_w_5_3),
    .I0(lv_b[5]),
    .I1(mp_hi[7]),
    .I3(GND),
    .CIN(hi_w_4_3) 
);
defparam hi_w_5_s.ALU_MODE=0;
  ALU hi_w_6_s (
    .SUM(hi_w[6]),
    .COUT(hi_w_6_3),
    .I0(lv_b[6]),
    .I1(mp_hi[8]),
    .I3(GND),
    .CIN(hi_w_5_3) 
);
defparam hi_w_6_s.ALU_MODE=0;
  ALU hi_w_7_s (
    .SUM(hi_w[7]),
    .COUT(hi_w_7_3),
    .I0(lv_b[7]),
    .I1(mp_hi[9]),
    .I3(GND),
    .CIN(hi_w_6_3) 
);
defparam hi_w_7_s.ALU_MODE=0;
  ALU hi_w_8_s (
    .SUM(hi_w[8]),
    .COUT(hi_w_8_3),
    .I0(lv_b[8]),
    .I1(mp_hi[10]),
    .I3(GND),
    .CIN(hi_w_7_3) 
);
defparam hi_w_8_s.ALU_MODE=0;
  ALU hi_w_9_s (
    .SUM(hi_w[9]),
    .COUT(hi_w_9_3),
    .I0(lv_b[9]),
    .I1(mp_hi[11]),
    .I3(GND),
    .CIN(hi_w_8_3) 
);
defparam hi_w_9_s.ALU_MODE=0;
  ALU hi_w_10_s (
    .SUM(hi_w[10]),
    .COUT(hi_w_10_3),
    .I0(lv_b[10]),
    .I1(mp_hi[12]),
    .I3(GND),
    .CIN(hi_w_9_3) 
);
defparam hi_w_10_s.ALU_MODE=0;
  ALU hi_w_11_s (
    .SUM(hi_w[11]),
    .COUT(hi_w_11_3),
    .I0(lv_b[11]),
    .I1(mp_hi[13]),
    .I3(GND),
    .CIN(hi_w_10_3) 
);
defparam hi_w_11_s.ALU_MODE=0;
  ALU hi_w_12_s (
    .SUM(hi_w[12]),
    .COUT(hi_w_12_3),
    .I0(GND),
    .I1(mp_hi_15_18),
    .I3(GND),
    .CIN(hi_w_11_3) 
);
defparam hi_w_12_s.ALU_MODE=0;
  ALU hi_w_13_s (
    .SUM(hi_w[13]),
    .COUT(hi_w_13_0_COUT),
    .I0(GND),
    .I1(mp_hi_15_18),
    .I3(GND),
    .CIN(hi_w_12_3) 
);
defparam hi_w_13_s.ALU_MODE=0;
  ALU ratio_w_0_s (
    .SUM(ratio_w[0]),
    .COUT(ratio_w_0_3),
    .I0(ratio_a[0]),
    .I1(mr[2]),
    .I3(GND),
    .CIN(GND) 
);
defparam ratio_w_0_s.ALU_MODE=0;
  ALU ratio_w_1_s (
    .SUM(ratio_w[1]),
    .COUT(ratio_w_1_3),
    .I0(ratio_a[1]),
    .I1(mr[3]),
    .I3(GND),
    .CIN(ratio_w_0_3) 
);
defparam ratio_w_1_s.ALU_MODE=0;
  ALU ratio_w_2_s (
    .SUM(ratio_w[2]),
    .COUT(ratio_w_2_3),
    .I0(ratio_a[2]),
    .I1(mr[4]),
    .I3(GND),
    .CIN(ratio_w_1_3) 
);
defparam ratio_w_2_s.ALU_MODE=0;
  ALU ratio_w_3_s (
    .SUM(ratio_w[3]),
    .COUT(ratio_w_3_3),
    .I0(ratio_a[3]),
    .I1(mr[5]),
    .I3(GND),
    .CIN(ratio_w_2_3) 
);
defparam ratio_w_3_s.ALU_MODE=0;
  ALU ratio_w_4_s (
    .SUM(ratio_w[4]),
    .COUT(ratio_w_4_3),
    .I0(ratio_a[4]),
    .I1(mr[6]),
    .I3(GND),
    .CIN(ratio_w_3_3) 
);
defparam ratio_w_4_s.ALU_MODE=0;
  ALU ratio_w_5_s (
    .SUM(ratio_w[5]),
    .COUT(ratio_w_5_3),
    .I0(ratio_a[5]),
    .I1(mr[7]),
    .I3(GND),
    .CIN(ratio_w_4_3) 
);
defparam ratio_w_5_s.ALU_MODE=0;
  ALU ratio_w_6_s (
    .SUM(ratio_w[6]),
    .COUT(ratio_w_6_3),
    .I0(ratio_a[6]),
    .I1(mr[8]),
    .I3(GND),
    .CIN(ratio_w_5_3) 
);
defparam ratio_w_6_s.ALU_MODE=0;
  ALU ratio_w_7_s (
    .SUM(ratio_w[7]),
    .COUT(ratio_w_7_3),
    .I0(ratio_a[7]),
    .I1(mr[9]),
    .I3(GND),
    .CIN(ratio_w_6_3) 
);
defparam ratio_w_7_s.ALU_MODE=0;
  ALU ratio_w_8_s (
    .SUM(ratio_w[8]),
    .COUT(ratio_w_8_3),
    .I0(ratio_a[8]),
    .I1(mr[10]),
    .I3(GND),
    .CIN(ratio_w_7_3) 
);
defparam ratio_w_8_s.ALU_MODE=0;
  ALU ratio_w_9_s (
    .SUM(ratio_w[9]),
    .COUT(ratio_w_9_3),
    .I0(ratio_a[9]),
    .I1(mr[11]),
    .I3(GND),
    .CIN(ratio_w_8_3) 
);
defparam ratio_w_9_s.ALU_MODE=0;
  ALU ratio_w_10_s (
    .SUM(ratio_w[10]),
    .COUT(ratio_w_10_3),
    .I0(ratio_a[10]),
    .I1(mr[12]),
    .I3(GND),
    .CIN(ratio_w_9_3) 
);
defparam ratio_w_10_s.ALU_MODE=0;
  ALU ratio_w_11_s (
    .SUM(ratio_w[11]),
    .COUT(ratio_w_11_3),
    .I0(ratio_a[11]),
    .I1(mr[13]),
    .I3(GND),
    .CIN(ratio_w_10_3) 
);
defparam ratio_w_11_s.ALU_MODE=0;
  ALU ratio_w_12_s (
    .SUM(ratio_w[12]),
    .COUT(ratio_w_12_3),
    .I0(ratio_a[12]),
    .I1(mr[14]),
    .I3(GND),
    .CIN(ratio_w_11_3) 
);
defparam ratio_w_12_s.ALU_MODE=0;
  ALU ratio_w_13_s (
    .SUM(ratio_w[13]),
    .COUT(ratio_w_13_3),
    .I0(ratio_a[13]),
    .I1(mr[15]),
    .I3(GND),
    .CIN(ratio_w_12_3) 
);
defparam ratio_w_13_s.ALU_MODE=0;
  ALU ratio_w_14_s (
    .SUM(ratio_w[14]),
    .COUT(ratio_w_14_3),
    .I0(ratio_a[14]),
    .I1(mr[16]),
    .I3(GND),
    .CIN(ratio_w_13_3) 
);
defparam ratio_w_14_s.ALU_MODE=0;
  ALU ratio_w_15_s (
    .SUM(ratio_w[15]),
    .COUT(ratio_w_15_3),
    .I0(ratio_a[15]),
    .I1(mr[17]),
    .I3(GND),
    .CIN(ratio_w_14_3) 
);
defparam ratio_w_15_s.ALU_MODE=0;
  ALU ratio_w_16_s (
    .SUM(ratio_w[16]),
    .COUT(ratio_w_16_3),
    .I0(ratio_a[16]),
    .I1(mr[18]),
    .I3(GND),
    .CIN(ratio_w_15_3) 
);
defparam ratio_w_16_s.ALU_MODE=0;
  ALU ratio_w_17_s (
    .SUM(ratio_w[17]),
    .COUT(ratio_w_17_3),
    .I0(ratio_a[17]),
    .I1(mr[19]),
    .I3(GND),
    .CIN(ratio_w_16_3) 
);
defparam ratio_w_17_s.ALU_MODE=0;
  ALU ratio_w_18_s (
    .SUM(ratio_w[18]),
    .COUT(ratio_w_18_3),
    .I0(ratio_a[18]),
    .I1(mr[20]),
    .I3(GND),
    .CIN(ratio_w_17_3) 
);
defparam ratio_w_18_s.ALU_MODE=0;
  ALU dp_lo_0_s (
    .SUM(dp_lo[0]),
    .COUT(dp_lo_0_3),
    .I0(lv_c[0]),
    .I1(lv_a[0]),
    .I3(GND),
    .CIN(VCC) 
);
defparam dp_lo_0_s.ALU_MODE=1;
  ALU dp_lo_1_s (
    .SUM(dp_lo[1]),
    .COUT(dp_lo_1_3),
    .I0(lv_c[1]),
    .I1(lv_a[1]),
    .I3(GND),
    .CIN(dp_lo_0_3) 
);
defparam dp_lo_1_s.ALU_MODE=1;
  ALU dp_lo_2_s (
    .SUM(dp_lo[2]),
    .COUT(dp_lo_2_3),
    .I0(lv_c[2]),
    .I1(lv_a[2]),
    .I3(GND),
    .CIN(dp_lo_1_3) 
);
defparam dp_lo_2_s.ALU_MODE=1;
  ALU dp_lo_3_s (
    .SUM(dp_lo[3]),
    .COUT(dp_lo_3_3),
    .I0(lv_c[3]),
    .I1(lv_a[3]),
    .I3(GND),
    .CIN(dp_lo_2_3) 
);
defparam dp_lo_3_s.ALU_MODE=1;
  ALU dp_lo_4_s (
    .SUM(dp_lo[4]),
    .COUT(dp_lo_4_3),
    .I0(lv_c[4]),
    .I1(lv_a[4]),
    .I3(GND),
    .CIN(dp_lo_3_3) 
);
defparam dp_lo_4_s.ALU_MODE=1;
  ALU dp_lo_5_s (
    .SUM(dp_lo[5]),
    .COUT(dp_lo_5_3),
    .I0(lv_c[5]),
    .I1(lv_a[5]),
    .I3(GND),
    .CIN(dp_lo_4_3) 
);
defparam dp_lo_5_s.ALU_MODE=1;
  ALU dp_lo_6_s (
    .SUM(dp_lo[6]),
    .COUT(dp_lo_6_3),
    .I0(lv_c[6]),
    .I1(lv_a[6]),
    .I3(GND),
    .CIN(dp_lo_5_3) 
);
defparam dp_lo_6_s.ALU_MODE=1;
  ALU dp_lo_7_s (
    .SUM(dp_lo[7]),
    .COUT(dp_lo_7_3),
    .I0(lv_c[7]),
    .I1(lv_a[7]),
    .I3(GND),
    .CIN(dp_lo_6_3) 
);
defparam dp_lo_7_s.ALU_MODE=1;
  ALU dp_lo_8_s (
    .SUM(dp_lo[8]),
    .COUT(dp_lo_8_3),
    .I0(lv_c[8]),
    .I1(lv_a[8]),
    .I3(GND),
    .CIN(dp_lo_7_3) 
);
defparam dp_lo_8_s.ALU_MODE=1;
  ALU dp_lo_9_s (
    .SUM(dp_lo[9]),
    .COUT(dp_lo_9_3),
    .I0(lv_c[9]),
    .I1(lv_a[9]),
    .I3(GND),
    .CIN(dp_lo_8_3) 
);
defparam dp_lo_9_s.ALU_MODE=1;
  ALU dp_lo_10_s (
    .SUM(dp_lo[10]),
    .COUT(dp_lo_10_3),
    .I0(lv_c[10]),
    .I1(lv_a[10]),
    .I3(GND),
    .CIN(dp_lo_9_3) 
);
defparam dp_lo_10_s.ALU_MODE=1;
  ALU dp_lo_11_s (
    .SUM(dp_lo[11]),
    .COUT(n301_13),
    .I0(lv_c[11]),
    .I1(lv_a[11]),
    .I3(GND),
    .CIN(dp_lo_10_3) 
);
defparam dp_lo_11_s.ALU_MODE=1;
  ALU dp_hi_0_s (
    .SUM(dp_hi[0]),
    .COUT(dp_hi_0_3),
    .I0(lv_d[0]),
    .I1(lv_b[0]),
    .I3(GND),
    .CIN(VCC) 
);
defparam dp_hi_0_s.ALU_MODE=1;
  ALU dp_hi_1_s (
    .SUM(dp_hi[1]),
    .COUT(dp_hi_1_3),
    .I0(lv_d[1]),
    .I1(lv_b[1]),
    .I3(GND),
    .CIN(dp_hi_0_3) 
);
defparam dp_hi_1_s.ALU_MODE=1;
  ALU dp_hi_2_s (
    .SUM(dp_hi[2]),
    .COUT(dp_hi_2_3),
    .I0(lv_d[2]),
    .I1(lv_b[2]),
    .I3(GND),
    .CIN(dp_hi_1_3) 
);
defparam dp_hi_2_s.ALU_MODE=1;
  ALU dp_hi_3_s (
    .SUM(dp_hi[3]),
    .COUT(dp_hi_3_3),
    .I0(lv_d[3]),
    .I1(lv_b[3]),
    .I3(GND),
    .CIN(dp_hi_2_3) 
);
defparam dp_hi_3_s.ALU_MODE=1;
  ALU dp_hi_4_s (
    .SUM(dp_hi[4]),
    .COUT(dp_hi_4_3),
    .I0(lv_d[4]),
    .I1(lv_b[4]),
    .I3(GND),
    .CIN(dp_hi_3_3) 
);
defparam dp_hi_4_s.ALU_MODE=1;
  ALU dp_hi_5_s (
    .SUM(dp_hi[5]),
    .COUT(dp_hi_5_3),
    .I0(lv_d[5]),
    .I1(lv_b[5]),
    .I3(GND),
    .CIN(dp_hi_4_3) 
);
defparam dp_hi_5_s.ALU_MODE=1;
  ALU dp_hi_6_s (
    .SUM(dp_hi[6]),
    .COUT(dp_hi_6_3),
    .I0(lv_d[6]),
    .I1(lv_b[6]),
    .I3(GND),
    .CIN(dp_hi_5_3) 
);
defparam dp_hi_6_s.ALU_MODE=1;
  ALU dp_hi_7_s (
    .SUM(dp_hi[7]),
    .COUT(dp_hi_7_3),
    .I0(lv_d[7]),
    .I1(lv_b[7]),
    .I3(GND),
    .CIN(dp_hi_6_3) 
);
defparam dp_hi_7_s.ALU_MODE=1;
  ALU dp_hi_8_s (
    .SUM(dp_hi[8]),
    .COUT(dp_hi_8_3),
    .I0(lv_d[8]),
    .I1(lv_b[8]),
    .I3(GND),
    .CIN(dp_hi_7_3) 
);
defparam dp_hi_8_s.ALU_MODE=1;
  ALU dp_hi_9_s (
    .SUM(dp_hi[9]),
    .COUT(dp_hi_9_3),
    .I0(lv_d[9]),
    .I1(lv_b[9]),
    .I3(GND),
    .CIN(dp_hi_8_3) 
);
defparam dp_hi_9_s.ALU_MODE=1;
  ALU dp_hi_10_s (
    .SUM(dp_hi[10]),
    .COUT(dp_hi_10_3),
    .I0(lv_d[10]),
    .I1(lv_b[10]),
    .I3(GND),
    .CIN(dp_hi_9_3) 
);
defparam dp_hi_10_s.ALU_MODE=1;
  ALU dp_hi_11_s (
    .SUM(dp_hi[11]),
    .COUT(n327_13),
    .I0(lv_d[11]),
    .I1(lv_b[11]),
    .I3(GND),
    .CIN(dp_hi_10_3) 
);
defparam dp_hi_11_s.ALU_MODE=1;
  ALU n353_s (
    .SUM(n353_0_SUM),
    .COUT(n353_3),
    .I0(dp_lo[1]),
    .I1(dp_lo[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam n353_s.ALU_MODE=0;
  ALU n352_s (
    .SUM(n352_2),
    .COUT(n352_3),
    .I0(dp_lo[2]),
    .I1(dp_lo[1]),
    .I3(GND),
    .CIN(n353_3) 
);
defparam n352_s.ALU_MODE=0;
  ALU n351_s (
    .SUM(n351_2),
    .COUT(n351_3),
    .I0(dp_lo[3]),
    .I1(dp_lo[2]),
    .I3(GND),
    .CIN(n352_3) 
);
defparam n351_s.ALU_MODE=0;
  ALU n350_s (
    .SUM(n350_2),
    .COUT(n350_3),
    .I0(dp_lo[4]),
    .I1(dp_lo[3]),
    .I3(GND),
    .CIN(n351_3) 
);
defparam n350_s.ALU_MODE=0;
  ALU n349_s (
    .SUM(n349_2),
    .COUT(n349_3),
    .I0(dp_lo[5]),
    .I1(dp_lo[4]),
    .I3(GND),
    .CIN(n350_3) 
);
defparam n349_s.ALU_MODE=0;
  ALU n348_s (
    .SUM(n348_2),
    .COUT(n348_3),
    .I0(dp_lo[6]),
    .I1(dp_lo[5]),
    .I3(GND),
    .CIN(n349_3) 
);
defparam n348_s.ALU_MODE=0;
  ALU n347_s (
    .SUM(n347_2),
    .COUT(n347_3),
    .I0(dp_lo[7]),
    .I1(dp_lo[6]),
    .I3(GND),
    .CIN(n348_3) 
);
defparam n347_s.ALU_MODE=0;
  ALU n346_s (
    .SUM(n346_2),
    .COUT(n346_3),
    .I0(dp_lo[8]),
    .I1(dp_lo[7]),
    .I3(GND),
    .CIN(n347_3) 
);
defparam n346_s.ALU_MODE=0;
  ALU n345_s (
    .SUM(n345_2),
    .COUT(n345_3),
    .I0(dp_lo[9]),
    .I1(dp_lo[8]),
    .I3(GND),
    .CIN(n346_3) 
);
defparam n345_s.ALU_MODE=0;
  ALU n344_s (
    .SUM(n344_2),
    .COUT(n344_3),
    .I0(dp_lo[10]),
    .I1(dp_lo[9]),
    .I3(GND),
    .CIN(n345_3) 
);
defparam n344_s.ALU_MODE=0;
  ALU n343_s (
    .SUM(n343_2),
    .COUT(n343_3),
    .I0(dp_lo[11]),
    .I1(dp_lo[10]),
    .I3(GND),
    .CIN(n344_3) 
);
defparam n343_s.ALU_MODE=0;
  ALU n342_s (
    .SUM(n342_2),
    .COUT(n341_8),
    .I0(n301_16),
    .I1(dp_lo[11]),
    .I3(GND),
    .CIN(n343_3) 
);
defparam n342_s.ALU_MODE=0;
  ALU n391_s (
    .SUM(n391_0_SUM),
    .COUT(n391_3),
    .I0(dp_hi[1]),
    .I1(dp_hi[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam n391_s.ALU_MODE=0;
  ALU n390_s (
    .SUM(n390_2),
    .COUT(n390_3),
    .I0(dp_hi[2]),
    .I1(dp_hi[1]),
    .I3(GND),
    .CIN(n391_3) 
);
defparam n390_s.ALU_MODE=0;
  ALU n389_s (
    .SUM(n389_2),
    .COUT(n389_3),
    .I0(dp_hi[3]),
    .I1(dp_hi[2]),
    .I3(GND),
    .CIN(n390_3) 
);
defparam n389_s.ALU_MODE=0;
  ALU n388_s (
    .SUM(n388_2),
    .COUT(n388_3),
    .I0(dp_hi[4]),
    .I1(dp_hi[3]),
    .I3(GND),
    .CIN(n389_3) 
);
defparam n388_s.ALU_MODE=0;
  ALU n387_s (
    .SUM(n387_2),
    .COUT(n387_3),
    .I0(dp_hi[5]),
    .I1(dp_hi[4]),
    .I3(GND),
    .CIN(n388_3) 
);
defparam n387_s.ALU_MODE=0;
  ALU n386_s (
    .SUM(n386_2),
    .COUT(n386_3),
    .I0(dp_hi[6]),
    .I1(dp_hi[5]),
    .I3(GND),
    .CIN(n387_3) 
);
defparam n386_s.ALU_MODE=0;
  ALU n385_s (
    .SUM(n385_2),
    .COUT(n385_3),
    .I0(dp_hi[7]),
    .I1(dp_hi[6]),
    .I3(GND),
    .CIN(n386_3) 
);
defparam n385_s.ALU_MODE=0;
  ALU n384_s (
    .SUM(n384_2),
    .COUT(n384_3),
    .I0(dp_hi[8]),
    .I1(dp_hi[7]),
    .I3(GND),
    .CIN(n385_3) 
);
defparam n384_s.ALU_MODE=0;
  ALU n383_s (
    .SUM(n383_2),
    .COUT(n383_3),
    .I0(dp_hi[9]),
    .I1(dp_hi[8]),
    .I3(GND),
    .CIN(n384_3) 
);
defparam n383_s.ALU_MODE=0;
  ALU n382_s (
    .SUM(n382_2),
    .COUT(n382_3),
    .I0(dp_hi[10]),
    .I1(dp_hi[9]),
    .I3(GND),
    .CIN(n383_3) 
);
defparam n382_s.ALU_MODE=0;
  ALU n381_s (
    .SUM(n381_2),
    .COUT(n381_3),
    .I0(dp_hi[11]),
    .I1(dp_hi[10]),
    .I3(GND),
    .CIN(n382_3) 
);
defparam n381_s.ALU_MODE=0;
  ALU n380_s (
    .SUM(n380_2),
    .COUT(n379_8),
    .I0(n327_16),
    .I1(dp_hi[11]),
    .I3(GND),
    .CIN(n381_3) 
);
defparam n380_s.ALU_MODE=0;
  ALU dr_0_s (
    .SUM(dr[0]),
    .COUT(dr_0_3),
    .I0(ratio_q[0]),
    .I1(ratio_a[0]),
    .I3(GND),
    .CIN(VCC) 
);
defparam dr_0_s.ALU_MODE=1;
  ALU dr_1_s (
    .SUM(dr[1]),
    .COUT(dr_1_3),
    .I0(ratio_q[1]),
    .I1(ratio_a[1]),
    .I3(GND),
    .CIN(dr_0_3) 
);
defparam dr_1_s.ALU_MODE=1;
  ALU dr_2_s (
    .SUM(dr[2]),
    .COUT(dr_2_3),
    .I0(ratio_q[2]),
    .I1(ratio_a[2]),
    .I3(GND),
    .CIN(dr_1_3) 
);
defparam dr_2_s.ALU_MODE=1;
  ALU dr_3_s (
    .SUM(dr[3]),
    .COUT(dr_3_3),
    .I0(ratio_q[3]),
    .I1(ratio_a[3]),
    .I3(GND),
    .CIN(dr_2_3) 
);
defparam dr_3_s.ALU_MODE=1;
  ALU dr_4_s (
    .SUM(dr[4]),
    .COUT(dr_4_3),
    .I0(ratio_q[4]),
    .I1(ratio_a[4]),
    .I3(GND),
    .CIN(dr_3_3) 
);
defparam dr_4_s.ALU_MODE=1;
  ALU dr_5_s (
    .SUM(dr[5]),
    .COUT(dr_5_3),
    .I0(ratio_q[5]),
    .I1(ratio_a[5]),
    .I3(GND),
    .CIN(dr_4_3) 
);
defparam dr_5_s.ALU_MODE=1;
  ALU dr_6_s (
    .SUM(dr[6]),
    .COUT(dr_6_3),
    .I0(ratio_q[6]),
    .I1(ratio_a[6]),
    .I3(GND),
    .CIN(dr_5_3) 
);
defparam dr_6_s.ALU_MODE=1;
  ALU dr_7_s (
    .SUM(dr[7]),
    .COUT(dr_7_3),
    .I0(ratio_q[7]),
    .I1(ratio_a[7]),
    .I3(GND),
    .CIN(dr_6_3) 
);
defparam dr_7_s.ALU_MODE=1;
  ALU dr_8_s (
    .SUM(dr[8]),
    .COUT(dr_8_3),
    .I0(ratio_q[8]),
    .I1(ratio_a[8]),
    .I3(GND),
    .CIN(dr_7_3) 
);
defparam dr_8_s.ALU_MODE=1;
  ALU dr_9_s (
    .SUM(dr[9]),
    .COUT(dr_9_3),
    .I0(ratio_q[9]),
    .I1(ratio_a[9]),
    .I3(GND),
    .CIN(dr_8_3) 
);
defparam dr_9_s.ALU_MODE=1;
  ALU dr_10_s (
    .SUM(dr[10]),
    .COUT(dr_10_3),
    .I0(ratio_q[10]),
    .I1(ratio_a[10]),
    .I3(GND),
    .CIN(dr_9_3) 
);
defparam dr_10_s.ALU_MODE=1;
  ALU dr_11_s (
    .SUM(dr[11]),
    .COUT(dr_11_3),
    .I0(ratio_q[11]),
    .I1(ratio_a[11]),
    .I3(GND),
    .CIN(dr_10_3) 
);
defparam dr_11_s.ALU_MODE=1;
  ALU dr_12_s (
    .SUM(dr[12]),
    .COUT(dr_12_3),
    .I0(ratio_q[12]),
    .I1(ratio_a[12]),
    .I3(GND),
    .CIN(dr_11_3) 
);
defparam dr_12_s.ALU_MODE=1;
  ALU dr_13_s (
    .SUM(dr[13]),
    .COUT(dr_13_3),
    .I0(ratio_q[13]),
    .I1(ratio_a[13]),
    .I3(GND),
    .CIN(dr_12_3) 
);
defparam dr_13_s.ALU_MODE=1;
  ALU dr_14_s (
    .SUM(dr[14]),
    .COUT(dr_14_3),
    .I0(ratio_q[14]),
    .I1(ratio_a[14]),
    .I3(GND),
    .CIN(dr_13_3) 
);
defparam dr_14_s.ALU_MODE=1;
  ALU dr_15_s (
    .SUM(dr[15]),
    .COUT(dr_15_3),
    .I0(ratio_q[15]),
    .I1(ratio_a[15]),
    .I3(GND),
    .CIN(dr_14_3) 
);
defparam dr_15_s.ALU_MODE=1;
  ALU dr_16_s (
    .SUM(dr[16]),
    .COUT(dr_16_3),
    .I0(ratio_q[16]),
    .I1(ratio_a[16]),
    .I3(GND),
    .CIN(dr_15_3) 
);
defparam dr_16_s.ALU_MODE=1;
  ALU dr_17_s (
    .SUM(dr[17]),
    .COUT(dr_17_3),
    .I0(ratio_q[17]),
    .I1(ratio_a[17]),
    .I3(GND),
    .CIN(dr_16_3) 
);
defparam dr_17_s.ALU_MODE=1;
  ALU dr_18_s (
    .SUM(dr[18]),
    .COUT(dr_18_3),
    .I0(ratio_q[18]),
    .I1(ratio_a[18]),
    .I3(GND),
    .CIN(dr_17_3) 
);
defparam dr_18_s.ALU_MODE=1;
  ALU dr_19_s (
    .SUM(dr[19]),
    .COUT(n619_11),
    .I0(ratio_q[19]),
    .I1(ratio_a[19]),
    .I3(GND),
    .CIN(dr_18_3) 
);
defparam dr_19_s.ALU_MODE=1;
  ALU n661_s (
    .SUM(n661_0_SUM),
    .COUT(n661_3),
    .I0(dr[1]),
    .I1(dr[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam n661_s.ALU_MODE=0;
  ALU n660_s (
    .SUM(n660_2),
    .COUT(n660_3),
    .I0(dr[2]),
    .I1(dr[1]),
    .I3(GND),
    .CIN(n661_3) 
);
defparam n660_s.ALU_MODE=0;
  ALU n659_s (
    .SUM(n659_2),
    .COUT(n659_3),
    .I0(dr[3]),
    .I1(dr[2]),
    .I3(GND),
    .CIN(n660_3) 
);
defparam n659_s.ALU_MODE=0;
  ALU n658_s (
    .SUM(n658_2),
    .COUT(n658_3),
    .I0(dr[4]),
    .I1(dr[3]),
    .I3(GND),
    .CIN(n659_3) 
);
defparam n658_s.ALU_MODE=0;
  ALU n657_s (
    .SUM(n657_2),
    .COUT(n657_3),
    .I0(dr[5]),
    .I1(dr[4]),
    .I3(GND),
    .CIN(n658_3) 
);
defparam n657_s.ALU_MODE=0;
  ALU n656_s (
    .SUM(n656_2),
    .COUT(n656_3),
    .I0(dr[6]),
    .I1(dr[5]),
    .I3(GND),
    .CIN(n657_3) 
);
defparam n656_s.ALU_MODE=0;
  ALU n655_s (
    .SUM(n655_2),
    .COUT(n655_3),
    .I0(dr[7]),
    .I1(dr[6]),
    .I3(GND),
    .CIN(n656_3) 
);
defparam n655_s.ALU_MODE=0;
  ALU n654_s (
    .SUM(n654_2),
    .COUT(n654_3),
    .I0(dr[8]),
    .I1(dr[7]),
    .I3(GND),
    .CIN(n655_3) 
);
defparam n654_s.ALU_MODE=0;
  ALU n653_s (
    .SUM(n653_2),
    .COUT(n653_3),
    .I0(dr[9]),
    .I1(dr[8]),
    .I3(GND),
    .CIN(n654_3) 
);
defparam n653_s.ALU_MODE=0;
  ALU n652_s (
    .SUM(n652_2),
    .COUT(n652_3),
    .I0(dr[10]),
    .I1(dr[9]),
    .I3(GND),
    .CIN(n653_3) 
);
defparam n652_s.ALU_MODE=0;
  ALU n651_s (
    .SUM(n651_2),
    .COUT(n651_3),
    .I0(dr[11]),
    .I1(dr[10]),
    .I3(GND),
    .CIN(n652_3) 
);
defparam n651_s.ALU_MODE=0;
  ALU n650_s (
    .SUM(n650_2),
    .COUT(n650_3),
    .I0(dr[12]),
    .I1(dr[11]),
    .I3(GND),
    .CIN(n651_3) 
);
defparam n650_s.ALU_MODE=0;
  ALU n649_s (
    .SUM(n649_2),
    .COUT(n649_3),
    .I0(dr[13]),
    .I1(dr[12]),
    .I3(GND),
    .CIN(n650_3) 
);
defparam n649_s.ALU_MODE=0;
  ALU n648_s (
    .SUM(n648_2),
    .COUT(n648_3),
    .I0(dr[14]),
    .I1(dr[13]),
    .I3(GND),
    .CIN(n649_3) 
);
defparam n648_s.ALU_MODE=0;
  ALU n647_s (
    .SUM(n647_2),
    .COUT(n647_3),
    .I0(dr[15]),
    .I1(dr[14]),
    .I3(GND),
    .CIN(n648_3) 
);
defparam n647_s.ALU_MODE=0;
  ALU n646_s (
    .SUM(n646_2),
    .COUT(n646_3),
    .I0(dr[16]),
    .I1(dr[15]),
    .I3(GND),
    .CIN(n647_3) 
);
defparam n646_s.ALU_MODE=0;
  ALU n645_s (
    .SUM(n645_2),
    .COUT(n645_3),
    .I0(dr[17]),
    .I1(dr[16]),
    .I3(GND),
    .CIN(n646_3) 
);
defparam n645_s.ALU_MODE=0;
  ALU n644_s (
    .SUM(n644_2),
    .COUT(n644_3),
    .I0(dr[18]),
    .I1(dr[17]),
    .I3(GND),
    .CIN(n645_3) 
);
defparam n644_s.ALU_MODE=0;
  ALU n643_s (
    .SUM(n643_2),
    .COUT(n643_3),
    .I0(dr[19]),
    .I1(dr[18]),
    .I3(GND),
    .CIN(n644_3) 
);
defparam n643_s.ALU_MODE=0;
  ALU n642_s (
    .SUM(n642_2),
    .COUT(n641_8),
    .I0(n619_14),
    .I1(dr[19]),
    .I3(GND),
    .CIN(n643_3) 
);
defparam n642_s.ALU_MODE=0;
  ALU lo_w_0_s (
    .SUM(lo_w[0]),
    .COUT(lo_w_0_3),
    .I0(lv_a[0]),
    .I1(mp_lo[2]),
    .I3(GND),
    .CIN(GND) 
);
defparam lo_w_0_s.ALU_MODE=0;
  ALU lo_w_1_s (
    .SUM(lo_w[1]),
    .COUT(lo_w_1_3),
    .I0(lv_a[1]),
    .I1(mp_lo[3]),
    .I3(GND),
    .CIN(lo_w_0_3) 
);
defparam lo_w_1_s.ALU_MODE=0;
  ALU lo_w_2_s (
    .SUM(lo_w[2]),
    .COUT(lo_w_2_3),
    .I0(lv_a[2]),
    .I1(mp_lo[4]),
    .I3(GND),
    .CIN(lo_w_1_3) 
);
defparam lo_w_2_s.ALU_MODE=0;
  ALU lo_w_3_s (
    .SUM(lo_w[3]),
    .COUT(lo_w_3_3),
    .I0(lv_a[3]),
    .I1(mp_lo[5]),
    .I3(GND),
    .CIN(lo_w_2_3) 
);
defparam lo_w_3_s.ALU_MODE=0;
  ALU lo_w_4_s (
    .SUM(lo_w[4]),
    .COUT(lo_w_4_3),
    .I0(lv_a[4]),
    .I1(mp_lo[6]),
    .I3(GND),
    .CIN(lo_w_3_3) 
);
defparam lo_w_4_s.ALU_MODE=0;
  ALU lo_w_5_s (
    .SUM(lo_w[5]),
    .COUT(lo_w_5_3),
    .I0(lv_a[5]),
    .I1(mp_lo[7]),
    .I3(GND),
    .CIN(lo_w_4_3) 
);
defparam lo_w_5_s.ALU_MODE=0;
  ALU lo_w_6_s (
    .SUM(lo_w[6]),
    .COUT(lo_w_6_3),
    .I0(lv_a[6]),
    .I1(mp_lo[8]),
    .I3(GND),
    .CIN(lo_w_5_3) 
);
defparam lo_w_6_s.ALU_MODE=0;
  ALU lo_w_7_s (
    .SUM(lo_w[7]),
    .COUT(lo_w_7_3),
    .I0(lv_a[7]),
    .I1(mp_lo[9]),
    .I3(GND),
    .CIN(lo_w_6_3) 
);
defparam lo_w_7_s.ALU_MODE=0;
  ALU lo_w_8_s (
    .SUM(lo_w[8]),
    .COUT(lo_w_8_3),
    .I0(lv_a[8]),
    .I1(mp_lo[10]),
    .I3(GND),
    .CIN(lo_w_7_3) 
);
defparam lo_w_8_s.ALU_MODE=0;
  ALU lo_w_9_s (
    .SUM(lo_w[9]),
    .COUT(lo_w_9_3),
    .I0(lv_a[9]),
    .I1(mp_lo[11]),
    .I3(GND),
    .CIN(lo_w_8_3) 
);
defparam lo_w_9_s.ALU_MODE=0;
  ALU lo_w_10_s (
    .SUM(lo_w[10]),
    .COUT(lo_w_10_3),
    .I0(lv_a[10]),
    .I1(mp_lo[12]),
    .I3(GND),
    .CIN(lo_w_9_3) 
);
defparam lo_w_10_s.ALU_MODE=0;
  ALU lo_w_11_s (
    .SUM(lo_w[11]),
    .COUT(lo_w_11_3),
    .I0(lv_a[11]),
    .I1(mp_lo[13]),
    .I3(GND),
    .CIN(lo_w_10_3) 
);
defparam lo_w_11_s.ALU_MODE=0;
  ALU lo_w_12_s (
    .SUM(lo_w[12]),
    .COUT(lo_w_12_3),
    .I0(GND),
    .I1(mp_lo_15_18),
    .I3(GND),
    .CIN(lo_w_11_3) 
);
defparam lo_w_12_s.ALU_MODE=0;
  ALU lo_w_13_s (
    .SUM(lo_w[13]),
    .COUT(lo_w_13_0_COUT),
    .I0(GND),
    .I1(mp_lo_15_18),
    .I3(GND),
    .CIN(lo_w_12_3) 
);
defparam lo_w_13_s.ALU_MODE=0;
  ALU xe_0_s (
    .SUM(xe_0_2),
    .COUT(xe_0_3),
    .I0(lo_r[0]),
    .I1(mv[8]),
    .I3(GND),
    .CIN(GND) 
);
defparam xe_0_s.ALU_MODE=0;
  ALU xe_1_s (
    .SUM(xe_1_2),
    .COUT(xe_1_3),
    .I0(lo_r[1]),
    .I1(mv[9]),
    .I3(GND),
    .CIN(xe_0_3) 
);
defparam xe_1_s.ALU_MODE=0;
  ALU xe_2_s (
    .SUM(xe_2_2),
    .COUT(xe_2_3),
    .I0(lo_r[2]),
    .I1(mv[10]),
    .I3(GND),
    .CIN(xe_1_3) 
);
defparam xe_2_s.ALU_MODE=0;
  ALU xe_3_s (
    .SUM(xe_3_2),
    .COUT(xe_3_3),
    .I0(lo_r[3]),
    .I1(mv[11]),
    .I3(GND),
    .CIN(xe_2_3) 
);
defparam xe_3_s.ALU_MODE=0;
  ALU xe_4_s (
    .SUM(xe_4_2),
    .COUT(xe_4_3),
    .I0(lo_r[4]),
    .I1(mv[12]),
    .I3(GND),
    .CIN(xe_3_3) 
);
defparam xe_4_s.ALU_MODE=0;
  ALU xe_5_s (
    .SUM(xe_5_2),
    .COUT(xe_5_3),
    .I0(lo_r[5]),
    .I1(mv[13]),
    .I3(GND),
    .CIN(xe_4_3) 
);
defparam xe_5_s.ALU_MODE=0;
  ALU xe_6_s (
    .SUM(xe_6_2),
    .COUT(xe_6_3),
    .I0(lo_r[6]),
    .I1(mv[14]),
    .I3(GND),
    .CIN(xe_5_3) 
);
defparam xe_6_s.ALU_MODE=0;
  ALU xe_7_s (
    .SUM(xe_7_2),
    .COUT(xe_7_3),
    .I0(lo_r[7]),
    .I1(mv[15]),
    .I3(GND),
    .CIN(xe_6_3) 
);
defparam xe_7_s.ALU_MODE=0;
  ALU xe_8_s (
    .SUM(xe_8_2),
    .COUT(xe_8_3),
    .I0(lo_r[8]),
    .I1(mv[16]),
    .I3(GND),
    .CIN(xe_7_3) 
);
defparam xe_8_s.ALU_MODE=0;
  ALU xe_9_s (
    .SUM(xe_9_2),
    .COUT(xe_9_3),
    .I0(lo_r[9]),
    .I1(mv[17]),
    .I3(GND),
    .CIN(xe_8_3) 
);
defparam xe_9_s.ALU_MODE=0;
  ALU xe_10_s (
    .SUM(xe_10_2),
    .COUT(xe_10_3),
    .I0(lo_r[10]),
    .I1(mv[18]),
    .I3(GND),
    .CIN(xe_9_3) 
);
defparam xe_10_s.ALU_MODE=0;
  ALU xe_11_s (
    .SUM(xe_11_2),
    .COUT(xe_11_3),
    .I0(lo_r[11]),
    .I1(mv[19]),
    .I3(GND),
    .CIN(xe_10_3) 
);
defparam xe_11_s.ALU_MODE=0;
  ALU xe_12_s (
    .SUM(xe_12_2),
    .COUT(xe_12_3),
    .I0(lo_r[12]),
    .I1(mv[20]),
    .I3(GND),
    .CIN(xe_11_3) 
);
defparam xe_12_s.ALU_MODE=0;
  ALU xe_13_s (
    .SUM(xe_13_2),
    .COUT(xe_13_3),
    .I0(lo_r[13]),
    .I1(mv[21]),
    .I3(GND),
    .CIN(xe_12_3) 
);
defparam xe_13_s.ALU_MODE=0;
  ALU xe_14_s (
    .SUM(xe_14_2),
    .COUT(xe_14_3),
    .I0(lo_r[13]),
    .I1(mv[22]),
    .I3(GND),
    .CIN(xe_13_3) 
);
defparam xe_14_s.ALU_MODE=0;
  ALU xe_15_s (
    .SUM(xe_15_2),
    .COUT(xe_15_3),
    .I0(lo_r[13]),
    .I1(mv[23]),
    .I3(GND),
    .CIN(xe_14_3) 
);
defparam xe_15_s.ALU_MODE=0;
  ALU xe_16_s (
    .SUM(xe_16_2),
    .COUT(xe_16_3),
    .I0(lo_r[13]),
    .I1(mv[24]),
    .I3(GND),
    .CIN(xe_15_3) 
);
defparam xe_16_s.ALU_MODE=0;
  ALU xe_17_s (
    .SUM(xe_17_2),
    .COUT(xe_17_3),
    .I0(lo_r[13]),
    .I1(mv[24]),
    .I3(GND),
    .CIN(xe_16_3) 
);
defparam xe_17_s.ALU_MODE=0;
  ALU xe_24_s (
    .SUM(xe_24_2),
    .COUT(xe_24_0_COUT),
    .I0(lo_r[13]),
    .I1(mv[24]),
    .I3(GND),
    .CIN(xe_17_3) 
);
defparam xe_24_s.ALU_MODE=0;
  ALU xe_0_s0 (
    .SUM(xe[0]),
    .COUT(xe_0_5),
    .I0(xe_0_2),
    .I1(extra_att[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam xe_0_s0.ALU_MODE=0;
  ALU xe_1_s0 (
    .SUM(xe[1]),
    .COUT(xe_1_5),
    .I0(xe_1_2),
    .I1(extra_att[1]),
    .I3(GND),
    .CIN(xe_0_5) 
);
defparam xe_1_s0.ALU_MODE=0;
  ALU xe_2_s0 (
    .SUM(xe[2]),
    .COUT(xe_2_5),
    .I0(xe_2_2),
    .I1(extra_att[2]),
    .I3(GND),
    .CIN(xe_1_5) 
);
defparam xe_2_s0.ALU_MODE=0;
  ALU xe_3_s0 (
    .SUM(xe[3]),
    .COUT(xe_3_5),
    .I0(xe_3_2),
    .I1(extra_att[3]),
    .I3(GND),
    .CIN(xe_2_5) 
);
defparam xe_3_s0.ALU_MODE=0;
  ALU xe_4_s0 (
    .SUM(xe[4]),
    .COUT(xe_4_5),
    .I0(xe_4_2),
    .I1(extra_att[4]),
    .I3(GND),
    .CIN(xe_3_5) 
);
defparam xe_4_s0.ALU_MODE=0;
  ALU xe_5_s0 (
    .SUM(xe[5]),
    .COUT(xe_5_5),
    .I0(xe_5_2),
    .I1(extra_att[5]),
    .I3(GND),
    .CIN(xe_4_5) 
);
defparam xe_5_s0.ALU_MODE=0;
  ALU xe_6_s0 (
    .SUM(xe[6]),
    .COUT(xe_6_5),
    .I0(xe_6_2),
    .I1(extra_att[6]),
    .I3(GND),
    .CIN(xe_5_5) 
);
defparam xe_6_s0.ALU_MODE=0;
  ALU xe_7_s0 (
    .SUM(xe[7]),
    .COUT(xe_7_5),
    .I0(xe_7_2),
    .I1(extra_att[7]),
    .I3(GND),
    .CIN(xe_6_5) 
);
defparam xe_7_s0.ALU_MODE=0;
  ALU xe_8_s0 (
    .SUM(xe[8]),
    .COUT(xe_8_5),
    .I0(xe_8_2),
    .I1(extra_att[8]),
    .I3(GND),
    .CIN(xe_7_5) 
);
defparam xe_8_s0.ALU_MODE=0;
  ALU xe_9_s0 (
    .SUM(xe[9]),
    .COUT(xe_9_5),
    .I0(xe_9_2),
    .I1(extra_att[9]),
    .I3(GND),
    .CIN(xe_8_5) 
);
defparam xe_9_s0.ALU_MODE=0;
  ALU xe_10_s0 (
    .SUM(xe[10]),
    .COUT(xe_10_5),
    .I0(xe_10_2),
    .I1(extra_att[10]),
    .I3(GND),
    .CIN(xe_9_5) 
);
defparam xe_10_s0.ALU_MODE=0;
  ALU xe_11_s0 (
    .SUM(xe[11]),
    .COUT(xe_11_5),
    .I0(xe_11_2),
    .I1(extra_att[11]),
    .I3(GND),
    .CIN(xe_10_5) 
);
defparam xe_11_s0.ALU_MODE=0;
  ALU xe_12_s0 (
    .SUM(xe[12]),
    .COUT(xe_12_5),
    .I0(xe_12_2),
    .I1(extra_att[12]),
    .I3(GND),
    .CIN(xe_11_5) 
);
defparam xe_12_s0.ALU_MODE=0;
  ALU xe_13_s0 (
    .SUM(xe[13]),
    .COUT(xe_13_5),
    .I0(xe_13_2),
    .I1(GND),
    .I3(GND),
    .CIN(xe_12_5) 
);
defparam xe_13_s0.ALU_MODE=0;
  ALU xe_14_s0 (
    .SUM(xe[14]),
    .COUT(xe_14_5),
    .I0(xe_14_2),
    .I1(GND),
    .I3(GND),
    .CIN(xe_13_5) 
);
defparam xe_14_s0.ALU_MODE=0;
  ALU xe_15_s0 (
    .SUM(xe[15]),
    .COUT(xe_15_5),
    .I0(xe_15_2),
    .I1(GND),
    .I3(GND),
    .CIN(xe_14_5) 
);
defparam xe_15_s0.ALU_MODE=0;
  ALU xe_16_s0 (
    .SUM(xe[16]),
    .COUT(xe_16_5),
    .I0(xe_16_2),
    .I1(GND),
    .I3(GND),
    .CIN(xe_15_5) 
);
defparam xe_16_s0.ALU_MODE=0;
  ALU xe_17_s0 (
    .SUM(xe[17]),
    .COUT(xe_17_5),
    .I0(xe_17_2),
    .I1(GND),
    .I3(GND),
    .CIN(xe_16_5) 
);
defparam xe_17_s0.ALU_MODE=0;
  ALU xe_24_s0 (
    .SUM(xe[24]),
    .COUT(xe_24_1_COUT),
    .I0(xe_24_2),
    .I1(GND),
    .I3(GND),
    .CIN(xe_17_5) 
);
defparam xe_24_s0.ALU_MODE=0;
  MUX2_LUT8 n839_s31 (
    .O(n839_35),
    .I0(n839_37),
    .I1(n839_39),
    .S0(voice_r_0[4]) 
);
  MUX2_LUT7 n839_s116 (
    .O(n839_37),
    .I0(n839_41),
    .I1(n839_43),
    .S0(voice_r[3]) 
);
  MUX2_LUT7 n839_s117 (
    .O(n839_39),
    .I0(n839_45),
    .I1(n839_47),
    .S0(voice_r[3]) 
);
  MUX2_LUT6 n839_s118 (
    .O(n839_41),
    .I0(n839_49),
    .I1(n839_51),
    .S0(voice_r_0[2]) 
);
  MUX2_LUT6 n839_s119 (
    .O(n839_43),
    .I0(n839_53),
    .I1(n839_55),
    .S0(voice_r_0[2]) 
);
  MUX2_LUT6 n839_s120 (
    .O(n839_45),
    .I0(n839_57),
    .I1(n839_59),
    .S0(voice_r_0[2]) 
);
  MUX2_LUT6 n839_s121 (
    .O(n839_47),
    .I0(n839_61),
    .I1(n839_63),
    .S0(voice_r_0[2]) 
);
  MUX2_LUT5 n839_s122 (
    .O(n839_49),
    .I0(n839_65),
    .I1(n839_67),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s123 (
    .O(n839_51),
    .I0(n839_69),
    .I1(n839_71),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s124 (
    .O(n839_53),
    .I0(n839_73),
    .I1(n839_75),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s125 (
    .O(n839_55),
    .I0(n839_77),
    .I1(n839_79),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s126 (
    .O(n839_57),
    .I0(n839_81),
    .I1(n839_83),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s127 (
    .O(n839_59),
    .I0(n839_85),
    .I1(n839_87),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s128 (
    .O(n839_61),
    .I0(n839_89),
    .I1(n839_91),
    .S0(voice_r_0[1]) 
);
  MUX2_LUT5 n839_s129 (
    .O(n839_63),
    .I0(n839_93),
    .I1(n839_95),
    .S0(voice_r_0[1]) 
);
  INV n301_s9 (
    .O(n301_16),
    .I(n301_13) 
);
  INV n327_s9 (
    .O(n327_16),
    .I(n327_13) 
);
  INV n619_s7 (
    .O(n619_14),
    .I(n619_11) 
);
  INV soft_steps_3_s3 (
    .O(soft_steps_3_8),
    .I(vel_r[6]) 
);
  piano_level_rom u_level_rom (
    .clk_12m288(clk_12m288),
    .level_addr(level_addr[14:0]),
    .level_q(level_q[11:0])
);
  piano_ratio_rom u_ratio_rom (
    .clk_12m288(clk_12m288),
    .slot(slot[3:0]),
    .ratio_addr(ratio_addr[8:4]),
    .ratio_q(ratio_q[19:0])
);
  piano_note_rom u_note_rom (
    .clk_12m288(clk_12m288),
    .note_r_0(note_r[0]),
    .note_r_1(note_r[1]),
    .note_r_2(note_r[2]),
    .note_r_3(note_r[3]),
    .note_r_5(note_r[5]),
    .note_r_6(note_r[6]),
    .note_q(note_q[12:0])
);
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
endmodule
module piano_note_rom (
  clk_12m288,
  note_r_0,
  note_r_1,
  note_r_2,
  note_r_3,
  note_r_5,
  note_r_6,
  note_q
)
;
input clk_12m288;
input note_r_0;
input note_r_1;
input note_r_2;
input note_r_3;
input note_r_5;
input note_r_6;
output [12:0] note_q;
wire [31:13] DO;
wire VCC;
wire GND;
  pROM note_q_0_s (
    .DO({DO[31:13],note_q[12:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({GND,GND,GND,note_r_6,note_r_5,note_r_5,note_r_3,note_r_2,note_r_1,note_r_0,GND,GND,VCC,VCC}) 
);
defparam note_q_0_s.BIT_WIDTH=16;
defparam note_q_0_s.INIT_RAM_00=256'h0881088108810881088108810881088108810881088108810881088108810881;
defparam note_q_0_s.INIT_RAM_01=256'h0881088108810881088108810881088108810881088108810881088108810881;
defparam note_q_0_s.INIT_RAM_02=256'h0B080ABE0A770A3409F509B8097E0947091208E008AF08810881088108810881;
defparam note_q_0_s.INIT_RAM_03=256'h11E71198114C110210540FB30F1E0E940E130D9B0D2B0CC20C5F0C010BAA0B57;
defparam note_q_0_s.INIT_RAM_04=256'h18E4184C17BC173116AD162F15B6154314D41469140213A0134112E6128E1239;
defparam note_q_0_s.INIT_RAM_05=256'h0245024502450245034505DD1C591C591C591C591C591C591B951ADB1A2B1983;
defparam note_q_0_s.INIT_RAM_06=256'h0245024502450245024502450245024502450245024502450245024502450245;
defparam note_q_0_s.INIT_RAM_07=256'h0245024502450245024502450245024502450245024502450245024502450245;
defparam note_q_0_s.READ_MODE=1'b0;
defparam note_q_0_s.RESET_MODE="SYNC";
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
endmodule
module piano_ratio_rom (
  clk_12m288,
  slot,
  ratio_addr,
  ratio_q
)
;
input clk_12m288;
input [3:0] slot;
input [8:4] ratio_addr;
output [19:0] ratio_q;
wire [31:20] DO;
wire VCC;
wire GND;
  pROM ratio_q_0_s (
    .DO({DO[31:20],ratio_q[19:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({ratio_addr[8:4],slot[3:0],GND,VCC,VCC,VCC,VCC}) 
);
defparam ratio_q_0_s.BIT_WIDTH=32;
defparam ratio_q_0_s.INIT_RAM_00=256'h0003FED100037D810002FCEC00027C330001FC2B00017D230000FE3B00007F8F;
defparam ratio_q_0_s.INIT_RAM_01=256'h000000000007A38400071B4C000694C400060D6800058A5A000506700004820F;
defparam ratio_q_0_s.INIT_RAM_02=256'h0003FD0C00037C790002FC5000027C760001FCDD00017D780000FE3B00007F17;
defparam ratio_q_0_s.INIT_RAM_03=256'h0000000000078F4A00070A900006863C000603980005815E0004FF0700047E11;
defparam ratio_q_0_s.INIT_RAM_04=256'h000402F600037F0E0002FF2200027F840001FF6900017F580000FEAC00007F9D;
defparam ratio_q_0_s.INIT_RAM_05=256'h00000000000794E3000710D200068D00000609D50005857200050378000482BA;
defparam ratio_q_0_s.INIT_RAM_06=256'h0004038E0003822A0003007700027FE20002000000017D940000FED200007FA5;
defparam ratio_q_0_s.INIT_RAM_07=256'h0000000000079BA00007160D00068D0000060E4D00058A5A000507ED00048565;
defparam ratio_q_0_s.INIT_RAM_08=256'h000404BE000383B8000302B00002815D0002012F0001803B00010026000080BE;
defparam ratio_q_0_s.INIT_RAM_09=256'h0000000000079CC000071826000693CB00060E4D00058BFE0005096A00048813;
defparam ratio_q_0_s.INIT_RAM_0A=256'h000404BE00038333000302B00002815D000200E3000180740000FFB400008000;
defparam ratio_q_0_s.INIT_RAM_0B=256'h0000000000079BA00007171A000692D200060E4D00058BFE000508AB00048767;
defparam ratio_q_0_s.INIT_RAM_0C=256'h000404BE000383B8000302B00002821B0002017B0001803B0001004C00008013;
defparam ratio_q_0_s.INIT_RAM_0D=256'h0000000000079A800007160D000691DA00060E4D00058BFE000508AB00048813;
defparam ratio_q_0_s.INIT_RAM_0E=256'h0004071F000386530003047800028338000202AB000181580001015600008098;
defparam ratio_q_0_s.INIT_RAM_0F=256'h000000000007A5C70007209000069A9E00061662000591BF00050DE400048AC2;
defparam ratio_q_0_s.INIT_RAM_10=256'h00040A1B000387E3000305CF000283F6000202F7000181CA0001013000007FED;
defparam ratio_q_0_s.INIT_RAM_11=256'h000000000007B36500072B210006A17700061CB2000596B20005126200048E1F;
defparam ratio_q_0_s.INIT_RAM_12=256'h00040C7F000388EF000305CF000283F60002025F00018191000100BE0000804C;
defparam ratio_q_0_s.INIT_RAM_13=256'h000000000007C6D900073A080006AF40000625C300059D52000517A5000490D1;
defparam ratio_q_0_s.INIT_RAM_14=256'h0004128000038DA6000308F2000285D300020390000181CA0001004C000080BE;
defparam ratio_q_0_s.INIT_RAM_15=256'h000000000007EBFD000759480006C3220006380C0005AD2F0005223A000498F2;
defparam ratio_q_0_s.INIT_RAM_16=256'h00041925000391DD00030C17000287B100020475000182AE0001010A00008098;
defparam ratio_q_0_s.INIT_RAM_17=256'h000000000008156800077C610006E06000064E460005BD3800052FF70004A330;
defparam ratio_q_0_s.INIT_RAM_18=256'h000423800003983800030FB4000289910002050D0001823C000100E400008039;
defparam ratio_q_0_s.INIT_RAM_19=256'h00000000000870AB0007BA3D0007171A00068B100005DB39000546240004B1AD;
defparam ratio_q_0_s.INIT_RAM_1A=256'h00042C1A00039D8D000312E100028AB1000205F3000183210001015600008085;
defparam ratio_q_0_s.INIT_RAM_1B=256'h000000000008858D0007D3D5000729390006850D0005E6B20005472D0004BC22;
defparam ratio_q_0_s.INIT_RAM_1C=256'h00043EC60003A73900031B1B0002905B000208590001843F000101C800008098;
defparam ratio_q_0_s.INIT_RAM_1D=256'h0000000000091FF000084EB3000789A10006CF7200061EF80005771D0004D709;
defparam ratio_q_0_s.INIT_RAM_1E=256'h00046C920003C7A500032C94000299E700020C93000184B20001021400008000;
defparam ratio_q_0_s.INIT_RAM_1F=256'h00000000000000000000000000087D7A000788630006A8710005DACC00051CEC;
defparam ratio_q_0_s.INIT_RAM_20=256'h00048F3E0003DEF500033B740002A271000212FA00018645000102AD000080BE;
defparam ratio_q_0_s.INIT_RAM_21=256'h000000000000000000000000000000000000000000070818000620B700054EDD;
defparam ratio_q_0_s.INIT_RAM_22=256'h0004DC9B0004116C00035AB90002B48600021AB300018DC8000102F900008130;
defparam ratio_q_0_s.INIT_RAM_23=256'h000000000000000000000000000000000000000000000000000000000005C0F3;
defparam ratio_q_0_s.INIT_RAM_24=256'h000000000004428E000377F30002C47B000222380001908C00010406000080F7;
defparam ratio_q_0_s.INIT_RAM_26=256'h000000000000000000000000000315C10002476600019B3F0001064900007FB4;
defparam ratio_q_0_s.INIT_RAM_28=256'h0000000000000000000000000000000000023CB6000198A4000106E5000080AB;
defparam ratio_q_0_s.READ_MODE=1'b0;
defparam ratio_q_0_s.RESET_MODE="SYNC";
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
endmodule