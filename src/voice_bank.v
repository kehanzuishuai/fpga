module voice_bank #(
    parameter VOICES      = 32,
    parameter SAMPLE_W    = 24,
    parameter AGE_W       = 32,
    parameter SAMPLE_RATE = 48000,
    parameter IDX_W       = 5,

    /*
     * 1: piano_partial_voice (AMY style partials) + piano_note_loader
     * 0: the previous voice.v (dual wavetable piano), kept for A/B
     *    comparison and as the way back
     */
    parameter PIANO_ENGINE = 1
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,

    input                              note_on,
    input                              note_off,
    input                              all_notes_off,

    input      [6:0]                   midi_note,
    input      [7:0]                   velocity,
    input      [1:0]                   waveform,

    input                              morph_enable,
    input      [9:0]                   morph,

    /* 0: hammer noise muted (only with PIANO_ENGINE = 1) */
    input                              hammer_enable,

    /*
     * 0 while the note loader fills a voice (about 0.2 ms per note).
     * The Note FIFO must only deliver an event when this is 1.
     */
    output                             event_ready,

    output     [VOICES*SAMPLE_W-1:0]   voice_samples,
    output     [VOICES-1:0]            voice_active,

    output reg                         allocation_valid,
    output reg [IDX_W-1:0]             allocation_index,
    // Reset-scoped modulo-65536 counters, driven by real control edges.
    output wire [47:0]                 diagnostic_counts,
    output wire [VOICES*7-1:0] display_voice_notes
);


wire [31:0] phase_inc;

wire [VOICES*7-1:0] notes;
assign display_voice_notes=notes;

reg [VOICES-1:0] starts;
reg [VOICES-1:0] stops;

wire [VOICES-1:0]
    voice_releasing;

wire [VOICES*SAMPLE_W-1:0]
    voice_env_levels;


/* ============================================================
 * MIDI -> phase increment
 * ============================================================ */

note_freq_table #(
    .SAMPLE_RATE(SAMPLE_RATE)
) u_note_freq_table (

    .midi_note
        (midi_note),

    .phase_inc
        (phase_inc)

);


/* ============================================================
 * New timing-oriented allocator
 * ============================================================ */

wire [IDX_W-1:0] chosen;
wire             grant;

/*
 * A Note On is only taken while the note loader is free.
 * With PIANO_ENGINE = 0 there is no loader and ld_busy is 0.
 */
wire             ld_busy;
wire             note_on_acc;

assign note_on_acc = note_on && !ld_busy;

assign event_ready = !ld_busy;

wire             unused_steal;

wire [IDX_W-1:0]
    unused_note_off_index;


