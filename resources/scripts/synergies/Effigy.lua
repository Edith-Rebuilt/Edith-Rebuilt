local mod = EdithRebuilt
local enums = mod.Enums
local NullItemID = enums.NullItemID
local modules = mod.Modules
local Helpers = modules.HELPERS
local StompUtils = modules.STOMP_UTILS
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param params EdithJumpStompParams | TEdithHopParryParams
local function EffigyIncreasedDamage(player, params)
    if not player:GetEffects():HasNullEffect(NullItemID.EFFIGY) then return end

    local damage = StompUtils.GetDamage(params)

    StompUtils.SetDamage(params, damage * 2.5)
    player:SetActiveCharge(Helpers.GetEffigyCharge(player) - 4, Helpers.GetEffigySlot(player))
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function (_, player, params)
    EffigyIncreasedDamage(player, params)
end)

---@param player EntityPlayer
---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function (_, player, _, params)
    EffigyIncreasedDamage(player, params)
end)