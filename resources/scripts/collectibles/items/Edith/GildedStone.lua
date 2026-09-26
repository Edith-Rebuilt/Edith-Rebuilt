local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local outcome = WeightedOutcomePicker()

outcome:AddOutcomeFloat(1, 25)
outcome:AddOutcomeFloat(2, 40)
outcome:AddOutcomeFloat(3, 15)
outcome:AddOutcomeFloat(4, 10)
outcome:AddOutcomeFloat(5, 5)
outcome:AddOutcomeFloat(6, 4)
outcome:AddOutcomeFloat(7, 1)

local RockRewards = {
    { Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_PENNY },
    { Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DOUBLEPACK },
    { Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_NICKEL },
    { Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DIME },
    { Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_LUCKYPENNY },
    { Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_QUARTER },
    { Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_DOLLAR },
}

---@param player EntityPlayer
local function GetChanceToShootRock(player)
    local luck = player.Luck
    local coins = player:GetNumCoins()
    local formula = ((coins + math.max(luck * 5, 0)) + 10) / 100

    return Maths.Clamp(formula, 0, 0.75)
end

---@param player EntityPlayer
---@return number
local function GetRockRewardChance(player)
    local luck = player.Luck
    local coins = player:GetNumCoins()
    local formula = (((coins * 2.5) + math.max(luck * 0.5, 0)) - 3) / 100

    return Maths.Clamp(formula, 0, 0.5)
end

---@param reward table
---@param rng RNG
---@return Vector
local function GetRewardVelocity(reward, rng)
    return reward.Variant == PickupVariant.PICKUP_COIN and rng:RandomVector():Resized(3) or Vector.Zero
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
	local player = Helpers.GetPlayerFromTear(tear)
    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
    if not ModRNG.RandomBoolean(rng, GetChanceToShootRock(player)) then return end

    Helpers.TurnTearToTerraTear(tear, rng)
end)

---@param rock GridEntityRock
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, function(_, rock, _, _, source)
	local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)

    if not ModRNG.RandomBoolean(rng, GetRockRewardChance(player)) then return end

    local reward = RockRewards[outcome:PickOutcome(rng)]
    local Velocity = GetRewardVelocity(reward, rng)

    Isaac.Spawn(EntityType.ENTITY_PICKUP, reward.Variant, reward.SubType, rock.Position, Velocity, nil)
end)