-- #region Imports
local mod = EdithRebuilt
local enums = mod.Enums

local Vars = enums.EffectVariant
local utils = enums.Utils
local misc = enums.Misc
local tables = enums.Tables
local ConfigData = enums.ConfigDataTypes

local level = utils.Level
local room = utils.Room

local modules = mod.Modules
local Edith = modules.EDITH
local TEdith = modules.TEDITH
local Helpers = modules.HELPERS
local targetArrow = modules.TARGET_ARROW
local Jump = modules.JUMP

local data = mod.DataHolder.GetEntityData
-- #endregion Imports

-- #region Constants
local LINE_SECTION_LENGTH = 16
local CAMERA_TARGET_WEIGHT = 0.6
local VESTIGE_DRAG = 1

local TELEPORT_DISTANCE_SQR = 400
local TELEPORT_PUSH_DISTANCE = 25

local ARROW_BASE_SCALE = 0.6
local ARROW_CHARGE_SCALE = 0.4
local FULL_CHARGE = 100

local ROTGUT_VARIANT = 1
local ROTGUT_PUSH_SPEED = 20

local BEAST_ROOM_NAME = "Beast Room"
local ROTGUT_MAGGOT_ROOM_NAME = "Rotgut Maggot"

local teleportPoints = {
	Vector(110, 135),
	Vector(595, 385),
	Vector(595, 272),
}

local targetArrows = {
	[Vars.EFFECT_EDITH_TARGET] = true,
	[Vars.EFFECT_EDITH_B_TARGET] = true,
	[Vars.EFFECT_EDITH_C_TARGET] = true,
}

local FreeMovementTargets = {
	[Vars.EFFECT_EDITH_TARGET] = true,
	[Vars.EFFECT_EDITH_C_TARGET] = true,
}

local doorRadius = {
	[Vars.EFFECT_EDITH_TARGET] = 28,
	[Vars.EFFECT_EDITH_B_TARGET] = 20,
	[Vars.EFFECT_EDITH_C_TARGET] = 28,
}

local RGBColors = { Target = Color(1, 0, 0), Arrow = Color(1, 0, 0) }

local currentDate = os.date("*t")
local isTDOV = currentDate.month == 3 and currentDate.day == 31

local targetSprite = Sprite("gfx/edith rebuilt target.anm2", true)
local targetLineColor = Color(1, 1, 1, 1)
-- #endregion Constants

-- #region Utils
---@param effect EntityEffect
local function IsAnyEdithTarget(effect)
	return targetArrows[effect.Variant] or false
end

---@param vectorA Vector
---@param vectorB Vector
---@param t number
local function interpolateVector2D(vectorA, vectorB, t)
	return vectorA * (1 - t) + vectorB * t
end

---@param callback ModCallbacks
---@param handler fun(effect: EntityEffect, player: EntityPlayer): any
local function AddTargetCallback(callback, handler)
	mod:AddCallback(callback, function(_, effect)
		if not IsAnyEdithTarget(effect) then return end

		local player = effect.SpawnerEntity:ToPlayer()
		if not player then return end

		return handler(effect, player)
	end)
end

---@param effect EntityEffect
---@param rgbColor {R: number, G: number, B: number}
---@param solidColor {Red: number, Green: number, Blue: number}
---@param rgbMode boolean
---@param rgbSpeed number
---@param rgbState number
---@return number rgbState
local function ApplyRGBOrSolidColor(effect, rgbColor, solidColor, rgbMode, rgbSpeed, rgbState)
	if rgbMode then
		rgbState = Helpers.RGBFunction(rgbColor, rgbSpeed, rgbState)
		Helpers.ChangeColor(effect, rgbColor.R, rgbColor.G, rgbColor.B)
	else
		Helpers.ChangeColor(effect, solidColor.Red, solidColor.Green, solidColor.Blue)
	end
	return rgbState
end

---@param from Vector
---@param to Vector
---@param color Color
---@param isObscure? boolean
local function drawLine(from, to, color, isObscure)
	local diffVector = to - from
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / LINE_SECTION_LENGTH) - 1
	local direction = Vector.FromAngle(angle)

	targetSprite:SetFrame("Line", isObscure and 1 or 0)
	targetSprite.Color = color
	targetSprite.Rotation = angle

	for i = 0, sectionCount do
		local currentPos = from + direction * (i * LINE_SECTION_LENGTH)
		targetSprite:Render(Isaac.WorldToScreen(currentPos))
	end
end
-- #endregion Utils

