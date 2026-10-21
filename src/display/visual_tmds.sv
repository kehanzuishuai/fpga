`default_nettype none
// DVI 8b/10b TMDS video encoding (not generic IBM 8b/10b).
module visual_tmds(input wire clk,rst_n,de,input wire [1:0] control,
 input wire [7:0] data,output reg [9:0] symbol);
 reg [8:0] q;
 integer k;
 // TMDS disparity is bounded to +/-8.32-bit integer add/compare chains
 // limited the old25MHz encoder to about35MHz after synthesis.
 reg signed [5:0] disparity;
 wire signed [5:0] balance=$signed({1'b0,pop8(q[7:0]),1'b0})-6'sd8;
 wire [3:0] ones=pop8(data);
 function automatic [3:0] pop8(input [7:0] value);
  reg [1:0] a,b,c,d;reg [2:0] ab,cd;
  begin
   a={1'b0,value[0]}+{1'b0,value[1]};b={1'b0,value[2]}+{1'b0,value[3]};
   c={1'b0,value[4]}+{1'b0,value[5]};d={1'b0,value[6]}+{1'b0,value[7]};
   ab={1'b0,a}+{1'b0,b};cd={1'b0,c}+{1'b0,d};pop8={1'b0,ab}+{1'b0,cd};
  end
 endfunction
 reg use_xnor;
 always_comb begin
   use_xnor=(ones>4 || (ones==4 && !data[0]));
   q[0]=data[0];
   for(k=1;k<8;k=k+1) q[k]=q[k-1]^data[k]^use_xnor;
   q[8]=!use_xnor;
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
   disparity<=disparity+(q[8]?6'sd2:6'sd0)-balance;
 end else begin
   symbol<={1'b0,q[8],q[7:0]};
   disparity<=disparity+balance-(q[8]?6'sd0:6'sd2);
 end
endmodule
`default_nettype wire
