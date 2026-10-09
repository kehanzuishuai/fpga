`timescale 1ns/1ps
// Test-only receiver at the final10-bit word boundary, BEFORE OSER10.
// Independent inverse coding, control detection and end-to-end pixel matching.
module tmds_stream_checker #(parameter FATAL_ON_ERROR=1)(
 input clk,rst_n,source_de,source_hs,source_vs,
 input [7:0] source_r,source_g,source_b,
 input [9:0] red_word,green_word,blue_word,
 output reg rx_de,output reg [7:0] rx_r,rx_g,rx_b,
 output integer pixels,blank_pixels,errors
);
 function automatic bit control_word(input [9:0] s);
 begin control_word=(s==10'b1101010100 || s==10'b0010101011 ||
 s==10'b0101010100 || s==10'b1010101011);end endfunction
 function automatic [1:0] decode_control(input [9:0] s);
 begin case(s)
 10'b1101010100:decode_control=0;10'b0010101011:decode_control=1;
 10'b0101010100:decode_control=2;10'b1010101011:decode_control=3;
 default:decode_control=2'bxx;endcase end endfunction
 function automatic [7:0] decode_data(input [9:0] s);
 reg [7:0] q;integer j;
 begin q=s[7:0]^{8{s[9]}};decode_data[0]=q[0];
 for(j=1;j<8;j=j+1)decode_data[j]=q[j]^q[j-1]^!s[8];end endfunction
 function automatic integer balance(input [9:0] s);
 integer j,n;begin n=0;for(j=0;j<10;j=j+1)n=n+integer'(s[j]);balance=2*n-10;end endfunction
 integer rd_r=0,rd_g=0,rd_b=0;
 reg exp_de,exp_hs,exp_vs;reg [23:0] exp_rgb;reg bad,bc,gc,rc;
 initial begin pixels=0;blank_pixels=0;errors=0;rx_de=0;rx_r=0;rx_g=0;rx_b=0;end
 always @(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
     pixels=0;blank_pixels=0;errors=0;rd_r=0;rd_g=0;rd_b=0;
     rx_de=0;rx_r=0;rx_g=0;rx_b=0;
   end else begin
     // Encoder consumes the pre-edge renderer output, not post-edge pixels.
     exp_de=source_de;exp_hs=source_hs;exp_vs=source_vs;
     exp_rgb={source_r,source_g,source_b};
     #1;
     if(rst_n)begin
       bc=control_word(blue_word);gc=control_word(green_word);rc=control_word(red_word);
       bad=((^{red_word,green_word,blue_word})===1'bx);
       rx_de=!(bc || gc || rc);
       if(rx_de!==exp_de)bad=1;
       if(rx_de)begin
         rx_r=decode_data(red_word);rx_g=decode_data(green_word);rx_b=decode_data(blue_word);
         if({rx_r,rx_g,rx_b}!==exp_rgb)bad=1;
         pixels=pixels+1;
         rd_r=rd_r+balance(red_word);rd_g=rd_g+balance(green_word);rd_b=rd_b+balance(blue_word);
         if(rd_r>8 || rd_r< -8 || rd_g>8 || rd_g< -8 || rd_b>8 || rd_b< -8)bad=1;
       end else begin
         rx_r=0;rx_g=0;rx_b=0;blank_pixels=blank_pixels+1;
         if(!(bc && gc && rc) || decode_control(blue_word)!=={exp_vs,exp_hs} ||
            green_word!==10'b1101010100 || red_word!==10'b1101010100)bad=1;
         rd_r=0;rd_g=0;rd_b=0;
       end
       if(bad)begin errors=errors+1;
         if(FATAL_ON_ERROR)$fatal(1,"final TMDS pixel/control/disparity mismatch");
       end
     end
   end
 end
endmodule
