local mod = EdithRebuilt
local Player = mod.Modules.PLAYER
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param isStomp boolean
local function FireTechX(player, isStomp)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then return end

	local techXDistance = (isStomp and Player.IsEdithBirthtight(player)) and 65 or 50
	local LaserDamage = (techXDistance / 100) + 0.25
	local techX = player:FireTechXLaser(player.Position, Vector.Zero, techXDistance, player, LaserDamage)

	techX.DisableFollowParent = true
	techX:SetTimeout(17)
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) FireTechX(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) FireTechX(player, true) end)
