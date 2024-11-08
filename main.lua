meta = {
    name = "Lazarus Ankh",
    version = "11.11",
    author = "Nitroxy",
    description = "On death revive and gain 0.5 minutes on your time\n\nFeatures:\n"
}

-- 66

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

--- variables ------------------------------------------------------------------------------------------------

--Universal time in frames
SEC = 60;
MIN = 3600;

--Pentalites
PENALTY = {
    ANKH = 30*SEC,
    QILIN = 3*MIN,
    TQILIN = 2*MIN,
    JETPACK = 4*MIN,
    TJETPACK = 3*MIN+30*SEC,
}

SHORT_PENALTY = {
    ANKH = 60*SEC,
    QILIN = -1,
    TQILIN = -1,
    JETPACK = 2*MIN,
    TJETPACK = 1*MIN+30*SEC,
}

-- New universal flag to tell if a new race has been started
local is_new_race = true;
--Start of the game gives the ankh without penalty. If is_ankh_penalty == false, then you get no penalty
local is_ankh_penalty = false;

--Remember total time for instant restarts
local stime = 1;

--Enable/disable ankh respawning
local ankh_respawn = true

--Used to determine the phase of the ankh for skipping the ankh cutscene
local ankh_flag = 0;

-- Deal coords
local deal_x = 1
local deal_y = 1
local deal_ready = false

--- functions --------------------------------------------------------------------------------------------------

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
    state.time_total = state.time_total + time;
end

--- callbacks --------------------------------------------------------------------------------------------------------

-- instant restart protection part 2
set_callback(function()
    ankh_respawn = true;
    deal_ready = false;
    is_ankh_penalty = false;
    state.time_total = stime;

    -- start a new race post-gen
    if is_new_race then
        schrodingers_ushabti()
    end

    is_new_race = false
end, ON.START)

-- instant restart protection part 1
-- Now includes the automatic seed insertion
set_callback(function()
    is_new_race = state.pause & 1 == 1 and state.pause & 2 == 2

    if is_new_race then
        stime = state.time_total;
    else
        stime = 1;
    end

    -- Start a new race pre-gen
    if is_new_race then
        -- Auto-import seeds
        if state.screen == SCREEN.CHARACTER_SELECT then
            local type = 16
            if tonumber(options.ab_seed, type) == nil then
                print("Invalid Seed!")
                error("Invalid Seed!")
            else
                state.seed = tonumber(options.ab_seed, type);
                print("Auto-Updated seed!");
            end
        else
            if state.screen == SCREEN.SEED_INPUT or state.screen == SCREEN.CAMP then
                print("You cannot start a race from the \"Enter new seed\" screen or adventure mode!");
                error();
            end
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


        --Short CO finisher
        if options.ea_short_co then
            if state.time_total >= 30*MIN then
                state.screen_next = SCREEN.DEATH;
                load_death_screen();
                
                if state.world * state.level > 1 then
                    if state.world == 8 then
                        options.f_endtime = string.format("7-%d", state.level);
                    else
                        options.f_endtime = string.format("%d-%d", state.world, state.level);
                    end
                end
                --state.time_total = 1;
            end
        end

    -- infinite ankh handling
    local has_ankh = get_player(1, false):has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
    if has_ankh == false then
        -- time penalty
        get_player(1, false):give_powerup(ENT_TYPE.ITEM_POWERUP_ANKH);
        if is_ankh_penalty then
            if options.ea_short_co then
                add_time(SHORT_PENALTY.ANKH)
            else
                add_time(PENALTY.ANKH);
            end
        else
            is_ankh_penalty = true;
        end
    end
end, ON.FRAME)

