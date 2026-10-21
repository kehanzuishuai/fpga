
module synth_core #(
    parameter REMOTE_ENABLE = 0,
    parameter SAMPLE_RATE        = 48000,
    parameter SAMPLE_W           = 24,
    parameter VOICES             = 32,
    parameter MASTER_ATTEN_SHIFT = 0,
    parameter IDX_W              = 5,
    parameter LOG2_VOICES        = 5,
    parameter COUNT_W            = LOG2_VOICES + 1,
    parameter MORPH_STEP         = 10'd4,
    parameter TEST_VELOCITY      = 8'd100,

    /* 1: AMY style partial engine, 0: previous wavetable voice */
    parameter PIANO_ENGINE       = 1,

    /*
     * 1: mix gain = 1 / (number of active voices)  (previous behaviour)
     * 0: constant mix gain.  A held note no longer gets quieter when
     *    another key goes down.
     */
    parameter POLY_NORMALIZE     = 0,

    /*
     * 1: mix -> piano_fx (soundboard, reverb, EQ, limiter) -> audio_out
     * 0: mix -> saturator -> audio_out  (previous chain)
     */
    parameter FX_ENABLE          = 1,

    /* piano_fx output gain before its limiter: 0 = x1, 1 = x2 */
    parameter FX_GAIN_SHIFT      = 1
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,
    input [2:0] instrument_id,

    input                              note_on,
    input                              note_off,
    input      [6:0]                   midi_note,
    input      [7:0]                   velocity,
    input      [1:0]                   waveform,

    /* Continuous-control plane */
    input                              morph_enable,
    input      [9:0]                   morph,

    input                              test_enable,

    /* 0: hammer noise muted (A/B comparison) */
    input                              hammer_enable,

    /*
     * Effects after the mix (piano_fx.v):
     *   bit 0    soundboard resonance on
     *   bit 1    reverb on
     *   bit 3:2  EQ preset, 0 natural, 1 warm, 2 bright
     *   bit 4    1 soft limiter, 0 plain clipping
     */
    input      [4:0]                   fx_ctrl,

    /* 0: the voice bank can not take a Note Event in this clk cycle */
    output                             event_ready,

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
    output wire [95:0]                diagnostic_audio
);

localparam MIX_W = SAMPLE_W + LOG2_VOICES;

