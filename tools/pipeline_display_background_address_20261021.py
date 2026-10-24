"""Split raster-to-packed-ROM address arithmetic without changing texels."""
def pipeline_background_address(s):
    assert 'parameter REGISTER_ADDR=' not in s
    s=s.replace('Four registered sampling stages','Six registered sampling stages')
    for i in range(4):s=s.replace(f'.WORDS(WORDS),.FILE(FILE{i})',f'.WORDS(WORDS),.FILE(FILE{i}),.REGISTER_ADDR(1)')
    s=s.replace('parameter WORDS=1,FILE=""','parameter WORDS=1,FILE="",parameter REGISTER_ADDR=0')
    s=s.replace('wire [AW-1:0] local_addr=addr[AW-1:0];', '''reg [AW-1:0] addr_q;
 always @(posedge clk)addr_q<=addr[AW-1:0];
 wire [AW-1:0] local_addr=REGISTER_ADDR!=0?addr_q:addr[AW-1:0];''')
    old=" wire [AW+1:0] word_addr=scaled/(AW+2)'(3);"
    assert old in s
    s=s.replace(old,''' localparam DIV_SHIFT=AW+2,PRODUCT_W=AW+DIV_SHIFT+1;
 localparam [PRODUCT_W-1:0] DIV3_RECIP=((1<<DIV_SHIFT)+2)/3;
 reg [PRODUCT_W-1:0] address_product;reg [AW-1:0] address_delayed;
 always @(posedge clk)begin
  address_product<=PRODUCT_W'(local_addr)*DIV3_RECIP;address_delayed<=local_addr;
 end
 wire [AW-1:0] quotient=AW'(address_product>>DIV_SHIFT);
 wire [AW+1:0] word_addr=REGISTER_ADDR!=0?{2'b0,address_delayed}+{2'b0,quotient}:scaled/(AW+2)'(3);''')
    s=s.replace("wire [1:0] residue=local_addr%AW'(3);", "wire [1:0] residue=REGISTER_ADDR!=0?2'(address_delayed)-2'(quotient)-{quotient[0],1'b0}:local_addr%AW'(3);")
    s=s.replace('reg [WEIGHT_W-1:0] wa,wb,wc,wd;', '''reg [WEIGHT_W-1:0] wa,wb,wc,wd;
 reg [WEIGHT_W-1:0] wa_addr,wb_addr,wc_addr,wd_addr,wa_addr2,wb_addr2,wc_addr2,wd_addr2;
 reg [1:0] corner_addr,corner_addr2;''')
    s=s.replace('select_q(corner,','select_q(corner_addr2,').replace('select_q(corner^','select_q(corner_addr2^')
    s=s.replace('sample_a<=a;sample_b<=b;sample_c<=c;sample_d<=d;', '''corner_addr<=corner;wa_addr<=wa;wb_addr<=wb;wc_addr<=wc;wd_addr<=wd;
  corner_addr2<=corner_addr;wa_addr2<=wa_addr;wb_addr2<=wb_addr;wc_addr2<=wc_addr;wd_addr2<=wd_addr;
  sample_a<=a;sample_b<=b;sample_c<=c;sample_d<=d;''')
    s=s.replace('weight_a<=wa;weight_b<=wb;weight_c<=wc;weight_d<=wd;', 'weight_a<=wa_addr2;weight_b<=wb_addr2;weight_c<=wc_addr2;weight_d<=wd_addr2;')
    assert '.REGISTER_ADDR(1)' in s and 'REGISTER_ADDR!=0' in s
    from display_texture_address_20261023 import retime_texture_address
    return retime_texture_address(s)
if __name__=='__main__':
    from pathlib import Path
    r=Path(__file__).resolve().parents[1];p=r/'src/display/visual_background.sv'
    before=r/'audit/display_integration_20261021/timing_repair/visual_background.before_address_pipeline.sv'
    if not before.exists():before.write_bytes(p.read_bytes())
    p.write_text(pipeline_background_address(before.read_text()))