-- olmec ankh
set_post_entity_spawn(function(ent)
    ent = ent --[[@as Powerup]]
    -- return of the crushing ankh bug
    ent:set_post_destroy(function() -- could be post instead
        is_ankh_penalty = false;
        add_time(-10*SEC);
        print("Reduced the timer by 10 seconds instantly and give no penalty on your next death")
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_PICKUP_ANKH)

-- deal check
set_post_entity_spawn(function(ent)
    ent = ent --[[@as Bow]]
    ent:set_post_destroy(function()
        deal_ready = true;
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_HOUYIBOW)

-- deal check 2
set_post_entity_spawn(function(ent)
    ent = ent --[[@as Bow]]
    ent:set_post_destroy(function()
        deal_ready = true;
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_LIGHT_ARROW)

-- exports seed
set_callback(function()
    options.ab_seed = string.format("%08X", state.seed);
    print("Auto-Imported seed!");
end, ON.CHARACTER_SELECT)

-- Might be able to rewrite it to instead check for the win first, then the skip option, so you can save the end time regardless.
-- cutscene skip. huge thanks to Super Ninja Fat/superninjafat for the code!
-- Short co setting adjustment
set_callback(function()
    -- Automatically adjust settings during short co runs

    -- Cutscene skip!!!
    if options.da_cutskip then
        if state.loading == 2 then
            if state.screen == SCREEN.LEVEL and state.screen_next == SCREEN.WIN then
                state.screen_next = SCREEN.SCORES;
                state.end_spaceship_character = ENT_TYPE.CHAR_ANA_SPELUNKY; --not perfect >:(
                options.f_endtime = format_time(state.time_total);
            end
        end
    end

    -- Main part of ankh skip
    if options.db_ankhskip then
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

-- wintime for co
set_callback(function ()
    options.f_endtime = format_time(state.time_total);
end, ON.CONSTELLATION)

-- FEEDC0DE
set_callback(function ()
    -- Because you are in adventure mode!
    -- options.ab_seed = "FEEDC0DE"
end, ON.CAMP)

--- options ------------------------------------------------------------------------------


-- Options
-- seed callback functionality
register_option_callback("ab_seed", "", function(draw_ctx)
    draw_ctx:win_separator_text("Seed input")
    -- Input
    options.ab_seed = draw_ctx:win_input_text("Seed input", options.ab_seed)
    draw_ctx:win_text("Automatically inserts seed when entering the character select screen")
    draw_ctx:win_text("Also automatically updates the seed at the start of the run")
    local button_pressed = draw_ctx:win_button("Update seed")
    draw_ctx:win_text("Use the \"Seed input\" field to enter a seed")
    draw_ctx:win_text("Then press the button to update the seed")
    draw_ctx:win_text("You cannot update the seed during a run.")
    -- Button
    if button_pressed then
        if state.screen == SCREEN.LEVEL or state.screen == SCREEN.TRANSITION then
            print("Go to main menu to update the seed!")
            return
        end
    
        local type = 16
    
        if tonumber(options.ab_seed, type) == nil then
            print("Invalid Seed!")
            error()
            return
        end
     
        if state.screen == SCREEN.SEED_INPUT then
            -- Custom seed input when used on seed input
            print("Updated seed! (Seed input version)");
            game_manager.screen_seed_input:set_seed(tonumber(options.ab_seed, type))
        elseif state.screen == SCREEN.CHARACTER_SELECT then
            -- Custom seed input when used on character select (To prevent the softlock)
            state.seed = tonumber(options.ab_seed, type);
            print("Updated seed! (old version). Make sure you are playing seeded mode!");
        elseif state.screen == SCREEN.MENU then
            -- Custom menu seed input to prevent the smokeeeey
            if game_manager.screen_menu.state ~= 7 then
                print("Don't update seed during an animation!")
            else
                print("Updated seed! (New version)");
                play_seeded(tonumber(options.ab_seed, type));
            end
        else
            -- Custom (default) seed input
            print("Updated seed! (New version?)");
            play_seeded(tonumber(options.ab_seed, type));
        end
    end
end)

-- emergency button
register_option_callback("c_EB", nil, function(draw_ctx)
    draw_ctx:win_separator_text("Emergency button")
    local button_pressed = draw_ctx:win_button("Emergency button")
    if options.cb_ej == false then
        draw_ctx:win_text("Gives you a free qilin to qilin skip with.")
        draw_ctx:win_text("Adds a 3 minute penalty on your time.")
        draw_ctx:win_text("The penalty is reduced by 1 minute if you have the tablet")
    elseif options.ea_short_co then
        draw_ctx:win_text("It's short CO! Go and get a free jetpack for only a 2 minute penalty!")
        draw_ctx:win_text("The penalty is also reduced by 0.5 minutes if you have the tablet!")
        draw_ctx:win_text("Note: During short CO you can use the emergency button at any time")
    else
        draw_ctx:win_text("Gives a jetpack for a 4 minute penalty.")
        draw_ctx:win_text("Also gives a rope when used.")
        draw_ctx:win_text("The penalty is reduced by 0.5 minutes if you have the tablet")
    end

    if button_pressed then
        if state.screen ~= SCREEN.LEVEL then
            print("Uh...")
            error()
            return
        end
    
        -- test if you are in tiamat
        if options.ca_emergency_lock then
            if state.theme ~= THEME.TIAMAT then
                print("You need to be in tiamat to use the emergency button!");
                return
            end
        end
    
        if options.cb_ej then
            -- Emergency jetpack version
            local jayjay = spawn_on_floor(ENT_TYPE.ITEM_JETPACK, math.floor(0), math.floor(0), LAYER.PLAYER);
            pick_up(get_player(1, false).uid, jayjay);
    
            --if options.cc_bonus_rope then
            get_player(1, false).inventory.ropes = get_player(1, false).inventory.ropes + 1;
            --end
            if options.ea_short_co then
                if get_player(1, false):has_powerup(ENT_TYPE.ITEM_POWERUP_TABLETOFDESTINY) then
                    add_time(SHORT_PENALTY.TJETPACK); -- 1.5 minutes
                else
                    -- og short co times
                    add_time(SHORT_PENALTY.JETPACK); -- 2 min
                end
            else
                if get_player(1, false):has_powerup(ENT_TYPE.ITEM_POWERUP_TABLETOFDESTINY) then
                    add_time(PENALTY.TJETPACK) -- 3.5
                else
                    -- Slightly increased penalty for jetpack
                    add_time(PENALTY.JETPACK); -- 4 minutes
                end
            end
        else
            -- Emergency qilin version
            local jayjay = spawn_on_floor(ENT_TYPE.MOUNT_QILIN, math.floor(0), math.floor(0), LAYER.PLAYER1);
            local the_boi = get_entity(jayjay) --[[@as Qilin]]
            the_boi.tamed = true
            --carry(jayjay, get_player(1, false).uid);
            the_boi:carry(get_player(1, false))
            -- Tablet timesave
            if get_player(1, false):has_powerup(ENT_TYPE.ITEM_POWERUP_TABLETOFDESTINY) then
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
    local prev_val = options.ca_emergency_lock
    options.ca_emergency_lock = draw_ctx:win_check("Disable emergency button lock", options.ca_emergency_lock)
    draw_ctx:win_text("Prevents the buttons use outside of tiamat")
    if options.ca_emergency_lock ~= prev_val then
        if options.ca_emergency_lock == false then
            options.cb_ej = true;
        end
    end
end)

-- OG EB
register_option_callback("cb_ej", false, function(draw_ctx)
    if options.ea_short_co then
        options.cb_ej = true
        return
    elseif options.ca_emergency_lock then
        options.cb_ej = false
        return
    end

    options.cb_ej = draw_ctx:win_check("Emergency Jetpack", options.cb_ej)
    draw_ctx:win_text("Replaces the qilin with the jetpack (the original emergency button).")
    draw_ctx:win_text("Includes the bonus rope and has a 4 min penalty")
end)

--[[
register_option_callback("cc_stuck", 0, function(draw_ctx)
    deal_ready = true
    if state.screen ~= SCREEN.LEVEL or not options.ea_short_co or state.world == 8 or not deal_ready then
        options.cc_stuck = 0
        return
    end
    local button_count = 0

    if draw_ctx:win_check("I lost bow", options.cc_stuck > 0) then
        button_count = 1
        if draw_ctx:win_check("I am stuck", options.cc_stuck > 1) then
            button_count = 2
            if draw_ctx:win_check("I need to cheat", options.cc_stuck > 2) then
                button_count = 3
                if draw_ctx: win_check("I TAKE ANY COST", options.cc_stuck > 3) then
                    button_count = 4
                end
            end
        end
    end
    if options.cc_stuck == 4 then
        button_count = 4
    end
    if button_count == 4 then
        local deal = draw_ctx:window("DEAL", deal_x, deal_y, 0, 0, false, function(ctx, pos, size)
            deal_x = -size.x/2+(math.random()-0.5)*0.005
            deal_y = size.y/2+(math.random()-0.5)*0.005
            ctx:win_text("TAKE THE DEAL")
            local choose = ctx:win_button("GET  THE  BOW")
            ctx:win_text("LOSE   10   MIN")
            if choose then
                local jayjay = spawn_on_floor(ENT_TYPE.ITEM_HOUYIBOW, math.floor(0), math.floor(0), LAYER.PLAYER);
                local armin = spawn_on_floor(ENT_TYPE.ITEM_LIGHT_ARROW, math.floor(0), math.floor(0), LAYER.PLAYER);
                ]]
                --get_entity(jayjay)--[[@as Bow]]:light_on_fire(60)
                --get_entity(armin)--[[@as LightArrow]]:light_on_fire(60)
                --[[
                pick_up(jayjay, armin)
                pick_up(get_player(1, false).uid, jayjay);

                get_player(1, false):set_cursed(true, true)
                ankh_respawn = false;

                --state.kali_altars_destroyed = 3
                --state.shoppie_aggro = 2
                --state.merchant_aggro = 1

                add_time(10*MIN)
                button_count = 0;
                deal_ready = false;
            end
        end)
        if not deal then
            button_count = 0
        end
    end
    options.cc_stuck = button_count
end)
]]

register_option_callback("cz_skipline", nil, function (draw_ctx)
    draw_ctx:win_separator_text("Skips")
end)

-- Cutscene skip. Might enable it permanently
register_option_bool("da_cutskip", "Cutscene skip", "Our lord and savior", true);

-- The highly popular ankh skip mod
register_option_bool("db_ankhskip", "Shorter Ankh animation", "Makes your respawns 2 times shorter", true);

register_option_callback("e_additionalline", nil, function(draw_ctx)
    draw_ctx:win_separator_text("Additional stuff")
end)

-- Short CO my beloved
--register_option_bool("ea_short_co", "Short CO Mode", "Limits the time to 30 minutes", false);
register_option_callback("ea_short_co", false, function(draw_ctx)
    local old_val = options.ea_short_co
    options.ea_short_co = draw_ctx:win_check("Short CO Mode", options.ea_short_co)
    draw_ctx:win_text("Limits the time to 30 minutes")
    -- When clicked:
    if old_val ~= options.ea_short_co then
        if options.ea_short_co then
            -- Is short CO:
            options.ca_emergency_lock = false
            options.cb_ej = true
        else
            -- Is normal:
            options.ca_emergency_lock = true
            options.cb_ej = false
        end
    end
end)

-- ending time
register_option_callback("f_endtime", "00:00.000", function(draw_ctx)
    draw_ctx:win_input_text("Ending time", options.f_endtime)
    draw_ctx:win_text("Also shows short CO ending level!")
end)

-- R.I.P.
-- register_option_button('g_Ej', 'Emergency button', 'Gives a jetpack for a 3 minute penalty', function()

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
