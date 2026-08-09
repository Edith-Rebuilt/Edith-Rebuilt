local mod = EdithRebuilt
local enums = mod.Enums
local callbacks = enums.Callbacks

---@param player EntityPlayer
local function AddDeadEyeCharge(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_EYE) then return end
    player:AddDeadEyeCharge()
end

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP_HIT, function (_, player)
    AddDeadEyeCharge(player)
end)

---@param player EntityPlayer
mod:AddCallback(callbacks.PERFECT_PARRY, function (_, player)
    AddDeadEyeCharge(player)
end)
