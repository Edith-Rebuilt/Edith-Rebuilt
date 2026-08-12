local mod = EdithRebuilt
local enums = mod.Enums
local subtype = enums.SubTypes
local game = enums.Utils.Game
local saltTypes = enums.SaltTypes
local modules = mod.Modules
local StatusEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local BitMask = modules.BIT_MASK
local Creeps = modules.CREEPS
local data = mod.DataHolder.GetEntityData

local ModCreeps = {
    [subtype.CINDER_CREEP] = true,
    [subtype.SALT_CREEP] = true,
    [subtype.PEPPER_CREEP] = true,
    [subtype.OREGANO_CREEP] = true,
}

---@param effect EntityEffect
local function isModCreepEffect(effect)
    return Helpers.When(effect.SubType, ModCreeps, false)
end

---@param effect EntityEffect
local function GetNearbyEnemies(effect)
    return Isaac.FindInRadius(effect.Position, 20 * effect.SpriteScale.X, EntityPartition.ENEMY)
end

local SaltedTimes = {
    [saltTypes.SAL] = 150,
    [saltTypes.SALT_HEART] = 120,
    [saltTypes.EDITHS_HOOD] = 120,
    [saltTypes.SALT_SHAKER] = 90,
    [saltTypes.SALT_SHAKER_JUDAS] = 90,
}

---@param effect EntityEffect 
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    if not isModCreepEffect(effect) then return end
    effect:GetSprite():Play("SmallBlood0" .. tostring(effect:GetDropRNG():RandomInt(1, 6)), true)
end, EffectVariant.PLAYER_CREEP_RED)

local function ApplySaltToEntity(entity, spawnType, player)
    StatusEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, entity, SaltedTimes[spawnType] or 120, player)

    local entData = data(entity)
    entData.SaltType = entData.SaltType or 0
    entData.SaltType = BitMask.AddBitFlags(entData.SaltType, spawnType)
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
            entity:AddFear(EntityRef(player), 120)
        else
            ApplySaltToEntity(entity, Creeps.GetSaltSpawnType(effect), player)
        end
    end
end

---@param effect EntityEffect
local function PepperCreepUpdate(effect)
    if not effect.SpawnerEntity then return end
    local player = effect.SpawnerEntity:ToPlayer()
    if not player then return end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        StatusEffects.SetStatusEffect(enums.EdithStatusEffects.PEPPERED, entity, 150, player)
    end
end

---@param effect EntityEffect
local function CinderCreepUpdate(effect)
    if not effect.SpawnerEntity then return end
    local player = effect.SpawnerEntity:ToPlayer()
    if not player then return end
    if not Player.PlayerHasBirthright(player) then return end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        data(entity).IsInCinderCreep = true
    end
end

local oreganoColor = Color(1, 1, 1, 1, 113/255, 120/255, 82/255)
---@param effect EntityEffect
local function OreganoCreepUpdate(effect)
    if not effect.SpawnerEntity then return end
    local player = effect.SpawnerEntity:ToPlayer()
    if not player then return end

    for _, entity in pairs(GetNearbyEnemies(effect)) do
        entity:AddSlowing(EntityRef(player), 150, 0.8, oreganoColor)
    end
end

local function CinderStatusManager(npc, npcData)
    if not npcData.IsInCinderCreep then
        npcData.CinderCount = 0
        return
    end

    npcData.CinderCount = npcData.CinderCount or 0
    npcData.CinderCount = npcData.CinderCount + 1

    if npcData.CinderCount % 15 == 0 then
        Helpers.SpawnFireJet(npc.Position, 5, 1, 0.7)
    end

    npcData.IsInCinderCreep = false
end

local function JudasBRSaltManager(npc, npcData)
    if not npcData.SaltType then return end
    if not BitMask.HasAnyBitFlags(npcData.SaltType, saltTypes.SALT_SHAKER_JUDAS) then return end 
    if game:GetFrameCount() % 15 ~= 0 then return end

    Helpers.SpawnFireJet(npc.Position, 2, 1, 1)
end

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local npcData = data(npc)

    JudasBRSaltManager(npc, npcData)
    CinderStatusManager(npc, npcData)
end)

local CreepUpdaters = {
    [subtype.SALT_CREEP] = SaltCreepUpdate,
    [subtype.PEPPER_CREEP] = PepperCreepUpdate,
    [subtype.CINDER_CREEP] = CinderCreepUpdate,
    [subtype.OREGANO_CREEP] = OreganoCreepUpdate,
}

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local updater = CreepUpdaters[effect.SubType]
    if updater then updater(effect) end
end, EffectVariant.PLAYER_CREEP_RED)