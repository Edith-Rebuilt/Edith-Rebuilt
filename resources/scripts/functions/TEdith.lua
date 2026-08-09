---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local parryTypes = enums.ParryTypes
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local jumpTags = enums.Tables.JumpTags
local TEdith = {}
local data = mod.DataHolder.GetEntityData

---@class TEdithHopParryParams
---@field HopDamage number
---@field HopRadius number
---@field HopKnockback number
---@field HopDirection Vector
---@field HopMoveCharge number
---@field HopMoveBRCharge number
---@field HopStaticCharge number -- Used to render ChargeBar and ChargeBar mechanics when TEdith isn't moving
---@field HopStaticBRCharge number -- Used to render ChargeBar and ChargeBar mechanics when TEdith isn't moving
---@field ParryDamage number
---@field ParryRadius number
---@field ParryKnockback number
---@field ParryCooldown number
---@field ImpreciseParriedEnemies Entity[]
---@field ParriedEnemies Entity[]
---@field IsHoping boolean
---@field IsParryJump boolean
---@field IsBlazingParry boolean
---@field ParryBomb boolean
---@field GrudgeDash boolean

local function NewHopParryParams()
	return {
		HopDamage = 0,
		HopRadius = 0,
		HopKnockback = 0,
		HopDirection = Vector.Zero,
		IsHoping = false,
		IsParryJump = false,
		HopMoveCharge = 0,
		HopMoveBRCharge = 0,
		HopStaticCharge = 0,
		HopStaticBRCharge = 0,
		ParryDamage = 0,
		ParryKnockback = 0,
		ParryRadius = 0,
		ParryCooldown = 0,
		ParriedEnemies = {},
		ImpreciseParriedEnemies = {},
		GrudgeDash = false,
		ParryBomb = false,
		IsBlazingParry = false
	} --[[@as TEdithHopParryParams]]
end

---@param player EntityPlayer
---@return TEdithHopParryParams
function TEdith.GetHopParryParams(player)
	local playerData = data(player)
    playerData.HopDashParams = playerData.HopDashParams or NewHopParryParams()
    
	return playerData.HopDashParams
end

---@param player EntityPlayer
---@param Static boolean --- `true` to get Static charge, otherwise gets Move charge 
---@param checkBirthright? boolean --- Setting it to `true` will add Birthright charge to the returned value
---@return number
function TEdith.GetHopDashCharge(player, Static, checkBirthright)
	local hopParams = TEdith.GetHopParryParams(player)
	local charge = Static and hopParams.HopStaticCharge or hopParams.HopMoveCharge
	local chargeBR = Static and hopParams.HopStaticBRCharge or hopParams.HopMoveBRCharge

	if not charge then return 0 end
	return charge + (checkBirthright and chargeBR or 0)
end

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
function TEdith.ParryCooldownManager(player, HopParams)
	local colorChange = math.min((HopParams.HopStaticCharge) / 100, 1) * 0.5
	local colorBRChange = math.min(HopParams.HopStaticBRCharge / 100, 1) * 0.1
	local playerData = data(player)
	local ParryCooldown = HopParams.ParryCooldown

	playerData.ParryReadyGlowCount = playerData.ParryReadyGlowCount or 0

	local GlowCount = playerData.ParryReadyGlowCount

	if ParryCooldown < 1 then
		playerData.ParryReadyGlowCount = GlowCount + 1
	end

	if GlowCount > 20 then
		playerData.ParryReadyGlowCount = 0
	end

	if colorChange > 0 and colorChange <= 1 then
		player:SetColor(Color(1, 1, 1, 1, colorChange, colorBRChange, 0), 5, 100, true, false)
	end

	if GlowCount == 20 and ParryCooldown == 0 then
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.5, 0, false, 1.3)
		player:SetColor(Color(1, 1, 1, 1, colorChange + 0.3, 0, 0), 5, 100, true, false)
	end
	
	if ParryCooldown == 1 and player.FrameCount > 20 then
		player:SetColor(Color(1, 1, 1, 1, 0.5 + colorChange), 5, 100, true, false)
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
		playerData.ParryReadyGlowCount = 0
	end

	if TEdith.IsTaintedEdithJump(player) ~= true then
		HopParams.ParryCooldown = math.max(ParryCooldown - 1, 0)
	end
end

