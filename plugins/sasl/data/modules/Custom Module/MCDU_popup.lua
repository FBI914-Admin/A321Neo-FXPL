size = {877, 1365}

local B612MONO_regular = sasl.gl.loadFont("fonts/B612Mono-Regular.ttf")
local MCDU_OVERLAY = sasl.gl.loadImage("textures/MCDU.png", 0, 0, 877, 1365)

local WHITELIST = "1234567890qwertyuiopasdfghjklzxcvbnm./ "

function update()
    --change menu item state
    if MCDU_window:isVisible() == true then
        sasl.setMenuItemState(Menu_main, ShowHideMCDU, MENU_CHECKED)
    else
        sasl.setMenuItemState(Menu_main, ShowHideMCDU, MENU_UNCHECKED)
    end
end

local CLICK_RECT_SIDE_L = {start_vec = {x = 10, y = 1140, w = 90, h = 50}, offset_vec = {x = 0, y = -75, w = 0, h = 0}, rpt = {x = 1, y = 6}}
CLICK_RECT_SIDE_L.cmd = {}
CLICK_RECT_SIDE_L.cmd[1] = {}
CLICK_RECT_SIDE_L.cmd[1][1] = "a321neo/cockpit/mcdu/side/L1"
CLICK_RECT_SIDE_L.cmd[2] = {}
CLICK_RECT_SIDE_L.cmd[2][1] = "a321neo/cockpit/mcdu/side/L2"
CLICK_RECT_SIDE_L.cmd[3] = {}
CLICK_RECT_SIDE_L.cmd[3][1] = "a321neo/cockpit/mcdu/side/L3"
CLICK_RECT_SIDE_L.cmd[4] = {}
CLICK_RECT_SIDE_L.cmd[4][1] = "a321neo/cockpit/mcdu/side/L4"
CLICK_RECT_SIDE_L.cmd[5] = {}
CLICK_RECT_SIDE_L.cmd[5][1] = "a321neo/cockpit/mcdu/side/L5"
CLICK_RECT_SIDE_L.cmd[6] = {}
CLICK_RECT_SIDE_L.cmd[6][1] = "a321neo/cockpit/mcdu/side/L6"

local CLICK_RECT_SIDE_R = {start_vec = {x = 780, y = 1140, w = 90, h = 50}, offset_vec = {x = 0, y = -75, w = 0, h = 0}, rpt = {x = 1, y = 6}}
CLICK_RECT_SIDE_R.cmd = {}
CLICK_RECT_SIDE_R.cmd[1] = {}
CLICK_RECT_SIDE_R.cmd[1][1] = "a321neo/cockpit/mcdu/side/R1"
CLICK_RECT_SIDE_R.cmd[2] = {}
CLICK_RECT_SIDE_R.cmd[2][1] = "a321neo/cockpit/mcdu/side/R2"
CLICK_RECT_SIDE_R.cmd[3] = {}
CLICK_RECT_SIDE_R.cmd[3][1] = "a321neo/cockpit/mcdu/side/R3"
CLICK_RECT_SIDE_R.cmd[4] = {}
CLICK_RECT_SIDE_R.cmd[4][1] = "a321neo/cockpit/mcdu/side/R4"
CLICK_RECT_SIDE_R.cmd[5] = {}
CLICK_RECT_SIDE_R.cmd[5][1] = "a321neo/cockpit/mcdu/side/R5"
CLICK_RECT_SIDE_R.cmd[6] = {}
CLICK_RECT_SIDE_R.cmd[6][1] = "a321neo/cockpit/mcdu/side/R6"

local CLICK_RECT_PAGES = {start_vec = {x = 80, y = 610, w = 100, h = 60}, offset_vec = {x = 109, y = -70, w = 0, h = 0}, rpt = {x = 6, y = 5}}
CLICK_RECT_PAGES.cmd = {}
CLICK_RECT_PAGES.cmd[1] = {}
CLICK_RECT_PAGES.cmd[1][1] = "a321neo/cockpit/mcdu/page/dir"
CLICK_RECT_PAGES.cmd[1][2] = "a321neo/cockpit/mcdu/page/prog"
CLICK_RECT_PAGES.cmd[1][3] = "a321neo/cockpit/mcdu/page/perf"
CLICK_RECT_PAGES.cmd[1][4] = "a321neo/cockpit/mcdu/page/init"
CLICK_RECT_PAGES.cmd[1][5] = "a321neo/cockpit/mcdu/page/data"

