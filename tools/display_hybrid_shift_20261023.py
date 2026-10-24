"""Use FFs on observed hold-critical metadata, retaining compact other shifts."""
def distributed_shifts(source):
    return source.replace('syn_srlstyle="registers"','syn_srlstyle="distributed_ram"')

def protect_scene_voices(source):
    if 'protected_voice_bitmap' in source:
        source=distributed_shifts(source)
        return source.replace('(* syn_srlstyle="distributed_ram" *) reg [31:0] protected_voice_bitmap;',
                              '(* syn_srlstyle="registers" *) reg [31:0] protected_voice_bitmap;')
    source=distributed_shifts(source)
    declaration='  pixel_state incoming,d,q;'
    capture='  always @(posedge clk)q<=d;'
    assert source.count(declaration)==40 and source.count(capture)==40
    source=source.replace(declaration,'''  pixel_state incoming,d,q_raw,q;
  // Actual routed hold paths originate at status_data[50+:32]. Keep this
  // voice bitmap in FFs; other unused/long metadata may use compact shifts.
  (* syn_srlstyle="registers" *) reg [31:0] protected_voice_bitmap;
  always_comb begin q=q_raw;q.status_data={q_raw.status_data[511:82],protected_voice_bitmap,q_raw.status_data[49:0]};end''')
    return source.replace(capture,'''  always @(posedge clk)begin
   q_raw<=d;protected_voice_bitmap<=d.status_data[50+:32];
  end''')

def predict_xy_clear(source):
    if 'reg clear_last;' in source:return source
    source=source.replace(' reg [9:0] index;',' (* syn_preserve=1 *) reg clear_last;\n reg [9:0] index;')
    source=source.replace('ready_shift<=0;clear_index<=0;index<=0;','ready_shift<=0;clear_index<=0;clear_last<=0;index<=0;')
    source=source.replace('state<=CLEAR;clear_index<=0;ready_signal<=0;','state<=CLEAR;clear_index<=0;clear_last<=0;ready_signal<=0;')
    old="   CLEAR:if(&clear_index)begin state<=COPY;index<=0;primed<=0;sum_x<=0;sum_y<=0;end else clear_index<=clear_index+1'b1;"
    assert source.count(old)==1
    return source.replace(old,"""   CLEAR:begin
    // Predict the terminal address one existing clock ahead. The bitmap
    // still clears every address, including DEPTH-1, on the same clocks.
    clear_last<=clear_index==DEPTH-2;
    if(clear_last)begin state<=COPY;index<=0;primed<=0;sum_x<=0;sum_y<=0;end
    else clear_index<=clear_index+1'b1;
   end""")
