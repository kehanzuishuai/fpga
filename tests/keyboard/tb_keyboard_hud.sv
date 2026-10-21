`timescale 1ns/1ps
module tb_keyboard_hud;
reg[9:0]x=0,y=184;reg[57:0]status={16'h8001,6'd16,24'habcdef,7'd60,1'b1,4'd3};
wire ink0,area0,on0,ink1,area1,on1;
piano_status_overlay #(.MAPPING_CONFIRMED(0)) raw_hud(x,y,status,ink0,area0,on0);
piano_status_overlay #(.MAPPING_CONFIRMED(1)) key_hud(x,y,status,ink1,area1,on1);
integer checks=0,k;reg[39:0]rawlabel="RAWS=",keylabel="KEYS=";
initial begin
 for(k=0;k<5;k=k+1)begin
  x=10'(8*k);#1;checks=checks+1;
  if(raw_hud.ch!==8'(rawlabel>>(8*(4-k))) || key_hud.ch!==8'(keylabel>>(8*(4-k))))
  $fatal(1,"mapping label");
 end
 x=296;#1;checks=checks+1;if(raw_hud.ch!=="0" || key_hud.ch!=="1")$fatal(1,"mapping confirmation indicator");
 y=168;x=184;#1;checks=checks+1;if(raw_hud.ch!=="C")$fatal(1,"MIDI note");
 for(k=0;k<16;k=k+1)begin
  x=10'(400+k*12);#1;checks=checks+1;
  if(!area0 || !area1 || on0!==status[42+k] || on1!==status[42+k])$fatal(1,"key bitmap mapping");
 end
 $display("PASS keyboard HUD: %0d checks; RAWS/MAP=0 before physical confirmation, KEYS/MAP=1 only when configured, bitmap and actual MIDI retained",checks);$finish;
end
endmodule
