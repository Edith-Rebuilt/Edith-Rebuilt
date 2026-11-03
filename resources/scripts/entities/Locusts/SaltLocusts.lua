local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local statusEffects = modules.STATUS_EFFECTS

local saltItem = {
    [items.COLLECTIBLE_SAL] = true,
    [items.COLLECTIBLE_SALT_HEART] = true,
    [items.COLLECTIBLE_EDITHS_HOOD] = true,
    [items.COLLECTIBLE_SALTSHAKER] = true,
}

-- -@param fam EntityFamiliar
-- -@param col Entity
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, fam, col)
    if not Helpers.When(fam.SubType, saltItem, false) then return end
    if not Helpers.IsEnemy(col) then return end

    statusEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, col, 120, fam.Player)
end)
