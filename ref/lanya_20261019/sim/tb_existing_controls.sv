`timescale 1ns/1ps
module tb_existing_controls;
 reg clk=0;always #5 clk=~clk;reg rst_n=0,mv=0,tv=0,local_event=0;
 reg [1:0] mtarget=0;reg [2:0] ttarget=0;
 wire mr,tr,mnext,tnext,adapter_fault;
 wire [1:0] current_mode,requested_mode;wire [2:0] current_timbre,requested_timbre;
 wire ms,ts,mode_fault,clear_request,mode_committed,timbre_committed;
 wire [15:0] unused_mgain,unused_tgain;wire unused_mblock,unused_tblock,unused_tflush,unused_tclear,unused_mclear;
 reg clear_ack=0;reg [15:0] keys=0;
 always @(posedge clk)clear_ack<=clear_request;
 wifi_request_steps #(.CLK_HZ(1000)) adapter(
  .clk(clk),.rst_n(rst_n),.switching(ms||ts),.system_fault(mode_fault),
  .local_mode_event(local_event),.local_timbre_event(local_event),
  .mode_valid(mv),.mode_ready(mr),.mode_value(mtarget),.mode_requested(requested_mode),
  .timbre_valid(tv),.timbre_ready(tr),.timbre_value(ttarget),.timbre_requested(requested_timbre),
  .remote_mode_next(mnext),.remote_timbre_next(tnext),.adapter_fault(adapter_fault));
 tl_mode_control #(.FADE_SAMPLES(4),.CLEAR_TIMEOUT(200)) mode_control(
  .clk(clk),.rst_n(rst_n),.sample_tick(1'b1),.next_mode(mnext&&!local_event),.loader_busy(1'b0),.clear_ack(clear_ack),
  .current_mode(current_mode),.requested_mode(requested_mode),.gain(unused_mgain),.block_note_on(unused_mblock),
  .clear_request(clear_request),.switching(ms),.clear_theremin(unused_mclear),.committed(mode_committed),.fault(mode_fault));
 yinse_selector selector(clk,rst_n,tnext&&!local_event,1'b0,requested_timbre);
 yinse_switch #(.FADE_SAMPLES(4),.KEYS(16)) timbre_control(
  .clk(clk),.rst_n(rst_n),.sample_tick(1'b1),.requested_id(requested_timbre),.keys_down(keys),.loader_busy(1'b0),
  .current_id(current_timbre),.gain(unused_tgain),.block_events(unused_tblock),.flush_events(unused_tflush),
  .clear_aux(unused_tclear),.committed(timbre_committed),.switching(ts));
 task mode(input [1:0] v);begin @(negedge clk);mtarget=v;mv=1;wait(mr);@(negedge clk);mv=0;end endtask
 task timbre(input [2:0] v);begin @(negedge clk);ttarget=v;tv=1;wait(tr);@(negedge clk);tv=0;end endtask
 initial begin
  repeat(4)@(negedge clk);rst_n=1;
  timbre(3);repeat(60)@(negedge clk);
  if(current_timbre!=3||ts||adapter_fault)$fatal(1,"actual yinse switch");
  mode(2);repeat(60)@(negedge clk);
  if(current_mode!=2||ms||mode_fault||adapter_fault)$fatal(1,"actual theremin mode switch");
  mode(0);repeat(60)@(negedge clk);if(current_mode!=0||ms)$fatal(1,"mode wrap");
  keys=1;timbre(1);repeat(60)@(negedge clk);
  if(current_timbre!=3||!ts)$fatal(1,"held keys barrier bypassed");
  keys=0;repeat(60)@(negedge clk);if(current_timbre!=1||ts)$fatal(1,"key release not applied");
  if(adapter_fault||mode_fault)$fatal(1,"unexpected fault");
  $display("PASS real yinse_selector/yinse_switch/tl_mode_control: absolute targets, mode wrap, fade/clear and held-key barrier");$finish;
 end
 initial begin #100000;$fatal(1,"existing controls watchdog");end
endmodule
