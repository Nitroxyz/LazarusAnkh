meta = {
    name = "Lazarus Ankh",
    version = "14.3.0",
    author = "Nitroxy",
    description = "The shiny racing mod"
}

-- 84

--0.00034722222 days penalty

--[[ Todo:
    - Custom blue ankh sprite
    - If a real ankh is being picked up:
        - Revert the custom sprite
    - Remember backitem and give it back on death
    - Force path

    - Time without death penalty
]]

local debug = require("debug_pack.lua")

--- variables ------------------------------------------------------------------------------------------------

--Universal time in frames
local SEC = 60;
local MIN = 3600;

--Pentalites
--[[ Normal
local PENALTY = {
    ANKH = 20*SEC,
    QILIN = 3*MIN,
    TQILIN = 1*MIN+30*SEC,
    JETPACK = 4*MIN,
    TJETPACK = 3*MIN,
    OLMEC = -20*SEC,
    SCO = 30*MIN,
}]]

--[[ Competitive times
PENALTY = {
    ANKH = 10*SEC,
    QILIN = 30*SEC,
    TQILIN = 15*SEC,
    JETPACK = 1*MIN,
    TJETPACK = 30*SEC,
    OLMEC = 0,
    SCO = 20*MIN,
}
]]

--[[ ShortCO
local SHORT_PENALTY = {
    ANKH = 60*SEC,
    QILIN = 2*MIN,
    TQILIN = 1*MIN,
    JETPACK = 2*MIN,
    TJETPACK = 1*MIN,
    OLMEC = 0*SEC,
}
]]

-- Profiles (W.i.P)
local PROFILES = {
    BASE = {
        ANKH = 20*SEC,
        QILIN = 3*MIN,
        TQILIN = 1*MIN+30*SEC,
        JETPACK = 4*MIN,
        TJETPACK = 3*MIN,
        OLMEC = -20*SEC,
        SCO = 30*MIN,
    },
    SHORT_CO = {
        ANKH = 60*SEC,
        QILIN = 2*MIN,
        TQILIN = 1*MIN,
        JETPACK = 2*MIN,
        TJETPACK = 1*MIN,
        OLMEC = 0*SEC,
    },
    COMP = {
        ANKH = 10*SEC,
        QILIN = 30*SEC,
        TQILIN = 15*SEC,
        JETPACK = 1*MIN,
        TJETPACK = 30*SEC,
        OLMEC = 0,
        SCO = 20*MIN,
    },
    CASUAL = {
        ANKH = 30*SEC,
        QILIN = 4*MIN,
        TQILIN = 2*MIN,
        JETPACK = 4*MIN,
        TJETPACK = 3*MIN,
        OLMEC = -10*SEC,
        SCO = 60*MIN,
    },
    OG = {
        ANKH = 30*SEC,
        QILIN = 3*MIN,
        TQILIN = 2*MIN,
        JETPACK = 4*MIN,
        TJETPACK = 3*MIN,
        OLMEC = -10*SEC,
        SCO = 30*MIN,
    }
}

-- Might need to set them, testing
--[[
options.da_cutskip = true
options.db_ankhskip = true
options.dc_nodark = true
]]

local STATE = {
    STARTING = 0,
    PLAYING = 1,
    FINISHED = 2,
    FORFEIT = 3,
}

-- Profiles
local ACTIVE_PROFILE = PROFILES.BASE
local PENALTY = PROFILES.BASE
-- New universal flag to tell if a new race has been started
local is_new_race = true
--If is_ankh_penalty == false, then you get no penalty on the next death
local is_ankh_penalty = true
--Remember total time for instant restarts
local stime = 1
--Used to determine the phase of the ankh for skipping the ankh cutscene
local ankh_flag = 0
--true when you picked up the olmec ankh the current run (not race)
local olmec_ankhed = false

local deaths = 0
-- When you die while cursed, you keep the cursed effect
local was_cursed = false
local cursed_lives = 0

local endtime_plus = ""

local player_state = STATE.STARTING

--- functions --------------------------------------------------------------------------------------------------

-- shorter calls
local function player()
    return get_player(1, false)
end

local function screen_level()
    return state.screen == SCREEN.LEVEL
end

local function in_game()
    return screen_level() or state.screen == SCREEN.TRANSITION
end

local function to_seed()
    local type = 16
    return tonumber(options.b_seed, type)
end

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
    local result = tonumber(tostring(random_pick), 12)
    state:set_correct_ushabti(result)
end

-- Add the penalty time
local function add_time(time)
    state.time_total = state.time_total + time
