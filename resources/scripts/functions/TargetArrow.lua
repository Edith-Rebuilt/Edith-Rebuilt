---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local variants = enums.EffectVariant
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local targetArrow = {}

---@param player EntityPlayer
---@return table
local function getTargetData(player)
	local pData = EntitySaveStateManager.GetEntityData(mod, player)
	pData.EdithRebuiltTargetData = pData.EdithRebuiltTargetData or {}

	return pData.EdithRebuiltTargetData
end

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted boolean?
---@return EntityEffect
function targetArrow.GetEdithTarget(player, tainted)
	local Data = getTargetData(player)
	return tainted and Data.TaintedEdithTarget or Data.EdithTarget
end

---Checks if Edith's target is moving
---@param player EntityPlayer
---@return boolean
function targetArrow.IsEdithTargetMoving(player)
	local k_up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex)
    local k_down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex)
    local k_left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex)
    local k_right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)

    return (k_down or k_right or k_left or k_up) or false
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function targetArrow.GetEdithTargetDistance(player)
	local target = targetArrow.GetEdithTarget(player, false)
	if not target then return 0 end
	return target and player.Position:Distance(target.Position) or 0
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function targetArrow.SpawnEdithTarget(player, tainted)
	if mod.Modules.HELPERS.IsDogmaAppearCutscene() then return end
	if targetArrow.GetEdithTarget(player, tainted or false) then return end 

	local Data = getTargetData(player)
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
		target.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
		target.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
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

	local Data = getTargetData(player)
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

local function RestorePlayerAlpha(player)
    if player.Color.A >= 1 then return end
    mod.Modules.HELPERS.ChangeColor(player, nil, nil, nil, 1)
end

---@param origin Vector
---@param target Vector?
---@param maxDistanceSquared number
---@return boolean
local function IsTargetNearDoor(origin, target, maxDistanceSquared)
    return target ~= nil and origin:DistanceSquared(target) <= maxDistanceSquared*maxDistanceSquared
end

---@return {Sprite: Sprite, Mausoleum: boolean, Strange: boolean, StrangeOpened: boolean}?
local function GetDoorFlags(door)
    local sprite = door:GetSprite()
    local layer = sprite:GetLayer(0)

    if not layer then return nil end

    local path = layer:GetSpritesheetPath()
    local mausoleum = path:find("mausoleum", 1, true) ~= nil or path:find("gehenna", 1, true) ~= nil
    local strange = path:find("mausoleum_alt", 1, true) ~= nil

    return {
        Sprite = sprite,
        Mausoleum = mausoleum,
        Strange = strange,
        StrangeOpened = strange and sprite:WasEventTriggered("FX")
    }
end

local function OpenMausoleumDoor(door, sprite, player)
    if not sprite:IsPlaying("KeyOpen") then
        sprite:Play("KeyOpen")
    end

    if sprite:IsFinished("KeyOpen") then
        door:TryUnlock(player, true)
    end
end

local function OpenStrangeDoor(door, player)
    if not (player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) or player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE)) then return end
    door:TryUnlock(player)
end

local function TryOpenDoor(door, flags, player, roomClear)
    if not roomClear then return end

    if flags.Strange then
        OpenStrangeDoor(door, player)
        return
    end

    if flags.Mausoleum then
        OpenMausoleumDoor(door, flags.Sprite, player)
        return
    end

    door:TryUnlock(player)
end

local function MovePlayerThroughDoor(player, doorPos, isTainted)
    player.Position = doorPos
    targetArrow.RemoveEdithTarget(player, isTainted)
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

---@param effect EntityEffect
---@param player EntityPlayer
---@param triggerDistance number
function targetArrow.TargetDoorManager(effect, player, triggerDistance)
    local room = game:GetRoom()
    local roomClear = room:IsClear()
    local roomName = level:GetCurrentRoomDesc().Data.Name
    local isTainted = mod.Modules.PLAYER.IsEdith(player, true)
    local mirrorRoom = roomName == "Mirror Room" and player:HasInstantDeathCurse()
    local effectPos = effect.Position
    local playerNearDoor = false

    FallFromGraceManager(effect, mirrorRoom, triggerDistance)

    for slot = 0, DoorSlot.DOWN1 do
        local door = room:GetDoor(slot)

        if not door then goto continue end

        local flags = GetDoorFlags(door)
        if not flags then goto continue end

        local doorPos = room:GetDoorSlotPosition(slot)

        if not IsTargetNearDoor(effectPos, doorPos, triggerDistance) then goto continue end

        print("trigger change")

        playerNearDoor = true

        local spritePath = flags.Sprite:GetLayer(0):GetSpritesheetPath()

        if door:IsOpen() or mirrorRoom or flags.StrangeOpened  then
            MovePlayerThroughDoor(player, doorPos, isTainted)
        else
            TryOpenDoor(door, flags, player, roomClear)
        end
        ::continue::
    end

    if not playerNearDoor then
        RestorePlayerAlpha(player)
    end
end
return targetArrow