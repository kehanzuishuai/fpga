from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out';O.mkdir(exist_ok=True)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
prefix=(R/'tests/remote_music_20261019/tb_control.sv').read_text().split(' integer old_on,old_off,n;')[0]
prefix=prefix.replace('module tb_control;','module tb_guidance;')
a=prefix.index(' remote_control dut(');b=prefix.index(' wire got',a)
prefix=prefix[:a]+''' wire [1:0] perf;wire [31:0] target;wire [2:0] gs;wire [15:0] done;
 remote_control dut(.clk(clk),.rst_n(rst_n),.sample_tick(tick),.uart_rx(rx),.uart_tx(tx),
 .keys(keys),.keys_valid(1'b1),.key_valid(kv),.key_on(ko),.key_index(ki),.key_velocity(vel),.key_waveform(kw),
 .key_ready(kr),.bridge_reset_n(brst),.event_valid(ev),.event_on(eo),.event_note(en),.event_velocity(v),.event_waveform(ew),
 .event_ready(er),.engine_idle(1'b1),.fifo_level(5'd0),.instrument(instrument),.switching(switching),.engine_clear(clear),
 .volume(volume),.effects(fx),.score_playing(playing),.mapped_key_note(mapped),.key_map(key_map),.synth_gain(gain),
 .performance_mode(perf),.guide_targets(target),.guide_state(gs),.guide_completed(done));
''' +prefix[b:]
body='''
 integer n,old_on;
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
  request(8'h06,0,0,0);if(reply[8]!=0 || reply[9]!=1)$fatal(1,"performance capability");
  request(8'h11,1,2,0);if(instrument!=0)$fatal(1,"physical piano retimbred");
  request(8'h30,1,4,0);
  request(8'h31,5,{8'd0,16'd100,8'd100,8'd60,8'd0},0);
  request(8'h31,5,{8'd0,16'd100,8'd100,8'd60,8'd1},0);
  request(8'h31,5,{8'd0,16'd10,8'd0,8'd0,8'd2},0);
  request(8'h31,5,{8'd0,16'd100,8'd100,8'd91,8'd3},0);
  request(8'h32,0,0,0);request(8'h16,1,2,0);
  request(8'h06,0,0,0);if(reply[8]!=2)$fatal(1,"actual performance readback");
  old_on=on_count;request(8'h15,1,1,0);
  if(gs!=2 || target!=1 || done!=0 || instrument!=0 || on_count!=old_on)$fatal(1,"guide didn't wait silently");
  request(8'h04,0,0,0);if(reply[9]!=1)$fatal(1,"guide not reported running");
  keys=2;repeat(40)@(negedge clk);if(done!=0)$fatal(1,"wrong key advanced");
  keys=3;repeat(40)@(negedge clk);if(done!=0)$fatal(1,"extra key advanced");
  keys=1;repeat(40)@(negedge clk);if(done!=1 || gs!=3 || instrument!=0)$fatal(1,"correct physical piano key");
  repeat(500)@(negedge clk);if(done!=1)$fatal(1,"held key repeats");
  keys=0;wait(gs==2);@(negedge clk);if(target!=1)$fatal(1,"repeated note target");
  keys=1;repeat(40)@(negedge clk);if(done!=2)$fatal(1,"repeated note not accepted");
  keys=0;wait(gs==6);repeat(200)@(negedge clk);
  keys=2;repeat(70)@(negedge clk);if(gs!=6 || done!=2)$fatal(1,"interrupted rest advanced");
  keys=0;n=0;
  while(gs==6)begin @(posedge clk);if(tick)n=n+1;@(negedge clk);end
  if(n<480 || n>481)$fatal(1,"interrupted rest not fully reset: %0d ticks",n);
  wait(gs==2 && target==32'h80000000);
  if(done!=3)$fatal(1,"rest didn't count");
  keys=1;repeat(40)@(negedge clk);if(done!=3)$fatal(1,"wrong board advanced");
  keys=32'h80000000;repeat(40)@(negedge clk);if(done!=4 || gs!=3)$fatal(1,"bank2 last key");
  keys=0;wait(gs==5);repeat(30)@(negedge clk);
  request(8'h04,0,0,0);if(reply[9]!=0)$fatal(1,"guide didn't finish");
  request(8'h15,1,1,0);if(gs!=2 || done!=0)$fatal(1,"finished guide cannot restart");
  request(8'h15,1,0,0);if(gs!=0 || target!=0)$fatal(1,"stop leaves target");
  request(8'h30,1,1,0);request(8'h31,5,{8'd0,16'd100,8'd100,8'd36,8'd0},0);request(8'h32,0,0,0);
  request(8'h15,1,1,3);if(gs!=0 || dut.guide_running)$fatal(1,"unmapped note started guidance");
  request(8'h20,0,0,0);
  for(n=0;n<32;n=n+1)request(8'h21,2,{32'd0,8'(n==0?36:60+n),8'(n)},0);
  request(8'h22,0,0,0);request(8'h15,1,1,0);
  if(gs!=2 || target!=1)$fatal(1,"guidance ignored applied mapping");
  keys=1;repeat(40)@(negedge clk);if(done!=1 || last_note!=36 || instrument!=0)$fatal(1,"remapped physical note/target mismatch");
  keys=0;wait(gs==5);repeat(30)@(negedge clk);
  request(8'h16,1,0,0);if(perf!=0)$fatal(1,"return to free");
  request(8'h30,1,1,0);request(8'h31,5,{8'd0,16'd3000,8'd100,8'd64,8'd0},0);request(8'h32,0,0,0);
  old_on=on_count;request(8'h15,1,1,0);wait(on_count==old_on+1);
  if(perf!=1 || !playing || instrument!=2 || last_note!=64)$fatal(1,"legacy automatic score lost after guidance");
  keys=2;repeat(40)@(negedge clk);if(on_count!=old_on+1)$fatal(1,"physical keys interrupted automatic score");
  keys=0;request(8'h15,1,0,0);wait(!playing && !switching);
  if(instrument!=0)$fatal(1,"automatic stop failed to restore piano");
  $display("PASS actual UART guidance: capability/readback, score ownership, wrong/extra/repeated keys, rest, bank2, finish/restart/stop, unmapped rejection and atomic remap; physical piano retained");$finish;
 end
 initial begin #500000000;$fatal(1,"guidance timeout");end
endmodule
'''
(O/'tb_guidance.sv').write_text(prefix+body)
src=[*sorted((R/'src/remote/uart').glob('*.sv')),R/'src/remote/wifi_core.sv',R/'src/remote/control/wifi_control.sv',
 R/'src/remote/control/wifi_score_player.sv',R/'src/remote/remote_control.sv',R/'src/ttp229_event_bridge.v',R/'src/display/visual_guide_controller.sv']
for name,args in [('guidance_compile',[iv,'-g2012','-s','tb_guidance','-o',O/'guidance.vvp',O/'tb_guidance.sv',*src]),
                  ('guidance',[iv.with_name('vvp.exe'),O/'guidance.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1600:],flush=True)
