position = {75,1690,320,285}
size = {320, 285}

local NIL = 0 -- used for input return and checking
local NIL_UNIQUE = "unique-nil" -- used for input return and checking

--[[
--
--
--      A32NX MCDU
--
--      CONSTS DECLARATION
--      FMGS & MCDU DATA INITIALIZATION
--      DATA & COMMAND REGISTRATION
--      MCDU - XP FUNC CONTROLS
--      MCDU PAGE SIMULATION
--
--
--]]

--[[
--
--
--      CONSTS DECLARATION
--
--
--]]
local MCDU_DRAW_SIZE = {w = size[1], h = size[2]} -- idk if size table is required by anything else, this is for internal reference

--define the const size, align and row.
local MCDU_DIV_SIZE = {"s", "l"}
local MCDU_DIV_ALIGN = {"L", "C", "R"} -- TODO: removed center
local MCDU_DIV_ROW = {1,2,3,4,5,6}

--line spacing
local MCDU_DRAW_OFFSET = {x = 7, y = 240} -- starting offset for line drawing
local MCDU_DRAW_SPACING = {x = 156, y = -18.5} -- change in offset per line drawn
local MCDU_DRAW_TEXT_SIZE = {s = 12, l = 20} -- font size

--reference table for drawing
local MCDU_DISP_COLOR = 
{
    ["white"] = {1.0, 1.0, 1.0},
    ["blue"] = {0.004, 1.0, 1.0},
    ["green"] = {0.184, 0.733, 0.219},
    ["orange"] = {0.725, 0.521, 0.18},
    ["black"] = {0,0,0,1},
}
local MCDU_DISP_TEXT_SIZE =
{
    ["s"] = MCDU_DRAW_TEXT_SIZE.s,
    ["l"] = MCDU_DRAW_TEXT_SIZE.l,
}
local MCDU_DISP_TEXT_SPACING =
{
    ["s"] = 1.667,
    ["l"] = 1.0,
}
local MCDU_DISP_TEXT_ALIGN =
{
    ["L"] = TEXT_ALIGN_LEFT,
    ["C"] = TEXT_ALIGN_CENTER,
    ["R"] = TEXT_ALIGN_RIGHT,
}

--fonts
local B612MONO_regular = sasl.gl.loadFont("fonts/B612Mono-Regular.ttf")

-- alphanumeric & decimal FMC entry keys
local MCDU_ENTRY_KEYS = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "Δ", "/", " "}
local MCDU_ENTRY_PAGES = {"dir", "prog", "perf", "init", "data", "f-pln", "rad nav", "fuel pred", "sec f-pln", "atc comm", "mcdu menu", "air port"}
local MCDU_ENTRY_SIDES = {"L1", "L2", "L3", "L4", "L5", "L6", "R1", "R2", "R3", "R4", "R5", "R6", "slew_up", "slew_down", "slew_left", "slew_right"}

--[[
--
--
--      FMGS & MCDU DATA INITIALIZATION
--
--
--]]

local fmgs_dat = {}
local fmgs_metadat = {}
local mcdu_dat = {}
local mcdu_dat_title = {}

for i,size in ipairs(MCDU_DIV_SIZE) do
	mcdu_dat[size] = {}
	for j,align in ipairs(MCDU_DIV_ALIGN) do
		mcdu_dat[size][align] = {}
	end
end

--entry line
local mcdu_entry = ""
local mcdu_entry_cache = "" --caches entry for when messages are shown
local mcdu_messages = {}
local mcdu_message_showing = false

--mcdu page call functions
local mcdu_sim_page = {}

--define custom functionalities
local function mcdu_send_message(message)
    table.insert(mcdu_messages, message)
end

local function mcdu_eval_entry(str, format)
    pass = true
    if #str ~= #format then
        pass = false
    end

    for i = 1,#format do
        if string.sub(format, i, i) == "!" then
            -- digit
            if string.find(string.sub(str, i, i), "%d") == nil then
                pass = false
            end
        elseif string.sub(format, i, i) == "@" then
            -- letter
            if string.find(string.sub(str, i, i), "%a") == nil then
                pass = false
            end
        elseif string.sub(format, i, i) == "#" then
            -- do nothing
        else
            if string.sub(str, i, i) ~= string.upper(string.sub(format, i, i)) then 
                pass = false
            end
        end
    end
    return pass
end

local function mcdu_get_entry(expected_formats)
    --[[
    -- expected_format
    --
    -- can accept multiple inputs ! for digits, @ for letters, # for anything
    -- https://www.lua.org/pil/20.2.html
    --]]
    me = mcdu_entry
    mcdu_entry = ""
    
    if expected_formats == nil then
        return me
    end

    if expected_formats[1] ~= nil then
        local pass = false
        variation = 0
        for i,format in ipairs(expected_formats) do-- expected_formats is a table
            if mcdu_eval_entry(me, format) then
                variation = i
                pass = true
            end
        end
        if pass then
            return me, variation 
        else
            mcdu_send_message("format error")
            return NIL, NIL
        end
    else
        if mcdu_eval_entry(me, expected_formats) then
            return me
        else
            mcdu_send_message("format error")
            return NIL
        end
    end
end

--clear MCDU
local function mcdu_clearall()
    mcdu_dat_title = {txt = "", col = "white", size = nil}
    for i,size in ipairs(MCDU_DIV_SIZE) do
        for j,align in ipairs(MCDU_DIV_ALIGN) do
            for k,row in ipairs(MCDU_DIV_ROW) do
                --mcdu_dat[size][align][row] = {txt = size .. "" .. align .. " " .. row, col = "white"}
                mcdu_dat[size][align][row] = {txt = nil, col = "white", size = nil}
            end
        end
    end
end

local mcdu_page = createGlobalPropertyi("a321neo/cockpit/mcdu/mcdu_page", 0, false, true, false)

--load MCDU page
local function mcdu_open_page(id)
    mcdu_clearall()
    set(mcdu_page, id)
    mcdu_sim_page[get(mcdu_page)]("render")
end

--pad a number up to a given dp
--e.g. (2.4, 3) -> 2.400
local function mcdu_pad_dp(number, required_dp)
    return(string.format("%." .. required_dp .. "f", number))
end

--pad a number up to a given length
--e.g. (50, 3) -> 050
local function mcdu_pad_num(number, required_length)
    str = tostring(number)
    while #str < required_length do
        str = "0" .. str
    end
    return str
end

--align an input to the right, given the total length
--e.g. ("ad", 4) -> "  ad"
local function mcdu_align_right(str, required_length)
    while #tostring(str) < required_length do
        str = " " .. str
    end
    return str
end

--align an input to the left, given the total length
--e.g. ("ad", 4) -> "  ad"
local function mcdu_align_left(str, required_length)
    while #tostring(str) < required_length do
        str = str .. " "
    end
    return str
end



--toggle obj between two strings, a and b
--e.g. ("ad", "ba", "ad") -> "ba"
local function mcdu_toggle(obj, str_a, str_b)
    if obj == str_a then
        return str_b
    elseif obj == str_b then
        return str_a
    end
end

--init FMGS data to 2nd argument
local function fmgs_dat_init(dat_name, dat_init)
    --is data uninitialised?
    if fmgs_dat[dat_name] == nil then
        fmgs_dat[dat_name] = dat_init
    end
end

