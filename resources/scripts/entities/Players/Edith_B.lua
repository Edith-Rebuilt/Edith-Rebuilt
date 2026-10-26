-- #region Imports
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local misc = enums.Misc
local parryTypes = enums.ParryTypes

local game = utils.Game
local sfx = utils.SFX
local room = utils.Room

local jumpTags = tables.JumpTags

local modules = mod.Modules
local VecDir = modules.VEC_DIR
local maths = modules.MATHS
local land = modules.LAND
local Player = modules.PLAYER
local TargetArrow = modules.TARGET_ARROW
local TEdithMod = modules.TEDITH
local Helpers = modules.HELPERS
local effects = modules.STATUS_EFFECTS
local BitMask = modules.BIT_MASK
local Jump = modules.JUMP

local data = mod.DataHolder.GetEntityData

local PLAYER_TYPE = enums.PlayerType.PLAYER_EDITH_B
-- #endregion Imports

-- #region Constants
local DAMAGE_BASE = 5.25
local VEC_ONE = Vector.One

local COOLING_INTERVAL = 6
local COOLING_STEP_HOPPING = 0.02
local COOLING_STEP_IDLE = 0.01

local MIN_DASH_CHARGE = 10
local MIN_STOP_CHARGE = 50
local MIN_ARMOR_CHARGE = 20
local SHAKE_CHARGE = 50

local REDIRECT_MAX_PRESSES = 10
local REDIRECT_COLOR_PRESS = 5
local REDIRECT_FRICTION_PRESSES = 2

local STORED_INPUT_WINDOW = 6
local PERFECT_PARRY_CHARGE = 25
local PERFECT_PARRY_CHARGE_RATIO = 0.75

local MIRROR_DOOR_DISTANCE_SQ = 1600
local WISP_MAX_SPEED_SQ = 2500
local TRANSITION_MODE_ROOM = 3

local HEAT_ADDERS = {
	[parryTypes.IMPRECISE] = 0.1,
	[parryTypes.PERFECT] = 0.25,
}

local STOP_DASH_ANIMATIONS = {
	["MinecartEnter"] = true,
	["TeleportUp"] = true,
	["TeleportDown"] = true,
}

local Colors = {
	Cooldown = Color(1, 1, 1, 1, 0.3),
	HopDashStop = Color(1, 1, 1, 1, 0, 0.1, 0.3),
	Redirection = Color(1, 1, 1, 1, 0.3, 0.3, 0.3),
	CoolingComplete = Color(1, 1, 1, 1, 0.1, 0.2, 0.25),
}
-- #endregion Constants

-- #region Callback wrapper
---@param callback ModCallbacks
---@param fn fun(player: EntityPlayer, ...): any
local function AddTEdithCallback(callback, fn)
	mod:AddCallback(callback, function(_, player, ...)
		if not Player.IsEdith(player, true) then return end
		return fn(player, ...)
	end)
end
-- #endregion Callback wrapper

-- #region Parry kill
mod:AddCallback(enums.Callbacks.PERFECT_PARRY_KILL, function(_, _, ent)
	data(ent).KilledByParry = true
end)

mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	if npc:IsBoss() then return end
	if not effects.EntHasStatusEffect(npc, "Cinder") then return end
	if not data(npc).KilledByParry then return end

	return true
end)
-- #endregion Parry kill

-- #region Reset
---@param player EntityPlayer
---@param forceStopHops boolean
local function ResetTEdithPlayer(player, forceStopHops)
	Helpers.ChangeColor(player, nil, nil, nil, 1)
	data(player).PressCount = 0

	if not forceStopHops then return end
	TEdithMod.StopTEdithHops(player, 0, true, true, true)
end

---@param isLevelCallback boolean
local function RoomFloorStopManager(isLevelCallback)
	local forceStop = isLevelCallback or room:GetType() == RoomType.ROOM_DUNGEON

	Player.ForEachPlayerType(function(player)
		local lowCharge = TEdithMod.GetHopDashCharge(player, false) < MIN_STOP_CHARGE
		ResetTEdithPlayer(player, forceStop or lowCharge)
	end, PLAYER_TYPE)
end
-- #endregion Reset

