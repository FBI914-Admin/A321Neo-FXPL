--sim datarefs

--a32nx datarefs

--fonts
local B612MONO_regular = sasl.gl.loadFont("fonts/B612Mono-Regular.ttf")

--colors
local BLACK = {0.0, 0.0, 0.0}
local ECAM_WHITE = {1.0, 1.0, 1.0}
local ECAM_BLUE = {0.004, 1.0, 1.0}
local ECAM_GREEN = {0.184, 0.733, 0.219}
local ECAM_ORANGE = {0.725, 0.521, 0.18}
local eng_1_bleed_cl = ECAM_ORANGE
local apugpu_bleed_cl = ECAM_ORANGE
local eng_2_bleed_cl = ECAM_ORANGE
local left_bleed_cl = ECAM_ORANGE
local mid_bleed_cl = ECAM_ORANGE
local right_bleed_cl = ECAM_ORANGE
local left_pack_cl = ECAM_ORANGE
local mid_pack_cl = ECAM_ORANGE
local right_pack_cl = ECAM_ORANGE
local sim_left_iso_cl = ECAM_GREEN
local sim_right_iso_cl = ECAM_GREEN

--valve positions
local sim_l_iso_line_xy = {size[1]/2 - size[1]/4 - 65, size[2]/2+110, size[1]/2 - size[1]/4 - 35, size[2]/2+110}
local sim_r_iso_line_xy = {size[1]/2 - size[1]/4 + 35, size[2]/2+110, size[1]/2 - size[1]/4 + 65, size[2]/2+110}


function update()
    --change menu item state
    if Packs_debug_window:isVisible() == true then
        sasl.setMenuItemState(Menu_main, ShowHidePacksDebug, MENU_CHECKED)
    else
        sasl.setMenuItemState(Menu_main, ShowHidePacksDebug, MENU_UNCHECKED)
    end

    if get(ENG_1_bleed_switch) == 1 then
        eng_1_bleed_cl = ECAM_GREEN
    else
        eng_1_bleed_cl = ECAM_ORANGE
    end

    if get(Apu_bleed_switch) == 1 then
        apugpu_bleed_cl = ECAM_GREEN
    else
        apugpu_bleed_cl = ECAM_ORANGE
    end

    if get(ENG_2_bleed_switch) == 1 then
        eng_2_bleed_cl = ECAM_GREEN
    else
        eng_2_bleed_cl = ECAM_ORANGE
    end

    if get(Left_bleed_avil) > 0.1 then
        left_bleed_cl = ECAM_GREEN
    else
        left_bleed_cl = ECAM_ORANGE
    end

    if get(Mid_bleed_avil) > 0.1 then
        mid_bleed_cl = ECAM_GREEN
    else
        mid_bleed_cl = ECAM_ORANGE
    end

    if get(Right_bleed_avil) > 0.1 then
        right_bleed_cl = ECAM_GREEN
    else
        right_bleed_cl = ECAM_ORANGE
    end

    if get(Pack_L) == 1 and get(Left_bleed_avil) > 0.1 then
        left_pack_cl = ECAM_GREEN
    else
        left_pack_cl = ECAM_ORANGE
    end

    if get(Pack_M) == 1 and get(Mid_bleed_avil) > 0.1 then
        mid_pack_cl = ECAM_GREEN
    else
        mid_pack_cl = ECAM_ORANGE
    end

    if get(Pack_R) == 1 and get(Right_bleed_avil) > 0.1  then
        right_pack_cl = ECAM_GREEN
    else
        right_pack_cl = ECAM_ORANGE
    end

    if get(Left_pack_iso_valve) == 1 then
        if get(Left_bleed_avil) > 0.1 and get(Mid_bleed_avil) > 0.1 then
            sim_left_iso_cl = ECAM_GREEN
        else
            sim_left_iso_cl = ECAM_ORANGE
        end
        sim_l_iso_line_xy = {size[1]/2 - size[1]/4 - 65, size[2]/2+80, size[1]/2 - size[1]/4 - 35, size[2]/2+80}
    else
        sim_left_iso_cl = ECAM_ORANGE
        sim_l_iso_line_xy = {size[1]/2 - size[1]/4 - 50, size[2]/2+95, size[1]/2 - size[1]/4 - 50, size[2]/2+65}
    end

    if get(Right_pack_iso_valve) == 1 then
        if get(Mid_bleed_avil) > 0.1 and get(Right_bleed_avil) > 0.1 then
            sim_right_iso_cl = ECAM_GREEN
        else
            sim_left_iso_cl = ECAM_ORANGE
        end
        sim_r_iso_line_xy = {size[1]/2 - size[1]/4 + 35, size[2]/2+80, size[1]/2 - size[1]/4 + 65, size[2]/2+80}
    else
        sim_right_iso_cl = ECAM_ORANGE
        sim_r_iso_line_xy = {size[1]/2 - size[1]/4 + 50, size[2]/2+95, size[1]/2 - size[1]/4 + 50, size[2]/2+65}
    end