localparam signed [MIX_W-1:0] CLIP_MAX =
    {{(MIX_W-SAMPLE_W){1'b0}}, 1'b0, {(SAMPLE_W-1){1'b1}}};

localparam signed [MIX_W-1:0] CLIP_MIN =
    {{(MIX_W-SAMPLE_W){1'b1}}, 1'b1, {(SAMPLE_W-1){1'b0}}};

wire [VOICES*SAMPLE_W-1:0] samples;
wire [VOICES-1:0] piano_active;
wire piano_ready,aux_ready;
wire signed [23:0] aux_pcm;
wire [VOICES-1:0] aux_active;
wire auxiliary=REMOTE_ENABLE!=0 && instrument_id!=0;
assign active_debug=auxiliary?aux_active:piano_active;
assign event_ready=auxiliary?aux_ready:piano_ready;

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
wire [47:0] diagnostic_counts;
reg [23:0] diagnostic_mix_peak,diagnostic_fx_peak;
wire [SAMPLE_W-1:0] diagnostic_mix_abs=sat_out[SAMPLE_W-1] ? -sat_out : sat_out;
wire [SAMPLE_W-1:0] diagnostic_fx_abs=audio_out[SAMPLE_W-1] ? -audio_out : audio_out;
assign diagnostic_audio={diagnostic_fx_peak,diagnostic_mix_peak,diagnostic_counts};
always @(posedge clk or negedge rst_n)
if(!rst_n)begin diagnostic_mix_peak<=0;diagnostic_fx_peak<=0;end
else if(sample_tick)begin
 if(diagnostic_mix_abs>diagnostic_mix_peak)diagnostic_mix_peak<=diagnostic_mix_abs;
 if(diagnostic_fx_abs>diagnostic_fx_peak)diagnostic_fx_peak<=diagnostic_fx_abs;
end

generate if(REMOTE_ENABLE!=0)begin:G_AUX
 wire valid, rejected;wire [VOICES-1:0] overruns,clips;
 yinse_aux_bank #(.VOICES(VOICES),.MIX_SHIFT(3)) bank(
 .clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),.all_notes_off(test_disable_pulse),
 .event_valid(auxiliary && (bank_on || bank_off)),.event_note_on(bank_on),
 .instrument_id(instrument_id),.event_note(bank_note),.event_velocity(bank_velocity),
 .event_ready(aux_ready),.pcm(aux_pcm),.pcm_valid(valid),.active_mask(aux_active),
 .overrun_mask(overruns),.clipped_mask(clips),.rejected(rejected));
end else begin:G_NO_AUX
 assign aux_ready=0;assign aux_pcm=0;assign aux_active=0;
end endgenerate

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
    .IDX_W       (IDX_W),
    .PIANO_ENGINE(PIANO_ENGINE)
) u_bank (
    .clk              (clk),
    .rst_n            (rst_n),
    .sample_tick      (sample_tick),
    .note_on          (bank_on && !auxiliary),
    .note_off         (bank_off && !auxiliary),
    .all_notes_off    (test_disable_pulse),
    .midi_note        (bank_note),
    .velocity         (bank_velocity),
    .waveform         (bank_waveform),
    .morph_enable     (bank_morph_enable),
    .morph            (morph_smooth),
    .hammer_enable    (hammer_enable),
    .event_ready      (piano_ready),
    .voice_samples    (samples),
    .voice_active     (piano_active),
    .allocation_valid (allocation_valid),
    .allocation_index (allocation_index),
    .diagnostic_counts(diagnostic_counts)
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
    .MASTER_ATTEN_SHIFT (MASTER_ATTEN_SHIFT),
    .NORMALIZE          (POLY_NORMALIZE)
) u_gain (
    .clk                (clk),
    .rst_n              (rst_n),
    .sample_tick        (sample_tick),

    .mixed_in           (sum),
    .active_voice_count (active_voice_count),

    .scaled_out         (normalized_sum),
    .applied_shift      (mix_gain_shift)
);

/*
 * Output stage.
 *
 * The voices finish a sample up to 210 clk after sample_tick, so
 * the mix is taken at the next sample_tick, when all 32 voice
 * outputs are stable.  piano_fx needs about 15 clk; i2s_tx reads
 * audio_out 8 clk after sample_tick and therefore always sees a
 * value that has been stable for most of a sample period.
 */

wire signed [SAMPLE_W-1:0] sat_out;
wire signed [MIX_W-1:0] selected_sum=auxiliary?{{(MIX_W-24){aux_pcm[23]}},aux_pcm}:normalized_sum;

saturator #(
    .IN_W (MIX_W),
    .OUT_W(SAMPLE_W)
) u_sat (
    .in (selected_sum),
    .out(sat_out)
);

generate

    if (FX_ENABLE != 0) begin : G_FX

        wire               fx_valid;
        wire signed [23:0] fx_out;

        piano_fx #(
            .IN_W       (MIX_W),
            .GAIN_SHIFT (FX_GAIN_SHIFT)
        ) u_fx (
            .clk               (clk),
            .rst_n             (rst_n),
            .in_valid          (sample_tick),
            .in_sample         (selected_sum),
            .soundboard_enable (fx_ctrl[0] && !auxiliary),
            .reverb_enable     (fx_ctrl[1]),
            .eq_preset         (fx_ctrl[3:2]),
            .limiter_soft      (fx_ctrl[4]),
            .out_valid         (fx_valid),
            .out_sample        (fx_out)
        );

        assign audio_out = fx_out;

    end

    else begin : G_NO_FX

        assign audio_out = sat_out;

    end

endgenerate

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
