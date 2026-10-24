"""Delay the complete compositor descriptor by the exact scene latency."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1];A=R/'audit/display_integration_20261021/timing_repair'
p=R/'src/display/visual_renderer.sv';b=A/'visual_renderer.before_scene_pipeline.sv'
if not b.exists():b.write_bytes(p.read_bytes())
s=b.read_text();latency=int(re.search(r'localparam PIPE_STAGES=(\d+)',(R/'src/display/visual_scene.sv').read_text())[1])
s=s.replace('module visual_renderer #','(* syn_srlstyle="distributed_ram" *)\nmodule visual_renderer #')
s=s.replace('key_trails,sharp_rgb,frost_rgb);','key_trails,sharp_rgb,frost_rgb,clk);')
s=s.replace('visual_scene scene(', 'visual_scene #(.BACKGROUND_LATENCY(4)) scene(')
from display_wave_pipeline_20261021 import pipeline_wave
s=pipeline_wave(s,R)
from display_spectrum_pipeline_20261021 import pipeline_spectrum
s=pipeline_spectrum(s)
fields={'draw_x':('x','[11:0]'),'draw_y':('y','[11:0]'),'draw_de':('de',''),'draw_hs':('hs',''),'draw_vs':('vs',''),
 'wave_min':('wave_min','[11:0]'),'wave_max':('wave_max','[11:0]'),'env_y':('env_y','[11:0]'),
 'spectrum_sample':('spectrum_sample','[7:0]'),'wave_initialized':('wave_initialized',''),'initialized':('initialized',''),
 'phase_left':('phase_left',''),'phase_aligned':('phase_aligned',''),'phase_vertical':('phase_vertical',''),
 'xy_signal':('xy_signal',''),'xy_direct':('xy_direct',''),'xy_mixed':('xy_mixed',''),'xy_shift':('xy_shift','signed [5:0]'),
 'status_live':('status_live',''),'status_data':('status_data','[511:0]'),
 'spectrum_range':('spectrum_range','[1:0]'),'peak_hz':('peak_hz','[15:0]'),'peak_valid':('peak_valid','')}
descriptor=f' localparam SCENE_LATENCY={latency};\n typedef struct packed {{\n'
descriptor+=''.join(f'  logic {w} {n};\n' for n,w in fields.values())+'  logic plot_grid,spectrum_bar;\n  logic [4:0] plot_flags;\n  logic [23:0] spectrum_color;\n } pixel_info;\n'
descriptor+=' pixel_info input_info,aligned;\n pixel_info info_pipe[0:SCENE_LATENCY-1];\n integer delay_pixel;\n'
descriptor+=" always @* begin\n  input_info='0;\n"+''.join(f'  input_info.{n}={src};\n' for src,(n,_) in fields.items())+' end\n'
descriptor+=''' pixel_info spectrum_ready,waveform_ready;
 always @* begin spectrum_ready=info_pipe[1];spectrum_ready.spectrum_sample=spectrum_sample;end
 always @* begin waveform_ready=info_pipe[5];waveform_ready.wave_min=wave_min;waveform_ready.wave_max=wave_max;end
 always @(posedge clk)begin
  info_pipe[0]<=input_info;
  for(delay_pixel=1;delay_pixel<SCENE_LATENCY;delay_pixel=delay_pixel+1)
   if(delay_pixel==2)info_pipe[delay_pixel]<=spectrum_ready;else if(delay_pixel==5)info_pipe[delay_pixel]<=waveform_ready;else info_pipe[delay_pixel]<=info_pipe[delay_pixel-1];
 end
 assign aligned=info_pipe[SCENE_LATENCY-1];
 reg [SCENE_LATENCY-1:0] info_valid;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)info_valid<=0;else info_valid<={info_valid[SCENE_LATENCY-2:0],1'b1};
'''
start=s.index(' visual_labels #');end=s.index(' // The exact font ROM',start)
labels=s[start:end]
label_source=(R/'src/display/visual_labels.sv').read_text()
label_latency=int(re.search(r'localparam LABEL_LATENCY=(\d+)',label_source)[1]) if 'localparam LABEL_LATENCY=' in label_source else 1
assert latency+1>=label_latency
labels=labels.replace('(label_ink)','(raw_label_ink)').replace('(label_color)','(raw_label_color)').replace('(label_coverage)','(raw_label_coverage)')
labels=''' wire raw_label_ink;wire [23:0] raw_label_color;wire [1:0] raw_label_coverage;
'''+labels
delay=latency+1-label_latency
if delay:
 labels+=f''' // Labels start at the raw pixel; align their exact {label_latency}-clock result
 // to the scene and one-clock base-image register.
 reg [26:0] label_pipe[0:{delay-1}];integer delay_label;
 always @(posedge clk)begin
  label_pipe[0]<={{raw_label_ink,raw_label_color,raw_label_coverage}};
  for(delay_label=1;delay_label<{delay};delay_label=delay_label+1)label_pipe[delay_label]<=label_pipe[delay_label-1];
 end
 assign {{label_ink,label_color,label_coverage}}=label_pipe[{delay-1}];
'''
else:labels+=' assign {label_ink,label_color,label_coverage}={raw_label_ink,raw_label_color,raw_label_coverage};\n'
s=s[:start]+descriptor+labels+s[end:]
start=s.index('  base_out_de<=draw_de;')
end=s.index(' initial if(LOGN',start)
body=s[start:end]
body=re.sub(r'\b('+ '|'.join(fields)+r')\b',lambda m:'aligned.'+fields[m[0]][0],body)
body=body.replace('base_out_de<=aligned.de;','base_out_de<=aligned.de && info_valid[SCENE_LATENCY-1];')
body=body.replace('if(aligned.de)begin','if(aligned.de && info_valid[SCENE_LATENCY-1])begin')
s=s[:start]+body+s[end:]
s=s.replace('// The exact font ROM adds one cycle.','// The scene and descriptor arrive together; the exact font ROM adds one cycle.')
from display_overlay_pipeline_20261021 import pipeline_overlay
s=pipeline_overlay(s)
from display_plot_flags_20261021 import pipeline_plot_flags
s=pipeline_plot_flags(s)
s=s.replace('output reg [7:0] red,green,blue','output wire [7:0] red,green,blue')
rgb_boundary=''' // Keep the intended renderer/encoder boundary during whole-project mapping.
 (* syn_preserve=1,syn_keep=1 *) reg [7:0] rgb_red,rgb_green,rgb_blue;
 assign red=rgb_red;assign green=rgb_green;assign blue=rgb_blue;
'''
at=s.index(' reg signed [15:0] wave')
s=s[:at]+rgb_boundary+s[at:]
s=re.sub(r'\b(red|green|blue)(?=\s*<=)',lambda m:'rgb_'+m[0],s)
s=s.replace('{red,green,blue}<=','{rgb_red,rgb_green,rgb_blue}<=')
# Compute the weighted text sums at the existing base-image register.  The
# penultimate label delay and scene_color describe that same pixel, so this
# splits the measured text path without adding any pixel latency.
blend_start=s.index(' function automatic [23:0] text_blend(')
blend_end=s.index(' endfunction',blend_start)+len(' endfunction')
s=s[:blend_start]+''' function automatic [9:0] text_weighted_sum(input [7:0] bg,fg,input [1:0] coverage);
  reg [9:0] b,f;begin
   b={2'b0,bg};f={2'b0,fg};
   case(coverage)
    0:text_weighted_sum=b+(b<<1)+10'd1;
    1:text_weighted_sum=(b<<1)+f+10'd1;
    2:text_weighted_sum=b+(f<<1)+10'd1;
    3:text_weighted_sum=f+(f<<1)+10'd1;
   endcase
  end
 endfunction
 function automatic [7:0] text_divide_three(input [9:0] rounded_sum);
  reg [19:0] product;begin
   // ceil(2^11/3)=683 gives the exact quotient for every sum in 0..766.
   product={10'd0,rounded_sum}*20'd683;text_divide_three=product[18:11];
  end
 endfunction'''+s[blend_end:]
assert delay>=2,'Text preparation requires one spare label alignment clock'
early=f'label_pipe[{delay-2}]'
assert all((n*683>>11)==n//3 for n in range(767)), 'Text divide-by-three must be exact'
s=s.replace(' reg [23:0] text_scene_q;',f''' wire [23:0] early_label_color={early}[25:2];
 wire [1:0] early_label_coverage={early}[1:0];
 (* syn_preserve=1 *) reg [9:0] text_r_sum,text_g_sum,text_b_sum;''')
s=s.replace('text_scene_q<=0;','text_r_sum<=0;text_g_sum<=0;text_b_sum<=0;')
s=s.replace('  text_scene_q<=scene_color;','''  text_r_sum<=text_weighted_sum(scene_color[23:16],early_label_color[23:16],early_label_coverage);
  text_g_sum<=text_weighted_sum(scene_color[15:8],early_label_color[15:8],early_label_coverage);
  text_b_sum<=text_weighted_sum(scene_color[7:0],early_label_color[7:0],early_label_coverage);''')
s=s.replace('text_blend(text_scene_q,label_color,label_coverage)',
 '{text_divide_three(text_r_sum),text_divide_three(text_g_sum),text_divide_three(text_b_sum)}')
from display_prefix_bits_20261023 import prefix_renderer
s=prefix_renderer(s)
from display_routed_fixes_20261023 import renderer_fixes
s=renderer_fixes(s)
from display_mod7_gap_20261023 import shorten_mod7
s=shorten_mod7(s)
p.write_text(s)
print('Aligned scene, labels, overlays and timing by',latency,'pixel clocks')
