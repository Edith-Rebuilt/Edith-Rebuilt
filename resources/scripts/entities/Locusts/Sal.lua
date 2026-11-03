local mod = EdithRebuilt
local enums = mod.Enums

local items = enums.CollectibleType

local modules = mod.Modules
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS

---@param fam EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (_, fam)
    if not Helpers.IsModItemLocust(fam, items.COLLECTIBLE_SAL) then return end
    if fam.State ~= -1 then return end
    if fam.FrameCount % 5 ~= 0 then return end

    Creeps.SpawnSaltCreep(fam, fam.Position, 0.5, 5, 3, 3, 4)
end)