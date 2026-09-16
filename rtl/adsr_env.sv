`default_nettype none
module adsr_env #(
  parameter int ENV_W = 24,
  parameter logic [ENV_W-1:0] ATTACK_STEP  = 24'd349525,
  parameter logic [ENV_W-1:0] DECAY_STEP   = 24'd17476,
  parameter logic [ENV_W-1:0] SUSTAIN      = 24'd12582912,
  parameter logic [ENV_W-1:0] RELEASE_STEP = 24'd8738
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic gate_on, input logic gate_off,
  output logic [ENV_W-1:0] level, output logic active,
  output logic [1:0] stage
);
  localparam logic [1:0] OFF=0, ATTACK=1, DECAY=2, SUSTAIN_STAGE=3;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin level<='0; stage<=OFF; active<=0; end
    else if(gate_on) begin level<='0; stage<=ATTACK; active<=1; end
    else if(gate_off && active) stage<=OFF;
    else if(sample_tick) begin
      case(stage)
        ATTACK: if(level >= {ENV_W{1'b1}}-ATTACK_STEP) begin level<={ENV_W{1'b1}}; stage<=DECAY; end else level<=level+ATTACK_STEP;
        DECAY: if(level <= SUSTAIN+DECAY_STEP) begin level<=SUSTAIN; stage<=SUSTAIN_STAGE; end else level<=level-DECAY_STEP;
        SUSTAIN_STAGE: level<=SUSTAIN;
        default: if(active) begin if(level<=RELEASE_STEP) begin level<='0; active<=0; end else level<=level-RELEASE_STEP; end
      endcase
    end
  end
endmodule
`default_nettype wire
