---@diagnostic disable: lowercase-global
meta = {
    name = "Lazarus Ankh",
    version = "9.4",
    author = "Nitroxy",
    description = "On death revive and gain 0.5 minutes on your time\n\nFeatures:\n"
}

-- 43

--0.00034722222 days penalty

--[[ Todo:
    - Custom blue ankh sprite
    - If a real ankh is being picked up:
        - Revert the custom sprite
    - Add an option to toggle how big the penalty is (maybe)
    - Add a counter for each death
    - Remember backitem and give it back on death
    - Force path

    - Time without deaths
    - Death amount
]]

--Universal time in frames
SEC = 60;
MIN = 3600;

--Integer cap
INT_MAX = 2147483648;

--Start of the game gives the ankh without penalty. If sval == false, then you get no penalty
Sval = false;

--Remember time
Stime = 0;

--Penalty
Penalty = 30*SEC;

--checks change in option
Prev_SCO = false;

--Locks input for n frames
Hold_timer = 0;

-- instant restart protection part 2
set_callback(function()
    Sval = false;
    state.time_total = Stime;
end, ON.START)

-- instant restart protection part 1
set_callback(function()
    if state.pause | 1 and state.pause | 2 then
        Stime = state.time_total;
    else
        Stime = 0;
    end
end, ON.RESET)

--[[
Mainframe
Handles:
- Short CO finisher
- Giving the ankh
]]
set_callback(function()

        -- faster ankh
    if options.da_ankhskip then
        modify_ankh_health_gain(4, 4)
    else
        modify_ankh_health_gain(4, 1)
    end
    
    -- End game bugfix done by peterscp
    -- What does it meaaan
    if test_flag(state.level_flags, 21) then
        return;
    end

        --[[
        --Short CO finisher
        if options.e_short_co then
            if state.time_total >= 30*MIN then
                load_death_screen();
                if state.world * state.level > 1 then
                    -- Todo: Figure out 8-34
                    options.f_endtime = string.format("%d-%d", state.world, state.level);
                end
                --dont forget to remove on release
                print("hadhd");
                Hold_timer = 2*SEC;
            end
        end
        ]]

    local tval = false; --flag for ankh
    local items = players[1]:get_powerups();
    --[[
        Could be replaced with:
        if players[1]:has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH) then
    ]]
    for _,v in pairs(items) do
        if v == ENT_TYPE.ITEM_POWERUP_ANKH then
          -- do something
          tval = true;
          break;
        end
    end
    if tval == false then
        -- time penalty
        players[1]:give_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
        if Sval then
            add_time(Penalty);
        else
            Sval = true;
        end
    end
end, ON.FRAME)

