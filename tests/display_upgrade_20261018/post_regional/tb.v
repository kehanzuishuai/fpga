`timescale 1ns/1ps
module tb_post_loader;
reg clk=0,rst_n=0,req=0;always #5 clk=~clk;
reg[6:0]note=7'bx;wire[31:0]inc;wire[4:0]state;
wire[31:0]we,done;wire[27:0]data;wire[8:0]addr;wire[12:0]release_slope;
note_freq_table f(.midi_note(note),.phase_inc(inc));
GSR GSR(.GSRI(1'b1));
piano_note_loader d(.clk_12m288 (clk),
.n290_6 (!rst_n),
.n3804_7 (1'b1),
.n3804_5 (1'b1),
.n3804_5_80 (1'b1),
.n3804_5_81 (1'b1),
.n3804_5_82 (1'b1),
.n3804_5_83 (1'b1),
.n3804_5_84 (1'b1),
.n3804_5_85 (1'b1),
.n3804_5_86 (1'b1),
.n3804_5_87 (1'b1),
.n3804_5_88 (1'b1),
.n3804_5_89 (1'b1),
.n3804_5_90 (1'b1),
.n135_7 ((state[1:0]==0)),
.out_note_on_Z (1'b1),
.n135_4 (req),
.chosen (5'd0),
.out_note_Z_0 (note[0]),
.out_note_Z_1 (note[1]),
.out_note_Z_2 (note[2]),
.out_note_Z_3 (note[3]),
.out_note_Z_5 (note[5]),
.out_note_Z_6 (note[6]),
.out_velocity_Z (1'b1),
.eng (2'd0),
.eng_91 (2'd0),
.eng_92 (2'd0),
.eng_93 (2'd0),
.eng_94 (2'd0),
.eng_95 (2'd0),
.eng_96 (2'd0),
.eng_97 (2'd0),
.eng_98 (2'd0),
.eng_99 (2'd0),
.eng_100 (2'd0),
.eng_101 (2'd0),
.eng_102 (2'd0),
.eng_103 (2'd0),
.vstate (2'd2),
.eng_104 (2'd0),
.vstate_105 (2'd2),
.eng_106 (2'd0),
.vstate_107 (2'd2),
.eng_108 (2'd0),
.vstate_109 (2'd2),
.eng_110 (2'd0),
.vstate_111 (2'd2),
.eng_112 (2'd0),
.vstate_113 (2'd2),
.eng_114 (2'd0),
.vstate_115 (2'd2),
.eng_116 (2'd0),
.vstate_117 (2'd2),
.eng_118 (2'd0),
.vstate_119 (2'd2),
.eng_120 (2'd0),
.vstate_121 (2'd2),
.eng_122 (2'd0),
.vstate_123 (2'd2),
.eng_124 (2'd0),
.vstate_125 (2'd2),
.vstate_126 (2'd2),
.eng_127 (2'd0),
.eng_128 (2'd0),
.vstate_129 (2'd2),
.eng_130 (2'd0),
.vstate_131 (2'd2),
.eng_132 (2'd0),
.vstate_133 (2'd2),
.eng_134 (2'd0),
.vstate_135 (2'd2),
.eng_136 (2'd0),
.vstate_137 (2'd2),
.vstate_138 (2'd2),
.eng_139 (2'd0),
.n839_98 (),
.n839_102 (),
.n839_118 (),
.n839_120 (),
.n839_126 (),
.n839_135 (),
.n839_137 (),
.n839_139 (),
.n839_141 (),
.n839_143 (),
.n839_145 (),
.n839_147 (),
.n839_149 (),
.n839_151 (),
.n839_153 (),
.n839_155 (),
.n839_157 (),
.n839_159 (),
.n839_161 (),
.n839_163 (),
.n839_165 (),
.n839_167 (),
.n839_169 (),
.n839_171 (),
.n1450_14 (),
.state (state),
.\G_PARTIAL.ld_we (we),
.\G_PARTIAL.ld_done (done),
.\G_PARTIAL.ld_rel_slope (release_slope),
.\G_PARTIAL.ld_addr (addr),
.\G_PARTIAL.ld_data (data));
integer n,cycles,fo,writes=0;
always @(posedge clk) if(rst_n && |we) begin
if(^data===1'bx)$fatal(1,"unknown loader data note%0d addr%0d data%h",note,addr,data);
$fdisplay(fo,"%0d,%0d,%0d",note,addr,data);writes=writes+1;
end
initial begin
fo=$fopen("tests/display_upgrade_20261018/post_regional/words.csv","w");
force d.note_r=note;force d.inc0_r=inc;
for(n=60;n<=75;n=n+1)begin
 rst_n=0;req=0;note=n;repeat(6)@(negedge clk);rst_n=1;repeat(4)@(negedge clk);
 req=1;@(negedge clk);req=0;cycles=0;
 while(!(|done))begin @(negedge clk);cycles=cycles+1;if(cycles>4000)$fatal(1,"Loader timeout state%0d",state);end
 @(negedge clk);
end
$fclose(fo);if(writes!=6400)$fatal(1,"Expected6400 writes got%0d",writes);
$display("PASS post-synthesis integrated Loader stimulus 16 notes,6400 words");$finish;
end
endmodule
