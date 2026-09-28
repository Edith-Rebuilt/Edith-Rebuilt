local mod = EdithRebuilt

local data = mod.DataHolder.GetEntityData

TREdith = {}

---@class TREdithFlingShoveParams
---@field ShoveDamage number
---@field ShoveRadius number
---@field ShoveKnockback number
---@field FlingStaticCharge number
---@field FlingMoveCharge number
---@field FlingDirection Vector
---@field FlingStrength number
---@field FlingDuration integer
---@field FlingVel Vector
---@field BurstRadius number
---@field BurstKnockback number
---@field Cooldown integer
---@field IsFlinging boolean
---@field ShovedEntities Entity[]

local function NewFlingShoveParams()
	return {
		ShoveDamage = 0,
		ShoveRadius = 0,
		ShoveKnockback = 0,
		FlingStaticCharge = 0,
		FlingMoveCharge = 0,
		FlingDirection = Vector.Zero,
		FlingStrength = 10,
		FlingDuration = 0,
		FlingVel = Vector.Zero,
		BurstRadius = 0,
		BurstKnockback = 0,
		Cooldown = 0,
		IsFlinging = false,
		ShovedEntities = {},
	} --[[@as TREdithFlingShoveParams]]
end

---@param player EntityPlayer
function TREdith.GetFlingShoveParams(player)
	local playerData = data(player)
    playerData.JumpParams = playerData.JumpParams or NewFlingShoveParams()

    return playerData.JumpParams
end

---@param player EntityPlayer
function TREdith.IsTREdith(player)
	return player:GetPlayerType() == mod.Enums.Epiphany.PlayerType.PLAYER_EDITH_C
end

---@param current number
---@param amount number
---@return number
local function AddCharge(current, amount)
    return mod.Modules.MATHS.Clamp(current + amount, 0, 1)
end

---@param player EntityPlayer
---@param charge number
function TREdith.AddFlingCharge(player, charge)
    local flingParams = TREdith.GetFlingShoveParams(player)

    flingParams.FlingMoveCharge = AddCharge(flingParams.FlingMoveCharge, charge)
    flingParams.FlingStaticCharge = AddCharge(flingParams.FlingStaticCharge, charge)
end

---@param player EntityPlayer
---@param Static boolean --- `true` to get Static charge, otherwise gets Move charge 
---@return number
function TREdith.GetFlingShoveCharge(player, Static)
	local flingParams = TREdith.GetFlingShoveParams(player)
	local charge = Static and flingParams.FlingStaticCharge or flingParams.FlingMoveCharge

	return charge
end

return TREdith