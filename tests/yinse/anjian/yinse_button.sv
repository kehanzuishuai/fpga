`default_nettype none
// One pulse after a stable press; release must also settle before rearming.
module yinse_button #(parameter integer DEBOUNCE_CYCLES=122880,
                      parameter bit ACTIVE_LOW=1)(
 input wire clk,rst_n,button,output reg pressed,output reg down
);
 localparam integer CW=(DEBOUNCE_CYCLES<2)?1:$clog2(DEBOUNCE_CYCLES);
 typedef logic [CW-1:0] count_t;
 reg meta,sync; reg [CW-1:0] count;
 wire raw_down=ACTIVE_LOW ? !sync : sync;
 initial if(DEBOUNCE_CYCLES<1)$fatal(1,"DEBOUNCE_CYCLES must be positive");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin meta<=ACTIVE_LOW;sync<=ACTIVE_LOW;end
 else begin meta<=button;sync<=meta;end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin count<=0;pressed<=0;down<=0;end
 else begin
  pressed<=0;
  if(raw_down==down)count<=0;
  else if(count==count_t'(DEBOUNCE_CYCLES-1))begin
   count<=0;down<=raw_down;pressed<=raw_down;
  end else count<=count+1'b1;
 end
endmodule
`default_nettype wire
