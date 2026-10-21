`timescale 1ns/1ps

/* ============================================================
 * One piano voice + note loader, driven the way voice_bank does.
 *
 * Writes build/voice_log.txt for tools/compare_pcm.py, which
 * replays the same events on the integer model and compares
 * every sample:
 *
 *   L <tick> <note> <velocity>     loader finished after this tick
 *   S <tick> <sample> <rel> <fade> one computed sample
 *
 * Plus arguments (ticks are 48 kHz sample numbers):
 *   +note=60 +vel=80 +on=4 +off=96000 +ticks=120000
 *   +note2=64 +vel2=100 +on2=30000     second Note On on the same
 *                                      voice (voice stealing)
 *   +hammer=0                          mute the hammer slot
 *   +log=build/voice_log.txt           log file
 * ============================================================ */

module tb_piano_voice;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always #40.690 clk = ~clk;

/* 48 kHz sample tick: one clk pulse every 256 clk */
reg [7:0] div = 8'd0;
reg       sample_tick = 1'b0;

always @(posedge clk) begin
    div         <= div + 1'b1;
    sample_tick <= (div == 8'd255);
end

integer tick = -1;

always @(posedge clk)
    if (sample_tick)
        tick = tick + 1;


/* ------------------------------------------------------------
 * Stimulus
 * ------------------------------------------------------------ */

integer p_note, p_vel, p_on, p_off, p_ticks;
integer p_note2, p_vel2, p_on2;
integer p_hammer;

reg [8*200-1:0] log_name;

reg        start = 1'b0;
reg        stop  = 1'b0;
// No valid pitch before the first explicit NoteOn stimulus.
reg [6:0]  note_in = 7'bx;
reg [7:0]  vel_in  = 8'd0;

wire [31:0] phase_inc;

note_freq_table #(
    .SAMPLE_RATE (48000)
) u_freq (
    .midi_note (note_in),
    .phase_inc (phase_inc)
);

wire        ld_busy;
wire        ld_ready;
wire        ld_we;
wire [8:0]  ld_addr;
wire [31:0] ld_data;
wire        ld_done;
wire [21:0] ld_rel_slope;

piano_note_loader #(
    .VOICES (1),
    .IDX_W  (1)
) u_loader (
    .clk          (clk),
    .rst_n        (rst_n),
    .req_valid    (start),
    .req_voice    (1'b0),
    .req_note     (note_in),
    .req_velocity (vel_in),
    .req_inc0     (phase_inc),
    .busy         (ld_busy),
    .voice_ready  (ld_ready),
    .ld_we        (ld_we),
    .ld_addr      (ld_addr),
    .ld_data      (ld_data),
    .ld_done      (ld_done),
    .ld_rel_slope (ld_rel_slope)
);

wire               active;
wire               releasing;
wire [23:0]        env_level;
wire [6:0]         note;
wire [31:0]        voice_inc;
wire signed [23:0] sample;
wire               strobe;
wire               dbg_rel;
wire               dbg_fade;
wire               dbg_overrun;

reg hammer_enable = 1'b1;

piano_partial_voice #(
    .NOISE_SEED (16'hACE1)
) u_voice (
    .clk               (clk),
    .rst_n             (rst_n),
    .sample_tick       (sample_tick),
    .start             (start),
    .stop              (stop),
    .phase_inc_in      (phase_inc),
    .note_in           (note_in),
    .velocity_in       (vel_in),
    .waveform_in       (2'd3),
    .morph_enable      (1'b0),
    .morph_in          (10'd0),
    .ld_ready          (ld_ready),
    .ld_we             (ld_we),
    .ld_addr           (ld_addr),
    .ld_data           (ld_data),
    .ld_done           (ld_done),
    .ld_rel_slope      (ld_rel_slope),
    .hammer_enable     (hammer_enable),
    .active            (active),
    .releasing         (releasing),
    .env_level         (env_level),
    .note              (note),
    .phase_inc         (voice_inc),
    .sample            (sample),
    .dbg_sample_strobe (strobe),
    .dbg_rel           (dbg_rel),
    .dbg_fade          (dbg_fade),
    .dbg_overrun       (dbg_overrun)
);


/* ------------------------------------------------------------
 * Log
 * ------------------------------------------------------------ */

integer fd;
integer load_cycles = 0;
integer max_load_cycles = 0;
integer busy_cycles = 0;
integer max_busy_cycles = 0;
integer x_count = 0;

always @(posedge clk) begin

    if (rst_n) begin

        if (ld_done)
            $fdisplay(fd, "L %0d %0d %0d", tick, note_in, vel_in);

        if (strobe) begin
            $fdisplay(fd, "S %0d %0d %0d %0d", tick, sample, dbg_rel, dbg_fade);
            if (^sample === 1'bx)
                x_count = x_count + 1;
        end

        /* how long the loader keeps the event path busy */
        if (ld_busy) begin
            load_cycles = load_cycles + 1;
        end
        else begin
            if (load_cycles > max_load_cycles)
                max_load_cycles = load_cycles;
            load_cycles = 0;
        end

        /* clk cycles the engine needs per sample */
        if (u_voice.eng != 2'd0) begin
            busy_cycles = busy_cycles + 1;
        end
        else begin
            if (busy_cycles > max_busy_cycles)
                max_busy_cycles = busy_cycles;
            busy_cycles = 0;
        end

    end

end

/*
 * The tasks are called from parallel fork branches, so they must be
 * automatic: a static task would share its argument between the calls.
 */
task automatic note_on;
    input [6:0] n;
    input [7:0] v;
    begin
        @(negedge clk);
        note_in = n;
        vel_in  = v;
        start   = 1'b1;
        @(negedge clk);
        start   = 1'b0;
    end
endtask

task automatic wait_tick;
    input integer t;
    begin
        while (tick < t)
            @(posedge clk);
    end
endtask

initial begin

    if (!$value$plusargs("note=%d",  p_note))   p_note  = 60;
    if (!$value$plusargs("vel=%d",   p_vel))    p_vel   = 80;
    if (!$value$plusargs("on=%d",    p_on))     p_on    = 4;
    if (!$value$plusargs("off=%d",   p_off))    p_off   = 96000;
    if (!$value$plusargs("ticks=%d", p_ticks))  p_ticks = 120000;
    if (!$value$plusargs("note2=%d", p_note2))  p_note2 = -1;
    if (!$value$plusargs("vel2=%d",  p_vel2))   p_vel2  = 100;
    if (!$value$plusargs("on2=%d",   p_on2))    p_on2   = -1;
    if (!$value$plusargs("hammer=%d", p_hammer)) p_hammer = 1;

    hammer_enable = (p_hammer != 0);

    if (!$value$plusargs("log=%s", log_name))
        log_name = "build/voice_log.txt";

    fd = $fopen(log_name, "w");

    #(1000);
    rst_n = 1'b1;

    fork

        begin
            wait_tick(p_on);
            note_on(p_note[6:0], p_vel[7:0]);
        end

        begin
            if (p_on2 >= 0) begin
                wait_tick(p_on2);
                note_on(p_note2[6:0], p_vel2[7:0]);
            end
        end

        begin
            wait_tick(p_off);
            @(negedge clk);
            stop = 1'b1;
            @(negedge clk);
            stop = 1'b0;
        end

    join

    wait_tick(p_ticks);

    $fflush(fd);
    $fclose(fd);

    $display("loader busy: %0d clk per note", max_load_cycles);
    $display("engine: at most %0d clk per sample (256 available), overrun=%0d",
             max_busy_cycles, dbg_overrun);
    $display("samples with X: %0d", x_count);

    if (dbg_overrun || (x_count != 0))
        $display("FAIL");
    else
        $display("SIM DONE");

    $finish;

end

endmodule
