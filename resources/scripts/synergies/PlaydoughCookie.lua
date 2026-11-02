local mod = EdithRebuilt
local modules = mod.Modules
local Helpers = modules.HELPERS
local StompUtils = modules.STOMP_UTILS
local Callbacks = mod.Enums.Callbacks

local subEffects = {
    [1] = function(_, _, params) StompUtils.SetDamage(params, StompUtils.GetDamage(params) * 2) end,
    [2] = function(player, ent) ent:AddBurn(EntityRef(player), 150, player.Damage) end,
    [3] = function(player, ent) ent:AddFreeze(EntityRef(player), 120) end,
}

local effects = {
    [1] = function() end,
    [2] = function(player, ent, rng, params)
        Helpers.When(rng:RandomInt(1, 3), subEffects)(player, ent, params)
    end,
    [3] = function(player, ent)
        ent:AddCharmed(EntityRef(player), 120)
    end,
    [4] = function(player, ent)
        ent:AddSlowing(EntityRef(player), 120, 120, Color(0.2, 0.2, 1))
    end,
    [5] = function(player, ent)
        ent:AddPoison(EntityRef(player), 120, player.Damage)
    end,
    [6] = function(player, ent)
        ent:AddFear(EntityRef(player), 120)
        ent:AddEntityFlags(EntityFlag.FLAG_ICE)
    end,
    [7] = function(player, ent)
        ent:AddBaited(EntityRef(player), 120)
    end,
    }

---@param player EntityPlayer
---@param ent Entity
---@param params TEdithHopParryParams|EdithJumpStompParams
local function ApplyPlaydoughEffect(player, ent, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_PLAYDOUGH_COOKIE) then return end

    local itemRNG = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_PLAYDOUGH_COOKIE)

    Helpers.WhenEval(itemRNG:RandomInt(1, 7), effects)
end

mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent, params) ApplyPlaydoughEffect(player, ent, params) end)
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent, params) ApplyPlaydoughEffect(player, ent, params) end)
