`timescale 1ns/1ps
module tb_allocator;
  logic request_valid; logic [6:0] request_note; logic [3:0] active;
  logic [31:0] ages; logic grant_valid,steal; logic [1:0] grant_index,note_off_index;
  voice_allocator #(.VOICES(4),.AGE_W(8)) dut(.request_valid,.active,.ages,.grant_valid,.grant_index,.steal,.note_off_index);
  initial begin
    request_note=60; request_valid=1; active=4'b1011; ages={8'd9,8'd2,8'd7,8'd4}; #1;
    if(!grant_valid || steal || grant_index!=2) $fatal(1,"free-voice priority failed");
    active=4'b1111; #1; if(!steal || grant_index!=2) $fatal(1,"oldest-voice selection failed");
    $display("TB_ALLOCATOR PASS: free first, then lowest timestamp"); $finish;
  end
endmodule
