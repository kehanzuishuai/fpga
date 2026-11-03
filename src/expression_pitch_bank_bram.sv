// Piano-only controller. Its consumers finish phase work before clock 223.
// State/pending data live in synchronous RAM. The next frame publishes during
// the idle tail; no voice calculation or sample output is delayed.
module expression_pitch_bank_bram #(parameter integer VOICES=32,IW=(VOICES<2 ? 1:$clog2(VOICES)),RAW_OUTPUT=0)(
 input wire clk,rst_n,sample_tick,input wire [VOICES-1:0] starts,
 input wire [6:0] glide,input wire [21:0] seed,input wire signed [6:0] seed_steps,
 input wire signed [7:0] lfo,output wire [VOICES*22-1:0] ratios);
 (* syn_ramstyle="block_ram" *) reg [21:0] current_memory[0:(1<<IW)-1];
 (* syn_ramstyle="block_ram" *) reg [21:0] pending_memory[0:(1<<IW)-1];
 reg [21:0] current_q,pending_q,frame_ratio[0:VOICES-1];
 reg signed [6:0] seed_code[0:VOICES-1];
 reg [VOICES-1:0] dirty,current_valid,pending_valid;
 reg busy;reg [IW-1:0] cursor;reg [7:0] frame_cycle;
 reg [6:0] glide_frame;reg signed [7:0] lfo_frame;
 wire [IW-1:0] current_address=sample_tick ? IW'(0):busy ? cursor+1'b1:IW'(0);
 wire read_pending=frame_cycle>=8'(254-VOICES) && frame_cycle<8'd254;
 wire [IW-1:0] pending_address=read_pending ? IW'(frame_cycle-(254-VOICES)):IW'(0);
 wire publish=frame_cycle>=8'(255-VOICES) && frame_cycle<8'd255 && !sample_tick;
 wire [IW-1:0] publish_index=IW'(frame_cycle-(255-VOICES));
 wire update=busy && !sample_tick && !starts[cursor];
 reg [21:0] decoded_seed;
 always @* begin decoded_seed=22'd65536;case(seed_code[cursor])
 -7'sd60:decoded_seed=22'd2048;
 -7'sd59:decoded_seed=22'd2170;
 -7'sd58:decoded_seed=22'd2299;
 -7'sd57:decoded_seed=22'd2435;
 -7'sd56:decoded_seed=22'd2580;
 -7'sd55:decoded_seed=22'd2734;
 -7'sd54:decoded_seed=22'd2896;
 -7'sd53:decoded_seed=22'd3069;
 -7'sd52:decoded_seed=22'd3251;
 -7'sd51:decoded_seed=22'd3444;
 -7'sd50:decoded_seed=22'd3649;
 -7'sd49:decoded_seed=22'd3866;
 -7'sd48:decoded_seed=22'd4096;
 -7'sd47:decoded_seed=22'd4340;
 -7'sd46:decoded_seed=22'd4598;
 -7'sd45:decoded_seed=22'd4871;
 -7'sd44:decoded_seed=22'd5161;
 -7'sd43:decoded_seed=22'd5468;
 -7'sd42:decoded_seed=22'd5793;
 -7'sd41:decoded_seed=22'd6137;
 -7'sd40:decoded_seed=22'd6502;
 -7'sd39:decoded_seed=22'd6889;
 -7'sd38:decoded_seed=22'd7298;
 -7'sd37:decoded_seed=22'd7732;
 -7'sd36:decoded_seed=22'd8192;
 -7'sd35:decoded_seed=22'd8679;
 -7'sd34:decoded_seed=22'd9195;
 -7'sd33:decoded_seed=22'd9742;
 -7'sd32:decoded_seed=22'd10321;
 -7'sd31:decoded_seed=22'd10935;
 -7'sd30:decoded_seed=22'd11585;
 -7'sd29:decoded_seed=22'd12274;
 -7'sd28:decoded_seed=22'd13004;
 -7'sd27:decoded_seed=22'd13777;
 -7'sd26:decoded_seed=22'd14596;
 -7'sd25:decoded_seed=22'd15464;
 -7'sd24:decoded_seed=22'd16384;
 -7'sd23:decoded_seed=22'd17358;
 -7'sd22:decoded_seed=22'd18390;
 -7'sd21:decoded_seed=22'd19484;
 -7'sd20:decoded_seed=22'd20643;
 -7'sd19:decoded_seed=22'd21870;
 -7'sd18:decoded_seed=22'd23170;
 -7'sd17:decoded_seed=22'd24548;
 -7'sd16:decoded_seed=22'd26008;
 -7'sd15:decoded_seed=22'd27554;
 -7'sd14:decoded_seed=22'd29193;
 -7'sd13:decoded_seed=22'd30929;
 -7'sd12:decoded_seed=22'd32768;
 -7'sd11:decoded_seed=22'd34716;
 -7'sd10:decoded_seed=22'd36781;
 -7'sd9:decoded_seed=22'd38968;
 -7'sd8:decoded_seed=22'd41285;
 -7'sd7:decoded_seed=22'd43740;
 -7'sd6:decoded_seed=22'd46341;
 -7'sd5:decoded_seed=22'd49097;
 -7'sd4:decoded_seed=22'd52016;
 -7'sd3:decoded_seed=22'd55109;
 -7'sd2:decoded_seed=22'd58386;
 -7'sd1:decoded_seed=22'd61858;
 7'sd0:decoded_seed=22'd65536;
 7'sd1:decoded_seed=22'd69433;
 7'sd2:decoded_seed=22'd73562;
 7'sd3:decoded_seed=22'd77936;
 7'sd4:decoded_seed=22'd82570;
 7'sd5:decoded_seed=22'd87480;
 7'sd6:decoded_seed=22'd92682;
 7'sd7:decoded_seed=22'd98193;
 7'sd8:decoded_seed=22'd104032;
 7'sd9:decoded_seed=22'd110218;
 7'sd10:decoded_seed=22'd116772;
 7'sd11:decoded_seed=22'd123715;
 7'sd12:decoded_seed=22'd131072;
 7'sd13:decoded_seed=22'd138866;
 7'sd14:decoded_seed=22'd147123;
 7'sd15:decoded_seed=22'd155872;
 7'sd16:decoded_seed=22'd165140;
 7'sd17:decoded_seed=22'd174960;
 7'sd18:decoded_seed=22'd185364;
 7'sd19:decoded_seed=22'd196386;
 7'sd20:decoded_seed=22'd208064;
 7'sd21:decoded_seed=22'd220436;
 7'sd22:decoded_seed=22'd233544;
 7'sd23:decoded_seed=22'd247431;
 7'sd24:decoded_seed=22'd262144;
 7'sd25:decoded_seed=22'd277732;
 7'sd26:decoded_seed=22'd294247;
 7'sd27:decoded_seed=22'd311744;
 7'sd28:decoded_seed=22'd330281;
 7'sd29:decoded_seed=22'd349920;
 7'sd30:decoded_seed=22'd370728;
 7'sd31:decoded_seed=22'd392772;
 7'sd32:decoded_seed=22'd416128;
 7'sd33:decoded_seed=22'd440872;
 7'sd34:decoded_seed=22'd467088;
 7'sd35:decoded_seed=22'd494862;
 7'sd36:decoded_seed=22'd524288;
 7'sd37:decoded_seed=22'd555464;
 7'sd38:decoded_seed=22'd588493;
 7'sd39:decoded_seed=22'd623487;
 7'sd40:decoded_seed=22'd660561;
 7'sd41:decoded_seed=22'd699841;
 7'sd42:decoded_seed=22'd741455;
 7'sd43:decoded_seed=22'd785544;
 7'sd44:decoded_seed=22'd832255;
 7'sd45:decoded_seed=22'd881744;
 7'sd46:decoded_seed=22'd934175;
 7'sd47:decoded_seed=22'd989724;
 7'sd48:decoded_seed=22'd1048576;
 7'sd49:decoded_seed=22'd1110928;
 7'sd50:decoded_seed=22'd1176987;
 7'sd51:decoded_seed=22'd1246974;
 7'sd52:decoded_seed=22'd1321123;
 7'sd53:decoded_seed=22'd1399681;
 7'sd54:decoded_seed=22'd1482910;
 7'sd55:decoded_seed=22'd1571089;
 7'sd56:decoded_seed=22'd1664511;
 7'sd57:decoded_seed=22'd1763488;
 7'sd58:decoded_seed=22'd1868350;
 7'sd59:decoded_seed=22'd1979448;
 7'sd60:decoded_seed=22'd2097152;
 default:decoded_seed=22'd65536;endcase end
 wire [21:0] value=dirty[cursor] ? decoded_seed:current_valid[cursor] ? current_q:22'd65536;
 wire [3:0] shift=glide_frame<=16 ? 4'd7:glide_frame<=32 ? 4'd8:glide_frame<=48 ? 4'd9:glide_frame<=64 ? 4'd10:glide_frame<=80 ? 4'd11:4'd12;
 wire [21:0] distance=value>22'd65536 ? value-22'd65536:22'd65536-value;
 wire [21:0] step=(distance>>shift)==0 ? 22'd1:distance>>shift;
 wire [21:0] advanced=glide_frame==0 ? 22'd65536:value>22'd65536 ? value-step:value<22'd65536 ? value+step:value;
 wire signed [30:0] modulation=$signed({1'b0,advanced})*lfo_frame;
 wire signed [31:0] modulated=$signed({1'b0,advanced})+(modulation>>>11);
 always @(posedge clk)begin
  current_q<=current_memory[current_address];pending_q<=pending_memory[pending_address];
  if(rst_n && update)begin current_memory[cursor]<=advanced;pending_memory[cursor]<=modulated[21:0];end
 end
 genvar g;generate for(g=0;g<VOICES;g=g+1)begin:OUT
  assign ratios[g*22+:22]=(RAW_OUTPUT==0 && glide==0 && lfo==0) ? 22'd65536:frame_ratio[g];
 end endgenerate
 integer i;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  busy<=0;cursor<=0;frame_cycle<=0;glide_frame<=0;lfo_frame<=0;
  dirty<=0;current_valid<=0;pending_valid<=0;
  for(i=0;i<VOICES;i=i+1)begin seed_code[i]<=0;frame_ratio[i]<=22'd65536;end
 end else begin
  if(sample_tick)begin busy<=1;cursor<=0;frame_cycle<=0;glide_frame<=glide;lfo_frame<=lfo;end
  else begin frame_cycle<=frame_cycle+1'b1;if(busy)begin if(cursor==IW'(VOICES-1))busy<=0;else cursor<=cursor+1'b1;end end
  for(i=0;i<VOICES;i=i+1)begin
   if(starts[i])begin
    dirty[i]<=1;seed_code[i]<=glide!=0 ? seed_steps:7'sd0;
    frame_ratio[i]<=glide!=0 ? seed:22'd65536;
   end else begin
    if(update && cursor==IW'(i))begin dirty[i]<=0;current_valid[i]<=1;pending_valid[i]<=1;end
    if(publish && publish_index==IW'(i) && pending_valid[i] && !dirty[i])frame_ratio[i]<=pending_q;
   end
  end
 end
endmodule

// Auxiliary oscillators consume the ratio on the tick edge. Recreate the
// original NBA publication boundary; starts retain their immediate seed.
module expression_pitch_bank_aux_bram #(parameter integer VOICES=32)(
 input wire clk,rst_n,sample_tick,input wire [VOICES-1:0] starts,
 input wire [6:0] glide,input wire [21:0] seed,input wire signed [6:0] seed_steps,
 input wire signed [7:0] lfo,output wire [VOICES*22-1:0] ratios);
 wire [VOICES*22-1:0] raw;
 expression_pitch_bank_bram #(.VOICES(VOICES),.RAW_OUTPUT(1)) memory_control(
 clk,rst_n,sample_tick,starts,glide,seed,seed_steps,lfo,raw);
 reg [21:0] sampled[0:VOICES-1];integer i;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin for(i=0;i<VOICES;i=i+1)sampled[i]<=22'd65536;end
 else for(i=0;i<VOICES;i=i+1)begin
  if(starts[i])sampled[i]<=glide!=0  ?  seed:22'd65536;
  else if(sample_tick)sampled[i]<=raw[i*22+:22];
 end
 genvar g;generate for(g=0;g<VOICES;g=g+1)begin:OUT
  assign ratios[g*22+:22]=(glide==0 && lfo==0)  ?  22'd65536:sampled[g];
 end endgenerate
endmodule
