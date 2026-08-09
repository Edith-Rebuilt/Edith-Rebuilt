local mod = EdithRebuilt
local modules = mod.Modules
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param isStomp boolean
local function FireTechLaser(player, ent, isStomp)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then return end
	if not Helpers.IsEnemy(ent) then return end

	local hasBirthright = Player.IsEdithBirthtight(player)
	local damageMult = (isStomp and hasBirthright) and 1.25 or 1
	local distDiv = (isStomp and hasBirthright) and 4 or 5
	local playerPos = player.Position
	local entPos = ent.Position
	local dir = (entPos - playerPos):Normalized()
	local dist = playerPos:Distance(entPos)
	local laser = player:FireTechLaser(playerPos, LaserOffset.LASER_TECH1_OFFSET, dir, false, true, player, damageMult)

	laser:SetMaxDistance(dist + (player.TearRange / distDiv))
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, ent) FireTechLaser(player, ent, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent) FireTechLaser(player, ent, true) end)
