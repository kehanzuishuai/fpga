`default_nettype none
// Absolute Wi-Fi targets -> one-cycle NEXT pulses for existing tl_mode_control /
// yinse_selector. Feed their REQUESTED registers back; actual state stays separate.
// Local input wins and cancels a pending remote target. Never bypass fade/clear.
module wifi_request_steps #(parameter integer CLK_HZ=12288000)(
 input wire clk,rst_n,switching,system_fault,local_mode_event,local_timbre_event,
 input wire mode_valid,output wire mode_ready,input wire [1:0] mode_value,mode_requested,
 input wire timbre_valid,output wire timbre_ready,input wire [2:0] timbre_value,timbre_requested,
 output reg remote_mode_next,remote_timbre_next,output reg adapter_fault
);
 reg mode_active,timbre_active,mode_wait,timbre_wait;
 reg [1:0] mode_target,mode_previous;reg [2:0] timbre_target,timbre_previous;
 reg [31:0] mode_ticks,timbre_ticks;
 localparam [31:0] TIMEOUT=32'(CLK_HZ/5);
 wire available=!switching && !system_fault && !adapter_fault;
 assign mode_ready=available && !mode_active && !local_mode_event && mode_requested<=2;
 assign timbre_ready=available && !timbre_active && !local_timbre_event && timbre_requested<=4;
 initial if(CLK_HZ<100)$fatal(1,"steps clock");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  mode_active<=0;timbre_active<=0;mode_wait<=0;timbre_wait<=0;
  mode_target<=0;timbre_target<=0;mode_previous<=0;timbre_previous<=0;
  mode_ticks<=0;timbre_ticks<=0;remote_mode_next<=0;remote_timbre_next<=0;adapter_fault<=0;
 end else begin
  remote_mode_next<=0;remote_timbre_next<=0;
  if(mode_valid && mode_ready)begin mode_active<=1;mode_target<=mode_value;mode_wait<=0;mode_ticks<=0;end
  if(timbre_valid && timbre_ready)begin timbre_active<=1;timbre_target<=timbre_value;timbre_wait<=0;timbre_ticks<=0;end
  if(mode_active)begin
   if(mode_requested==mode_target)begin mode_active<=0;mode_wait<=0;end
   else if(mode_wait)begin
    if(mode_requested!=mode_previous)begin mode_wait<=0;mode_ticks<=0;end
    else if(mode_ticks>=TIMEOUT-1)begin adapter_fault<=1;mode_active<=0;end
    else mode_ticks<=mode_ticks+1'b1;
   end else begin remote_mode_next<=1;mode_previous<=mode_requested;mode_wait<=1;mode_ticks<=0;end
  end
  if(timbre_active)begin
   if(timbre_requested==timbre_target)begin timbre_active<=0;timbre_wait<=0;end
   else if(timbre_wait)begin
    if(timbre_requested!=timbre_previous)begin timbre_wait<=0;timbre_ticks<=0;end
    else if(timbre_ticks>=TIMEOUT-1)begin adapter_fault<=1;timbre_active<=0;end
    else timbre_ticks<=timbre_ticks+1'b1;
   end else begin remote_timbre_next<=1;timbre_previous<=timbre_requested;timbre_wait<=1;timbre_ticks<=0;end
  end
  if(local_mode_event || system_fault || adapter_fault)begin mode_active<=0;mode_wait<=0;remote_mode_next<=0;end
  if(local_timbre_event || system_fault || adapter_fault)begin timbre_active<=0;timbre_wait<=0;remote_timbre_next<=0;end
 end
endmodule
`default_nettype wire
