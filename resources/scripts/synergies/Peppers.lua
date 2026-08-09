local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local modules = mod.Modules
local ModRNG = modules.RNG
local Player = modules.PLAYER

local PEPPER_CANDLES = {
    { collectible = CollectibleType.COLLECTIBLE_BIRDS_EYE, method = "ShootRedCandle" },
    { collectible = CollectibleType.COLLECTIBLE_GHOST_PEPPER, method = "ShootBlueCandle" },
}

---@param player EntityPlayer
---@param candle table
---@param direction Vector
local function ShootCandle(player, candle, direction)
    if not player:HasCollectible(candle.collectible) then return end
    player[candle.method](player, direction)
end

---@param player EntityPlayer
---@return boolean
local function HasBothPeppers(player)
    return player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER)
       and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRDS_EYE)
end

---@param player EntityPlayer
---@return RNG|nil
local function GetPepperRNG(player)
    return player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_GHOST_PEPPER)
        or player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BIRDS_EYE)
end

---@param player EntityPlayer
---@param isStomp boolean
---@return number
local function GetFireCount(player, isStomp)
    return (isStomp and Player.IsEdithBirthtight(player)) and 8 or 4
end

---@param player EntityPlayer
---@param hasBothPeppers boolean
---@return number
local function GetFireChance(player, hasBothPeppers)
    local luckMod = hasBothPeppers and 8 or 12
    local maxDiv  = hasBothPeppers and 1 or 2
    return 1 / math.max(luckMod - player.Luck, maxDiv)
end

---@param player EntityPlayer
---@param rng RNG
---@param hasBothPeppers boolean
---@param direction Vector
local function ShootCandleInDirection(player, rng, hasBothPeppers, direction)
    if hasBothPeppers then
        local candle = ModRNG.RandomBoolean(rng) and PEPPER_CANDLES[1] or PEPPER_CANDLES[2]
        ShootCandle(player, candle, direction)
    else
        for _, candle in ipairs(PEPPER_CANDLES) do
            ShootCandle(player, candle, direction)
        end
    end
end

---@param player EntityPlayer
---@param isStomp boolean
local function ShootPeppers(player, isStomp)
    local rng = GetPepperRNG(player)
    if not rng then return end

    local hasBothPeppers = HasBothPeppers(player)
    if not ModRNG.RandomBoolean(rng, GetFireChance(player, hasBothPeppers)) then return end

    local fires = GetFireCount(player, isStomp)
    local degrees = 360 / fires

    for i = 1, fires do
        ShootCandleInDirection(player, rng, hasBothPeppers, Vector(0, 1):Rotated(degrees * i))
    end
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) ShootPeppers(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) ShootPeppers(player, true)  end)