---Reset both Tainted Edith's Move charge and Birthright charge
---@param player EntityPlayer
---@param Move boolean Resets both `HopMoveCharge` and HopMoveBRCharge
---@param Static boolean Resets both `HopStaticCharge` and `HopStaticBRCharge`
function TEdith.ResetHopDashCharge(player, Move, Static)
	local hopParams = TEdith.GetHopParryParams(player)

	if Move then
		hopParams.HopMoveCharge = 0
		hopParams.HopMoveBRCharge = 0
	end

	if Static then
		hopParams.HopStaticCharge = 0
		hopParams.HopStaticBRCharge = 0
	end
end

function TEdith.IsTaintedEdithJump(player)
	return JumpLib:GetData(player).Tags["edithRebuilt_TaintedEdithJump"] or false
end

-- local function SetArrowDirection(player, arrow)
-- 	arrow.Velocity = 
-- end	

---@param player EntityPlayer
---@param arrow EntityEffect
---@param arrowVel Vector
---@param hopParams TEdithHopParryParams
local function ArrowVelocityManager(player, arrow, arrowVel, hopParams)
	local posDif = arrow.Position - player.Position
    local posDifNorm = posDif:Normalized()
    local vecSize = data(player).IsRedirectioningMove and 12.5 or 10
    local posDifLength = posDif:Length()
    local maxDist = (2.5 * (10 / vecSize))
    local targetVel = arrowVel:Resized(vecSize)

	hopParams.HopDirection = posDifNorm

    if posDifLength >= maxDist then
        targetVel = targetVel - (posDifNorm * (posDifLength / maxDist))
    end

	arrow.Velocity = targetVel
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
function TEdith.ArrowMovementManager(player, hopParams)
	local modules = mod.Modules
	local arrow = modules.TARGET_ARROW.GetEdithTarget(player, true)

	if not arrow then return end

	local input = modules.PLAYER.GetMovementInput(player)
	local arrowVel = modules.VEC_DIR.GetMovementVector(input)

	ArrowVelocityManager(player, arrow, arrowVel, hopParams)
end

---Helper function to stop Tainted Edith's hop-dash
---@param player EntityPlayer
---@param cooldown number
---@param useQuitJump boolean
---@param resetCharge boolean
---@param keepFriction? boolean
function TEdith.StopTEdithHops(player, cooldown, useQuitJump, resetCharge, keepFriction)
	if not mod.Modules.PLAYER.IsEdith(player, true) then return end

	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false
	keepFriction = keepFriction or false

	local hopParams = TEdith.GetHopParryParams(player)
	local isMoving = hopParams.IsHoping or hopParams.GrudgeDash

	if not isMoving then return end

	mod.Modules.LAND.TaintedEdithHop(player, hopParams)

	hopParams.IsHoping = false
	hopParams.GrudgeDash = false
	hopParams.HopDirection = Vector.Zero

	if not keepFriction then
		player:MultiplyFriction(0.5)
	end

	if useQuitJump then
		JumpLib:QuitJump(player)
	end

	if resetCharge then
		TEdith.ResetHopDashCharge(player, true, true)
	end

	player:SetMinDamageCooldown(cooldown)
end

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
function TEdith.BlazingParryManager(player, HopParams)
	local modules = mod.Modules

	HopParams.IsBlazingParry = modules.RNG.RandomBoolean(player:GetDropRNG(), modules.HELPERS.GetLuckInteractionChance(player.Luck))
end

function TEdith.HopCurve(t)
    return 1 - ((1 - t) ^ 2)
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isHopVecZero boolean
---@param isJumping boolean
---@param isGrudge boolean
local function ManageEdithHop(player, hopParams, isHopVecZero, isJumping, isGrudge)
	if isHopVecZero then return end

	if not isJumping and not isGrudge then
		mod.Modules.JUMP.InitTaintedEdithHop(player)
	end

	hopParams.IsHoping = true
end

local smoothFactor = 0.25

---@param player EntityPlayer
---@param HopVec Vector
---@param speedBase number
local function ManageEdithDash(player, HopVec, chargeMult, speedBase)
	local targetVel = (((HopVec * 2) * (speedBase + (player.MoveSpeed - 1))) * TEdith.HopCurve(chargeMult))

	player.Velocity = player.Velocity + (targetVel - player.Velocity) * smoothFactor
end

