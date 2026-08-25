--[[
    Adding custom runes
    -------------------
    Hello brave, intrepid Lua modder! Do this on MC_POST_MODS_LOADED to prevent your
    custom rune from activating twice and having the default description modifier
    with this collectibles
    - RunicTablet.Collectible.RunicTablet.CUSTOM_EFFECTS[id] = true
    Description modifiers can be added in the same function after checking for
    global EID. View scripts_rr/compat/eid_declarations for examples. You are free
    to populate the below GIANTBOOK, PRE_USE, and POST_USE tables within this
    function as well.
]]

---@diagnostic disable: undefined-global

local mod = EdithRebuilt
local enums = mod.Enums

mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, function ()
    if not RunicTablet then return end

    RunicTablet.Collectible.RunicTablet.CUSTOM_EFFECTS[enums.Card.CARD_SOUL_EDITH] = true
end)

