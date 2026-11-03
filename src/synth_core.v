
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
 input wire [6:0] expression_glide,expression_vibrato,
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
    output wire engine_initialized,

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
    output wire [95:0]                diagnostic_audio,
    output wire [VOICES*7-1:0] display_voice_notes,
    output wire [VOICES*16-1:0] display_env_levels,
    output wire [VOICES*3-1:0] display_env_phases,
    output wire [VOICES-1:0] display_env_valid,display_env_done,display_env_starts
);

localparam MIX_W = SAMPLE_W + LOG2_VOICES;

localparam signed [MIX_W-1:0] CLIP_MAX =
    {{(MIX_W-SAMPLE_W){1'b0}}, 1'b0, {(SAMPLE_W-1){1'b1}}};

localparam signed [MIX_W-1:0] CLIP_MIN =
    {{(MIX_W-SAMPLE_W){1'b1}}, 1'b1, {(SAMPLE_W-1){1'b0}}};

wire [VOICES*SAMPLE_W-1:0] samples;
wire [VOICES-1:0] piano_active;
wire [VOICES*7-1:0] piano_notes,aux_notes;
wire [VOICES*16-1:0] piano_env_levels,aux_env_levels;
wire [VOICES*3-1:0] piano_env_phases,aux_env_phases;
wire [VOICES-1:0] piano_env_valid,piano_env_done,piano_env_starts,aux_env_starts;
assign display_env_levels=auxiliary?aux_env_levels:piano_env_levels;
assign display_env_phases=auxiliary?aux_env_phases:piano_env_phases;
assign display_env_valid=auxiliary?{VOICES{sample_tick}}:piano_env_valid;
assign display_env_done=auxiliary?{VOICES{sample_tick}}:piano_env_done;
assign display_env_starts=auxiliary?aux_env_starts:piano_env_starts;
assign display_voice_notes=auxiliary?aux_notes:piano_notes;
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

reg [31:0] expression_lfo_phase;
reg [6:0] expression_last_note;reg expression_have_note;
wire expression_accept=bank_on && event_ready;
always @(posedge clk or negedge rst_n)
 if(!rst_n)begin expression_lfo_phase<=0;expression_last_note<=60;expression_have_note<=0;end
 else begin
  if(sample_tick)expression_lfo_phase<=expression_lfo_phase+32'd447392;
  if(expression_accept)begin expression_last_note<=bank_note;expression_have_note<=1;end
 end
wire signed [7:0] expression_triangle=expression_lfo_phase[31]?
 $signed({1'b0,~expression_lfo_phase[30:24]})-8'sd64:
 $signed({1'b0,expression_lfo_phase[30:24]})-8'sd64;
wire signed [15:0] expression_depth_product=expression_triangle*$signed({1'b0,expression_vibrato});
wire signed [7:0] expression_lfo=expression_vibrato==0?8'sd0:8'(expression_depth_product/16'sd100);
wire signed [8:0] expression_distance=$signed({2'b0,expression_last_note})-$signed({2'b0,bank_note});
reg [21:0] expression_seed;
wire signed [6:0] expression_seed_steps=(expression_have_note && expression_glide!=0 && expression_distance>=-9'sd60 && expression_distance<=9'sd60)?expression_distance[6:0]:7'sd0;
always @* begin
 expression_seed=22'd65536;
 if(expression_have_note && expression_glide!=0)case(expression_distance)
 -9'sd60:expression_seed=22'd2048;
 -9'sd59:expression_seed=22'd2170;
 -9'sd58:expression_seed=22'd2299;
 -9'sd57:expression_seed=22'd2435;
 -9'sd56:expression_seed=22'd2580;
 -9'sd55:expression_seed=22'd2734;
 -9'sd54:expression_seed=22'd2896;
 -9'sd53:expression_seed=22'd3069;
 -9'sd52:expression_seed=22'd3251;
 -9'sd51:expression_seed=22'd3444;
 -9'sd50:expression_seed=22'd3649;
 -9'sd49:expression_seed=22'd3866;
 -9'sd48:expression_seed=22'd4096;
 -9'sd47:expression_seed=22'd4340;
 -9'sd46:expression_seed=22'd4598;
 -9'sd45:expression_seed=22'd4871;
 -9'sd44:expression_seed=22'd5161;
 -9'sd43:expression_seed=22'd5468;
 -9'sd42:expression_seed=22'd5793;
 -9'sd41:expression_seed=22'd6137;
 -9'sd40:expression_seed=22'd6502;
 -9'sd39:expression_seed=22'd6889;
 -9'sd38:expression_seed=22'd7298;
 -9'sd37:expression_seed=22'd7732;
 -9'sd36:expression_seed=22'd8192;
 -9'sd35:expression_seed=22'd8679;
 -9'sd34:expression_seed=22'd9195;
 -9'sd33:expression_seed=22'd9742;
 -9'sd32:expression_seed=22'd10321;
 -9'sd31:expression_seed=22'd10935;
 -9'sd30:expression_seed=22'd11585;
 -9'sd29:expression_seed=22'd12274;
 -9'sd28:expression_seed=22'd13004;
 -9'sd27:expression_seed=22'd13777;
 -9'sd26:expression_seed=22'd14596;
 -9'sd25:expression_seed=22'd15464;
 -9'sd24:expression_seed=22'd16384;
 -9'sd23:expression_seed=22'd17358;
 -9'sd22:expression_seed=22'd18390;
 -9'sd21:expression_seed=22'd19484;
 -9'sd20:expression_seed=22'd20643;
 -9'sd19:expression_seed=22'd21870;
 -9'sd18:expression_seed=22'd23170;
 -9'sd17:expression_seed=22'd24548;
 -9'sd16:expression_seed=22'd26008;
 -9'sd15:expression_seed=22'd27554;
 -9'sd14:expression_seed=22'd29193;
 -9'sd13:expression_seed=22'd30929;
 -9'sd12:expression_seed=22'd32768;
 -9'sd11:expression_seed=22'd34716;
 -9'sd10:expression_seed=22'd36781;
 -9'sd9:expression_seed=22'd38968;
 -9'sd8:expression_seed=22'd41285;
 -9'sd7:expression_seed=22'd43740;
 -9'sd6:expression_seed=22'd46341;
 -9'sd5:expression_seed=22'd49097;
 -9'sd4:expression_seed=22'd52016;
 -9'sd3:expression_seed=22'd55109;
 -9'sd2:expression_seed=22'd58386;
 -9'sd1:expression_seed=22'd61858;
 9'sd0:expression_seed=22'd65536;
 9'sd1:expression_seed=22'd69433;
 9'sd2:expression_seed=22'd73562;
 9'sd3:expression_seed=22'd77936;
 9'sd4:expression_seed=22'd82570;
 9'sd5:expression_seed=22'd87480;
 9'sd6:expression_seed=22'd92682;
 9'sd7:expression_seed=22'd98193;
 9'sd8:expression_seed=22'd104032;
 9'sd9:expression_seed=22'd110218;
 9'sd10:expression_seed=22'd116772;
 9'sd11:expression_seed=22'd123715;
 9'sd12:expression_seed=22'd131072;
 9'sd13:expression_seed=22'd138866;
 9'sd14:expression_seed=22'd147123;
 9'sd15:expression_seed=22'd155872;
 9'sd16:expression_seed=22'd165140;
 9'sd17:expression_seed=22'd174960;
 9'sd18:expression_seed=22'd185364;
 9'sd19:expression_seed=22'd196386;
 9'sd20:expression_seed=22'd208064;
 9'sd21:expression_seed=22'd220436;
 9'sd22:expression_seed=22'd233544;
 9'sd23:expression_seed=22'd247431;
 9'sd24:expression_seed=22'd262144;
 9'sd25:expression_seed=22'd277732;
 9'sd26:expression_seed=22'd294247;
 9'sd27:expression_seed=22'd311744;
 9'sd28:expression_seed=22'd330281;
 9'sd29:expression_seed=22'd349920;
 9'sd30:expression_seed=22'd370728;
 9'sd31:expression_seed=22'd392772;
 9'sd32:expression_seed=22'd416128;
 9'sd33:expression_seed=22'd440872;
 9'sd34:expression_seed=22'd467088;
 9'sd35:expression_seed=22'd494862;
 9'sd36:expression_seed=22'd524288;
 9'sd37:expression_seed=22'd555464;
 9'sd38:expression_seed=22'd588493;
 9'sd39:expression_seed=22'd623487;
 9'sd40:expression_seed=22'd660561;
 9'sd41:expression_seed=22'd699841;
 9'sd42:expression_seed=22'd741455;
 9'sd43:expression_seed=22'd785544;
 9'sd44:expression_seed=22'd832255;
 9'sd45:expression_seed=22'd881744;
 9'sd46:expression_seed=22'd934175;
 9'sd47:expression_seed=22'd989724;
 9'sd48:expression_seed=22'd1048576;
 9'sd49:expression_seed=22'd1110928;
 9'sd50:expression_seed=22'd1176987;
 9'sd51:expression_seed=22'd1246974;
 9'sd52:expression_seed=22'd1321123;
 9'sd53:expression_seed=22'd1399681;
 9'sd54:expression_seed=22'd1482910;
 9'sd55:expression_seed=22'd1571089;
 9'sd56:expression_seed=22'd1664511;
 9'sd57:expression_seed=22'd1763488;
 9'sd58:expression_seed=22'd1868350;
 9'sd59:expression_seed=22'd1979448;
 9'sd60:expression_seed=22'd2097152;
 default:expression_seed=22'd65536;endcase
end
generate if(REMOTE_ENABLE!=0)begin:G_AUX
 wire valid, rejected;wire [VOICES-1:0] overruns,clips;
 yinse_aux_bank #(.VOICES(VOICES),.MIX_SHIFT(3)) bank(
 .clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),.all_notes_off(test_disable_pulse),
 .expression_glide(expression_glide),.expression_seed(expression_seed),.expression_seed_steps(expression_seed_steps),.expression_lfo(expression_lfo),
 .event_valid(auxiliary && (bank_on || bank_off)),.event_note_on(bank_on),
 .instrument_id(instrument_id),.event_note(bank_note),.event_velocity(bank_velocity),
 .event_ready(aux_ready),.pcm(aux_pcm),.pcm_valid(valid),.active_mask(aux_active),
 .overrun_mask(overruns),.clipped_mask(clips),.rejected(rejected),.display_voice_notes(aux_notes),.display_env_levels(aux_env_levels),.display_env_phases(aux_env_phases),.display_env_starts(aux_env_starts));
end else begin:G_NO_AUX
 assign aux_env_levels=0;assign aux_env_phases=0;assign aux_env_starts=0;
 assign aux_ready=0;assign aux_pcm=0;assign aux_active=0;assign aux_notes=0;
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
 .expression_glide(expression_glide),.expression_vibrato(expression_vibrato),
    .clk              (clk),
    .rst_n            (rst_n),
    .sample_tick      (sample_tick),
    .expression_seed(expression_seed),.expression_seed_steps(expression_seed_steps),.expression_lfo(expression_lfo),
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
    .diagnostic_counts(diagnostic_counts),.display_voice_notes(piano_notes),.display_env_levels(piano_env_levels),.display_env_phases(piano_env_phases),
    .display_env_valid(piano_env_valid),.display_env_done(piano_env_done),.display_env_starts(piano_env_starts)
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
            .initialized(engine_initialized),
            .out_sample        (fx_out)
        );

        assign audio_out = fx_out;

    end

    else begin : G_NO_FX

        assign audio_out = sat_out;
        assign engine_initialized=rst_n;

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
