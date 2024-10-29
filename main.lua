meta = {
    name = "Lazarus Ankh",
    version = "10.5",
    author = "Nitroxy",
    description = "On death revive and gain 0.5 minutes on your time\n\nFeatures:\n"
}

-- 56

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
local sval = false;

--Remember time
local stime = 0;

--Penalty
local penalty = 30*SEC;

-- Emergency button Penalty
local eb_penalty = 3*MIN;

--Locks input for n frames
--local hold_timer = 0;

--Used to determine the phase of the ankh for skipping the ankh cutscene
local ankh_flag = 0;


-- Idea from PeterSCP
local function format_time(time)
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

-- Set the ushabti to a random one
local function schrodingers_ushabti()
    local random_pick = math.random(0, 99)
    local result = tonumber(random_pick, 12)
    state:set_correct_ushabti(result)
end

-- Add the penalty time
local function add_time(time)
    state.time_total = state.time_total + time;
end

-- instant restart protection part 2
set_callback(function()
    sval = false;
    state.time_total = stime;
    if stime == 1 then
        schrodingers_ushabti()
    end
end, ON.START)

-- instant restart protection part 1
-- Now includes the automatic seed insertion
set_callback(function()
    if state.pause & 1 == 1 and state.pause & 2 == 2 then
        stime = state.time_total;
    else
        stime = 1;
    end

    -- Auto-import seeds
    if state.screen == SCREEN.CHARACTER_SELECT then
        local type = 16
        if tonumber(options.ab_seed, type) == nil then
            print("Invalid Seed!")
            error("Invalid Seed!")
        else
            --state.seed = sign_int(temp);
            state.seed = tonumber(options.ab_seed, type);
            print("Updated seed!");
        end
    else
        if state.screen == SCREEN.SEED_INPUT or state.screen == SCREEN.CAMP then
            print("You need to be in the Character Select screen to update the seed!");
            error("You need to be in the Character Select screen to update the seed!");
        end
    end
end, ON.RESET)


-- Short CO finisher (Unused atm)
-- Giving the ankh
-- Ankh health gain
set_callback(function()

    -- faster ankh
    if options.e_ankhskip then
        modify_ankh_health_gain(4, 4)
    else
        modify_ankh_health_gain(4, 1)
    end
    
    -- "End game" bugfix done by peterscp
    -- Also fixes duat
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
                hold_timer = 2*SEC;
            end
        end
        ]]

    local has_ankh = get_player(1, false):has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
    if has_ankh == false then
        -- time penalty
        get_player(1, false):give_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
        if sval then
            add_time(penalty);
        else
            sval = true;
        end
    end
end, ON.FRAME)