-- #region Overheat
---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
---@param heat number
local function TEdithCooling(player, HopParams, heat)
	if player.FrameCount % COOLING_INTERVAL ~= 0 then return end
	if heat <= 0 then return end

	local decreaser = HopParams.IsHoping and COOLING_STEP_HOPPING or COOLING_STEP_IDLE

	if heat <= decreaser then
		sfx:Play(SoundEffect.SOUND_STEAM_HALFSEC, 0.25, 2, false, 0.5)
		player:SetColor(Colors.CoolingComplete, 5, 1, true, true)
	end

	TEdithMod.AddParryHeat(player, -decreaser)
end

---@param player EntityPlayer
---@param heat number
local function SpawnHeatSmoke(player, heat)
	local playerScale = player.SpriteScale

	local smoke = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.POOF02, 2,
		player.Position - Vector(0, 30 * playerScale.Y),
		Vector(0, -1) * (3 * heat),
		player
	):ToEffect() ---@cast smoke EntityEffect

	local rng = smoke:GetDropRNG()
	local colorize = 1 - (0.5 * heat)
	local size = 0.4 + (0.1 * heat)
	local sprite = smoke:GetSprite()

	sprite.Color:SetColorize(colorize, colorize, colorize, 1)
	sprite.PlaybackSpeed = 1.3 + (0.3 * heat)
	sprite.Scale = Vector(size, size) * playerScale * modules.RNG.RandomFloat(rng, 0.9, 1.1)
end

---@param player EntityPlayer
---@param heat number
local function TEdithHeatColor(player, heat)
	if heat <= 0 then return end

	local color = player.Color
	color.RO = color.RO + (0.5 * heat)
	player:SetColor(color, 1, 10, true, false)

	local smokeInterval = 10 - math.ceil(6 * heat * heat)
	if player.FrameCount % smokeInterval ~= 0 then return end

	SpawnHeatSmoke(player, heat)
end

---@param player EntityPlayer
---@param parryType ParryTypes
local function OverHeatManager(player, parryType)
	local adder = Helpers.When(parryType, HEAT_ADDERS)
	if not adder then return end

	TEdithMod.AddParryHeat(player, adder)
end
-- #endregion Overheat

-- #region Hop dash
---@param player EntityPlayer
---@param arrow EntityEffect?
---@param HopParams table
local function ManageHopDashCharge(player, arrow, HopParams)
	if arrow then
		TEdithMod.HopDashChargeManager(player, arrow, HopParams)
		return
	end

	TEdithMod.HopDashMovementManager(player, HopParams)

	if TEdithMod.GetHopDashCharge(player, false) < MIN_DASH_CHARGE then
		HopParams.HopMoveCharge = 0
		HopParams.HopStaticCharge = 0
		HopParams.HopDirection = Vector.Zero
	end
end

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
---@param arrow EntityEffect?
local function ManageHeadDirection(player, HopParams, arrow)
	if Player.IsPlayerShooting(player) then return end

	local faceDirection = VecDir.VectorToDirection(HopParams.HopDirection)
	local chosenDir = faceDirection or Direction.DOWN
	local isActive = HopParams.IsHoping or (arrow and arrow.Visible == true)

	if not isActive and VecDir.VectorEquals(HopParams.HopDirection, Vector.Zero) then
		chosenDir = Direction.DOWN
	end

	player:SetHeadDirection(chosenDir, 1, true)
end

---@param player EntityPlayer
local function ManageStopAnimations(player)
	if not Helpers.When(player:GetSprite():GetAnimation(), STOP_DASH_ANIMATIONS, false) then return end

	TEdithMod.StopTEdithHops(player, 0, true, true)
end

---@param player EntityPlayer
local function PitfallJumpStop(player)
	if not player:GetSprite():IsPlaying("FallIn") then return end

	TEdithMod.StopTEdithHops(player, 9, true, true, true)
end

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
---@param MiscConfig MiscData
local function ManageGrudgeEffects(player, HopParams, MiscConfig)
	if not Helpers.IsGrudgeChallenge() then return end
	if not HopParams.GrudgeDash then return end
	if data(player).IsRedirectioningMove then return end

	if MiscConfig and MiscConfig.EnableShakescreen and HopParams.HopMoveCharge > SHAKE_CHARGE then
		game:ShakeScreen(2)
	end

	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.3, 0, false, 1.2)
