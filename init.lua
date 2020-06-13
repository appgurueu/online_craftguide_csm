online_craftguide = {}
setfenv(1, setmetatable(online_craftguide, {__index = _G}))
if minetest.get_csm_restrictions().read_itemdefs then
    minetest.log("Unable to render inventory images as read_itemdefs is restricted")
    return
end
if not minetest.get_item_defs or not minetest.store_texture then
    minetest.log("The online_craftguide CSM requires Minetest 5.3 with PR#10003 merged")
    return
end
function render(per_step)
    if not minetest.localplayer then
        minetest.after(0, render)
        return
    end
    per_step = per_step or 10
    text_id = minetest.localplayer:hud_add{
        hud_elem_type = "text",
        name = "online_craftguide:rendering_progress",
        position = {x=0.5, y=0.5},
        text = "Rendering... 0%",
        number = 0xffffff,
        z_index = 1000
    }
    statbar_id = minetest.localplayer:hud_add{
        hud_elem_type = "image",
        text = "progress_bar_bg.png",
        position = {x = 0.5, y = 0.5},
        scale = {x=1, y=1},
        z_index = 900
    }
    local itemdefs = minetest.get_item_defs()
    itemdefs[""] = nil
    local total = 0
    for name, def in pairs(itemdefs) do
        if not def.description or (def.groups.not_in_creative_inventory or 0) > 0 then
            itemdefs[name] = nil
        else
            total = total + 1
        end
    end
    local done = 0
    minetest.register_globalstep(function()
        for name, def in pairs(itemdefs) do
            if not minetest.store_texture("[item:"..def.name, "images/"..name:gsub("%:", "_")..".png") then
                minetest.log("Storing texture for "..def.name.." failed")
            end
            itemdefs[name] = nil
            done = done + 1
            local proportion = done/total
            minetest.localplayer:hud_change(text_id, "text", "Rendering... "..math.floor(proportion * 100).."%")
            minetest.localplayer:hud_change(statbar_id, "text", "progress_bar_bg.png^(progress_bar.png^([combine:256x48:"..math.floor(proportion * 256)..",0=(progress_bar.png^[noalpha)^[colorize:#4A412A:255)^[makealpha:74,65,42)")
            if done >= per_step then
                break
            end
        end
        if done == total then
            minetest.localplayer:hud_remove(text_id)
            minetest.localplayer:hud_remove(statbar_id)
        end
    end)
end
minetest.after(0, render)
setfenv(1, _G)
