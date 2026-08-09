local mod = EdithRebuilt
local ModRNG = mod.Modules.RNG
local Player = mod.Modules.PLAYER
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param isStomp boolean
local function TrySpawnCoin(player, ent, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER)
    local chance = (isStomp and Player.IsEdithBirthtight(player)) and 0.10 or 0.05

    if not ModRNG.RandomBoolean(rng, chance) then return end

    local randomVel = ModRNG.RandomFloat(rng, 1.5, 3.5)

    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COIN,
        CoinSubType.COIN_PENNY,
        ent.Position,
        rng:RandomVector() * randomVel,
        player
    )
end

mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent) TrySpawnCoin(player, ent, false) end)
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent) TrySpawnCoin(player, ent, true)  end)
