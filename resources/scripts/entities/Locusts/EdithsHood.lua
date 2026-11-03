local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS

---@param npc EntityNPC
---@param source EntityRef  
mod:AddCallback(PRE_NPC_KILL.ID, function (_, npc, source)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_EDITHS_HOOD) then return end

    Helpers.SpawnSaltTears(ent:ToFamiliar().Player, npc, ent:GetDropRNG(), 3, 6)
end)