module post_xy_source (
  clk_12m288,
  n114_32,
  u_synth_top_4_1,
  u_synth_top_5_1,
  u_synth_top_6_1,
  u_synth_top_7_1,
  u_synth_top_15_1,
  u_synth_top_14_1,
  u_synth_top_13_1,
  u_synth_top_12_1,
  u_synth_top_11_1,
  u_synth_top_10_1,
  u_synth_top_9_1,
  u_synth_top_8_1,
  visual_pcm_valid,
  audio_pa_en_d,
  left_reg_15_11,
  visual_pcm,
  paired_valid,
  paired_pcm,
  paired_x,
  paired_y
)
;
input clk_12m288;
input n114_32;
input u_synth_top_4_1;
input u_synth_top_5_1;
input u_synth_top_6_1;
input u_synth_top_7_1;
input u_synth_top_15_1;
input u_synth_top_14_1;
input u_synth_top_13_1;
input u_synth_top_12_1;
input u_synth_top_11_1;
input u_synth_top_10_1;
input u_synth_top_9_1;
input u_synth_top_8_1;
input visual_pcm_valid;
input audio_pa_en_d;
input left_reg_15_11;
input [23:20] visual_pcm;
output paired_valid;
output [15:8] paired_pcm;
output [15:0] paired_x;
output [15:0] paired_y;
wire n1352_7;
wire n1351_7;
wire n1350_7;
wire n1349_7;
wire n1348_7;
wire n1347_7;
wire n1346_7;
wire n1345_7;
wire n1344_7;
wire n1343_7;
wire n1342_7;
wire n1341_7;
wire n1340_7;
wire n1339_7;
wire n1338_7;
wire n1337_7;
wire n1336_7;
wire n1335_7;
wire n1334_7;
wire n1333_7;
wire n1332_7;
wire n1331_7;
wire n1330_7;
wire n1329_7;
wire n1328_7;
wire n1327_7;
wire n1326_7;
wire n1325_7;
wire n1324_7;
wire n1323_7;
wire n1322_7;
wire n1321_7;
wire n1320_7;
wire n1319_7;
wire n1318_7;
wire n1317_7;
wire n1316_7;
wire n1315_7;
wire n1314_7;
wire n1313_7;
wire n1312_7;
wire n1311_7;
wire n1310_7;
wire n1309_7;
wire n1308_7;
wire n1307_7;
wire n1306_7;
wire n1305_7;
wire n1304_7;
wire n1303_7;
wire n1302_7;
wire n1301_7;
wire n1300_7;
wire n1299_7;
wire n1298_7;
wire n1297_7;
wire n1296_7;
wire n1295_7;
wire n1294_7;
wire n1293_7;
wire n1292_7;
wire n1291_7;
wire n1290_7;
wire n1289_7;
wire n1288_7;
wire n1287_7;
wire n1286_7;
wire n1285_7;
wire n1284_7;
wire n1283_7;
wire n1282_7;
wire n1281_7;
wire n1280_7;
wire n1279_7;
wire n1278_7;
wire n1277_7;
wire n1276_7;
wire n1275_7;
wire n1274_7;
wire n1273_7;
wire n1272_7;
wire n1271_7;
wire n1270_7;
wire n1269_7;
wire n1268_7;
wire n1267_7;
wire n1266_7;
wire n1265_7;
wire n1264_7;
wire n1263_7;
wire n1262_7;
wire n1261_7;
wire n1260_7;
wire n1259_7;
wire n1258_7;
wire n1257_7;
wire n1256_7;
wire n1255_7;
wire n1254_7;
wire n1253_7;
wire n1252_7;
wire n1251_7;
wire n1250_7;
wire n1249_7;
wire n1248_7;
wire n1247_7;
wire n1246_7;
wire n1245_7;
wire n1244_7;
wire n1243_7;
wire n1242_7;
wire n1241_7;
wire n1240_7;
wire n1239_7;
wire n1238_7;
wire n1237_7;
wire n1236_7;
wire n1235_7;
wire n1234_7;
wire n1233_7;
wire n1232_7;
wire n1231_7;
wire n1230_7;
wire n1229_7;
wire n1228_7;
wire n1227_7;
wire n1226_7;
wire n1225_7;
wire n1224_7;
wire n1223_7;
wire n1222_7;
wire n1221_7;
wire n1220_7;
wire n1219_7;
wire n1218_7;
wire n1217_7;
wire n1216_7;
wire n1215_7;
wire n1214_7;
wire n1213_7;
wire n1212_7;
wire n1211_7;
wire n1210_7;
wire n1209_7;
wire n1208_7;
wire n1207_7;
wire n1206_7;
wire n1205_7;
wire n1204_7;
wire n1203_7;
wire n1202_7;
wire n1201_7;
wire n1200_7;
wire n1199_7;
wire n1198_7;
wire n1197_7;
wire n1196_7;
wire n1195_7;
wire n1194_7;
wire n1193_7;
wire n1176_7;
wire n1175_7;
wire n1174_7;
wire n1173_7;
wire n1172_7;
wire n1170_7;
wire n1169_7;
wire n1718_6;
wire n1099_6;
wire n1098_6;
wire n1097_6;
wire n1096_6;
wire n1095_6;
wire n1094_6;
wire n1093_6;
wire n1092_6;
wire n1091_6;
wire n1090_6;
wire n1089_6;
wire n1088_6;
wire n1087_6;
wire n1086_6;
wire n1085_6;
wire addr0_9_6;
wire addr0_8_6;
wire addr0_7_6;
wire addr0_5_6;
wire addr0_2_6;
wire n1173_8;
wire n1718_7;
wire n1718_8;
wire n1718_9;
wire n1099_7;
wire n1099_8;
wire addr1_5_13;
wire addr2_6_13;
wire addr2_8_13;
wire addr3_3_13;
wire n2972_6;
wire n2972_7;
wire n1099_9;
wire n1099_10;
wire n1099_11;
wire n1099_12;
wire n1099_13;
wire n1099_14;
wire addr1_8_14;
wire addr0_3_8;
wire n1172_10;
wire n3004_6;
wire n2972_9;
wire addr1_8_16;
wire addr1_6_16;
wire addr1_6_18;
wire addr3_8_15;
wire addr3_6_15;
wire n850_8;
wire addr0_4_8;
wire addr0_6_8;
wire n1170_10;
wire n1171_10;
wire sum0_39_19;
wire accept_16;
wire n2960_8;
wire accept;
wire n837_12;
wire index_7_10;
wire busy;
wire total_0_1;
wire total_0_2;
wire total_1_1;
wire total_1_2;
wire total_2_1;
wire total_2_2;
wire total_3_1;
wire total_3_2;
wire total_4_1;
wire total_4_2;
wire total_5_1;
wire total_5_2;
wire total_6_1;
wire total_6_2;
wire total_7_1;
wire total_7_2;
wire total_8_1;
wire total_8_2;
wire total_9_1;
wire total_9_2;
wire total_10_1;
wire total_10_2;
wire total_11_1;
wire total_11_2;
wire total_12_1;
wire total_12_2;
wire total_13_1;
wire total_13_2;
wire total_14_1;
wire total_14_2;
wire total_15_1;
wire total_15_2;
wire total_16_1;
wire total_16_2;
wire total_17_1;
wire total_17_2;
wire total_18_1;
wire total_18_2;
wire total_19_1;
wire total_19_2;
wire total_20_1;
wire total_20_2;
wire total_21_1;
wire total_21_2;
wire total_22_1;
wire total_22_2;
wire total_23_1;
wire total_23_2;
wire total_24_1;
wire total_24_2;
wire total_25_1;
wire total_25_2;
wire total_26_1;
wire total_26_2;
wire total_27_1;
wire total_27_2;
wire total_28_1;
wire total_28_2;
wire total_29_1;
wire total_29_2;
wire total_30_1;
wire total_30_2;
wire total_31_1;
wire total_31_2;
wire total_32_1;
wire total_32_2;
wire total_33_1;
wire total_33_2;
wire total_34_1;
wire total_34_2;
wire total_35_1;
wire total_35_2;
wire total_36_1;
wire total_36_2;
wire total_37_1;
wire total_37_2;
wire total_38_1;
wire total_38_2;
wire total_39_1;
wire total_39_2;
wire total_40_1;
wire total_40_2;
wire total_41_1;
wire total_41_0_COUT;
wire total_0_3;
wire total_0_4;
wire total_1_3;
wire total_1_4;
wire total_2_3;
wire total_2_4;
wire total_3_3;
wire total_3_4;
wire total_4_3;
wire total_4_4;
wire total_5_3;
wire total_5_4;
wire total_6_3;
wire total_6_4;
wire total_7_3;
wire total_7_4;
wire total_8_3;
wire total_8_4;
wire total_9_3;
wire total_9_4;
wire total_10_3;
wire total_10_4;
wire total_11_3;
wire total_11_4;
wire total_12_3;
wire total_12_4;
wire total_13_3;
wire total_13_4;
wire total_14_3;
wire total_14_4;
wire total_15_3;
wire total_15_4;
wire total_16_3;
wire total_16_4;
wire total_17_3;
wire total_17_4;
wire total_18_3;
wire total_18_4;
wire total_19_3;
wire total_19_4;
wire total_20_3;
wire total_20_4;
wire total_21_3;
wire total_21_4;
wire total_22_3;
wire total_22_4;
wire total_23_3;
wire total_23_4;
wire total_24_3;
wire total_24_4;
wire total_25_3;
wire total_25_4;
wire total_26_3;
wire total_26_4;
wire total_27_3;
wire total_27_4;
wire total_28_3;
wire total_28_4;
wire total_29_3;
wire total_29_4;
wire total_30_3;
wire total_30_4;
wire total_31_3;
wire total_31_4;
wire total_32_3;
wire total_32_4;
wire total_33_3;
wire total_33_4;
wire total_34_3;
wire total_34_4;
wire total_35_3;
wire total_35_4;
wire total_36_3;
wire total_36_4;
wire total_37_3;
wire total_37_4;
wire total_38_3;
wire total_38_4;
wire total_39_3;
wire total_39_4;
wire total_40_3;
wire total_40_4;
wire total_41_3;
wire total_41_1_COUT;
wire total_0_6;
wire total_1_6;
wire total_2_6;
wire total_3_6;
wire total_4_6;
wire total_5_6;
wire total_6_6;
wire total_7_6;
wire total_8_6;
wire total_9_6;
wire total_10_6;
wire total_11_6;
wire total_12_6;
wire total_13_6;
wire total_14_6;
wire total_15_6;
wire total_16_6;
wire total_17_6;
wire total_18_6;
wire total_19_6;
wire total_20_6;
wire total_21_6;
wire total_22_6;
wire total_23_6;
wire total_24_6;
wire total_25_6;
wire total_26_6;
wire total_27_6;
wire total_28_6;
wire total_29_6;
wire total_30_6;
wire total_31_6;
wire total_32_6;
wire total_33_6;
wire total_34_6;
wire total_35_6;
wire total_36_6;
wire total_37_6;
wire total_38_6;
wire total_39_6;
wire total_40_6;
wire total_41_2_COUT;
wire n849_1;
wire n849_2;
wire n848_1;
wire n848_2;
wire n847_1;
wire n847_2;
wire n846_1;
wire n846_2;
wire n845_1;
wire n845_2;
wire n844_1;
wire n844_2;
wire n843_1;
wire n843_2;
wire n842_1;
wire n842_2;
wire n841_1;
wire n841_2;
wire n840_1;
wire n840_0_COUT;
wire tap_base_3_3;
wire tap_base_4_3;
wire tap_base_5_3;
wire tap_base_6_3;
wire tap_base_7_3;
wire tap_base_8_3;
wire tap_base_9_0_COUT;
wire n836_1;
wire n836_2;
wire n835_1;
wire n835_2;
wire n834_1;
wire n834_2;
wire n833_1;
wire n833_2;
wire n832_1;
wire n832_2;
wire n831_1;
wire n831_2;
wire n830_1;
wire n830_2;
wire n829_1;
wire n829_2;
wire n828_1;
wire n828_0_COUT;
wire n6_6;
wire [9:0] addr0;
wire [9:1] addr3;
wire [9:2] addr1;
wire [9:2] addr2;
wire [15:0] c0;
wire [9:0] wp;
wire [9:0] base;
wire [10:0] fill;
wire [15:0] x_delayed;
wire [15:8] held_pcm;
wire [7:0] index;
wire [15:0] q0;
wire [15:0] q1;
wire [15:0] q2;
wire [15:0] q3;
wire [14:0] c1;
wire [11:0] c2;
wire [11:0] c3;
wire [39:0] t0;
wire [39:0] t1;
wire [39:0] t2;
wire [39:0] t3;
wire [41:0] total;
wire [9:3] tap_base;
wire [31:16] DO;
wire [31:16] DO_0;
wire [31:16] DO_1;
wire [31:16] DO_2;
wire [31:18] DO_3;
wire [47:40] DOUT;
wire [47:0] CASO;
wire [26:0] SOA;
wire [47:40] DOUT_0;
wire [47:0] CASO_0;
wire [26:0] SOA_0;
wire [47:40] DOUT_1;
wire [47:0] CASO_1;
wire [26:0] SOA_1;
wire [47:40] DOUT_2;
wire [47:0] CASO_2;
wire [26:0] SOA_2;
wire VCC;
wire GND;
  LUT3 addr0_9_s2 (
    .F(addr0[9]),
    .I0(addr0_9_6),
    .I1(tap_base[9]),
    .I2(accept) 
);
defparam addr0_9_s2.INIT=8'h5C;
  LUT4 addr0_8_s2 (
    .F(addr0[8]),
    .I0(tap_base[8]),
    .I1(wp[8]),
    .I2(addr0_8_6),
    .I3(accept) 
);
defparam addr0_8_s2.INIT=16'h3CAA;
  LUT4 addr0_7_s2 (
    .F(addr0[7]),
    .I0(tap_base[7]),
    .I1(wp[7]),
    .I2(addr0_7_6),
    .I3(accept) 
);
defparam addr0_7_s2.INIT=16'h3CAA;
  LUT4 addr0_6_s2 (
    .F(addr0[6]),
    .I0(tap_base[6]),
    .I1(wp[6]),
    .I2(addr0_6_8),
    .I3(accept) 
);
defparam addr0_6_s2.INIT=16'h3CAA;
  LUT4 addr0_5_s2 (
    .F(addr0[5]),
    .I0(tap_base[5]),
    .I1(wp[5]),
    .I2(addr0_5_6),
    .I3(accept) 
);
defparam addr0_5_s2.INIT=16'h3CAA;
  LUT4 addr0_4_s2 (
    .F(addr0[4]),
    .I0(tap_base[4]),
    .I1(wp[4]),
    .I2(addr0_4_8),
    .I3(accept) 
);
defparam addr0_4_s2.INIT=16'h3CAA;
  LUT4 addr0_3_s2 (
    .F(addr0[3]),
    .I0(tap_base[3]),
    .I1(wp[3]),
    .I2(addr0_3_8),
    .I3(accept) 
);
defparam addr0_3_s2.INIT=16'h3CAA;
  LUT4 addr0_2_s2 (
    .F(addr0[2]),
    .I0(base[2]),
    .I1(wp[2]),
    .I2(addr0_2_6),
    .I3(accept) 
);
defparam addr0_2_s2.INIT=16'h3CAA;
  LUT4 addr0_1_s2 (
    .F(addr0[1]),
    .I0(base[1]),
    .I1(wp[0]),
    .I2(wp[1]),
    .I3(accept) 
);
defparam addr0_1_s2.INIT=16'h3CAA;
  LUT3 addr0_0_s2 (
    .F(addr0[0]),
    .I0(wp[0]),
    .I1(base[0]),
    .I2(accept) 
);
defparam addr0_0_s2.INIT=8'h5C;
  LUT2 addr3_2_s5 (
    .F(addr3[2]),
    .I0(base[2]),
    .I1(base[1]) 
);
defparam addr3_2_s5.INIT=4'h6;
  LUT2 n1352_s2 (
    .F(n1352_7),
    .I0(accept),
    .I1(t3[0]) 
);
defparam n1352_s2.INIT=4'h4;
  LUT2 n1351_s2 (
    .F(n1351_7),
    .I0(accept),
    .I1(t3[1]) 
);
defparam n1351_s2.INIT=4'h4;
  LUT2 n1350_s2 (
    .F(n1350_7),
    .I0(accept),
    .I1(t3[2]) 
);
defparam n1350_s2.INIT=4'h4;
  LUT2 n1349_s2 (
    .F(n1349_7),
    .I0(accept),
    .I1(t3[3]) 
);
defparam n1349_s2.INIT=4'h4;
  LUT2 n1348_s2 (
    .F(n1348_7),
    .I0(accept),
    .I1(t3[4]) 
);
defparam n1348_s2.INIT=4'h4;
  LUT2 n1347_s2 (
    .F(n1347_7),
    .I0(accept),
    .I1(t3[5]) 
);
defparam n1347_s2.INIT=4'h4;
  LUT2 n1346_s2 (
    .F(n1346_7),
    .I0(accept),
    .I1(t3[6]) 
);
defparam n1346_s2.INIT=4'h4;
  LUT2 n1345_s2 (
    .F(n1345_7),
    .I0(accept),
    .I1(t3[7]) 
);
defparam n1345_s2.INIT=4'h4;
  LUT2 n1344_s2 (
    .F(n1344_7),
    .I0(accept),
    .I1(t3[8]) 
);
defparam n1344_s2.INIT=4'h4;
  LUT2 n1343_s2 (
    .F(n1343_7),
    .I0(accept),
    .I1(t3[9]) 
);
defparam n1343_s2.INIT=4'h4;
  LUT2 n1342_s2 (
    .F(n1342_7),
    .I0(accept),
    .I1(t3[10]) 
);
defparam n1342_s2.INIT=4'h4;
  LUT2 n1341_s2 (
    .F(n1341_7),
    .I0(accept),
    .I1(t3[11]) 
);
defparam n1341_s2.INIT=4'h4;
  LUT2 n1340_s2 (
    .F(n1340_7),
    .I0(accept),
    .I1(t3[12]) 
);
defparam n1340_s2.INIT=4'h4;
  LUT2 n1339_s2 (
    .F(n1339_7),
    .I0(accept),
    .I1(t3[13]) 
);
defparam n1339_s2.INIT=4'h4;
  LUT2 n1338_s2 (
    .F(n1338_7),
    .I0(accept),
    .I1(t3[14]) 
);
defparam n1338_s2.INIT=4'h4;
  LUT2 n1337_s2 (
    .F(n1337_7),
    .I0(accept),
    .I1(t3[15]) 
);
defparam n1337_s2.INIT=4'h4;
  LUT2 n1336_s2 (
    .F(n1336_7),
    .I0(accept),
    .I1(t3[16]) 
);
defparam n1336_s2.INIT=4'h4;
  LUT2 n1335_s2 (
    .F(n1335_7),
    .I0(accept),
    .I1(t3[17]) 
);
defparam n1335_s2.INIT=4'h4;
  LUT2 n1334_s2 (
    .F(n1334_7),
    .I0(accept),
    .I1(t3[18]) 
);
defparam n1334_s2.INIT=4'h4;
  LUT2 n1333_s2 (
    .F(n1333_7),
    .I0(accept),
    .I1(t3[19]) 
);
defparam n1333_s2.INIT=4'h4;
  LUT2 n1332_s2 (
    .F(n1332_7),
    .I0(accept),
    .I1(t3[20]) 
);
defparam n1332_s2.INIT=4'h4;
  LUT2 n1331_s2 (
    .F(n1331_7),
    .I0(accept),
    .I1(t3[21]) 
);
defparam n1331_s2.INIT=4'h4;
  LUT2 n1330_s2 (
    .F(n1330_7),
    .I0(accept),
    .I1(t3[22]) 
);
defparam n1330_s2.INIT=4'h4;
  LUT2 n1329_s2 (
    .F(n1329_7),
    .I0(accept),
    .I1(t3[23]) 
);
defparam n1329_s2.INIT=4'h4;
  LUT2 n1328_s2 (
    .F(n1328_7),
    .I0(accept),
    .I1(t3[24]) 
);
defparam n1328_s2.INIT=4'h4;
  LUT2 n1327_s2 (
    .F(n1327_7),
    .I0(accept),
    .I1(t3[25]) 
);
defparam n1327_s2.INIT=4'h4;
  LUT2 n1326_s2 (
    .F(n1326_7),
    .I0(accept),
    .I1(t3[26]) 
);
defparam n1326_s2.INIT=4'h4;
  LUT2 n1325_s2 (
    .F(n1325_7),
    .I0(accept),
    .I1(t3[27]) 
);
defparam n1325_s2.INIT=4'h4;
  LUT2 n1324_s2 (
    .F(n1324_7),
    .I0(accept),
    .I1(t3[28]) 
);
defparam n1324_s2.INIT=4'h4;
  LUT2 n1323_s2 (
    .F(n1323_7),
    .I0(accept),
    .I1(t3[29]) 
);
defparam n1323_s2.INIT=4'h4;
  LUT2 n1322_s2 (
    .F(n1322_7),
    .I0(accept),
    .I1(t3[30]) 
);
defparam n1322_s2.INIT=4'h4;
  LUT2 n1321_s2 (
    .F(n1321_7),
    .I0(accept),
    .I1(t3[31]) 
);
defparam n1321_s2.INIT=4'h4;
  LUT2 n1320_s2 (
    .F(n1320_7),
    .I0(accept),
    .I1(t3[32]) 
);
defparam n1320_s2.INIT=4'h4;
  LUT2 n1319_s2 (
    .F(n1319_7),
    .I0(accept),
    .I1(t3[33]) 
);
defparam n1319_s2.INIT=4'h4;
  LUT2 n1318_s2 (
    .F(n1318_7),
    .I0(accept),
    .I1(t3[34]) 
);
defparam n1318_s2.INIT=4'h4;
  LUT2 n1317_s2 (
    .F(n1317_7),
    .I0(accept),
    .I1(t3[35]) 
);
defparam n1317_s2.INIT=4'h4;
  LUT2 n1316_s2 (
    .F(n1316_7),
    .I0(accept),
    .I1(t3[36]) 
);
defparam n1316_s2.INIT=4'h4;
  LUT2 n1315_s2 (
    .F(n1315_7),
    .I0(accept),
    .I1(t3[37]) 
);
defparam n1315_s2.INIT=4'h4;
  LUT2 n1314_s2 (
    .F(n1314_7),
    .I0(accept),
    .I1(t3[38]) 
);
defparam n1314_s2.INIT=4'h4;
  LUT2 n1313_s2 (
    .F(n1313_7),
    .I0(accept),
    .I1(t3[39]) 
);
defparam n1313_s2.INIT=4'h4;
  LUT2 n1312_s2 (
    .F(n1312_7),
    .I0(accept),
    .I1(t2[0]) 
);
defparam n1312_s2.INIT=4'h4;
  LUT2 n1311_s2 (
    .F(n1311_7),
    .I0(accept),
    .I1(t2[1]) 
);
defparam n1311_s2.INIT=4'h4;
  LUT2 n1310_s2 (
    .F(n1310_7),
    .I0(accept),
    .I1(t2[2]) 
);
defparam n1310_s2.INIT=4'h4;
  LUT2 n1309_s2 (
    .F(n1309_7),
    .I0(accept),
    .I1(t2[3]) 
);
defparam n1309_s2.INIT=4'h4;
  LUT2 n1308_s2 (
    .F(n1308_7),
    .I0(accept),
    .I1(t2[4]) 
);
defparam n1308_s2.INIT=4'h4;
  LUT2 n1307_s2 (
    .F(n1307_7),
    .I0(accept),
    .I1(t2[5]) 
);
defparam n1307_s2.INIT=4'h4;
  LUT2 n1306_s2 (
    .F(n1306_7),
    .I0(accept),
    .I1(t2[6]) 
);
defparam n1306_s2.INIT=4'h4;
  LUT2 n1305_s2 (
    .F(n1305_7),
    .I0(accept),
    .I1(t2[7]) 
);
defparam n1305_s2.INIT=4'h4;
  LUT2 n1304_s2 (
    .F(n1304_7),
    .I0(accept),
    .I1(t2[8]) 
);
defparam n1304_s2.INIT=4'h4;
  LUT2 n1303_s2 (
    .F(n1303_7),
    .I0(accept),
    .I1(t2[9]) 
);
defparam n1303_s2.INIT=4'h4;
  LUT2 n1302_s2 (
    .F(n1302_7),
    .I0(accept),
    .I1(t2[10]) 
);
defparam n1302_s2.INIT=4'h4;
  LUT2 n1301_s2 (
    .F(n1301_7),
    .I0(accept),
    .I1(t2[11]) 
);
defparam n1301_s2.INIT=4'h4;
  LUT2 n1300_s2 (
    .F(n1300_7),
    .I0(accept),
    .I1(t2[12]) 
);
defparam n1300_s2.INIT=4'h4;
  LUT2 n1299_s2 (
    .F(n1299_7),
    .I0(accept),
    .I1(t2[13]) 
);
defparam n1299_s2.INIT=4'h4;
  LUT2 n1298_s2 (
    .F(n1298_7),
    .I0(accept),
    .I1(t2[14]) 
);
defparam n1298_s2.INIT=4'h4;
  LUT2 n1297_s2 (
    .F(n1297_7),
    .I0(accept),
    .I1(t2[15]) 
);
defparam n1297_s2.INIT=4'h4;
  LUT2 n1296_s2 (
    .F(n1296_7),
    .I0(accept),
    .I1(t2[16]) 
);
defparam n1296_s2.INIT=4'h4;
  LUT2 n1295_s2 (
    .F(n1295_7),
    .I0(accept),
    .I1(t2[17]) 
);
defparam n1295_s2.INIT=4'h4;
  LUT2 n1294_s2 (
    .F(n1294_7),
    .I0(accept),
    .I1(t2[18]) 
);
defparam n1294_s2.INIT=4'h4;
  LUT2 n1293_s2 (
    .F(n1293_7),
    .I0(accept),
    .I1(t2[19]) 
);
defparam n1293_s2.INIT=4'h4;
  LUT2 n1292_s2 (
    .F(n1292_7),
    .I0(accept),
    .I1(t2[20]) 
);
defparam n1292_s2.INIT=4'h4;
  LUT2 n1291_s2 (
    .F(n1291_7),
    .I0(accept),
    .I1(t2[21]) 
);
defparam n1291_s2.INIT=4'h4;
  LUT2 n1290_s2 (
    .F(n1290_7),
    .I0(accept),
    .I1(t2[22]) 
);
defparam n1290_s2.INIT=4'h4;
  LUT2 n1289_s2 (
    .F(n1289_7),
    .I0(accept),
    .I1(t2[23]) 
);
defparam n1289_s2.INIT=4'h4;
  LUT2 n1288_s2 (
    .F(n1288_7),
    .I0(accept),
    .I1(t2[24]) 
);
defparam n1288_s2.INIT=4'h4;
  LUT2 n1287_s2 (
    .F(n1287_7),
    .I0(accept),
    .I1(t2[25]) 
);
defparam n1287_s2.INIT=4'h4;
  LUT2 n1286_s2 (
    .F(n1286_7),
    .I0(accept),
    .I1(t2[26]) 
);
defparam n1286_s2.INIT=4'h4;
  LUT2 n1285_s2 (
    .F(n1285_7),
    .I0(accept),
    .I1(t2[27]) 
);
defparam n1285_s2.INIT=4'h4;
  LUT2 n1284_s2 (
    .F(n1284_7),
    .I0(accept),
    .I1(t2[28]) 
);
defparam n1284_s2.INIT=4'h4;
  LUT2 n1283_s2 (
    .F(n1283_7),
    .I0(accept),
    .I1(t2[29]) 
);
defparam n1283_s2.INIT=4'h4;
  LUT2 n1282_s2 (
    .F(n1282_7),
    .I0(accept),
    .I1(t2[30]) 
);
defparam n1282_s2.INIT=4'h4;
  LUT2 n1281_s2 (
    .F(n1281_7),
    .I0(accept),
    .I1(t2[31]) 
);
defparam n1281_s2.INIT=4'h4;
  LUT2 n1280_s2 (
    .F(n1280_7),
    .I0(accept),
    .I1(t2[32]) 
);
defparam n1280_s2.INIT=4'h4;
  LUT2 n1279_s2 (
    .F(n1279_7),
    .I0(accept),
    .I1(t2[33]) 
);
defparam n1279_s2.INIT=4'h4;
  LUT2 n1278_s2 (
    .F(n1278_7),
    .I0(accept),
    .I1(t2[34]) 
);
defparam n1278_s2.INIT=4'h4;
  LUT2 n1277_s2 (
    .F(n1277_7),
    .I0(accept),
    .I1(t2[35]) 
);
defparam n1277_s2.INIT=4'h4;
  LUT2 n1276_s2 (
    .F(n1276_7),
    .I0(accept),
    .I1(t2[36]) 
);
defparam n1276_s2.INIT=4'h4;
  LUT2 n1275_s2 (
    .F(n1275_7),
    .I0(accept),
    .I1(t2[37]) 
);
defparam n1275_s2.INIT=4'h4;
  LUT2 n1274_s2 (
    .F(n1274_7),
    .I0(accept),
    .I1(t2[38]) 
);
defparam n1274_s2.INIT=4'h4;
  LUT2 n1273_s2 (
    .F(n1273_7),
    .I0(accept),
    .I1(t2[39]) 
);
defparam n1273_s2.INIT=4'h4;
  LUT2 n1272_s2 (
    .F(n1272_7),
    .I0(accept),
    .I1(t1[0]) 
);
defparam n1272_s2.INIT=4'h4;
  LUT2 n1271_s2 (
    .F(n1271_7),
    .I0(accept),
    .I1(t1[1]) 
);
defparam n1271_s2.INIT=4'h4;
  LUT2 n1270_s2 (
    .F(n1270_7),
    .I0(accept),
    .I1(t1[2]) 
);
defparam n1270_s2.INIT=4'h4;
  LUT2 n1269_s2 (
    .F(n1269_7),
    .I0(accept),
    .I1(t1[3]) 
);
defparam n1269_s2.INIT=4'h4;
  LUT2 n1268_s2 (
    .F(n1268_7),
    .I0(accept),
    .I1(t1[4]) 
);
defparam n1268_s2.INIT=4'h4;
  LUT2 n1267_s2 (
    .F(n1267_7),
    .I0(accept),
    .I1(t1[5]) 
);
defparam n1267_s2.INIT=4'h4;
  LUT2 n1266_s2 (
    .F(n1266_7),
    .I0(accept),
    .I1(t1[6]) 
);
defparam n1266_s2.INIT=4'h4;
  LUT2 n1265_s2 (
    .F(n1265_7),
    .I0(accept),
    .I1(t1[7]) 
);
defparam n1265_s2.INIT=4'h4;
  LUT2 n1264_s2 (
    .F(n1264_7),
    .I0(accept),
    .I1(t1[8]) 
);
defparam n1264_s2.INIT=4'h4;
  LUT2 n1263_s2 (
    .F(n1263_7),
    .I0(accept),
    .I1(t1[9]) 
);
defparam n1263_s2.INIT=4'h4;
  LUT2 n1262_s2 (
    .F(n1262_7),
    .I0(accept),
    .I1(t1[10]) 
);
defparam n1262_s2.INIT=4'h4;
  LUT2 n1261_s2 (
    .F(n1261_7),
    .I0(accept),
    .I1(t1[11]) 
);
defparam n1261_s2.INIT=4'h4;
  LUT2 n1260_s2 (
    .F(n1260_7),
    .I0(accept),
    .I1(t1[12]) 
);
defparam n1260_s2.INIT=4'h4;
  LUT2 n1259_s2 (
    .F(n1259_7),
    .I0(accept),
    .I1(t1[13]) 
);
defparam n1259_s2.INIT=4'h4;
  LUT2 n1258_s2 (
    .F(n1258_7),
    .I0(accept),
    .I1(t1[14]) 
);
defparam n1258_s2.INIT=4'h4;
  LUT2 n1257_s2 (
    .F(n1257_7),
    .I0(accept),
    .I1(t1[15]) 
);
defparam n1257_s2.INIT=4'h4;
  LUT2 n1256_s2 (
    .F(n1256_7),
    .I0(accept),
    .I1(t1[16]) 
);
defparam n1256_s2.INIT=4'h4;
  LUT2 n1255_s2 (
    .F(n1255_7),
    .I0(accept),
    .I1(t1[17]) 
);
defparam n1255_s2.INIT=4'h4;
  LUT2 n1254_s2 (
    .F(n1254_7),
    .I0(accept),
    .I1(t1[18]) 
);
defparam n1254_s2.INIT=4'h4;
  LUT2 n1253_s2 (
    .F(n1253_7),
    .I0(accept),
    .I1(t1[19]) 
);
defparam n1253_s2.INIT=4'h4;
  LUT2 n1252_s2 (
    .F(n1252_7),
    .I0(accept),
    .I1(t1[20]) 
);
defparam n1252_s2.INIT=4'h4;
  LUT2 n1251_s2 (
    .F(n1251_7),
    .I0(accept),
    .I1(t1[21]) 
);
defparam n1251_s2.INIT=4'h4;
  LUT2 n1250_s2 (
    .F(n1250_7),
    .I0(accept),
    .I1(t1[22]) 
);
defparam n1250_s2.INIT=4'h4;
  LUT2 n1249_s2 (
    .F(n1249_7),
    .I0(accept),
    .I1(t1[23]) 
);
defparam n1249_s2.INIT=4'h4;
  LUT2 n1248_s2 (
    .F(n1248_7),
    .I0(accept),
    .I1(t1[24]) 
);
defparam n1248_s2.INIT=4'h4;
  LUT2 n1247_s2 (
    .F(n1247_7),
    .I0(accept),
    .I1(t1[25]) 
);
defparam n1247_s2.INIT=4'h4;
  LUT2 n1246_s2 (
    .F(n1246_7),
    .I0(accept),
    .I1(t1[26]) 
);
defparam n1246_s2.INIT=4'h4;
  LUT2 n1245_s2 (
    .F(n1245_7),
    .I0(accept),
    .I1(t1[27]) 
);
defparam n1245_s2.INIT=4'h4;
  LUT2 n1244_s2 (
    .F(n1244_7),
    .I0(accept),
    .I1(t1[28]) 
);
defparam n1244_s2.INIT=4'h4;
  LUT2 n1243_s2 (
    .F(n1243_7),
    .I0(accept),
    .I1(t1[29]) 
);
defparam n1243_s2.INIT=4'h4;
  LUT2 n1242_s2 (
    .F(n1242_7),
    .I0(accept),
    .I1(t1[30]) 
);
defparam n1242_s2.INIT=4'h4;
  LUT2 n1241_s2 (
    .F(n1241_7),
    .I0(accept),
    .I1(t1[31]) 
);
defparam n1241_s2.INIT=4'h4;
  LUT2 n1240_s2 (
    .F(n1240_7),
    .I0(accept),
    .I1(t1[32]) 
);
defparam n1240_s2.INIT=4'h4;
  LUT2 n1239_s2 (
    .F(n1239_7),
    .I0(accept),
    .I1(t1[33]) 
);
defparam n1239_s2.INIT=4'h4;
  LUT2 n1238_s2 (
    .F(n1238_7),
    .I0(accept),
    .I1(t1[34]) 
);
defparam n1238_s2.INIT=4'h4;
  LUT2 n1237_s2 (
    .F(n1237_7),
    .I0(accept),
    .I1(t1[35]) 
);
defparam n1237_s2.INIT=4'h4;
  LUT2 n1236_s2 (
    .F(n1236_7),
    .I0(accept),
    .I1(t1[36]) 
);
defparam n1236_s2.INIT=4'h4;
  LUT2 n1235_s2 (
    .F(n1235_7),
    .I0(accept),
    .I1(t1[37]) 
);
defparam n1235_s2.INIT=4'h4;
  LUT2 n1234_s2 (
    .F(n1234_7),
    .I0(accept),
    .I1(t1[38]) 
);
defparam n1234_s2.INIT=4'h4;
  LUT2 n1233_s2 (
    .F(n1233_7),
    .I0(accept),
    .I1(t1[39]) 
);
defparam n1233_s2.INIT=4'h4;
  LUT2 n1232_s2 (
    .F(n1232_7),
    .I0(accept),
    .I1(t0[0]) 
);
defparam n1232_s2.INIT=4'h4;
  LUT2 n1231_s2 (
    .F(n1231_7),
    .I0(accept),
    .I1(t0[1]) 
);
defparam n1231_s2.INIT=4'h4;
  LUT2 n1230_s2 (
    .F(n1230_7),
    .I0(accept),
    .I1(t0[2]) 
);
defparam n1230_s2.INIT=4'h4;
  LUT2 n1229_s2 (
    .F(n1229_7),
    .I0(accept),
    .I1(t0[3]) 
);
defparam n1229_s2.INIT=4'h4;
  LUT2 n1228_s2 (
    .F(n1228_7),
    .I0(accept),
    .I1(t0[4]) 
);
defparam n1228_s2.INIT=4'h4;
  LUT2 n1227_s2 (
    .F(n1227_7),
    .I0(accept),
    .I1(t0[5]) 
);
defparam n1227_s2.INIT=4'h4;
  LUT2 n1226_s2 (
    .F(n1226_7),
    .I0(accept),
    .I1(t0[6]) 
);
defparam n1226_s2.INIT=4'h4;
  LUT2 n1225_s2 (
    .F(n1225_7),
    .I0(accept),
    .I1(t0[7]) 
);
defparam n1225_s2.INIT=4'h4;
  LUT2 n1224_s2 (
    .F(n1224_7),
    .I0(accept),
    .I1(t0[8]) 
);
defparam n1224_s2.INIT=4'h4;
  LUT2 n1223_s2 (
    .F(n1223_7),
    .I0(accept),
    .I1(t0[9]) 
);
defparam n1223_s2.INIT=4'h4;
  LUT2 n1222_s2 (
    .F(n1222_7),
    .I0(accept),
    .I1(t0[10]) 
);
defparam n1222_s2.INIT=4'h4;
  LUT2 n1221_s2 (
    .F(n1221_7),
    .I0(accept),
    .I1(t0[11]) 
);
defparam n1221_s2.INIT=4'h4;
  LUT2 n1220_s2 (
    .F(n1220_7),
    .I0(accept),
    .I1(t0[12]) 
);
defparam n1220_s2.INIT=4'h4;
  LUT2 n1219_s2 (
    .F(n1219_7),
    .I0(accept),
    .I1(t0[13]) 
);
defparam n1219_s2.INIT=4'h4;
  LUT2 n1218_s2 (
    .F(n1218_7),
    .I0(accept),
    .I1(t0[14]) 
);
defparam n1218_s2.INIT=4'h4;
  LUT2 n1217_s2 (
    .F(n1217_7),
    .I0(accept),
    .I1(t0[15]) 
);
defparam n1217_s2.INIT=4'h4;
  LUT2 n1216_s2 (
    .F(n1216_7),
    .I0(accept),
    .I1(t0[16]) 
);
defparam n1216_s2.INIT=4'h4;
  LUT2 n1215_s2 (
    .F(n1215_7),
    .I0(accept),
    .I1(t0[17]) 
);
defparam n1215_s2.INIT=4'h4;
  LUT2 n1214_s2 (
    .F(n1214_7),
    .I0(accept),
    .I1(t0[18]) 
);
defparam n1214_s2.INIT=4'h4;
  LUT2 n1213_s2 (
    .F(n1213_7),
    .I0(accept),
    .I1(t0[19]) 
);
defparam n1213_s2.INIT=4'h4;
  LUT2 n1212_s2 (
    .F(n1212_7),
    .I0(accept),
    .I1(t0[20]) 
);
defparam n1212_s2.INIT=4'h4;
  LUT2 n1211_s2 (
    .F(n1211_7),
    .I0(accept),
    .I1(t0[21]) 
);
defparam n1211_s2.INIT=4'h4;
  LUT2 n1210_s2 (
    .F(n1210_7),
    .I0(accept),
    .I1(t0[22]) 
);
defparam n1210_s2.INIT=4'h4;
  LUT2 n1209_s2 (
    .F(n1209_7),
    .I0(accept),
    .I1(t0[23]) 
);
defparam n1209_s2.INIT=4'h4;
  LUT2 n1208_s2 (
    .F(n1208_7),
    .I0(accept),
    .I1(t0[24]) 
);
defparam n1208_s2.INIT=4'h4;
  LUT2 n1207_s2 (
    .F(n1207_7),
    .I0(accept),
    .I1(t0[25]) 
);
defparam n1207_s2.INIT=4'h4;
  LUT2 n1206_s2 (
    .F(n1206_7),
    .I0(accept),
    .I1(t0[26]) 
);
defparam n1206_s2.INIT=4'h4;
  LUT2 n1205_s2 (
    .F(n1205_7),
    .I0(accept),
    .I1(t0[27]) 
);
defparam n1205_s2.INIT=4'h4;
  LUT2 n1204_s2 (
    .F(n1204_7),
    .I0(accept),
    .I1(t0[28]) 
);
defparam n1204_s2.INIT=4'h4;
  LUT2 n1203_s2 (
    .F(n1203_7),
    .I0(accept),
    .I1(t0[29]) 
);
defparam n1203_s2.INIT=4'h4;
  LUT2 n1202_s2 (
    .F(n1202_7),
    .I0(accept),
    .I1(t0[30]) 
);
defparam n1202_s2.INIT=4'h4;
  LUT2 n1201_s2 (
    .F(n1201_7),
    .I0(accept),
    .I1(t0[31]) 
);
defparam n1201_s2.INIT=4'h4;
  LUT2 n1200_s2 (
    .F(n1200_7),
    .I0(accept),
    .I1(t0[32]) 
);
defparam n1200_s2.INIT=4'h4;
  LUT2 n1199_s2 (
    .F(n1199_7),
    .I0(accept),
    .I1(t0[33]) 
);
defparam n1199_s2.INIT=4'h4;
  LUT2 n1198_s2 (
    .F(n1198_7),
    .I0(accept),
    .I1(t0[34]) 
);
defparam n1198_s2.INIT=4'h4;
  LUT2 n1197_s2 (
    .F(n1197_7),
    .I0(accept),
    .I1(t0[35]) 
);
defparam n1197_s2.INIT=4'h4;
  LUT2 n1196_s2 (
    .F(n1196_7),
    .I0(accept),
    .I1(t0[36]) 
);
defparam n1196_s2.INIT=4'h4;
  LUT2 n1195_s2 (
    .F(n1195_7),
    .I0(accept),
    .I1(t0[37]) 
);
defparam n1195_s2.INIT=4'h4;
  LUT2 n1194_s2 (
    .F(n1194_7),
    .I0(accept),
    .I1(t0[38]) 
);
defparam n1194_s2.INIT=4'h4;
  LUT2 n1193_s2 (
    .F(n1193_7),
    .I0(accept),
    .I1(t0[39]) 
);
defparam n1193_s2.INIT=4'h4;
  LUT2 n1176_s2 (
    .F(n1176_7),
    .I0(index[0]),
    .I1(accept) 
);
defparam n1176_s2.INIT=4'h1;
  LUT3 n1175_s2 (
    .F(n1175_7),
    .I0(accept),
    .I1(index[0]),
    .I2(index[1]) 
);
defparam n1175_s2.INIT=8'h14;
  LUT4 n1174_s2 (
    .F(n1174_7),
    .I0(index[0]),
    .I1(index[1]),
    .I2(accept),
    .I3(index[2]) 
);
defparam n1174_s2.INIT=16'h0708;
  LUT3 n1173_s2 (
    .F(n1173_7),
    .I0(accept),
    .I1(index[3]),
    .I2(n1173_8) 
);
defparam n1173_s2.INIT=8'h14;
  LUT3 n1172_s2 (
    .F(n1172_7),
    .I0(accept),
    .I1(index[4]),
    .I2(n1172_10) 
);
defparam n1172_s2.INIT=8'h14;
  LUT3 n1170_s2 (
    .F(n1170_7),
    .I0(accept),
    .I1(index[6]),
    .I2(n1170_10) 
);
defparam n1170_s2.INIT=8'h14;
  LUT4 n1169_s2 (
    .F(n1169_7),
    .I0(index[6]),
    .I1(n1170_10),
    .I2(accept),
    .I3(index[7]) 
);
defparam n1169_s2.INIT=16'h0708;
  LUT4 n1718_s1 (
    .F(n1718_6),
    .I0(n3004_6),
    .I1(n1718_7),
    .I2(n1718_8),
    .I3(n1718_9) 
);
defparam n1718_s1.INIT=16'h8000;
  LUT3 n1099_s1 (
    .F(n1099_6),
    .I0(n1099_7),
    .I1(total[15]),
    .I2(n1099_8) 
);
defparam n1099_s1.INIT=8'hF4;
  LUT3 n1098_s1 (
    .F(n1098_6),
    .I0(n1099_7),
    .I1(total[16]),
    .I2(n1099_8) 
);
defparam n1098_s1.INIT=8'hF4;
  LUT3 n1097_s1 (
    .F(n1097_6),
    .I0(n1099_7),
    .I1(total[17]),
    .I2(n1099_8) 
);
defparam n1097_s1.INIT=8'hF4;
  LUT3 n1096_s1 (
    .F(n1096_6),
    .I0(n1099_7),
    .I1(total[18]),
    .I2(n1099_8) 
);
defparam n1096_s1.INIT=8'hF4;
  LUT3 n1095_s1 (
    .F(n1095_6),
    .I0(n1099_7),
    .I1(total[19]),
    .I2(n1099_8) 
);
defparam n1095_s1.INIT=8'hF4;
  LUT3 n1094_s1 (
    .F(n1094_6),
    .I0(n1099_7),
    .I1(total[20]),
    .I2(n1099_8) 
);
defparam n1094_s1.INIT=8'hF4;
  LUT3 n1093_s1 (
    .F(n1093_6),
    .I0(n1099_7),
    .I1(total[21]),
    .I2(n1099_8) 
);
defparam n1093_s1.INIT=8'hF4;
  LUT3 n1092_s1 (
    .F(n1092_6),
    .I0(n1099_7),
    .I1(total[22]),
    .I2(n1099_8) 
);
defparam n1092_s1.INIT=8'hF4;
  LUT3 n1091_s1 (
    .F(n1091_6),
    .I0(n1099_7),
    .I1(total[23]),
    .I2(n1099_8) 
);
defparam n1091_s1.INIT=8'hF4;
  LUT3 n1090_s1 (
    .F(n1090_6),
    .I0(n1099_7),
    .I1(total[24]),
    .I2(n1099_8) 
);
defparam n1090_s1.INIT=8'hF4;
  LUT3 n1089_s1 (
    .F(n1089_6),
    .I0(n1099_7),
    .I1(total[25]),
    .I2(n1099_8) 
);
defparam n1089_s1.INIT=8'hF4;
  LUT3 n1088_s1 (
    .F(n1088_6),
    .I0(n1099_7),
    .I1(total[26]),
    .I2(n1099_8) 
);
defparam n1088_s1.INIT=8'hF4;
  LUT3 n1087_s1 (
    .F(n1087_6),
    .I0(n1099_7),
    .I1(total[27]),
    .I2(n1099_8) 
);
defparam n1087_s1.INIT=8'hF4;
  LUT3 n1086_s1 (
    .F(n1086_6),
    .I0(n1099_7),
    .I1(total[28]),
    .I2(n1099_8) 
);
defparam n1086_s1.INIT=8'hF4;
  LUT3 n1085_s1 (
    .F(n1085_6),
    .I0(n1099_7),
    .I1(total[29]),
    .I2(n1099_8) 
);
defparam n1085_s1.INIT=8'hF4;
  LUT4 addr1_4_s6 (
    .F(addr1[4]),
    .I0(tap_base[3]),
    .I1(base[2]),
    .I2(base[1]),
    .I3(tap_base[4]) 
);
defparam addr1_4_s6.INIT=16'hFE01;
  LUT3 addr1_7_s6 (
    .F(addr1[7]),
    .I0(tap_base[6]),
    .I1(addr1_6_16),
    .I2(tap_base[7]) 
);
defparam addr1_7_s6.INIT=8'hB4;
  LUT3 addr1_9_s5 (
    .F(addr1[9]),
    .I0(tap_base[8]),
    .I1(addr1_8_16),
    .I2(tap_base[9]) 
);
defparam addr1_9_s5.INIT=8'hB4;
  LUT2 addr2_3_s6 (
    .F(addr2[3]),
    .I0(tap_base[3]),
    .I1(base[2]) 
);
defparam addr2_3_s6.INIT=4'h9;
  LUT3 addr2_4_s6 (
    .F(addr2[4]),
    .I0(tap_base[3]),
    .I1(base[2]),
    .I2(tap_base[4]) 
);
defparam addr2_4_s6.INIT=8'hE1;
  LUT2 addr2_6_s6 (
    .F(addr2[6]),
    .I0(tap_base[6]),
    .I1(addr2_6_13) 
);
defparam addr2_6_s6.INIT=4'h6;
  LUT3 addr2_7_s6 (
    .F(addr2[7]),
    .I0(tap_base[6]),
    .I1(addr2_6_13),
    .I2(tap_base[7]) 
);
defparam addr2_7_s6.INIT=8'hB4;
  LUT3 addr2_9_s5 (
    .F(addr2[9]),
    .I0(tap_base[8]),
    .I1(addr2_8_13),
    .I2(tap_base[9]) 
);
defparam addr2_9_s5.INIT=8'hB4;
  LUT3 addr3_7_s6 (
    .F(addr3[7]),
    .I0(tap_base[6]),
    .I1(addr3_6_15),
    .I2(tap_base[7]) 
);
defparam addr3_7_s6.INIT=8'hB4;
  LUT3 addr3_9_s5 (
    .F(addr3[9]),
    .I0(tap_base[8]),
    .I1(addr3_8_15),
    .I2(tap_base[9]) 
);
defparam addr3_9_s5.INIT=8'hB4;
  LUT3 addr0_9_s3 (
    .F(addr0_9_6),
    .I0(wp[8]),
    .I1(addr0_8_6),
    .I2(wp[9]) 
);
defparam addr0_9_s3.INIT=8'h78;
  LUT2 addr0_8_s3 (
    .F(addr0_8_6),
    .I0(wp[7]),
    .I1(addr0_7_6) 
);
defparam addr0_8_s3.INIT=4'h8;
  LUT2 addr0_7_s3 (
    .F(addr0_7_6),
    .I0(wp[6]),
    .I1(addr0_6_8) 
);
defparam addr0_7_s3.INIT=4'h8;
  LUT2 addr0_5_s3 (
    .F(addr0_5_6),
    .I0(wp[4]),
    .I1(addr0_4_8) 
);
defparam addr0_5_s3.INIT=4'h8;
  LUT2 addr0_2_s3 (
    .F(addr0_2_6),
    .I0(wp[0]),
    .I1(wp[1]) 
);
defparam addr0_2_s3.INIT=4'h8;
  LUT3 n1173_s3 (
    .F(n1173_8),
    .I0(index[0]),
    .I1(index[1]),
    .I2(index[2]) 
);
defparam n1173_s3.INIT=8'h80;
  LUT4 n1718_s2 (
    .F(n1718_7),
    .I0(fill[6]),
    .I1(fill[7]),
    .I2(fill[8]),
    .I3(fill[9]) 
);
defparam n1718_s2.INIT=16'h0001;
  LUT4 n1718_s3 (
    .F(n1718_8),
    .I0(fill[2]),
    .I1(fill[3]),
    .I2(fill[4]),
    .I3(fill[5]) 
);
defparam n1718_s3.INIT=16'h0001;
  LUT3 n1718_s4 (
    .F(n1718_9),
    .I0(fill[0]),
    .I1(fill[1]),
    .I2(fill[10]) 
);
defparam n1718_s4.INIT=8'h10;
  LUT4 n1099_s2 (
    .F(n1099_7),
    .I0(n1099_9),
    .I1(n1099_10),
    .I2(n1099_11),
    .I3(total[41]) 
);
defparam n1099_s2.INIT=16'h7F00;
  LUT4 n1099_s3 (
    .F(n1099_8),
    .I0(n1099_12),
    .I1(n1099_13),
    .I2(n1099_14),
    .I3(total[41]) 
);
defparam n1099_s3.INIT=16'h007F;
  LUT2 addr1_5_s7 (
    .F(addr1_5_13),
    .I0(tap_base[4]),
    .I1(tap_base[3]) 
);
defparam addr1_5_s7.INIT=4'h1;
  LUT4 addr2_6_s7 (
    .F(addr2_6_13),
    .I0(tap_base[5]),
    .I1(tap_base[4]),
    .I2(tap_base[3]),
    .I3(base[2]) 
);
defparam addr2_6_s7.INIT=16'h0001;
  LUT3 addr2_8_s7 (
    .F(addr2_8_13),
    .I0(tap_base[7]),
    .I1(tap_base[6]),
    .I2(addr2_6_13) 
);
defparam addr2_8_s7.INIT=8'h10;
  LUT2 addr3_3_s7 (
    .F(addr3_3_13),
    .I0(base[2]),
    .I1(base[1]) 
);
defparam addr3_3_s7.INIT=4'h8;
  LUT4 n2972_s3 (
    .F(n2972_6),
    .I0(index[3]),
    .I1(index[4]),
    .I2(index[5]),
    .I3(index[6]) 
);
defparam n2972_s3.INIT=16'h0001;
  LUT4 n2972_s4 (
    .F(n2972_7),
    .I0(index[0]),
    .I1(index[1]),
    .I2(index[2]),
    .I3(busy) 
);
defparam n2972_s4.INIT=16'h0100;
  LUT4 n1099_s4 (
    .F(n1099_9),
    .I0(total[36]),
    .I1(total[37]),
    .I2(total[38]),
    .I3(total[39]) 
);
defparam n1099_s4.INIT=16'h8000;
  LUT4 n1099_s5 (
    .F(n1099_10),
    .I0(total[32]),
    .I1(total[33]),
    .I2(total[34]),
    .I3(total[35]) 
);
defparam n1099_s5.INIT=16'h8000;
  LUT3 n1099_s6 (
    .F(n1099_11),
    .I0(total[30]),
    .I1(total[31]),
    .I2(total[40]) 
);
defparam n1099_s6.INIT=8'h80;
  LUT4 n1099_s7 (
    .F(n1099_12),
    .I0(total[36]),
    .I1(total[37]),
    .I2(total[38]),
    .I3(total[39]) 
);
defparam n1099_s7.INIT=16'h0001;
  LUT4 n1099_s8 (
    .F(n1099_13),
    .I0(total[32]),
    .I1(total[33]),
    .I2(total[34]),
    .I3(total[35]) 
);
defparam n1099_s8.INIT=16'h0001;
  LUT3 n1099_s9 (
    .F(n1099_14),
    .I0(total[30]),
    .I1(total[31]),
    .I2(total[40]) 
);
defparam n1099_s9.INIT=8'h01;
  LUT3 addr1_8_s8 (
    .F(addr1_8_14),
    .I0(tap_base[7]),
    .I1(tap_base[6]),
    .I2(addr1_6_18) 
);
defparam addr1_8_s8.INIT=8'h10;
  LUT3 addr0_3_s4 (
    .F(addr0_3_8),
    .I0(wp[2]),
    .I1(wp[0]),
    .I2(wp[1]) 
);
defparam addr0_3_s4.INIT=8'h80;
  LUT4 addr2_8_s8 (
    .F(addr2[8]),
    .I0(tap_base[8]),
    .I1(tap_base[7]),
    .I2(tap_base[6]),
    .I3(addr2_6_13) 
);
defparam addr2_8_s8.INIT=16'hA9AA;
  LUT2 addr1_2_s8 (
    .F(addr1[2]),
    .I0(base[2]),
    .I1(base[1]) 
);
defparam addr1_2_s8.INIT=4'h9;
  LUT4 n1172_s4 (
    .F(n1172_10),
    .I0(index[3]),
    .I1(index[0]),
    .I2(index[1]),
    .I3(index[2]) 
);
defparam n1172_s4.INIT=16'h8000;
  LUT3 n3004_s2 (
    .F(n3004_6),
    .I0(index[7]),
    .I1(n2972_6),
    .I2(n2972_7) 
);
defparam n3004_s2.INIT=8'h80;
  LUT3 n2972_s5 (
    .F(n2972_9),
    .I0(index[7]),
    .I1(n2972_6),
    .I2(n2972_7) 
);
defparam n2972_s5.INIT=8'h40;
  LUT3 addr1_8_s9 (
    .F(addr1_8_16),
    .I0(base[2]),
    .I1(base[1]),
    .I2(addr1_8_14) 
);
defparam addr1_8_s9.INIT=8'h10;
  LUT3 addr1_6_s9 (
    .F(addr1_6_16),
    .I0(base[2]),
    .I1(base[1]),
    .I2(addr1_6_18) 
);
defparam addr1_6_s9.INIT=8'h10;
  LUT4 addr1_5_s8 (
    .F(addr1[5]),
    .I0(base[2]),
    .I1(base[1]),
    .I2(addr1_5_13),
    .I3(tap_base[5]) 
);
defparam addr1_5_s8.INIT=16'hEF10;
  LUT3 addr1_3_s8 (
    .F(addr1[3]),
    .I0(tap_base[3]),
    .I1(base[2]),
    .I2(base[1]) 
);
defparam addr1_3_s8.INIT=8'hA9;
  LUT3 addr1_6_s10 (
    .F(addr1_6_18),
    .I0(tap_base[5]),
    .I1(tap_base[4]),
    .I2(tap_base[3]) 
);
defparam addr1_6_s10.INIT=8'h01;
  LUT4 addr3_5_s7 (
    .F(addr3[5]),
    .I0(addr3_3_13),
    .I1(tap_base[4]),
    .I2(tap_base[3]),
    .I3(tap_base[5]) 
);
defparam addr3_5_s7.INIT=16'hFE01;
  LUT4 addr2_5_s7 (
    .F(addr2[5]),
    .I0(base[2]),
    .I1(tap_base[4]),
    .I2(tap_base[3]),
    .I3(tap_base[5]) 
);
defparam addr2_5_s7.INIT=16'hFE01;
  LUT3 addr3_8_s8 (
    .F(addr3_8_15),
    .I0(base[2]),
    .I1(base[1]),
    .I2(addr1_8_14) 
);
defparam addr3_8_s8.INIT=8'h70;
  LUT3 addr3_6_s8 (
    .F(addr3_6_15),
    .I0(base[2]),
    .I1(base[1]),
    .I2(addr1_6_18) 
);
defparam addr3_6_s8.INIT=8'h70;
  LUT4 addr3_4_s7 (
    .F(addr3[4]),
    .I0(tap_base[3]),
    .I1(base[2]),
    .I2(base[1]),
    .I3(tap_base[4]) 
);
defparam addr3_4_s7.INIT=16'hEA15;
  LUT3 addr3_3_s8 (
    .F(addr3[3]),
    .I0(tap_base[3]),
    .I1(base[2]),
    .I2(base[1]) 
);
defparam addr3_3_s8.INIT=8'h95;
  LUT4 n850_s3 (
    .F(n850_8),
    .I0(busy),
    .I1(fill[10]),
    .I2(visual_pcm_valid),
    .I3(fill[0]) 
);
defparam n850_s3.INIT=16'hEF10;
  LUT4 addr0_4_s4 (
    .F(addr0_4_8),
    .I0(wp[3]),
    .I1(wp[2]),
    .I2(wp[0]),
    .I3(wp[1]) 
);
defparam addr0_4_s4.INIT=16'h8000;
  LUT3 addr0_6_s4 (
    .F(addr0_6_8),
    .I0(wp[5]),
    .I1(wp[4]),
    .I2(addr0_4_8) 
);
defparam addr0_6_s4.INIT=8'h80;
  LUT4 addr1_6_s11 (
    .F(addr1[6]),
    .I0(tap_base[6]),
    .I1(base[2]),
    .I2(base[1]),
    .I3(addr1_6_18) 
);
defparam addr1_6_s11.INIT=16'hA9AA;
  LUT4 addr1_8_s10 (
    .F(addr1[8]),
    .I0(tap_base[8]),
    .I1(base[2]),
    .I2(base[1]),
    .I3(addr1_8_14) 
);
defparam addr1_8_s10.INIT=16'hA9AA;
  LUT4 addr3_6_s9 (
    .F(addr3[6]),
    .I0(tap_base[6]),
    .I1(base[2]),
    .I2(base[1]),
    .I3(addr1_6_18) 
);
defparam addr3_6_s9.INIT=16'h95AA;
  LUT4 addr3_8_s9 (
    .F(addr3[8]),
    .I0(tap_base[8]),
    .I1(base[2]),
    .I2(base[1]),
    .I3(addr1_8_14) 
);
defparam addr3_8_s9.INIT=16'h95AA;
  LUT3 n1170_s4 (
    .F(n1170_10),
    .I0(index[5]),
    .I1(index[4]),
    .I2(n1172_10) 
);
defparam n1170_s4.INIT=8'h80;
  LUT4 n1171_s4 (
    .F(n1171_10),
    .I0(accept),
    .I1(index[5]),
    .I2(index[4]),
    .I3(n1172_10) 
);
defparam n1171_s4.INIT=16'h1444;
  LUT4 sum0_39_s13 (
    .F(sum0_39_19),
    .I0(index[7]),
    .I1(n2972_6),
    .I2(n2972_7),
    .I3(index_7_10) 
);
defparam sum0_39_s13.INIT=16'hBF00;
  LUT4 accept_s9 (
    .F(accept_16),
    .I0(audio_pa_en_d),
    .I1(left_reg_15_11),
    .I2(n3004_6),
    .I3(busy) 
);
defparam accept_s9.INIT=16'h0F88;
  LUT4 n2960_s3 (
    .F(n2960_8),
    .I0(busy),
    .I1(fill[10]),
    .I2(audio_pa_en_d),
    .I3(left_reg_15_11) 
);
defparam n2960_s3.INIT=16'h1000;
  LUT3 accept_s10 (
    .F(accept),
    .I0(busy),
    .I1(audio_pa_en_d),
    .I2(left_reg_15_11) 
);
defparam accept_s10.INIT=8'h40;
  LUT4 n837_s5 (
    .F(n837_12),
    .I0(busy),
    .I1(audio_pa_en_d),
    .I2(left_reg_15_11),
    .I3(wp[0]) 
);
defparam n837_s5.INIT=16'hBF40;
  LUT3 index_7_s4 (
    .F(index_7_10),
    .I0(busy),
    .I1(audio_pa_en_d),
    .I2(left_reg_15_11) 
);
defparam index_7_s4.INIT=8'hEA;
  DFFCE c0_15_s0 (
    .Q(c0[15]),
    .D(n6_6),
    .CLK(clk_12m288),
    .CLEAR(GND),
    .CE(VCC) 
);
  DFFCE wp_9_s0 (
    .Q(wp[9]),
    .D(n828_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_8_s0 (
    .Q(wp[8]),
    .D(n829_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_7_s0 (
    .Q(wp[7]),
    .D(n830_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_6_s0 (
    .Q(wp[6]),
    .D(n831_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_5_s0 (
    .Q(wp[5]),
    .D(n832_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_4_s0 (
    .Q(wp[4]),
    .D(n833_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_3_s0 (
    .Q(wp[3]),
    .D(n834_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_2_s0 (
    .Q(wp[2]),
    .D(n835_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE wp_1_s0 (
    .Q(wp[1]),
    .D(n836_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_9_s0 (
    .Q(base[9]),
    .D(wp[9]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_8_s0 (
    .Q(base[8]),
    .D(wp[8]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_7_s0 (
    .Q(base[7]),
    .D(wp[7]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_6_s0 (
    .Q(base[6]),
    .D(wp[6]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_5_s0 (
    .Q(base[5]),
    .D(wp[5]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_4_s0 (
    .Q(base[4]),
    .D(wp[4]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_3_s0 (
    .Q(base[3]),
    .D(wp[3]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_2_s0 (
    .Q(base[2]),
    .D(wp[2]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_1_s0 (
    .Q(base[1]),
    .D(wp[1]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE base_0_s0 (
    .Q(base[0]),
    .D(wp[0]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE fill_10_s0 (
    .Q(fill[10]),
    .D(n840_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_9_s0 (
    .Q(fill[9]),
    .D(n841_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_8_s0 (
    .Q(fill[8]),
    .D(n842_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_7_s0 (
    .Q(fill[7]),
    .D(n843_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_6_s0 (
    .Q(fill[6]),
    .D(n844_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_5_s0 (
    .Q(fill[5]),
    .D(n845_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_4_s0 (
    .Q(fill[4]),
    .D(n846_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_3_s0 (
    .Q(fill[3]),
    .D(n847_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_2_s0 (
    .Q(fill[2]),
    .D(n848_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE fill_1_s0 (
    .Q(fill[1]),
    .D(n849_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2960_8) 
);
  DFFCE x_delayed_15_s0 (
    .Q(x_delayed[15]),
    .D(q0[15]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_14_s0 (
    .Q(x_delayed[14]),
    .D(q0[14]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_13_s0 (
    .Q(x_delayed[13]),
    .D(q0[13]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_12_s0 (
    .Q(x_delayed[12]),
    .D(q0[12]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_11_s0 (
    .Q(x_delayed[11]),
    .D(q0[11]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_10_s0 (
    .Q(x_delayed[10]),
    .D(q0[10]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_9_s0 (
    .Q(x_delayed[9]),
    .D(q0[9]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_8_s0 (
    .Q(x_delayed[8]),
    .D(q0[8]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_7_s0 (
    .Q(x_delayed[7]),
    .D(q0[7]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_6_s0 (
    .Q(x_delayed[6]),
    .D(q0[6]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_5_s0 (
    .Q(x_delayed[5]),
    .D(q0[5]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_4_s0 (
    .Q(x_delayed[4]),
    .D(q0[4]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_3_s0 (
    .Q(x_delayed[3]),
    .D(q0[3]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_2_s0 (
    .Q(x_delayed[2]),
    .D(q0[2]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_1_s0 (
    .Q(x_delayed[1]),
    .D(q0[1]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE x_delayed_0_s0 (
    .Q(x_delayed[0]),
    .D(q0[0]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n2972_9) 
);
  DFFCE held_pcm_15_s0 (
    .Q(held_pcm[15]),
    .D(visual_pcm[23]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_14_s0 (
    .Q(held_pcm[14]),
    .D(visual_pcm[22]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_13_s0 (
    .Q(held_pcm[13]),
    .D(visual_pcm[21]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_12_s0 (
    .Q(held_pcm[12]),
    .D(visual_pcm[20]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_11_s0 (
    .Q(held_pcm[11]),
    .D(u_synth_top_4_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_10_s0 (
    .Q(held_pcm[10]),
    .D(u_synth_top_5_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_9_s0 (
    .Q(held_pcm[9]),
    .D(u_synth_top_6_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE held_pcm_8_s0 (
    .Q(held_pcm[8]),
    .D(u_synth_top_7_1),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(accept) 
);
  DFFCE valid_s0 (
    .Q(paired_valid),
    .D(n1718_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(VCC) 
);
  DFFCE wave_sample_15_s0 (
    .Q(paired_pcm[15]),
    .D(held_pcm[15]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_14_s0 (
    .Q(paired_pcm[14]),
    .D(held_pcm[14]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_13_s0 (
    .Q(paired_pcm[13]),
    .D(held_pcm[13]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_12_s0 (
    .Q(paired_pcm[12]),
    .D(held_pcm[12]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_11_s0 (
    .Q(paired_pcm[11]),
    .D(held_pcm[11]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_10_s0 (
    .Q(paired_pcm[10]),
    .D(held_pcm[10]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_9_s0 (
    .Q(paired_pcm[9]),
    .D(held_pcm[9]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE wave_sample_8_s0 (
    .Q(paired_pcm[8]),
    .D(held_pcm[8]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_15_s0 (
    .Q(paired_x[15]),
    .D(x_delayed[15]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_14_s0 (
    .Q(paired_x[14]),
    .D(x_delayed[14]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_13_s0 (
    .Q(paired_x[13]),
    .D(x_delayed[13]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_12_s0 (
    .Q(paired_x[12]),
    .D(x_delayed[12]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_11_s0 (
    .Q(paired_x[11]),
    .D(x_delayed[11]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_10_s0 (
    .Q(paired_x[10]),
    .D(x_delayed[10]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_9_s0 (
    .Q(paired_x[9]),
    .D(x_delayed[9]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_8_s0 (
    .Q(paired_x[8]),
    .D(x_delayed[8]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_7_s0 (
    .Q(paired_x[7]),
    .D(x_delayed[7]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_6_s0 (
    .Q(paired_x[6]),
    .D(x_delayed[6]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_5_s0 (
    .Q(paired_x[5]),
    .D(x_delayed[5]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_4_s0 (
    .Q(paired_x[4]),
    .D(x_delayed[4]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_3_s0 (
    .Q(paired_x[3]),
    .D(x_delayed[3]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_2_s0 (
    .Q(paired_x[2]),
    .D(x_delayed[2]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_1_s0 (
    .Q(paired_x[1]),
    .D(x_delayed[1]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE x_sample_0_s0 (
    .Q(paired_x[0]),
    .D(x_delayed[0]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_15_s0 (
    .Q(paired_y[15]),
    .D(total[41]),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_14_s0 (
    .Q(paired_y[14]),
    .D(n1085_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_13_s0 (
    .Q(paired_y[13]),
    .D(n1086_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_12_s0 (
    .Q(paired_y[12]),
    .D(n1087_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_11_s0 (
    .Q(paired_y[11]),
    .D(n1088_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_10_s0 (
    .Q(paired_y[10]),
    .D(n1089_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_9_s0 (
    .Q(paired_y[9]),
    .D(n1090_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_8_s0 (
    .Q(paired_y[8]),
    .D(n1091_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_7_s0 (
    .Q(paired_y[7]),
    .D(n1092_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_6_s0 (
    .Q(paired_y[6]),
    .D(n1093_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_5_s0 (
    .Q(paired_y[5]),
    .D(n1094_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_4_s0 (
    .Q(paired_y[4]),
    .D(n1095_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_3_s0 (
    .Q(paired_y[3]),
    .D(n1096_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_2_s0 (
    .Q(paired_y[2]),
    .D(n1097_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_1_s0 (
    .Q(paired_y[1]),
    .D(n1098_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE y_sample_0_s0 (
    .Q(paired_y[0]),
    .D(n1099_6),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(n3004_6) 
);
  DFFCE index_7_s1 (
    .Q(index[7]),
    .D(n1169_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_7_s1.INIT=1'b0;
  DFFCE index_6_s1 (
    .Q(index[6]),
    .D(n1170_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_6_s1.INIT=1'b0;
  DFFCE index_5_s1 (
    .Q(index[5]),
    .D(n1171_10),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_5_s1.INIT=1'b0;
  DFFCE index_4_s1 (
    .Q(index[4]),
    .D(n1172_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_4_s1.INIT=1'b0;
  DFFCE index_3_s1 (
    .Q(index[3]),
    .D(n1173_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_3_s1.INIT=1'b0;
  DFFCE index_2_s1 (
    .Q(index[2]),
    .D(n1174_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_2_s1.INIT=1'b0;
  DFFCE index_1_s1 (
    .Q(index[1]),
    .D(n1175_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_1_s1.INIT=1'b0;
  DFFCE index_0_s1 (
    .Q(index[0]),
    .D(n1176_7),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(index_7_10) 
);
defparam index_0_s1.INIT=1'b0;
  DFFCE wp_0_s9 (
    .Q(wp[0]),
    .D(n837_12),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(VCC) 
);
defparam wp_0_s9.INIT=1'b0;
  DFFCE fill_0_s1 (
    .Q(fill[0]),
    .D(n850_8),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(VCC) 
);
defparam fill_0_s1.INIT=1'b0;
  DFFCE busy_s4 (
    .Q(busy),
    .D(accept_16),
    .CLK(clk_12m288),
    .CLEAR(n114_32),
    .CE(VCC) 
);
defparam busy_s4.INIT=1'b0;
  SDPB history_history_0_0_s (
    .DO({DO[31:16],q0[15:0]}),
    .CLKA(clk_12m288),
    .CEA(accept),
    .CLKB(clk_12m288),
    .CEB(VCC),
    .OCE(GND),
    .RESET(GND),
    .ADA({wp[9:0],GND,GND,VCC,VCC}),
    .ADB({addr0[9:0],GND,GND,GND,GND}),
    .DI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,visual_pcm[23:20],u_synth_top_4_1,u_synth_top_5_1,u_synth_top_6_1,u_synth_top_7_1,u_synth_top_8_1,u_synth_top_9_1,u_synth_top_10_1,u_synth_top_11_1,u_synth_top_12_1,u_synth_top_13_1,u_synth_top_14_1,u_synth_top_15_1}),
    .BLKSELA({GND,GND,GND}),
    .BLKSELB({GND,GND,GND}) 
);
defparam history_history_0_0_s.BIT_WIDTH_0=16;
defparam history_history_0_0_s.BIT_WIDTH_1=16;
defparam history_history_0_0_s.READ_MODE=1'b0;
defparam history_history_0_0_s.RESET_MODE="SYNC";
defparam history_history_0_0_s.BLK_SEL_0=3'b000;
defparam history_history_0_0_s.BLK_SEL_1=3'b000;
  SDPB history_history_0_0_s0 (
    .DO({DO_0[31:16],q1[15:0]}),
    .CLKA(clk_12m288),
    .CEA(accept),
    .CLKB(clk_12m288),
    .CEB(VCC),
    .OCE(GND),
    .RESET(GND),
    .ADA({wp[9:0],GND,GND,VCC,VCC}),
    .ADB({addr1[9:2],addr3[1],base[0],GND,GND,GND,GND}),
    .DI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,visual_pcm[23:20],u_synth_top_4_1,u_synth_top_5_1,u_synth_top_6_1,u_synth_top_7_1,u_synth_top_8_1,u_synth_top_9_1,u_synth_top_10_1,u_synth_top_11_1,u_synth_top_12_1,u_synth_top_13_1,u_synth_top_14_1,u_synth_top_15_1}),
    .BLKSELA({GND,GND,GND}),
    .BLKSELB({GND,GND,GND}) 
);
defparam history_history_0_0_s0.BIT_WIDTH_0=16;
defparam history_history_0_0_s0.BIT_WIDTH_1=16;
defparam history_history_0_0_s0.READ_MODE=1'b0;
defparam history_history_0_0_s0.RESET_MODE="SYNC";
defparam history_history_0_0_s0.BLK_SEL_0=3'b000;
defparam history_history_0_0_s0.BLK_SEL_1=3'b000;
  SDPB history_history_0_0_s1 (
    .DO({DO_1[31:16],q2[15:0]}),
    .CLKA(clk_12m288),
    .CEA(accept),
    .CLKB(clk_12m288),
    .CEB(VCC),
    .OCE(GND),
    .RESET(GND),
    .ADA({wp[9:0],GND,GND,VCC,VCC}),
    .ADB({addr2[9:2],base[1:0],GND,GND,GND,GND}),
    .DI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,visual_pcm[23:20],u_synth_top_4_1,u_synth_top_5_1,u_synth_top_6_1,u_synth_top_7_1,u_synth_top_8_1,u_synth_top_9_1,u_synth_top_10_1,u_synth_top_11_1,u_synth_top_12_1,u_synth_top_13_1,u_synth_top_14_1,u_synth_top_15_1}),
    .BLKSELA({GND,GND,GND}),
    .BLKSELB({GND,GND,GND}) 
);
defparam history_history_0_0_s1.BIT_WIDTH_0=16;
defparam history_history_0_0_s1.BIT_WIDTH_1=16;
defparam history_history_0_0_s1.READ_MODE=1'b0;
defparam history_history_0_0_s1.RESET_MODE="SYNC";
defparam history_history_0_0_s1.BLK_SEL_0=3'b000;
defparam history_history_0_0_s1.BLK_SEL_1=3'b000;
  SDPB history_history_0_0_s2 (
    .DO({DO_2[31:16],q3[15:0]}),
    .CLKA(clk_12m288),
    .CEA(accept),
    .CLKB(clk_12m288),
    .CEB(VCC),
    .OCE(GND),
    .RESET(GND),
    .ADA({wp[9:0],GND,GND,VCC,VCC}),
    .ADB({addr3[9:1],base[0],GND,GND,GND,GND}),
    .DI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,visual_pcm[23:20],u_synth_top_4_1,u_synth_top_5_1,u_synth_top_6_1,u_synth_top_7_1,u_synth_top_8_1,u_synth_top_9_1,u_synth_top_10_1,u_synth_top_11_1,u_synth_top_12_1,u_synth_top_13_1,u_synth_top_14_1,u_synth_top_15_1}),
    .BLKSELA({GND,GND,GND}),
    .BLKSELB({GND,GND,GND}) 
);
defparam history_history_0_0_s2.BIT_WIDTH_0=16;
defparam history_history_0_0_s2.BIT_WIDTH_1=16;
defparam history_history_0_0_s2.READ_MODE=1'b0;
defparam history_history_0_0_s2.RESET_MODE="SYNC";
defparam history_history_0_0_s2.BLK_SEL_0=3'b000;
defparam history_history_0_0_s2.BLK_SEL_1=3'b000;
  pROM c3_0_s1 (
    .DO({c1[7:0],c2[11:0],c3[11:0]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({GND,GND,index[6:0],GND,VCC,VCC,VCC,VCC}) 
);
defparam c3_0_s1.BIT_WIDTH=32;
defparam c3_0_s1.INIT_RAM_00=256'hFBFFBFFBFBFFBFFBFCFFCFFCFCFFCFFCFCFFCFFCFCFFCFFCFDFFDFFDFDFFDFFD;
defparam c3_0_s1.INIT_RAM_01=256'hF5FF5FF5F6FF6FF6F7FF7FF7F8FF8FF7F9FF8FF8F9FF9FF9FAFFAFFAFAFFAFFA;
defparam c3_0_s1.INIT_RAM_02=256'hEAFE9FE9EBFEBFEAEDFEDFECEFFEEFEEF0FF0FEFF2FF1FF1F3FF2FF2F4FF4FF3;
defparam c3_0_s1.INIT_RAM_03=256'hD6FD5FD5D9FD8FD8DCFDBFDBDFFDEFDDE1FE0FE0E3FE3FE2E6FE5FE4E8FE7FE7;
defparam c3_0_s1.INIT_RAM_04=256'hB6FB4FB3BBFBAFB8BFFBEFBDC4FC3FC2C8FC7FC6CCFCBFCACFFCFFCED3FD2FD1;
defparam c3_0_s1.INIT_RAM_05=256'h7AF77F7484F82F7F8DF8BF8995F93F919DF9BF99A4FA2FA1AAFA9FA7B0FAFFAD;
defparam c3_0_s1.INIT_RAM_06=256'hDEED5ECBFFEF7EEF1AF13F0D30F2BF2543F3FF3A54F50F4C62F5FF5B6FF6CF69;
defparam c3_0_s1.INIT_RAM_07=256'hB54D7E83BE89A6F422BBAB3836D00CC2D3DB2D8E39E23E0B80E70E5FB5EA9E9C;
defparam c3_0_s1.INIT_RAM_08=256'h5714B14090180171DD1C71B34E22D210002CA29B463DE3876664256C2904BBA3;
defparam c3_0_s1.INIT_RAM_09=256'h9409108EA109E09BB00AC0A9C10BD0B8D50D00CBED0E60E0091010FA2B122119;
defparam c3_0_s1.INIT_RAM_0A=256'h5105004E570560545E05C05A650630616D06B069750730717E07C07A89086083;
defparam c3_0_s1.INIT_RAM_0B=256'h2E02D02C3103103035034033390380373D03C03B4204103F460450444C04A049;
defparam c3_0_s1.INIT_RAM_0C=256'h190180181B01A01A1D01D01C2001F01E2202102125024023280270262B02A029;
defparam c3_0_s1.INIT_RAM_0D=256'h0C00C00C0E00D00D0F00E00E1001000F12011011130130131501501417016016;
defparam c3_0_s1.INIT_RAM_0E=256'h0600600506006006070070070800700708008008090090090A00A00A0B00B00B;
defparam c3_0_s1.INIT_RAM_0F=256'h0300300303003003040040030400400404004004040040040500500505005005;
defparam c3_0_s1.READ_MODE=1'b0;
defparam c3_0_s1.RESET_MODE="SYNC";
  pROM c3_0_s2 (
    .DO({DO_3[31:18],c0[14],c0[11:0],c1[14],c1[12],c1[10:8]}),
    .CLK(clk_12m288),
    .CE(VCC),
    .OCE(GND),
    .RESET(GND),
    .AD({GND,GND,index[6:0],GND,VCC,VCC,VCC,VCC}) 
);
defparam c3_0_s2.BIT_WIDTH=32;
defparam c3_0_s2.INIT_RAM_00=256'h0003FF7F0003FF7F0003FF9F0003FF9F0003FF9F0003FFBF0003FFBF0003FFBF;
defparam c3_0_s2.INIT_RAM_01=256'h0003FEBF0003FEDF0003FEFF0003FF1F0003FF3F0003FF3F0003FF5F0003FF7F;
defparam c3_0_s2.INIT_RAM_02=256'h0003FD5F0003FD9F0003FDBF0003FDFF0003FE3F0003FE5F0003FE7F0003FE9F;
defparam c3_0_s2.INIT_RAM_03=256'h0003FAFF0003FB5F0003FBBF0003FBFF0003FC5F0003FC9F0003FCDF0003FD1F;
defparam c3_0_s2.INIT_RAM_04=256'h0003F6FF0003F79F0003F83F0003F8BF0003F93F0003F9BF0003FA1F0003FA9F;
defparam c3_0_s2.INIT_RAM_05=256'h0003EFBF0003F0DF0003F1FF0003F2FF0003F3FF0003F4DF0003F59F0003F65F;
defparam c3_0_s2.INIT_RAM_06=256'h0003DCFE0003E0DE0003E41F0003E6BF0003E91F0003EAFF0003ECBF0003EE5F;
defparam c3_0_s2.INIT_RAM_07=256'h00028BB70003529900038F3C0003ACBD0003BE1D0003C9BE0003D1FE0003D81E;
defparam c3_0_s2.INIT_RAM_08=256'h00002C810000342100003EA100004E42000067C3000099040001218700022FAB;
defparam c3_0_s2.INIT_RAM_09=256'h000012E0000014A000001680000018C000001B6000001E6000002221000026A1;
defparam c3_0_s2.INIT_RAM_0A=256'h00000A6000000B2000000BE000000CE000000DE000000EE00000102000001180;
defparam c3_0_s2.INIT_RAM_0B=256'h000005E000000640000006C000000740000007C00000086000000900000009A0;
defparam c3_0_s2.INIT_RAM_0C=256'h0000032000000380000003C00000040000000460000004A00000050000000560;
defparam c3_0_s2.INIT_RAM_0D=256'h000001A0000001C0000001E0000002200000024000000280000002C0000002E0;
defparam c3_0_s2.INIT_RAM_0E=256'h000000C0000000C0000000E00000010000000120000001200000014000000160;
defparam c3_0_s2.INIT_RAM_0F=256'h000000600000006000000080000000800000008000000080000000A0000000A0;
defparam c3_0_s2.READ_MODE=1'b0;
defparam c3_0_s2.RESET_MODE="SYNC";
  MULTALU27X18 p0_0_s (
    .DOUT({DOUT[47:40],t0[39:0]}),
    .CASO(CASO[47:0]),
    .SOA(SOA[26:0]),
    .A({q0[15],q0[15],q0[15],q0[15],q0[15],q0[15],q0[15],q0[15],q0[15],q0[15],q0[15],q0[15:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({c0[15],c0[15],c0[15:14],c0[15:14],c0[11:0]}),
    .C({n1193_7,n1193_7,n1193_7,n1193_7,n1193_7,n1193_7,n1193_7,n1193_7,n1193_7,n1194_7,n1195_7,n1196_7,n1197_7,n1198_7,n1199_7,n1200_7,n1201_7,n1202_7,n1203_7,n1204_7,n1205_7,n1206_7,n1207_7,n1208_7,n1209_7,n1210_7,n1211_7,n1212_7,n1213_7,n1214_7,n1215_7,n1216_7,n1217_7,n1218_7,n1219_7,n1220_7,n1221_7,n1222_7,n1223_7,n1224_7,n1225_7,n1226_7,n1227_7,n1228_7,n1229_7,n1230_7,n1231_7,n1232_7}),
    .D({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,sum0_39_19}),
    .RESET({GND,n114_32}) 
);
defparam p0_0_s.MULT_RESET_MODE="ASYNC";
defparam p0_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam p0_0_s.ACCSEL_IREG_CE="CE0";
defparam p0_0_s.ACCSEL_IREG_RESET="RESET0";
defparam p0_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam p0_0_s.ADDSUB0_IREG_CE="CE0";
defparam p0_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam p0_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam p0_0_s.ADDSUB1_IREG_CE="CE0";
defparam p0_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam p0_0_s.FB_PREG_EN="FALSE";
defparam p0_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam p0_0_s.ACCSEL_PREG_CE="CE0";
defparam p0_0_s.ACCSEL_PREG_RESET="RESET0";
defparam p0_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam p0_0_s.ADDSUB0_PREG_CE="CE0";
defparam p0_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam p0_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam p0_0_s.ADDSUB1_PREG_CE="CE0";
defparam p0_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam p0_0_s.OREG_CLK="BYPASS";
defparam p0_0_s.OREG_CE="CE0";
defparam p0_0_s.OREG_RESET="RESET0";
defparam p0_0_s.PRE_LOAD=48'h000000000000;
defparam p0_0_s.CASI_SEL=1'b0;
defparam p0_0_s.AREG_CLK="BYPASS";
defparam p0_0_s.AREG_CE="CE0";
defparam p0_0_s.AREG_RESET="RESET0";
defparam p0_0_s.BREG_CLK="BYPASS";
defparam p0_0_s.BREG_CE="CE0";
defparam p0_0_s.BREG_RESET="RESET0";
defparam p0_0_s.DREG_CLK="BYPASS";
defparam p0_0_s.DREG_CE="CE0";
defparam p0_0_s.DREG_RESET="RESET0";
defparam p0_0_s.PREG_CLK="BYPASS";
defparam p0_0_s.PREG_CE="CE0";
defparam p0_0_s.PREG_RESET="RESET0";
defparam p0_0_s.SOA_PREG_EN="FALSE";
defparam p0_0_s.DYN_P_SEL="FALSE";
defparam p0_0_s.P_SEL=1'b0;
defparam p0_0_s.DYN_P_ADDSUB="FALSE";
defparam p0_0_s.P_ADDSUB=1'b0;
defparam p0_0_s.ACC_SEL=1'b0;
defparam p0_0_s.ADD_SUB_0=1'b0;
defparam p0_0_s.ADD_SUB_1=1'b0;
defparam p0_0_s.A_SEL=1'b0;
defparam p0_0_s.CASISEL_IREG_CE="CE0";
defparam p0_0_s.CASISEL_IREG_CLK="BYPASS";
defparam p0_0_s.CASISEL_IREG_RESET="RESET0";
defparam p0_0_s.CASISEL_PREG_CE="CE0";
defparam p0_0_s.CASISEL_PREG_CLK="BYPASS";
defparam p0_0_s.CASISEL_PREG_RESET="RESET0";
defparam p0_0_s.CSEL_IREG_CE="CE0";
defparam p0_0_s.CSEL_IREG_CLK="BYPASS";
defparam p0_0_s.CSEL_IREG_RESET="RESET0";
defparam p0_0_s.CSEL_PREG_CE="CE0";
defparam p0_0_s.CSEL_PREG_CLK="BYPASS";
defparam p0_0_s.CSEL_PREG_RESET="RESET0";
defparam p0_0_s.C_IREG_CE="CE0";
defparam p0_0_s.C_IREG_CLK="CLK0";
defparam p0_0_s.C_IREG_RESET="RESET0";
defparam p0_0_s.C_PREG_CE="CE0";
defparam p0_0_s.C_PREG_CLK="BYPASS";
defparam p0_0_s.C_PREG_RESET="RESET0";
defparam p0_0_s.C_SEL=1'b1;
defparam p0_0_s.DYN_ACC_SEL="FALSE";
defparam p0_0_s.DYN_ADD_SUB_0="FALSE";
defparam p0_0_s.DYN_ADD_SUB_1="FALSE";
defparam p0_0_s.DYN_A_SEL="FALSE";
defparam p0_0_s.DYN_CASI_SEL="FALSE";
defparam p0_0_s.DYN_C_SEL="FALSE";
defparam p0_0_s.MULT12X12_EN="FALSE";
defparam p0_0_s.PADDSUB_IREG_CE="CE0";
defparam p0_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam p0_0_s.PADDSUB_IREG_RESET="RESET0";
defparam p0_0_s.PSEL_IREG_CE="CE0";
defparam p0_0_s.PSEL_IREG_CLK="BYPASS";
defparam p0_0_s.PSEL_IREG_RESET="RESET0";
  MULTALU27X18 p1_0_s (
    .DOUT({DOUT_0[47:40],t1[39:0]}),
    .CASO(CASO_0[47:0]),
    .SOA(SOA_0[26:0]),
    .A({q1[15],q1[15],q1[15],q1[15],q1[15],q1[15],q1[15],q1[15],q1[15],q1[15],q1[15],q1[15:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({c0[15],c0[15],c0[15],c1[14],c0[15],c1[12],c0[14],c1[10:0]}),
    .C({n1233_7,n1233_7,n1233_7,n1233_7,n1233_7,n1233_7,n1233_7,n1233_7,n1233_7,n1234_7,n1235_7,n1236_7,n1237_7,n1238_7,n1239_7,n1240_7,n1241_7,n1242_7,n1243_7,n1244_7,n1245_7,n1246_7,n1247_7,n1248_7,n1249_7,n1250_7,n1251_7,n1252_7,n1253_7,n1254_7,n1255_7,n1256_7,n1257_7,n1258_7,n1259_7,n1260_7,n1261_7,n1262_7,n1263_7,n1264_7,n1265_7,n1266_7,n1267_7,n1268_7,n1269_7,n1270_7,n1271_7,n1272_7}),
    .D({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,sum0_39_19}),
    .RESET({GND,n114_32}) 
);
defparam p1_0_s.MULT_RESET_MODE="ASYNC";
defparam p1_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam p1_0_s.ACCSEL_IREG_CE="CE0";
defparam p1_0_s.ACCSEL_IREG_RESET="RESET0";
defparam p1_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam p1_0_s.ADDSUB0_IREG_CE="CE0";
defparam p1_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam p1_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam p1_0_s.ADDSUB1_IREG_CE="CE0";
defparam p1_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam p1_0_s.FB_PREG_EN="FALSE";
defparam p1_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam p1_0_s.ACCSEL_PREG_CE="CE0";
defparam p1_0_s.ACCSEL_PREG_RESET="RESET0";
defparam p1_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam p1_0_s.ADDSUB0_PREG_CE="CE0";
defparam p1_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam p1_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam p1_0_s.ADDSUB1_PREG_CE="CE0";
defparam p1_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam p1_0_s.OREG_CLK="BYPASS";
defparam p1_0_s.OREG_CE="CE0";
defparam p1_0_s.OREG_RESET="RESET0";
defparam p1_0_s.PRE_LOAD=48'h000000000000;
defparam p1_0_s.CASI_SEL=1'b0;
defparam p1_0_s.AREG_CLK="BYPASS";
defparam p1_0_s.AREG_CE="CE0";
defparam p1_0_s.AREG_RESET="RESET0";
defparam p1_0_s.BREG_CLK="BYPASS";
defparam p1_0_s.BREG_CE="CE0";
defparam p1_0_s.BREG_RESET="RESET0";
defparam p1_0_s.DREG_CLK="BYPASS";
defparam p1_0_s.DREG_CE="CE0";
defparam p1_0_s.DREG_RESET="RESET0";
defparam p1_0_s.PREG_CLK="BYPASS";
defparam p1_0_s.PREG_CE="CE0";
defparam p1_0_s.PREG_RESET="RESET0";
defparam p1_0_s.SOA_PREG_EN="FALSE";
defparam p1_0_s.DYN_P_SEL="FALSE";
defparam p1_0_s.P_SEL=1'b0;
defparam p1_0_s.DYN_P_ADDSUB="FALSE";
defparam p1_0_s.P_ADDSUB=1'b0;
defparam p1_0_s.ACC_SEL=1'b0;
defparam p1_0_s.ADD_SUB_0=1'b0;
defparam p1_0_s.ADD_SUB_1=1'b0;
defparam p1_0_s.A_SEL=1'b0;
defparam p1_0_s.CASISEL_IREG_CE="CE0";
defparam p1_0_s.CASISEL_IREG_CLK="BYPASS";
defparam p1_0_s.CASISEL_IREG_RESET="RESET0";
defparam p1_0_s.CASISEL_PREG_CE="CE0";
defparam p1_0_s.CASISEL_PREG_CLK="BYPASS";
defparam p1_0_s.CASISEL_PREG_RESET="RESET0";
defparam p1_0_s.CSEL_IREG_CE="CE0";
defparam p1_0_s.CSEL_IREG_CLK="BYPASS";
defparam p1_0_s.CSEL_IREG_RESET="RESET0";
defparam p1_0_s.CSEL_PREG_CE="CE0";
defparam p1_0_s.CSEL_PREG_CLK="BYPASS";
defparam p1_0_s.CSEL_PREG_RESET="RESET0";
defparam p1_0_s.C_IREG_CE="CE0";
defparam p1_0_s.C_IREG_CLK="CLK0";
defparam p1_0_s.C_IREG_RESET="RESET0";
defparam p1_0_s.C_PREG_CE="CE0";
defparam p1_0_s.C_PREG_CLK="BYPASS";
defparam p1_0_s.C_PREG_RESET="RESET0";
defparam p1_0_s.C_SEL=1'b1;
defparam p1_0_s.DYN_ACC_SEL="FALSE";
defparam p1_0_s.DYN_ADD_SUB_0="FALSE";
defparam p1_0_s.DYN_ADD_SUB_1="FALSE";
defparam p1_0_s.DYN_A_SEL="FALSE";
defparam p1_0_s.DYN_CASI_SEL="FALSE";
defparam p1_0_s.DYN_C_SEL="FALSE";
defparam p1_0_s.MULT12X12_EN="FALSE";
defparam p1_0_s.PADDSUB_IREG_CE="CE0";
defparam p1_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam p1_0_s.PADDSUB_IREG_RESET="RESET0";
defparam p1_0_s.PSEL_IREG_CE="CE0";
defparam p1_0_s.PSEL_IREG_CLK="BYPASS";
defparam p1_0_s.PSEL_IREG_RESET="RESET0";
  MULTALU27X18 p2_0_s (
    .DOUT({DOUT_1[47:40],t2[39:0]}),
    .CASO(CASO_1[47:0]),
    .SOA(SOA_1[26:0]),
    .A({q2[15],q2[15],q2[15],q2[15],q2[15],q2[15],q2[15],q2[15],q2[15],q2[15],q2[15],q2[15:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({c0[15],c0[15],c0[15],c1[14],c0[15],c1[12],c2[11:0]}),
    .C({n1273_7,n1273_7,n1273_7,n1273_7,n1273_7,n1273_7,n1273_7,n1273_7,n1273_7,n1274_7,n1275_7,n1276_7,n1277_7,n1278_7,n1279_7,n1280_7,n1281_7,n1282_7,n1283_7,n1284_7,n1285_7,n1286_7,n1287_7,n1288_7,n1289_7,n1290_7,n1291_7,n1292_7,n1293_7,n1294_7,n1295_7,n1296_7,n1297_7,n1298_7,n1299_7,n1300_7,n1301_7,n1302_7,n1303_7,n1304_7,n1305_7,n1306_7,n1307_7,n1308_7,n1309_7,n1310_7,n1311_7,n1312_7}),
    .D({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,sum0_39_19}),
    .RESET({GND,n114_32}) 
);
defparam p2_0_s.MULT_RESET_MODE="ASYNC";
defparam p2_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam p2_0_s.ACCSEL_IREG_CE="CE0";
defparam p2_0_s.ACCSEL_IREG_RESET="RESET0";
defparam p2_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam p2_0_s.ADDSUB0_IREG_CE="CE0";
defparam p2_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam p2_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam p2_0_s.ADDSUB1_IREG_CE="CE0";
defparam p2_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam p2_0_s.FB_PREG_EN="FALSE";
defparam p2_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam p2_0_s.ACCSEL_PREG_CE="CE0";
defparam p2_0_s.ACCSEL_PREG_RESET="RESET0";
defparam p2_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam p2_0_s.ADDSUB0_PREG_CE="CE0";
defparam p2_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam p2_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam p2_0_s.ADDSUB1_PREG_CE="CE0";
defparam p2_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam p2_0_s.OREG_CLK="BYPASS";
defparam p2_0_s.OREG_CE="CE0";
defparam p2_0_s.OREG_RESET="RESET0";
defparam p2_0_s.PRE_LOAD=48'h000000000000;
defparam p2_0_s.CASI_SEL=1'b0;
defparam p2_0_s.AREG_CLK="BYPASS";
defparam p2_0_s.AREG_CE="CE0";
defparam p2_0_s.AREG_RESET="RESET0";
defparam p2_0_s.BREG_CLK="BYPASS";
defparam p2_0_s.BREG_CE="CE0";
defparam p2_0_s.BREG_RESET="RESET0";
defparam p2_0_s.DREG_CLK="BYPASS";
defparam p2_0_s.DREG_CE="CE0";
defparam p2_0_s.DREG_RESET="RESET0";
defparam p2_0_s.PREG_CLK="BYPASS";
defparam p2_0_s.PREG_CE="CE0";
defparam p2_0_s.PREG_RESET="RESET0";
defparam p2_0_s.SOA_PREG_EN="FALSE";
defparam p2_0_s.DYN_P_SEL="FALSE";
defparam p2_0_s.P_SEL=1'b0;
defparam p2_0_s.DYN_P_ADDSUB="FALSE";
defparam p2_0_s.P_ADDSUB=1'b0;
defparam p2_0_s.ACC_SEL=1'b0;
defparam p2_0_s.ADD_SUB_0=1'b0;
defparam p2_0_s.ADD_SUB_1=1'b0;
defparam p2_0_s.A_SEL=1'b0;
defparam p2_0_s.CASISEL_IREG_CE="CE0";
defparam p2_0_s.CASISEL_IREG_CLK="BYPASS";
defparam p2_0_s.CASISEL_IREG_RESET="RESET0";
defparam p2_0_s.CASISEL_PREG_CE="CE0";
defparam p2_0_s.CASISEL_PREG_CLK="BYPASS";
defparam p2_0_s.CASISEL_PREG_RESET="RESET0";
defparam p2_0_s.CSEL_IREG_CE="CE0";
defparam p2_0_s.CSEL_IREG_CLK="BYPASS";
defparam p2_0_s.CSEL_IREG_RESET="RESET0";
defparam p2_0_s.CSEL_PREG_CE="CE0";
defparam p2_0_s.CSEL_PREG_CLK="BYPASS";
defparam p2_0_s.CSEL_PREG_RESET="RESET0";
defparam p2_0_s.C_IREG_CE="CE0";
defparam p2_0_s.C_IREG_CLK="CLK0";
defparam p2_0_s.C_IREG_RESET="RESET0";
defparam p2_0_s.C_PREG_CE="CE0";
defparam p2_0_s.C_PREG_CLK="BYPASS";
defparam p2_0_s.C_PREG_RESET="RESET0";
defparam p2_0_s.C_SEL=1'b1;
defparam p2_0_s.DYN_ACC_SEL="FALSE";
defparam p2_0_s.DYN_ADD_SUB_0="FALSE";
defparam p2_0_s.DYN_ADD_SUB_1="FALSE";
defparam p2_0_s.DYN_A_SEL="FALSE";
defparam p2_0_s.DYN_CASI_SEL="FALSE";
defparam p2_0_s.DYN_C_SEL="FALSE";
defparam p2_0_s.MULT12X12_EN="FALSE";
defparam p2_0_s.PADDSUB_IREG_CE="CE0";
defparam p2_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam p2_0_s.PADDSUB_IREG_RESET="RESET0";
defparam p2_0_s.PSEL_IREG_CE="CE0";
defparam p2_0_s.PSEL_IREG_CLK="BYPASS";
defparam p2_0_s.PSEL_IREG_RESET="RESET0";
  MULTALU27X18 p3_0_s (
    .DOUT({DOUT_2[47:40],t3[39:0]}),
    .CASO(CASO_2[47:0]),
    .SOA(SOA_2[26:0]),
    .A({q3[15],q3[15],q3[15],q3[15],q3[15],q3[15],q3[15],q3[15],q3[15],q3[15],q3[15],q3[15:0]}),
    .SIA({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .B({c0[15],c0[15],c0[15],c2[11],c0[15],c2[11],c3[11:0]}),
    .C({n1313_7,n1313_7,n1313_7,n1313_7,n1313_7,n1313_7,n1313_7,n1313_7,n1313_7,n1314_7,n1315_7,n1316_7,n1317_7,n1318_7,n1319_7,n1320_7,n1321_7,n1322_7,n1323_7,n1324_7,n1325_7,n1326_7,n1327_7,n1328_7,n1329_7,n1330_7,n1331_7,n1332_7,n1333_7,n1334_7,n1335_7,n1336_7,n1337_7,n1338_7,n1339_7,n1340_7,n1341_7,n1342_7,n1343_7,n1344_7,n1345_7,n1346_7,n1347_7,n1348_7,n1349_7,n1350_7,n1351_7,n1352_7}),
    .D({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .CASI({GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND,GND}),
    .ACCSEL(GND),
    .PSEL(GND),
    .ASEL(GND),
    .PADDSUB(GND),
    .CSEL(GND),
    .CASISEL(GND),
    .ADDSUB({GND,GND}),
    .CLK({GND,clk_12m288}),
    .CE({VCC,sum0_39_19}),
    .RESET({GND,n114_32}) 
);
defparam p3_0_s.MULT_RESET_MODE="ASYNC";
defparam p3_0_s.ACCSEL_IREG_CLK="BYPASS";
defparam p3_0_s.ACCSEL_IREG_CE="CE0";
defparam p3_0_s.ACCSEL_IREG_RESET="RESET0";
defparam p3_0_s.ADDSUB0_IREG_CLK="BYPASS";
defparam p3_0_s.ADDSUB0_IREG_CE="CE0";
defparam p3_0_s.ADDSUB0_IREG_RESET="RESET0";
defparam p3_0_s.ADDSUB1_IREG_CLK="BYPASS";
defparam p3_0_s.ADDSUB1_IREG_CE="CE0";
defparam p3_0_s.ADDSUB1_IREG_RESET="RESET0";
defparam p3_0_s.FB_PREG_EN="FALSE";
defparam p3_0_s.ACCSEL_PREG_CLK="BYPASS";
defparam p3_0_s.ACCSEL_PREG_CE="CE0";
defparam p3_0_s.ACCSEL_PREG_RESET="RESET0";
defparam p3_0_s.ADDSUB0_PREG_CLK="BYPASS";
defparam p3_0_s.ADDSUB0_PREG_CE="CE0";
defparam p3_0_s.ADDSUB0_PREG_RESET="RESET0";
defparam p3_0_s.ADDSUB1_PREG_CLK="BYPASS";
defparam p3_0_s.ADDSUB1_PREG_CE="CE0";
defparam p3_0_s.ADDSUB1_PREG_RESET="RESET0";
defparam p3_0_s.OREG_CLK="BYPASS";
defparam p3_0_s.OREG_CE="CE0";
defparam p3_0_s.OREG_RESET="RESET0";
defparam p3_0_s.PRE_LOAD=48'h000000000000;
defparam p3_0_s.CASI_SEL=1'b0;
defparam p3_0_s.AREG_CLK="BYPASS";
defparam p3_0_s.AREG_CE="CE0";
defparam p3_0_s.AREG_RESET="RESET0";
defparam p3_0_s.BREG_CLK="BYPASS";
defparam p3_0_s.BREG_CE="CE0";
defparam p3_0_s.BREG_RESET="RESET0";
defparam p3_0_s.DREG_CLK="BYPASS";
defparam p3_0_s.DREG_CE="CE0";
defparam p3_0_s.DREG_RESET="RESET0";
defparam p3_0_s.PREG_CLK="BYPASS";
defparam p3_0_s.PREG_CE="CE0";
defparam p3_0_s.PREG_RESET="RESET0";
defparam p3_0_s.SOA_PREG_EN="FALSE";
defparam p3_0_s.DYN_P_SEL="FALSE";
defparam p3_0_s.P_SEL=1'b0;
defparam p3_0_s.DYN_P_ADDSUB="FALSE";
defparam p3_0_s.P_ADDSUB=1'b0;
defparam p3_0_s.ACC_SEL=1'b0;
defparam p3_0_s.ADD_SUB_0=1'b0;
defparam p3_0_s.ADD_SUB_1=1'b0;
defparam p3_0_s.A_SEL=1'b0;
defparam p3_0_s.CASISEL_IREG_CE="CE0";
defparam p3_0_s.CASISEL_IREG_CLK="BYPASS";
defparam p3_0_s.CASISEL_IREG_RESET="RESET0";
defparam p3_0_s.CASISEL_PREG_CE="CE0";
defparam p3_0_s.CASISEL_PREG_CLK="BYPASS";
defparam p3_0_s.CASISEL_PREG_RESET="RESET0";
defparam p3_0_s.CSEL_IREG_CE="CE0";
defparam p3_0_s.CSEL_IREG_CLK="BYPASS";
defparam p3_0_s.CSEL_IREG_RESET="RESET0";
defparam p3_0_s.CSEL_PREG_CE="CE0";
defparam p3_0_s.CSEL_PREG_CLK="BYPASS";
defparam p3_0_s.CSEL_PREG_RESET="RESET0";
defparam p3_0_s.C_IREG_CE="CE0";
defparam p3_0_s.C_IREG_CLK="CLK0";
defparam p3_0_s.C_IREG_RESET="RESET0";
defparam p3_0_s.C_PREG_CE="CE0";
defparam p3_0_s.C_PREG_CLK="BYPASS";
defparam p3_0_s.C_PREG_RESET="RESET0";
defparam p3_0_s.C_SEL=1'b1;
defparam p3_0_s.DYN_ACC_SEL="FALSE";
defparam p3_0_s.DYN_ADD_SUB_0="FALSE";
defparam p3_0_s.DYN_ADD_SUB_1="FALSE";
defparam p3_0_s.DYN_A_SEL="FALSE";
defparam p3_0_s.DYN_CASI_SEL="FALSE";
defparam p3_0_s.DYN_C_SEL="FALSE";
defparam p3_0_s.MULT12X12_EN="FALSE";
defparam p3_0_s.PADDSUB_IREG_CE="CE0";
defparam p3_0_s.PADDSUB_IREG_CLK="BYPASS";
defparam p3_0_s.PADDSUB_IREG_RESET="RESET0";
defparam p3_0_s.PSEL_IREG_CE="CE0";
defparam p3_0_s.PSEL_IREG_CLK="BYPASS";
defparam p3_0_s.PSEL_IREG_RESET="RESET0";
  ALU total_0_s (
    .SUM(total_0_1),
    .COUT(total_0_2),
    .I0(t0[0]),
    .I1(t1[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam total_0_s.ALU_MODE=0;
  ALU total_1_s (
    .SUM(total_1_1),
    .COUT(total_1_2),
    .I0(t0[1]),
    .I1(t1[1]),
    .I3(GND),
    .CIN(total_0_2) 
);
defparam total_1_s.ALU_MODE=0;
  ALU total_2_s (
    .SUM(total_2_1),
    .COUT(total_2_2),
    .I0(t0[2]),
    .I1(t1[2]),
    .I3(GND),
    .CIN(total_1_2) 
);
defparam total_2_s.ALU_MODE=0;
  ALU total_3_s (
    .SUM(total_3_1),
    .COUT(total_3_2),
    .I0(t0[3]),
    .I1(t1[3]),
    .I3(GND),
    .CIN(total_2_2) 
);
defparam total_3_s.ALU_MODE=0;
  ALU total_4_s (
    .SUM(total_4_1),
    .COUT(total_4_2),
    .I0(t0[4]),
    .I1(t1[4]),
    .I3(GND),
    .CIN(total_3_2) 
);
defparam total_4_s.ALU_MODE=0;
  ALU total_5_s (
    .SUM(total_5_1),
    .COUT(total_5_2),
    .I0(t0[5]),
    .I1(t1[5]),
    .I3(GND),
    .CIN(total_4_2) 
);
defparam total_5_s.ALU_MODE=0;
  ALU total_6_s (
    .SUM(total_6_1),
    .COUT(total_6_2),
    .I0(t0[6]),
    .I1(t1[6]),
    .I3(GND),
    .CIN(total_5_2) 
);
defparam total_6_s.ALU_MODE=0;
  ALU total_7_s (
    .SUM(total_7_1),
    .COUT(total_7_2),
    .I0(t0[7]),
    .I1(t1[7]),
    .I3(GND),
    .CIN(total_6_2) 
);
defparam total_7_s.ALU_MODE=0;
  ALU total_8_s (
    .SUM(total_8_1),
    .COUT(total_8_2),
    .I0(t0[8]),
    .I1(t1[8]),
    .I3(GND),
    .CIN(total_7_2) 
);
defparam total_8_s.ALU_MODE=0;
  ALU total_9_s (
    .SUM(total_9_1),
    .COUT(total_9_2),
    .I0(t0[9]),
    .I1(t1[9]),
    .I3(GND),
    .CIN(total_8_2) 
);
defparam total_9_s.ALU_MODE=0;
  ALU total_10_s (
    .SUM(total_10_1),
    .COUT(total_10_2),
    .I0(t0[10]),
    .I1(t1[10]),
    .I3(GND),
    .CIN(total_9_2) 
);
defparam total_10_s.ALU_MODE=0;
  ALU total_11_s (
    .SUM(total_11_1),
    .COUT(total_11_2),
    .I0(t0[11]),
    .I1(t1[11]),
    .I3(GND),
    .CIN(total_10_2) 
);
defparam total_11_s.ALU_MODE=0;
  ALU total_12_s (
    .SUM(total_12_1),
    .COUT(total_12_2),
    .I0(t0[12]),
    .I1(t1[12]),
    .I3(GND),
    .CIN(total_11_2) 
);
defparam total_12_s.ALU_MODE=0;
  ALU total_13_s (
    .SUM(total_13_1),
    .COUT(total_13_2),
    .I0(t0[13]),
    .I1(t1[13]),
    .I3(GND),
    .CIN(total_12_2) 
);
defparam total_13_s.ALU_MODE=0;
  ALU total_14_s (
    .SUM(total_14_1),
    .COUT(total_14_2),
    .I0(t0[14]),
    .I1(t1[14]),
    .I3(GND),
    .CIN(total_13_2) 
);
defparam total_14_s.ALU_MODE=0;
  ALU total_15_s (
    .SUM(total_15_1),
    .COUT(total_15_2),
    .I0(t0[15]),
    .I1(t1[15]),
    .I3(GND),
    .CIN(total_14_2) 
);
defparam total_15_s.ALU_MODE=0;
  ALU total_16_s (
    .SUM(total_16_1),
    .COUT(total_16_2),
    .I0(t0[16]),
    .I1(t1[16]),
    .I3(GND),
    .CIN(total_15_2) 
);
defparam total_16_s.ALU_MODE=0;
  ALU total_17_s (
    .SUM(total_17_1),
    .COUT(total_17_2),
    .I0(t0[17]),
    .I1(t1[17]),
    .I3(GND),
    .CIN(total_16_2) 
);
defparam total_17_s.ALU_MODE=0;
  ALU total_18_s (
    .SUM(total_18_1),
    .COUT(total_18_2),
    .I0(t0[18]),
    .I1(t1[18]),
    .I3(GND),
    .CIN(total_17_2) 
);
defparam total_18_s.ALU_MODE=0;
  ALU total_19_s (
    .SUM(total_19_1),
    .COUT(total_19_2),
    .I0(t0[19]),
    .I1(t1[19]),
    .I3(GND),
    .CIN(total_18_2) 
);
defparam total_19_s.ALU_MODE=0;
  ALU total_20_s (
    .SUM(total_20_1),
    .COUT(total_20_2),
    .I0(t0[20]),
    .I1(t1[20]),
    .I3(GND),
    .CIN(total_19_2) 
);
defparam total_20_s.ALU_MODE=0;
  ALU total_21_s (
    .SUM(total_21_1),
    .COUT(total_21_2),
    .I0(t0[21]),
    .I1(t1[21]),
    .I3(GND),
    .CIN(total_20_2) 
);
defparam total_21_s.ALU_MODE=0;
  ALU total_22_s (
    .SUM(total_22_1),
    .COUT(total_22_2),
    .I0(t0[22]),
    .I1(t1[22]),
    .I3(GND),
    .CIN(total_21_2) 
);
defparam total_22_s.ALU_MODE=0;
  ALU total_23_s (
    .SUM(total_23_1),
    .COUT(total_23_2),
    .I0(t0[23]),
    .I1(t1[23]),
    .I3(GND),
    .CIN(total_22_2) 
);
defparam total_23_s.ALU_MODE=0;
  ALU total_24_s (
    .SUM(total_24_1),
    .COUT(total_24_2),
    .I0(t0[24]),
    .I1(t1[24]),
    .I3(GND),
    .CIN(total_23_2) 
);
defparam total_24_s.ALU_MODE=0;
  ALU total_25_s (
    .SUM(total_25_1),
    .COUT(total_25_2),
    .I0(t0[25]),
    .I1(t1[25]),
    .I3(GND),
    .CIN(total_24_2) 
);
defparam total_25_s.ALU_MODE=0;
  ALU total_26_s (
    .SUM(total_26_1),
    .COUT(total_26_2),
    .I0(t0[26]),
    .I1(t1[26]),
    .I3(GND),
    .CIN(total_25_2) 
);
defparam total_26_s.ALU_MODE=0;
  ALU total_27_s (
    .SUM(total_27_1),
    .COUT(total_27_2),
    .I0(t0[27]),
    .I1(t1[27]),
    .I3(GND),
    .CIN(total_26_2) 
);
defparam total_27_s.ALU_MODE=0;
  ALU total_28_s (
    .SUM(total_28_1),
    .COUT(total_28_2),
    .I0(t0[28]),
    .I1(t1[28]),
    .I3(GND),
    .CIN(total_27_2) 
);
defparam total_28_s.ALU_MODE=0;
  ALU total_29_s (
    .SUM(total_29_1),
    .COUT(total_29_2),
    .I0(t0[29]),
    .I1(t1[29]),
    .I3(GND),
    .CIN(total_28_2) 
);
defparam total_29_s.ALU_MODE=0;
  ALU total_30_s (
    .SUM(total_30_1),
    .COUT(total_30_2),
    .I0(t0[30]),
    .I1(t1[30]),
    .I3(GND),
    .CIN(total_29_2) 
);
defparam total_30_s.ALU_MODE=0;
  ALU total_31_s (
    .SUM(total_31_1),
    .COUT(total_31_2),
    .I0(t0[31]),
    .I1(t1[31]),
    .I3(GND),
    .CIN(total_30_2) 
);
defparam total_31_s.ALU_MODE=0;
  ALU total_32_s (
    .SUM(total_32_1),
    .COUT(total_32_2),
    .I0(t0[32]),
    .I1(t1[32]),
    .I3(GND),
    .CIN(total_31_2) 
);
defparam total_32_s.ALU_MODE=0;
  ALU total_33_s (
    .SUM(total_33_1),
    .COUT(total_33_2),
    .I0(t0[33]),
    .I1(t1[33]),
    .I3(GND),
    .CIN(total_32_2) 
);
defparam total_33_s.ALU_MODE=0;
  ALU total_34_s (
    .SUM(total_34_1),
    .COUT(total_34_2),
    .I0(t0[34]),
    .I1(t1[34]),
    .I3(GND),
    .CIN(total_33_2) 
);
defparam total_34_s.ALU_MODE=0;
  ALU total_35_s (
    .SUM(total_35_1),
    .COUT(total_35_2),
    .I0(t0[35]),
    .I1(t1[35]),
    .I3(GND),
    .CIN(total_34_2) 
);
defparam total_35_s.ALU_MODE=0;
  ALU total_36_s (
    .SUM(total_36_1),
    .COUT(total_36_2),
    .I0(t0[36]),
    .I1(t1[36]),
    .I3(GND),
    .CIN(total_35_2) 
);
defparam total_36_s.ALU_MODE=0;
  ALU total_37_s (
    .SUM(total_37_1),
    .COUT(total_37_2),
    .I0(t0[37]),
    .I1(t1[37]),
    .I3(GND),
    .CIN(total_36_2) 
);
defparam total_37_s.ALU_MODE=0;
  ALU total_38_s (
    .SUM(total_38_1),
    .COUT(total_38_2),
    .I0(t0[38]),
    .I1(t1[38]),
    .I3(GND),
    .CIN(total_37_2) 
);
defparam total_38_s.ALU_MODE=0;
  ALU total_39_s (
    .SUM(total_39_1),
    .COUT(total_39_2),
    .I0(t0[39]),
    .I1(t1[39]),
    .I3(GND),
    .CIN(total_38_2) 
);
defparam total_39_s.ALU_MODE=0;
  ALU total_40_s (
    .SUM(total_40_1),
    .COUT(total_40_2),
    .I0(t0[39]),
    .I1(t1[39]),
    .I3(GND),
    .CIN(total_39_2) 
);
defparam total_40_s.ALU_MODE=0;
  ALU total_41_s (
    .SUM(total_41_1),
    .COUT(total_41_0_COUT),
    .I0(t0[39]),
    .I1(t1[39]),
    .I3(GND),
    .CIN(total_40_2) 
);
defparam total_41_s.ALU_MODE=0;
  ALU total_0_s0 (
    .SUM(total_0_3),
    .COUT(total_0_4),
    .I0(t2[0]),
    .I1(t3[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam total_0_s0.ALU_MODE=0;
  ALU total_1_s0 (
    .SUM(total_1_3),
    .COUT(total_1_4),
    .I0(t2[1]),
    .I1(t3[1]),
    .I3(GND),
    .CIN(total_0_4) 
);
defparam total_1_s0.ALU_MODE=0;
  ALU total_2_s0 (
    .SUM(total_2_3),
    .COUT(total_2_4),
    .I0(t2[2]),
    .I1(t3[2]),
    .I3(GND),
    .CIN(total_1_4) 
);
defparam total_2_s0.ALU_MODE=0;
  ALU total_3_s0 (
    .SUM(total_3_3),
    .COUT(total_3_4),
    .I0(t2[3]),
    .I1(t3[3]),
    .I3(GND),
    .CIN(total_2_4) 
);
defparam total_3_s0.ALU_MODE=0;
  ALU total_4_s0 (
    .SUM(total_4_3),
    .COUT(total_4_4),
    .I0(t2[4]),
    .I1(t3[4]),
    .I3(GND),
    .CIN(total_3_4) 
);
defparam total_4_s0.ALU_MODE=0;
  ALU total_5_s0 (
    .SUM(total_5_3),
    .COUT(total_5_4),
    .I0(t2[5]),
    .I1(t3[5]),
    .I3(GND),
    .CIN(total_4_4) 
);
defparam total_5_s0.ALU_MODE=0;
  ALU total_6_s0 (
    .SUM(total_6_3),
    .COUT(total_6_4),
    .I0(t2[6]),
    .I1(t3[6]),
    .I3(GND),
    .CIN(total_5_4) 
);
defparam total_6_s0.ALU_MODE=0;
  ALU total_7_s0 (
    .SUM(total_7_3),
    .COUT(total_7_4),
    .I0(t2[7]),
    .I1(t3[7]),
    .I3(GND),
    .CIN(total_6_4) 
);
defparam total_7_s0.ALU_MODE=0;
  ALU total_8_s0 (
    .SUM(total_8_3),
    .COUT(total_8_4),
    .I0(t2[8]),
    .I1(t3[8]),
    .I3(GND),
    .CIN(total_7_4) 
);
defparam total_8_s0.ALU_MODE=0;
  ALU total_9_s0 (
    .SUM(total_9_3),
    .COUT(total_9_4),
    .I0(t2[9]),
    .I1(t3[9]),
    .I3(GND),
    .CIN(total_8_4) 
);
defparam total_9_s0.ALU_MODE=0;
  ALU total_10_s0 (
    .SUM(total_10_3),
    .COUT(total_10_4),
    .I0(t2[10]),
    .I1(t3[10]),
    .I3(GND),
    .CIN(total_9_4) 
);
defparam total_10_s0.ALU_MODE=0;
  ALU total_11_s0 (
    .SUM(total_11_3),
    .COUT(total_11_4),
    .I0(t2[11]),
    .I1(t3[11]),
    .I3(GND),
    .CIN(total_10_4) 
);
defparam total_11_s0.ALU_MODE=0;
  ALU total_12_s0 (
    .SUM(total_12_3),
    .COUT(total_12_4),
    .I0(t2[12]),
    .I1(t3[12]),
    .I3(GND),
    .CIN(total_11_4) 
);
defparam total_12_s0.ALU_MODE=0;
  ALU total_13_s0 (
    .SUM(total_13_3),
    .COUT(total_13_4),
    .I0(t2[13]),
    .I1(t3[13]),
    .I3(GND),
    .CIN(total_12_4) 
);
defparam total_13_s0.ALU_MODE=0;
  ALU total_14_s0 (
    .SUM(total_14_3),
    .COUT(total_14_4),
    .I0(t2[14]),
    .I1(t3[14]),
    .I3(GND),
    .CIN(total_13_4) 
);
defparam total_14_s0.ALU_MODE=0;
  ALU total_15_s0 (
    .SUM(total_15_3),
    .COUT(total_15_4),
    .I0(t2[15]),
    .I1(t3[15]),
    .I3(GND),
    .CIN(total_14_4) 
);
defparam total_15_s0.ALU_MODE=0;
  ALU total_16_s0 (
    .SUM(total_16_3),
    .COUT(total_16_4),
    .I0(t2[16]),
    .I1(t3[16]),
    .I3(GND),
    .CIN(total_15_4) 
);
defparam total_16_s0.ALU_MODE=0;
  ALU total_17_s0 (
    .SUM(total_17_3),
    .COUT(total_17_4),
    .I0(t2[17]),
    .I1(t3[17]),
    .I3(GND),
    .CIN(total_16_4) 
);
defparam total_17_s0.ALU_MODE=0;
  ALU total_18_s0 (
    .SUM(total_18_3),
    .COUT(total_18_4),
    .I0(t2[18]),
    .I1(t3[18]),
    .I3(GND),
    .CIN(total_17_4) 
);
defparam total_18_s0.ALU_MODE=0;
  ALU total_19_s0 (
    .SUM(total_19_3),
    .COUT(total_19_4),
    .I0(t2[19]),
    .I1(t3[19]),
    .I3(GND),
    .CIN(total_18_4) 
);
defparam total_19_s0.ALU_MODE=0;
  ALU total_20_s0 (
    .SUM(total_20_3),
    .COUT(total_20_4),
    .I0(t2[20]),
    .I1(t3[20]),
    .I3(GND),
    .CIN(total_19_4) 
);
defparam total_20_s0.ALU_MODE=0;
  ALU total_21_s0 (
    .SUM(total_21_3),
    .COUT(total_21_4),
    .I0(t2[21]),
    .I1(t3[21]),
    .I3(GND),
    .CIN(total_20_4) 
);
defparam total_21_s0.ALU_MODE=0;
  ALU total_22_s0 (
    .SUM(total_22_3),
    .COUT(total_22_4),
    .I0(t2[22]),
    .I1(t3[22]),
    .I3(GND),
    .CIN(total_21_4) 
);
defparam total_22_s0.ALU_MODE=0;
  ALU total_23_s0 (
    .SUM(total_23_3),
    .COUT(total_23_4),
    .I0(t2[23]),
    .I1(t3[23]),
    .I3(GND),
    .CIN(total_22_4) 
);
defparam total_23_s0.ALU_MODE=0;
  ALU total_24_s0 (
    .SUM(total_24_3),
    .COUT(total_24_4),
    .I0(t2[24]),
    .I1(t3[24]),
    .I3(GND),
    .CIN(total_23_4) 
);
defparam total_24_s0.ALU_MODE=0;
  ALU total_25_s0 (
    .SUM(total_25_3),
    .COUT(total_25_4),
    .I0(t2[25]),
    .I1(t3[25]),
    .I3(GND),
    .CIN(total_24_4) 
);
defparam total_25_s0.ALU_MODE=0;
  ALU total_26_s0 (
    .SUM(total_26_3),
    .COUT(total_26_4),
    .I0(t2[26]),
    .I1(t3[26]),
    .I3(GND),
    .CIN(total_25_4) 
);
defparam total_26_s0.ALU_MODE=0;
  ALU total_27_s0 (
    .SUM(total_27_3),
    .COUT(total_27_4),
    .I0(t2[27]),
    .I1(t3[27]),
    .I3(GND),
    .CIN(total_26_4) 
);
defparam total_27_s0.ALU_MODE=0;
  ALU total_28_s0 (
    .SUM(total_28_3),
    .COUT(total_28_4),
    .I0(t2[28]),
    .I1(t3[28]),
    .I3(GND),
    .CIN(total_27_4) 
);
defparam total_28_s0.ALU_MODE=0;
  ALU total_29_s0 (
    .SUM(total_29_3),
    .COUT(total_29_4),
    .I0(t2[29]),
    .I1(t3[29]),
    .I3(GND),
    .CIN(total_28_4) 
);
defparam total_29_s0.ALU_MODE=0;
  ALU total_30_s0 (
    .SUM(total_30_3),
    .COUT(total_30_4),
    .I0(t2[30]),
    .I1(t3[30]),
    .I3(GND),
    .CIN(total_29_4) 
);
defparam total_30_s0.ALU_MODE=0;
  ALU total_31_s0 (
    .SUM(total_31_3),
    .COUT(total_31_4),
    .I0(t2[31]),
    .I1(t3[31]),
    .I3(GND),
    .CIN(total_30_4) 
);
defparam total_31_s0.ALU_MODE=0;
  ALU total_32_s0 (
    .SUM(total_32_3),
    .COUT(total_32_4),
    .I0(t2[32]),
    .I1(t3[32]),
    .I3(GND),
    .CIN(total_31_4) 
);
defparam total_32_s0.ALU_MODE=0;
  ALU total_33_s0 (
    .SUM(total_33_3),
    .COUT(total_33_4),
    .I0(t2[33]),
    .I1(t3[33]),
    .I3(GND),
    .CIN(total_32_4) 
);
defparam total_33_s0.ALU_MODE=0;
  ALU total_34_s0 (
    .SUM(total_34_3),
    .COUT(total_34_4),
    .I0(t2[34]),
    .I1(t3[34]),
    .I3(GND),
    .CIN(total_33_4) 
);
defparam total_34_s0.ALU_MODE=0;
  ALU total_35_s0 (
    .SUM(total_35_3),
    .COUT(total_35_4),
    .I0(t2[35]),
    .I1(t3[35]),
    .I3(GND),
    .CIN(total_34_4) 
);
defparam total_35_s0.ALU_MODE=0;
  ALU total_36_s0 (
    .SUM(total_36_3),
    .COUT(total_36_4),
    .I0(t2[36]),
    .I1(t3[36]),
    .I3(GND),
    .CIN(total_35_4) 
);
defparam total_36_s0.ALU_MODE=0;
  ALU total_37_s0 (
    .SUM(total_37_3),
    .COUT(total_37_4),
    .I0(t2[37]),
    .I1(t3[37]),
    .I3(GND),
    .CIN(total_36_4) 
);
defparam total_37_s0.ALU_MODE=0;
  ALU total_38_s0 (
    .SUM(total_38_3),
    .COUT(total_38_4),
    .I0(t2[38]),
    .I1(t3[38]),
    .I3(GND),
    .CIN(total_37_4) 
);
defparam total_38_s0.ALU_MODE=0;
  ALU total_39_s0 (
    .SUM(total_39_3),
    .COUT(total_39_4),
    .I0(t2[39]),
    .I1(t3[39]),
    .I3(GND),
    .CIN(total_38_4) 
);
defparam total_39_s0.ALU_MODE=0;
  ALU total_40_s0 (
    .SUM(total_40_3),
    .COUT(total_40_4),
    .I0(t2[39]),
    .I1(t3[39]),
    .I3(GND),
    .CIN(total_39_4) 
);
defparam total_40_s0.ALU_MODE=0;
  ALU total_41_s0 (
    .SUM(total_41_3),
    .COUT(total_41_1_COUT),
    .I0(t2[39]),
    .I1(t3[39]),
    .I3(GND),
    .CIN(total_40_4) 
);
defparam total_41_s0.ALU_MODE=0;
  ALU total_0_s1 (
    .SUM(total[0]),
    .COUT(total_0_6),
    .I0(total_0_1),
    .I1(total_0_3),
    .I3(GND),
    .CIN(GND) 
);
defparam total_0_s1.ALU_MODE=0;
  ALU total_1_s1 (
    .SUM(total[1]),
    .COUT(total_1_6),
    .I0(total_1_1),
    .I1(total_1_3),
    .I3(GND),
    .CIN(total_0_6) 
);
defparam total_1_s1.ALU_MODE=0;
  ALU total_2_s1 (
    .SUM(total[2]),
    .COUT(total_2_6),
    .I0(total_2_1),
    .I1(total_2_3),
    .I3(GND),
    .CIN(total_1_6) 
);
defparam total_2_s1.ALU_MODE=0;
  ALU total_3_s1 (
    .SUM(total[3]),
    .COUT(total_3_6),
    .I0(total_3_1),
    .I1(total_3_3),
    .I3(GND),
    .CIN(total_2_6) 
);
defparam total_3_s1.ALU_MODE=0;
  ALU total_4_s1 (
    .SUM(total[4]),
    .COUT(total_4_6),
    .I0(total_4_1),
    .I1(total_4_3),
    .I3(GND),
    .CIN(total_3_6) 
);
defparam total_4_s1.ALU_MODE=0;
  ALU total_5_s1 (
    .SUM(total[5]),
    .COUT(total_5_6),
    .I0(total_5_1),
    .I1(total_5_3),
    .I3(GND),
    .CIN(total_4_6) 
);
defparam total_5_s1.ALU_MODE=0;
  ALU total_6_s1 (
    .SUM(total[6]),
    .COUT(total_6_6),
    .I0(total_6_1),
    .I1(total_6_3),
    .I3(GND),
    .CIN(total_5_6) 
);
defparam total_6_s1.ALU_MODE=0;
  ALU total_7_s1 (
    .SUM(total[7]),
    .COUT(total_7_6),
    .I0(total_7_1),
    .I1(total_7_3),
    .I3(GND),
    .CIN(total_6_6) 
);
defparam total_7_s1.ALU_MODE=0;
  ALU total_8_s1 (
    .SUM(total[8]),
    .COUT(total_8_6),
    .I0(total_8_1),
    .I1(total_8_3),
    .I3(GND),
    .CIN(total_7_6) 
);
defparam total_8_s1.ALU_MODE=0;
  ALU total_9_s1 (
    .SUM(total[9]),
    .COUT(total_9_6),
    .I0(total_9_1),
    .I1(total_9_3),
    .I3(GND),
    .CIN(total_8_6) 
);
defparam total_9_s1.ALU_MODE=0;
  ALU total_10_s1 (
    .SUM(total[10]),
    .COUT(total_10_6),
    .I0(total_10_1),
    .I1(total_10_3),
    .I3(GND),
    .CIN(total_9_6) 
);
defparam total_10_s1.ALU_MODE=0;
  ALU total_11_s1 (
    .SUM(total[11]),
    .COUT(total_11_6),
    .I0(total_11_1),
    .I1(total_11_3),
    .I3(GND),
    .CIN(total_10_6) 
);
defparam total_11_s1.ALU_MODE=0;
  ALU total_12_s1 (
    .SUM(total[12]),
    .COUT(total_12_6),
    .I0(total_12_1),
    .I1(total_12_3),
    .I3(GND),
    .CIN(total_11_6) 
);
defparam total_12_s1.ALU_MODE=0;
  ALU total_13_s1 (
    .SUM(total[13]),
    .COUT(total_13_6),
    .I0(total_13_1),
    .I1(total_13_3),
    .I3(GND),
    .CIN(total_12_6) 
);
defparam total_13_s1.ALU_MODE=0;
  ALU total_14_s1 (
    .SUM(total[14]),
    .COUT(total_14_6),
    .I0(total_14_1),
    .I1(total_14_3),
    .I3(GND),
    .CIN(total_13_6) 
);
defparam total_14_s1.ALU_MODE=0;
  ALU total_15_s1 (
    .SUM(total[15]),
    .COUT(total_15_6),
    .I0(total_15_1),
    .I1(total_15_3),
    .I3(GND),
    .CIN(total_14_6) 
);
defparam total_15_s1.ALU_MODE=0;
  ALU total_16_s1 (
    .SUM(total[16]),
    .COUT(total_16_6),
    .I0(total_16_1),
    .I1(total_16_3),
    .I3(GND),
    .CIN(total_15_6) 
);
defparam total_16_s1.ALU_MODE=0;
  ALU total_17_s1 (
    .SUM(total[17]),
    .COUT(total_17_6),
    .I0(total_17_1),
    .I1(total_17_3),
    .I3(GND),
    .CIN(total_16_6) 
);
defparam total_17_s1.ALU_MODE=0;
  ALU total_18_s1 (
    .SUM(total[18]),
    .COUT(total_18_6),
    .I0(total_18_1),
    .I1(total_18_3),
    .I3(GND),
    .CIN(total_17_6) 
);
defparam total_18_s1.ALU_MODE=0;
  ALU total_19_s1 (
    .SUM(total[19]),
    .COUT(total_19_6),
    .I0(total_19_1),
    .I1(total_19_3),
    .I3(GND),
    .CIN(total_18_6) 
);
defparam total_19_s1.ALU_MODE=0;
  ALU total_20_s1 (
    .SUM(total[20]),
    .COUT(total_20_6),
    .I0(total_20_1),
    .I1(total_20_3),
    .I3(GND),
    .CIN(total_19_6) 
);
defparam total_20_s1.ALU_MODE=0;
  ALU total_21_s1 (
    .SUM(total[21]),
    .COUT(total_21_6),
    .I0(total_21_1),
    .I1(total_21_3),
    .I3(GND),
    .CIN(total_20_6) 
);
defparam total_21_s1.ALU_MODE=0;
  ALU total_22_s1 (
    .SUM(total[22]),
    .COUT(total_22_6),
    .I0(total_22_1),
    .I1(total_22_3),
    .I3(GND),
    .CIN(total_21_6) 
);
defparam total_22_s1.ALU_MODE=0;
  ALU total_23_s1 (
    .SUM(total[23]),
    .COUT(total_23_6),
    .I0(total_23_1),
    .I1(total_23_3),
    .I3(GND),
    .CIN(total_22_6) 
);
defparam total_23_s1.ALU_MODE=0;
  ALU total_24_s1 (
    .SUM(total[24]),
    .COUT(total_24_6),
    .I0(total_24_1),
    .I1(total_24_3),
    .I3(GND),
    .CIN(total_23_6) 
);
defparam total_24_s1.ALU_MODE=0;
  ALU total_25_s1 (
    .SUM(total[25]),
    .COUT(total_25_6),
    .I0(total_25_1),
    .I1(total_25_3),
    .I3(GND),
    .CIN(total_24_6) 
);
defparam total_25_s1.ALU_MODE=0;
  ALU total_26_s1 (
    .SUM(total[26]),
    .COUT(total_26_6),
    .I0(total_26_1),
    .I1(total_26_3),
    .I3(GND),
    .CIN(total_25_6) 
);
defparam total_26_s1.ALU_MODE=0;
  ALU total_27_s1 (
    .SUM(total[27]),
    .COUT(total_27_6),
    .I0(total_27_1),
    .I1(total_27_3),
    .I3(GND),
    .CIN(total_26_6) 
);
defparam total_27_s1.ALU_MODE=0;
  ALU total_28_s1 (
    .SUM(total[28]),
    .COUT(total_28_6),
    .I0(total_28_1),
    .I1(total_28_3),
    .I3(GND),
    .CIN(total_27_6) 
);
defparam total_28_s1.ALU_MODE=0;
  ALU total_29_s1 (
    .SUM(total[29]),
    .COUT(total_29_6),
    .I0(total_29_1),
    .I1(total_29_3),
    .I3(GND),
    .CIN(total_28_6) 
);
defparam total_29_s1.ALU_MODE=0;
  ALU total_30_s1 (
    .SUM(total[30]),
    .COUT(total_30_6),
    .I0(total_30_1),
    .I1(total_30_3),
    .I3(GND),
    .CIN(total_29_6) 
);
defparam total_30_s1.ALU_MODE=0;
  ALU total_31_s1 (
    .SUM(total[31]),
    .COUT(total_31_6),
    .I0(total_31_1),
    .I1(total_31_3),
    .I3(GND),
    .CIN(total_30_6) 
);
defparam total_31_s1.ALU_MODE=0;
  ALU total_32_s1 (
    .SUM(total[32]),
    .COUT(total_32_6),
    .I0(total_32_1),
    .I1(total_32_3),
    .I3(GND),
    .CIN(total_31_6) 
);
defparam total_32_s1.ALU_MODE=0;
  ALU total_33_s1 (
    .SUM(total[33]),
    .COUT(total_33_6),
    .I0(total_33_1),
    .I1(total_33_3),
    .I3(GND),
    .CIN(total_32_6) 
);
defparam total_33_s1.ALU_MODE=0;
  ALU total_34_s1 (
    .SUM(total[34]),
    .COUT(total_34_6),
    .I0(total_34_1),
    .I1(total_34_3),
    .I3(GND),
    .CIN(total_33_6) 
);
defparam total_34_s1.ALU_MODE=0;
  ALU total_35_s1 (
    .SUM(total[35]),
    .COUT(total_35_6),
    .I0(total_35_1),
    .I1(total_35_3),
    .I3(GND),
    .CIN(total_34_6) 
);
defparam total_35_s1.ALU_MODE=0;
  ALU total_36_s1 (
    .SUM(total[36]),
    .COUT(total_36_6),
    .I0(total_36_1),
    .I1(total_36_3),
    .I3(GND),
    .CIN(total_35_6) 
);
defparam total_36_s1.ALU_MODE=0;
  ALU total_37_s1 (
    .SUM(total[37]),
    .COUT(total_37_6),
    .I0(total_37_1),
    .I1(total_37_3),
    .I3(GND),
    .CIN(total_36_6) 
);
defparam total_37_s1.ALU_MODE=0;
  ALU total_38_s1 (
    .SUM(total[38]),
    .COUT(total_38_6),
    .I0(total_38_1),
    .I1(total_38_3),
    .I3(GND),
    .CIN(total_37_6) 
);
defparam total_38_s1.ALU_MODE=0;
  ALU total_39_s1 (
    .SUM(total[39]),
    .COUT(total_39_6),
    .I0(total_39_1),
    .I1(total_39_3),
    .I3(GND),
    .CIN(total_38_6) 
);
defparam total_39_s1.ALU_MODE=0;
  ALU total_40_s1 (
    .SUM(total[40]),
    .COUT(total_40_6),
    .I0(total_40_1),
    .I1(total_40_3),
    .I3(GND),
    .CIN(total_39_6) 
);
defparam total_40_s1.ALU_MODE=0;
  ALU total_41_s1 (
    .SUM(total[41]),
    .COUT(total_41_2_COUT),
    .I0(total_41_1),
    .I1(total_41_3),
    .I3(GND),
    .CIN(total_40_6) 
);
defparam total_41_s1.ALU_MODE=0;
  ALU n849_s (
    .SUM(n849_1),
    .COUT(n849_2),
    .I0(fill[1]),
    .I1(fill[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam n849_s.ALU_MODE=0;
  ALU n848_s (
    .SUM(n848_1),
    .COUT(n848_2),
    .I0(fill[2]),
    .I1(GND),
    .I3(GND),
    .CIN(n849_2) 
);
defparam n848_s.ALU_MODE=0;
  ALU n847_s (
    .SUM(n847_1),
    .COUT(n847_2),
    .I0(fill[3]),
    .I1(GND),
    .I3(GND),
    .CIN(n848_2) 
);
defparam n847_s.ALU_MODE=0;
  ALU n846_s (
    .SUM(n846_1),
    .COUT(n846_2),
    .I0(fill[4]),
    .I1(GND),
    .I3(GND),
    .CIN(n847_2) 
);
defparam n846_s.ALU_MODE=0;
  ALU n845_s (
    .SUM(n845_1),
    .COUT(n845_2),
    .I0(fill[5]),
    .I1(GND),
    .I3(GND),
    .CIN(n846_2) 
);
defparam n845_s.ALU_MODE=0;
  ALU n844_s (
    .SUM(n844_1),
    .COUT(n844_2),
    .I0(fill[6]),
    .I1(GND),
    .I3(GND),
    .CIN(n845_2) 
);
defparam n844_s.ALU_MODE=0;
  ALU n843_s (
    .SUM(n843_1),
    .COUT(n843_2),
    .I0(fill[7]),
    .I1(GND),
    .I3(GND),
    .CIN(n844_2) 
);
defparam n843_s.ALU_MODE=0;
  ALU n842_s (
    .SUM(n842_1),
    .COUT(n842_2),
    .I0(fill[8]),
    .I1(GND),
    .I3(GND),
    .CIN(n843_2) 
);
defparam n842_s.ALU_MODE=0;
  ALU n841_s (
    .SUM(n841_1),
    .COUT(n841_2),
    .I0(fill[9]),
    .I1(GND),
    .I3(GND),
    .CIN(n842_2) 
);
defparam n841_s.ALU_MODE=0;
  ALU n840_s (
    .SUM(n840_1),
    .COUT(n840_0_COUT),
    .I0(fill[10]),
    .I1(GND),
    .I3(GND),
    .CIN(n841_2) 
);
defparam n840_s.ALU_MODE=0;
  ALU tap_base_3_s (
    .SUM(tap_base[3]),
    .COUT(tap_base_3_3),
    .I0(base[3]),
    .I1(index[0]),
    .I3(GND),
    .CIN(VCC) 
);
defparam tap_base_3_s.ALU_MODE=1;
  ALU tap_base_4_s (
    .SUM(tap_base[4]),
    .COUT(tap_base_4_3),
    .I0(base[4]),
    .I1(index[1]),
    .I3(GND),
    .CIN(tap_base_3_3) 
);
defparam tap_base_4_s.ALU_MODE=1;
  ALU tap_base_5_s (
    .SUM(tap_base[5]),
    .COUT(tap_base_5_3),
    .I0(base[5]),
    .I1(index[2]),
    .I3(GND),
    .CIN(tap_base_4_3) 
);
defparam tap_base_5_s.ALU_MODE=1;
  ALU tap_base_6_s (
    .SUM(tap_base[6]),
    .COUT(tap_base_6_3),
    .I0(base[6]),
    .I1(index[3]),
    .I3(GND),
    .CIN(tap_base_5_3) 
);
defparam tap_base_6_s.ALU_MODE=1;
  ALU tap_base_7_s (
    .SUM(tap_base[7]),
    .COUT(tap_base_7_3),
    .I0(base[7]),
    .I1(index[4]),
    .I3(GND),
    .CIN(tap_base_6_3) 
);
defparam tap_base_7_s.ALU_MODE=1;
  ALU tap_base_8_s (
    .SUM(tap_base[8]),
    .COUT(tap_base_8_3),
    .I0(base[8]),
    .I1(index[5]),
    .I3(GND),
    .CIN(tap_base_7_3) 
);
defparam tap_base_8_s.ALU_MODE=1;
  ALU tap_base_9_s (
    .SUM(tap_base[9]),
    .COUT(tap_base_9_0_COUT),
    .I0(base[9]),
    .I1(index[6]),
    .I3(GND),
    .CIN(tap_base_8_3) 
);
defparam tap_base_9_s.ALU_MODE=1;
  ALU n836_s (
    .SUM(n836_1),
    .COUT(n836_2),
    .I0(wp[1]),
    .I1(wp[0]),
    .I3(GND),
    .CIN(GND) 
);
defparam n836_s.ALU_MODE=0;
  ALU n835_s (
    .SUM(n835_1),
    .COUT(n835_2),
    .I0(wp[2]),
    .I1(GND),
    .I3(GND),
    .CIN(n836_2) 
);
defparam n835_s.ALU_MODE=0;
  ALU n834_s (
    .SUM(n834_1),
    .COUT(n834_2),
    .I0(wp[3]),
    .I1(GND),
    .I3(GND),
    .CIN(n835_2) 
);
defparam n834_s.ALU_MODE=0;
  ALU n833_s (
    .SUM(n833_1),
    .COUT(n833_2),
    .I0(wp[4]),
    .I1(GND),
    .I3(GND),
    .CIN(n834_2) 
);
defparam n833_s.ALU_MODE=0;
  ALU n832_s (
    .SUM(n832_1),
    .COUT(n832_2),
    .I0(wp[5]),
    .I1(GND),
    .I3(GND),
    .CIN(n833_2) 
);
defparam n832_s.ALU_MODE=0;
  ALU n831_s (
    .SUM(n831_1),
    .COUT(n831_2),
    .I0(wp[6]),
    .I1(GND),
    .I3(GND),
    .CIN(n832_2) 
);
defparam n831_s.ALU_MODE=0;
  ALU n830_s (
    .SUM(n830_1),
    .COUT(n830_2),
    .I0(wp[7]),
    .I1(GND),
    .I3(GND),
    .CIN(n831_2) 
);
defparam n830_s.ALU_MODE=0;
  ALU n829_s (
    .SUM(n829_1),
    .COUT(n829_2),
    .I0(wp[8]),
    .I1(GND),
    .I3(GND),
    .CIN(n830_2) 
);
defparam n829_s.ALU_MODE=0;
  ALU n828_s (
    .SUM(n828_1),
    .COUT(n828_0_COUT),
    .I0(wp[9]),
    .I1(GND),
    .I3(GND),
    .CIN(n829_2) 
);
defparam n828_s.ALU_MODE=0;
  INV n6_s2 (
    .O(n6_6),
    .I(index[6]) 
);
  INV addr3_1_s7 (
    .O(addr3[1]),
    .I(base[1]) 
);
  INV addr2_2_s7 (
    .O(addr2[2]),
    .I(base[2]) 
);
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
endmodule /* visual_xy_source */