end

local function time_to_string(time, adjective)
    local minutes = math.floor(time/MIN)
    local seconds = math.floor(time%MIN/SEC)
    local result = ""
    if minutes > 0 then
        if minutes == 1 or adjective then
            result = string.format("%d minute", minutes)
        else
            result = string.format("%d minutes", minutes)
        end
    end
    if minutes > 0 and seconds > 0 then
        result = result .. " and "
    end
    if seconds > 0 then
        if seconds == 1 or adjective then
            result = result .. string.format("%d second", seconds)
        else
            result = result .. string.format("%d seconds", seconds)
        end
    end
    if result == "" then
        if adjective then
            result = "0 second"
        else
            result = "0 seconds"
        end
    end
    return result
end

local function update_endtime()
    options.f_endtime = format_time(state.time_total)
    local new_time = state.time_total-stime+1
    if olmec_ankhed then
        new_time = new_time-PENALTY.OLMEC
    end
    endtime_plus = format_time(new_time)
    player_state = STATE.FINISHED
end

-- reused string
local function fifty_percent(normal_time, tablet_time)
    if normal_time == 2 * tablet_time then
        return "The penalty is also reduced by 50% if you have the tablet!"
    else
        return string.format("The penalty is also reduced by %s if you have the tablet!", time_to_string(normal_time-tablet_time, false))
    end
end

--- callbacks --------------------------------------------------------------------------------------------------------

-- instant restart protection part 2
set_callback(function()
    is_ankh_penalty = true
    olmec_ankhed = false
    was_cursed = false
    cursed_lives = 0
    state.time_total = stime;
    player():give_powerup(ENT_TYPE.ITEM_POWERUP_ANKH)
    -- start a new race post-gen
    if is_new_race then
        schrodingers_ushabti()
        deaths = 0
    end

    is_new_race = false
end, ON.START)

-- instant restart protection part 1
-- Now includes the automatic seed insertion
set_callback(function()
    is_new_race = not(state.pause & 1 == 1 and state.pause & 2 == 2)
    debug.print_if(is_new_race == in_game(), "Error code: 0")

    if is_new_race then
        stime = 1
    else
        stime = state.time_total
    end

    -- Start a new race pre-gen
    if is_new_race then
        -- Auto-import seeds
        if state.screen == SCREEN.CHARACTER_SELECT then
            if options.b_seed ~= "FEEDC0DE" then
                if to_seed() == nil or options.b_seed:len() ~= 8 then
                    print("Invalid Seed!")
                    error("Invalid Seed!")
                elseif state.seed ~= to_seed() then
                    state.seed = to_seed()
                    print("Auto-Updated seed!")
                end
            end
        elseif state.screen == SCREEN.SEED_INPUT or state.screen == SCREEN.CAMP then
            print("You cannot start a race from the \"Enter new seed\" screen or adventure mode!")
        end
    end
end, ON.RESET)


-- Short CO finisher
-- Giving the ankh
-- Ankh health gain
-- Penalty time when dying
set_callback(function()

    -- faster ankh
    if options.db_ankhskip then
        modify_ankh_health_gain(4, 4)
    else
        modify_ankh_health_gain(4, 1)
    end
    
    -- "End game" bugfix done by peterscp
    -- Also fixes duat
    if test_flag(state.level_flags, 21) then
        return;
    end

    player_state = STATE.PLAYING

    --Short CO finisher
    if options.ea_short_co then
        if state.time_total >= ACTIVE_PROFILE.SCO then
            state.screen_next = SCREEN.DEATH;
            load_death_screen();
            
            if state.world*state.level > 1 then
                if state.world == 8 then
                    options.f_endtime = string.format("7-%d", state.level);
                else
                    options.f_endtime = string.format("%d-%d", state.world, state.level);
                end
                player_state = STATE.FINISHED
            end
            --state.time_total = 1;
        end
    end

    -- infinite ankh handling
    local has_ankh = player():has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
    if not has_ankh then
        -- time penalty
        player():give_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
        deaths = deaths + 1
        if is_ankh_penalty then
            add_time(PENALTY.ANKH);
            if was_cursed and cursed_lives > 0 then
                player():set_cursed(true, true) -- maybe effect, maybe not
                cursed_lives = cursed_lives - 1
            end
        end
        is_ankh_penalty = true;
    end

    if not test_flag(player().flags, ENT_FLAG.DEAD) then
        was_cursed = player():is_cursed()
        if debug.if_change(2, was_cursed) then
            if was_cursed then
                -- got cursed
                cursed_lives = 2
            else
                -- got uncursed
                cursed_lives = 0
            end
        end
    end
end, ON.FRAME)

