module piano_dual_wavetable (
    input  wire              clk,
    input  wire [7:0]        addr,

    output reg signed [23:0] low_sample,
    output reg signed [23:0] high_sample
);

/*
 * Dual-layer synthetic piano wavetable
 *
 * LOW:
 *   fundamental + low harmonics
 *   forms the long-lived body of the note
 *
 * HIGH:
 *   upper harmonics
 *   forms hammer / brightness information
 *
 * Runtime:
 *   only ROM lookup
 *
 * Synchronous ROM also inserts a timing register boundary.
 */

always @(posedge clk) begin

    case (addr)

        8'd0:   begin low_sample <=  24'sd334849;  high_sample <= -24'sd497805;  end
        8'd1:   begin low_sample <=  24'sd690834;  high_sample <= -24'sd443554;  end
        8'd2:   begin low_sample <=  24'sd1042383; high_sample <= -24'sd398745;  end
        8'd3:   begin low_sample <=  24'sd1387266; high_sample <= -24'sd363912;  end
        8'd4:   begin low_sample <=  24'sd1723345; high_sample <= -24'sd336718;  end
        8'd5:   begin low_sample <=  24'sd2048595; high_sample <= -24'sd312895;  end
        8'd6:   begin low_sample <=  24'sd2361136; high_sample <= -24'sd287777;  end
        8'd7:   begin low_sample <=  24'sd2659249; high_sample <= -24'sd257890;  end
        8'd8:   begin low_sample <=  24'sd2941395; high_sample <= -24'sd222056;  end
        8'd9:   begin low_sample <=  24'sd3206236; high_sample <= -24'sd181653;  end
        8'd10:  begin low_sample <=  24'sd3452643; high_sample <= -24'sd139997;  end
        8'd11:  begin low_sample <=  24'sd3679708; high_sample <= -24'sd101096;  end
        8'd12:  begin low_sample <=  24'sd3886750; high_sample <= -24'sd68233;   end
        8'd13:  begin low_sample <=  24'sd4073317; high_sample <= -24'sd42865;   end
        8'd14:  begin low_sample <=  24'sd4239183; high_sample <= -24'sd24208;   end
        8'd15:  begin low_sample <=  24'sd4384349; high_sample <= -24'sd9605;    end

        8'd16:  begin low_sample <=  24'sd4509030; high_sample <=  24'sd4477;     end
        8'd17:  begin low_sample <=  24'sd4613645; high_sample <=  24'sd21193;    end
        8'd18:  begin low_sample <=  24'sd4698806; high_sample <=  24'sd42245;    end
        8'd19:  begin low_sample <=  24'sd4765299; high_sample <=  24'sd67361;    end
        8'd20:  begin low_sample <=  24'sd4814069; high_sample <=  24'sd94474;    end
        8'd21:  begin low_sample <=  24'sd4846195; high_sample <=  24'sd120522;   end
        8'd22:  begin low_sample <=  24'sd4862873; high_sample <=  24'sd142565;   end
        8'd23:  begin low_sample <=  24'sd4865392; high_sample <=  24'sd158665;   end
        8'd24:  begin low_sample <=  24'sd4855140; high_sample <=  24'sd169771;   end
        8'd25:  begin low_sample <=  24'sd4833591; high_sample <=  24'sd178792;   end
        8'd26:  begin low_sample <=  24'sd4802270; high_sample <=  24'sd189490;   end
        8'd27:  begin low_sample <=  24'sd4762703; high_sample <=  24'sd204028;   end
        8'd28:  begin low_sample <=  24'sd4716371; high_sample <=  24'sd221494;   end
        8'd29:  begin low_sample <=  24'sd4664664; high_sample <=  24'sd239691;   end
        8'd30:  begin low_sample <=  24'sd4608840; high_sample <=  24'sd255344;   end
        8'd31:  begin low_sample <=  24'sd4550004; high_sample <=  24'sd265570;   end

        8'd32:  begin low_sample <=  24'sd4489063; high_sample <=  24'sd269158;   end
        8'd33:  begin low_sample <=  24'sd4426715; high_sample <=  24'sd267550;   end
        8'd34:  begin low_sample <=  24'sd4363422; high_sample <=  24'sd264148;   end
        8'd35:  begin low_sample <=  24'sd4299440; high_sample <=  24'sd263025;   end
        8'd36:  begin low_sample <=  24'sd4234825; high_sample <=  24'sd267107;   end
        8'd37:  begin low_sample <=  24'sd4169506; high_sample <=  24'sd277767;   end
        8'd38:  begin low_sample <=  24'sd4103322; high_sample <=  24'sd294683;   end
        8'd39:  begin low_sample <=  24'sd4036057; high_sample <=  24'sd316875;   end
        8'd40:  begin low_sample <=  24'sd3967482; high_sample <=  24'sd343072;   end
        8'd41:  begin low_sample <=  24'sd3897412; high_sample <=  24'sd372240;   end
        8'd42:  begin low_sample <=  24'sd3825744; high_sample <=  24'sd403976;   end
        8'd43:  begin low_sample <=  24'sd3752512; high_sample <=  24'sd438658;   end
        8'd44:  begin low_sample <=  24'sd3677914; high_sample <=  24'sd477401;   end
        8'd45:  begin low_sample <=  24'sd3602323; high_sample <=  24'sd521799;   end
        8'd46:  begin low_sample <=  24'sd3526298; high_sample <=  24'sd573562;   end
        8'd47:  begin low_sample <=  24'sd3450548; high_sample <=  24'sd634050;   end

        8'd48:  begin low_sample <=  24'sd3375891; high_sample <=  24'sd704026;   end
        8'd49:  begin low_sample <=  24'sd3303206; high_sample <=  24'sd783589;   end
        8'd50:  begin low_sample <=  24'sd3233375; high_sample <=  24'sd872261;   end
        8'd51:  begin low_sample <=  24'sd3167227; high_sample <=  24'sd968952;   end
        8'd52:  begin low_sample <=  24'sd3105487; high_sample <=  24'sd1072403;  end
        8'd53:  begin low_sample <=  24'sd3048724; high_sample <=  24'sd1181332;  end
        8'd54:  begin low_sample <=  24'sd2997336; high_sample <=  24'sd1294467;  end
        8'd55:  begin low_sample <=  24'sd2951538; high_sample <=  24'sd1410661;  end
        8'd56:  begin low_sample <=  24'sd2911364; high_sample <=  24'sd1528910;  end
        8'd57:  begin low_sample <=  24'sd2876679; high_sample <=  24'sd1648344;  end
        8'd58:  begin low_sample <=  24'sd2847192; high_sample <=  24'sd1768243;  end
        8'd59:  begin low_sample <=  24'sd2822475; high_sample <=  24'sd1888044;  end
        8'd60:  begin low_sample <=  24'sd2801997; high_sample <=  24'sd2007358;  end
        8'd61:  begin low_sample <=  24'sd2785161; high_sample <=  24'sd2125943;  end
        8'd62:  begin low_sample <=  24'sd2771312; high_sample <=  24'sd2243662;  end
        8'd63:  begin low_sample <=  24'sd2759755; high_sample <=  24'sd2360389;  end

        8'd64:  begin low_sample <=  24'sd2749782; high_sample <=  24'sd2475990;  end
        8'd65:  begin low_sample <=  24'sd2740703; high_sample <=  24'sd2589979;  end
        8'd66:  begin low_sample <=  24'sd2731867; high_sample <=  24'sd2701420;  end
        8'd67:  begin low_sample <=  24'sd2722672; high_sample <=  24'sd2809069;  end
        8'd68:  begin low_sample <=  24'sd2712590; high_sample <=  24'sd2911608;  end
        8'd69:  begin low_sample <=  24'sd2701199; high_sample <=  24'sd3007863;  end
        8'd70:  begin low_sample <=  24'sd2688219; high_sample <=  24'sd3097020;  end
        8'd71:  begin low_sample <=  24'sd2673533; high_sample <=  24'sd3178791;  end
        8'd72:  begin low_sample <=  24'sd2657190; high_sample <=  24'sd3253498;  end
        8'd73:  begin low_sample <=  24'sd2639415; high_sample <=  24'sd3322112;  end
        8'd74:  begin low_sample <=  24'sd2620597; high_sample <=  24'sd3386208;  end
        8'd75:  begin low_sample <=  24'sd2601269; high_sample <=  24'sd3447790;  end
        8'd76:  begin low_sample <=  24'sd2582082; high_sample <=  24'sd3508921;  end
        8'd77:  begin low_sample <=  24'sd2563772; high_sample <=  24'sd3571297;  end
        8'd78:  begin low_sample <=  24'sd2547101; high_sample <=  24'sd3635923;  end
        8'd79:  begin low_sample <=  24'sd2532802; high_sample <=  24'sd3702871;  end

        8'd80:  begin low_sample <=  24'sd2521538; high_sample <=  24'sd3771120;  end
        8'd81:  begin low_sample <=  24'sd2513844; high_sample <=  24'sd3838513;  end
        8'd82:  begin low_sample <=  24'sd2510090; high_sample <=  24'sd3901843;  end
        8'd83:  begin low_sample <=  24'sd2510463; high_sample <=  24'sd3957064;  end
        8'd84:  begin low_sample <=  24'sd2514950; high_sample <=  24'sd3999610;  end
        8'd85:  begin low_sample <=  24'sd2523352; high_sample <=  24'sd4024804;  end
        8'd86:  begin low_sample <=  24'sd2535293; high_sample <=  24'sd4028354;  end
        8'd87:  begin low_sample <=  24'sd2550237; high_sample <=  24'sd4006773;  end
        8'd88:  begin low_sample <=  24'sd2567518; high_sample <=  24'sd3957809;  end
        8'd89:  begin low_sample <=  24'sd2586393; high_sample <=  24'sd3880709;  end
        8'd90:  begin low_sample <=  24'sd2606078; high_sample <=  24'sd3776349;  end
        8'd91:  begin low_sample <=  24'sd2625802; high_sample <=  24'sd3647305;  end
        8'd92:  begin low_sample <=  24'sd2644860; high_sample <=  24'sd3497786;  end
        8'd93:  begin low_sample <=  24'sd2662651; high_sample <=  24'sd3333370;  end
        8'd94:  begin low_sample <=  24'sd2678726; high_sample <=  24'sd3160646;  end
        8'd95:  begin low_sample <=  24'sd2692846; high_sample <=  24'sd2986657;  end

        8'd96:  begin low_sample <=  24'sd2704999; high_sample <=  24'sd2818298;  end
        8'd97:  begin low_sample <=  24'sd2715356; high_sample <=  24'sd2661748;  end
        8'd98:  begin low_sample <=  24'sd2724198; high_sample <=  24'sd2521920;  end
        8'd99:  begin low_sample <=  24'sd2731844; high_sample <=  24'sd2402069;  end
        8'd100: begin low_sample <=  24'sd2738599; high_sample <=  24'sd2303489;  end
        8'd101: begin low_sample <=  24'sd2744726; high_sample <=  24'sd2225403;  end
        8'd102: begin low_sample <=  24'sd2750422; high_sample <=  24'sd2165107;  end
        8'd103: begin low_sample <=  24'sd2755790; high_sample <=  24'sd2118239;  end
        8'd104: begin low_sample <=  24'sd2760834; high_sample <=  24'sd2079227;  end
        8'd105: begin low_sample <=  24'sd2765450; high_sample <=  24'sd2041906;  end
        8'd106: begin low_sample <=  24'sd2769447; high_sample <=  24'sd2000278;  end
        8'd107: begin low_sample <=  24'sd2772579; high_sample <=  24'sd1949180;  end
        8'd108: begin low_sample <=  24'sd2774575; high_sample <=  24'sd1884739;  end
        8'd109: begin low_sample <=  24'sd2775171; high_sample <=  24'sd1804643;  end
        8'd110: begin low_sample <=  24'sd2774138; high_sample <=  24'sd1708193;  end
        8'd111: begin low_sample <=  24'sd2771319; high_sample <=  24'sd1596215;  end

        8'd112: begin low_sample <=  24'sd2766654; high_sample <=  24'sd1470837;  end
        8'd113: begin low_sample <=  24'sd2760188; high_sample <=  24'sd1335013;  end
        8'd114: begin low_sample <=  24'sd2752072; high_sample <=  24'sd1192056;  end
        8'd115: begin low_sample <=  24'sd2742559; high_sample <=  24'sd1045158;  end
        8'd116: begin low_sample <=  24'sd2731990; high_sample <=  24'sd897036;   end
        8'd117: begin low_sample <=  24'sd2720775; high_sample <=  24'sd749833;   end
        8'd118: begin low_sample <=  24'sd2709358; high_sample <=  24'sd604363;   end
        8'd119: begin low_sample <=  24'sd2698180; high_sample <=  24'sd460780;   end
        8'd120: begin low_sample <=  24'sd2687657; high_sample <=  24'sd318837;   end
        8'd121: begin low_sample <=  24'sd2678142; high_sample <=  24'sd178058;   end
        8'd122: begin low_sample <=  24'sd2669893; high_sample <=  24'sd38292;    end
        8'd123: begin low_sample <=  24'sd2663035; high_sample <= -24'sd100199;   end
        8'd124: begin low_sample <=  24'sd2657538; high_sample <= -24'sd236467;   end
        8'd125: begin low_sample <=  24'sd2653211; high_sample <= -24'sd368992;   end
        8'd126: begin low_sample <=  24'sd2649717; high_sample <= -24'sd496275;   end
        8'd127: begin low_sample <=  24'sd2646581; high_sample <= -24'sd617018;   end

        8'd128: begin low_sample <= -24'sd334849;  high_sample <=  24'sd497805;   end
        8'd129: begin low_sample <= -24'sd690834;  high_sample <=  24'sd443554;   end
        8'd130: begin low_sample <= -24'sd1042383; high_sample <=  24'sd398745;   end
        8'd131: begin low_sample <= -24'sd1387266; high_sample <=  24'sd363912;   end
        8'd132: begin low_sample <= -24'sd1723345; high_sample <=  24'sd336718;   end
        8'd133: begin low_sample <= -24'sd2048595; high_sample <=  24'sd312895;   end
        8'd134: begin low_sample <= -24'sd2361136; high_sample <=  24'sd287777;   end
        8'd135: begin low_sample <= -24'sd2659249; high_sample <=  24'sd257890;   end
        8'd136: begin low_sample <= -24'sd2941395; high_sample <=  24'sd222056;   end
        8'd137: begin low_sample <= -24'sd3206236; high_sample <=  24'sd181653;   end
        8'd138: begin low_sample <= -24'sd3452643; high_sample <=  24'sd139997;   end
        8'd139: begin low_sample <= -24'sd3679708; high_sample <=  24'sd101096;   end
        8'd140: begin low_sample <= -24'sd3886750; high_sample <=  24'sd68233;    end
        8'd141: begin low_sample <= -24'sd4073317; high_sample <=  24'sd42865;    end
        8'd142: begin low_sample <= -24'sd4239183; high_sample <=  24'sd24208;    end
        8'd143: begin low_sample <= -24'sd4384349; high_sample <=  24'sd9605;     end

        8'd144: begin low_sample <= -24'sd4509030; high_sample <= -24'sd4477;     end
        8'd145: begin low_sample <= -24'sd4613645; high_sample <= -24'sd21193;    end
        8'd146: begin low_sample <= -24'sd4698806; high_sample <= -24'sd42245;    end
        8'd147: begin low_sample <= -24'sd4765299; high_sample <= -24'sd67361;    end
        8'd148: begin low_sample <= -24'sd4814069; high_sample <= -24'sd94474;    end
        8'd149: begin low_sample <= -24'sd4846195; high_sample <= -24'sd120522;   end
        8'd150: begin low_sample <= -24'sd4862873; high_sample <= -24'sd142565;   end
        8'd151: begin low_sample <= -24'sd4865392; high_sample <= -24'sd158665;   end
        8'd152: begin low_sample <= -24'sd4855140; high_sample <= -24'sd169771;   end
        8'd153: begin low_sample <= -24'sd4833591; high_sample <= -24'sd178792;   end
        8'd154: begin low_sample <= -24'sd4802270; high_sample <= -24'sd189490;   end
        8'd155: begin low_sample <= -24'sd4762703; high_sample <= -24'sd204028;   end
        8'd156: begin low_sample <= -24'sd4716371; high_sample <= -24'sd221494;   end
        8'd157: begin low_sample <= -24'sd4664664; high_sample <= -24'sd239691;   end
        8'd158: begin low_sample <= -24'sd4608840; high_sample <= -24'sd255344;   end
        8'd159: begin low_sample <= -24'sd4550004; high_sample <= -24'sd265570;   end

        8'd160: begin low_sample <= -24'sd4489063; high_sample <= -24'sd269158;   end
        8'd161: begin low_sample <= -24'sd4426715; high_sample <= -24'sd267550;   end
        8'd162: begin low_sample <= -24'sd4363422; high_sample <= -24'sd264148;   end
        8'd163: begin low_sample <= -24'sd4299440; high_sample <= -24'sd263025;   end
        8'd164: begin low_sample <= -24'sd4234825; high_sample <= -24'sd267107;   end
        8'd165: begin low_sample <= -24'sd4169506; high_sample <= -24'sd277767;   end
        8'd166: begin low_sample <= -24'sd4103322; high_sample <= -24'sd294683;   end
        8'd167: begin low_sample <= -24'sd4036057; high_sample <= -24'sd316875;   end
        8'd168: begin low_sample <= -24'sd3967482; high_sample <= -24'sd343072;   end
        8'd169: begin low_sample <= -24'sd3897412; high_sample <= -24'sd372240;   end
        8'd170: begin low_sample <= -24'sd3825744; high_sample <= -24'sd403976;   end
        8'd171: begin low_sample <= -24'sd3752512; high_sample <= -24'sd438658;   end
        8'd172: begin low_sample <= -24'sd3677914; high_sample <= -24'sd477401;   end
        8'd173: begin low_sample <= -24'sd3602323; high_sample <= -24'sd521799;   end
        8'd174: begin low_sample <= -24'sd3526298; high_sample <= -24'sd573562;   end
        8'd175: begin low_sample <= -24'sd3450548; high_sample <= -24'sd634050;   end

        8'd176: begin low_sample <= -24'sd3375891; high_sample <= -24'sd704026;   end
        8'd177: begin low_sample <= -24'sd3303206; high_sample <= -24'sd783589;   end
        8'd178: begin low_sample <= -24'sd3233375; high_sample <= -24'sd872261;   end
        8'd179: begin low_sample <= -24'sd3167227; high_sample <= -24'sd968952;   end
        8'd180: begin low_sample <= -24'sd3105487; high_sample <= -24'sd1072403;  end
        8'd181: begin low_sample <= -24'sd3048724; high_sample <= -24'sd1181332;  end
        8'd182: begin low_sample <= -24'sd2997336; high_sample <= -24'sd1294467;  end
        8'd183: begin low_sample <= -24'sd2951538; high_sample <= -24'sd1410661;  end
        8'd184: begin low_sample <= -24'sd2911364; high_sample <= -24'sd1528910;  end
        8'd185: begin low_sample <= -24'sd2876679; high_sample <= -24'sd1648344;  end
        8'd186: begin low_sample <= -24'sd2847192; high_sample <= -24'sd1768243;  end
        8'd187: begin low_sample <= -24'sd2822475; high_sample <= -24'sd1888044;  end
        8'd188: begin low_sample <= -24'sd2801997; high_sample <= -24'sd2007358;  end
        8'd189: begin low_sample <= -24'sd2785161; high_sample <= -24'sd2125943;  end
        8'd190: begin low_sample <= -24'sd2771312; high_sample <= -24'sd2243662;  end
        8'd191: begin low_sample <= -24'sd2759755; high_sample <= -24'sd2360389;  end

        8'd192: begin low_sample <= -24'sd2749782; high_sample <= -24'sd2475990;  end
        8'd193: begin low_sample <= -24'sd2740703; high_sample <= -24'sd2589979;  end
        8'd194: begin low_sample <= -24'sd2731867; high_sample <= -24'sd2701420;  end
        8'd195: begin low_sample <= -24'sd2722672; high_sample <= -24'sd2809069;  end
        8'd196: begin low_sample <= -24'sd2712590; high_sample <= -24'sd2911608;  end
        8'd197: begin low_sample <= -24'sd2701199; high_sample <= -24'sd3007863;  end
        8'd198: begin low_sample <= -24'sd2688219; high_sample <= -24'sd3097020;  end
        8'd199: begin low_sample <= -24'sd2673533; high_sample <= -24'sd3178791;  end
        8'd200: begin low_sample <= -24'sd2657190; high_sample <= -24'sd3253498;  end
        8'd201: begin low_sample <= -24'sd2639415; high_sample <= -24'sd3322112;  end
        8'd202: begin low_sample <= -24'sd2620597; high_sample <= -24'sd3386208;  end
        8'd203: begin low_sample <= -24'sd2601269; high_sample <= -24'sd3447790;  end
        8'd204: begin low_sample <= -24'sd2582082; high_sample <= -24'sd3508921;  end
        8'd205: begin low_sample <= -24'sd2563772; high_sample <= -24'sd3571297;  end
        8'd206: begin low_sample <= -24'sd2547101; high_sample <= -24'sd3635923;  end
        8'd207: begin low_sample <= -24'sd2532802; high_sample <= -24'sd3702871;  end

        8'd208: begin low_sample <= -24'sd2521538; high_sample <= -24'sd3771120;  end
        8'd209: begin low_sample <= -24'sd2513844; high_sample <= -24'sd3838513;  end
        8'd210: begin low_sample <= -24'sd2510090; high_sample <= -24'sd3901843;  end
        8'd211: begin low_sample <= -24'sd2510463; high_sample <= -24'sd3957064;  end
        8'd212: begin low_sample <= -24'sd2514950; high_sample <= -24'sd3999610;  end
        8'd213: begin low_sample <= -24'sd2523352; high_sample <= -24'sd4024804;  end
        8'd214: begin low_sample <= -24'sd2535293; high_sample <= -24'sd4028354;  end
        8'd215: begin low_sample <= -24'sd2550237; high_sample <= -24'sd4006773;  end
        8'd216: begin low_sample <= -24'sd2567518; high_sample <= -24'sd3957809;  end
        8'd217: begin low_sample <= -24'sd2586393; high_sample <= -24'sd3880709;  end
        8'd218: begin low_sample <= -24'sd2606078; high_sample <= -24'sd3776349;  end
        8'd219: begin low_sample <= -24'sd2625802; high_sample <= -24'sd3647305;  end
        8'd220: begin low_sample <= -24'sd2644860; high_sample <= -24'sd3497786;  end
        8'd221: begin low_sample <= -24'sd2662651; high_sample <= -24'sd3333370;  end
        8'd222: begin low_sample <= -24'sd2678726; high_sample <= -24'sd3160646;  end
        8'd223: begin low_sample <= -24'sd2692846; high_sample <= -24'sd2986657;  end

        8'd224: begin low_sample <= -24'sd2704999; high_sample <= -24'sd2818298;  end
        8'd225: begin low_sample <= -24'sd2715356; high_sample <= -24'sd2661748;  end
        8'd226: begin low_sample <= -24'sd2724198; high_sample <= -24'sd2521920;  end
        8'd227: begin low_sample <= -24'sd2731844; high_sample <= -24'sd2402069;  end
        8'd228: begin low_sample <= -24'sd2738599; high_sample <= -24'sd2303489;  end
        8'd229: begin low_sample <= -24'sd2744726; high_sample <= -24'sd2225403;  end
        8'd230: begin low_sample <= -24'sd2750422; high_sample <= -24'sd2165107;  end
        8'd231: begin low_sample <= -24'sd2755790; high_sample <= -24'sd2118239;  end
        8'd232: begin low_sample <= -24'sd2760834; high_sample <= -24'sd2079227;  end
        8'd233: begin low_sample <= -24'sd2765450; high_sample <= -24'sd2041906;  end
        8'd234: begin low_sample <= -24'sd2769447; high_sample <= -24'sd2000278;  end
        8'd235: begin low_sample <= -24'sd2772579; high_sample <= -24'sd1949180;  end
        8'd236: begin low_sample <= -24'sd2774575; high_sample <= -24'sd1884739;  end
        8'd237: begin low_sample <= -24'sd2775171; high_sample <= -24'sd1804643;  end
        8'd238: begin low_sample <= -24'sd2774138; high_sample <= -24'sd1708193;  end
        8'd239: begin low_sample <= -24'sd2771319; high_sample <= -24'sd1596215;  end

        8'd240: begin low_sample <= -24'sd2766654; high_sample <= -24'sd1470837;  end
        8'd241: begin low_sample <= -24'sd2760188; high_sample <= -24'sd1335013;  end
        8'd242: begin low_sample <= -24'sd2752072; high_sample <= -24'sd1192056;  end
        8'd243: begin low_sample <= -24'sd2742559; high_sample <= -24'sd1045158;  end
        8'd244: begin low_sample <= -24'sd2731990; high_sample <= -24'sd897036;   end
        8'd245: begin low_sample <= -24'sd2720775; high_sample <= -24'sd749833;   end
        8'd246: begin low_sample <= -24'sd2709358; high_sample <= -24'sd604363;   end
        8'd247: begin low_sample <= -24'sd2698180; high_sample <= -24'sd460780;   end
        8'd248: begin low_sample <= -24'sd2687657; high_sample <= -24'sd318837;   end
        8'd249: begin low_sample <= -24'sd2678142; high_sample <= -24'sd178058;   end
        8'd250: begin low_sample <= -24'sd2669893; high_sample <= -24'sd38292;    end
        8'd251: begin low_sample <= -24'sd2663035; high_sample <=  24'sd100199;   end
        8'd252: begin low_sample <= -24'sd2657538; high_sample <=  24'sd236467;   end
        8'd253: begin low_sample <= -24'sd2653211; high_sample <=  24'sd368992;   end
        8'd254: begin low_sample <= -24'sd2649717; high_sample <=  24'sd496275;   end
        8'd255: begin low_sample <= -24'sd2646581; high_sample <=  24'sd617018;   end

        default: begin
            low_sample  <= 24'sd0;
            high_sample <= 24'sd0;
        end

    endcase

end

endmodule