-- #region Target Management
---@param effect EntityEffect
---@param player EntityPlayer
---@param params table
local function UpdateTargetAnimation(effect, player, params)
	local isActive = Helpers.IsKeyStompPressed(player) or (Jump.IsJumping(player) and params.Cooldown == 0)
	local isBlinking = isActive and (not Helpers.IsVestigeChallenge() or Jump.IsJumping(player))

	effect:GetSprite():Play(isBlinking and "Blink" or "Idle")
end

---@param playerPos Vector
---@param effectPos Vector
---@param isBeastRoom boolean
local function UpdateCameraFocus(playerPos, effectPos, isBeastRoom)
	if isBeastRoom then return end
	room:GetCamera():SetFocusPosition(interpolateVector2D(playerPos, effectPos, CAMERA_TARGET_WEIGHT))
end

---@param effect EntityEffect
---@param player EntityPlayer
local function HandleVestigeDrag(effect, player)
	if not (Helpers.IsVestigeChallenge() and Jump.IsJumping(player)) then return end
	effect.Velocity = effect.Velocity * VESTIGE_DRAG
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param isBeastRoom boolean
---@param roomName string
local function HandleDungeonTeleport(effect, player, isBeastRoom, roomName)
	if room:GetType() ~= RoomType.ROOM_DUNGEON then return end
	if isBeastRoom then return end

	local effectPos = effect.Position
	for _, point in ipairs(teleportPoints) do
		if (effectPos - point):LengthSquared() > TELEPORT_DISTANCE_SQR then goto continue end
		if roomName == ROTGUT_MAGGOT_ROOM_NAME and (point.X ~= 595 and point.Y ~= 385) then goto continue end
		player.Position = effectPos + effect.Velocity:Resized(TELEPORT_PUSH_DISTANCE)
		::continue::
	end
end

---@param effect EntityEffect
---@param player EntityPlayer
local function SyncMarkedTarget(effect, player)
	local markedTarget = player:GetMarkedTarget()
	if not markedTarget then return end

	markedTarget.Position = effect.Position
	markedTarget.Velocity = Vector.Zero
	markedTarget.Visible = false
end

---@param effect EntityEffect
---@param player EntityPlayer
local function FreeMovmentTargetManagement(effect, player)
	if not FreeMovementTargets[effect.Variant] then return end

	local params = Edith.GetJumpStompParams(player)
	local roomName = level:GetCurrentRoomDesc().Data.Name
	local isBeastRoom = roomName == BEAST_ROOM_NAME

	if effect.Variant == Vars.EFFECT_EDITH_TARGET then
		UpdateTargetAnimation(effect, player, params)
		HandleVestigeDrag(effect, player)
	end

	UpdateCameraFocus(player.Position, effect.Position, isBeastRoom)
	HandleDungeonTeleport(effect, player, isBeastRoom, roomName)
	SyncMarkedTarget(effect, player)
end
-- #endregion Target Management

-- #region Arrow Management
---@param charge number
---@param isRedirect boolean
---@param sprite Sprite
local function FullChargeArrow(charge, isRedirect, sprite)
	if charge < FULL_CHARGE then return end
	if isRedirect then return end
	if sprite:IsPlaying("Charged") then return end

	sprite:Play("Charged", true)
end

---@param effect EntityEffect
---@param player EntityPlayer
local function ArrowUpdate(effect, player)
	if effect.Variant ~= Vars.EFFECT_EDITH_B_TARGET then return end

	local playerData = data(player)
	local effectData = data(effect)

	local charge = TEdith.GetHopDashCharge(player, false, false)
	local sprite = effect:GetSprite()
	local isRedirect = playerData.IsRedirectioningMove

	if not isRedirect then
		local scaleX = ARROW_BASE_SCALE + ARROW_CHARGE_SCALE * (charge / FULL_CHARGE)
		effect.SpriteScale = Vector(scaleX, 1)
	else
		if not effectData.TriggeredIdle then
			sprite:Play("Pop")
		end

		if sprite:IsEventTriggered("TriggerIdle") then
			sprite:Play("Idle", true)
			effectData.TriggeredIdle = true
		end
	end

	FullChargeArrow(charge, isRedirect, sprite)
end
-- #endregion Arrow Management

-- #region Rendering
---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData EdithData
local function DrawTargetLine(effect, player, saveData)
	if not saveData.TargetLine then return end

	local effectSprite = effect:GetSprite()
	local frameLimit = Helpers.When(effectSprite:GetAnimation(), tables.FrameLimits, 0)
	local isObscure = effectSprite:GetFrame() >= frameLimit
	local lineColor = tables.TargetVisualParams[saveData.TargetDesign.Design].LineColor or effect.Color

	targetLineColor:SetColorize(lineColor.R, lineColor.G, lineColor.B, 1)
	drawLine(player.Position, effect.Position, targetLineColor, isObscure)