---@param hopParams TEdithHopParryParams
---@param isGrudge boolean
local function SetGrudgeDashState(hopParams, isGrudge)
	hopParams.GrudgeDash = isGrudge and hopParams.IsHoping
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
function TEdith.HopDashMovementManager(player, hopParams)
	local charge = TEdith.GetHopDashCharge(player, false, false)

	if charge < 10 then return end

	local HopVec = hopParams.HopDirection
	local modules = mod.Modules
	local isHopVecZero = HopVec.X == 0 and HopVec.Y == 0
	local isJumping = modules.JUMP.IsJumping(player)
	local isGrudge = modules.HELPERS.IsGrudgeChallenge()
	local chargeMult = (charge / 100)
	local speedBase = isGrudge and 9 or 8.5

	ManageEdithHop(player, hopParams, isHopVecZero, isJumping, isGrudge)
	ManageEdithDash(player, HopVec, chargeMult, speedBase)
	SetGrudgeDashState(hopParams, isGrudge)
end

---@param current number
---@param amount number
---@return number
local function AddCharge(current, amount)
    return mod.Modules.MATHS.Clamp(current + amount, 0, 100)
end

---@param player EntityPlayer
---@param charge number
---@param brMult number
function TEdith.AddHopDashCharge(player, charge, brMult)
    local hopParams = TEdith.GetHopParryParams(player)

    hopParams.HopMoveCharge = AddCharge(hopParams.HopMoveCharge, charge)
    hopParams.HopStaticCharge = AddCharge(hopParams.HopStaticCharge, charge)

    if not (mod.Modules.PLAYER.PlayerHasBirthright(player) and hopParams.HopMoveCharge >= 100) then return end

    local brCharge = charge * brMult
    hopParams.HopMoveBRCharge = AddCharge(hopParams.HopMoveBRCharge, brCharge)
    hopParams.HopStaticBRCharge = AddCharge(hopParams.HopStaticBRCharge, brCharge)
end

---@param player EntityPlayer
---@param arrow EntityEffect
---@param hopParams TEdithHopParryParams
function TEdith.HopDashChargeManager(player, arrow, hopParams)
	local isJumping = mod.Modules.JUMP.IsJumping(player)
    if arrow.FrameCount > 1 and not hopParams.IsHoping and not isJumping then
		local chargeAdd = enums.Misc.BaseHopChargeAdder * mod.Modules.MATHS.exp(player.MoveSpeed, 1, 1.5)
        TEdith.AddHopDashCharge(player, chargeAdd, 0.5)
    end
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param forceParry boolean
---@param jumpData JumpData
local function HandleParryLanding(player, hopParams, forceParry, jumpData)
	local Land = mod.Modules.LAND
    local PerfectParry = Land.ParryLandManager(player, hopParams, true)
    local parryResult = forceParry or PerfectParry
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, parryResult), misc.BurntSaltColor, jumpData, parryResult)
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param jumpData JumpData
local function HandleNormalParry(player, hopParams, jumpData)
    if not hopParams.IsHoping then
        mod.Modules.JUMP.InitTaintedEdithParryJump(player, jumpTags.TEdithJump)
	else
		TEdith.StopTEdithHops(player, 0, true, true, false)
		HandleParryLanding(player, hopParams, false, jumpData)
    end
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param jumpData JumpData
local function HandleGrudgeParry(player, hopParams, jumpData)
    TEdith.StopTEdithHops(player, 0, true, true, false)
    HandleParryLanding(player, hopParams, true, jumpData)
end

---@param player EntityPlayer
---@param IsGrudge boolean
---@param hopParams TEdithHopParryParams
---@param jumpData JumpData
function TEdith.ParryTriggerManager(player, IsGrudge, hopParams, jumpData)
    if IsGrudge then
        HandleGrudgeParry(player, hopParams, jumpData)
    else
        HandleNormalParry(player, hopParams, jumpData)
    end
    player:MultiplyFriction(0.1)
end

---@param hopParams TEdithHopParryParams
---@return ParryTypes
function TEdith.GetParryType(hopParams)
	local impreciseCount = #hopParams.ImpreciseParriedEnemies
	local perfectCount = #hopParams.ParriedEnemies

	if impreciseCount > 0 then
		return perfectCount > 0 and parryTypes.PERFECT or parryTypes.IMPRECISE
	end

	return parryTypes.FAILED
end

return TEdith