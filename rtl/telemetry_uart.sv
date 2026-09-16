`default_nettype none
// Compact generic frames: A5, type, active_count, peak[23:0], pcm[23:0], checksum.
module telemetry_uart #(
  parameter int CLK_HZ=12000000, parameter int BAUD=115200,
  parameter int VOICE_COUNT_W=6, parameter int SAMPLE_W=24
) (
  input logic clk, input logic rst_n, input logic report_strobe,
  input logic [VOICE_COUNT_W-1:0] active_voice_count,
  input logic [SAMPLE_W-1:0] audio_peak, input logic signed [SAMPLE_W-1:0] pcm_sample,
  output logic tx, output logic busy
);
  logic tx_ready, tx_valid; logic [7:0] tx_data; logic [3:0] index;
  logic [7:0] checksum;
  logic [7:0] active_count_byte;
  always @* active_count_byte={{(8-VOICE_COUNT_W){1'b0}},active_voice_count};
  uart_tx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) u_tx(.clk,.rst_n,.valid(tx_valid),.data(tx_data),.ready(tx_ready),.tx);
  assign busy=(index!=0)||tx_valid||!tx_ready;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin index<=0; tx_valid<=0; tx_data<=0; checksum<=0; end
    else begin
      if(index==0 && report_strobe) begin index<=1; checksum<=8'hA5^8'h01^active_count_byte^audio_peak[23:16]^audio_peak[15:8]^audio_peak[7:0]^pcm_sample[23:16]^pcm_sample[15:8]^pcm_sample[7:0]; end
      if(!tx_valid && index!=0) begin
        tx_valid<=1;
        case(index)
          1:tx_data<=8'hA5; 2:tx_data<=8'h01; 3:tx_data<=active_count_byte;
          4:tx_data<=audio_peak[23:16]; 5:tx_data<=audio_peak[15:8]; 6:tx_data<=audio_peak[7:0];
          7:tx_data<=pcm_sample[23:16]; 8:tx_data<=pcm_sample[15:8]; 9:tx_data<=pcm_sample[7:0];
          default: tx_data<=checksum;
        endcase
      end else if(tx_valid && tx_ready) begin
        tx_valid<=0; if(index==10) index<=0; else index<=index+1'b1;
      end
    end
  end
endmodule
`default_nettype wire
