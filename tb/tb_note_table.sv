`timescale 1ns/1ps
module tb_note_table;
  logic [6:0] note;logic [31:0] phase_inc,previous;integer fd,k;
  note_freq_table dut(.midi_note(note),.phase_inc);
  initial begin
    fd=$fopen("sim_out/note_table.csv","w");if(fd==0)$fatal(1,"cannot create note table capture");
    $fwrite(fd,"note,phase_inc\n");previous=0;
    for(k=0;k<128;k=k+1)begin
      note=k[6:0];#1;
      if(k!=0&&phase_inc<=previous)$fatal(1,"note table not monotonic at %0d",k);
      $fwrite(fd,"%0d,%0d\n",k,phase_inc);previous=phase_inc;
    end
    $fclose(fd);
    if(dut.phase_inc_48k(7'd69)!=32'd39370534)$fatal(1,"A4 phase increment mismatch");
    $display("TB_NOTE_TABLE PASS: all 128 MIDI ROM entries captured and monotonic");$finish;
  end
endmodule
