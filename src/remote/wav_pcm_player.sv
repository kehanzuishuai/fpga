`default_nettype none
// Streaming RIFF/WAVE decoder. PCM format 1, 16/24 bit, mono/stereo,
// 44100/48000 Hz. All RIFF parsing and resampling happen in the FPGA.
// Unknown chunks and odd-byte padding are skipped within the RIFF bounds.
// The bounded input FIFO is supplied by wav_spi_stream, not a whole-file RAM.
module wav_pcm_player(
 input wire clk,rst_n,start,stop,finish,input wire [31:0] file_size,
 input wire byte_valid,output wire byte_ready,input wire [7:0] byte_data,
 input wire [14:0] buffered,input wire frame_tick,
 output reg signed [23:0] left_pcm,right_pcm,
 output reg [7:0] status,error,output reg [31:0] played_frames
);
 localparam IDLE=0,RIFF=1,CHUNK=2,FMT=3,SKIP=4,DATA=5,PAD=6,DONE=7,FAIL=8,COUNT=9,BOUND_SUM=10,BOUND_CHECK=11;
 reg [32:0] chunk_end;
 reg [31:0] last_source_index,pop_limit;
 reg [3:0] state;reg [5:0] pos;
 reg [31:0] quotient;reg [2:0] remainder3;reg [5:0] divide_count;
 wire [3:0] shifted_remainder={remainder3,quotient[31]};
 wire divide_bit=shifted_remainder>={1'b0,block_align[2:0]};
 wire [3:0] next_remainder=divide_bit?shifted_remainder-{1'b0,block_align[2:0]}:shifted_remainder;
 wire [31:0] next_quotient={quotient[30:0],divide_bit};
 reg [31:0] offset,chunk_id,chunk_size,remaining,container_size;
 reg fmt_seen,data_seen,input_finished,playing;
 reg [15:0] format_code,channels,block_align,bits;
 reg [31:0] sample_rate,byte_rate,data_frames;
 reg [2:0] frame_byte;reg [47:0] frame_build;
 reg [47:0] frames[0:63];reg [5:0] wr,rd;reg [6:0] queued;
 reg signed [23:0] a_l,a_r,b_l,b_r;
 reg [15:0] phase;reg [31:0] source_index;
 wire [31:0] chunk_size_next={byte_data,chunk_size[31:8]};
 wire [47:0] frame_next=frame_build | (48'(byte_data) << (frame_byte*8));
 wire take=byte_valid && byte_ready;
 wire push=take && state==DATA && frame_byte+1==block_align;
 wire begin_play=!playing && status==1 && data_seen && error==0 && queued!=0 &&
                 (buffered>=8192 || input_finished);
 wire [16:0] phase_sum={1'b0,phase}+17'(sample_rate);
 wire advance=phase_sum>=48000;
 wire normal_pop=playing && frame_tick && advance && source_index<pop_limit;
 wire [1:0] pops=begin_play?(data_frames>1?2:1):(normal_pop?1:0);
 wire [31:0] fraction_wide=32'(phase)*32'd89478;
 wire [15:0] fraction=fraction_wide[31:16];
 wire signed [24:0] dl={b_l[23],b_l}-{a_l[23],a_l};
 wire signed [24:0] dr={b_r[23],b_r}-{a_r[23],a_r};
 wire signed [41:0] product_l=dl*$signed({1'b0,fraction});
 wire signed [41:0] product_r=dr*$signed({1'b0,fraction});
 assign byte_ready=state!=BOUND_SUM && state!=BOUND_CHECK && state!=COUNT && state!=IDLE && state!=DONE && state!=FAIL && offset<file_size &&
                   (state!=PAD || chunk_size[0]) && (state!=DATA || queued<62);
 wire [31:0] expected_byte_rate=(block_align==2)?sample_rate<<1:
  (block_align==3)?sample_rate+(sample_rate<<1):
  (block_align==4)?sample_rate<<2:(sample_rate<<2)+(sample_rate<<1);
 task automatic fail(input [7:0] reason);
  begin error<=reason;state<=FAIL;playing<=0;left_pcm<=0;right_pcm<=0;status<=8;end
 endtask
 always @(posedge clk)if(push)begin
  if(bits==16)frames[wr]<=channels==1?{frame_next[15:0],8'd0,frame_next[15:0],8'd0}:
                                                {frame_next[31:16],8'd0,frame_next[15:0],8'd0};
  else frames[wr]<=channels==1?{frame_next[23:0],frame_next[23:0]}:frame_next;
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  chunk_end<=0;last_source_index<=0;pop_limit<=0;quotient<=0;remainder3<=0;divide_count<=0;state<=IDLE;pos<=0;offset<=0;chunk_id<=0;chunk_size<=0;remaining<=0;container_size<=0;
  fmt_seen<=0;data_seen<=0;input_finished<=0;playing<=0;
  format_code<=0;channels<=0;block_align<=0;bits<=0;sample_rate<=0;byte_rate<=0;data_frames<=0;
  frame_byte<=0;frame_build<=0;wr<=0;rd<=0;queued<=0;
  a_l<=0;a_r<=0;b_l<=0;b_r<=0;phase<=0;source_index<=0;
  left_pcm<=0;right_pcm<=0;status<=0;error<=0;played_frames<=0;
 end else if(start || stop)begin
  chunk_end<=0;last_source_index<=0;pop_limit<=0;quotient<=0;remainder3<=0;divide_count<=0;state<=start?RIFF:IDLE;pos<=0;offset<=0;chunk_id<=0;chunk_size<=0;remaining<=0;container_size<=0;
  fmt_seen<=0;data_seen<=0;input_finished<=0;playing<=0;
  format_code<=0;channels<=0;block_align<=0;bits<=0;sample_rate<=0;byte_rate<=0;data_frames<=0;
  frame_byte<=0;frame_build<=0;wr<=0;rd<=0;queued<=0;
  a_l<=0;a_r<=0;b_l<=0;b_r<=0;phase<=0;source_index<=0;
  left_pcm<=0;right_pcm<=0;status<=start?1:0;error<=0;played_frames<=0;
 end else begin
  if(finish)input_finished<=1;
  if(push)wr<=wr+1'b1;
  if(pops!=0 && queued>=pops)rd<=rd+6'(pops);
  queued<=queued+7'(push)-((queued>=pops)?7'(pops):7'd0);
  if(begin_play && queued>=(data_frames>1?2:1))begin
   {a_r,a_l}<=frames[rd];{b_r,b_l}<=frames[data_frames>1?rd+6'd1:rd];
   source_index<=0;phase<=0;playing<=1;status<=2;
  end
  if(playing && frame_tick)begin
   left_pcm<=a_l+24'(product_l>>>16);right_pcm<=a_r+24'(product_r>>>16);
   played_frames<=played_frames+1'b1;
   phase<=16'(advance?phase_sum-48000:phase_sum);
   if(advance)begin
    if(source_index>=last_source_index)begin playing<=0;status<=3;end
    else if(normal_pop && queued==0)fail(7); // underrun: never repeat stale samples
    else begin
     source_index<=source_index+1'b1;a_l<=b_l;a_r<=b_r;
     if(normal_pop){b_r,b_l}<=frames[rd];
    end
   end
  end else if(!playing && status==3 && frame_tick)begin left_pcm<=0;right_pcm<=0;end
  if(state==BOUND_SUM)begin
   chunk_end<={1'b0,offset}+{1'b0,chunk_size}+33'(chunk_size[0]);state<=BOUND_CHECK;
  end
  if(state==BOUND_CHECK)begin
      if(chunk_end>{1'b0,file_size})fail(2);
      else if(chunk_id==32'h20746d66)begin
       if(fmt_seen || data_seen || chunk_size<16)fail(3);else state<=FMT;
      end else if(chunk_id==32'h61746164)begin
       if(!fmt_seen || data_seen || chunk_size==0)fail(4);
       else begin
        quotient<=chunk_size;remainder3<=0;divide_count<=32;state<=COUNT;
        frame_byte<=0;frame_build<=0;
       end
      end else if(chunk_size==0)state<=CHUNK;
      else state<=SKIP;
  end
  if(state==COUNT)begin
   quotient<=next_quotient;remainder3<=next_remainder[2:0];divide_count<=divide_count-1'b1;
   if(divide_count==1)begin
    if(next_remainder!=0)fail(4);
    else begin data_seen<=1;data_frames<=next_quotient;last_source_index<=next_quotient-1'b1;pop_limit<=(next_quotient>2)?next_quotient-2:0;state<=DATA;frame_byte<=0;frame_build<=0;end
   end
  end
  if(take)begin
   offset<=offset+1'b1;
   case(state)
    RIFF:begin
     pos<=pos+1'b1;
     case(pos)
      0:if(byte_data!="R")fail(1);1:if(byte_data!="I")fail(1);
      2,3:if(byte_data!="F")fail(1);
      4:container_size[7:0]<=byte_data;5:container_size[15:8]<=byte_data;
      6:container_size[23:16]<=byte_data;7:container_size[31:24]<=byte_data;
      8:if(byte_data!="W")fail(1);9:if(byte_data!="A")fail(1);
      10:if(byte_data!="V")fail(1);
      11:begin
       if(byte_data!="E" || {1'b0,container_size}+33'd8!={1'b0,file_size})fail(1);
       else begin state<=CHUNK;pos<=0;end
      end
      default:fail(1);
     endcase
    end
    CHUNK:begin
     pos<=pos+1'b1;
     if(pos<4)chunk_id<={byte_data,chunk_id[31:8]};
     else chunk_size<={byte_data,chunk_size[31:8]};
     if(pos==7)begin
      remaining<=chunk_size_next;pos<=0;
      state<=BOUND_SUM;
     end
    end
    FMT:begin
     remaining<=remaining-1'b1;if(pos<17)pos<=pos+1'b1;
     case(pos)
      0:format_code[7:0]<=byte_data;1:format_code[15:8]<=byte_data;
      2:channels[7:0]<=byte_data;3:channels[15:8]<=byte_data;
      4:sample_rate[7:0]<=byte_data;5:sample_rate[15:8]<=byte_data;
      6:sample_rate[23:16]<=byte_data;7:sample_rate[31:24]<=byte_data;
      8:byte_rate[7:0]<=byte_data;9:byte_rate[15:8]<=byte_data;
      10:byte_rate[23:16]<=byte_data;11:byte_rate[31:24]<=byte_data;
      12:block_align[7:0]<=byte_data;13:block_align[15:8]<=byte_data;
      14:bits[7:0]<=byte_data;15:bits[15:8]<=byte_data;
      default:begin end
     endcase
     // Validate after the final fmt byte has been registered (PAD state).
     if(remaining==1)begin fmt_seen<=1;state<=PAD;pos<=0;end
    end
    SKIP:begin remaining<=remaining-1'b1;if(remaining==1)begin state<=PAD;pos<=0;end end
    DATA:begin
     remaining<=remaining-1'b1;frame_build<=frame_next;
     if(frame_byte+1==block_align)begin frame_byte<=0;frame_build<=0;end
     else frame_byte<=frame_byte+1'b1;
     if(remaining==1)begin state<=PAD;pos<=0;end
    end
    PAD:begin state<=CHUNK;pos<=0;end
    default:fail(2);
   endcase
  end
  // Non-byte transition permits fmt validation and even-chunk completion
  // without accidentally consuming the next chunk's first byte.
  if(state==PAD)begin
   if(fmt_seen && (format_code!=1 || (channels!=1 && channels!=2) ||
      (bits!=16 && bits!=24) || (sample_rate!=44100 && sample_rate!=48000) ||
      block_align!=(channels==1?(bits>>3):(bits>>2)) || byte_rate!=expected_byte_rate))fail(5);
   else if(!chunk_size[0])begin state<=CHUNK;pos<=0;end
  end
  if(state==CHUNK && pos==0 && offset==file_size)begin
   if(!data_seen)fail(4);else state<=DONE;
  end
  if(input_finished && buffered==0 && !byte_valid && offset!=file_size && state!=IDLE && state!=FAIL && state!=BOUND_SUM && state!=BOUND_CHECK)fail(6);
 end
endmodule
`default_nettype wire
