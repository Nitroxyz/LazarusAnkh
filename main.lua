meta = {
    name = "Lazarus Ankh",
    version = "8.1",
    author = "Nitroxy",
    description = "On death revive and gain 0.5 minutes on your time\n\nFeatures:\n"
}

-- 23

--0.00034722222 days penalty

--[[ Todo:
    - On start of level give ankh if not having one alr
    - Every time you die:
        - Add 2-3 minutes on the timer
        - Give another ankh
    - Custom blue ankh sprite
    - If a real ankh is being picked up:
        - Revert the custom sprite
        - Allow a death without penalty
    - Add an option to toggle how big the penalty is (maybe)
    - Add a counter for each death
    - Remember backitem and give it back on death
    - Force path

]]

--Start of the game gives the ankh without penalty. If sval == false, then you get no penalty
sval = false

--Remembered backitem enitity

--Remembered backitem ENT_TYPE
backy = -1

--Remember time
stime = 0;

set_callback(function ()
    sval = false
    --prinspect(state.time_total)
    state.time_total = stime;
    
end, ON.START)

set_callback(function()
    --prinspect(state.pause);
    if state.pause == 3 then
        stime = state.time_total;
    else
        stime = 0;
    end
end, ON.RESET)

set_callback(function()
    tval = false
    items = players[1]:get_powerups()
    for _,v in pairs(items) do
        if v == ENT_TYPE.ITEM_POWERUP_ANKH then
          -- do something
          tval = true
          break
        end
    end
    if tval == false then

        -- time penalty
        players[1]:give_powerup(ENT_TYPE.ITEM_POWERUP_ANKH)
        if sval then
            state.time_total = state.time_total + 1800 --3600 for 2 min
        else
            sval = true
        end
    end

    
    --[[if players[1].holding_uid > -1 then
        held_item = get_entity(players[1].holding_uid)
        if held_item.type.id ~= ENT_TYPE.ITEM_PICKUP_ANKH then
            sval = false
        end
    end]]
    
    -- check backitem
    if worn_backitem(players[1].uid) > 0 and backy < 0 then
        backy = get_entity_type(worn_backitem(players[1].uid))
        --prinspect(backy)
    end

end, ON.FRAME)

-- olmec ankh
set_post_entity_spawn(function(ent)
    ent:set_pre_destroy(function(idc)
        --[[if killa == get_player(personalPlayerSlot, true) then
            lowBroke = true
            coBroke = true
        end
        ]]
        sval = false
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_PICKUP_ANKH)

-- exports seed
set_callback(function ()
    options.a_seed = state.seed;
end, ON.CHARACTER_SELECT)

-- cutscene skip. huge thanks to Super Ninja Fat/superninjafat for the code!
set_callback(function ()
    if options.d_cutskip then
        if state.loading == 2 then
            if state.screen == SCREEN.LEVEL and state.screen_next == SCREEN.WIN then
                state.screen_next = SCREEN.SCORES
                state.end_spaceship_character = ENT_TYPE.CHAR_ANA_SPELUNKY
            end
        end
    end
end, ON.PRE_UPDATE)

-- wintime
--[[
set_callback(function ()
    prinspect(state.time_total);
end, ON.WIN)
]]


-- Options

register_option_int("a_seed", "Seed input", "Automatically inserts seed of the run in the character select screen ", 0, 0, 0);

-- imports seed
register_option_button("b_button_seed", "Update seed", "Use the \"Seed input\" field to enter an external seed\nThen press the button to update the seed\nMake sure you are in the character select screen before using it", function ()
    if state.screen == SCREEN.CHARACTER_SELECT then
        state.seed = options.a_seed;
        print("Updated seed!");
    else
        print("You need to be in the Character Select screen to update the seed!");
    end
end)

-- emergency button
register_option_button('c_Ej', 'Emergency button', 'Gives a jetpack for a 3 minute penalty\nLook on the fyi page for safe usage', function()
    jayjay = spawn_on_floor(ENT_TYPE.ITEM_JETPACK, math.floor(0), math.floor(0), LAYER.PLAYER)
    pick_up(players[1].uid, jayjay)
    state.time_total = state.time_total + 10800 -- = 3 minutes in frames
end)

register_option_bool("d_cutskip", "Cutscene skip", "No mo waitin", true);

--[[ stuff
set_callback(function()
    render
end, ON.RENDER_POST_HUD)


    register_option_bool("counter", "count deaths", "enables a visual which shows how many times you died", true)


register_option_bool("a_custom", "custom position", "Be precise", false)
register_option_float("left", "left", "", -0.985, -1, 1)
register_option_float("top", "top", "", 0.910, -1, 1)
register_option_float("big", "big", "", 0.05, 0, 2)
]]