end

---@param effect EntityEffect
---@param saveData EdithData
---@param effectData table
local function ApplyEffectColor(effect, saveData, effectData)
	effectData.RGBState = ApplyRGBOrSolidColor(
		effect,
		RGBColors.Target,
		saveData.TargetColor,
		saveData.RGBMode,
		saveData.RGBSpeed,
		effectData.RGBState
	)

	local isDesign1 = saveData.TargetDesign.Idx == 1
	local activeColor = saveData.RGBMode and RGBColors.Target or effect.Color
	local newColor = (not isTDOV and isDesign1) and activeColor or Color.Default
	effect:SetColor(newColor, -1, 100, false, false)
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData EdithData
local function EdithTargetRender(effect, player, saveData)
	local effectData = data(effect)
	effectData.RGBState = effectData.RGBState or 0

	ApplyEffectColor(effect, saveData, effectData)
	DrawTargetLine(effect, player, saveData)
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData TEdithData
local function UpdateArrowRotation(effect, player, saveData)
	if saveData.ArrowDesign == 2 or Helpers.IsGrudgeChallenge() then return end
	effect:GetSprite().Rotation = TEdith.GetHopParryParams(player).HopDirection:GetAngleDegrees()
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData TEdithData
local function TaintedEdithArrowRender(effect, player, saveData)
	local effectData = data(effect)
	effectData.RGBState = effectData.RGBState or 0
	effect.Visible = effect.FrameCount > 1

	UpdateArrowRotation(effect, player, saveData)
	effectData.RGBState = ApplyRGBOrSolidColor(
		effect,
		RGBColors.Arrow,
		saveData.ArrowColor,
		saveData.RGBMode,
		saveData.RGBSpeed,
		effectData.RGBState
	)
end
-- #endregion Rendering

-- #region Sprite Design
local function GetTargetDesignSuffix()
	local design = Helpers.GetConfigData(ConfigData.EDITH).TargetDesign.Design
	local isColor = design == "Choose Color" or design == ""
	return isColor and "" or ("_" .. design)
end

local function GetArrowDesignSuffix()
	local arrowDesign = Helpers.GetConfigData(ConfigData.TEDITH).ArrowDesign
	return Helpers.IsGrudgeChallenge() and "_grudge" or tables.ArrowSuffix[arrowDesign]
end

local spriteParams = {
	[Vars.EFFECT_EDITH_TARGET] = { path = misc.TargetPath, suffix = GetTargetDesignSuffix },
	[Vars.EFFECT_EDITH_B_TARGET] = { path = misc.ArrowPath, suffix = GetArrowDesignSuffix },
}
-- #endregion Sprite Design

-- #region Callbacks
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	if npc.Variant ~= ROTGUT_VARIANT then return end

	local capsule = npc:GetCollisionCapsule()
	for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.EFFECT)) do
		if ent.Variant ~= Vars.EFFECT_EDITH_TARGET then goto continue end
		local player = ent.SpawnerEntity:ToPlayer()
		if not player then goto continue end
		ent.Velocity = (player.Position - npc.Position):Resized(ROTGUT_PUSH_SPEED)
		::continue::
	end
end, EntityType.ENTITY_ROTGUT)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
	if not IsAnyEdithTarget(effect) then return end
	Isaac.RunCallback(enums.Callbacks.TARGET_SPRITE_CHANGE, effect)
end)

AddTargetCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(effect, player)
	targetArrow.TargetDoorManager(effect, player, doorRadius[effect.Variant])
	FreeMovmentTargetManagement(effect, player)
	ArrowUpdate(effect, player)
end)

AddTargetCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, function(effect, player)
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end

	local isTarget = effect.Variant == Vars.EFFECT_EDITH_TARGET
	local dataType = isTarget and ConfigData.EDITH or ConfigData.TEDITH
	local confData = Helpers.GetConfigData(dataType) ---@cast confData EdithData|TEdithData
	local render = isTarget and EdithTargetRender or TaintedEdithArrowRender

	render(effect, player, confData)
end)

mod:AddCallback(enums.Callbacks.TARGET_SPRITE_CHANGE, function(_, effect)
	local params = spriteParams[effect.Variant]
	if not params then return end

	effect:GetSprite():ReplaceSpritesheet(0, params.path .. params.suffix() .. ".png", true)
end)
-- #endregion Callbacks