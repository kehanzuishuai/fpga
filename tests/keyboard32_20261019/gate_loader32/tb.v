`timescale 1ns/1ps
module tb_post_loader;
reg clk=0,rst_n=0,req=0;always #5 clk=~clk;
reg[6:0]note=7'bx;wire[31:0]inc;wire[4:0]state;
wire[31:0]we,done;wire[27:0]data;wire[8:0]addr;wire[12:0]release_slope;
note_freq_table f(.midi_note(note),.phase_inc(inc));
GSR GSR(.GSRI(1'b1));
piano_note_loader d(.clk_12m288 (clk),
.n541_6 (!rst_n),
.n3804_5 (1'b1),
.n3804_5_90 (1'b1),
.n3804_5_91 (1'b1),
.n3804_5_92 (1'b1),
.n3804_5_93 (1'b1),
.n3804_5_94 (1'b1),
.n3804_5_95 (1'b1),
.n3804_5_96 (1'b1),
.n3804_5_97 (1'b1),
.n3804_5_98 (1'b1),
.n3804_5_99 (1'b1),
.n3804_5_100 (1'b1),
.n3804_5_101 (1'b1),
.n135_7 ((state[3:0]==0)),
.out_note_on_Z (1'b1),
.n135_4 (req),
.chosen (1'b0),
.out_note_Z (note),
.out_velocity_Z (1'b1),
.eng (2'd0),
.eng_102 (2'd0),
.eng_103 (2'd0),
.eng_104 (2'd0),
.eng_105 (2'd0),
.eng_106 (2'd0),
.eng_107 (2'd0),
.eng_108 (2'd0),
.eng_109 (2'd0),
.eng_110 (2'd0),
.eng_111 (2'd0),
.eng_112 (2'd0),
.eng_113 (2'd0),
.eng_114 (2'd0),
.vstate (2'd2),
.eng_115 (2'd0),
.vstate_116 (2'd2),
.eng_117 (2'd0),
.vstate_118 (2'd2),
.eng_119 (2'd0),
.vstate_120 (2'd2),
.eng_121 (2'd0),
.vstate_122 (2'd2),
.eng_123 (2'd0),
.vstate_124 (2'd2),
.eng_125 (2'd0),
.vstate_126 (2'd2),
.eng_127 (2'd0),
.vstate_128 (2'd2),
.eng_129 (2'd0),
.vstate_130 (2'd2),
.eng_131 (2'd0),
.vstate_132 (2'd2),
.eng_133 (2'd0),
.vstate_134 (2'd2),
.eng_135 (2'd0),
.vstate_136 (2'd2),
.vstate_137 (2'd2),
.eng_138 (2'd0),
.eng_139 (2'd0),
.vstate_140 (2'd2),
.eng_141 (2'd0),
.vstate_142 (2'd2),
.eng_143 (2'd0),
.vstate_144 (2'd2),
.eng_145 (2'd0),
.vstate_146 (2'd2),
.eng_147 (2'd0),
.vstate_148 (2'd2),
.vstate_149 (2'd2),
.eng_150 (2'd0),
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
fo=$fopen("tests/keyboard32_20261019/gate_loader32/words.csv","w");
force d.note_r=note;force d.inc0_r=inc;
for(n=60;n<=91;n=n+1)begin
 rst_n=0;req=0;note=n;repeat(6)@(negedge clk);rst_n=1;repeat(4)@(negedge clk);
 req=1;@(negedge clk);req=0;cycles=0;
 while(!(|done))begin @(negedge clk);cycles=cycles+1;if(cycles>4000)$fatal(1,"Loader timeout state%0d",state);end
 @(negedge clk);
end
$fclose(fo);if(writes!=12800)$fatal(1,"Expected12800 writes got%0d",writes);
$display("PASS post-synthesis integrated Loader stimulus 32 notes,12800 words");$finish;
end
endmodule
