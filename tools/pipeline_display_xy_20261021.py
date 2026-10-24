"""Pipeline XY normalization and separate Bresenham setup, preserving pixels."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];A=R/'audit/display_integration_20261021/timing_repair'
p=R/'src/display/visual_xy_plot.sv';b=A/'visual_xy_plot.before_pipeline.sv'
if not b.exists():b.write_bytes(p.read_bytes())
s=b.read_text().replace('localparam [3:0] IDLE','localparam [4:0] IDLE').replace('DRAW_LINE=8,HOLD=9;','DRAW_LINE=8,HOLD=9,SET_ERROR=10;').replace('reg [3:0] state;','reg [4:0] state;reg [2:0] map_wait;')
a=s.index(' wire [COORD_BITS-1:0] mapped_x=');z=s.index(' assign busy=',a)
s=s[:a]+''' // The magnitude is clamped before an exact reciprocal division by 63.
 // For 0<=n<=LIMIT, ceil(2^SHIFT/63) has error strictly below 1/63.
 localparam LIMIT=(SPAN/2-1)*63,MAG_BITS=$clog2(LIMIT+1);
 localparam RECIP_SHIFT=$clog2(LIMIT*62+1),RECIP=((1<<RECIP_SHIFT)+62)/63;
 localparam RECIP_BITS=$clog2(RECIP+1),PRODUCT_BITS=MAG_BITS+RECIP_BITS;
 reg signed [16:0] centered_x_q,centered_y_q;
 reg signed [31:0] product_x,product_y,shifted_x,shifted_y;
 reg [MAG_BITS-1:0] magnitude_x,magnitude_y;
 reg negative_x,negative_y,quotient_negative_x,quotient_negative_y;
 reg [PRODUCT_BITS-1:0] reciprocal_x,reciprocal_y;
 wire [COORD_BITS-1:0] quotient_x=COORD_BITS'(reciprocal_x>>RECIP_SHIFT);
 wire [COORD_BITS-1:0] quotient_y=COORD_BITS'(reciprocal_y>>RECIP_SHIFT);
 reg [COORD_BITS-1:0] mapped_x,mapped_y;
 always @(posedge clk)begin
  centered_x_q<=centered_x;centered_y_q<=centered_y;
  product_x<=32'($signed(centered_x_q))*32'(SPAN/2-1);
  product_y<=32'($signed(centered_y_q))*32'(SPAN/2-1);
  shifted_x<=ready_shift>=0?product_x>>>ready_shift:product_x<<<(-ready_shift);
  shifted_y<=ready_shift>=0?product_y>>>ready_shift:product_y<<<(-ready_shift);
  magnitude_x<=(shifted_x>LIMIT || shifted_x< -LIMIT)?MAG_BITS'(LIMIT):MAG_BITS'(shifted_x<0?-shifted_x:shifted_x);
  magnitude_y<=(shifted_y>LIMIT || shifted_y< -LIMIT)?MAG_BITS'(LIMIT):MAG_BITS'(shifted_y<0?-shifted_y:shifted_y);
  negative_x<=shifted_x[31];negative_y<=shifted_y[31];
  reciprocal_x<=PRODUCT_BITS'(magnitude_x)*PRODUCT_BITS'(RECIP);
  reciprocal_y<=PRODUCT_BITS'(magnitude_y)*PRODUCT_BITS'(RECIP);
  quotient_negative_x<=negative_x;quotient_negative_y<=negative_y;
  mapped_x<=quotient_negative_x?COORD_BITS'(SPAN/2)-quotient_x:COORD_BITS'(SPAN/2)+quotient_x;
  mapped_y<=quotient_negative_y?COORD_BITS'(SPAN/2)+quotient_y:COORD_BITS'(SPAN/2)-quotient_y;
 end
'''+s[z:]
s=s.replace('state<=IDLE;front<=0;', 'state<=IDLE;map_wait<=0;front<=0;')
s=s.replace('wire [16:0] candidate=ax>ay?ax:ay;', '''reg [16:0] peak_ax,peak_ay;reg [1:0] peak_valid_pipe;
 wire [16:0] candidate=peak_ax>peak_ay?peak_ax:peak_ay;
 always @(posedge clk)begin
  peak_ax<=centered_x_q[16]?17'(-centered_x_q):17'(centered_x_q);
  peak_ay<=centered_y_q[16]?17'(-centered_y_q):17'(centered_y_q);
  peak_valid_pipe<={peak_valid_pipe[0],state==PEAK && primed && index<=512};
 end''')
s=s.replace('if(primed)begin peak<=next_peak;\n     if(index==512)begin state<=GAIN;end\n    end',
 '''if(peak_valid_pipe[2])peak<=next_peak;
    if(index==515)state<=GAIN;''')
s=s.replace('reg [1:0] peak_valid_pipe;', 'reg [2:0] peak_valid_pipe;')
s=s.replace('wire [16:0] candidate=peak_ax>peak_ay?peak_ax:peak_ay;', 'reg [16:0] candidate;')
s=s.replace('peak_valid_pipe<={peak_valid_pipe[0],', 'candidate<=peak_ax>peak_ay?peak_ax:peak_ay;\n  peak_valid_pipe<={peak_valid_pipe[1:0],')
s=s.replace('READ_POINT:state<=WAIT_POINT;\n   WAIT_POINT:state<=BEGIN_LINE;',
 '''READ_POINT:begin state<=WAIT_POINT;map_wait<=0;end
   WAIT_POINT:if(map_wait==5)state<=BEGIN_LINE;else map_wait<=map_wait+1'b1;''')
a=s.index('    error<=$signed({3\'b0,(mapped_x>');z=s.index('   DRAW_LINE:begin',a)
s=s[:a]+'''    state<=SET_ERROR;
   end
   SET_ERROR:begin
    error<=$signed({2'b0,delta_x})-$signed({2'b0,delta_y});state<=DRAW_LINE;
   end
'''+s[z:]
from display_hybrid_shift_20261023 import predict_xy_clear
s=predict_xy_clear(s)
p.write_text(s)
print('Pipelined exact XY normalization (6 clocks), delta and line setup')
