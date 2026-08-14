local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local sounds = enums.SoundEffect
local misc = enums.Misc
local utils = enums.Utils
local saltTypes = enums.SaltTypes
local sfx = utils.SFX
local SaltQuantity = 14
local modules = mod.Modules
local ModRNG = modules.RNG
local Player = modules.PLAYER
local BitMask = modules.BIT_MASK
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local degree = 360 / SaltQuantity
local data = mod.DataHolder.GetEntityData
local flags = saltTypes.SALT_SHAKER | saltTypes.SALT_SHAKER_JUDAS

local SALT_SHAKER = {
    CREEP_DURATION_BASE = 6,
    CREEP_DURATION_CARBATTERY = 12,
    JUDAS_SALT_COLOR = Color(1, 0.4, 0.15),
    TYPES = {
        [saltTypes.SALT_SHAKER] = true,
        [saltTypes.SALT_SHAKER_JUDAS] = true,
    }
}

---@param player EntityPlayer
---@return {SaltType: SaltTypes, Color: Color}
local function GetSaltShakerParams(player)
    local spawnType = Player.IsJudasWithBirthright(player) and saltTypes.SALT_SHAKER_JUDAS or saltTypes.SALT_SHAKER
    local color = spawnType == saltTypes.SALT_SHAKER_JUDAS and SALT_SHAKER.JUDAS_SALT_COLOR or nil
    return {SaltType = spawnType, Color = color}
end

---@param player EntityPlayer
---@param position Vector
---@param duration number
---@param spawnType SaltTypes
---@param color Color?
local function SpawnSaltShakerCreep(player, position, duration, spawnType, color)
    local salt = Creeps.SpawnSaltCreep(player, position, 0, duration, 1, 4.5, spawnType, false, true, color)
    return salt
end

---@param player EntityPlayer
local function DespawnExistingSaltCreeps(player)
    for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, enums.SubTypes.SALT_CREEP)) do
        if GetPtrHash(entity.SpawnerEntity) ~= GetPtrHash(player) then goto continue end
        entity:ToEffect():SetTimeout(1)
        ::continue::
    end
end

---@param player EntityPlayer
---@param spawnType SaltTypes
---@param color Color?
---@param hasCarBattery boolean
local function SpawnSaltCircle(player, spawnType, color, hasCarBattery)
    local duration = hasCarBattery and SALT_SHAKER.CREEP_DURATION_CARBATTERY or SALT_SHAKER.CREEP_DURATION_BASE
    for i = 1, SaltQuantity do
        local salt = SpawnSaltShakerCreep(player, player.Position + misc.SaltShakerDist:Rotated(degree * i), duration, spawnType, color)
        data(salt).Shaker = true
    end
end

---@param player EntityPlayer
---@param rng RNG
local function SpawnSaltCloud(player, rng)
    local cloud = StsEffects.SpawnSpicePuff(player, rng)
    local X = ModRNG.RandomFloat(rng, 0.8, 1.15)
    local Y = ModRNG.RandomFloat(rng, 0.8, 1.15)

    cloud.Color = StsEffects.GetSpiceEffectData(enums.EdithStatusEffects.SALTED).Color
    cloud.SpriteScale = Vector(X, Y)
    cloud:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(rng, 1.4, 1.8)
end

local function PushNearbyEnemies(player)
    for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 40, EntityPartition.ENEMY)) do
        Helpers.TriggerPush(enemy, player, 50)
    end
end

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, rng, player, flag)
    if BitMask.HasBitFlags(flag, UseFlag.USE_CARBATTERY --[[@as BitSet128]]) then return end

    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
    local saltParams = GetSaltShakerParams(player)
    local spawnType, color = saltParams.SaltType, saltParams.Color

    DespawnExistingSaltCreeps(player)
    SpawnSaltCloud(player, rng)
    SpawnSaltCircle(player, spawnType, color, hasCarBattery)
    PushNearbyEnemies(player)

    data(player).PushCapsulePos = player.Position

    sfx:Play(sounds.SOUND_SALT_SHAKER, 2, 0, false, ModRNG.RandomFloat(rng, 0.9, 1.1), 0)
    return true
end, items.COLLECTIBLE_SALTSHAKER)

---@param npc EntityNPC
---@param source EntityRef
mod:AddCallback(PRE_NPC_KILL.ID, function (_, npc, source)
    if not StsEffects.EntHasStatusEffect(npc, enums.EdithStatusEffects.SALTED) then return end

    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end

    local saltType = data(npc).SaltType

    if not saltType then return end
    if not BitMask.HasBitFlags(saltType, flags --[[@as BitSet128]]) then return end

    local saltParams = GetSaltShakerParams(player)
    local spawnType, color = saltParams.SaltType, saltParams.Color
    SpawnSaltShakerCreep(player, npc.Position, 5, spawnType, color)
end)

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local pos = data(player).PushCapsulePos

    if not pos then return end

    local capsule = Capsule(data(player).PushCapsulePos, Vector.One, 1, 60)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
        ent:AddVelocity((ent.Position - pos):Resized(20))
    end
end)