-- olmec ankh
set_post_entity_spawn(function(ent)
    ent = ent --[[@as Powerup]]
    -- return of the crushing ankh bug
    ent:set_post_destroy(function()
        is_ankh_penalty = false
        olmec_ankhed = true
        cursed_lives = 0
        if PENALTY.OLMEC ~= 0 then
                    add_time(PENALTY.OLMEC);
                    print(string.format("Reduced the timer by %s instantly and give no penalty on your next death", time_to_string(-PENALTY.OLMEC, false)))
        else
            print("Give no penalty on your next death")
        end
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_PICKUP_ANKH)

set_callback(function()
    player_state = STATE.STARTING
end, ON.CHARACTER_SELECT)

-- Might be able to rewrite it to instead check for the win first, then the skip option, so you can save the end time regardless.
-- cutscene skip. huge thanks to Super Ninja Fat/superninjafat for the code!
-- Short co setting adjustment
set_callback(function()
    -- Automatically adjust settings during short co runs

    --[[ Versions and their character
    12.0 and before ANA
    13.0 OTAKU (little jay)
    14.0 AU
    15.0 PILOT
    ]]

    -- Cutscene skip!!!
    --if options.da_cutskip then
    if state.loading == 2 then
        if screen_level() and state.screen_next == SCREEN.WIN then
            debug.print_if(screen_level() ~= in_game(), "Error code: 1")
            state.screen_next = SCREEN.SCORES;
            state.end_spaceship_character = ENT_TYPE.CHAR_PILOT; --perfect :3
            update_endtime()
        end
    end
    --end

    -- Main part of ankh skip
    if options.db_ankhskip then
        local ankhs = get_entities_by_type(ENT_TYPE.ITEM_POWERUP_ANKH);
        for _, v in pairs(ankhs) do
            local ankh = get_entity(v) --[[@as AnkhPowerup]]

            -- This should be able to replace the previous flag stuff
            if ankh.timer1 == 0 then
                ankh_flag = 0;
            elseif ankh.timer1 == 1 then
                ankh_flag = 1;
                --print("Do")
            -- Manual lockout to prevent the ankhskip from softlocking
    	    elseif ankh.timer1 > 677 then
                debug.print_once(2, "Error code: 4")
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
                else
                    debug.print_once(0, "Error code: 2")
                end
            elseif ankh_flag == 2 then
                -- You need to put it to any number below 120, 119 being optimal
                if 20 < ankh.timer2 and ankh.timer2 < 120 then
                    ankh.timer2 = 119;
                    ankh_flag = ankh_flag + 1;
                    --print("Mi")
                    -- no more extra flags, it just prevents more stages
                else
                    debug.print_once(1, "Error code: 3")
                end
            end
        end
    end
end, ON.POST_UPDATE)

-- wintime for co
set_callback(function ()
    update_endtime()
end, ON.CONSTELLATION)

-- FEEDC0DE
set_callback(function ()
    -- Because you are in adventure mode!
    options.b_seed = "FEEDC0DE"
end, ON.CAMP)

-- Fancy lights (Spirit1 version)
set_callback(function()
    if options.dc_nodark and state.time_last_level < 30*SEC and not state.illumination then
        state.level_flags = clr_flag(state.level_flags, 18)
        state.illumination = create_illumination(Color:white(), 20000, 172, 252)
    end
end, ON.POST_LEVEL_GENERATION)


--- options ------------------------------------------------------------------------------


-- Options

-- seed callback functionality
register_option_callback("b_seed", "FEEDC0DE", function(draw_ctx)
    draw_ctx:win_separator_text("Seed input")
    -- Input
    options.b_seed = draw_ctx:win_input_text("Seed input", options.b_seed)
    draw_ctx:win_text("Also automatically updates the seed at the start of the run")
    local button_pressed = draw_ctx:win_button("Update seed")
    draw_ctx:win_text("Use the \"Seed input\" field to enter a seed")
    draw_ctx:win_text("Then press the button to update the seed")
    local export_button = draw_ctx:win_button("Export seed")
    draw_ctx:win_text("Displays the active seed in the seed input")
    draw_ctx:win_text("Use it after making a seed in the vanilla seed input screen")
    if export_button then
        options.b_seed = string.format("%08X", state.seed);
        print("Exported seed")
    end
    -- Button
    if button_pressed then
        if in_game() then
            print("Go to main menu to update the seed!")
            return
        end
        if options.b_seed:len() ~= 8 then
            print("Invalid Seed! (Incorrect size)")
            error()
            return
        end
        if to_seed() == nil then
            print("Invalid Seed!")
            error()
            return
        end
     
        if state.screen == SCREEN.SEED_INPUT then
            -- Custom seed input when used on seed input
            game_manager.screen_seed_input:set_seed(to_seed())
            print("Updated seed! (Seed input version)")
        elseif state.screen == SCREEN.CHARACTER_SELECT then
            -- Custom seed input when used on character select (To prevent the softlock)
            if state.screen_character_select.seeded_run then
                state.seed = to_seed()
                print("Updated seed! (old version). Make sure you are playing seeded mode!")
            else
                play_seeded(to_seed())
                state.screen_last = SCREEN.MENU
                print("You are in the wrong mode silly :)")
            end
        elseif state.screen == SCREEN.MENU then
            -- Custom menu seed input to prevent the smokeeeey
            if game_manager.screen_menu.state ~= 7 then
                print("Don't update seed during an animation!")
            else
                print("Updated seed! (New version)");
                play_seeded(to_seed())
            end
        else
            -- Custom (default) seed input
            print("Updated seed! (New version?)");
            debug.print_if(true, state.screen)
            play_seeded(to_seed())
        end
    end
end)

-- emergency button
register_option_callback("c_EB", nil, function(draw_ctx)
    draw_ctx:win_separator_text("Emergency button")
    local button_pressed = draw_ctx:win_button("Emergency button")
    --local ej = options.cb_ej
    --local short_co = options.ea_short_co 
    if options.ea_short_co then
        if options.cb_ej then
            draw_ctx:win_text(string.format("It's short CO! Go and get a free jetpack for only a %s penalty!", time_to_string(PENALTY.JETPACK, true)))
            draw_ctx:win_text(fifty_percent(PENALTY.JETPACK, PENALTY.TJETPACK))
            draw_ctx:win_text("Note: During short CO you can use the emergency button at any time")
        else
            draw_ctx:win_text("Soo")
            draw_ctx:win_text("Have fun on shortlowCO% lel")
            draw_ctx:win_text(string.format("%s penalty when used", time_to_string(PENALTY.QILIN, true)))
            draw_ctx:win_text(fifty_percent(PENALTY.QILIN, PENALTY.TQILIN))
        end
    else
        if options.cb_ej then
            draw_ctx:win_text(string.format("Gives a jetpack for a %s penalty", time_to_string(PENALTY.JETPACK, true)))
            draw_ctx:win_text("Also gives a rope when used.")
            draw_ctx:win_text(fifty_percent(PENALTY.JETPACK, PENALTY.TJETPACK))
        else
            draw_ctx:win_text("Gives you a free qilin to qilin skip with.")
            draw_ctx:win_text(string.format("Adds a %s penalty on your time.", time_to_string(PENALTY.QILIN, true)))
            draw_ctx:win_text(fifty_percent(PENALTY.QILIN, PENALTY.TQILIN))
        end
    end

    if button_pressed then
        if not in_game() then
            print("Uh...")
            error()
            return
        end

        -- test if you are in tiamat
        if options.ca_emergency_lock and state.theme ~= THEME.TIAMAT then
            print("You need to be in tiamat to use the emergency button!");
            return
        end

        local has_tablet = player():has_powerup(ENT_TYPE.ITEM_POWERUP_TABLETOFDESTINY)

        if options.cb_ej then
            if player():worn_backitem() == -1 then
                -- Emergency jetpack version
                local jayjay = spawn_on_floor(ENT_TYPE.ITEM_JETPACK, math.floor(0), math.floor(0), LAYER.PLAYER);
                pick_up(player().uid, jayjay);
                -- bonus rope
                player().inventory.ropes = player().inventory.ropes + 1;

                if has_tablet then
                    add_time(PENALTY.TJETPACK)
                else
                    add_time(PENALTY.JETPACK)
                end
            else
                print("Cannot use while wearing a backitem!")
                error()
            end
        else
            -- Emergency qilin version
            local jayjay = spawn_on_floor(ENT_TYPE.MOUNT_QILIN, math.floor(0), math.floor(0), LAYER.PLAYER1);
            local qilin = get_entity(jayjay) --[[@as Qilin]]
            qilin.tamed = true
            --carry(jayjay, player().uid);
            qilin:carry(player())

            -- Tablet timesave
            if has_tablet then
                add_time(PENALTY.TQILIN); -- 2 minutes
            else
                add_time(PENALTY.QILIN); -- 3 minutes
            end
        end
    end
end)

-- emergency button lock. Prevents it from being used outside of tiamat unless deactivated
register_option_callback("ca_emergency_lock", true, function(draw_ctx)
    if options.ea_short_co then
        options.ca_emergency_lock = false
        return
    end
    options.ca_emergency_lock = draw_ctx:win_check("Disable emergency button lock", options.ca_emergency_lock)
    draw_ctx:win_text("Prevents the buttons use outside of tiamat")
    if debug.if_change(1, options.ca_emergency_lock) and not options.ca_emergency_lock then
        options.cb_ej = true
    end
end)

-- OG EB
register_option_callback("cb_ej", false, function(draw_ctx)
    if options.g_additional_options then
        --[[
        if options.ea_short_co then
            options.cb_ej = true
            return
        elseif options.ca_emergency_lock then
            options.cb_ej = false
            return
        end
        ]]
        options.cb_ej = draw_ctx:win_check("Emergency Jetpack", options.cb_ej)
        if options.ea_short_co then
            draw_ctx:win_text("Disable this to get a qilin")
            draw_ctx:win_text("Both have a 2 minute penalty") -- Custom!
        else
            draw_ctx:win_text("Replaces the qilin with the jetpack (the original emergency button).")
            draw_ctx:win_text(string.format("Includes the bonus rope and has a %s penalty", time_to_string(PENALTY.JETPACK, true)))
        end
    else
        options.cb_ej = (options.ea_short_co) -- true if shortCO, false when not
    end
end)

register_option_callback("d_skips", nil, function (draw_ctx)
    if options.g_additional_options then
        draw_ctx:win_separator_text("Skips")
        --options.da_cutskip = draw_ctx:win_check("Cutscene skip", options.da_cutskip)      -- Needs to be disabled bc stuff breaks when this is off
        options.db_ankhskip = draw_ctx:win_check("Shorter Ankh animation", options.db_ankhskip)
        options.dc_nodark = draw_ctx:win_check("Vanilla dark level behavior", options.dc_nodark)
    else
        options.db_ankhskip = true
        options.dc_nodark = true
    end
end)

-- Short CO my beloved
register_option_callback("ea_short_co", false, function(draw_ctx)
    draw_ctx:win_separator_text("Additional stuff")
    options.ea_short_co = draw_ctx:win_check("Short CO Mode", options.ea_short_co)
    draw_ctx:win_text(string.format("Limits the time to %s", time_to_string(PENALTY.SCO, false)))
    -- When clicked:
    if debug.if_change(0, options.ea_short_co) then
        if options.ea_short_co then
            -- Is short CO:
            options.ca_emergency_lock = false
            options.cb_ej = true
            PENALTY = PROFILES.SHORT_CO
            if deaths > 0 and in_game() then
                print("Adjust penalty")
                add_time((PENALTY.ANKH-ACTIVE_PROFILE.ANKH)*deaths)
                -- Bonus penalty for forgetting to enable it
                add_time(20*SEC)
            end
        else
            -- Is normal:
            options.ca_emergency_lock = true
            options.cb_ej = false
            PENALTY = ACTIVE_PROFILE
        end
    end
end)

-- ending time
register_option_callback("f_endtime", "00:00.000", function(draw_ctx)
    draw_ctx:win_input_text("Ending time", options.f_endtime)
    draw_ctx:win_text("Also shows short CO ending level!")
end)

-- bonus visuals
register_option_callback("fa_bonus_stats", nil, function(draw_ctx)
    if options.g_additional_options then
        draw_ctx:win_input_text("Death count", tostring(deaths))
        draw_ctx:win_text("Count your number of failiures")

        draw_ctx:win_input_text("Entime plus", endtime_plus)
        draw_ctx:win_text("Time for only this run (doesn't include olmec time reduction)")

        draw_ctx:win_input_text("Olmec Ankh", tostring(olmec_ankhed))
    end
end)

-- Additional options
register_option_bool("g_additional_options", "Show additional options", "If you hate qol. Resets to defaults when disabled", false)

-- Note
register_option_callback("h_note", nil, function (draw_ctx)
    draw_ctx:win_separator_text("Note")
    draw_ctx:win_text(string.format("Infinite Ankh: On death revive and gain a %s penalty", time_to_string(PENALTY.ANKH, true)))
    draw_ctx:win_text("Instant restart protection: Instant restarting will not reset the time. You can always instant restart during a race")
    draw_ctx:win_text("Olmec Ankh: Picking up the Ankh in Olmec's Lair will give you one revive without penalty and evtl. reduces the time a little")
end)