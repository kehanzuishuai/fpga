"""Prepare common pane corner centers in the existing coordinate stage."""
def prepared_function():
 return ''' function automatic [12:0] round_pane_prepared(input signed [12:0] sx,sy,x0,y0,w,h,right_start,right_last,bottom_start,bottom_last);
 reg [5:0] dx,dy;begin
 dx=6'((sx < 13'sd28) ? (13'sd28-sx) : (sx>=right_start ? sx-right_last : 0));
 dy=6'((sy < 13'sd28) ? (13'sd28-sy) : (sy>=bottom_start ? sy-bottom_last : 0));
 round_pane_prepared={sx>=x0 && sx<x0+w && sy>=y0 && sy<y0+h,dx,dy};
 end endfunction
'''

def prepare_pane_geometry(source):
 if 'function automatic [12:0] round_pane_prepared' in source:return source
 marker=' } pixel_state;';assert source.count(marker)==1
 source=source.replace(marker,''' // All five concentric pane borders have the same corner centers.
  logic signed [12:0] pane_right_start,pane_right_last,pane_bottom_start,pane_bottom_last;
'''+marker)
 marker='d.pane_x=d.sx-d.px;d.pane_y=d.sy-d.py;';assert source.count(marker)==1
 source=source.replace(marker,marker+'''
d.pane_right_start=$signed({1'b0,d.pw})-13'sd28;
d.pane_right_last=$signed({1'b0,d.pw})-13'sd29;
d.pane_bottom_start=$signed({1'b0,d.ph})-13'sd28;
d.pane_bottom_last=$signed({1'b0,d.ph})-13'sd29;''')
 for offset,radius in [(0,28),(-7,35),(-4,32),(-2,30),(1,27)]:
  old=f'round_geometry(d.pane_x,d.pane_y,{offset},{offset},d.pw-({2*offset}),d.ph-({2*offset}),{radius})'
  assert source.count(old)==1,old
  new=f'round_pane_prepared(d.pane_x,d.pane_y,{offset},{offset},d.pw-({2*offset}),d.ph-({2*offset}),d.pane_right_start,d.pane_right_last,d.pane_bottom_start,d.pane_bottom_last)'
  source=source.replace(old,new)
 marker=' function automatic [12:0] round_geometry';assert source.count(marker)==1
 return source.replace(marker,prepared_function()+marker)
