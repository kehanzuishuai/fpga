"""Lossless early note selection in the existing 21-cycle label pipeline."""
def compact_selected_note(source):
    if 'key_note_pipe[0]<=pick_key_note' in source:
        return source
    declaration=' reg [6:0] char_key_note;'
    delay='status_pipe[meta_i]<=status_pipe[meta_i-1];control_pipe[meta_i]<=control_pipe[meta_i-1];'
    lookup='char_key_note<=pick_key_note(status_pipe[15],attr_pipe[14][32:28]);'
    for text in (declaration,delay,lookup):
        assert source.count(text)==1,('Expected original label pipeline',text)
    source=source.replace(declaration,''' // Select the current label's note after region/attribute registration.
 // Keep the original capture at stage16; only unused mapping metadata is dropped.
 reg [6:0] char_key_note,key_note_pipe[0:13];integer note_stage;
 always @(posedge clk)begin
  key_note_pipe[0]<=pick_key_note(status_pipe[1],attr_pipe[0][32:28]);
  for(note_stage=1;note_stage<14;note_stage=note_stage+1)
   key_note_pipe[note_stage]<=key_note_pipe[note_stage-1];
 end''')
    source=source.replace(delay,'''if(meta_i<2)status_pipe[meta_i]<=status_pipe[meta_i-1];
   else status_pipe[meta_i]<={status_pipe[meta_i-1][511:306],224'b0,status_pipe[meta_i-1][81:0]};
   control_pipe[meta_i]<=control_pipe[meta_i-1];''')
    return source.replace(lookup,'char_key_note<=key_note_pipe[13];')
