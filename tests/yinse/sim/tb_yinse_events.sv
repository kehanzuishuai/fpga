`timescale 1ns/1ps
module tb_yinse_events;
 reg clk=0,rst_n=0,tick=0,clear=0,valid=0,on=1;reg [2:0] instrument=3;
 reg [6:0] note=36;reg [7:0] velocity=100;
 always #5 clk=~clk;
 integer counter=0,accepted=0,expected=0,wait_cycles=0;
 always @(negedge clk)begin counter=counter+1;tick=counter%16==0;end
 wire ready,pcm_valid,rejected;wire signed [23:0] pcm;wire [3:0] active,overrun,clips;
 yinse_aux_bank #(.VOICES(4)) dut(clk,rst_n,tick,clear,valid,on,instrument,note,velocity,
 ready,pcm,pcm_valid,active,overrun,clips,rejected);
 always @(posedge clk)if(rst_n && valid && ready && !clear)accepted=accepted+1;
 task automatic send(input integer n,input bit is_on,input integer vel);
  integer elapsed;reg found;begin
   @(negedge clk);note=7'(n);on=is_on;velocity=8'(vel);valid=1;elapsed=0;
   @(posedge clk);
   while(!ready)begin elapsed=elapsed+1;if(elapsed>3000)$fatal(1,"stalled forever");@(posedge clk);end
   expected=expected+1;wait_cycles=wait_cycles+elapsed;
   @(negedge clk);valid=0;
   if(accepted!=expected)$fatal(1,"lost/duplicate ready-valid event");
   if(is_on && vel>0)begin
    found=0;
    if(dut.notes[6:0]==note || dut.notes[13:7]==note || dut.notes[20:14]==note || dut.notes[27:21]==note)found=1;
    if(!found)$fatal(1,"acknowledged note not stored");
   end
  end
 endtask
 integer i;
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(4)@(negedge clk);rst_n=1;
  // More note events than slots; initialization must produce real backpressure.
  for(i=0;i<100;i=i+1)begin
   send(36+(i%61),1,100);
   if(i%7==0)send(36+(i%61),0,0); // note off even when KS fills RAM
  end
  for(i=0;i<20;i=i+1)send(69,1,100); // same-note retrigger under pressure
  send(69,1,0);
  if(wait_cycles==0)$fatal(1,"backpressure not exercised");
  if(|overrun || |clips || rejected)$fatal(1,"stress status");
  @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;
  repeat(40)@(negedge clk);
  if(active!=0 || pcm!=0)$fatal(1,"clear not prioritized");
  $display("PASS %0d ready-valid events, %0d waiting cycles, full bank stealing, note storage, repeat, velocity-zero release and clear",accepted,wait_cycles);$finish;
 end
 initial begin #10000000;$fatal(1,"event watchdog");end
endmodule
