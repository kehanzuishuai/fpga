"""Connect the user-approved guidance feature without changing web resources."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
def edit(name,old,new):
 p=R/name;s=p.read_text(encoding='utf-8');assert s.count(old)==1,(name,old,s.count(old));p.write_text(s.replace(old,new),encoding='utf-8')
shutil.copy2(Path('E:/xianshi(shengjiban)/src/visual_guide_controller.sv'),R/'src/display/visual_guide_controller.sv')

# Feature negotiation is opt-in: old standalone control wrappers retain rejection.
edit('src/remote/control/wifi_control.sv','module wifi_control #(parameter integer CLK_HZ=12288000,',
 'module wifi_control #(parameter integer PERFORMANCE_ENABLE=0,CLK_HZ=12288000,')
edit('src/remote/control/wifi_control.sv','input wire switching,system_fault,',
 'input wire switching,system_fault,\n input wire [1:0] actual_performance,input wire [2:0] performance_state,')
edit('src/remote/control/wifi_control.sv',"    8'h05:if(packet_len==0)",
 "    8'h06:if(packet_len==0 && PERFORMANCE_ENABLE!=0)reply(0,{8'd0,5'd0,performance_state,8'd1,6'd0,actual_performance});else reply(2,0);\n    8'h05:if(packet_len==0)")
edit('src/remote/control/wifi_control.sv',"8'h10,8'h11,8'h12,8'h13,8'h14,8'h15:begin", "8'h10,8'h11,8'h12,8'h13,8'h14,8'h15,8'h16:begin")
edit('src/remote/control/wifi_control.sv',"(packet_cmd==8'h15 && packet_len==1 && p0<=1))begin",
 "(packet_cmd==8'h15 && packet_len==1 && p0<=1) ||\n        (packet_cmd==8'h16 && PERFORMANCE_ENABLE!=0 && packet_len==1 && p0<=2))begin")
edit('src/remote/wifi_core.sv','module wifi_core #(parameter integer CLK_HZ=12288000,BAUD=115200,',
 'module wifi_core #(parameter integer PERFORMANCE_ENABLE=0,CLK_HZ=12288000,BAUD=115200,')
edit('src/remote/wifi_core.sv','input wire [1:0] actual_mode,input wire [2:0] actual_timbre,',
 'input wire [1:0] actual_mode,input wire [2:0] actual_timbre,\n input wire [1:0] actual_performance,input wire [2:0] performance_state,')
edit('src/remote/wifi_core.sv','wifi_control #(.DEFAULT_KEYS(DEFAULT_KEYS),',
 'wifi_control #(.PERFORMANCE_ENABLE(PERFORMANCE_ENABLE),.DEFAULT_KEYS(DEFAULT_KEYS),')
edit('src/remote/wifi_core.sv','.actual_mode(actual_mode),.actual_timbre(actual_timbre),',
 '.actual_mode(actual_mode),.actual_timbre(actual_timbre),\n  .actual_performance(actual_performance),.performance_state(performance_state),')

p=R/'src/remote/remote_control.sv';s=p.read_text()
s=s.replace('input wire [31:0] keys,input wire key_valid,key_on,', 'input wire [31:0] keys,input wire keys_valid,input wire key_valid,key_on,')
s=s.replace('output wire [6:0] display_score_note,output wire [15:0] display_score_completed',
 'output wire [6:0] display_score_note,output wire [15:0] display_score_completed,\n output reg [1:0] performance_mode,output wire [31:0] guide_targets,\n output wire [2:0] guide_state,output wire [15:0] guide_completed')
s=s.replace('wire [4:0] score_index;', 'wire [4:0] score_index,player_index;')
s=s.replace('wire source_safe=!score_owned', 'wire source_safe=!guide_running && !score_owned')
old="  (cfg_cmd==8'h15 && (!cfg_value[0] || (!switching && !score_playing && source_safe && score_count!=0)));"
assert old in s
s=s.replace(old,"  (cfg_cmd==8'h16 && cfg_value<=2 && !switching && source_safe) ||\n  (cfg_cmd==8'h15 && (!cfg_value[0] || (!switching && !score_playing && source_safe && score_count!=0 &&\n   (performance_mode!=2 || (preflight_ok && keys_valid)))));")
s=s.replace('wifi_core #(.DEFAULT_KEYS(DEFAULT_KEYS))', 'wifi_core #(.PERFORMANCE_ENABLE(1),.DEFAULT_KEYS(DEFAULT_KEYS))')
s=s.replace('.actual_mode(2\'d0),.actual_timbre(selected_instrument),',
 '.actual_mode(2\'d0),.actual_timbre(selected_instrument),\n  .actual_performance(performance_mode),.performance_state(guide_state),')
s=s.replace('.actual_volume(volume),.actual_tempo(tempo),.score_playing(score_playing),',
 '.actual_volume(volume),.actual_tempo(tempo),.score_playing(score_playing || guide_running),')
s=s.replace('.tables_safe(tables_safe && !switching && !score_owned),',
 '.tables_safe(tables_safe && !switching && !score_owned && !guide_running && !guide_request),')
s=s.replace('.score_count(score_count),.score_index(score_index),.score_event(score_event),\n  .playing(player_playing)',
 '.score_count(score_count),.score_index(player_index),.score_event(score_event),\n  .playing(player_playing)')
s=s.replace('instrument<=0;requested_instrument<=0;', 'performance_mode<=0;instrument<=0;requested_instrument<=0;')
s=s.replace("   8'h15:if(cfg_value[0])begin\n    score_owned<=1;", "   8'h16:performance_mode<=cfg_value[1:0];\n   8'h15:if(cfg_value[0] && performance_mode!=2)begin\n    performance_mode<=1;score_owned<=1;")
# No existing score session exists during guidance. Play/stop control below is
# independent of engine reset and leaves physical piano events flowing.
k=s.index(' always @(posedge clk or negedge rst_n)')
guide=''' // Guidance reads the committed score RAM, never a second unsynchronized copy.
 reg guide_running,guide_start;
 reg [4:0] guide_index,scan_index;
 reg guide_sent,preflight_active,preflight_ok,preflight_bad;
 reg [31:0] guide_phase;
 wire [31:0] guide_advance=guide_phase+32'(tempo)*32'd1000;
 wire guide_ms=sample_tick && guide_advance>=32'd5760000;
 wire guide_request=cfg_valid && cfg_cmd==8'h15 && cfg_value[0] && performance_mode==2;
 wire guide_launch=guide_request && cfg_ready;
 wire guide_stop=play_stop || performance_mode!=2;
 wire guide_event_ready,guide_step,guide_finished;
 reg [31:0] mapped_target;integer target_i;
 always @* begin
  mapped_target=0;
  for(target_i=0;target_i<32;target_i=target_i+1)
   if(key_map[target_i*7+:7]==score_event[6:0])mapped_target[target_i]=1;
 end
 assign score_index=performance_mode==2?(preflight_active?scan_index:guide_index):player_index;
 visual_guide_controller guide(
  .clk(clk),.rst_n(rst_n),.enable(performance_mode==2),.start(guide_start),.stop(guide_stop),
  .paused(1'b0),.tick_ms(guide_ms),.keys_valid(keys_valid),.keys(keys),
  .event_valid(guide_running && !guide_sent && !guide_start &&
   (score_event[14:8]==0 || mapped_target!=0)),.event_ready(guide_event_ready),
  .event_keys(score_event[14:8]==0?32'd0:mapped_target),.event_rest_ms(score_event[31:16]),
  .event_last({1'b0,guide_index}+6'd1>=score_count),
  .target_keys(guide_targets),.display_state(guide_state),.completed(guide_completed),
  .step_done(guide_step),.finished(guide_finished));
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  guide_running<=0;guide_start<=0;guide_index<=0;guide_sent<=0;guide_phase<=0;
  scan_index<=0;preflight_active<=0;preflight_ok<=0;preflight_bad<=0;
 end else begin
  guide_start<=0;
  if(!guide_request)begin preflight_active<=0;preflight_ok<=0;preflight_bad<=0;scan_index<=0;end
  else if(source_safe && !switching && keys_valid && score_count!=0)begin
   if(!preflight_active && !preflight_ok && !preflight_bad)begin preflight_active<=1;scan_index<=0;end
   else if(preflight_active)begin
    if(score_event[14:8]!=0 && mapped_target==0)begin preflight_active<=0;preflight_bad<=1;end
    else if({1'b0,scan_index}+6'd1>=score_count)begin preflight_active<=0;preflight_ok<=1;end
    else scan_index<=scan_index+1'b1;
   end
  end
  if(guide_launch)begin guide_running<=1;guide_start<=1;guide_index<=0;guide_sent<=0;guide_phase<=0;end
  else if(guide_stop || guide_finished)begin guide_running<=0;guide_sent<=0;guide_phase<=0;end
  else if(guide_running)begin
   if(sample_tick)guide_phase<=guide_ms?guide_advance-32'd5760000:guide_advance;
   if(guide_event_ready && !guide_sent && !guide_start)guide_sent<=1;
   if(guide_step && {1'b0,guide_index}+6'd1<score_count)begin guide_index<=guide_index+1'b1;guide_sent<=0;guide_phase<=0;end
  end
 end
'''
s=s[:k]+guide+s[k:]
p.write_text(s,encoding='utf-8')

edit('src/tang_mega_138k_pro_top.v.v','wire [6:0] display_score_note;wire [15:0] display_score_completed;',
 'wire [6:0] display_score_note;wire [15:0] display_score_completed;\nwire [1:0] performance_mode;wire [31:0] guide_targets;wire [2:0] guide_state;wire [15:0] guide_completed;')
edit('src/tang_mega_138k_pro_top.v.v','.uart_rx(esp_uart_rx),.uart_tx(esp_uart_tx),.keys(key_state32),',
 '.uart_rx(esp_uart_rx),.uart_tx(esp_uart_tx),.keys(key_state32),.keys_valid(&key_bank_mode16),')
edit('src/tang_mega_138k_pro_top.v.v','.display_score_note(display_score_note),.display_score_completed(display_score_completed));',
 '.display_score_note(display_score_note),.display_score_completed(display_score_completed),\n .performance_mode(performance_mode),.guide_targets(guide_targets),.guide_state(guide_state),.guide_completed(guide_completed));')
edit('src/tang_mega_138k_pro_top.v.v','.score_rest(display_score_rest),.score_note(display_score_note),.score_completed(display_score_completed),',
 '.score_rest(display_score_rest),.score_note(display_score_note),.score_completed(display_score_completed),\n .performance_mode(performance_mode),.guide_targets(guide_targets),.guide_state(guide_state),.guide_completed(guide_completed),')
edit('src/display/display_status_adapter.sv','input wire [6:0] score_note,input wire [15:0] score_completed,',
 'input wire [6:0] score_note,input wire [15:0] score_completed,\n input wire [1:0] performance_mode,input wire [31:0] guide_targets,\n input wire [2:0] guide_state,input wire [15:0] guide_completed,')
edit('src/display/display_status_adapter.sv',"status_data[457:456]=score_owned?2'd1:2'd0;", 'status_data[457:456]=performance_mode;')
edit('src/display/display_status_adapter.sv','status_data[508:493]=score_owned?score_completed:16\'d0;',
 '''status_data[508:493]=score_owned?score_completed:16'd0;
  if(performance_mode==2)begin
   status_data[489:458]=guide_targets;status_data[492:490]=guide_state;
   status_data[508:493]=guide_completed;
  end''')
edit('yinyue_fashengqi.gprj','    </FileList>',
 '        <File path="src/display/visual_guide_controller.sv" type="file.verilog" enable="1"/>\n    </FileList>')
print('Guidance RTL connected; same physical piano, committed mapping and score RAM.')
