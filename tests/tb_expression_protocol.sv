module tb_expression_protocol;
reg clk=0;always #5 clk=~clk;
reg rst_n=0,pv=0;wire pr,rv,cv;reg [7:0] seq=0,cmd=0,len=0;reg [47:0] payload=0;wire [47:0] response;wire [7:0] cc;wire [15:0] val;
wifi_control dut(.clk(clk),.rst_n(rst_n),.packet_valid(pv),.packet_ready(pr),.packet_seq(seq),.packet_cmd(cmd),.packet_len(len),.packet_payload(payload),.response_valid(rv),.response_ready(1'b1),.response_payload(response),.cfg_valid(cv),.cfg_ready(1'b1),.cfg_cmd(cc),.cfg_value(val),.rec_event(1'b0),.sample_tick(1'b0));
task request(input [7:0] c,input [7:0] l,input [7:0] v,input [7:0] status);
begin
 @(negedge clk);while(!pr)@(negedge clk);seq=seq+1;cmd=c;len=l;payload={40'd0,v};pv=1;
 @(negedge clk);pv=0;while(!rv)@(negedge clk);
 if(response[15:8]!==status)$fatal(1,"cmd %h status %h",c,response);
 @(negedge clk);
end endtask
initial begin
 #21;rst_n=1;
 request(8'h19,1,100,0);request(8'h1a,1,75,0);request(8'h18,1,50,0);
 request(8'h08,0,0,0);
 if(response[47:16]!==32'h014b6432)$fatal(1,"readback %h",response);
 request(8'h19,1,101,1);request(8'h1a,2,10,1);
 request(8'h19,1,0,0);request(8'h1a,1,0,0);
 $display("PASS expression commands, bounds, lengths and readback");$finish;
end
initial begin #10000;$fatal(1,"timeout");end
endmodule
