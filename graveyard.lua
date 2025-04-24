-- Deal coords
local MIN
local SEC
local deal_x = 1
local deal_y = 1
local deal_ready = false

local function add_time(numba) end

-- notp1
set_post_entity_spawn(function(ent)
    if options.eb_notp then
        ent:destroy()
    end
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_TELEPORTER)
-- notp2
set_post_entity_spawn(function(ent)
    if options.eb_notp then
        ent:destroy()
    end
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_TELEPORTER_BACKPACK)
-- notp3
set_post_entity_spawn(function(ent)
    if options.eb_notp then
        ent:destroy()
    end
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_PURCHASABLE_TELEPORTER_BACKPACK)

-- deal check
set_post_entity_spawn(function(ent)
    ent:set_post_destroy(function()
        deal_ready = true;
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_HOUYIBOW)
-- deal check 2
set_post_entity_spawn(function(ent)
    ent:set_post_destroy(function()
        deal_ready = true;
        return false;
    end)
end, SPAWN_TYPE.ANY, MASK.ITEM, ENT_TYPE.ITEM_LIGHT_ARROW)

-- bubble skip test
set_post_entity_spawn(function(ent)
    if ent.x > 15 and ent.x < 18 then
        ent:destroy()
    end
end, SPAWN_TYPE.ANY, MASK.ANY, ENT_TYPE.ACTIVEFLOOR_BUBBLE_PLATFORM)

-- No dark level when fast af (fienestar version)
set_callback(function()
    if options.dc_nodark then
        if state.time_last_level < 30*SEC then
            state.level_flags = clr_flag(state.level_flags, 18)
        end
    end
end, ON.POST_ROOM_GENERATION)

-- exports seed
set_callback(function()
    -- Out of commission
    options.b_seed = string.format("%08X", state.seed);
    print("Auto-Imported seed!");
end, ON.CHARACTER_SELECT)

-- Emergency bow
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
                --get_entity(jayjay)--[[@as Bow]]:light_on_fire(60)
                --get_entity(armin)--[[@as LightArrow]]:light_on_fire(60)
                pick_up(jayjay, armin)
                pick_up(get_player(1, false).uid, jayjay);

                get_player(1, false):set_cursed(true, true)
                --ankh_respawn = false;

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

-- Cutscene skip. Might enable it permanently
register_option_bool("da_cutskip", "Cutscene skip", "Our lord and savior", true);