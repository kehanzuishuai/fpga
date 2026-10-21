`default_nettype none
// DVI 8b/10b TMDS video encoding (not generic IBM 8b/10b).
module old_tmds(input wire clk,rst_n,de,input wire [1:0] control,
 input wire [7:0] data,output reg [9:0] symbol);
 reg [8:0] q;
 integer k,ones,balance,disparity;
 reg use_xnor;
 always_comb begin
   ones=0;
   for(k=0;k<8;k=k+1) ones=ones+integer'(data[k]);
   use_xnor=(ones>4 || (ones==4 && !data[0]));
   q[0]=data[0];
   for(k=1;k<8;k=k+1) q[k]=q[k-1]^data[k]^use_xnor;
   q[8]=!use_xnor;
   ones=0;for(k=0;k<8;k=k+1)ones=ones+integer'(q[k]);
   balance=2*ones-8;
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n) begin symbol<=10'b1101010100;disparity<=0;end
 else if(!de) begin
   disparity<=0;
   case(control)
    0:symbol<=10'b1101010100;1:symbol<=10'b0010101011;
    2:symbol<=10'b0101010100;3:symbol<=10'b1010101011;
   endcase
 end else if(disparity==0 || balance==0) begin
   symbol<={~q[8],q[8],q[8]?q[7:0]:~q[7:0]};
   disparity<=disparity+(q[8]?balance:-balance);
 end else if((disparity>0 && balance>0)||(disparity<0 && balance<0)) begin
   symbol<={1'b1,q[8],~q[7:0]};
   disparity<=disparity+(q[8]?2:0)-balance;
 end else begin
   symbol<={1'b0,q[8],q[7:0]};
   disparity<=disparity+balance-(q[8]?0:2);
 end
endmodule
`default_nettype wire
