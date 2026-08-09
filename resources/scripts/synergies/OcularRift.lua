local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local ModRNG = mod.Modules.RNG
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param entity Entity
---@param isStomp boolean
local function TrySpawnRift(player, entity, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_OCULAR_RIFT) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_OCULAR_RIFT)
    local formula = 1 / math.max((20 - player.Luck), 5)

    if not ModRNG.RandomBoolean(rng, formula) then return end

    local damage = (isStomp and Player.IsEdithBirthtight(player)) and player.Damage or player.Damage / 2

    local rift = Isaac.Spawn(
        EntityType.ENTITY_EFFECT, EffectVariant.RIFT, 0,
        entity.Position, Vector.Zero, player
    ):ToEffect() ---@cast rift EntityEffect

    rift.CollisionDamage = damage
    rift:SetTimeout(60)
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, entity) TrySpawnRift(player, entity, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP_HIT, function(_, player, entity) TrySpawnRift(player, entity, true)  end)
