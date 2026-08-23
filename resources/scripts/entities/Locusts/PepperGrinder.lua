local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local StatusEffects = modules.STATUS_EFFECTS
local ModRNG = modules.RNG

---@param ent Entity
---@param RNG RNG
local function SpawnPepperCloud(ent, RNG)
    local X = ModRNG.RandomFloat(RNG, 0.8, 1)
    local Y = ModRNG.RandomFloat(RNG, 0.8, 1)
    local pitch = ModRNG.RandomFloat(RNG, 0.9, 1.1)
    local pepperCloud = StatusEffects.SpawnSpicePuff(ent, RNG)

    pepperCloud.SpriteScale = pepperCloud.SpriteScale * Vector(X, Y)
    Helpers.ChangeColor(pepperCloud, 0.4, 0.4, 0.4)
    enums.Utils.SFX:Play(enums.SoundEffect.SOUND_PEPPER_GRINDER, 10, 0, false, pitch)
end

---@param locust EntityFamiliar
local function TriggerEnemyDamage(locust)
    for _, enemy in ipairs(Isaac.FindInRadius(locust.Position, 60, EntityPartition.ENEMY)) do
        Helpers.TriggerPush(enemy, locust, 20)
        StatusEffects.SetStatusEffect(enums.EdithStatusEffects.PEPPERED, enemy, 90, locust)
    end
end

---@param ent Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, ent, amount, flags, source)
    local sourceEnt = source.Entity

    if not sourceEnt then return end

    local fam = sourceEnt:ToFamiliar()

    if not fam then return end
    if not Helpers.IsModItemLocust(fam, items.COLLECTIBLE_PEPPERGRINDER) then return end

    SpawnPepperCloud(fam, fam:GetDropRNG())
    TriggerEnemyDamage(fam)
end)