"""Pair single-port KS memories without changing samples or clock scheduling."""
from pathlib import Path
import shutil,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/packed_ks';A.mkdir(exist_ok=True)
paths=['src/instruments/jita/yinse_ks_loop.sv','src/instruments/gongyong/yinse_aux_voice.sv','src/instruments/gongyong/yinse_aux_bank.sv']
for n in paths:
    p=A/'before'/n;p.parent.mkdir(parents=True,exist_ok=True)
    assert not p.exists(), 'One-time transform: archived source already exists'
    shutil.copy2(R/n,p)
p=R/paths[0];s=p.read_text()
header=s[s.index('module yinse_ks_loop'):s.index(');')+2]
wrapper=header+'''
 wire [$clog2(MAX_DELAY)-1:0] unused_address;
 wire unused_read,unused_write;wire[23:0] unused_data;
 yinse_ks_loop_core #(.MAX_DELAY(MAX_DELAY),.SEED(SEED)) core(
  clk,rst_n,sample_tick,start,clear,enable,delay_in,tuning_in,sample,busy,overrun,clipped,
  unused_address,unused_read,unused_write,unused_data,24'd0);
endmodule
'''
s=s.replace('module yinse_ks_loop #','module yinse_ks_loop_core #',1).replace("parameter [23:0] SEED=24'h713AC5)(","parameter [23:0] SEED=24'h713AC5,parameter EXTERNAL_MEMORY=0)(",1)
s=s.replace('output reg signed [23:0] sample,output wire busy,output reg overrun,clipped\n','''output reg signed [23:0] sample,output wire busy,output reg overrun,clipped,
 output wire [$clog2(MAX_DELAY)-1:0] memory_address,
 output wire memory_read,memory_write,output wire [23:0] memory_write_data,
 input wire [23:0] memory_read_data
''',1)
s=s.replace('reg signed [23:0] memory[0:MAX_DELAY-1],read_data,current,w,v;','reg signed [23:0] current,w,v;wire signed [23:0] read_data;',1)
a=s.index(' // No RAM reset:');b=s.index(' always @(posedge clk or negedge rst_n)',a)
s=s[:a]+''' // One read OR write per voice per clock; paired memories preserve that port.
 assign memory_read=state==READ0 || state==READ1;
 assign memory_write=state==FILL || state==WRITE;
 assign memory_address=state==FILL?fill_ptr:state==WRITE?ptr:read_address;
 assign memory_write_data=state==FILL?$signed(noise)>>>1:clamp24(new_ring);
 generate if(EXTERNAL_MEMORY)begin:G_EXTERNAL_MEMORY
  assign read_data=memory_read_data;
 end else begin:G_LOCAL_MEMORY
  reg signed [23:0] memory[0:MAX_DELAY-1],read_q;
  assign read_data=read_q;
  // No RAM reset: only initialized note-length addresses are read.
  always @(posedge clk)begin
   if(memory_read)read_q<=memory[memory_address];
   if(memory_write)memory[memory_address]<=memory_write_data;
  end
 end endgenerate
'''+s[b:]
s=s.replace('`default_nettype none\n','`default_nettype none\n'+wrapper,1);p.write_text(s)
p=R/paths[1];s=p.read_text()
start=s.index('module yinse_aux_voice_shared');end=s.index(');',start)+2;header=s[start:end]
wrapper=header+'''
 wire [$clog2(MAX_DELAY)-1:0] unused_address;
 wire unused_read,unused_write;wire[23:0] unused_data;
 yinse_aux_voice_context #(.MAX_DELAY(MAX_DELAY),.SEED(SEED),.EXTERNAL_ARITH(EXTERNAL_ARITH)) context_voice(
  clk,rst_n,sample_tick,start,stop,clear,instrument_in,note_in,velocity_in,
  ready,active,sample,overrun,clipped,note,note_params,compute_enable,shared_result,arithmetic_query,
  unused_address,unused_read,unused_write,unused_data,24'd0);
endmodule
'''
s=s[:start]+wrapper+s[start:]
start=s.index('module yinse_aux_voice_shared',start+len(wrapper));s=s[:start]+s[start:].replace('module yinse_aux_voice_shared','module yinse_aux_voice_context',1)
s=s[:start]+s[start:].replace('parameter EXTERNAL_ARITH=0)(','parameter EXTERNAL_ARITH=0,parameter EXTERNAL_KS_MEMORY=0)(',1)
start=s.index('module yinse_aux_voice_context');prefix=s[:start];tail=s[start:]
tail=tail.replace('output wire [398:0] arithmetic_query\n','''output wire [398:0] arithmetic_query,
 output wire [$clog2(MAX_DELAY)-1:0] ks_memory_address,
 output wire ks_memory_read,ks_memory_write,output wire [23:0] ks_memory_write_data,
 input wire [23:0] ks_memory_read_data
''',1)
tail=tail.replace('yinse_ks_loop #(.MAX_DELAY(MAX_DELAY),.SEED(SEED)) ks(','yinse_ks_loop_core #(.MAX_DELAY(MAX_DELAY),.SEED(SEED),.EXTERNAL_MEMORY(EXTERNAL_KS_MEMORY)) ks(',1)
tail=tail.replace('ks_length,ks_tuning,ks_sample,ks_busy,ks_overrun,ks_clipped);','ks_length,ks_tuning,ks_sample,ks_busy,ks_overrun,ks_clipped,\n ks_memory_address,ks_memory_read,ks_memory_write,ks_memory_write_data,ks_memory_read_data);',1)
p.write_text(prefix+tail)
p=R/paths[2];s=p.read_text()
marker=' genvar g;'
assert s.count(marker)==1
s=s.replace(marker,''' // Keep every24-bit sample and each independent logical port. The upper
 // six bits of two voices share one true-dual-port2048x9 block; lower18
 // bits each retain a1024x18 block. Three blocks per pair, no arbitration.
 localparam PACKED_KS=(MAX_DELAY==1024 && VOICES>=2);
 localparam KAW=$clog2(MAX_DELAY);
 wire [VOICES*KAW-1:0] ks_address;
 wire [VOICES-1:0] ks_read,ks_write;
 wire [VOICES*24-1:0] ks_write_data,ks_read_data;
 genvar pair;
 generate if(PACKED_KS)begin:G_PACKED_KS
  for(pair=0;pair<VOICES/2;pair=pair+1)begin:P
   yinse_ks_ram_pair memory(clk,
    ks_address[(pair*2)*KAW+:KAW],ks_read[pair*2],ks_write[pair*2],ks_write_data[(pair*2)*24+:24],ks_read_data[(pair*2)*24+:24],
    ks_address[(pair*2+1)*KAW+:KAW],ks_read[pair*2+1],ks_write[pair*2+1],ks_write_data[(pair*2+1)*24+:24],ks_read_data[(pair*2+1)*24+:24]);
  end
 end else begin:G_LOCAL_KS
  assign ks_read_data=0;
 end endgenerate
 genvar g;''',1)
