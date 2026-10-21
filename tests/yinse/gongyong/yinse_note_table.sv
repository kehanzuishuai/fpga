`default_nettype none
// 48 kHz ONLY; supported MIDI 36..96. Outside range is rejected, not aliased.
module yinse_note_table(input wire [6:0] note,output reg [31:0] increment,
 output reg [10:0] delay_length,output reg signed [15:0] tuning,output reg valid);
 always_comb begin
 increment=0;delay_length=2;tuning=0;valid=0;
 case(note)
 7'd36:begin increment=32'd5852465;delay_length=11'd733;tuning=16'hebdf;valid=1;end
 7'd37:begin increment=32'd6200470;delay_length=11'd692;tuning=16'hf536;valid=1;end
 7'd38:begin increment=32'd6569170;delay_length=11'd653;tuning=16'heefb;valid=1;end
 7'd39:begin increment=32'd6959793;delay_length=11'd617;tuning=16'h1edf;valid=1;end
 7'd40:begin increment=32'd7373644;delay_length=11'd582;tuning=16'h0195;valid=1;end
 7'd41:begin increment=32'd7812103;delay_length=11'd549;tuning=16'hf019;valid=1;end
 7'd42:begin increment=32'd8276635;delay_length=11'd518;tuning=16'he97e;valid=1;end
 7'd43:begin increment=32'd8768789;delay_length=11'd489;tuning=16'hef3a;valid=1;end
 7'd44:begin increment=32'd9290209;delay_length=11'd462;tuning=16'h0d58;valid=1;end
 7'd45:begin increment=32'd9842633;delay_length=11'd436;tuning=16'h095e;valid=1;end
 7'd46:begin increment=32'd10427907;delay_length=11'd411;tuning=16'hebe8;valid=1;end
 7'd47:begin increment=32'd11047982;delay_length=11'd388;tuning=16'hf17c;valid=1;end
 7'd48:begin increment=32'd11704930;delay_length=11'd366;tuning=16'he910;valid=1;end
 7'd49:begin increment=32'd12400941;delay_length=11'd346;tuning=16'h0afa;valid=1;end
 7'd50:begin increment=32'd13138339;delay_length=11'd326;tuning=16'hea84;valid=1;end
 7'd51:begin increment=32'd13919586;delay_length=11'd308;tuning=16'hfc88;valid=1;end
 7'd52:begin increment=32'd14747287;delay_length=11'd291;tuning=16'h1350;valid=1;end
 7'd53:begin increment=32'd15624207;delay_length=11'd274;tuning=16'heb08;valid=1;end
 7'd54:begin increment=32'd16553270;delay_length=11'd259;tuning=16'h0263;valid=1;end
 7'd55:begin increment=32'd17537579;delay_length=11'd244;tuning=16'heaa1;valid=1;end
 7'd56:begin increment=32'd18580418;delay_length=11'd231;tuning=16'h1aa1;valid=1;end
 7'd57:begin increment=32'd19685267;delay_length=11'd218;tuning=16'h1837;valid=1;end
 7'd58:begin increment=32'd20855814;delay_length=11'd205;tuning=16'he915;valid=1;end
 7'd59:begin increment=32'd22095965;delay_length=11'd194;tuning=16'h0853;valid=1;end
 7'd60:begin increment=32'd23409859;delay_length=11'd183;tuning=16'h0210;valid=1;end
 7'd61:begin increment=32'd24801882;delay_length=11'd173;tuning=16'h1933;valid=1;end
 7'd62:begin increment=32'd26276679;delay_length=11'd163;tuning=16'h032b;valid=1;end
 7'd63:begin increment=32'd27839171;delay_length=11'd154;tuning=16'h0fff;valid=1;end
 7'd64:begin increment=32'd29494575;delay_length=11'd145;tuning=16'hf8d1;valid=1;end
 7'd65:begin increment=32'd31248413;delay_length=11'd137;tuning=16'h038e;valid=1;end
 7'd66:begin increment=32'd33106541;delay_length=11'd129;tuning=16'hf2b6;valid=1;end
 7'd67:begin increment=32'd35075158;delay_length=11'd122;tuning=16'h0341;valid=1;end
 7'd68:begin increment=32'd37160835;delay_length=11'd115;tuning=16'hfb35;valid=1;end
 7'd69:begin increment=32'd39370534;delay_length=11'd109;tuning=16'h20ea;valid=1;end
 7'd70:begin increment=32'd41711627;delay_length=11'd102;tuning=16'he7b9;valid=1;end
 7'd71:begin increment=32'd44191930;delay_length=11'd97;tuning=16'h1793;valid=1;end
 7'd72:begin increment=32'd46819719;delay_length=11'd91;tuning=16'hf296;valid=1;end
 7'd73:begin increment=32'd49603764;delay_length=11'd86;tuning=16'hfac0;valid=1;end
 7'd74:begin increment=32'd52553357;delay_length=11'd81;tuning=16'hf303;valid=1;end
 7'd75:begin increment=32'd55678342;delay_length=11'd77;tuning=16'h1c33;valid=1;end
 7'd76:begin increment=32'd58989149;delay_length=11'd72;tuning=16'heed9;valid=1;end
 7'd77:begin increment=32'd62496826;delay_length=11'd68;tuning=16'hf329;valid=1;end
 7'd78:begin increment=32'd66213081;delay_length=11'd64;tuning=16'hec35;valid=1;end
 7'd79:begin increment=32'd70150316;delay_length=11'd61;tuning=16'h1463;valid=1;end
 7'd80:begin increment=32'd74321671;delay_length=11'd57;tuning=16'hefd8;valid=1;end
 7'd81:begin increment=32'd78741067;delay_length=11'd54;tuning=16'hfd28;valid=1;end
 7'd82:begin increment=32'd83423255;delay_length=11'd51;tuning=16'h0107;valid=1;end
 7'd83:begin increment=32'd88383859;delay_length=11'd48;tuning=16'hfa3a;valid=1;end
 7'd84:begin increment=32'd93639437;delay_length=11'd45;tuning=16'hec26;valid=1;end
 7'd85:begin increment=32'd99207528;delay_length=11'd43;tuning=16'h0ecc;valid=1;end
 7'd86:begin increment=32'd105106715;delay_length=11'd40;tuning=16'hec57;valid=1;end
 7'd87:begin increment=32'd111356685;delay_length=11'd38;tuning=16'hfbb4;valid=1;end
 7'd88:begin increment=32'd117978298;delay_length=11'd36;tuning=16'h0667;valid=1;end
 7'd89:begin increment=32'd124993653;delay_length=11'd34;tuning=16'h0986;valid=1;end
 7'd90:begin increment=32'd132426162;delay_length=11'd32;tuning=16'h0471;valid=1;end
 7'd91:begin increment=32'd140300631;delay_length=11'd30;tuning=16'hf92d;valid=1;end
 7'd92:begin increment=32'd148643341;delay_length=11'd28;tuning=16'heaea;valid=1;end
 7'd93:begin increment=32'd157482134;delay_length=11'd27;tuning=16'h1069;valid=1;end
 7'd94:begin increment=32'd166846509;delay_length=11'd25;tuning=16'hf22f;valid=1;end
 7'd95:begin increment=32'd176767719;delay_length=11'd24;tuning=16'h0e71;valid=1;end
 7'd96:begin increment=32'd187278874;delay_length=11'd22;tuning=16'he932;valid=1;end
 default:begin end
 endcase
 end
endmodule
`default_nettype wire
