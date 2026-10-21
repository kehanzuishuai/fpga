`timescale 1ns/1ps
module tb_wav;
 reg clk=0;always #10 clk=~clk;
 reg rst_n=0,sck=0,cs=1,mosi=0;wire miso;
 wire start,stop,finish,valid,ready;wire [7:0] data,status,error,transport_error;
 wire [31:0] size,played;wire [14:0] buffered;
 reg frame_tick=0;integer tick_count=0;
 always @(posedge clk)begin
  if(tick_count==1041)begin tick_count<=0;frame_tick<=1;end
  else begin tick_count<=tick_count+1;frame_tick<=0;end
 end
 wire signed [23:0] l,r;
 wav_spi_stream stream(clk,rst_n,sck,cs,mosi,miso,start,stop,finish,size,
 valid,ready,data,buffered,status,error,played,transport_error);
 wav_pcm_player player(clk,rst_n,start,stop,finish,size,valid,ready,data,buffered,frame_tick,l,r,status,error,played);
 reg [7:0] source[0:262143];reg [47:0] expected[0:65535];
 reg [7:0] packet[0:1033];reg [7:0] response[0:23];
 integer file_bytes,expected_frames,seq=100,matched=0,test_case=0;
 string fixture;
 function automatic [15:0] crc_byte(input [15:0] c,input [7:0] b);
  reg [15:0] x;integer k;
  begin x=c^{b,8'd0};for(k=0;k<8;k=k+1)x=x[15]?(x<<1)^16'h1021:x<<1;crc_byte=x;end
 endfunction
 task automatic spi_byte(input [7:0] tx,output reg [7:0] rx);
  integer bitno;
  begin rx=0;for(bitno=7;bitno>=0;bitno=bitno-1)begin
   mosi=tx[bitno];#125;rx={rx[6:0],miso};sck=1;#125;sck=0;
  end end
 endtask
 task automatic poll;
  integer i;reg [7:0] value;reg [15:0] crc;
  begin
   cs=0;#1000;
   for(i=0;i<24;i=i+1)begin spi_byte(i==0?8'h57:i==1?8'h41:i==2?8'd1:8'd0,value);response[i]=value;end
   #500;cs=1;#1000;
   crc=16'hffff;for(i=0;i<22;i=i+1)crc=crc_byte(crc,response[i]);
   if(response[0]!=8'h57 || response[1]!=8'h41 || crc!={response[23],response[22]})$fatal(1,"SPI status CRC / timing");
  end
 endtask
 task automatic send(input [7:0] command,input integer length,input bit corrupt);
  integer i;reg [15:0] crc;reg [7:0] ignored;
  begin
   packet[0]=8'h57;packet[1]=8'h41;packet[2]=1;packet[3]=command;
   packet[4]=8'(seq);packet[5]=8'(seq>>8);packet[6]=8'(length);packet[7]=8'(length>>8);
   crc=16'hffff;for(i=0;i<8+length;i=i+1)crc=crc_byte(crc,packet[i]);
   packet[8+length]=crc[7:0]^(corrupt?8'd1:8'd0);packet[9+length]=crc[15:8];
   cs=0;#1000;for(i=0;i<10+length;i=i+1)spi_byte(packet[i],ignored);
   #500;cs=1;#1000;
  end
 endtask
 always @(posedge clk)if(frame_tick && player.playing)begin
  #1;
  if(matched>=expected_frames)$fatal(1,"too many output frames");
  if({r,l}!==expected[matched])$fatal(1,"PCM case%0d frame%0d got %h/%h expected %h",test_case,matched,l,r,expected[matched]);
  matched=matched+1;
 end
 task automatic fixture_test(input string name,input integer number);
  integer offset,n,i,tries;
  begin
   test_case=number;matched=0;
   $readmemh({"tests/remote_music_20261019/out/",name,".mem"},source);
   $readmemh({"tests/remote_music_20261019/out/",name,"_expected.mem"},expected);
   file_bytes={source[3],source[2],source[1],source[0]};
   expected_frames={source[7],source[6],source[5],source[4]};
   packet[8]=8'(file_bytes);packet[9]=8'(file_bytes>>8);packet[10]=8'(file_bytes>>16);packet[11]=8'(file_bytes>>24);
   send(1,4,0);seq=seq+1;poll();
   if({response[5],response[4]}!=16'(seq) || transport_error!=0)$fatal(1,"start");
   offset=0;
   while(offset<file_bytes)begin
    n=file_bytes-offset>1024?1024:file_bytes-offset;
    poll();tries=0;
    while(response[3][0] || {response[7],response[6]}<n)begin
     #100000;poll();tries=tries+1;if(tries>200)$fatal(1,"stalled stream %d error%d",status,error);
    end
    for(i=0;i<n;i=i+1)packet[8+i]=source[8+offset+i];
    if(offset==0)begin
     send(2,n,1);if(transport_error!=2)$fatal(1,"CRC rejection");
     if(stream.received!=0)$fatal(1,"corrupt frame committed");
    end
    send(2,n,0);seq=seq+1;
    if(transport_error!=0)$fatal(1,"data rejected %d",transport_error);
    if(offset==0)begin
     seq=seq-1;send(2,n,0);seq=seq+1;
     if(stream.received!=n)$fatal(1,"retry committed twice");
    end
    offset=offset+n;
   end
   poll();while(response[3][0])poll();send(3,0,0);seq=seq+1;
   tries=0;
   while(status!=3 && error==0)begin #100000;tries=tries+1;if(tries>10000)$fatal(1,"playback timeout");end
   if(error!=0 || matched!=expected_frames)$fatal(1,"case%0d decode error%0d frames%0d/%0d",number,error,matched,expected_frames);
   $display("PASS WAV %s: %0d raw bytes, %0d exact stereo output frames, CRC rejection and retry",name,file_bytes,matched);$fflush();
   send(4,0,0);seq=seq+1;#50000;
   if(l!=0 || r!=0 || buffered!=0)$fatal(1,"stop did not flush");
  end
 endtask
 initial begin
  #100;rst_n=1;#5000;
  fixture_test("stereo24_48000",0);
  fixture_test("mono16_44100",1);
  fixture_test("stereo16_48000",2);
  $display("PASS WAV integration");$finish;
 end
 initial begin #2000000000;$fatal(1,"global timeout");end
endmodule
