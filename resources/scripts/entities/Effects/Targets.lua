local mod = EdithRebuilt
local enums = mod.Enums
local Vars = enums.EffectVariant
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local room = utils.Room
local misc = enums.Misc
local tables = enums.Tables
local ConfigData = enums.ConfigDataTypes
local Hsx = mod.Hsx
local defColor = Color.Default
local RGBColors = { Target = Color(1, 0, 0), Arrow = Color(1, 0, 0) }
local modules = mod.Modules
local Edith = modules.EDITH
local TEdith = modules.TEDITH
local Helpers = modules.HELPERS
local targetArrow = modules.TARGET_ARROW
local Jump = modules.JUMP
local data = mod.DataHolder.GetEntityData

local teleportPoints = {
	Vector(110, 135),
	Vector(595, 385),
	Vector(595, 272),
}

---@param effect EntityEffect
local function IsAnyEdithTarget(effect)
    local var = effect.Variant
    return var == Vars.EFFECT_EDITH_TARGET or var == Vars.EFFECT_EDITH_B_TARGET
end

local function interpolateVector2D(vectorA, vectorB, t)
	local minT = (1 - t)
    return Vector(minT * vectorA.X + t * vectorB.X, minT * vectorA.Y + t * vectorB.Y)
end

---@param color Color
---@param step number
---@param value number
---@return number
local function RGBFunction(color, step, value)
	value = value + step

	if value > 1 then value = 0 end

	color.R, color.G, color.B = Hsx.rgb2hsv(color.R, color.G, color.B)
	color.R = color.R + step
	color.R, color.G, color.B = Hsx.hsv2rgb(color.R, color.G, color.B)

	return value
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
        rgbState = RGBFunction(rgbColor, rgbSpeed, rgbState)
        Helpers.ChangeColor(effect, rgbColor.R, rgbColor.G, rgbColor.B)
    else
        Helpers.ChangeColor(effect, solidColor.Red, solidColor.Green, solidColor.Blue)
    end
    return rgbState
end

local targetSprite = Sprite("gfx/edith rebuilt target.anm2", true)

---Draws a line between from `from` position to `to` position
---@param from Vector
---@param to Vector
---@param color Color
---@param isObscure? boolean
local function drawLine(from, to, color, isObscure)
	local diffVector = to - from
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / 16) - 1
	local direction = Vector.FromAngle(angle)

	targetSprite:SetFrame("Line", isObscure and 1 or 0)
	targetSprite.Color = color
	targetSprite.Rotation = angle

	for i = 0, sectionCount do
		local currentPos = from + direction * (i * 16)
		targetSprite:Render(Isaac.WorldToScreen(currentPos))
	end
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param params table
local function UpdateTargetAnimation(effect, player, params)
	local isActive = Helpers.IsKeyStompPressed(player) or (Jump.IsJumping(player) and params.Cooldown == 0)
	local anim = "Idle"
	local isVestige = Helpers.IsVestigeChallenge()

	if isVestige then
		anim = isActive and Jump.IsJumping(player) and "Blink" or "Idle"
	else
		anim = isActive and "Blink" or "Idle"
	end

	effect:GetSprite():Play(anim)
end

---@param playerPos Vector
---@param effectPos Vector
---@param isBeastRoom boolean
local function UpdateCameraFocus(playerPos, effectPos, isBeastRoom)
	if isBeastRoom then return end
	room:GetCamera():SetFocusPosition(interpolateVector2D(playerPos, effectPos, 0.6))
end

---@param effect EntityEffect
---@param player EntityPlayer
local function HandleVestigeDrag(effect, player)
	if not (Helpers.IsVestigeChallenge() and Jump.IsJumping(player)) then return end
	effect.Velocity = effect.Velocity * 0.6
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param isBeastRoom boolean
---@param RoomName string
local function HandleDungeonTeleport(effect, player, isBeastRoom, RoomName)
	if room:GetType() ~= RoomType.ROOM_DUNGEON then return end

	local effectPos = effect.Position
	for _, v in pairs(teleportPoints) do
		if (effectPos - v):Length() > 20 then goto continue end
		if isBeastRoom then goto continue end
		if RoomName == "Rotgut Maggot" and (v.X ~= 595 and v.Y ~= 385) then goto continue end
		player.Position = effectPos + effect.Velocity:Resized(25)
		::continue::
	end
end

