local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG

---@param fam EntityFamiliar
---@param col Entity
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, fam, col)
    if not Helpers.IsModItemLocust(fam, items.COLLECTIBLE_GILDED_STONE) then return end
    if not Helpers.IsEnemy(col) then return end
    if ModRNG.RandomBoolean(fam:GetDropRNG(), 0.25) then return end

    col:AddMidasFreeze(EntityRef(fam), 75)
end)

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
---@return boolean|table?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, amount, flags, source, countdown)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_GILDED_STONE) then return end

    local mult = ModRNG.RandomFloat(ent:GetDropRNG(), 1.5, 2)

    return {Damage = amount * mult, DamageFlags = flags, DamageCountdown = countdown}
end)

---@param npc EntityNPC
---@param source EntityRef  
mod:AddCallback(PRE_NPC_KILL.ID, function (_, npc, source)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_GILDED_STONE) then return end

    Helpers.SpawnSaltTears(ent:ToFamiliar().Player, npc, ent:GetDropRNG(), 3, 6)
end)