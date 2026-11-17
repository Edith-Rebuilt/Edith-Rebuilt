---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local variants = enums.EffectVariant

local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local room = utils.Room

local saveManager = mod.SaveManager

local targetArrow = {}

---@param player EntityPlayer
---@return table
function targetArrow.getTargetData(player)
	local pData = EntitySaveStateManager.GetEntityData(mod, player)
	pData.EdithRebuiltTargetData = pData.EdithRebuiltTargetData or {}

	return pData.EdithRebuiltTargetData
end

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted boolean?
---@return EntityEffect
function targetArrow.GetEdithTarget(player, tainted)
	local Data = targetArrow.getTargetData(player)
	return tainted and Data.TaintedEdithTarget or Data.EdithTarget
end

---Checks if Edith's target is moving
---@param player EntityPlayer
---@return boolean
function targetArrow.IsEdithTargetMoving(player)
    local idx = player.ControllerIndex
    local inputs = {
        up = Input.IsActionPressed(ButtonAction.ACTION_UP, idx),
        down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, idx),
        left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, idx),
        right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, idx),
    }

    return inputs.up or inputs.down or inputs.left or inputs.right
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function targetArrow.GetEdithTargetDistance(player)
	local target = targetArrow.GetEdithTarget(player, false)
	if not target then return 0 end
	return target and player.Position:Distance(target.Position) or 0
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function targetArrow.GetEdithTargetDistanceSquared(player)
	local target = targetArrow.GetEdithTarget(player, false)
	if not target then return 0 end
	return target and player.Position:DistanceSquared(target.Position) or 0
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function targetArrow.SpawnEdithTarget(player, tainted)
	if mod.Modules.HELPERS.IsDogmaAppearCutscene() then return end
	if targetArrow.GetEdithTarget(player, tainted or false) then return end 

	local Data = targetArrow.getTargetData(player)
	local TargetVariant = tainted and variants.EFFECT_EDITH_B_TARGET or variants.EFFECT_EDITH_TARGET
	local target = Isaac.Spawn(	
		EntityType.ENTITY_EFFECT,
		TargetVariant,
		0,
		player.Position,
		Vector.Zero,
		player
	):ToEffect() ---@cast target EntityEffect
	target.DepthOffset = -100
	target.SortingLayer = SortingLayer.SORTING_NORMAL

	if tainted then
		Data.TaintedEdithTarget = target
	else
        target.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		Data.EdithTarget = target
	end
end

---Function to remove Edith's target
---@param player EntityPlayer
---@param tainted? boolean
function targetArrow.RemoveEdithTarget(player, tainted)
	local target = targetArrow.GetEdithTarget(player, tainted)

	if not target then return end
	target:Remove()

	local Data = targetArrow.getTargetData(player)
	if tainted then
		Data.TaintedEdithTarget = nil
	else
		Data.EdithTarget = nil
	end
end

---Returns a normalized vector that represents direction regarding Edith and her Target, set `tainted` to true to check for Tainted Edith's arrow instead
---@param player EntityPlayer
---@param tainted boolean?
---@return Vector
function targetArrow.GetEdithTargetDirection(player, tainted)
	local target = targetArrow.GetEdithTarget(player, tainted or false)
	if not target then return Vector.Zero end

	return (target.Position - player.Position):Normalized()
end

---@param origin Vector
---@param target Vector?
---@param maxDistanceSquared number
---@return boolean
local function IsTargetNearDoor(origin, target, maxDistanceSquared)
    return target ~= nil and origin:DistanceSquared(target) <= maxDistanceSquared*maxDistanceSquared
end

---@class DoorFlags 
---@field Ascent boolean
---@field Mausoleum boolean
---@field Mirror boolean
---@field Mineshaft boolean

local RepentanceStages = {
    [StageType.STAGETYPE_REPENTANCE] = true,
    [StageType.STAGETYPE_REPENTANCE_B] = true
}

---@param door GridEntityDoor
---@return DoorFlags
local function GetDoorFlags(door)
    local targetIndex = door.TargetRoomIndex
    local isSecretExit = targetIndex == GridRooms.ROOM_SECRET_EXIT_IDX
    local chapter = mod.Modules.HELPERS.GetCurrentChapter()

    local isRepStage = RepentanceStages[level:GetStageType()]

    local stage = level:GetStage()
    local isAltChapter2 = chapter == 2 and isRepStage
    local isNonAltStageFive = level:GetStage() == LevelStage.STAGE3_1 and not isRepStage

    return {
        Ascent = isSecretExit and (stage == LevelStage.STAGE3_2 and not isRepStage),
        Mausoleum = isSecretExit and (isAltChapter2 or isNonAltStageFive),
        Mirror = targetIndex == GridRooms.ROOM_MIRROR_IDX,
        Mineshaft = targetIndex == GridRooms.ROOM_MINESHAFT_IDX,
    }
end