--get FMGS data with initialisation
local function fmgs_dat_get(dat_name, dat_init, dat_init_col, dat_set_col, dat_format_callback)
    --[[
    -- dat_name     name of data from fmgs_dat
    -- dat_init     value the data starts with initially
    -- dat_init_col colour when data hasn't been set
    -- dat_set_col  colour when data has been set
    -- dat_format_callback (optional) format callback when data has been set
    --]]

    if fmgs_dat[dat_name] == nil then
        return {txt = dat_init, col = dat_init_col}
    else
        val = fmgs_dat[dat_name]
        if dat_format_callback == nil then
            dat_format_callback = function (val) return val end
        end

        if type(dat_init) == "string" then
            val = tostring(dat_format_callback(tostring(val)))
            --padding
            val = mcdu_align_right(val, #dat_init)
        else
            val = dat_format_callback(val)
        end

        return {txt = val, col = dat_set_col}
    end
end

--get FMGS data with initialisation sans colouring. GET PURE TEXT
local function fmgs_dat_get_txt(dat_name, dat_init, dat_format_callback)
    --[[
    -- dat_name     name of data from fmgs_dat
    -- dat_init     value the data starts with initially
    -- dat_format_callback (optional) format callback when data has been set
    --]]

    if fmgs_dat[dat_name] == nil then
        return dat_init
    else
        val = fmgs_dat[dat_name]
        if dat_format_callback == nil then
            dat_format_callback = function (val) return val end
        end

        if type(dat_init) == "string" then
            val = tostring(dat_format_callback(tostring(val)))
            --padding
            val = mcdu_align_right(val, #dat_init)
        else
            val = dat_format_callback(val)
        end

        return val
    end
end



--[[
--
--
--      DATA & COMMAND REGISTERATION
--
--
--]]
--a321neo commands
local mcdu_debug_get = sasl.createCommand("a321neo/debug/mcdu/get_data", "retrieve FMGS data from pointer a321neo/cockpit/mdu/mcdu_debug_pointer to a321neo/cockpit/mcdu/mcdu_debug_dat")
local mcdu_debug_set = sasl.createCommand("a321neo/debug/mcdu/set_data", "inject FMGS data from pointer a321neo/cockpit/mdu/mcdu_debug_pointer to a321neo/cockpit/mcdu/mcdu_debug_dat")
local mcdu_debug_pointer = createGlobalPropertys("a321neo/cockpit/mcdu/mcdu_debug_pointer")
local mcdu_debug_dat = createGlobalPropertys("a321neo/cockpit/mcdu/mcdu_debug_dat")

local mcdu_debug_busy = createGlobalPropertyi("a321neo/cockpit/mcdu/mcdu_debug_busy")

--mcdu entry inputs
local mcdu_inp = {}

local entry_cooldown = 0

local MCDU_ENTRY = 
{
    {
        ref_name = "key",               --the group of the command
        ref_desc = "Key",               --the description of the command
        ref_entries = MCDU_ENTRY_KEYS,  --the group of keys
        ref_callback =                  --what they should do
        function (count, val)
            if get(TIME) - entry_cooldown > get(DELTA_TIME) then
                entry_cooldown = get(TIME)
                if #mcdu_entry < 22 then
                    mcdu_entry = mcdu_entry .. val
                end
            end
        end
    },
    {
        ref_name = "page",
        ref_desc = "Page",
        ref_entries = MCDU_ENTRY_PAGES,
        ref_callback = 
        function (count, val)
            mcdu_open_page(count * 100)
        end
    },
    {
        ref_name = "side",
        ref_desc = "Side key",
        ref_entries = MCDU_ENTRY_SIDES,
        ref_callback = 
        function (count, val)
            mcdu_sim_page[get(mcdu_page)](val)
        end
    },
    {
        ref_name = "misc",
        ref_desc = "Clear key",
        ref_entries = {"clr"},
        ref_callback = 
        function (count, val)
            if mcdu_message_showing then
                mcdu_entry = mcdu_entry_cache
                mcdu_message_showing = false
            else
                if #mcdu_entry > 0 then
                    mcdu_entry = mcdu_entry:sub(1,#mcdu_entry - 1) 
                else
                    if #mcdu_entry == 0 then
                        mcdu_entry = "CLR"
                        mcdu_message_showing = true
                    end
                end
            end
        end
    },
    {
        ref_name = "misc",
        ref_desc = "positive_negative",
        ref_entries = {"positive_negative"},
        ref_callback = 
        function (count, val)
            if #mcdu_entry < 22 then
                if string.sub(mcdu_entry, #mcdu_entry, #mcdu_entry) == "-" then
                    mcdu_entry = string.sub(mcdu_entry, 0, #mcdu_entry - 1) .. "+"
                elseif string.sub(mcdu_entry, #mcdu_entry, #mcdu_entry) == "+" then
                    mcdu_entry = string.sub(mcdu_entry, 0, #mcdu_entry - 1) .. "-"
                elseif string.sub(mcdu_entry, #mcdu_entry, #mcdu_entry) ~= "+" and string.sub(mcdu_entry, #mcdu_entry, #mcdu_entry) ~= "-" then
                    mcdu_entry = mcdu_entry .. "-"
                end
            end
        end
    }
}

--register all entry keys
for i,entry_category in ipairs(MCDU_ENTRY) do
    for count,entry in ipairs(entry_category.ref_entries) do
        mcdu_inp[entry] = createCommand("a321neo/cockpit/mcdu/" .. entry_category.ref_name .. "/" .. entry, "MCDU " .. entry .. " " .. entry_category.ref_desc)
        sasl.registerCommandHandler(mcdu_inp[entry], 0, function (phase)
            if phase == SASL_COMMAND_BEGIN then
                if get(Mcdu_enabled) == 1 then
                    entry_category.ref_callback(count, entry)
                end
            end
        end)
    end
end

--a321neo command handlers
--debugging
local hokey_pokey = false --wonder what this does
sasl.registerCommandHandler(mcdu_debug_get, 0, function (phase)
    if phase == SASL_COMMAND_BEGIN then
        print("MCDU DEBUG get " .. fmgs_dat[get(mcdu_debug_pointer)])
        set(mcdu_debug_dat, fmgs_dat[get(mcdu_debug_pointer)])
        mcdu_open_page(get(mcdu_page))
    end
end)
sasl.registerCommandHandler(mcdu_debug_set, 0, function (phase)
    if phase == SASL_COMMAND_BEGIN then
        print("MCDU DEBUG set " .. fmgs_dat[get(mcdu_debug_pointer)])
        fmgs_dat[get(mcdu_debug_pointer)] = get(mcdu_debug_dat)
        mcdu_open_page(get(mcdu_page))
    end
end)


--[[
--
--
--      MCDU DRAWING
--
--
--]]

local draw_lines = {}
local draw_lines_itr = 0

local function draw_dat(dat, draw_size, disp_x, disp_y, disp_text_align)
    if dat.txt == nil then
        return
    end
    disp_text = tostring(dat.txt):upper()
    dat.col = dat.col or "white" --default colour
    disp_color = MCDU_DISP_COLOR[dat.col]

    -- is there a custom size
    if dat.size == nil then
        disp_size = draw_size
    else
        disp_size = dat.size
    end

    -- text size 
    disp_text_size = MCDU_DISP_TEXT_SIZE[disp_size]
    -- text spacing
    disp_spacing = MCDU_DISP_TEXT_SPACING[disp_size]

    -- replace { with the box
    text = ""
    for j = 1,#disp_text do
        if disp_text:sub(j,j) == "{" then
            text = text .. "□"
        else
            text = text .. disp_text:sub(j,j)
        end
    end
    disp_text = text

    -- now draw it!
    table.insert(draw_lines, {disp_x = disp_x, disp_y = disp_y, disp_text = disp_text, disp_text_size = disp_text_size, disp_text_align = disp_text_align, disp_color = disp_color, disp_spacing = disp_spacing})
end

local function draw_update()
    -- clear all line which need to be drawn
    draw_lines = {}
    draw_lines_itr = 0

    for i,draw_row in ipairs(MCDU_DIV_ROW) do
        for j,draw_size in ipairs(MCDU_DIV_SIZE) do
            draw_act_row = ((i - 1) * 2) + (j - 1) -- draw actual row

            for k,draw_align in ipairs(MCDU_DIV_ALIGN) do

                -- spacings
                disp_x = MCDU_DRAW_OFFSET.x
                disp_x = disp_x + (MCDU_DRAW_SPACING.x * (k - 1)) -- so -140, 0, 140

                disp_y = MCDU_DRAW_OFFSET.y
                disp_y = disp_y + (MCDU_DRAW_SPACING.y * draw_act_row) -- so 108, 90, 72

                -- text alignment
                disp_text_align = MCDU_DISP_TEXT_ALIGN[draw_align]

                -- text data
                dat_full = mcdu_dat[draw_size][draw_align][draw_row]
                if dat_full[1] == nil then
                    draw_dat(dat_full, draw_size, disp_x, disp_y, disp_text_align)
                else
                    for l,dat in pairs(dat_full) do
                        draw_dat(dat, draw_size, disp_x, disp_y, disp_text_align)
                    end
                end
            end
        end
    end

    --draw title line
    if mcdu_dat_title[1] == nil then
        draw_dat(mcdu_dat_title, "l", MCDU_DRAW_OFFSET.x, MCDU_DRAW_OFFSET.y + 20, MCDU_DISP_TEXT_ALIGN["L"])
    else
        for l,dat in pairs(mcdu_dat_title) do
            draw_dat(dat, "l", MCDU_DRAW_OFFSET.x, MCDU_DRAW_OFFSET.y + 20, MCDU_DISP_TEXT_ALIGN["L"])
        end
    end
end

local function colorize()
    for i,f in ipairs({"white", "blue", "orange", "green"}) do
        c = {}
        c[0] = MCDU_DISP_COLOR[f][1];c[1] = MCDU_DISP_COLOR[f][2];c[2] = MCDU_DISP_COLOR[f][3]
        inc = 0.1
        if c[0] < 1 and c[1] == 0 and c[2] == 0 then
            c[0] = c[0] + inc
        elseif c[0] == 1 and c[1] < 1 and c[2] == 0 then
            c[1] = c[1] + inc
        elseif c[0] <= 1 and c[0] > 0 and c[1] == 1 and c[2] == 0 then
            c[0] = c[0] - inc
        elseif c[0] == 0 and c[1] == 1 and c[2] < 1 then
            c[2] = c[2] + inc
        elseif c[0] == 0 and c[1] <= 1 and c[1] > 0 and c[2] == 1 then
            c[1] = c[1] - inc
        elseif c[0] < 1 and c[1] == 0 and c[2] == 1 then
            c[0] = c[0] + inc
        elseif c[0] == 1 and c[1] == 0 and c[2] <= 1 and c[2] > 0 then
            c[2] = c[2] - inc
        end
        MCDU_DISP_COLOR[f][1] = math.min(math.max(c[0], 0), 1); MCDU_DISP_COLOR[f][2] = math.min(math.max(c[1], 0), 1); MCDU_DISP_COLOR[f][3] = math.min(math.max(c[2], 0), 1)
    end
    draw_update()
end

--drawing the MCDU display
function draw()
    if hokey_pokey then
        colorize()
    end
    if get(Mcdu_enabled) == 1 then
        --MCDU popup
        --Mcdu_draw_ok = true
        MCDU_set_popup("draw lines", draw_lines)
        MCDU_set_popup("mcdu entry", mcdu_entry)
        MCDU_set_popup("enabled", true)
        --Mcdu_disp_color = MCDU_DISP_COLOR
        --Mcdu_draw_lines = draw_lines

        sasl.gl.drawRectangle(0, 0, 320 , 285, MCDU_DISP_COLOR["black"])
        local draw_size = {MCDU_DRAW_SIZE.w, MCDU_DRAW_SIZE.h} -- for debugging
        --sasl.gl.drawText(B612MONO_regular, draw_size[1]/2-140, draw_size[2]/2+108, mcdu_dat_title.txt, 20, false, false,TEXT_ALIGN_LEFT, MCDU_DISP_COLOR[mcdu_dat_title_L.col])

        --draw all horizontal lines
        for i,line in ipairs(draw_lines) do
            sasl.gl.setFontGlyphSpacingFactor(B612MONO_regular, line.disp_spacing)
            sasl.gl.drawText(B612MONO_regular, line.disp_x, line.disp_y, line.disp_text, line.disp_text_size, false, false, line.disp_text_align, line.disp_color)
        end

        --drawing scratchpad
        sasl.gl.drawText(B612MONO_regular, draw_size[1]/2-140, draw_size[2]/2-132, mcdu_entry, 20, false, false, TEXT_ALIGN_LEFT, MCDU_DISP_COLOR["white"])
    end
end

--[[
--
--
--      MCDU - XP FUNC CONTROLS
--
--
--]]

local mcdu_ctrl_instructions = {}
local mcdu_ctrl_listeners = {}

--add a listener for when the function value changes, callback is called
local function mcdu_ctrl_add_listener(data_func_cache, data_func, callback)
    if data_func_cache == nil then
        data_func_cache = data_func()
    end
    table.insert(mcdu_ctrl_listeners, {data_func = data_func, data_func_cache = data_func_cache, callback = callback})
end

--check whether listener has changed or not
local function mcdu_ctrl_exe_listener(listener)
    d = listener.data_func()
    if d ~= listener.data_func_cache then
        listener.data_func_cache = d
        listener.callback()
    end
end

--add an XP FMC instruction for the XP FMC to execute
local function mcdu_ctrl_add_inst(inst)
    table.insert(mcdu_ctrl_instructions, 1, inst)
end

--execute the next XP FMC instruction
local function mcdu_ctrl_exe_inst()
    if #mcdu_ctrl_instructions == 0 then
        set(mcdu_debug_busy, 0)
		return
	end
    set(mcdu_debug_busy, 1)

	inst = mcdu_ctrl_instructions[#mcdu_ctrl_instructions]
	table.remove(mcdu_ctrl_instructions)
    if inst.type == "CMD" then
        sasl.commandOnce(findCommand(inst.arg))
    end
    if inst.type == "GET_LN" then
        refcon = inst.refcon or 0
        inst.callback(get(globalPropertys("sim/cockpit2/radios/indicators/fms_cdu1_text_line" .. inst.arg)), refcon)
    end
    if inst.type == "INPUT" then
        if string.sub(get(globalPropertys("sim/cockpit2/radios/indicators/fms_cdu1_text_line13")), 2, 2) == " " then
            for i = 0,#inst.arg - 1 do
                table.insert(mcdu_ctrl_instructions, {type = "CMD", arg = "sim/FMS/key_" .. string.upper(string.sub(inst.arg, #inst.arg - i, #inst.arg - i))})
            end
        else
            sasl.commandOnce(findCommand("sim/FMS/key_clear"))
            --delete the entire scratchpad
            table.insert(mcdu_ctrl_instructions, inst)
        end
    end
    if inst.type == "NOOP" then
        -- no operation
    end
end

--sasl get nav aid information
local function mcdu_ctrl_get_nav(find_nameid, find_type)
    --find by name
    id = sasl.findNavAid(find_nameid:upper(), nil, nil, nil, nil, find_type)
    --if name is not found
    if id == -1 then
        --find by id
        id = sasl.findNavAid(nil, find_nameid:upper(), nil, nil, nil, find_type) 
    end
    local nav = {}
    nav.navtype, nav.lat, nav.lon, nav.height, nav.freq, nav.hdg, nav.id, nav.name, nav.loadedDSF = sasl.getNavAidInfo(id)
    print("nav")
    print("type " .. nav.navtype)
    print("lat " .. nav.lat)
    print("lon " .. nav.lon)
    print("height " .. nav.height)
    print("freq " .. nav.freq)
    print("hdg " .. nav.hdg)
    print("id " .. nav.id)
    print("name " .. nav.name)
    return nav
end

--[[
--mcdu_ctrl_get_nav("ksea", NAV_ILS)
--id = sasl.findFirstNavAidOfType(NAV_ILS)
--id = sasl.findNavAid(nil, "KSEA 16C", nil, nil, nil, NAV_OUTERMARKER)
for i = 0,10 do
    local nav = {}
    nav.navtype, nav.lat, nav.lon, nav.height, nav.freq, nav.hdg, nav.id, nav.name, nav.loadedDSF = sasl.getNavAidInfo(id)
    print("nav")
    print("type " .. nav.navtype)
    print("lat " .. nav.lat)
    print("lon " .. nav.lon)
    print("height " .. nav.height)
    print("freq " .. nav.freq)
    print("hdg " .. nav.hdg)
    print("id " .. nav.id)
    print("name " .. nav.name)
    id = sasl.getNextNavAid (id)
end
--]]

mcdu_entry = ""

--update
function update()
    if get(mcdu_page) == 0 then --on start
       mcdu_open_page(505) --open 505 A/C status
    end

    -- display next message
    if #mcdu_messages > 0 and not mcdu_message_showing then
        mcdu_entry_cache = mcdu_entry
        mcdu_entry = mcdu_messages[#mcdu_messages]:upper()
        mcdu_message_showing = true
        table.remove(mcdu_messages)
    end

    -- check and execute all listeners
    for i, listener in ipairs(mcdu_ctrl_listeners) do
        mcdu_ctrl_exe_listener(listener)
    end

    -- check and execute next XP FMC instruction
    mcdu_ctrl_exe_inst()
end

--[[
--
--
--      MCDU PAGE SIMULATION
--
--      loosely based on
--      http://www.a320dp.com/A320_DP/nav-flight-management/sys-14.0.0.html
--      
--      WARNING - the website has an outdated MCDU, consult ToLiss for actual data
--      14.7.5 would be (0705 - 200) so 0505 so 505
--
--      0 - nothing
--      100 - dir
--      200 - prog
--      300 - perf
--      400 - init
--      500 - data
--        505 - data A/C status
--      600 - f-pln
--        601 - f-pln lat rev
--        602 - f-pln lat rev dept airport
--        603 - f-pln lat rev dest airport
--      700 - rad nav
--      800 - fuel pred
--      900 - sec f-pln
--      1000 - atc comm
--      1100 - mcdu menu
--      1200 - air port
--
--
--]]

local function mcdu_ctrl_get_cycle(callback)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/index"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1l"})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "4", callback = callback})
end

-- returns the result for error checking
local function mcdu_ctrl_try_catch(callback)
    mcdu_ctrl_add_inst({type = "NOOP"})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "13", callback = 
    function (val) 
        if val:sub(1,2) ~= "[I" then -- [INVALID ENTRY]
            callback()

        else
            mcdu_send_message("not in database")-- INVALID ENTRY
        end
    end})
end

local function mcdu_ctrl_set_fpln_origin(input, try_catch)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/fpln"})
    mcdu_ctrl_add_inst({type = "INPUT", arg = input})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1l"})
    mcdu_ctrl_try_catch(try_catch)
end

local function mcdu_ctrl_set_fpln_dest(input, try_catch)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/fpln"})
    mcdu_ctrl_add_inst({type = "INPUT", arg = input})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1r"})
    mcdu_ctrl_try_catch(try_catch)
end

local function mcdu_ctrl_get_origin_latlon(origin, callback)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/index"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_2r"})
    mcdu_ctrl_add_inst({type = "INPUT", arg = origin})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1l"})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "4", callback = callback})
end

local function mcdu_ctrl_get_runway_length(runway, refcon, callback)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/index"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_2r"})
    mcdu_ctrl_add_inst({type = "INPUT", arg = runway})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1l"})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "6", callback = callback, refcon = refcon})
end

local function mcdu_ctrl_get_runways_origin(accessor_callback)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/dep_arr"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1l"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/prev"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/prev"})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "2", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "4", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "6", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "8", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "10", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/next"})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "2", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "4", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "6", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "8", callback = accessor_callback})
    mcdu_ctrl_add_inst({type = "GET_LN", arg = "10", callback = accessor_callback})
end

local function mcdu_ctrl_get_sids(callback)
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/dep_arr"})
    mcdu_ctrl_add_inst({type = "CMD", arg = "sim/FMS/ls_1l"})
end

-- 00 template
mcdu_sim_page[00] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          a321-521nx"

        --[[
        mcdu_dat["s"]["L"][1].txt = "□"
        mcdu_dat["l"]["L"][1][1] = {txt = " a", col = "green"}
        mcdu_dat["l"]["L"][1][1] = {txt = "  a", col = "blue", size = "s"}
        --]]

        draw_update()
    end
end

-- 100 dir
mcdu_sim_page[100] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          dir"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

-- 200 prog
mcdu_sim_page[200] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          prog"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

-- 300 perf
mcdu_sim_page[300] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          perf"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

-- 400 init
mcdu_sim_page[400] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          init"

        fmgs_dat_init("fmgs init", false)   -- init has the fmgs been initialised? to false
        fmgs_dat_init("latlon sel", "nil") -- init latlon selection for irs alignment

        fmgs_dat_init("crz temp alt", true) --init has crz temp been changed?

        --[[ CO RTE --]]
        mcdu_dat["s"]["L"][1].txt = " co rte"
        --changes on fmgs airport init
        if fmgs_dat["fmgs init"] then
            mcdu_dat["l"]["L"][1] = fmgs_dat_get("co rte", "[         ]", "blue", "blue")
        else
            mcdu_dat["l"]["L"][1] = fmgs_dat_get("co rte", "{{{{{{{{{{", "orange", "blue")
        end

        --[[ FROM / TO --]]
        mcdu_dat["s"]["R"][1].txt = " from/to  "

        mcdu_dat["l"]["R"][1] = fmgs_dat_get("origin", "{{{{", "orange", "blue")
        mcdu_dat["l"]["R"][1].txt = mcdu_dat["l"]["R"][1].txt .. "/" .. fmgs_dat_get_txt("dest", "{{{{")

        --[[ ALTN / CO RTE --]]
        mcdu_dat["s"]["L"][2].txt = "altn/co rte"
        mcdu_dat["l"]["L"][2].txt = "----/---------"

        --[[ FLT NBR --]]
        mcdu_dat["s"]["L"][3].txt = "flt nbr"
        mcdu_dat["l"]["L"][3] = fmgs_dat_get("flt nbr", "{{{{{{{{", "orange", "blue")

        --[[ IRS ALIGN --]]
        if fmgs_dat_get_txt("irs aligned", "hide") == "show" then
            mcdu_dat["l"]["R"][3] = {txt = "align irs>", col = "orange"}
        end

        --[[ LAT / LONG --]]
        mcdu_dat["s"]["R"][4].txt = "long"
        mcdu_dat["s"]["L"][4].txt = "lat"

        --irs latlon change selection
        if fmgs_dat["latlon sel"] == "lat" then
            mcdu_dat["s"]["L"][4].txt = "lat⇅"
        elseif fmgs_dat["latlon sel"] == "long" then
            mcdu_dat["s"]["R"][4].txt = "⇅long"
        end

        mcdu_dat["l"]["L"][4] = fmgs_dat_get("lat fmt", "----.-", "white", "blue")
        mcdu_dat["l"]["R"][4] = fmgs_dat_get("lon fmt", "-----.--", "white", "blue")

        --[[ COST INDEX --]]
        mcdu_dat["s"]["L"][5].txt = "cost index"
        --changes on fmgs airport init
        if fmgs_dat["fmgs init"] then
            mcdu_dat["l"]["L"][5] = fmgs_dat_get("cost index", "{{{", "orange", "blue")
        else
            mcdu_dat["l"]["L"][5] = fmgs_dat_get("cost index", "---", "white", "blue")
        end

        --[[ WIND --]]
        mcdu_dat["l"]["R"][5].txt = "wind>"

        --[[ CRZ FL/TEMP --]]
        mcdu_dat["s"]["L"][6].txt = "crz fl/temp"
        --changes on fmgs airport init
        if fmgs_dat["fmgs init"] then
            crz_fl_init_txt = "{{{{{"
            crz_fl_init_col = "orange"
        else
            crz_fl_init_txt = "-----"
            crz_fl_init_col = "white"
        end
        mcdu_dat["l"]["L"][6][1] = fmgs_dat_get("crz fl", crz_fl_init_txt, crz_fl_init_col, "blue", 
            --formatting
            function (val) 
                if #val > 4 then
                    return "FL" .. val:sub(1,3)
                else
                    return val:sub(1,4)
                end
            end
        )
        mcdu_dat["l"]["L"][6][1].txt = mcdu_dat["l"]["L"][6][1].txt .. "/" --append slant

        --has crz temp been altered?
        if fmgs_dat["crz temp alt"] then
            crz_temp_size = "l"
        else
            crz_temp_size = "s"
        end
        --changes on fmgs airport init
        if fmgs_dat["fmgs init"] then
            mcdu_dat["l"]["L"][6][2] = {txt = "      " .. fmgs_dat_get_txt("crz temp", "{{{") .. "°", col = mcdu_dat["l"]["L"][6][1].col, size = crz_temp_size}
        else
            mcdu_dat["l"]["L"][6][2] = {txt = "      " .. fmgs_dat_get_txt("crz temp", "---") .. "°", col = mcdu_dat["l"]["L"][6][1].col, size = crz_temp_size}
        end

        --[[ TROPO --]]
        mcdu_dat["s"]["R"][6].txt = "tropo "
        fmgs_dat_init("tropo", 39060)
        --grows bigger if changed
        if fmgs_dat["tropo"] == 39060 then
            tropo_size = "s"
        else
            tropo_size = "l"
        end
        mcdu_dat["l"]["R"][6] = {txt = fmgs_dat["tropo"], col = "blue", size = tropo_size}

        draw_update()
    end
	-- flt nbr
    if phase == "L3" then
        input = mcdu_get_entry()
        fmgs_dat["flt nbr"] = input
        mcdu_open_page(400) -- reload
    end
    -- cost index
    if phase == "L5" then
        --format e.g. 100
        input, variation = mcdu_get_entry({
            "!!!", -- 100 cost index
            "!!",  -- 10 cost index
            "!"    -- 1 cost index
        })
        fmgs_dat["cost index"] = input
        mcdu_open_page(400) -- reload
    end
    -- crz fl/temp
    if phase == "L6" then
        --format e.g. FL230
        input, variation = mcdu_get_entry({
            "!!",   -- 80 (8000 feet)
            "!!!",  -- 230 (23000 feet)
            "fl!!!",-- FL230 (23000 feet)
            "fl!!!/!",-- FL230/7 (23000 feet, -7 celcius)
            "fl!!!/!!",-- FL230/40 (23000 feet, -40 celcius)
            "fl!!!/-!",-- FL230/-7 (23000 feet, -40 celcius)
            "fl!!!/-!!",-- FL230/-40 (23000 feet, -40 celcius)
            "/!",   -- 7 (-7 celcius)
            "/!!",  -- 40 (-40 celcius)
            "/-!",  -- -7 (-7 celcius)
            "/-!!"  -- -40 (-40 celcius)
        })

        --automatically calculate crz temp
        if variation >= 1 and variation <= 3 then
            if variation ~= 3 then
                alt = input
            else
                alt = input:sub(3,5)
            end
            fmgs_dat["crz temp"] = math.floor(tonumber(alt) * -0.2 + 16)
            fmgs_dat["crz temp alt"] = false --crz temp has not been altered

        else
            fmgs_dat["crz temp alt"] = true --crz temp has been manually altered
        end

        --set crz FL or crz temp
        if variation == 1 then
            fmgs_dat["crz fl"] = input * 100
        elseif variation == 2 then
            fmgs_dat["crz fl"] = input * 100
        elseif variation == 3 then
            fmgs_dat["crz fl"] = tonumber(input:sub(3,5)) * 100
        elseif variation == 4 then
            fmgs_dat["crz fl"] = input:sub(3,5) * 100
            fmgs_dat["crz temp"] = input:sub(7,7) * -1
        elseif variation == 5 then
            fmgs_dat["crz fl"] = input:sub(3,5) * 100
            fmgs_dat["crz temp"] = input:sub(7,8) * -1
        elseif variation == 6 then
            fmgs_dat["crz fl"] = input:sub(3,5) * 100
            fmgs_dat["crz temp"] = input:sub(7,8)
        elseif variation == 7 then
            fmgs_dat["crz fl"] = input:sub(3,5) * 100
            fmgs_dat["crz temp"] = input:sub(7,9)
        elseif variation == 8 then
            fmgs_dat["crz temp"] = input:sub(2,2) * -1
        elseif variation == 9 then
            fmgs_dat["crz temp"] = input:sub(2,3) * -1
        elseif variation == 10 then
            fmgs_dat["crz temp"] = input:sub(2,3)
        elseif variation == 11 then
            fmgs_dat["crz temp"] = input:sub(2,4)
        end
        mcdu_open_page(400) -- reload
    end

    -- from/to
    if phase == "R1" then
        --format e.g. ksea/kbfi
        input = mcdu_get_entry("####/####")
        --check for correct entry
        if input ~= NIL then
            --set orgin for XP FMC
            --format e.g. ksea/kbfi
            airp_origin = input:sub(1,4)
            airp_dest = input:sub(6,9)

            --get origin from XP FMC
            mcdu_ctrl_set_fpln_origin(airp_origin, function(val) --callback
            fmgs_dat["origin"] = airp_origin

            --get dest from XP FMC
            mcdu_ctrl_set_fpln_dest(airp_dest, function(val) --callback
            fmgs_dat["dest"] = airp_dest

            --set co rte
            fmgs_dat["fmgs init"] = true
            mcdu_open_page(400) -- reload

            --get lat lon from XP FMC
            mcdu_ctrl_get_origin_latlon(input:sub(1,4), function(val) --callback
            --format e.g. N12°34.56 must be convert to 1234.5N
            fmgs_dat["lat fmt"] = val:sub(2,3) .. val:sub(6,9) .. val:sub(1,1)
            --format e.g. W123°45.67 must be convert to 12345.67W
            fmgs_dat["lon fmt"] = val:sub(13,15) .. val:sub(18,22) .. val:sub(12,12)
            print("lat lon upload")

            mcdu_open_page(400) -- reload

            --add listener for when ADIRS are turned on
            mcdu_ctrl_add_listener(0,                       --default value
                function () return get(Adirs_sys_on) end,   --get data function
                function ()                                 --callback
                    --IRS are online but not aligned?
                    if get(Adirs_irs_aligned) == 0 and get(Adirs_sys_on) == 1 then
                        fmgs_dat["irs aligned"] = "show"
                        fmgs_dat["latlon sel"] = "lat"
                    end

                    --set lat
                    --format e.g. 1234.5N
                    fmgs_dat["lat"] = tonumber(fmgs_dat["lat fmt"]:sub(1,6))
                    fmgs_dat["lat_dir"] = fmgs_dat["lat fmt"]:sub(7,7)

                    --set lon
                    --format e.g. 12345.67W
                    fmgs_dat["lon"] = tonumber(fmgs_dat["lon fmt"]:sub(1,8))
                    fmgs_dat["lon_dir"] = fmgs_dat["lon fmt"]:sub(9,9)

                    --if on init page, reload it
                    if get(mcdu_page) == 400 then
                        mcdu_open_page(400) -- reload
                    end
                end
            )

            --get SID
            fmgs_dat["runways"] = {}
            terminate = false
            mcdu_ctrl_get_runways_origin(function (val) --accessor callback
            --val is runway name
            runway_name = val:sub(22,24)
            --is there any more runways?
            if not terminate then
                --is this not a blank line?
                if runway_name ~= "   " then

                    --get runway length
                    airport = fmgs_dat["origin"]:upper()

                    index = 0
                    mcdu_ctrl_get_runway_length(
                        airport .. runway_name, --input arg
                        runway_name, --refcon arg
                        function (val, refcon) --callback arg
                            --val is runway length
                            --format e.g. from  9420FT to 9420
                            runway_length = ""
                            --start after space, so at i = 2 not i = 1
                            for i = 2, string.len(val) do
                                --has it reached f in FT?
                                if val:sub(i,i) == "F" then
                                    break
                                end
                                runway_length = val:sub(2,i)
                            end
                            --refcon is runway_name
                            runway_name = refcon

                            --record name and length
                            table.insert(fmgs_dat["runways"], {index = index, name = runway_name, length = runway_length})

                            index = index + 1
                        end
                    ) --end callback
                else
                    --all runways recorded. stop
                    fmgs_dat["terminate"] = true
                end
            end

            end) --end callback
            end) --end callback
            end) --end callback
            end) --end callback

            mcdu_open_page(400) -- reload
        end
    end

    -- align irs>
    if phase == "R3" then
        --is the irs not aligned?
        if fmgs_dat["irs aligned"] == "show" then
            fmgs_dat["irs aligned"] = "hide"    --hide irs align>
            fmgs_dat["latlon sel"] = "nil"      --stop lat/lon selection
        end
        mcdu_open_page(400) -- reload
    end

    -- tropo
    if phase == "R6" then
        input = mcdu_get_entry("!!!")
        fmgs_dat["tropo"] = input * 100
        mcdu_open_page(400) -- reload
    end

    -- slew left/right (used for lat lon)
    if phase == "slew_left" or phase == "slew_right" then
        --toggle between lat and lon select
        fmgs_dat["latlon sel"] = mcdu_toggle(fmgs_dat["latlon sel"], "lat", "lon")
        mcdu_open_page(400) -- reload
    end

    -- slew up (used for lat lon)
    if phase == "slew_up" or phase == "slew_down" then
        if phase == "slew_up" then
            increment = 1
        else
            increment = -1
        end
        if fmgs_dat["latlon sel"] == "lat" then
            --change lat from 0-9000.0
            fmgs_dat["lat"] = Math_clamp(fmgs_dat["lat"] + increment * 0.1, 0, 9000)
            --flip
            if fmgs_dat["lat"] == 0 or fmgs_dat["lat"] == 9000 then
                fmgs_dat["lat"] = fmgs_dat["lat"] - increment * 0.1
                fmgs_dat["lat_dir"] = mcdu_toggle(fmgs_dat["lat_dir"], "N", "S") --flip
            end
            --padding decimal
            fmgs_dat["lat"] = mcdu_pad_dp(fmgs_dat["lat"], 1)
            --assign
            fmgs_dat["lat fmt"] = fmgs_dat["lat"] .. fmgs_dat["lat_dir"]
        elseif fmgs_dat["latlon sel"] == "lon" then
            --change lon from 0-180000.00
            fmgs_dat["lon"] = Math_clamp(fmgs_dat["lon"] + increment * 0.01, 0, 18000)
            --flip
            if fmgs_dat["lon"] == 0 or fmgs_dat["lon"] == 18000 then
                fmgs_dat["lon"] = fmgs_dat["lon"] - increment * 0.01
                fmgs_dat["lon_dir"] = mcdu_toggle(fmgs_dat["lon_dir"], "W", "E") --flip
            end
            --padding decimal
            fmgs_dat["lon"] = mcdu_pad_dp(fmgs_dat["lon"], 2)
            --assign
            fmgs_dat["lon fmt"] = fmgs_dat["lon"] .. fmgs_dat["lon_dir"]
        end
        mcdu_open_page(400) -- reload
    end
end

-- 402 IRS
mcdu_sim_page[100] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "        irs init"

		mcdu_dat["s"]["L"][3].txt = "   irs1 off"
        mcdu_dat["l"]["L"][3].txt = "    --'--.--/---'--.--"
		mcdu_dat["s"]["L"][4].txt = "   irs2 off"
        mcdu_dat["l"]["L"][4].txt = "    --'--.--/---'--.--"
		mcdu_dat["s"]["L"][5].txt = "   irs3 off"
        mcdu_dat["l"]["L"][5].txt = "    --'--.--/---'--.--"
		mcdu_dat["l"]["L"][6].txt = "<return"

        draw_update()
    end
end

-- 500 data
mcdu_sim_page[500] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "     data index"

        mcdu_dat["s"]["L"][1].txt = " position"
        mcdu_dat["l"]["L"][1].txt = "<monitor"
        mcdu_dat["s"]["L"][2].txt = " irs"
        mcdu_dat["l"]["L"][2].txt = "<monitor"
        mcdu_dat["s"]["L"][3].txt = " gps"
        mcdu_dat["l"]["L"][3].txt = "<monitor"
        mcdu_dat["l"]["L"][4].txt = "<a/c status"

        draw_update()
    end
    if phase == "L4" then
        mcdu_open_page(505) -- open 505 data A/C status
    end
end

-- 505 data A/C status
mcdu_sim_page[505] =
function (phase)
    if phase == "render" then

        mcdu_dat["s"]["L"][1].txt = " eng"

        if get(Engine_option) == 0 then
            mcdu_dat_title.txt = "        a321-521nx"
            mcdu_dat["l"]["L"][1] = {txt = "cfm-leap-1a", col = "green"}
        else
            mcdu_dat_title.txt = "        a321-721nx"
            mcdu_dat["l"]["L"][1] = {txt = "pw-1130g-jm", col = "green"}
        end
        
        mcdu_dat["s"]["L"][2].txt = " active data base"
        mcdu_ctrl_get_cycle(function(val)
            mcdu_dat["l"]["L"][2] = {txt = val, col = "blue"}
            draw_update()
        end)
        mcdu_dat["s"]["L"][3].txt = " second data base"
        mcdu_dat["l"]["L"][3] = {txt = " none", col = "blue", size = "s"}

        mcdu_dat["s"]["L"][5].txt = "chg code"
        mcdu_dat["l"]["L"][5] = {txt = "[ ]", col = "blue"}
        mcdu_dat["s"]["L"][6].txt = "idle/perf"
        mcdu_dat["l"]["L"][6] = {txt = "+0.0/+0.0", col = "green"}

        mcdu_dat["l"]["R"][6].txt = "options>"

       
        draw_update()
    end
    if phase == "R6" then
        mcdu_open_page(1101) -- open 1101 mcdu menu options
    end
end

fmgs_dat["fpln"] = {}
fmgs_dat["fpln fmt"] = {}

local function fpln_addwpt(loc, via, name, trk, time, dist, spd, alt, efob, windspd, windhdg, next)
    wpt = {}
    wpt.name = name or ""
    wpt.time = time or "----"
    wpt.dist = dist or ""
    wpt.spd = spd or "---"
    wpt.alt = alt or "-----"
    wpt.via = via or ""
    wpt.trk = trk or ""
    wpt.next = next
    wpt.efob = efob or 5.5
    wpt.windspd = windspd or 0
    wpt.windhdg = windhdg or 0
    table.insert(fmgs_dat["fpln"], loc, wpt)
end

--formats the fpln
local function fpln_format()
    --init local variables
    fpln_fmt = {}
    fpln = fmgs_dat["fpln"]

    --init previous waypoint to first
    wpt_prev = {next = fpln[1].name}

    for i,wpt in ipairs(fpln) do
        --is waypoint a blank?
        if wpt.name ~= "" then
            --check for flight discontinuities
            if wpt_prev.next ~= wpt.name then
                table.insert(fpln_fmt, "---f-pln discontinuity--")
            end
            --insert waypoint
            table.insert(fpln_fmt, wpt)
            --set previous waypoint
            wpt_prev = wpt
        end
    end
    table.insert(fpln_fmt, "----- end of f-pln -----")
    table.insert(fpln_fmt, "----- no altn fpln -----")

    --output
    fmgs_dat["fpln fmt"] = fpln_fmt
end
-- loc via name trk time dist spd alt efob windspd windhdg next
fpln_addwpt(1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)

--DEMO
--table.remove(fmgs_dat["fpln"])
fpln_addwpt(1, nil, "kbfi", nil, nil, nil, nil, nil, nil, nil, nil, nil) 
fpln_addwpt(1, "chins3", "humpp", nil, 2341, 14, 297, 15000, nil, nil, nil, "aubrn")
fpln_addwpt(1, nil, "ksea", nil, nil, nil, nil, nil, nil, nil, nil, "humpp")

-- 600 f-pln
mcdu_sim_page[600] =
function (phase)
    if phase == "render" then
        fmgs_dat_init("fpln index", 0)
        fmgs_dat_init("fpln page", 1)
        --format the fpln
        fpln_format()
        --initialize fpln page index
        fpln_index = fmgs_dat["fpln index"]
        --draw the f-pln
        for i = 1, math.min(#fmgs_dat["fpln fmt"], 5) do
            --increment fpln index, loop around flight plan.
            fpln_index = fpln_index % #fmgs_dat["fpln fmt"] + 1

            fpln_wpt = fmgs_dat["fpln fmt"][fpln_index] or ""
            --is it a simple message?
            if type(fpln_wpt) == "string" then
                mcdu_dat["l"]["L"][i].txt = fpln_wpt
            --is it a waypoint?
            else
                --set title
                if i == 1 and fpln_wpt.name:sub(1,4) == fmgs_dat["origin"] then
                    mcdu_dat_title.txt = " from"
                end
                --[[ VIA --]]
                --is via an airway/note or heading?
                if type(fpln_wpt.via) == "string" then
                    --is via an airway or note?
                    if fpln_wpt.via:sub(1,1) ~= "(" then
                        mcdu_dat["s"]["L"][i][1] = {txt = " " .. fpln_wpt.via}
                    --via must be a note
                    else
                        mcdu_dat["s"]["L"][i][1] = {txt = " " .. fpln_wpt.via, col = "green"}
                    end
                --via must be a heading
                else
                    mcdu_dat["s"]["L"][i][1] = {txt = " H" .. fpln_wpt.via .. "°"}
                end

                --[[ NAME --]]
                mcdu_dat["l"]["L"][i][1] = {txt = fpln_wpt.name, col = "green"}

                --[[ TRK --]]
                mcdu_dat["s"]["L"][i][2] = {txt = "        " .. fpln_wpt.trk, col = "green"}

                --[[ DIST --]]
                mcdu_dat["s"]["R"][i] = {txt = fpln_wpt.dist .. "     ", col = "green", size = "s"}

                if fmgs_dat["fpln page"] == 1 then
                    --[[ TIME --]]
                    mcdu_dat["l"]["L"][i][2] = {txt = "        " .. fpln_wpt.time, col = "green", size = "s"}

                    --[[ SPD --]]
                    mcdu_dat["l"]["R"][i][1] = {txt = fpln_wpt.spd .. "/      ", col = "green", size = "s"}

                    --[[ ALT --]]
                    mcdu_dat["l"]["R"][i][2] = {txt = fpln_wpt.alt, col = "green", size = "s"}
                else
                    --[[ EFOB --]]
                    mcdu_dat["l"]["L"][i][2] = {txt = "        " .. fpln_wpt.efob, col = "green", size = "s"}

                    --[[ WIND SPD --]]
                    mcdu_dat["l"]["R"][i][1] = {txt = mcdu_align_left(fpln_wpt.windspd, 3), col = "green", size = "s"}

                    --[[ WIND ALT --]]
                    mcdu_dat["l"]["R"][i][2] = {txt = mcdu_pad_num(fpln_wpt.windhdg, 3) ..  "°/   ", col = "green", size = "s"}
                end
            end
        end

        --[[ DEST --]]
        mcdu_dat["s"]["L"][6] = {txt = "dest    time  "}
        mcdu_dat["s"]["R"][6] = {txt = "dist  efob"}
        --the last index of the f-pln must be the destination
        dest_index = #fmgs_dat["fpln"]
        dest_wpt = fmgs_dat["fpln"][dest_index]
        mcdu_dat["l"]["L"][6][1] = {txt = dest_wpt.name}
        mcdu_dat["l"]["L"][6][2] = {txt = "        " .. dest_wpt.time}
        --formatting
        if dest_wpt.dist == "" then
            mcdu_dat["l"]["R"][6][2] = {txt = "-----      "}
        else
            mcdu_dat["l"]["R"][6][2] = {txt = dest_wpt.dist .. "      "}
        end
        --formatting
        if dest_wpt.efob == "" then
            mcdu_dat["l"]["R"][6][1] = {txt = "--.- "}
        else
            mcdu_dat["l"]["R"][6][1] = {txt = dest_wpt.efob .. " "}
        end

        draw_update()
    end

    --if any of the side buttons are pushed
    if phase:sub(1,1) == "R" or phase:sub(1,1) == "L" then

        index = phase:sub(2,2)
        wpt_check = mcdu_dat["l"]["L"][tonumber(index)][1] or "invalid"

        --if valid wpt, open 601 f-pln lat rev page
        if wpt_check ~= "invalid" then
            fmgs_dat["lat rev wpt"] = wpt_check.txt
            mcdu_open_page(601) -- 601 f-pln lat rev page
        end
    end

    -- slew left/right (used for lat lon)
    if phase == "slew_left" or phase == "slew_right" then
        --toggle between lat and lon select
        fmgs_dat["fpln page"] = mcdu_toggle(fmgs_dat["fpln page"], 1, 2)
        mcdu_open_page(600) -- reload
    end

    --slew up or down
    if phase == "slew_up" or phase == "slew_down" then
        if phase == "slew_up" then
            increment = -1
        else
            increment = 1
        end
        --is flight plan long enough to slew up and down?
        if #fmgs_dat["fpln fmt"] > 2 then
            fmgs_dat["fpln index"] = fmgs_dat["fpln index"] % #fmgs_dat["fpln fmt"] + increment 
            print(fmgs_dat["fpln index"])
        end
        mcdu_open_page(600)
    end
end

-- 601 f-pln lat rev page
mcdu_sim_page[601] =
function (phase)
    if phase == "render" then
        fmgs_dat_init("lat rev wpt", "none")
        --get the wpt in question's name
        wpt_find_name = fmgs_dat["lat rev wpt"]
        wpt = "invalid"
        --find the wpt data with the name
        for i, wpt_find in ipairs(fmgs_dat["fpln"]) do
            if wpt_find.name == wpt_find_name then
                wpt = wpt_find
                break
            end
        end
        if wpt == "invalid" then
            mcdu_send_message("error 601 " .. wpt_find_name) --throw error!
            return
        end
        mcdu_dat_title[1] = {txt = "   lat rev"}
        mcdu_dat_title[2] = {txt = "           from", size = "s"}
        mcdu_dat_title[3] = {txt = "                " .. wpt.name, col = "green"}

        --get lat lon
        fmgs_dat_init("lat fmt2", "")
        fmgs_dat_init("lon fmt2", "")
        if fmgs_dat["lat fmt2"] == "" then
            --get lat lon from XP FMC
            mcdu_ctrl_get_origin_latlon(wpt.name, function(val) --callback
            --Nxx''xx.xx Wxxx''xx.xx
            fmgs_dat["lat fmt2"] = val:sub(2,9) .. val:sub(1,1)
            fmgs_dat["lon fmt2"] = val:sub(13,21) .. val:sub(12,12)

            mcdu_open_page(601) -- reload
            end) --end callback
        end

        mcdu_dat["s"]["L"][1] = {txt = "   " .. fmgs_dat["lat fmt2"] .. "/" .. fmgs_dat["lon fmt2"], col = "green"}

        mcdu_dat["s"]["R"][2].txt = "ll xing/incr/no"
        mcdu_dat["l"]["R"][2] = {txt = "[  ]°/[ ]°/[ ]", col = "blue"}

        mcdu_dat["s"]["R"][3].txt = "next wpt "
        mcdu_dat["l"]["R"][3] = {txt = "[    ]", col = "blue"}
        --if wpt is not dept airport
        if wpt.name:upper():sub(1,4) ~= fmgs_dat["dest"] then
            mcdu_dat["s"]["R"][4].txt = "new dest "
            mcdu_dat["l"]["R"][4] = {txt = "[  ]", col = "blue"}
        end

        --is wpt the dept airport?
        if wpt.name:upper():sub(1,4) == fmgs_dat["origin"] then
            mcdu_dat["l"]["L"][1].txt = "<departure"
            mcdu_dat["l"]["R"][1].txt = "fix info>"
        --is wpt the dept airport?
        elseif wpt.name:upper():sub(1,4) == fmgs_dat["dest"] then
            mcdu_dat["l"]["R"][1].txt = "arrival>"
            mcdu_dat["l"]["L"][3].txt = "<altn"
        end

        mcdu_dat["l"]["L"][6].txt = "<return"

        draw_update()
    end
    
    --departure
    if phase == "L1" then
        --is wpt the dept airport?
        if wpt.name:upper():sub(1,4) == fmgs_dat["origin"] then
            mcdu_open_page(602) -- open 602 f-pln lat rev page dept airport
        end
    end
    --arrival/fix info
    if phase == "R1" then
        --is wpt the dept airport?
        if wpt.name:upper():sub(1,4) == fmgs_dat["dest"] then
            mcdu_open_page(603) -- open 603 f-pln lat rev page dest airport
        else
            mcdu_send_message("not yet implemented!")
        end
    end
    --altn
    if phase == "L3" then
        --is wpt the dept airport?
        if wpt.name:upper():sub(1,4) == fmgs_dat["origin"] then
            mcdu_open_page(602) -- open 602 f-pln lat rev page dept airport
        end
    end
    if phase == "R2" or phase == "R3" or phase == "R4" then
        mcdu_send_message("not yet implemented!")
    end
    if phase == "L6" then
        mcdu_open_page(600) -- open 600 f-pln
    end
end

fmgs_dat["origin"] = "KSEA"
fmgs_dat["dest"] = "KBFI"

-- 602 f-pln lat rev page dept airport
mcdu_sim_page[602] =
function (phase)
    if phase == "render" then
        mcdu_dat_title[1] = {txt = " departure"}
        mcdu_dat_title[2] = {txt = "             from", size = "s"}
        mcdu_dat_title[3] = {txt = "                  " .. wpt.name, col = "green"}

        mcdu_dat["s"]["L"][1].txt = " rwy      sid     trans"
        mcdu_dat["l"]["L"][1].txt = " ---     ------  ------"
            
        mcdu_dat["s"]["L"][2].txt = " available runways"
        line = 2
        offset = 1
        fmgs_dat["offset"] = 0

        --set airport in question
        airport = fmgs_dat["origin"]
        for i,runway in ipairs(fmgs_dat["runways"]) do
            --get ILS data
            ils = mcdu_ctrl_get_nav(airport .. " " .. runway.name, NAV_ILS)

            --get ILS freq
            --format e.g. 11170 to 111.70
            ils.freq = tostring(ils.freq)
            freq = ils.freq:sub(1,3) .. "." .. ils.freq:sub(5,7)

            --get ILS crs
            ils.hdg = degTrueToDegMagnetic(ils.hdg)
            if ils.hdg > 180 then
                --format e.g. 342 to -18
                ils.hdg = ils.hdg - 360
            end
            --how many digits?
            ils.hdg = tostring(ils.hdg)
            if string.len(ils.hdg) == 1 then
                hdg = ils.hdg:sub(1,1)
            elseif string.len(ils.hdg) == 2 then
                hdg = ils.hdg:sub(1,2)
            else
                hdg = ils.hdg:sub(1,3)
            end
            
            --format e.g. from RW16C to 16C

            mcdu_dat["l"]["L"][line] = {txt = "<" .. runway.name .. "   " .. runway.length .. "FT", col = "blue"}
            mcdu_dat["l"]["R"][line] = {txt = "crs" .. hdg .. "   ", col = "blue", size = "s"}
            --display runway length
            mcdu_dat["s"]["L"][line + 1] = {txt = "       ILS", col = "blue"}
            mcdu_dat["s"]["R"][line + 1] = {txt = ils.id .. "/" .. freq, col = "blue"}

            --does runway length already exist for this runway?
            line = ((line + 1) % 4) + 2
        end

        mcdu_dat["l"]["L"][6].txt = "<return"

        draw_update()
    end
    
    if phase == "R2" or phase == "R3" or phase == "R4" then
        mcdu_send_message("not yet implemented!")
    end
    if phase == "L6" then
        mcdu_open_page(600) -- open 600 f-pln
    end
    if phase == "slew_up" or phase == "slew_down" then
        if phase == "slew_up" then
            offset = offset + 1
        else
            offset = offset - 1
        end
        mcdu_open_page(600) -- open 600 f-pln
    end
end

-- 603 f-pln lat rev page dest airport
mcdu_sim_page[603] =
function (phase)
    if phase == "render" then
        mcdu_dat_title[1] = {txt = " arrival"}
        mcdu_dat_title[2] = {txt = "           from", size = "s"}
        mcdu_dat_title[3] = {txt = "                  " .. wpt.name, col = "green"}

        mcdu_dat["l"]["L"][6].txt = "<return"

        draw_update()
    end
    
    if phase == "R2" or phase == "R3" or phase == "R4" then
        mcdu_send_message("not yet implemented!")
    end
    if phase == "L6" then
        mcdu_open_page(600) -- open 600 f-pln
    end
end

-- 700 rad nav
mcdu_sim_page[700] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "        radio nav"
        mcdu_dat["s"]["L"][1].txt = "vor1/freq"

        mcdu_dat["l"]["L"][1][1] = {txt = " [ ]", col = "blue"}
        mcdu_dat["l"]["L"][1][2] = {txt = "    /111.00", col = "blue", size = "s"}

        mcdu_dat["s"]["R"][1].txt = "freq/vor2"

        mcdu_dat["l"]["R"][1][1] = {txt = "[ ] ", col = "blue"}
        mcdu_dat["l"]["R"][1][2] = {txt = "110.90/    ", col = "blue", size = "s"}

        mcdu_dat["s"]["L"][2].txt = "crs"
        mcdu_dat["l"]["L"][2] = {txt = "315", col = "blue"}
        mcdu_dat["s"]["R"][2].txt = "crs"
        mcdu_dat["l"]["R"][2] = {txt = "315", col = "blue"}

        mcdu_dat["s"]["L"][3].txt = "ils /freq"
        mcdu_dat["l"]["L"][3][1] = {txt = "[  ]", col = "blue"}
        mcdu_dat["l"]["L"][3][2] = {txt = "    /08.10", col = "blue", size = "s"}

        mcdu_dat["s"]["R"][3].txt = "chan/ mls"
        mcdu_dat["l"]["R"][3].txt = "---/--- "

        mcdu_dat["s"]["L"][4].txt = "crs"
        mcdu_dat["l"]["L"][4].txt = "---"

        mcdu_dat["s"]["R"][4].txt = "slope   crs"
        mcdu_dat["l"]["R"][4].txt = " -.-    ---"

        mcdu_dat["s"]["L"][5].txt = "adf1/freq"
        mcdu_dat["l"]["L"][5][1] = {txt = " [ ]", col = "blue"}
        mcdu_dat["l"]["L"][5][2] = {txt = "    / 210.0", col = "blue", size = "s"}

        mcdu_dat["s"]["R"][5].txt = "freq/adf2"
        mcdu_dat["l"]["R"][5][1] = {txt = "[ ] ", col = "blue"}
        mcdu_dat["l"]["R"][5][2] = {txt = "210.0/    ", col = "blue", size = "s"}

        draw_update()
    end
end

-- 800 fuel pred
mcdu_sim_page[800] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          fuel pred"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

-- 900 sec f-pln
mcdu_sim_page[900] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          sec f-pln"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

-- 1000 atc comm
mcdu_sim_page[1000] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          atc comm"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

-- 1100 mcdu menu
mcdu_sim_page[1100] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "        mcdu menu"
        mcdu_dat["l"]["L"][1].txt = "<fmgc"

        mcdu_dat["l"]["R"][6].txt = "options>"
        draw_update()
    end
    if phase == "L1" then
        mcdu_open_page(505) -- open 505 data a/c status
    end
    if phase == "R6" then
        mcdu_open_page(1101) -- open 1101 mcdu menu options
    end
end

-- 1101 mcdu menu options
mcdu_sim_page[1101] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "     a32nx project"

        mcdu_dat["l"]["L"][1].txt = "<about"
        mcdu_dat["l"]["L"][2].txt = "<colours"

        mcdu_dat["s"]["R"][1].txt = "developers"
        mcdu_dat["l"]["R"][1] = {txt = "jonathan orr", col = "blue"}
        mcdu_dat["l"]["R"][2] = {txt = "henrick ku", col = "green"}
        mcdu_dat["s"]["R"][3].txt = "mcdu written by"
        mcdu_dat["l"]["R"][3] = {txt = "chaidhat chaimongkol", col = "orange"}

        draw_update()
    end
    if phase == "L1" then
        mcdu_open_page(1102) -- open 1102 mcdu menu options about
    end
    if phase == "L2" then
        mcdu_open_page(1103) -- open 1103 mcdu menu options colours
    end
    if phase == "R6" then
        mcdu_open_page(1100) -- open 1100 mcdu menu
    end
end

local function mcdu_set_colour(colour)
        --format e.g. r0.00
        input, variation = mcdu_get_entry({"r!.!!", "g!.!!", "b!.!!"})
        --check for correct entry
        if input ~= NIL then
            print(input)
            input_col = input:sub(2,2) .. "." .. string.sub(input, 4,5)
            MCDU_DISP_COLOR[colour][variation] = input_col

            mcdu_open_page(1103) -- reload page
        else
            mcdu_send_message("format e.g. b0.50")
        end
end

-- 1102 mcdu menu options about
mcdu_sim_page[1102] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "     a32nx about"
        mcdu_dat["s"]["L"][1].txt = "mcdu version"
        mcdu_dat["l"]["L"][1].txt = "v1.0"
        mcdu_dat["s"]["L"][2].txt = "license"
        mcdu_dat["l"]["L"][2].txt = "gpl 3.0"
        mcdu_dat["s"]["L"][3].txt = "github.com"
        mcdu_dat["l"]["L"][3].txt = "jonathanorr/a321neo-fxpl"

        mcdu_dat["l"]["R"][6].txt = "return>"

        draw_update()
    end
    if phase == "R6" then
        mcdu_open_page(1101) -- open 1101 mcdu menu options
    end
end

-- 1103 mcdu menu options colours
mcdu_sim_page[1103] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "     a32nx colours"
        for i,col in ipairs({"white", "blue", "green", "orange"}) do
            mcdu_dat["s"]["L"][i].txt = col .. " colour"
            mcdu_dat["l"]["L"][i] = {txt = "<R" .. MCDU_DISP_COLOR[col][1] .. "G" .. MCDU_DISP_COLOR[col][2] .. "B" .. MCDU_DISP_COLOR[col][3], col = col}
        end
        mcdu_dat["l"]["L"][5].txt = "format e.g. r0.10"
        mcdu_dat["l"]["L"][6].txt = "<disco mode"

        mcdu_dat["l"]["R"][6].txt = "return>"
        draw_update()
    end
    if phase == "L1" then
        mcdu_set_colour("white")
    end
    if phase == "L2" then
        mcdu_set_colour("blue")
    end
    if phase == "L3" then
        mcdu_set_colour("green")
    end
    if phase == "L4" then
        mcdu_set_colour("orange")
    end
    if phase == "L6" then
        hokey_pokey = true
        for i,f in ipairs({"white", "blue", "orange", "green"}) do
            MCDU_DISP_COLOR[f] = {1, 0, 0} 
        end
    end
    if phase == "R6" then
        mcdu_open_page(1101) -- open 1101 mcdu menu options
    end
end

-- 1200 air port
mcdu_sim_page[1200] =
function (phase)
    if phase == "render" then
        mcdu_dat_title.txt = "          air port"

        mcdu_dat["l"]["L"][1].txt = "not yet implemented"

        draw_update()
    end
end

