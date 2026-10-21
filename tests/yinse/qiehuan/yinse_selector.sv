`default_nettype none
module yinse_selector(input wire clk,rst_n,next_pulse,previous_pulse,
 output reg [2:0] requested_id);
 always @(posedge clk or negedge rst_n)
 if(!rst_n)requested_id<=0;
 else if(next_pulse && !previous_pulse)requested_id<=(requested_id==4)?3'd0:requested_id+1'b1;
 else if(previous_pulse && !next_pulse)requested_id<=(requested_id==0)?3'd4:requested_id-1'b1;
endmodule
`default_nettype wire
