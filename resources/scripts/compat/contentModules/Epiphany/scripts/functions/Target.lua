local mod = EdithRebuilt_TarnishedEdith
local mainMod = EdithRebuilt
local mainModules = mainMod.Modules
local effectVariant = mod.Enums.EffectVariant
local Helpers = mainModules.HELPERS
local TargetArrow = mainModules.TARGET_ARROW

local Target = {}

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@return EntityEffect
function Target.GetTREdithTarget(player)
	local Data = TargetArrow.getTargetData(player)
	return Data.TREdithTarget
end

---@param player EntityPlayer
function Target.SpawnTREdithTarget(player)
	if Helpers.IsDogmaAppearCutscene() then return end
	if Target.GetTREdithTarget(player) then return end

	local Data = TargetArrow.getTargetData(player)
	local target = Isaac.Spawn(	
		EntityType.ENTITY_EFFECT,
		effectVariant.EFFECT_EDITH_C_TARGET,
		0,
		player.Position,
		Vector.Zero,
		player
	):ToEffect() ---@cast target EntityEffect
	target.DepthOffset = -100
	target.SortingLayer = SortingLayer.SORTING_NORMAL
    target.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
    target.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
    Data.TREdithTarget = target
end

---@param player EntityPlayer
---@return Vector
function Target.GetEdithTargetDirection(player)
	local target = Target.GetTREdithTarget(player)
	if not target then return Vector.Zero end

	return (target.Position - player.Position):Normalized()
end

---Function to remove Edith's target
---@param player EntityPlayer
function Target.RemoveEdithTarget(player)
	local target = Target.GetTREdithTarget(player)

	if not target then return end
	target:Remove()
	local Data = TargetArrow.getTargetData(player)

	Data.TREdithTarget = nil
end

return Target