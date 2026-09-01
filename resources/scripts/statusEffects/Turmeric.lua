local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local rng = RNG(math.max(Random(), 1))
local TurmericColor = Color(1, 1, 1, 1, 250/255, 198/255, 49/255)

---@param entity Entity
local function SpawnTurmericCloud(entity)
    local Puff = Status.SpawnSpicePuff(entity, rng)
    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(rng, 0.9, 1.1)
    Puff.Color = TurmericColor
end

---@param entity Entity
local function SetTurmeric(entity)
    for _, enemy in ipairs(Isaac.FindInRadius(entity.Position, 60, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(enemy) then goto continue end
        if not ModRNG.RandomBoolean(rng, 0.4) then goto continue end

        SpawnTurmericCloud(entity)
        Status.SetStatusEffect(effects.TURMERIC, enemy, 90, entity)
        ::continue::
    end
end

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param Cooldown integer
---@return boolean|table?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, _, Cooldown)
    if not Status.EntHasStatusEffect(entity, effects.TURMERIC) then return end
    SetTurmeric(entity)
    return {Damage = amount * 1.25, DamageFlags = flags, DamageCountdown = Cooldown}
end)