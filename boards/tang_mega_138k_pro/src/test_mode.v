`default_nettype none
// Diagnostic MIDI notes >=4 default2048/48k FFT bins apart.
// These still enter the ordinary independent Voice DDS/ADSR/mixer path.
module test_mode #(parameter VOICES=32,parameter IDX_W=5)(
 input wire enable,input wire [IDX_W-1:0] index,
 output reg force_start,output reg [6:0] midi_note
);
 wire [31:0] extended_index={{(32-IDX_W){1'b0}},index};
 always @(*)begin
   force_start=enable && extended_index<VOICES;
   case(extended_index)
     32'd0:midi_note=7'd60;
     32'd1:midi_note=7'd66;
     32'd2:midi_note=7'd70;
     32'd3:midi_note=7'd74;
     32'd4:midi_note=7'd77;
     32'd5:midi_note=7'd80;
     32'd6:midi_note=7'd82;
     32'd7:midi_note=7'd84;
     32'd8:midi_note=7'd86;
     32'd9:midi_note=7'd88;
     32'd10:midi_note=7'd90;
     32'd11:midi_note=7'd92;
     32'd12:midi_note=7'd93;
     32'd13:midi_note=7'd94;
     32'd14:midi_note=7'd95;
     32'd15:midi_note=7'd96;
     32'd16:midi_note=7'd97;
     32'd17:midi_note=7'd98;
     32'd18:midi_note=7'd99;
     32'd19:midi_note=7'd100;
     32'd20:midi_note=7'd101;
     32'd21:midi_note=7'd102;
     32'd22:midi_note=7'd103;
     32'd23:midi_note=7'd104;
     32'd24:midi_note=7'd105;
     32'd25:midi_note=7'd106;
     32'd26:midi_note=7'd107;
     32'd27:midi_note=7'd108;
     32'd28:midi_note=7'd109;
     32'd29:midi_note=7'd110;
     32'd30:midi_note=7'd111;
     32'd31:midi_note=7'd112;
     default:midi_note=7'd60;
   endcase
 end
endmodule
`default_nettype wire
