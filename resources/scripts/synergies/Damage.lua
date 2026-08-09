local mod = EdithRebuilt
local modules = mod.Modules
local ModRNG = modules.RNG
local Player = modules.PLAYER
local StompUtils = modules.STOMP_UTILS
local Callbacks = mod.Enums.Callbacks

local adders = {
    ---@param player EntityPlayer
    ---@param params EdithJumpStompParams|TEdithHopParryParams
    ---@param damage number
    ---@param rng RNG
    ---@param Birthright boolean
    [CollectibleType.COLLECTIBLE_APPLE] = function(player, params, damage, rng, Birthright)
        local baseChance = Birthright and 10 or 15
        if not ModRNG.RandomBoolean(rng, 1 / math.max(baseChance - player.Luck, 1)) then return end
        StompUtils.SetDamage(params, damage * 4)
    end,
    ---@param player EntityPlayer
    ---@param params EdithJumpStompParams|TEdithHopParryParams
    ---@param damage number
    ---@param rng RNG
    ---@param Birthright boolean
    [CollectibleType.COLLECTIBLE_TOUGH_LOVE] = function(player, params, damage, rng, Birthright)
        local baseChance = Birthright and 7 or 10
        if not ModRNG.RandomBoolean(rng, 1 / math.max(baseChance - player.Luck, 1)) then return end
        StompUtils.SetDamage(params, damage * 3.2)
    end,
    ---@param params EdithJumpStompParams|TEdithHopParryParams
    ---@param damage number
    ---@param rng RNG
    ---@param Birthright boolean
    [CollectibleType.COLLECTIBLE_STYE] = function(_, params, damage, rng, Birthright)
        if not ModRNG.RandomBoolean(rng, Birthright and 0.75 or 0.5) then return end
        StompUtils.SetDamage(params, damage * 1.28)
    end,
    ---@param params EdithJumpStompParams|TEdithHopParryParams
    ---@param damage number
    ---@param rng RNG
    ---@param Birthright boolean
    [CollectibleType.COLLECTIBLE_BLOOD_CLOT] = function(_, params, damage, rng, Birthright)
        if not ModRNG.RandomBoolean(rng, Birthright and 0.75 or 0.5) then return end
        StompUtils.SetDamage(params, damage * 1.1)
    end,
    ---@param params EdithJumpStompParams|TEdithHopParryParams
    ---@param damage number
    ---@param rng RNG
    ---@param Birthright boolean
    [CollectibleType.COLLECTIBLE_CHEMICAL_PEEL] = function(_, params, damage, rng, Birthright)
        if not ModRNG.RandomBoolean(rng, Birthright and 0.75 or 0.5) then return end
        StompUtils.SetDamage(params, damage + 2)
    end,
}

---@param player EntityPlayer
---@param params TEdithHopParryParams|EdithJumpStompParams
---@param isStomp boolean
local function ApplyDamageAdders(player, params, isStomp)
    local damage = StompUtils.GetDamage(params)
    local hasBirthright = isStomp and Player.IsEdithBirthtight(player)

    for item, funct in pairs(adders) do
        if not player:HasCollectible(item) then goto Continue end
        funct(player, params, damage, player:GetCollectibleRNG(item), hasBirthright)
        ::Continue::
    end
end

---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, _, params)
    ApplyDamageAdders(player, params, false)
end)

---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function(_, player, params)
    ApplyDamageAdders(player, params, true)
end)
