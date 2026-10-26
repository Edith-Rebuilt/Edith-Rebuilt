-- #region Import
local mod = EdithRebuilt
local enums = mod.Enums

local subtype = enums.SubTypes
local saltTypes = enums.SaltTypes
local statusEffects = enums.EdithStatusEffects

local game = enums.Utils.Game

local modules = mod.Modules
local StatusEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local BitMask = modules.BIT_MASK
local Creeps = modules.CREEPS

local data = mod.DataHolder.GetEntityData
-- #endregion Import

-- #region Constants
local CREEP_RADIUS = 20
local CREEP_SPRITE_VARIANTS = 6

local DEFAULT_SALTED_TIME = 120
local VESTIGE_FEAR_TIME = 120
local PEPPERED_TIME = 150
local OREGANO_SLOW_TIME = 150
local OREGANO_SLOW_AMOUNT = 0.8
local OREGANO_COLOR = Color(1, 1, 1, 1, 113/255, 120/255, 82/255)

local CINDER_FIRE_INTERVAL = 15
local JUDAS_FIRE_INTERVAL = 15

local ModCreeps = {
    [subtype.CINDER_CREEP] = true,
    [subtype.SALT_CREEP] = true,
    [subtype.PEPPER_CREEP] = true,
    [subtype.OREGANO_CREEP] = true,
}

local SaltedTimes = {
    [saltTypes.SAL] = 150,
    [saltTypes.SALT_HEART] = 120,
    [saltTypes.EDITHS_HOOD] = 120,
    [saltTypes.SALT_SHAKER] = 90,
    [saltTypes.SALT_SHAKER_JUDAS] = 90,
}
-- #endregion Constants

-- #region Creeps

---@param effect EntityEffect
local function IsModCreepEffect(effect)
    return Helpers.When(effect.SubType, ModCreeps, false)
end

---@param effect EntityEffect
local function GetNearbyEnemies(effect)
    return Isaac.FindInRadius(effect.Position, CREEP_RADIUS * effect.SpriteScale.X, EntityPartition.ENEMY)
end

---@param effect EntityEffect
---@return EntityPlayer?
local function GetSpawnerPlayer(effect)
    return effect.SpawnerEntity and effect.SpawnerEntity:ToPlayer()
end

---@param effect EntityEffect
local function PepperCreepUpdate(effect)
    local player = GetSpawnerPlayer(effect)
    if not player then return end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        StatusEffects.SetStatusEffect(statusEffects.PEPPERED, entity, PEPPERED_TIME, player)
    end
end

---@param effect EntityEffect
local function OreganoCreepUpdate(effect)
    local player = GetSpawnerPlayer(effect)
    if not player then return end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        entity:AddSlowing(EntityRef(player), OREGANO_SLOW_TIME, OREGANO_SLOW_AMOUNT, OREGANO_COLOR)
    end
end
-- #endregion Creeps

-- #region Salt
local function ApplySaltToEntity(entity, spawnType, player)
    StatusEffects.SetStatusEffect(statusEffects.SALTED, entity, SaltedTimes[spawnType] or DEFAULT_SALTED_TIME, player)

    local entData = data(entity)
    entData.SaltType = BitMask.AddBitFlags(entData.SaltType or 0, spawnType)
end

---@param effect EntityEffect
local function SaltCreepUpdate(effect)
    local player = Helpers.GetPlayerFromTear(effect)
    if not player then return end

    if data(effect).Shaker and effect.Timeout == 1 then
        data(player).PushCapsulePos = nil
    end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        if Helpers.IsVestigeChallenge() then
            entity:AddFear(EntityRef(player), VESTIGE_FEAR_TIME)
        else
            ApplySaltToEntity(entity, Creeps.GetSaltSpawnType(effect), player)
        end
    end
end

local function JudasBRSaltManager(npc, npcData)
    if not npcData.SaltType then return end
    if not BitMask.HasAnyBitFlags(npcData.SaltType, saltTypes.SALT_SHAKER_JUDAS) then return end
    if game:GetFrameCount() % JUDAS_FIRE_INTERVAL ~= 0 then return end

    Helpers.SpawnFireJet(npc.Position, 2, 1, 1)
end
-- #endregion Salt

-- #region Cinder

---@param effect EntityEffect
local function CinderCreepUpdate(effect)
    local player = GetSpawnerPlayer(effect)
    if not player then return end
    if not Player.PlayerHasBirthright(player) then return end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        data(entity).IsInCinderCreep = true
    end
end

local function CinderStatusManager(npc, npcData)
    if not npcData.IsInCinderCreep then
        npcData.CinderCount = 0
        return
    end

    npcData.CinderCount = (npcData.CinderCount or 0) + 1

    if npcData.CinderCount % CINDER_FIRE_INTERVAL == 0 then
        Helpers.SpawnFireJet(npc.Position, 5, 1, 0.7)
    end

    npcData.IsInCinderCreep = false
end
-- #endregion Cinder

-- #region Callbacks
local CreepUpdaters = {
    [subtype.SALT_CREEP] = SaltCreepUpdate,
    [subtype.PEPPER_CREEP] = PepperCreepUpdate,
    [subtype.CINDER_CREEP] = CinderCreepUpdate,
    [subtype.OREGANO_CREEP] = OreganoCreepUpdate,
}

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    if not IsModCreepEffect(effect) then return end

    local variant = effect:GetDropRNG():RandomInt(1, CREEP_SPRITE_VARIANTS)
    effect:GetSprite():Play("SmallBlood0" .. variant, true)
end, EffectVariant.PLAYER_CREEP_RED)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local updater = CreepUpdaters[effect.SubType]
    if updater then updater(effect) end
end, EffectVariant.PLAYER_CREEP_RED)

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local npcData = data(npc)

    JudasBRSaltManager(npc, npcData)
    CinderStatusManager(npc, npcData)
end)
-- #endregion Callbacks