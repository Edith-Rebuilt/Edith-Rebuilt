local mod = EdithRebuilt
local ModRNG = mod.Modules.RNG
local Player = mod.Modules.PLAYER
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param baseDamage number
---@param isStomp boolean
local function TryHolyLight(player, ent, baseDamage, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HOLY_LIGHT)
    local formula = 1 / math.max((10 - (player.Luck * 0.9)), 2)

    if not ModRNG.RandomBoolean(rng, formula) then return end

    local damageMult = (isStomp and Player.IsEdithBirthtight(player)) and 4 or 3

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, ent.Position, Vector.Zero, player)
    ent:TakeDamage(baseDamage * damageMult, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
end

---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent, params)
    TryHolyLight(player, ent, params.ParryDamage, false)
end)

---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent, params)
    TryHolyLight(player, ent, params.Damage, true)
end)