CLICK_RECT_PAGES.cmd[2] = {}
CLICK_RECT_PAGES.cmd[2][1] = "a321neo/cockpit/mcdu/page/f-pln"
CLICK_RECT_PAGES.cmd[2][2] = "a321neo/cockpit/mcdu/page/rad nav"
CLICK_RECT_PAGES.cmd[2][3] = "a321neo/cockpit/mcdu/page/fuel pred"
CLICK_RECT_PAGES.cmd[2][4] = "a321neo/cockpit/mcdu/page/sec f-pln"
CLICK_RECT_PAGES.cmd[2][5] = "a321neo/cockpit/mcdu/page/atc comm"
CLICK_RECT_PAGES.cmd[2][6] = "a321neo/cockpit/mcdu/page/mcdu menu"

CLICK_RECT_PAGES.cmd[3] = {}
CLICK_RECT_PAGES.cmd[3][1] = "a321neo/cockpit/mcdu/page/air port"

CLICK_RECT_PAGES.cmd[4] = {}
CLICK_RECT_PAGES.cmd[4][1] = "a321neo/cockpit/mcdu/side/slew_left"
CLICK_RECT_PAGES.cmd[4][2] = "a321neo/cockpit/mcdu/side/slew_up"

CLICK_RECT_PAGES.cmd[5] = {}
CLICK_RECT_PAGES.cmd[5][1] = "a321neo/cockpit/mcdu/side/slew_right"
CLICK_RECT_PAGES.cmd[5][2] = "a321neo/cockpit/mcdu/side/slew_down"

local CLICK_RECT_ALPHABET = {start_vec = {x = 350, y = 440, w = 80, h = 70}, offset_vec = {x = 89, y = -79, w = 0, h = 0}, rpt = {x = 5, y = 6}}
CLICK_RECT_ALPHABET.cmd = {}

CLICK_RECT_ALPHABET.cmd[1] = {}
CLICK_RECT_ALPHABET.cmd[1][1] = "a321neo/cockpit/mcdu/key/A"
CLICK_RECT_ALPHABET.cmd[1][2] = "a321neo/cockpit/mcdu/key/B"
CLICK_RECT_ALPHABET.cmd[1][3] = "a321neo/cockpit/mcdu/key/C"
CLICK_RECT_ALPHABET.cmd[1][4] = "a321neo/cockpit/mcdu/key/D"
CLICK_RECT_ALPHABET.cmd[1][5] = "a321neo/cockpit/mcdu/key/E"

CLICK_RECT_ALPHABET.cmd[2] = {}
CLICK_RECT_ALPHABET.cmd[2][1] = "a321neo/cockpit/mcdu/key/F"
CLICK_RECT_ALPHABET.cmd[2][2] = "a321neo/cockpit/mcdu/key/G"
CLICK_RECT_ALPHABET.cmd[2][3] = "a321neo/cockpit/mcdu/key/H"
CLICK_RECT_ALPHABET.cmd[2][4] = "a321neo/cockpit/mcdu/key/I"
CLICK_RECT_ALPHABET.cmd[2][5] = "a321neo/cockpit/mcdu/key/J"

CLICK_RECT_ALPHABET.cmd[3] = {}
CLICK_RECT_ALPHABET.cmd[3][1] = "a321neo/cockpit/mcdu/key/K"
CLICK_RECT_ALPHABET.cmd[3][2] = "a321neo/cockpit/mcdu/key/L"
CLICK_RECT_ALPHABET.cmd[3][3] = "a321neo/cockpit/mcdu/key/M"
CLICK_RECT_ALPHABET.cmd[3][4] = "a321neo/cockpit/mcdu/key/N"
CLICK_RECT_ALPHABET.cmd[3][5] = "a321neo/cockpit/mcdu/key/O"

