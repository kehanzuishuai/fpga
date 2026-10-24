module tb_kl_root;GSR GSR(.GSRI(1'b1));tb_keyboard_latency tb();
 integer accepted=0;
 // No delay: this wrapper has no timescale, a #delay here would be seconds.
 initial force tb.dut.u_remote.core.control.rec_enabled=1'b1;
 always @(posedge tb.dut.clk_12m288)if(tb.dut.u_remote.key_valid && tb.dut.u_remote.key_ready)accepted=accepted+1;
 final $display("REC accepted %0d wp %0d rp %0d overflow %0d",accepted,tb.dut.u_remote.core.control.rec_wp,tb.dut.u_remote.core.control.rec_rp,tb.dut.u_remote.core.control.rec_overflow);
endmodule
