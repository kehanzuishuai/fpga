`default_nettype none
module tl_link_guard #(parameter integer CLK_HZ=12288000,TIMEOUT_MS=100,RECOVERY_FRAMES=3)(
 input wire clk,rst_n,packet_valid,input wire [7:0] sequence_id,flags,
 input wire [31:0] frequency_mhz,input wire [15:0] amplitude,
 output reg update,linked,calibrating,sensor_fault,
 output reg [31:0] frequency_out,output reg [15:0] amplitude_out
);
 reg have_sequence;reg [7:0] previous;reg [31:0] age;reg [7:0] good;
 localparam [31:0] LAST=32'((CLK_HZ/1000)*TIMEOUT_MS-1);
 wire [7:0] distance=sequence_id-previous;
 // While recovering, any changed sequence may start a new candidate stream;
 // three consecutive frames are still needed. This permits sender reboot.
 wire fresh=!have_sequence || (distance!=0 && (!linked || !distance[7]));
 wire usable=flags==8'h0b && frequency_mhz>=20000 && frequency_mhz<=4000000;
 initial if(CLK_HZ<1000 || TIMEOUT_MS<1 || RECOVERY_FRAMES<1 || RECOVERY_FRAMES>255)$fatal(1,"link parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  have_sequence<=0;previous<=0;age<=0;good<=0;update<=0;linked<=0;
  calibrating<=0;sensor_fault<=0;frequency_out<=440000;amplitude_out<=0;
 end else begin
  update<=0;
  if(age!=LAST)age<=age+1'b1;
  else begin linked<=0;good<=0;have_sequence<=0;amplitude_out<=0;calibrating<=0;sensor_fault<=0;end
  if(packet_valid && fresh)begin
   age<=0;have_sequence<=1;previous<=sequence_id;
   calibrating<=flags[2];sensor_fault<=flags[4];
   if(!usable)begin linked<=0;good<=0;amplitude_out<=0;end
   else begin
    if(!have_sequence || distance!=1)good<=1;
    else if(good<8'(RECOVERY_FRAMES))good<=good+1'b1;
    if(linked || RECOVERY_FRAMES==1 || (have_sequence && distance==1 && good>=8'(RECOVERY_FRAMES-1)))begin
     linked<=1;update<=1;frequency_out<=frequency_mhz;amplitude_out<=amplitude;
    end
   end
  end
 end
endmodule
`default_nettype wire
