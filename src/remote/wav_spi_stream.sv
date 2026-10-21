`default_nettype none
// Mode 0, MSB first, 4 MHz maximum, sampled by the board's 50 MHz clock.
// Each CS transaction: 57 41 01 cmd seq16le length16le payload crc16le.
// CRC-16/CCITT-FALSE covers the header and payload. Data is committed only
// after the complete transaction passes CRC, sequence and capacity checks.
module wav_spi_stream #(parameter AW=14)(
 input wire clk,rst_n,spi_sck,spi_cs_n,spi_mosi,output wire spi_miso,
 output reg start,stop,finish,output reg [31:0] file_size,
 output wire byte_valid,input wire byte_ready,output wire [7:0] byte_data,
 output wire [AW:0] buffered,input wire [7:0] player_state,player_error,
 input wire [31:0] played_frames,output reg [7:0] transport_error
);
 localparam CAPACITY=1<<AW;
 (* async_reg="true" *) reg [2:0] sck_sync,cs_sync,mosi_sync;
 wire rise=sck_sync[2:1]==2'b01,fall=sck_sync[2:1]==2'b10;
 wire select=cs_sync[2:1]==2'b10,deselect=cs_sync[2:1]==2'b01;
 reg [7:0] shift,tx_byte;reg [2:0] bit_index;
 reg [15:0] rx_count,rx_crc,wire_crc,sequence_id,length,expected_seq;
 reg [7:0] command;reg header_ok;
 reg [7:0] staging[0:1023];
 reg [7:0] memory[0:CAPACITY-1];
 reg [AW-1:0] wp,rp;reg [AW:0] count;
 reg out_valid;reg [7:0] out_data;
 reg copying,copy_wait;reg [10:0] copy_index,copy_length;reg [7:0] stage_read;
 reg cache_valid;reg [7:0] last_command;reg [15:0] last_length,last_crc;
 reg [31:0] received;reg [31:0] start_size;
 reg [191:0] status_hold;
 wire [7:0] incoming={shift[6:0],mosi_sync[2]};
 wire pop=(!out_valid || byte_ready) && count!=0;
 wire push=copying && copy_wait;
 assign byte_valid=out_valid;assign byte_data=out_data;
 assign buffered=count+{{AW{1'b0}},out_valid};
 assign spi_miso=cs_sync[2]?1'b0:tx_byte[7];
 function automatic [15:0] crc_byte(input [15:0] c,input [7:0] b);
  reg [15:0] x;integer k;
  begin x=c^{b,8'd0};for(k=0;k<8;k=k+1)x=x[15]?(x<<1)^16'h1021:x<<1;crc_byte=x;end
 endfunction
 function automatic [175:0] status_body;
  reg [191:0] p;reg [15:0] c;integer k;
  begin
   p=0;p[7:0]=8'h57;p[15:8]=8'h41;p[23:16]=1;
   p[31:24]={7'd0,copying};p[47:32]=expected_seq;
   p[63:48]=16'(CAPACITY-count-{{AW{1'b0}},out_valid});
   p[71:64]=transport_error;p[79:72]=player_state;p[87:80]=player_error;
   p[127:96]=received;p[159:128]=played_frames;
   status_body=p[175:0];
  end
 endfunction
 reg [175:0] status_body_r,status_body_crc_r;
 reg [15:0] status_crc_half_r;
 function automatic [15:0] status_crc_first(input [175:0] body);
  reg [15:0] c;integer k;
  begin
   c=16'hffff;for(k=0;k<11;k=k+1)c=crc_byte(c,body[k*8+:8]);
   status_crc_first=c;
  end
 endfunction
 function automatic [191:0] status_packet(input [175:0] body,input [15:0] first_crc);
  reg [15:0] c;integer k;
  begin
   c=first_crc;for(k=11;k<22;k=k+1)c=crc_byte(c,body[k*8+:8]);
   status_packet={c,body};
  end
 endfunction
 // Pipeline FIFO arithmetic and the two 11-byte CRC halves.
 // The body travels with its CRC; CS snapshots a coherent status 40ns old.
 always @(posedge clk or negedge rst_n)
  if(!rst_n)begin status_body_r<=0;status_body_crc_r<=0;status_crc_half_r<=16'hffff;end
  else begin
   status_body_r<=status_body();
   status_body_crc_r<=status_body_r;status_crc_half_r<=status_crc_first(status_body_r);
  end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin sck_sync<=0;cs_sync<=7;mosi_sync<=0;end
 else begin sck_sync<={sck_sync[1:0],spi_sck};cs_sync<={cs_sync[1:0],spi_cs_n};mosi_sync<={mosi_sync[1:0],spi_mosi};end
 // Synchronous RAM access. The staging RAM is never reset or exposed before CRC.
 always @(posedge clk)begin
  if(!copying && !cs_sync[2] && rise && bit_index==7 && rx_count>=8 && rx_count<8+length && rx_count<1032)
   staging[rx_count-8]<=incoming;
  if(copying && !copy_wait)stage_read<=staging[copy_index[9:0]];
  if(push)memory[wp]<=stage_read;
  if(pop)out_data<=memory[rp];
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  shift<=0;tx_byte<=0;bit_index<=0;rx_count<=0;rx_crc<=16'hffff;wire_crc<=0;
  sequence_id<=0;length<=0;expected_seq<=0;command<=0;header_ok<=0;
  wp<=0;rp<=0;count<=0;out_valid<=0;copying<=0;copy_wait<=0;copy_index<=0;copy_length<=0;
  cache_valid<=0;last_command<=0;last_length<=0;last_crc<=0;
  received<=0;start_size<=0;file_size<=0;transport_error<=0;status_hold<=0;
  start<=0;stop<=0;finish<=0;
 end else begin
  start<=0;stop<=0;finish<=0;
  if(out_valid && byte_ready)out_valid<=0;
  if(pop)begin rp<=rp+1'b1;out_valid<=1;end
  if(push)begin
   wp<=wp+1'b1;copy_wait<=0;
   if(copy_index+1>=copy_length)begin copying<=0;copy_index<=0;end
   else copy_index<=copy_index+1'b1;
  end else if(copying)copy_wait<=1;
  case({push,pop})2'b10:count<=count+1'b1;2'b01:count<=count-1'b1;default:begin end endcase
  if(select)begin
   bit_index<=0;rx_count<=0;rx_crc<=16'hffff;wire_crc<=0;shift<=0;
   header_ok<=1;length<=0;command<=0;start_size<=0;
   status_hold<=status_packet(status_body_crc_r,status_crc_half_r);tx_byte<=8'h57;
  end else if(!cs_sync[2])begin
   if(rise)begin
    shift<=incoming;bit_index<=bit_index+1'b1;
    if(bit_index==7)begin
     if(rx_count<8 || rx_count<8+length)rx_crc<=crc_byte(rx_crc,incoming);
     if(rx_count==8+length)wire_crc[7:0]<=incoming;
     if(rx_count==9+length)wire_crc[15:8]<=incoming;
     case(rx_count)
      0:if(incoming!=8'h57)header_ok<=0;
      1:if(incoming!=8'h41)header_ok<=0;
      2:if(incoming!=1)header_ok<=0;
      3:command<=incoming;
      4:sequence_id[7:0]<=incoming;5:sequence_id[15:8]<=incoming;
      6:length[7:0]<=incoming;7:length[15:8]<=incoming;
      8:start_size[7:0]<=incoming;9:start_size[15:8]<=incoming;
      10:start_size[23:16]<=incoming;11:start_size[31:24]<=incoming;
      default:begin end
     endcase
     if(rx_count!=16'hffff)rx_count<=rx_count+1'b1;
    end
   end
   if(fall)begin
    if(bit_index==0)tx_byte<=rx_count<24?status_hold[rx_count*8+:8]:8'd0;
    else tx_byte<={tx_byte[6:0],1'b0};
   end
  end
  if(deselect && command!=0)begin
   if(!header_ok || bit_index!=0 || length>1024 || rx_count!=length+10)transport_error<=1;
   else if(rx_crc!=wire_crc)transport_error<=2;
   else if(cache_valid && sequence_id==expected_seq-1'b1 && command==last_command && length==last_length && rx_crc==last_crc)transport_error<=0;
   else if(copying)transport_error<=3;
   else if(command==1 && length==4 && start_size>=44)begin
    start<=1;file_size<=start_size;received<=0;expected_seq<=sequence_id+1'b1;
    wp<=0;rp<=0;count<=0;out_valid<=0;transport_error<=0;
   end else if(command==4 && length==0)begin
    stop<=1;wp<=0;rp<=0;count<=0;out_valid<=0;received<=0;file_size<=0;
    expected_seq<=sequence_id+1'b1;transport_error<=0;
   end else if(sequence_id!=expected_seq)transport_error<=4;
   else if(command==2 && length!=0)begin
    if(file_size==0 || received+32'(length)>file_size)transport_error<=5;
    else if(32'(count)+32'(out_valid)+32'(length)>CAPACITY)transport_error<=3;
    else begin
     copying<=1;copy_wait<=0;copy_index<=0;copy_length<=length[10:0];received<=received+32'(length);
     expected_seq<=expected_seq+1'b1;transport_error<=0;
    end
   end else if(command==3 && length==0 && received==file_size && file_size!=0)begin
    finish<=1;expected_seq<=expected_seq+1'b1;transport_error<=0;
   end else transport_error<=5;
   // Only successful, first executions enter the duplicate cache.
   if(header_ok && bit_index==0 && length<=1024 && rx_count==length+10 && rx_crc==wire_crc && !copying &&
      ((command==1 && length==4 && start_size>=44) || (command==4 && length==0) ||
       (sequence_id==expected_seq &&
        ((command==2 && length!=0 && file_size!=0 && received+32'(length)<=file_size &&
          32'(count)+32'(out_valid)+32'(length)<=CAPACITY) ||
         (command==3 && length==0 && received==file_size && file_size!=0)))))begin
    cache_valid<=1;last_command<=command;last_length<=length;last_crc<=rx_crc;
   end
  end
 end
endmodule
`default_nettype wire
