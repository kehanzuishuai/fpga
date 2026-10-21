`timescale 1ns/1ps
// Snapshot injection at the reader/mapper boundary; never claims physical order.
module tb_scale_mapping;
parameter REMAPPED=0, BASE=60;
localparam [63:0] RAW_TABLE=64'hfedc43210ba98765;
reg clk50=0,rst_n=0;always #10 clk50=~clk50;
reg [15:0] raw=0;reg fv=0;
wire scl;
tang_mega_138k_pro_top #(.KEY_RAW_MAP_ENABLE(REMAPPED),
 .KEY_RAW_INDEX_TABLE(RAW_TABLE),.KEY_BASE_NOTE(BASE)) dut(
 .clk_50m(clk50),.rst_n(rst_n),.ttp229_scl(scl),.ttp229_sdo(1'b1));
wire clk=dut.clk_12m288;
integer ons=0,offs=0,k,b,fd,timeout;
reg [15:0] accepted=0;
always @(posedge clk)if(dut.synth_rst_n && dut.event_valid && dut.event_ready)begin
 if(dut.event_note!==BASE+dut.event_key_index || dut.event_velocity!==100)
   $fatal(1,"actual elaborated table/key/velocity mismatch");
 if(dut.event_note_on)begin
   if(accepted[dut.event_key_index])$fatal(1,"duplicate On");
   accepted[dut.event_key_index]=1;ons=ons+1;
 end else begin
   if(!accepted[dut.event_key_index])$fatal(1,"unmatched Off");
   accepted[dut.event_key_index]=0;offs=offs+1;
 end
end
function [15:0] raw_for(input [15:0] keys);
 integer i;begin raw_for=0;
 for(i=0;i<16;i=i+1)raw_for[REMAPPED ? RAW_TABLE[i*4+:4] : i]=keys[i];
 end
endfunction
task snapshot(input [15:0] keys);
 begin
 @(negedge clk);raw=raw_for(keys);fv=1;
 @(negedge clk);fv=0;
 timeout=0;
 while((dut.key_state!==keys || accepted!==keys || dut.event_valid || dut.fifo_level!=0 ||
  dut.u_synth_top.u_synth.u_core.u_bank.ld_busy) && timeout<65000)begin
  @(negedge clk);timeout=timeout+1;
 end
 if(timeout>=65000)$fatal(1,"state/FIFO/loader convergence");
 if(keys && dut.status_note!==BASE+$clog2(keys & (~keys+1)))$fatal(1,"HDMI source note differs from event mapping");
 end
endtask
initial begin
 force dut.key_reader_state=raw;force dut.key_reader_frame_valid=fv;force dut.key_frame_error=1'b0;
 fd=$fopen($sformatf("tests/scale_decay_20261017/mapping_r%0d_b%0d.csv",REMAPPED,BASE),"w");
 $fdisplay(fd,"target_physical_key,configured_raw_bit,logical_key,midi,target_frequency_hz,physical_status");
 $dumpfile($sformatf("tests/scale_decay_20261017/mapping_r%0d_b%0d.vcd",REMAPPED,BASE));
 $dumpvars(0,raw,fv,dut.key_state,dut.event_valid,dut.event_ready,dut.event_note_on,dut.event_note,accepted);
 #1;rst_n=1;#1;rst_n=0;#1000;rst_n=1;wait(dut.synth_rst_n);
 if(dut.KEYBOARD_PROFILE!=0 || dut.u_ttp229_event_bridge.USE_NOTE_TABLE!=1 || dut.key_mapping_error)
  $fatal(1,"unexpected effective configuration");
 for(k=0;k<16;k=k+1)begin
  snapshot(16'b1<<k);
  b=REMAPPED ? RAW_TABLE[k*4+:4] : k;
  $fdisplay(fd,"%0d,%0d,%0d,%0d,%.9f,待GAO确认",k+1,b,k,dut.event_note,440.0*$pow(2.0,(BASE+k-69)/12.0));
  $display("PASS raw%0d logical%0d -> MIDI%0d On/Off; physical order UNCONFIRMED",b,k,dut.event_note);
  snapshot(0);
 end
 // Include all high bits, independent releases, and all sixteen simultaneous.
 snapshot(16'hf001);snapshot(16'hd001);snapshot(16'h8001);snapshot(0);
 snapshot(16'hffff);snapshot(16'hfffe);snapshot(16'h8000);snapshot(0);
 if(ons!=37 || offs!=37)$fatal(1,"expected 37 On/Off, got %0d/%0d",ons,offs);
 if(dut.key_note_on_count!=37 || dut.key_note_off_count!=37)$fatal(1,"real FIFO-write counts differ");
 $fclose(fd);$display("PASS scale mapping base=%0d remapped=%0d 16 unique notes, 37 On/37 Off, high chords and all16",BASE,REMAPPED);$finish;
end
initial begin #2000000000;$fatal(1,"mapping timeout");end
endmodule