---@param option integer
---@return {Suffix: string, LineColor: {R: number, G: number, B: number}?}
local function GetTargetVisualParams(option)
	return tables.TargetVisualParams[option]
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
local function EdithTargetManagement(effect, player)
	if effect.Variant ~= Vars.EFFECT_EDITH_TARGET then return end

	local params = Edith.GetJumpStompParams(player)
	local RoomName = level:GetCurrentRoomDesc().Data.Name
	local isBeastRoom = RoomName == "Beast Room"

	UpdateTargetAnimation(effect, player, params)
	UpdateCameraFocus(player.Position, effect.Position, isBeastRoom)
	HandleVestigeDrag(effect, player)
	HandleDungeonTeleport(effect, player, isBeastRoom, RoomName)
	SyncMarkedTarget(effect, player)
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
	if npc.Variant ~= 1 then return end
	local capsule = npc:GetCollisionCapsule()

	for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.EFFECT)) do
		if ent.Variant ~= Vars.EFFECT_EDITH_TARGET then goto continue end		
		local player = ent.SpawnerEntity:ToPlayer()
		if not player then goto continue end
		ent.Velocity = (player.Position - npc.Position):Resized(20)
		::continue::
	end
end, EntityType.ENTITY_ROTGUT)

local currentDate = os.date("*t")
local isTDOV = (currentDate.month == 3 and currentDate.day == 31)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function (_, effect)
	if not IsAnyEdithTarget(effect) then return end
	Isaac.RunCallback(mod.Enums.Callbacks.TARGET_SPRITE_CHANGE, effect)
end)

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData EdithData
local function DrawTargetLine(effect, player, saveData)
    if not saveData.TargetLine then return end

    local effectSprite = effect:GetSprite()
    local color = effect.Color
    local frameLimit = Helpers.When(effectSprite:GetAnimation(), tables.FrameLimits, 0)
    local isObscure = effectSprite:GetFrame() >= frameLimit
    local lineColor = GetTargetVisualParams(saveData.TargetDesign).LineColor or color

    local targetlineColor = misc.TargetLineColor
    targetlineColor:SetColorize(lineColor.R, lineColor.G, lineColor.B, 1)
    drawLine(player.Position, effect.Position, targetlineColor, isObscure)
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

    local isDesign1 = saveData.TargetDesign == 1
    local activeColor = saveData.RGBMode and RGBColors.Target or effect.Color
    local newColor = (not isTDOV and isDesign1) and activeColor or defColor
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
local function UpdateArrowRotation(effect, player, saveData)
    if not (saveData.ArrowDesign ~= 2 and not Helpers.IsGrudgeChallenge()) then return end
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

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	if not IsAnyEdithTarget(effect) then return end
	local player = effect.SpawnerEntity:ToPlayer()
	local radius = effect.Variant == Vars.EFFECT_EDITH_TARGET and 28 or 20

    if not player then return end
	targetArrow.TargetDoorManager(effect, player, radius)
    EdithTargetManagement(effect, player)
end)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, function(_, effect)
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
	if not IsAnyEdithTarget(effect) then return end

	local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end

	local isTarget = effect.Variant == Vars.EFFECT_EDITH_TARGET
	local dataType = isTarget and enums.ConfigDataTypes.EDITH or enums.ConfigDataTypes.TEDITH
	local confData = Helpers.GetConfigData(dataType) ---@cast confData EdithData|TEdithData	
	local func = isTarget and EdithTargetRender or TaintedEdithArrowRender

	func(effect, player, confData)
end)

local function GetTargetDesignSuffix()
	local MenuSprite = Helpers.GetConfigData(ConfigData.EDITH).TargetDesign
	return GetTargetVisualParams(MenuSprite).Suffix
end

local function GetArrowDesignSuffix()
	local MenuSprite = Helpers.GetConfigData(ConfigData.TEDITH).ArrowDesign
	local design = Helpers.IsGrudgeChallenge() and "_grudge" or tables.ArrowSuffix[MenuSprite]
	return design
end

local spriteParams = {
	[Vars.EFFECT_EDITH_TARGET] = {
		path = misc.TargetPath,
		suffix = GetTargetDesignSuffix,
	} ,
	[Vars.EFFECT_EDITH_B_TARGET] = {
		path = misc.ArrowPath,
		suffix = GetArrowDesignSuffix,
	},
}

---@param effect EntityEffect
mod:AddCallback(enums.Callbacks.TARGET_SPRITE_CHANGE, function(_, effect)
	local sprite = spriteParams[effect.Variant]
	local path = sprite.path
	local suffix = sprite.suffix()
	effect:GetSprite():ReplaceSpritesheet(0, path .. suffix .. ".png", true)
end)