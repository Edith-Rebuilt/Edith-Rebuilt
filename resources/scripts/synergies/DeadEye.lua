local mod = EdithRebuilt
local enums = mod.Enums
local Player = mod.Modules.PLAYER
local callbacks = enums.Callbacks

---@param player EntityPlayer
---@param isStomp boolean
local function AddDeadEyeCharge(player, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_EYE) then return end

    local charges = (isStomp and Player.IsEdithBirthtight(player)) and 2 or 1

    for _ = 1, charges do
        player:AddDeadEyeCharge()
    end
end

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP_HIT, function (_, player)
    AddDeadEyeCharge(player, true)
end)

---@param player EntityPlayer
mod:AddCallback(callbacks.PERFECT_PARRY, function (_, player)
    AddDeadEyeCharge(player, false)
end)
