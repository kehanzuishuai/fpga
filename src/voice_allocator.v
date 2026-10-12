module voice_allocator #(
    parameter VOICES  = 32,
    parameter AGE_W   = 32,
    parameter ENV_W   = 24,
    parameter INDEX_W = 5
)(
    input                              clk,
    input                              rst_n,

    input                              request_valid,

    input      [VOICES-1:0]            active,
    input      [VOICES-1:0]            releasing,

    input      [VOICES*AGE_W-1:0]      ages,
    input      [VOICES*ENV_W-1:0]      env_levels,

    output reg                         grant_valid,
    output reg [INDEX_W-1:0]           grant_index,

    output reg                         steal,
    output reg [INDEX_W-1:0]           note_off_index
);


/*
 * Timing optimized for this project's fixed 32-voice architecture.
 *
 * Voice audio processing is still fully parallel.
 */

wire [31:0] active_32;
wire [31:0] releasing_32;

assign active_32 =
    active[31:0];

assign releasing_32 =
    releasing[31:0];


wire [31:0] free_mask;
wire [31:0] release_mask;


assign free_mask =
    ~active_32;

assign release_mask =
    active_32 &
    releasing_32;


/* ============================================================
 * Small 8-way encoder
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


/* ============================================================
 * 4 groups x 8 voices
 * ============================================================ */

reg               free_found;
reg [INDEX_W-1:0] free_index;

reg               release_found;
reg [INDEX_W-1:0] release_index;


always @(*) begin

    free_found =
        1'b0;

    free_index =
        {INDEX_W{1'b0}};


    if (|free_mask[7:0]) begin

        free_found =
            1'b1;

        free_index =
            {2'b00, first_one8(free_mask[7:0])};

    end
    else if (|free_mask[15:8]) begin

        free_found =
            1'b1;

        free_index =
            {2'b01, first_one8(free_mask[15:8])};

    end
    else if (|free_mask[23:16]) begin

        free_found =
            1'b1;

        free_index =
            {2'b10, first_one8(free_mask[23:16])};

    end
    else if (|free_mask[31:24]) begin

        free_found =
            1'b1;

        free_index =
            {2'b11, first_one8(free_mask[31:24])};

    end


    release_found =
        1'b0;

    release_index =
        {INDEX_W{1'b0}};


    if (|release_mask[7:0]) begin

        release_found =
            1'b1;

        release_index =
            {2'b00, first_one8(release_mask[7:0])};

    end
    else if (|release_mask[15:8]) begin

        release_found =
            1'b1;

        release_index =
            {2'b01, first_one8(release_mask[15:8])};

    end
    else if (|release_mask[23:16]) begin

        release_found =
            1'b1;

        release_index =
            {2'b10, first_one8(release_mask[23:16])};

    end
    else if (|release_mask[31:24]) begin

        release_found =
            1'b1;

        release_index =
            {2'b11, first_one8(release_mask[31:24])};

    end

end


/* ============================================================
 * Round-robin steal
 * ============================================================ */

reg [INDEX_W-1:0] steal_ptr;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        steal_ptr <=
            {INDEX_W{1'b0}};

    end

    else if (
        request_valid &&
        !free_found &&
        !release_found
    ) begin

        steal_ptr <=
            steal_ptr + 1'b1;

    end

end


/* ============================================================
 * Final grant
 * ============================================================ */

always @(*) begin

    grant_valid =
        request_valid;

    grant_index =
        {INDEX_W{1'b0}};

    steal =
        1'b0;

    note_off_index =
        {INDEX_W{1'b0}};


    if (request_valid) begin

        if (free_found) begin

            grant_index =
                free_index;

        end

        else if (release_found) begin

            grant_index =
                release_index;

            steal =
                1'b1;

        end

        else begin

            grant_index =
                steal_ptr;

            steal =
                1'b1;

        end

    end

end


/*
 * ages / env_levels are intentionally retained only for
 * interface compatibility.
 *
 * They no longer participate in the critical allocation path.
 */

endmodule