end
-- #endregion Hop dash

-- #region Parry input
---@param player EntityPlayer
---@param playerData table
---@param HopParams TEdithHopParryParams
---@param IsGrudge boolean
---@param jumpData JumpData
local function ManageParryInput(player, playerData, HopParams, IsGrudge, jumpData)
	local cooldown = HopParams.ParryCooldown

	if Helpers.IsKeyStompTriggered(player) then
		local isCurrentJumpParry = Jump.IsSpecificJump(JumpLib:GetData(player), jumpTags.TEdithJump)
		local maxCooldown = playerData.MaxParryCooldown

		if cooldown == 0 and not isCurrentJumpParry and not HopParams.IsParryJump then
			TEdithMod.ParryTriggerManager(player, IsGrudge, HopParams, jumpData)
		elseif maxCooldown and cooldown > 0 and cooldown >= maxCooldown - STORED_INPUT_WINDOW then
			player:SetColor(Colors.Cooldown, 3, 1, true, false)
			playerData.StoredInput = true
		end
	elseif playerData.StoredInput and cooldown <= 0 then
		TEdithMod.ParryTriggerManager(player, IsGrudge, HopParams, jumpData)
		playerData.StoredInput = false
	end
end
-- #endregion Parry input

-- #region Redirection
---@param player EntityPlayer
---@param pData table
---@param arrow EntityEffect
local function SetRedirectValues(player, pData, arrow)
	local canRedirect = TEdithMod.GetHopDashCharge(player, false) > 0
		and TEdithMod.GetHopDashCharge(player, true) <= 0

	pData.IsRedirectioningMove = canRedirect and arrow ~= nil
	pData.PressCount = pData.PressCount or 0
end

---@param player EntityPlayer
---@param pData table
---@param arrow EntityEffect?
---@param isArrowMoving boolean
local function ManageTargetCleanup(player, pData, arrow, isArrowMoving)
	if not arrow or isArrowMoving then return end

	TargetArrow.RemoveEdithTarget(player, true)

	if pData.IsRedirectioningMove and pData.PressCount <= REDIRECT_MAX_PRESSES then
		TEdithMod.StopTEdithHops(player, 20, false, true, true)
		player:MultiplyFriction(0.05)
		player:SetColor(Colors.HopDashStop, 5, 1000, true, false)
	end

	pData.PressCount = 0
end

---@param player EntityPlayer
---@param pData table
---@param isArrowMoving boolean
local function ManageRedirectionInput(player, pData, isArrowMoving)
	if not isArrowMoving then return end

	pData.PressCount = pData.PressCount + 1

	if not pData.IsRedirectioningMove then return end

	if pData.PressCount == REDIRECT_COLOR_PRESS then
		player:SetColor(Colors.Redirection, 5, 1000, true, false)
	elseif pData.PressCount <= REDIRECT_FRICTION_PRESSES then
		player:SetMinDamageCooldown(20)
		player:MultiplyFriction(0.05)
	end
end

---@param player EntityPlayer
---@param isArrowMoving boolean
local function ArrowSpawnManager(player, isArrowMoving)
	if not isArrowMoving then return end
	if player.ControlsCooldown > 0 then return end

	TargetArrow.SpawnEdithTarget(player, true)
end
-- #endregion Redirection

-- #region Landing
---@param player EntityPlayer
---@param jumpData JumpData
---@param params TEdithHopParryParams
local function OnHopLand(player, jumpData, params)
	if not Jump.IsSpecificJump(jumpData, jumpTags.TEdithHop) then return end

	local tearRange = player.TearRange / 40
	local knockbackBase = (player.ShotSpeed * 10) + 8
	local chargeRatio = TEdithMod.GetHopDashCharge(player, false, false) / 100
	local brMult = 1 + params.HopMoveBRCharge / 100
	local baseDamage = (DAMAGE_BASE + player.Damage) / 2

	params.HopDamage = baseDamage * TEdithMod.HopCurve(chargeRatio) * brMult
	params.HopKnockback = knockbackBase * maths.exp(chargeRatio, 1, 1.5)
	params.HopRadius = math.min(30 + (tearRange - 9), 35)

	player:SpawnWaterImpactEffects(player.Position, VEC_ONE, 1)
	land.LandFeedbackManager(player, land.GetLandSoundTable(true), misc.BurntSaltColor, jumpData)
	land.TaintedEdithHop(player, params)
