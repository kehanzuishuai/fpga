`timescale 1ns/1ps
module tb_hud16;
reg[9:0]x=0,y=0;reg[57:0]s=0;wire ink,area,on;
piano_status_overlay #(.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) hud(x,y,s,ink,area,on);
integer k,j;reg[7:0]letter[0:15];reg[7:0]acc[0:15];
initial begin
letter[0]="C";letter[1]="C";letter[2]="D";letter[3]="D";letter[4]="E";letter[5]="F";letter[6]="F";letter[7]="G";letter[8]="G";letter[9]="A";letter[10]="A";letter[11]="B";letter[12]="C";letter[13]="C";letter[14]="D";letter[15]="D";
for(k=0;k<16;k=k+1)begin
acc[k]=(k==1||k==3||k==6||k==8||k==10||k==13||k==15)?"#":" ";
s={16'(1<<k),6'd32,24'habcdef,7'(60+k),1'b1,4'd3};
for(j=0;j<16;j=j+1)begin x=10'(8+24*j);y=198;#1;if(!area || on!==(j==k))$fatal(1,"key correspondence%0d/%0d",k,j);end
x=392;#1;if(area)$fatal(1,"seventeenth key");
x=23*8;y=164;#1;if(hud.ch!==letter[k] || hud.bits==0)$fatal(1,"note glyph%0d",k);
x=24*8;#1;if(hud.ch!==acc[k])$fatal(1,"sharp%0d",k);
x=25*8;#1;if(hud.ch!==(k<12?8'd52:8'd53))$fatal(1,"octave%0d",k);
end
$display("PASS16key positions onehot/all note names MIDI60..75; Voice32 does not create32keys");$finish;
end endmodule
