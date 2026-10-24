"""Move bounded keyboard edge subtraction one existing clock earlier."""
from pathlib import Path
import shutil,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/key_lip'
A.mkdir(parents=True,exist_ok=True)
paths=['src/display/visual_scene.sv','tools/display_key_pipeline_20261021.py','tools/pipeline_display_scene_20261021.py']
for n in paths:
    b=A/'before'/n;b.parent.mkdir(parents=True,exist_ok=True)
    if not b.exists():shutil.copy2(R/n,b)
func=''' function automatic [7:0] min_key_edges(input [7:0] horizontal,top_edge,bottom_edge);
  reg [7:0] vertical;begin
   vertical=top_edge<bottom_edge?top_edge:bottom_edge;
   min_key_edges=horizontal<vertical?horizontal:vertical;
  end
 endfunction
'''
p=R/paths[0];s=p.read_text()
if 'min_key_edges' not in s:
    s=s.replace(' localparam PIPE_STAGES=',func+' localparam PIPE_STAGES=',1)
    s=s.replace('  logic signed [12:0] light;','  logic signed [12:0] light;\n  logic [7:0] key_top_edge,key_bottom_edge;',1)
    a=' d.light=d.key_x;if(92-d.key_x<d.light)d.light=92-d.key_x;'
    assert s.count(a)==1
    s=s.replace(a,a+"\n // work_hit guarantees 846<=sy<=1005: both distances fit unsigned8.\n d.key_top_edge=8'(d.sy)-8'd78;d.key_bottom_edge=8'd237-8'(d.sy);",1)
    a=' if(d.sy-846<d.light)d.light=d.sy-846;if(1005-d.sy<d.light)d.light=1005-d.sy;'
    assert s.count(a)==1
    s=s.replace(a,' d.light={5\'d0,min_key_edges(d.light[7:0],d.key_top_edge,d.key_bottom_edge)};',1)
    p.write_text(s)
p=R/paths[1];s=p.read_text()
if 'key_top_edge' not in s:
    s=s.replace(' light=key_x;if(92-key_x<light)light=92-key_x;'," light=key_x;if(92-key_x<light)light=92-key_x;\n key_top_edge=8'(sy)-8'd78;key_bottom_edge=8'd237-8'(sy);",1)
    a=' if(sy-846<light)light=sy-846;if(1005-sy<light)light=1005-sy;'
    assert s.count(a)==1
    s=s.replace(a," light={5'd0,min_key_edges(light[7:0],key_top_edge,key_bottom_edge)};",1)
    p.write_text(s)
p=R/paths[2];s=p.read_text()
if 'min_key_edges' not in s:
    marker='chunks=[]'
    assert s.count(marker)==1
    s=s.replace(marker,'functions+='+repr(func)+'\n'+marker,1)
    marker="group(7,'light_third,rim_green',False)"
    assert s.count(marker)==1
    s=s.replace(marker,marker+"\ngroup(8,'key_top_edge,key_bottom_edge',False)",1)
    p.write_text(s)
checks=0
for y in range(846,1006):
    for x in range(93):
        horizontal=min(x,92-x)
        old=min(horizontal,y-846,1005-y)
        top=((y&255)-78)&255;bottom=(237-(y&255))&255
        assert top==y-846 and bottom==1005-y
        assert old==min(horizontal,top,bottom)
        checks+=1
receipt=dict(status='APPLIED_PENDING_RTL_EQUIVALENCE_AND_SYNTHESIS',arithmetic_pairs=checks,pipeline_latency=40,
             scope='Existing stage21 computes two8-bit edge distances; existing stage22 compares them. work_hit geometry limits sy846..1005 and local key_x0..92. No added stage, changed colors, voice logic or features.',
             files={n:hashlib.sha256((R/n).read_bytes()).hexdigest() for n in paths})
(A/'CHANGE.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt,indent=2))
