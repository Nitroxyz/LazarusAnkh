-- Version 2.1.1
-- Made by Nitroxy

local debug = {
    x = -0.7,       -- recommended x value
    y = 0.7,        -- recommended y value
    d = 0.1,        -- recommended delta value
    k = -0.9,       -- recommended x value for keys (in front)
    q = {},         -- quicker alternatives
    active = true   -- only runs stuff when true
}

local draw_list = {}

local prev_val = {}

-- -0.7, 0.7, 0.1

function debug.draw(id, ex, yai, thing)
    if debug.active then
        if draw_list[id] then
            clear_callback(draw_list[id])
        end
        draw_list[id] = set_callback(function(draw_ctx)
            draw_ctx = draw_ctx --[[@as GuiDrawContext]]
            local c = rgba(255, 255, 255, 255)
        
            draw_ctx:draw_text(ex, yai, 25, tostring(thing), c)
        end, ON.GUIFRAME)
    end
end

function debug.draw_list(id, ex, yai, delta, thingies)
    if debug.active then
        if draw_list[id] then
            clear_callback(draw_list[id])
        end
        draw_list[id] = set_callback(function(draw_ctx)
            draw_ctx = draw_ctx --[[@as GuiDrawContext]]
            local c = rgba(255, 255, 255, 255)
            local yei = yai
            for index, value in ipairs(thingies) do
                draw_ctx:draw_text(ex, yei, 25, tostring(value), c)
                yei = yei - delta
            end
        end, ON.GUIFRAME)
    end
end

function debug.draw_hash(id, ex, yai, delta, thingies)
    if debug.active then
        if draw_list[id] then
            clear_callback(draw_list[id])
        end
        draw_list[id] = set_callback(function(draw_ctx)
            draw_ctx = draw_ctx --[[@as GuiDrawContext]]
            local c = rgba(255, 255, 255, 255)
            local yei = yai
            for key, value in pairs(thingies) do
                draw_ctx:draw_text(ex, yei, 25, tostring(value), c)
                yei = yei - delta
            end
        end, ON.GUIFRAME)
    end
end

function debug.draw_key(id, ex, yai, delta, thingies)
    if debug.active then
        if draw_list[id] then
            clear_callback(draw_list[id])
        end
        draw_list[id] = set_callback(function(draw_ctx)
            draw_ctx = draw_ctx --[[@as GuiDrawContext]]
            local c = rgba(255, 255, 255, 255)
            local yei = yai
            for key, value in pairs(thingies) do
                draw_ctx:draw_text(ex, yei, 25, tostring(key), c)
                yei = yei - delta
            end
        end, ON.GUIFRAME)
    end
end

function debug.if_change(id, value)
    local result = false
    if prev_val[id] then
        if prev_val[id] ~= value then
            result = true
        end
    end
    prev_val[id] = value
    return result
end

function debug.print_on_change(id, value, output)
    if debug.active then
        if debug.if_change(id, value) then
            if type(output) == "string" then
                print(output)
            else
                prinspect(output)
            end
        end
    end
end

-- TODO: Make strings be normal
function debug.print_if(check, output)
    if debug.active then
        if check then
            if type(output) == "string" then
                print(output)
            else
                prinspect(output)
            end
        end
    end
end

function debug.q.draw(id, thing)
    debug.draw(id, debug.x, debug.y, thing)
end

function debug.q.draw_list(id, things)
    debug.draw_list(id, debug.x, debug.y, debug.d, things)
end

function debug.q.draw_hash(id, things)
    debug.draw_hash(id, debug.x, debug.y, debug.d, things)
end

function debug.q.draw_key(id, things)
    debug.draw_key(id, debug.k, debug.y, debug.d, things)
end

function debug.q.print_on_change(id, value)
    debug.print_on_change(id, value, value)
end

function debug.q.print_if(check, output)
    debug.print_if(check, output)
end

return debug