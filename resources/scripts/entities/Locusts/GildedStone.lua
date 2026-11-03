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

---@param amount number
---@param source EntityRef
---@return boolean|table?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, _, amount, _, source)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_GILDED_STONE) then return end

    local mult = ModRNG.RandomFloat(ent:GetDropRNG(), 1.5, 2)

    return {Damage = amount * mult}
end)

---@param npc EntityNPC
---@param source EntityRef  
mod:AddCallback(PRE_NPC_KILL.ID, function (_, npc, source)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_GILDED_STONE) then return end

    Helpers.SpawnSaltTears(ent:ToFamiliar().Player, npc, ent:GetDropRNG(), 3, 6)
end)