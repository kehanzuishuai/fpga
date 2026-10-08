
module synth_core #(
    parameter SAMPLE_RATE        = 48000,
    parameter SAMPLE_W           = 24,
    parameter VOICES             = 32,
    parameter MASTER_ATTEN_SHIFT = 0,
    parameter IDX_W              = 5,
    parameter LOG2_VOICES        = 5,
    parameter COUNT_W            = LOG2_VOICES + 1,
    parameter MORPH_STEP         = 10'd4,
    parameter TEST_VELOCITY      = 8'd100
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,

    input                              note_on,
    input                              note_off,
    input      [6:0]                   midi_note,
    input      [7:0]                   velocity,
    input      [1:0]                   waveform,

    /* Continuous-control plane */
    input                              morph_enable,
    input      [9:0]                   morph,

    input                              test_enable,

    output signed [SAMPLE_W-1:0]       audio_out,
    output     [VOICES-1:0]            active_debug,
    output     [COUNT_W-1:0]           active_voice_count,
    output     [SAMPLE_W-1:0]          audio_peak,
    output                             pcm_strobe,
    output signed [SAMPLE_W-1:0]       pcm_sample,
    output                             dbg_note_event,
    output                             dbg_audio_onset,
    output reg                         dbg_clip,
    output                             latency_valid,
    output     [23:0]                  latency_samples,
    output     [5:0]                   mix_gain_shift,
    output reg                         visual_sample_strobe,
    output reg signed [SAMPLE_W-1:0]   lissajous_x,
    output reg signed [SAMPLE_W-1:0]   lissajous_y,
    output signed [SAMPLE_W-1:0]       visual_voice_x,visual_voice_y
);

localparam MIX_W = SAMPLE_W + LOG2_VOICES;

