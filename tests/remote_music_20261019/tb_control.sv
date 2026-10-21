`timescale 1ns/1ps
module tb_control;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,rx=1;wire tx;reg tick=0;integer count=0;
 always @(negedge clk)begin count=count+1;tick=count%16==0;end
 reg [31:0] keys=0;wire kv,ko,kr,brst,ev,eo,er;
 wire [4:0] ki;wire [6:0] kn,en,mapped;wire [7:0] vel,v;wire [1:0] kw,ew;
 wire [31:0] reported;wire [2:0] instrument;wire switching,clear,playing;
 wire [15:0] volume,gain;wire [4:0] fx;wire [223:0] key_map;
 assign er=1;
 ttp229_event_bridge #(.KEY_COUNT(32)) bridge(clk,brst,1'b1,keys,8'd100,kr,kv,ko,kn,vel,kw,ki,reported);
 remote_control dut(clk,rst_n,tick,rx,tx,keys,kv,ko,ki,vel,kw,kr,brst,
 ev,eo,en,v,ew,er,1'b1,5'd0,instrument,switching,clear,volume,fx,playing,mapped,key_map,gain);
 wire got,framing;wire [7:0] reply_byte;
 wifi_uart_rx receiver(clk,rst_n,tx,reply_byte,got,framing);
 reg [7:0] reply[0:15],packet[0:15];integer reply_count=0,sequence_id=1;
 integer on_count=0,off_count=0;reg [6:0] last_note;
 always @(posedge clk)begin
  if(framing)$fatal(1,"UART reply framing");
  if(got)begin if(reply_count>=16)$fatal(1,"extra reply");reply[reply_count]=reply_byte;reply_count=reply_count+1;end
  if(ev&&er)begin if(eo)on_count=on_count+1;else off_count=off_count+1;last_note=en;end
  if(clear&&gain!=0)$fatal(1,"timbre reset was not silent");
 end
 function automatic [15:0] crc(input [15:0] initial_crc,input [7:0] b);
  reg [15:0] x;integer k;begin x=initial_crc^{b,8'd0};for(k=0;k<8;k=k+1)x=x[15]?(x<<1)^16'h1021:x<<1;crc=x;end
 endfunction
 task automatic uart_byte(input [7:0] b);
  integer k;begin rx=0;repeat(107)@(negedge clk);for(k=0;k<8;k=k+1)begin rx=b[k];repeat(107)@(negedge clk);end
  rx=1;repeat(107)@(negedge clk);end
 endtask
 task automatic request(input [7:0] cmd,input integer n,input [47:0] p,input integer expected_status);
  integer k,waited;reg [15:0] c;
  begin
   reply_count=0;
   for(k=0;k<16;k=k+1)packet[k]=0;
   packet[0]=8'ha5;packet[1]=8'h5a;packet[2]=1;packet[3]=8'(sequence_id);packet[4]=cmd;packet[5]=8'(n);
   for(k=0;k<n;k=k+1)packet[6+k]=p[k*8+:8];
   c=16'hffff;for(k=2;k<14;k=k+1)c=crc(c,packet[k]);packet[14]=c[7:0];packet[15]=c[15:8];
   for(k=0;k<16;k=k+1)uart_byte(packet[k]);
   waited=0;while(reply_count<16)begin @(negedge clk);waited=waited+1;if(waited>3000000)$fatal(1,"UART timeout cmd%h",cmd);end
   c=16'hffff;for(k=2;k<14;k=k+1)c=crc(c,reply[k]);
   if(reply[3]!=8'(sequence_id)||reply[6]!=cmd||reply[7]!=expected_status||c!={reply[15],reply[14]})$fatal(1,"reply cmd%h status%0d expected%0d",cmd,reply[7],expected_status);
   sequence_id=sequence_id+1;repeat(10)@(negedge clk);
  end
 endtask
 integer old_on,old_off,n;
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
  request(1,0,0,0);request(8'h24,1,16,0);if(reply[9]!=76)$fatal(1,"bank2 must start at76");
  keys=32'h80000000;repeat(20)@(negedge clk);if(on_count!=1||last_note!=91)$fatal(1,"key32");
  for(n=1;n<=4;n=n+1)begin
   old_on=on_count;request(8'h11,1,48'(n),0);
   wait(!switching);repeat(30)@(negedge clk);
   if(instrument!=0 || dut.selected_instrument!=n || on_count!=old_on || last_note!=91 || gain!=65535 || switching)
    $fatal(1,"phone selection affected physical piano %d on%0d/%0d",n,on_count,old_on);
  end
  keys=0;repeat(30)@(negedge clk);
  request(8'h12,2,16'd32768,0);repeat(5000)@(negedge clk);if(volume!=32768)$fatal(1,"volume");
  request(8'h13,1,5'b10010,0);if(fx!=5'b10010)$fatal(1,"FX not applied");
  request(8'h10,1,1,2); // No unimplemented theremin/ensemble mode advertised.
  request(8'h30,1,1,0);request(8'h31,5,{8'd0,16'd3000,8'd100,8'd64,8'd0},0);request(8'h32,0,0,0);
  for(n=0;n<5;n=n+1)begin
  request(8'h11,1,48'(n),0);old_on=on_count;old_off=off_count;
  request(8'h15,1,1,0);wait(on_count==old_on+1);
  if(!playing||instrument!=n||last_note!=64)$fatal(1,"automatic score timbre");
  keys=1;repeat(100)@(negedge clk);if(on_count!=old_on+1)$fatal(1,"key interrupted score ownership");
  request(8'h15,1,0,0);wait(!playing && !switching);repeat(30)@(negedge clk);
  if(instrument!=0||off_count!=old_off+1||on_count!=old_on+2||last_note!=60)$fatal(1,"score stop/piano rearm");
  keys=0;repeat(30)@(negedge clk);
  end
  request(8'h30,1,1,0);request(8'h31,5,{8'd0,16'd10,8'd100,8'd64,8'd0},0);request(8'h32,0,0,0);
  old_on=on_count;old_off=off_count;request(8'h15,1,1,0);wait(!playing && !switching);
  if(on_count!=old_on+1 || off_count!=old_off+1 || instrument!=0)$fatal(1,"natural score end must return to piano");
  request(8'h20,0,0,0);
  for(n=0;n<32;n=n+1)request(8'h21,2,{32'd0,8'd60,8'(n)},0);
  request(8'h22,0,0,1);request(8'h24,1,31,0);if(reply[9]!=91)$fatal(1,"duplicate map committed");
  for(n=0;n<32;n=n+1)begin
   request(8'h21,2,{32'd0,8'(91-n),8'(n)},0);
   if(key_map!==dut.DEFAULT_KEYS)$fatal(1,"partial key map became active");
  end
  request(8'h22,0,0,0);if(dut.key_revision!=1)$fatal(1,"key map revision");
  sequence_id=sequence_id-1;request(8'h22,0,0,0);
  if(dut.key_revision!=1)$fatal(1,"retried commit applied twice");
  for(n=0;n<32;n=n+1)if(key_map[n*7+:7]!==7'(91-n))$fatal(1,"atomic map mismatch key%0d",n);
  request(8'h24,1,0,0);if(reply[9]!=91)$fatal(1,"updated key1");
  request(8'h24,1,31,0);if(reply[9]!=60)$fatal(1,"updated key32");
  keys=1;repeat(30)@(negedge clk);request(8'h20,0,0,0);
  for(n=0;n<32;n=n+1)request(8'h21,2,{32'd0,8'(60+n),8'(n)},0);
  request(8'h22,0,0,3);if(key_map[0+:7]!=91 || dut.key_revision!=1)$fatal(1,"busy map committed");
  $display("PASS real UART control: physical keys remain piano under all phone timbre selections, score-only timbre and final NoteOff/piano rearm, volume, FX, duplicate map rejection, atomic 32-key commit/retry and busy rejection");$finish;
 end
 initial begin #100000000;$fatal(1,"control timeout");end
endmodule
