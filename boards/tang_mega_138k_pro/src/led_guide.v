

module led_guide #(
    parameter LED_COUNT = 12
)(
    input                       enable,
    input                       target_valid,
    input      [6:0]            target_note,

    input                       note_played,
    input      [6:0]            played_note,

    output reg [LED_COUNT-1:0]  leds,
    output reg                  hit
);


/* ============================================================
 * Convert LED_COUNT to 7-bit constant
 * ============================================================ */
localparam [6:0] LED_COUNT_7 = LED_COUNT;


/* ============================================================
 * Teaching LED guide
 * ============================================================ */
always @(*) begin

    /*
     * 判断用户是否弹中了目标音符
     */
    hit =
        enable &&
        target_valid &&
        note_played &&
        (played_note == target_note);


    /*
     * 默认所有 LED 熄灭
     */
    leds = {LED_COUNT{1'b0}};


    /*
     * 教学模式有效时：
     * MIDI note 对 LED_COUNT 取余
     *
     * 默认 LED_COUNT = 12：
     *
     * C  -> LED0
     * C# -> LED1
     * D  -> LED2
     * ...
     * B  -> LED11
     */
    if (enable && target_valid) begin

        leds =
            {{(LED_COUNT-1){1'b0}}, 1'b1}
            << (target_note % LED_COUNT_7);

    end

end


endmodule
