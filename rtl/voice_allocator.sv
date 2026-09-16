`default_nettype none
// Stateless selection helper. voice_bank owns actual voice state; allocator
// deterministically chooses a free entry, otherwise the smallest timestamp.
module voice_allocator #(
  parameter int VOICES=32, parameter int AGE_W=32
) (
  input logic request_valid,
  input logic [VOICES-1:0] active,
  input logic [VOICES*AGE_W-1:0] ages,
  output logic grant_valid, output logic [$clog2(VOICES)-1:0] grant_index,
  output logic steal, output logic [$clog2(VOICES)-1:0] note_off_index
);
  integer i;
  logic found_free;
  logic [AGE_W-1:0] oldest_age;
  always @* begin
    i=0; grant_valid=0; grant_index='0; note_off_index='0; steal=0; found_free=0; oldest_age={AGE_W{1'b1}};
    if(request_valid) begin
      for(i=0;i<VOICES;i=i+1) begin
        if(!active[i] && !found_free) begin grant_index=i[$clog2(VOICES)-1:0]; found_free=1; end
        if(!found_free && active[i] && ages[i*AGE_W +: AGE_W] < oldest_age) begin oldest_age=ages[i*AGE_W +: AGE_W]; grant_index=i[$clog2(VOICES)-1:0]; end
      end
      grant_valid=1; steal=!found_free;
    end
  end
  // Note matching is intentionally performed by voice_bank, where each
  // Voice's registered note is available.
endmodule
`default_nettype wire