-- olmec ankh
set_post_entity_spawn(function(ent)
    ent = ent --[[@as Powerup]]
    ent:set_pre_picked_up(function()
        sval = false;
        add_time(-10*SEC)
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_PICKUP_ANKH)

-- exports seed
set_callback(function()
    options.ab_seed = string.format("%08X", state.seed);
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

    -- Main part of ankh skip
    if options.e_ankhskip then
        local ankhs = get_entities_by_type(ENT_TYPE.ITEM_POWERUP_ANKH);
        for i, v in pairs(ankhs) do
            local ankh = get_entity(v) --[[@as AnkhPowerup]]

            -- This should be able to replace the previous flag stuff
            if ankh.timer1 == 0 then
                ankh_flag = 0;
            elseif ankh.timer1 == 1 then
                ankh_flag = 1;
                --print("Do")
            -- Manual lockout to prevent the ankhskip from softlocking
    	    elseif ankh.timer1 > 677 then
                return
            end

            --ankh.x = 0;
            --ankh.y = 0;
            if ankh_flag == 1 then
                if ankh.timer2 > 1 then
                    -- You need to put it to any number above 100
                    ankh.timer2 = 120;
                    ankh_flag = ankh_flag + 1;
                    --print("Re")
                end
            elseif ankh_flag == 2 then
                -- You need to put it to any number below 120, 119 being optimal
                if 20 < ankh.timer2 and ankh.timer2 < 120 then
                    ankh.timer2 = 119;
                    ankh_flag = ankh_flag + 1;
                    --print("Mi")
                    -- no more extra flags, it just prevents more stages
                end
            end
        end
    end
end, ON.POST_UPDATE)

--[[
set_callback(function ()
    if hold_timer > 0 then
        hold_timer = hold_timer - 1;
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
register_option_string("ab_seed", "Seed input", "Automatically inserts seed of the run in the character select screen.\nAlso automatically inserts the seed at the start of the run", "");

-- imports seed
register_option_button("b_button_seed", "Update seed", "Use the \"Seed input\" field to enter an external seed\nThen press the button to update the seed\nMake sure you are in the character select screen before using it",
function ()
    if state.screen == SCREEN.CHARACTER_SELECT then
        local type = 16

        if tonumber(options.ab_seed, type) == nil then
            print("Invalid Seed!")
            error()
        else
            state.seed = tonumber(options.ab_seed, type);
            print("Updated seed!");
        end
    else
        print("You need to be in the Character Select screen to update the seed!");
        error();
    end
end)

-- emergency button
register_option_button("c_EB", "Emergency button", "Gives you a free qilin to qilin skip with. Adds a 3 minute penalty on your time", function()
    -- test if you are in tiamat
    if options.ca_emergency_lock then
        if state.theme ~= THEME.TIAMAT then
            print("You need to be in tiamat to use the emergency button!");
            error()
            return
        end
    end

    if options.cb_ej then
        local jayjay = spawn_on_floor(ENT_TYPE.ITEM_JETPACK, math.floor(0), math.floor(0), LAYER.PLAYER);
        pick_up(get_player(1, false).uid, jayjay);

        if options.cc_bonus_rope then
            get_player(1, false).inventory.ropes = get_player(1, false).inventory.ropes + 1;
        end
    else
        local jayjay = spawn_on_floor(ENT_TYPE.MOUNT_QILIN, math.floor(0), math.floor(0), LAYER.PLAYER1);
        local the_boi = get_entity(jayjay) --[[@as Qilin]]
        the_boi.tamed = true
        --carry(jayjay, get_player(1, false).uid);
        the_boi:carry(get_player(1, false))
    end
    add_time(eb_penalty); -- 3 minutes
end)

register_option_bool("ca_emergency_lock", "Disable emergency button lock", "", true);

register_option_bool("cb_ej", "Emergency Jetpack", "Replaces the qilin with the jetpack (the original emergency button)", false)

register_option_bool("cc_bonus_rope", "Bonus rope", "Gives you one rope when using the emergency (jetpack) button. Requires the emergency jetpack option to be on", true)

register_option_bool("d_cutskip", "Cutscene skip", "", true);

register_option_bool("e_ankhskip", "Shorter Ankh animation", "", true);

-- register_option_bool("e_short_co", "Short CO Mode", "Limits the time to 30 minutes", false);

register_option_string("f_endtime", "Ending time", "", "00:00.000");

-- register_option_button('g_Ej', 'Emergency button', 'Gives a jetpack for a 3 minute penalty', function()

--register_option_string("f_endtime", "Ending time", "Also shows Short CO ending level!", "00:00.000");

--[[ stuff
register_option_int("g_deaths", "Total Deaths", "", 0, 0, 0)

--register_option_int("customaziation_omg", "Customization", "CUSTOMIZATION", 30, 0, 2147483647);

register_option_bool("counter", "count deaths", "enables a visual which shows how many times you died", true)

register_option_bool("a_custom", "custom position", "Be precise", false)
register_option_float("left", "left", "", -0.985, -1, 1)
register_option_float("top", "top", "", 0.910, -1, 1)
register_option_float("big", "big", "", 0.05, 0, 2)
]]

exports = {
    set_penalty = function(t_penalty)
        penalty = t_penalty;
    end
}