localparam signed [MIX_W-1:0] CLIP_MAX =
    {{(MIX_W-SAMPLE_W){1'b0}}, 1'b0, {(SAMPLE_W-1){1'b1}}};

localparam signed [MIX_W-1:0] CLIP_MIN =
    {{(MIX_W-SAMPLE_W){1'b1}}, 1'b1, {(SAMPLE_W-1){1'b0}}};

wire [VOICES*SAMPLE_W-1:0] samples;
// Observe existing independent voices; no duplicate oscillator or state.
assign visual_voice_x=samples[0 +: SAMPLE_W];
generate if(VOICES>1)begin:visual_two_voices
assign visual_voice_y=samples[SAMPLE_W +: SAMPLE_W];
end else begin:visual_one_voice
assign visual_voice_y={SAMPLE_W{1'b0}};
end endgenerate
wire signed [MIX_W-1:0] sum;
wire signed [MIX_W-1:0] normalized_sum;

reg test_d;
reg test_enable_q;
reg [COUNT_W-1:0] test_count;
localparam [COUNT_W-1:0] TEST_VOICES = VOICES;

wire test_force;
wire [6:0] test_note;
wire test_disable_pulse;

reg       bank_on;
reg       bank_off;
reg [6:0] bank_note;
reg [7:0] bank_velocity;
reg [1:0] bank_waveform;
reg       bank_morph_enable;

wire morph_enable_s;
wire [9:0] morph_smooth;

wire allocation_valid;
wire [IDX_W-1:0] allocation_index;

assign test_disable_pulse = test_enable_q && !test_enable;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        test_enable_q <= 1'b0;
    else
        test_enable_q <= test_enable;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        test_d     <= 1'b0;
        test_count <= {COUNT_W{1'b0}};
    end
    else if (sample_tick) begin
        test_d <= test_enable;

        if (!test_enable)
            test_count <= {COUNT_W{1'b0}};
        else if (!test_d)
            test_count <= {{(COUNT_W-1){1'b0}}, 1'b1};
        else if (test_count < TEST_VOICES)
            test_count <= test_count + 1'b1;
    end
end

/*
 * Important: on the first sample_tick after test_enable rises, the old
 * test_count is still 0, so MIDI index 0 is injected before test_count
 * becomes 1. The original sequence therefore did NOT actually skip index 0.
 */
test_mode #(
    .VOICES(VOICES),
    .IDX_W (IDX_W)
) u_test_mode (
    .enable      (test_enable && (test_count < TEST_VOICES)),
    .index       (test_count[IDX_W-1:0]),
    .force_start (test_force),
    .midi_note   (test_note)
);

morph_control #(
    .STEP(MORPH_STEP)
) u_morph_control (
    .clk           (clk),
    .rst_n         (rst_n),
    .sample_tick   (sample_tick),
    .enable_target (morph_enable),
    .morph_target  (morph),
    .morph_enable  (morph_enable_s),
    .morph_value   (morph_smooth)
);

always @(*) begin
    bank_on           = note_on;
    bank_off          = note_off;
    bank_note         = midi_note;
    bank_velocity     = velocity;
    bank_waveform     = waveform;
    bank_morph_enable = morph_enable_s;

    /* Clean validation mode: fixed velocity, sine waveform, no morph. */
    if (test_force) begin
        bank_on           = sample_tick;
        bank_off          = 1'b0;
        bank_note         = test_note;
        bank_velocity     = TEST_VELOCITY;
        bank_waveform     = 2'd0;
        bank_morph_enable = 1'b0;
    end
end

voice_bank #(
    .VOICES      (VOICES),
    .SAMPLE_W    (SAMPLE_W),
    .SAMPLE_RATE (SAMPLE_RATE),
    .IDX_W       (IDX_W)
) u_bank (
    .clk              (clk),
    .rst_n            (rst_n),
    .sample_tick      (sample_tick),
    .note_on          (bank_on),
    .note_off         (bank_off),
    .all_notes_off    (test_disable_pulse),
    .midi_note        (bank_note),
    .velocity         (bank_velocity),
    .waveform         (bank_waveform),
    .morph_enable     (bank_morph_enable),
    .morph            (morph_smooth),
    .voice_samples    (samples),
    .voice_active     (active_debug),
    .allocation_valid (allocation_valid),
    .allocation_index (allocation_index)
);

tree_mixer #(
    .VOICES      (VOICES),
    .SAMPLE_W    (SAMPLE_W),
    .LOG2_VOICES (LOG2_VOICES)
) u_mixer (
    .samples(samples),
    .mixed  (sum)
);

polyphony_gain #(
    .SAMPLE_W           (SAMPLE_W),
    .LOG2_VOICES        (LOG2_VOICES),
    .MASTER_ATTEN_SHIFT (MASTER_ATTEN_SHIFT)
) u_gain (
    .clk                (clk),
    .rst_n              (rst_n),
    .sample_tick        (sample_tick),

    .mixed_in           (sum),
    .active_voice_count (active_voice_count),

    .scaled_out         (normalized_sum),
    .applied_shift      (mix_gain_shift)
);

saturator #(
    .IN_W (MIX_W),
    .OUT_W(SAMPLE_W)
) u_sat (
    .in (normalized_sum),
    .out(audio_out)
);

audio_telemetry #(
    .VOICES   (VOICES),
    .SAMPLE_W (SAMPLE_W),
    .COUNT_W  (COUNT_W)
) u_telemetry (
    .clk                (clk),
    .rst_n              (rst_n),
    .sample_tick        (sample_tick),
    .active_voices      (active_debug),
    .audio              (audio_out),
    .active_voice_count (active_voice_count),
    .audio_peak         (audio_peak),
    .pcm_strobe         (pcm_strobe),
    .pcm_sample         (pcm_sample)
);

latency_monitor #(
    .SAMPLE_W(SAMPLE_W),
    .COUNT_W (24),
    .VOICES  (VOICES),
    .IDX_W   (IDX_W)
) u_latency (
    .clk               (clk),
    .rst_n             (rst_n),
    .sample_tick       (sample_tick),
    .event_strobe      (allocation_valid),
    .event_voice_index (allocation_index),
    .voice_samples     (samples),
    .dbg_event         (dbg_note_event),
    .dbg_audio         (dbg_audio_onset),
    .latency_valid     (latency_valid),
    .latency_samples   (latency_samples)
);

always @(*) begin
    visual_sample_strobe = sample_tick;
    lissajous_x = audio_out;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        lissajous_y <= {SAMPLE_W{1'b0}};
    else if (sample_tick)
        lissajous_y <= audio_out;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dbg_clip <= 1'b0;
    else begin
        dbg_clip <= 1'b0;
        if (sample_tick && ((normalized_sum > CLIP_MAX) || (normalized_sum < CLIP_MIN)))
            dbg_clip <= 1'b1;
    end
end

endmodule
