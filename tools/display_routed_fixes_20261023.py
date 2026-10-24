"""Target the completed V5 STA paths without changing visual content."""
import re

def register_shifts(source):
    # Ordinary random-access wave/font memories are not shift registers.
    return source.replace('syn_srlstyle="distributed_ram"','syn_srlstyle="registers"')

def retime_spectrum(source):
    if 'SCAN preparation clock uses the final registered peak bin' in source:return source
    old="wire [LOGN-2:0] candidate_bin=new_peak?prev_count[LOGN-2:0]:peak_bin;"
    assert source.count(old)==1
    source=source.replace(old,'// SCAN preparation clock uses the final registered peak bin.')
    source=source.replace("64'(candidate_bin)*64'(SAMPLE_RATE)","64'(peak_bin)*64'(SAMPLE_RATE)")
    old='peak_hz<=candidate_hz;peak_valid<=new_peak || peak_power!=0;'
    assert source.count(old)==1
    source=source.replace(old,'peak_valid<=new_peak || peak_power!=0;')
    old='   SPEC_SCAN:begin\n    primed<=1;'
    assert source.count(old)==1
    source=source.replace(old,'''   SPEC_SCAN:begin
    // Final COPY bin is already in peak_bin. Use the existing preparation
    // clock for Hz conversion; scan/release timing and final metadata agree.
    if(!primed)peak_hz<=candidate_hz;
    primed<=1;''')
    start=source.index(' wire [LOGN-2:0] highest_candidate=')
    end=source.index(' function [7:0] power_height',start)
    source=source[:start]+''' // Factor the two-bit range selection outside the late significance mux.
 function automatic [1:0] range_for_bin(input [LOGN-2:0] bin);
 begin range_for_bin=bin<=((1<<(LOGN-3))-2)?2'd0:
  bin<=((1<<(LOGN-2))-2)?2'd1:bin<=(3*(1<<(LOGN-3))-2)?2'd2:2'd3;
 end endfunction
 wire [1:0] desired_range=significant?range_for_bin(prev_count[LOGN-2:0]):range_for_bin(highest_bin);
'''+source[end:]
    return source

def preserve_gradient(source):
    if '(* syn_preserve=1,syn_keep=1 *) reg [9:0] gradient_pos1;' in source:return source
    old=' reg [9:0] gradient_pos1;'
    if old in source:source=source.replace(old,' (* syn_preserve=1,syn_keep=1 *) reg [9:0] gradient_pos1;')
    return source

def stage_static_chars(source):
    if 'reg [15:0] static_character_q;' in source:return source
    start=source.index(' function automatic [15:0] static_char(')
    end=source.index('endfunction',start)+len('endfunction')
    function=source[start:end]
    lines=function.splitlines();constants=[];dynamic=[]
    for line in lines[1:-1]:
        m=re.fullmatch(r"\s*14'd(\d+):static_char=(.*);",line)
        assert m,('Unexpected static character entry',line)
        (constants if re.fullmatch(r"16'[hd][0-9a-fA-F]+|32",m[2]) else dynamic).append(line)
    assert len(constants)>60 and len(dynamic)>5
    header=lines[0].replace('begin case(index)','begin static_char=static_character_q;case(index)')
    shortened=header+'\n'+'\n'.join(dynamic)+'\n default:static_char=static_character_q;endcase end endfunction'
    early=''' reg [15:0] static_character_q;
 function automatic [15:0] static_constant(input [13:0] index);
 begin case(index)
'''+('\n'.join(line.replace('static_char=','static_constant=') for line in constants))+'''
 default:static_constant=16'd32;endcase end endfunction
 // Same stage as attr_char; the following character edge handles only
 // dynamic text and kind selection. Overall label latency remains21 clocks.
 always @(posedge clk)static_character_q<=static_constant({attr_pipe[14][35:28],attr_pipe[14][19:14]});
'''
    return source[:start]+early+shortened+source[end:]

def renderer_fixes(source):return register_shifts(preserve_gradient(retime_spectrum(source)))
def label_fixes(source):
    from display_selected_note_20261023 import compact_selected_note
    return register_shifts(stage_static_chars(compact_selected_note(source)))

def table_key_fallback(source):
    """Optional next revision: decimal K1..K16 via literal glyph values."""
    if '// Exact fallback K1..K16 table' in source:return source
    old=" else if(pos==0)key_char=16'd75;else if(pos==1)key_char=decimal(32'(key%16+1),key%16+1>=10?1:0);else key_char=key%16+1>=10?decimal(32'(key%16+1),0):16'd32;"
    assert source.count(old)==1
    leading='\n'.join(f"  4'd{k}:key_char=16'd{49+k};" for k in range(9))
    trailing='\n'.join(f"  4'd{k}:key_char=16'd{48+k-9};" for k in range(9,16))
    return source.replace(old,""" // Exact fallback K1..K16 table; mapped MIDI note names are unchanged.
 else if(pos==0)key_char=16'd75;
 else if(pos==1)begin case(key[3:0])
"""+leading+"""
  default:key_char=16'd49;endcase end
 else begin case(key[3:0])
"""+trailing+"""
  default:key_char=16'd32;endcase end""")

def stage_axis_digits(source):
    if 'reg [19:0] axis_bcd_q;' in source:return source
    old=' reg [19:0] numeric_bcd;'
    assert source.count(old)==1
    source=source.replace(old,''' // Axis arguments and range are ready at the existing char-status edge.
 // Register their BCD before the shared digit selector, retaining21 clocks.
 reg [19:0] axis_bcd_q;
 always @(posedge clk)axis_bcd_q<=axis_bcd(control_pipe[15][1:0],attr_pipe[14][35:28]);
 reg [19:0] numeric_bcd;''')
    old='AXIS:numeric_bcd=axis_bcd(char_range,argument);'
    assert source.count(old)==1
    return source.replace(old,'AXIS:numeric_bcd=axis_bcd_q;')

def stage_completed_digits(source):
    if 'reg [15:0] completed_character_q[0:4];' in source:return source
    marker=' reg [19:0] axis_bcd_q;';assert source.count(marker)==1
    captures=[]
    for digit in range(5):
        char=f"16'd48+16'(completed_bcd_pipe[15][{digit*4}+:4])"
        if digit:char=f"(status_pipe[15][493+:16] < 16'd{10**digit} ? 16'd32 : {char})"
        captures.append(f'  completed_character_q[{digit}]<={char};')
    source=source.replace(marker,''' reg [15:0] completed_character_q[0:4];
 // Trim and ASCII conversion share the existing char-status capture edge.
 always @(posedge clk)begin
'''+('\n'.join(captures))+'\n end\n'+marker)
    import re
    for digit in range(5):
        key=2820-digit
        pattern=r"14'd"+str(key)+r':static_char=[^;]+;'
        assert len(re.findall(pattern,source))==1
        source=re.sub(pattern,f"14'd{key}:static_char=completed_character_q[{digit}];",source)
    return source
