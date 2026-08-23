local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.DataHolder.GetEntityData
local saltTypes = enums.SaltTypes
local invalidDamageFlags = DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS | DamageFlag.DAMAGE_NO_PENALTIES
local modules = mod.Modules
local ModRNG = modules.RNG
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local BitMask = modules.BIT_MASK
local effects = enums.EdithStatusEffects

---@param entity Entity
---@param player EntityPlayer
local function SpawnSaltTears(entity, player)
    for _ = 1, player:GetCollectibleRNG(items.COLLECTIBLE_SALT_HEART):RandomInt(4, 6) do
        local tears = player:FireTear(entity.Position, RandomVector() * (player.ShotSpeed * 10), false, false, false, player, 1)

        tears.CollisionDamage = tears.CollisionDamage / 2
		Helpers.ForceSaltTear(tears, false)
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
    end
end

---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param player EntityPlayer
---@param playerData table
local function TriggerDoubleDamage(amount, flags, source, player, playerData)
    playerData.SaltHeartDDFlag = true
    player:TakeDamage(amount * 2, flags, source, 0)
    playerData.SaltHeartDDFlag = false
end 

---@param player EntityPlayer
---@param playerData table
local function SetSaltStatusEffect(player, playerData)
    playerData.SaltHeartDDFlag = playerData.SaltHeartDDFlag or false
    StsEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, player, 90, player)
end

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, amount, flags, source)
    local player = entity:ToPlayer()
    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    if BitMask.HasBitFlags(flags, invalidDamageFlags--[[@as BitSet128]]) then return end

    local playerData = data(player)

    SetSaltStatusEffect(player, playerData)

    if not playerData.SaltHeartDDFlag then
        TriggerDoubleDamage(amount, flags, source, player, playerData)
        return false
    end

    SpawnSaltTears(entity, player)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not StsEffects.EntHasStatusEffect(player, effects.SALTED) then return end
    if StsEffects.GetStatusEffectCountdown(player, effects.SALTED) % 5 ~= 0 then return end

    Creeps.SpawnSaltCreep(player, player.Position, 0, 5, 2, 3, saltTypes.SALT_HEART, true, true)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    player.Damage = (player.Damage + ((0.5 * player:GetCollectibleNum(items.COLLECTIBLE_SALT_HEART)))) * 1.75
end, CacheFlag.CACHE_DAMAGE)

---@param npc EntityNPC
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function (_, npc, source)
    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if not StsEffects.EntHasStatusEffect(player, effects.SALTED) then return end
    if not data(npc).SaltType then return end
    if not BitMask.HasAnyBitFlags(data(npc).SaltType, saltTypes.SALT_HEART) then return end
    if not ModRNG.RandomBoolean(player:GetCollectibleRNG(items.COLLECTIBLE_SALT_HEART), 0.25) then return end

    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, npc.Position, Vector.Zero, nil)
end)