-- olmec ankh
set_post_entity_spawn(function(ent)
    --[[
        Could be replaced with:
        ent:set_post/pre_picked_up(function())
    ]]
    ent:set_pre_destroy(function()
        --[[if killa == get_player(personalPlayerSlot, true) then
            lowBroke = true
            coBroke = true
        end
        ]]
        Sval = false;
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_PICKUP_ANKH)



-- exports seed
set_callback(function()
    if options.a_type then
        options.ab_seed = tostring(sign_int(state.seed));
    else
        --local temp = unsign_int(state.seed);
        options.ab_seed = string.format("%08X", state.seed);
    end
    print("Imported seed to seed input!");
end, ON.CHARACTER_SELECT)

-- Might be able to rewrite it to instead check for the win first, then the skip option, so you can save the end time regardless.
-- cutscene skip. huge thanks to Super Ninja Fat/superninjafat for the code!
set_callback(function()
    if options.d_cutskip then
        if state.loading == 2 then
            if state.screen == SCREEN.LEVEL and state.screen_next == SCREEN.WIN then
                state.screen_next = SCREEN.SCORES;
                state.end_spaceship_character = ENT_TYPE.CHAR_ANA_SPELUNKY; --not perfect
                options.f_endtime = format_time(state.time_total);
            end
        end
    end
end, ON.PRE_UPDATE)

--[[
set_callback(function ()
    if Hold_timer > 0 then
        Hold_timer = Hold_timer - 1;
        return true;
    end
end, ON.PRE_PROCESS_INPUT)
]]

-- wintime
--[[
set_callback(function ()
    prinspect(state.time_total);
    options.f_endtime = format_time(state.time_total);
end, ON.WIN)
]]


-- Options
register_option_bool("a_type", "Use old seed type", "", false);

register_option_string("ab_seed", "Seed input", "Automatically inserts seed of the run in the character select screen", "");

-- imports seed
register_option_button("b_button_seed", "Update seed", "Use the \"Seed input\" field to enter an external seed\nThen press the button to update the seed\nMake sure you are in the character select screen before using it",
function ()
    if state.screen == SCREEN.CHARACTER_SELECT then
        local type;
        if options.a_type then
            type = 10;
        else
            type = 16;
        end
        if tonumber(options.ab_seed, type) == nil then
            print("Invalid Seed!")
        else
            --state.seed = sign_int(temp);
            state.seed = tonumber(options.ab_seed, type);
            print("Updated seed!");
        end
    else
        print("You need to be in the Character Select screen to update the seed!");
    end
end)


-- emergency button
register_option_button('c_Ej', 'Emergency button', 'Gives a jetpack for a 3 minute penalty', function()
    -- test if you are in tiamat
    if options.ca_emergency_lock then
        if state.theme ~= THEME.TIAMAT then
            print("You need to be in tiamat to use the emergency button!");
            return
        end
    end
    local jayjay = spawn_on_floor(ENT_TYPE.ITEM_JETPACK, math.floor(0), math.floor(0), LAYER.PLAYER);
    pick_up(players[1].uid, jayjay);
    add_time(3*MIN); -- 3 minutes

    -- Add ropes
    if options.cb_bonus_rope then
        players[1].inventory.ropes = players[1].inventory.ropes + 1;
    end
end)

register_option_bool("ca_emergency_lock", "Disable emergency button lock", "", true);

register_option_bool("cb_bonus_rope", "Bonus rope", "Gives you one rope when using the emergency button", true)

register_option_bool("d_cutskip", "Cutscene skip", "", true);

register_option_bool("da_ankhskip", "Shorter Ankh animation", "", false);

-- register_option_bool("e_short_co", "Short CO Mode", "Limits the time to 30 minutes", false);

register_option_string("f_endtime", "Ending time", "", "00:00.000");
--register_option_string("f_endtime", "Ending time", "Also shows Short CO ending level!", "00:00.000");

--[[ stuff
--register_option_int("g_deaths", "Total Deaths", "", 0, 0, 0)

--register_option_int("customaziation_omg", "Customization", "CUSTOMIZATION", 30, 0, 2147483647);

register_option_bool("counter", "count deaths", "enables a visual which shows how many times you died", true)

register_option_bool("a_custom", "custom position", "Be precise", false)
register_option_float("left", "left", "", -0.985, -1, 1)
register_option_float("top", "top", "", 0.910, -1, 1)
register_option_float("big", "big", "", 0.05, 0, 2)
]]

-- Idea from PeterSCP
function format_time(time)
    local result;
    local frames = time % 60;
    time = math.floor(time / 60);
    local frametime = 1000 / 60;
    frames = math.floor(frametime * frames);
    local seconds = time % 60;
    time = math.floor(time / 60);
    local minutes = time % 60;
    --note: %02d makes 5 -> 05
    result = string.format("%02d:%02d.%03d", minutes, seconds, frames);
    time = math.floor(time / 60);
    if time > 0 then
        result = string.format("%02d:%s", time, result);
    end
    return result;
end

function sign_int(i)
    return (i+INT_MAX) % (INT_MAX*2) - INT_MAX;
end

function unsign_int(i)
    return (i) % (INT_MAX*2);
end

function add_time(time)
    state.time_total = state.time_total + time;
end

--string.format("%X", 255) -> FF
--tonumber("C", 16) -> 12
--tonumber("Incorrect Seed", 16) -> nil
--im even
--local f = (d+im) % (im*2) - im;
--back
--local e = (i+1) % (-im*2)+ im*2 - 1;

exports = {
    set_penalty = function(t_penalty)
        Penalty = t_penalty;
    end
}
