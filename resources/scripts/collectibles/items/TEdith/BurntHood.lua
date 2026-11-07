local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType

local modules = mod.Modules
local TEdith = modules.TEDITH
local Land = modules.LAND
local Jump = modules.JUMP
local ParryHop = modules.PARRY_HOP

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
	if Jump.IsJumping(player) then return end
    Jump.InitTaintedEdithParryJump(player, "BrokenHoodParry")
end, items.COLLECTIBLE_BURNT_HOOD)

---@param player EntityPlayer
---@param jumpData JumpData
---@return boolean
local function TriggerParry(player, jumpData)
	local PerfectParry = ParryHop.ParryLandManager(player, TEdith.GetHopParryParams(player), false)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, PerfectParry), Color.Default, jumpData, PerfectParry)

	return PerfectParry
end

---@param player EntityPlayer
local function TriggerPerfectParryReward(player)
	player:SetMinDamageCooldown(20)
	player:FullCharge(player:GetActiveItemSlot(items.COLLECTIBLE_BURNT_HOOD))
end	

---@param player EntityPlayer
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player, jumpData)
	local PerfectParry = TriggerParry(player, jumpData)

	if not PerfectParry then return end

	TriggerPerfectParryReward(player)
end, { tag = "BrokenHoodParry" })