voice_allocator #(
    .VOICES  (VOICES),
    .AGE_W   (AGE_W),
    .ENV_W   (SAMPLE_W),
    .INDEX_W (IDX_W)
) u_voice_allocator (

    .clk
        (clk),

    .rst_n
        (rst_n),

    .request_valid
        (note_on_acc),

    .active
        (voice_active),

    .releasing
        (voice_releasing),

    .ages
        ({(VOICES*AGE_W){1'b0}}),

    .env_levels
        (voice_env_levels),

    .grant_valid
        (grant),

    .grant_index
        (chosen),

    .steal
        (unused_steal),

    .note_off_index
        (unused_note_off_index)

);


/* ============================================================
 * Debug allocation output
 * ============================================================ */

always @(*) begin

    allocation_valid =
        note_on_acc &&
        grant;

    allocation_index =
        chosen;

end


/* ============================================================
 * Note-Off matching
 * ============================================================ */

wire [31:0] note_match_mask;


genvar m;

generate

    for (
        m = 0;
        m < 32;
        m = m + 1
    ) begin : GEN_NOTE_MATCH

        assign note_match_mask[m] =

            voice_active[m]

            &&

            !voice_releasing[m]

            &&

            (
                notes[
                    m*7
                    +: 7
                ]
                ==
                midi_note
            );

    end

endgenerate


/* ============================================================
 * Small priority encoder
 * ============================================================ */

function [2:0] first_one8;

    input [7:0] value;

    begin

        if      (value[0]) first_one8 = 3'd0;
        else if (value[1]) first_one8 = 3'd1;
        else if (value[2]) first_one8 = 3'd2;
        else if (value[3]) first_one8 = 3'd3;
        else if (value[4]) first_one8 = 3'd4;
        else if (value[5]) first_one8 = 3'd5;
        else if (value[6]) first_one8 = 3'd6;
        else               first_one8 = 3'd7;

    end

endfunction


reg             match_found;
reg [IDX_W-1:0] match_index;


always @(*) begin

    match_found =
        1'b0;

    match_index =
        {IDX_W{1'b0}};


    if (|note_match_mask[7:0]) begin

        match_found =
            1'b1;

        match_index =
            {2'b00,
             first_one8(note_match_mask[7:0])};

    end

    else if (|note_match_mask[15:8]) begin

        match_found =
            1'b1;

        match_index =
            {2'b01,
             first_one8(note_match_mask[15:8])};

    end

    else if (|note_match_mask[23:16]) begin

        match_found =
            1'b1;

        match_index =
            {2'b10,
             first_one8(note_match_mask[23:16])};

    end

    else if (|note_match_mask[31:24]) begin

        match_found =
            1'b1;

        match_index =
            {2'b11,
             first_one8(note_match_mask[31:24])};

    end

end


/* ============================================================
 * START / STOP
 * ============================================================ */

always @(*) begin

    starts =
        {VOICES{1'b0}};

    stops =
        {VOICES{1'b0}};


    if (
        note_on_acc &&
        grant
    ) begin

        starts[chosen] =
            1'b1;

    end


    if (all_notes_off) begin

        stops =
            voice_active;

    end

    else if (
        note_off &&
        match_found
    ) begin

        stops[match_index] =
            1'b1;

    end

end


/* ============================================================
 * 32 independent voices
 * ============================================================ */

genvar g;

generate

if (PIANO_ENGINE != 0) begin : G_PARTIAL

    /* --------------------------------------------------------
     * One note loader for all voices
     * -------------------------------------------------------- */

    wire [VOICES-1:0] voice_ld_ready;
    wire [VOICES-1:0] ld_we;
    wire [VOICES-1:0] ld_done;
    wire [8:0]        ld_addr;
    wire [31:0]       ld_data;
    wire [21:0]       ld_rel_slope;
    reg [15:0] diag_alloc,diag_loaded,diag_play;
    assign diagnostic_counts={diag_play,diag_loaded,diag_alloc};
    always @(posedge clk or negedge rst_n)
    if(!rst_n)begin diag_alloc<=0;diag_loaded<=0;diag_play<=0;end
    else begin
        if(note_on_acc && grant)diag_alloc<=diag_alloc+1'b1;
        if(|ld_done)diag_loaded<=diag_loaded+1'b1;
        // ld_ready means V_LOAD && engine idle; the same edge enters V_PLAY.
        if(|(ld_done & voice_ld_ready))diag_play<=diag_play+1'b1;
    end

    piano_note_loader #(
        .VOICES (VOICES),
        .IDX_W  (IDX_W)
    ) u_note_loader (

        .clk
            (clk),

        .rst_n
            (rst_n),

        .req_valid
            (note_on_acc && grant),

        .req_voice
            (chosen),

        .req_note
            (midi_note),

        .req_velocity
            (velocity),

        .req_inc0
            (phase_inc),

        .busy
            (ld_busy),

        .voice_ready
            (voice_ld_ready),

        .ld_we
            (ld_we),

        .ld_addr
            (ld_addr),

        .ld_data
            (ld_data),

        .ld_done
            (ld_done),

        .ld_rel_slope
            (ld_rel_slope)

    );


    for (
        g = 0;
        g < VOICES;
        g = g + 1
    ) begin : G_VOICE

        wire [31:0]
            unused_inc;

        wire
            unused_strobe;

        wire
            unused_rel;

        wire
            unused_fade;

        wire
            unused_overrun;


        // Fixed measured gain follows each raw voice; keep the old note's
        // coefficient during fade and commit only after the new loader finishes.
        wire signed [SAMPLE_W-1:0] raw_sample;
        piano_note_gain #(.SAMPLE_W(SAMPLE_W)) u_note_gain (
            .clk(clk), .rst_n(rst_n), .start(starts[g]),
            .note_in(midi_note), .load_done(ld_done[g]),
            .sample_in(raw_sample),
            .sample_out(voice_samples[g*SAMPLE_W +: SAMPLE_W])
        );

        piano_partial_voice #(
            .SAMPLE_W   (SAMPLE_W),
            .NOISE_SEED (16'hACE1 ^ (g * 16'h0101))
        ) u_voice (

            .clk
                (clk),

            .rst_n
                (rst_n),

            .sample_tick
                (sample_tick),

            .start
                (starts[g]),

            .stop
                (stops[g]),

            .phase_inc_in
                (phase_inc),

            .note_in
                (midi_note),

            .velocity_in
                (velocity),

            .waveform_in
                (waveform),

            .morph_enable
                (morph_enable),

            .morph_in
                (morph),

            .ld_ready
                (voice_ld_ready[g]),

            .ld_we
                (ld_we[g]),

            .ld_addr
                (ld_addr),

            .ld_data
                (ld_data),

            .ld_done
                (ld_done[g]),

            .ld_rel_slope
                (ld_rel_slope),

            .hammer_enable
                (hammer_enable),

            .active
                (voice_active[g]),

            .releasing
                (voice_releasing[g]),

            .env_level
                (
                    voice_env_levels[
                        g*SAMPLE_W
                        +: SAMPLE_W
                    ]
                ),

            .note
                (
                    notes[
                        g*7
                        +: 7
                    ]
                ),

            .phase_inc
                (unused_inc),

            .sample
                (
                    raw_sample
                ),

            .dbg_sample_strobe
                (unused_strobe),

            .dbg_rel
                (unused_rel),

            .dbg_fade
                (unused_fade),

            .dbg_overrun
                (unused_overrun)

        );

    end

end

else begin : G_LEGACY

    assign ld_busy = 1'b0;
    assign diagnostic_counts = 48'd0;

    for (
        g = 0;
        g < VOICES;
        g = g + 1
    ) begin : G_VOICE

        wire [31:0]
            unused_inc;


        voice #(
            .SAMPLE_W(SAMPLE_W)
        ) u_voice (

            .clk
                (clk),

            .rst_n
                (rst_n),

            .sample_tick
                (sample_tick),

            .start
                (starts[g]),

            .stop
                (stops[g]),

            .phase_inc_in
                (phase_inc),

            .note_in
                (midi_note),

            .velocity_in
                (velocity),

            .waveform_in
                (waveform),

            .morph_enable
                (morph_enable),

            .morph_in
                (morph),

            .active
                (voice_active[g]),

            .releasing
                (voice_releasing[g]),

            .env_level
                (
                    voice_env_levels[
                        g*SAMPLE_W
                        +: SAMPLE_W
                    ]
                ),

            .note
                (
                    notes[
                        g*7
                        +: 7
                    ]
                ),

            .phase_inc
                (unused_inc),

            .sample
                (
                    voice_samples[
                        g*SAMPLE_W
                        +: SAMPLE_W
                    ]
                )

        );

    end

end

endgenerate


endmodule