CLICK_RECT_ALPHABET.cmd[4] = {}
CLICK_RECT_ALPHABET.cmd[4][1] = "a321neo/cockpit/mcdu/key/P"
CLICK_RECT_ALPHABET.cmd[4][2] = "a321neo/cockpit/mcdu/key/Q"
CLICK_RECT_ALPHABET.cmd[4][3] = "a321neo/cockpit/mcdu/key/R"
CLICK_RECT_ALPHABET.cmd[4][4] = "a321neo/cockpit/mcdu/key/S"
CLICK_RECT_ALPHABET.cmd[4][5] = "a321neo/cockpit/mcdu/key/T"

CLICK_RECT_ALPHABET.cmd[5] = {}
CLICK_RECT_ALPHABET.cmd[5][1] = "a321neo/cockpit/mcdu/key/U"
CLICK_RECT_ALPHABET.cmd[5][2] = "a321neo/cockpit/mcdu/key/V"
CLICK_RECT_ALPHABET.cmd[5][3] = "a321neo/cockpit/mcdu/key/W"
CLICK_RECT_ALPHABET.cmd[5][4] = "a321neo/cockpit/mcdu/key/X"
CLICK_RECT_ALPHABET.cmd[5][5] = "a321neo/cockpit/mcdu/key/Y"

CLICK_RECT_ALPHABET.cmd[6] = {}
CLICK_RECT_ALPHABET.cmd[6][1] = "a321neo/cockpit/mcdu/key/Z"
CLICK_RECT_ALPHABET.cmd[6][2] = "a321neo/cockpit/mcdu/key//"
CLICK_RECT_ALPHABET.cmd[6][3] = "a321neo/cockpit/mcdu/key/ "
CLICK_RECT_ALPHABET.cmd[6][4] = "a321neo/cockpit/mcdu/key/Δ"
CLICK_RECT_ALPHABET.cmd[6][5] = "a321neo/cockpit/mcdu/misc/clr"

local CLICK_RECT_NUMERIC = {start_vec = {x = 100, y = 240, w = 70, h = 65}, offset_vec = {x = 79, y = -69, w = 0, h = 0}, rpt = {x = 3, y = 4}}
CLICK_RECT_NUMERIC.cmd = {}

CLICK_RECT_NUMERIC.cmd[1] = {}
CLICK_RECT_NUMERIC.cmd[1][1] = "a321neo/cockpit/mcdu/key/1"
CLICK_RECT_NUMERIC.cmd[1][2] = "a321neo/cockpit/mcdu/key/2"
CLICK_RECT_NUMERIC.cmd[1][3] = "a321neo/cockpit/mcdu/key/3"

CLICK_RECT_NUMERIC.cmd[2] = {}
CLICK_RECT_NUMERIC.cmd[2][1] = "a321neo/cockpit/mcdu/key/4"
CLICK_RECT_NUMERIC.cmd[2][2] = "a321neo/cockpit/mcdu/key/5"
CLICK_RECT_NUMERIC.cmd[2][3] = "a321neo/cockpit/mcdu/key/6"

CLICK_RECT_NUMERIC.cmd[3] = {}
CLICK_RECT_NUMERIC.cmd[3][1] = "a321neo/cockpit/mcdu/key/7"
CLICK_RECT_NUMERIC.cmd[3][2] = "a321neo/cockpit/mcdu/key/8"
CLICK_RECT_NUMERIC.cmd[3][3] = "a321neo/cockpit/mcdu/key/9"

CLICK_RECT_NUMERIC.cmd[4] = {}
CLICK_RECT_NUMERIC.cmd[4][1] = "a321neo/cockpit/mcdu/key/."
CLICK_RECT_NUMERIC.cmd[4][2] = "a321neo/cockpit/mcdu/key/0"
CLICK_RECT_NUMERIC.cmd[4][3] = "a321neo/cockpit/mcdu/misc/positive_negative"

local CLICK_RECT_BRTDIM = {start_vec = {x = 740, y = 600, w = 60, h = 65}, offset_vec = {x = 79, y = -69, w = 0, h = 0}, rpt = {x = 1, y = 2}}
CLICK_RECT_BRTDIM.cmd = {}