end

---@param player EntityPlayer
---@param jumpData JumpData
---@param params TEdithHopParryParams
local function OnParryLand(player, jumpData, params)
	if not Jump.IsSpecificJump(jumpData, jumpTags.TEdithJump) then return end

	if TargetArrow.GetEdithTarget(player, true) then
		TEdithMod.ResetHopDashCharge(player, true, true)
	end

	local perfectParry = land.ParryLandManager(player, params, true)

	land.LandFeedbackManager(player, land.GetLandSoundTable(true, perfectParry), misc.BurntSaltColor, jumpData, perfectParry)
end

---@param player EntityPlayer
---@param parryType ParryTypes
local function ParryHopDashChargeBonus(player, parryType)
	if parryType ~= parryTypes.PERFECT then return end

	TEdithMod.AddHopDashCharge(player, PERFECT_PARRY_CHARGE, PERFECT_PARRY_CHARGE_RATIO)
end
-- #endregion Landing

-- #region Mirror room
---@param door GridEntityDoor
---@param player EntityPlayer
---@return boolean
local function IsMirrorDoorNearPlayer(door, player)
	local sheet = door:GetSprite():GetLayer(0):GetSpritesheetPath()

	return string.find(sheet, "mirror") ~= nil
		and door.Position:DistanceSquared(player.Position) <= MIRROR_DOOR_DISTANCE_SQ
end

---@param player EntityPlayer
local function FlipHopDirectionNearMirror(player)
	local params = TEdithMod.GetHopParryParams(player)

	for slot = 0, DoorSlot.NUM_DOOR_SLOTS do
		local door = room:GetDoor(slot)

		if door then
			if not IsMirrorDoorNearPlayer(door, player) then break end

			params.HopDirection.X = -params.HopDirection.X
			player:SetHeadDirection(VecDir.VectorToDirection(params.HopDirection), 2, true)
		end
	end
end
-- #endregion Mirror room

-- #region Wisps
---@param fam EntityFamiliar
local function IsWisp(fam)
	local variant = fam.Variant
	return variant == FamiliarVariant.WISP or variant == FamiliarVariant.ITEM_WISP
end

---@param player EntityPlayer
---@param ent Entity
local function StopVel(player, ent)
	if not Player.IsEdith(player, true) then return end
	if ent.Velocity:LengthSquared() <= WISP_MAX_SPEED_SQ then return end

	ent.Velocity = Vector.Zero
end
-- #endregion Wisps

-- #region Chargebars
---@param playerData table
local function SetChargeBars(playerData)
	playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)
	playerData.BRChargeBar = playerData.BRChargeBar or Sprite("gfx/TEdithBRChargebar.anm2", true)
end

---@param player EntityPlayer
---@param playerData table
local function GetMainChargeOffset(player, playerData)
	local isBRBarVisible = Player.PlayerHasBirthright(player)
		and not playerData.BRChargeBar:IsFinished("Disappear")

	return isBRBarVisible and misc.ChargeBarleftVector or misc.ChargeBarcenterVector
end

local function RenderChargeBars(playerData, playerPos, offset, dashCharge, dashBRCharge)
	HudHelper.RenderChargeBar(playerData.ChargeBar, dashCharge, 100, playerPos + offset)
	HudHelper.RenderChargeBar(playerData.BRChargeBar, dashBRCharge, 100, playerPos + misc.ChargeBarrightVector)
end
-- #endregion Charge bars

-- #region Callbacks
AddTEdithCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
	local HopParams = TEdithMod.GetHopParryParams(player)
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local heat = TEdithMod.GetParryHeat(player)

	Player.ManageLeoEffect(player)

	TEdithCooling(player, HopParams, heat)
	SetEdithSprite(player)
	TEdithHeatColor(player, heat)
	ManageHopDashCharge(player, arrow, HopParams)
	TEdithMod.ParryCooldownManager(player, HopParams)
end)

AddTEdithCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(player)
	local HopParams = TEdithMod.GetHopParryParams(player)
	local MiscConfig = Helpers.GetConfigData("MiscData") ---@cast MiscConfig MiscData
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local isArrowMoving = TargetArrow.IsEdithTargetMoving(player)
	local pData = data(player)

	TEdithMod.ArrowMovementManager(player, HopParams)
	ManageParryInput(player, pData, HopParams, Helpers.IsGrudgeChallenge(), JumpLib:GetData(player))

	if HopParams.IsHoping then
		TEdithMod.ResetHopDashCharge(player, false, true)
	end

	PitfallJumpStop(player)
	SetRedirectValues(player, pData, arrow)
	ManageTargetCleanup(player, pData, arrow, isArrowMoving)
	ArrowSpawnManager(player, isArrowMoving)
	ManageRedirectionInput(player, pData, isArrowMoving)
	ManageGrudgeEffects(player, HopParams, MiscConfig)
	ManageHeadDirection(player, HopParams, arrow)
	ManageStopAnimations(player)
end)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_ROOM_TEMP_EFFECTS, function()
	if utils.Level:GetCurrentRoomDesc().Data.Name == "Mirror Room" then
		Player.ForEachPlayerType(FlipHopDirectionNearMirror, PLAYER_TYPE)
	end

	RoomFloorStopManager(false)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	RoomFloorStopManager(true)
end)

mod:AddCallback(enums.Callbacks.POST_PARRY_LAND, function(_, player)
	local parryType = TEdithMod.GetParryType(TEdithMod.GetHopParryParams(player))

	ParryHopDashChargeBonus(player, parryType)
	OverHeatManager(player, parryType)
end)

mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, jumpData)
	local player = ent:ToPlayer()
	if not player then return end

	local HopParams = TEdithMod.GetHopParryParams(player)

	TEdithMod.BlazingParryManager(player, HopParams)
	OnHopLand(player, jumpData, HopParams)
	OnParryLand(player, jumpData, HopParams)
end)

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags, source)
	if source.Type == EntityType.ENTITY_SLOT then return end
	if not Player.IsEdith(player, true) then return end
	if data(player).IsRedirectioningMove then return end

	local HopParams = TEdithMod.GetHopParryParams(player)

	if not (HopParams.IsHoping == true and HopParams.HopMoveCharge >= MIN_ARMOR_CHARGE) then return end
	if BitMask.HasBitFlags(flags, DamageFlag.DAMAGE_RED_HEARTS --[[@as BitSet128]]) then return end

	return false
end)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if RoomTransition:GetTransitionMode() == TRANSITION_MODE_ROOM then return end

	Player.ForEachPlayerType(function(player)
		local hopParams = TEdithMod.GetHopParryParams(player)
		local dashCharge = hopParams.HopStaticCharge
		local dashBRCharge = hopParams.HopStaticBRCharge

		if not dashCharge or not dashBRCharge then return end

		local playerData = data(player)

		SetChargeBars(playerData)
		RenderChargeBars(
			playerData,
			Player.GetPlayerRenderPos(player),
			GetMainChargeOffset(player, playerData),
			dashCharge,
			dashBRCharge
		)
	end, PLAYER_TYPE)
end)

AddTEdithCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function(player, _, grid)
	if not grid then return end

	local params = TEdithMod.GetHopParryParams(player)
	if not (params.IsHoping or params.GrudgeDash) then return end

	if grid:ToRock() or grid:ToPoop() or grid:ToTNT() then
		grid:Destroy()
	elseif not Jump.IsJumping(player) then
		TEdithMod.StopTEdithHops(player, 20, true, not data(player).TaintedEdithTarget, true)
	end
end)

AddTEdithCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function(player, collider)
	if collider.Type ~= EntityType.ENTITY_FIREPLACE then return end
	if collider.Variant ~= 4 then return end
	if player:HasInstantDeathCurse() then return end

	TEdithMod.StopTEdithHops(player, 20, true, true, true)
end)

mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
	if not IsWisp(fam) or not fam.Player then return end

	StopVel(fam.Player, fam)
end)

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	local player = npc:GetPlayerTarget():ToPlayer()
	if not player then return end

	StopVel(player, npc)
end, EntityType.ENTITY_WILLO)
-- #endregion Callbacks