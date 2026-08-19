local mod = EdithRebuilt
local JumpTags = mod.Enums.Tables.JumpTags
local modules = mod.Modules
local TargetArrow = modules.TARGET_ARROW
local Helpers = modules.HELPERS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local Jump = modules.JUMP

---@param player EntityPlayer
---@return boolean
local function IsEdithAndVestige(player)
	return Player.IsEdith(player, false) and Helpers.IsVestigeChallenge()
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
	if not IsEdithAndVestige(player) then return end
	player.TearRange = Player.rangeUp(player.TearRange, 1.75)
end, CacheFlag.CACHE_RANGE)

local function HandleVestigeDeath(player)
    if not player:IsDead() then return false end
    TargetArrow.RemoveEdithTarget(player)
    return true
end

local function HandleVestigeJumpTrigger(player)
    local jumpData = JumpLib:GetData(player)
    local isJumping = jumpData.Jumping
    local sprite = player:GetSprite()

    if Helpers.IsKeyStompTriggered(player) and not isJumping
    and not sprite:IsPlaying("BigJumpUp") and not sprite:IsPlaying("BigJumpFinish") then
        player:PlayExtraAnimation("BigJumpUp")
    end

    if sprite:IsEventTriggered("StartJump") and not isJumping then
        Jump.InitEdithJump(player, JumpTags.EdithJump, true)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if not IsEdithAndVestige(player) then return end
    if HandleVestigeDeath(player) then return end
    HandleVestigeJumpTrigger(player)
end)

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function (_, player)
	if not IsEdithAndVestige(player) then return end

	local target = TargetArrow.GetEdithTarget(player)

	if not target then return end
	local IsFalling = JumpLib:IsFalling(player)
	local targetDistance = TargetArrow.GetEdithTargetDistance(player)

	if Jump.GetJumpFrame(player) > 4 then
		EdithMod.EdithDash(player, TargetArrow.GetEdithTargetDirection(player), targetDistance, 40)
	end

	if IsFalling or TargetArrow.GetEdithTargetDistanceSquared(player) <= 25 then
		player.Velocity = Vector.Zero
		player.Position = target.Position
	end
end, EdithRebuilt.Enums.Tables.JumpParams.EdithJump)