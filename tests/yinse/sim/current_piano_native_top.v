// Audit wrapper only. All piano modules are original src files.
module current_piano_native_top(input clk,rst_n,sample_tick,note_on,note_off,
 input [6:0] midi_note,input [7:0] velocity,
 output event_ready,output [31:0] active,overruns,
 output [5:0] count,output signed [23:0] pcm);
 synth_core dut(.clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),
 .note_on(note_on),.note_off(note_off),.midi_note(midi_note),.velocity(velocity),
 .waveform(2'b00),.morph_enable(1'b0),.morph(10'd0),.test_enable(1'b0),
 .hammer_enable(1'b1),.fx_ctrl(5'b10011),.event_ready(event_ready),
 .active_debug(active),.active_voice_count(count),.audio_out(pcm));
 genvar g;generate for(g=0;g<32;g=g+1)begin : G_MONITOR
 assign overruns[g]=dut.u_bank.G_PARTIAL.G_VOICE[g].u_voice.dbg_overrun;
 end endgenerate
endmodule