---@param door GridEntityDoor
---@param flags DoorFlags
---@param player EntityPlayer
---@param roomClear boolean
local function TryOpenDoor(door, flags, player, roomClear)
    if not roomClear then return end
    if door:IsOpen() then return end

    door:TryUnlock(player, flags.Mausoleum)
end

---@param effect EntityEffect
---@param mirrorRoom boolean
---@param triggerDistance number
local function FallFromGraceManager(effect, mirrorRoom, triggerDistance)
    if not FFGRACE then return end
    if not FFGRACE.STAGE.Boiler:IsStage() then return end
    if not mirrorRoom then return end

    local mirrorDoor = Isaac.FindByType(EntityType.ENTITY_EFFECT, 12547)[1]

    if not mirrorDoor then return end
    if not IsTargetNearDoor(effect.Position, mirrorDoor.Position, triggerDistance) then return end

    local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end

    FFGRACE:MirrorDoorEnter(player)
end

local function GetLastNormalRoomIndex()
    local LastRoomDesc = level:GetLastRoomDesc()
    local LastRoomIndex = LastRoomDesc.GridIndex
    local runSave = saveManager.GetRunSave()

    if LastRoomIndex > 0 and LastRoomDesc:GetDimension() == Dimension.NORMAL then
        runSave.lastNormalRoom = LastRoomIndex
    end

    return runSave.lastNormalRoom
end

---@param player EntityPlayer
---@param door GridEntityDoor
---@param flags DoorFlags
---@param lostCurse boolean
local function DoorTransitionManager(player, door, flags, lostCurse)
    local roomTarget = door.TargetRoomIndex
    local targetDimension = level:GetRoomByIdx(roomTarget):GetDimension()
    local transition = RoomTransitionAnim.WALK

    if flags.Mirror and lostCurse then
        roomTarget = level:GetCurrentRoomIndex()
        transition = RoomTransitionAnim.FADE_MIRROR
    end

    local lastNormalRoomIndex = GetLastNormalRoomIndex()

    if flags.Mineshaft then
        roomTarget = (
            targetDimension == Dimension.MINESHAFT and 162 or lastNormalRoomIndex
        )
    end

    level.LeaveDoor = door.Slot

    game:StartRoomTransition(roomTarget, door.Direction, transition, player, targetDimension)
end

local CrawlspaceTransitions = {
    [119] = { room = -15, direction = Direction.RIGHT, anim = RoomTransitionAnim.WALK },
    [74] = { room = -6, direction = Direction.RIGHT, anim = RoomTransitionAnim.WALK },
    [2] = { direction = Direction.NO_DIRECTION, anim = RoomTransitionAnim.PIXELATION },
}

local invalidTransitionGrids = {
    [GridEntityType.GRID_WALL] = true,
    [GridEntityType.GRID_GRAVITY] = true,
    [GridEntityType.GRID_DOOR] = true,
}

---@param effect EntityEffect
local function CrawlspacesManager(effect)
    if room:GetType() ~= RoomType.ROOM_DUNGEON then return end

    local targetGrid = room:GetGridEntityFromPos(effect.Position)
    if not targetGrid then return end

    local gridIndex = targetGrid:GetGridIndex()
    local transition = CrawlspaceTransitions[gridIndex]

    if not transition then return end
    if invalidTransitionGrids[targetGrid:GetType()] then return end
    if targetGrid:ToRock() then return end

    local roomTarget = transition.room or GetLastNormalRoomIndex()

    game:StartRoomTransition(roomTarget, transition.direction, transition.anim, player, level:GetDimension())
end

---@param door GridEntityDoor
---@param flags DoorFlags
---@return true
local function CanTriggerRoomTransition(door, flags)
    local openingAnim = door.OpenLockedAnimation
    local isOpening = (
        (flags.Mausoleum or flags.Ascent) and
        openingAnim ~= nil and 
        not door:GetSprite():IsFinished(openingAnim)
    )

    return (door:IsOpen() and not isOpening) or flags.Mirror
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param triggerDistance number
function targetArrow.TargetDoorManager(effect, player, triggerDistance)
    local roomName = level:GetCurrentRoomDesc().Data.Name
    local lostCurse = player:HasInstantDeathCurse()
    local mirrorRoom = roomName == "Mirror Room" and lostCurse
    local effectPos = effect.Position

    FallFromGraceManager(effect, mirrorRoom, triggerDistance)
    CrawlspacesManager(effect)

    for slot, _ in pairs(level:GetRoomByIdx(level:GetCurrentRoomIndex()).Doors) do
        local door = room:GetDoor(slot)

        if not door then goto continue end
        if not IsTargetNearDoor(effectPos, door.Position, triggerDistance) then goto continue end

        local flags = GetDoorFlags(door)

        if CanTriggerRoomTransition(door, flags) then
            DoorTransitionManager(player, door, flags, lostCurse)
        else
            TryOpenDoor(door, flags, player, room:IsClear())
        end
        ::continue::
    end
end

return targetArrow