local CLICK_RECTS = {CLICK_RECT_SIDE_L, CLICK_RECT_SIDE_R, CLICK_RECT_PAGES, CLICK_RECT_ALPHABET, CLICK_RECT_NUMERIC, CLICK_RECT_BRTDIM}
local click_rect_all = {}

for i,click_rect in ipairs(CLICK_RECTS) do
    for j = 1, click_rect.rpt.x do
        for k = 1, click_rect.rpt.y do
            rpt_x = j - 1
            rpt_y = k - 1
            cmd = "nil"
            if click_rect.cmd[k] ~= nil then
                if click_rect.cmd[k][j] ~= nil then
                    cmd = click_rect.cmd[k][j]
                end
            end
            table.insert(click_rect_all, {
                x = click_rect.start_vec.x + (click_rect.offset_vec.x * rpt_x),
                y = click_rect.start_vec.y + (click_rect.offset_vec.y * rpt_y),
                w = click_rect.start_vec.w + (click_rect.offset_vec.w * rpt_x),
                h = click_rect.start_vec.h + (click_rect.offset_vec.h * rpt_y),
                cmd = cmd
            })
        end
    end
end

function draw()
    sasl.gl.drawTexture(MCDU_OVERLAY, 0, 0, 877, 1365)
    if get(Mcdu_enabled) == 1 then
        --does enabled exist?
        if MCDU_get_popup("enabled") ~= nil then
            --is enabled true?
            if MCDU_get_popup("enabled") then
                for i,line in ipairs(MCDU_get_popup("draw lines")) do
                    sasl.gl.setFontGlyphSpacingFactor(B612MONO_regular, line.disp_spacing)
                    --sasl.gl.drawText(B612MONO_regular, (line.disp_x * 2) + 98, (line.disp_y * 2) + 345, line.disp_text, line.disp_text_size * 1.2, false, false, line.disp_text_align, line.disp_color)
                    sasl.gl.drawText(B612MONO_regular, (line.disp_x * 1.83) + 140, (line.disp_y * 2.03) + 700, line.disp_text, line.disp_text_size * 1.7, false, false, line.disp_text_align, line.disp_color)
                end
            end
            --drawing scratchpad
            sasl.gl.drawText(B612MONO_regular, 150, 730, MCDU_get_popup("mcdu entry"), 35, false, false, TEXT_ALIGN_LEFT, {1,1,1})
            for i,click_rect in ipairs(click_rect_all) do
                --sasl.gl.drawRectangle(click_rect.x, click_rect.y, click_rect.w, click_rect.h, {1,0,0})
            end
            
        end
    end
end

function onKeyDown ( component , charCode , key , shDown , ctrlDown , altOptDown )
    --is it a key down or key hold event?
        if charCode == SASL_KEY_RETURN or
           charCode == SASL_KEY_ESCAPE or
           charCode == SASL_KEY_TAB
           then
            --noop
        elseif charCode == SASL_KEY_DELETE then
            sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/misc/clr"))
        elseif string.char(charCode) == "+" or string.char(charCode) == "-" then
            sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/misc/positive_negative"))
        elseif charCode == SASL_KEY_UP then
            sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/side/slew_up"))
        elseif charCode == SASL_KEY_DOWN then
            sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/side/slew_down"))
        elseif charCode == SASL_KEY_LEFT then
            sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/side/slew_left"))
        elseif charCode == SASL_KEY_RIGHT then
            sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/side/slew_right"))
        else
            local pass = false
            for i = 1, string.len(WHITELIST) do
                if string.char(charCode):lower() == WHITELIST:sub(i,i) then
                    pass = true
                end
            end
            if pass then
                sasl.commandOnce(sasl.findCommand("a321neo/cockpit/mcdu/key/" .. string.char(charCode):upper()))
            end
        end
    return true
end

function onMouseDown (component , x , y , button , parentX , parentY)
    for i,click_rect in ipairs(click_rect_all) do
        if x > click_rect.x and x < click_rect.x + click_rect.w then
            if y > click_rect.y and y < click_rect.y + click_rect.h then
                if button == MB_LEFT then
                    if click_rect.cmd ~= "nil" then
                        print(click_rect.cmd)
                        sasl.commandOnce(sasl.findCommand(click_rect.cmd))
                    end
                end
            end
        end
    end
    return true
end

