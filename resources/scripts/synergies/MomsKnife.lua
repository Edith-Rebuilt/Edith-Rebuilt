local mod = EdithRebuilt
local Player = mod.Modules.PLAYER
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
---@param isStomp boolean
local function FireKnives(player, isStomp)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then return end

	local knifeEntities = (isStomp and Player.IsEdithBirthtight(player)) and 8 or 4
	local degrees = 360 / knifeEntities

	for i = 1, knifeEntities do
		local knife = player:FireKnife(player, degrees * i, true, 0, 0)
		knife:Shoot(1, player.TearRange / 3)
		data(knife).SynergyKnife = true
	end
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) FireKnives(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) FireKnives(player, true) end)

---@param knife EntityKnife
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, knife)
	if not data(knife).SynergyKnife then return end
	if knife:IsFlying() then return end

	knife:Remove()
end)