s=s.replace('yinse_aux_voice_shared #(.MAX_DELAY(MAX_DELAY),.SEED(24\'h713AC5+24\'(g)),.EXTERNAL_ARITH(1)) voice(',"yinse_aux_voice_context #(.MAX_DELAY(MAX_DELAY),.SEED(24'h713AC5+24'(g)),.EXTERNAL_ARITH(1),.EXTERNAL_KS_MEMORY(PACKED_KS)) voice(",1)
a='queries[g*399+:399]);';assert s.count(a)==1
s=s.replace(a,'''queries[g*399+:399],
   ks_address[g*KAW+:KAW],ks_read[g],ks_write[g],ks_write_data[g*24+:24],ks_read_data[g*24+:24]);''',1)
s+='''
`default_nettype none
// Two independent1024x24 synchronous ports occupy three18Kbit BSRAMs.
module yinse_ks_ram_pair(
 input wire clk,
 input wire[9:0] address_a,input wire read_a,write_a,input wire[23:0] data_a,output wire[23:0] q_a,
 input wire[9:0] address_b,input wire read_b,write_b,input wire[23:0] data_b,output wire[23:0] q_b
);
 (* syn_ramstyle="block_ram" *) reg[17:0] lower_a[0:1023],lower_b[0:1023];
 reg[17:0] low_q_a,low_q_b;
 always @(posedge clk)begin
  if(read_a)low_q_a<=lower_a[address_a];
  if(write_a)lower_a[address_a]<=data_a[17:0];
  if(read_b)low_q_b<=lower_b[address_b];
  if(write_b)lower_b[address_b]<=data_b[17:0];
 end
 wire[17:0] high_q_a,high_q_b;
 DPX9B #(.READ_MODE0(1'b0),.READ_MODE1(1'b0),.WRITE_MODE0(2'b00),.WRITE_MODE1(2'b00),
 .BIT_WIDTH_0(9),.BIT_WIDTH_1(9)) upper_pair(
 .DOA(high_q_a),.DOB(high_q_b),.DIA({12'd0,data_a[23:18]}),.DIB({12'd0,data_b[23:18]}),
 .BLKSELA(3'd0),.BLKSELB(3'd0),
 .ADA({1'b0,address_a,3'd0}),.ADB({1'b1,address_b,3'd0}),
 .WREA(write_a),.WREB(write_b),.CLKA(clk),.CLKB(clk),.CEA(read_a||write_a),.CEB(read_b||write_b),
 .OCEA(1'b1),.OCEB(1'b1),.RESETA(1'b0),.RESETB(1'b0));
 assign q_a={high_q_a[5:0],low_q_a};assign q_b={high_q_b[5:0],low_q_b};
endmodule
`default_nettype wire
'''
p.write_text(s)
result=dict(status='APPLIED_PENDING_EQUIVALENCE_AND_SYNTHESIS',programming=False,
    scope='Same32 auxiliary contexts, exact24-bit KS values, same per-voice synchronous read/write clock. Standalone/public interfaces wrapped unchanged. Physical piano path untouched.',
    expected_ks_bsram_blocks_before=64,expected_after=48,
    files={n:hashlib.sha256((R/n).read_bytes()).hexdigest() for n in paths})
(A/'CHANGE.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
