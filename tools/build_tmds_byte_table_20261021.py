"""Exact combinational byte transform; disparity feedback and word cadence unchanged."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'audit/display_integration_20261021/backup/src/display/visual_tmds.sv').read_text()
s=s.replace('output reg [9:0] symbol);','output reg [9:0] symbol) /* synthesis syn_romstyle="logic" */;')
a=s.index(' reg [8:0] q;');b=s.index(' always @(posedge clk',a)
body=''' // Exact transition-minimization transform for all256 bytes. This is a
 // combinational LUT table, not a new pixel pipeline or a block RAM.
 function automatic [14:0] byte_transform(input [7:0] value);
  begin case(value)
'''
for byte in range(256):
 ones=byte.bit_count();xnor=ones>4 or (ones==4 and not (byte&1));q=byte&1
 for bit in range(1,8):q|=(((q>>(bit-1))&1)^((byte>>bit)&1)^int(xnor))<<bit
 balance=2*q.bit_count()-8;q|=int(not xnor)<<8
 body+=f" 8'h{byte:02x}:byte_transform=15'h{(((balance&63)<<9)|q):04x};\n"
body+=''' default:byte_transform=0;
 endcase end
 endfunction
 wire [14:0] transformed=byte_transform(data);
 wire [8:0] q=transformed[8:0];
 wire signed [5:0] balance=$signed(transformed[14:9]);
 reg signed [5:0] disparity;
'''
(R/'src/display/visual_tmds.sv').write_text(s[:a]+body+s[b:])
