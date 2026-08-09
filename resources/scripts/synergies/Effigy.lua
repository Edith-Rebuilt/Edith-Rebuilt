local mod = EdithRebuilt
local enums = mod.Enums
local NullItemID = enums.NullItemID
local modules = mod.Modules
local Helpers = modules.HELPERS
local StompUtils = modules.STOMP_UTILS
local Player = modules.PLAYER
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param params EdithJumpStompParams | TEdithHopParryParams
---@param isStomp boolean
local function EffigyIncreasedDamage(player, params, isStomp)
    if not player:GetEffects():HasNullEffect(NullItemID.EFFIGY) then return end

    local reduceCharges = (isStomp and Player.IsEdithBirthtight(player)) and 2 or 4
    local damage = StompUtils.GetDamage(params)

    StompUtils.SetDamage(params, damage * 2.5)
    player:SetActiveCharge(Helpers.GetEffigyCharge(player) - reduceCharges, Helpers.GetEffigySlot(player))
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function (_, player, params)
    EffigyIncreasedDamage(player, params, true)
end)

---@param player EntityPlayer
---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function (_, player, _, params)
    EffigyIncreasedDamage(player, params, false)
end)