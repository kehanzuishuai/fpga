`default_nettype none
module polyphony_gain #(
  parameter int VOICES=32,parameter int SAMPLE_W=24,parameter int MASTER_ATTEN_SHIFT=0
) (
  input logic signed [SAMPLE_W+$clog2(VOICES)-1:0] mixed_in,
  input logic [$clog2(VOICES+1)-1:0] active_voice_count,
  output logic signed [SAMPLE_W+$clog2(VOICES)-1:0] scaled_out,
  output logic [5:0] applied_shift
);
  localparam int COUNT_W=$clog2(VOICES+1);
  localparam integer MASTER_SHIFT_INT=MASTER_ATTEN_SHIFT;
  localparam logic [5:0] MASTER_SHIFT=MASTER_SHIFT_INT[5:0];
  logic [5:0] voice_shift;
  function automatic [5:0] active_headroom(input logic [COUNT_W-1:0] count);
    integer count_value;
    begin
      count_value=0;count_value[COUNT_W-1:0]=count;
      if(count_value<=1)active_headroom=0;
      else if(count_value<=2)active_headroom=1;
      else if(count_value<=4)active_headroom=2;
      else if(count_value<=8)active_headroom=3;
      else if(count_value<=16)active_headroom=4;
      else active_headroom=5;
    end
  endfunction
  always @* begin
    voice_shift=active_headroom(active_voice_count);
    applied_shift=voice_shift+MASTER_SHIFT;
    scaled_out=mixed_in>>>applied_shift;
  end
endmodule
`default_nettype wire