end

function draw()
    sasl.gl.drawRectangle(0, 0, size[1], size[2], BLACK)
    --x plane pack system diagram--
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4, size[2]/2+200, "X-PLANE PACKS", 15,false, false, TEXT_ALIGN_CENTER, ECAM_BLUE)
    --direct bleed feeds--
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4 - 100, size[2]/2-150, "ENG 1 BLEED", 10,false, false, TEXT_ALIGN_CENTER, eng_1_bleed_cl)
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4      , size[2]/2-150, "APU/GPU BLEED", 10,false, false, TEXT_ALIGN_CENTER, apugpu_bleed_cl)
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4 + 100, size[2]/2-150, "ENG 2 BLEED", 10,false, false, TEXT_ALIGN_CENTER, eng_2_bleed_cl)
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4 - 100, size[2]/2-140, size[1]/2 - size[1]/4 - 100, size[2]/2+80, 2, left_bleed_cl)
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4      , size[2]/2-140, size[1]/2 - size[1]/4      , size[2]/2+80, 2, mid_bleed_cl)
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4 + 100, size[2]/2-140, size[1]/2 - size[1]/4 + 100, size[2]/2+80, 2, right_bleed_cl)
    --briding and x bleeds--
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4 - 100, size[2]/2+80, size[1]/2 - size[1]/4 - 65,  size[2]/2+80, 2, left_bleed_cl)
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4 - 35 , size[2]/2+80, size[1]/2 - size[1]/4     ,  size[2]/2+80, 2, mid_bleed_cl)
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4      , size[2]/2+80, size[1]/2 - size[1]/4 + 35,  size[2]/2+80, 2, mid_bleed_cl)
    sasl.gl.drawWideLine(size[1]/2 - size[1]/4 + 65 , size[2]/2+80, size[1]/2 - size[1]/4 + 100, size[2]/2+80, 2, right_bleed_cl)
    --ISO valves--
    sasl.gl.drawArc(size[1]/2 - size[1]/4 - 50,  size[2]/2+80, 13, 15, 0, 360, sim_left_iso_cl)
    sasl.gl.drawArc(size[1]/2 - size[1]/4 + 50,  size[2]/2+80, 13, 15, 0, 360, sim_right_iso_cl)
    --ISO valve lines--
    sasl.gl.drawWideLine(sim_l_iso_line_xy[1], sim_l_iso_line_xy[2], sim_l_iso_line_xy[3], sim_l_iso_line_xy[4], 2, sim_left_iso_cl)
    sasl.gl.drawWideLine(sim_r_iso_line_xy[1], sim_r_iso_line_xy[2], sim_r_iso_line_xy[3], sim_r_iso_line_xy[4], 2, sim_right_iso_cl)
    --packs--
    sasl.gl.drawRectangle(size[1]/2 - size[1]/4 - 110, size[2]/2 + 100, 20, 15, left_pack_cl)
    sasl.gl.drawRectangle(size[1]/2 - size[1]/4 - 10 , size[2]/2 + 100, 20, 15, mid_pack_cl)
    sasl.gl.drawRectangle(size[1]/2 - size[1]/4 + 90 , size[2]/2 + 100, 20, 15, right_pack_cl)
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4 - 100, size[2]/2+120, "L PACK", 10,false, false, TEXT_ALIGN_CENTER, left_pack_cl)
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4      , size[2]/2+120, "M PACK", 10,false, false, TEXT_ALIGN_CENTER, mid_pack_cl)
    sasl.gl.drawText(B612MONO_regular, size[1]/2 - size[1]/4 + 100, size[2]/2+120, "R PACK", 10,false, false, TEXT_ALIGN_CENTER, right_pack_cl)

    --a320 pack system diagram--
    sasl.gl.drawText(B612MONO_regular, size[1]/2 + size[1]/4, size[2]/2+200, "A321NEO PACKS", 15,false, false, TEXT_ALIGN_CENTER, ECAM_BLUE)
end
