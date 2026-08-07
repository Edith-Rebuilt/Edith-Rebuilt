local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local utils = enums.Utils
local game = utils.Game
local pool = utils.ItemPool
local room = utils.Room
local modules = mod.Modules
local Player = modules.PLAYER
local Helpers = modules.HELPERS
local TargetArrow = modules.TARGET_ARROW
local BitMask = modules.BIT_MASK
local costumes = enums.NullItemID

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddPriorityCallback(ModCallbacks.MC_INPUT_ACTION, CallbackPriority.IMPORTANT, function(_, entity, input, action)
    if not entity then return end

    local player = entity:ToPlayer()

    if not player then return end
    if not Player.IsAnyEdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)

local ModCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
}

local whiteListCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
    [CollectibleType.COLLECTIBLE_HOLY_MANTLE] = true,
    [CollectibleType.COLLECTIBLE_FATE] = true,
    [CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS] = true,
    [CollectibleType.COLLECTIBLE_GAMEKID] = true,
    [CollectibleType.COLLECTIBLE_EYE_OF_THE_OCCULT] = true,
    [CollectibleType.COLLECTIBLE_NUMBER_ONE] = true,
}

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, function(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end    
    if Helpers.When(itemconfig.Costume.ID, whiteListCostumes, false) then return end
    return true
end)

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_REMOVE_COSTUME, function(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end
    if not Helpers.When(itemconfig.Costume.ID, ModCostumes, false) then return end
    return true
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not Player.IsAnyEdith(player) then return end
	Player.WaterCurrentManager(player)
    Player.ManageEdithWeapons(player)
end)

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
	if not Player.IsAnyEdith(player) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags)
    if not Player.IsAnyEdith(player) then return end

    local roomType = room:GetType()
    local isAcid = BitMask.HasBitFlags(flags, DamageFlag.DAMAGE_ACID --[[@as BitSet128]])
    local isSpike = BitMask.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES --[[@as BitSet128]])
    local isSafeRoom = roomType == RoomType.ROOM_SACRIFICE or roomType == RoomType.ROOM_DEVIL
    local shouldBlock = isAcid or (isSpike and not isSafeRoom)

    if shouldBlock then
        return false
    end
end)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
    if not Player.IsAnyEdith(player) then return end

    local isTainted = Player.IsEdith(player, true)
    local target = TargetArrow.GetEdithTarget(player)

	Helpers.ForceSaltTear(tear, isTainted)

    if isTainted then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	if not target then return end

    tear.Velocity = -((tear.Position - target.Position):Normalized()):Resized(player.ShotSpeed * 10)
end)

local ReloadCostumeItem = {
    [CollectibleType.COLLECTIBLE_D4] = true,
    [CollectibleType.COLLECTIBLE_D100] = true,
}

---@param ID CollectibleType
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, ID, _, player)
    if not Player.IsAnyEdith(player) then return end
    if not ReloadCostumeItem[ID] then return end

    Player.SetCustomSprite(player, Player.IsEdith(player, true))
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
	if not Player.IsAnyEdith(player) then return end

    local IsEdith = Player.IsEdith(player, false)
    local params = {
        ANM2 = IsEdith and "gfx/EdithAnim.anm2" or "gfx/EdithTaintedAnim.anm2",
        costume = IsEdith and costumes.EDITH or costumes.T_EDITH,
    }

	Player.SetNewANM2(player, params.ANM2)
	player:AddNullItemEffect(params.costume, true)
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    if not Player.AnyoneIsEdith() then return end

    pool:RemoveCollectible(CollectibleType.COLLECTIBLE_NIGHT_LIGHT)
    pool:RemoveCollectible(CollectibleType.COLLECTIBLE_MONTEZUMAS_REVENGE)
    pool:RemoveCollectible(CollectibleType.COLLECTIBLE_SUPLEX)
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function(_, player, _, grid)
	if not Player.IsAnyEdith(player) then return end
    if not grid then return end
    if grid:GetType() ~= GridEntityType.GRID_ROCK_SPIKED then return end
	return true
end)

local VestigePath = "gfx/ui/stage/EdithPortraitVestige.png"
local GrudgePath = "gfx/ui/stage/TEdithPortraitGrudge.png"

---@param sprite Sprite
---@param layer integer
local function replacePortrait(sprite, layer)
    local challenge = Isaac.GetChallenge()
    local isVestige = challenge == enums.Challenge.CHALLENGE_VESTIGE
    local isGrudge = challenge == enums.Challenge.CHALLENGE_GRUDGE
    local path = isVestige and VestigePath or isGrudge and GrudgePath

    if not path then return end

    sprite:ReplaceSpritesheet(layer, path, true)
end

mod:AddCallback(ModCallbacks.MC_POST_BOSS_INTRO_SHOW, function()
    replacePortrait(RoomTransition:GetVersusScreenSprite(), 12)
end)

mod:AddCallback(ModCallbacks.MC_POST_NIGHTMARE_SCENE_SHOW, function()
    replacePortrait(NightmareScene.GetBackgroundSprite(), 6)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if room:GetType() ~= RoomType.ROOM_DUNGEON then return end

    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if not Player.IsAnyEdith(player) then goto continue end
        player:UseActiveItem(CollectibleType.COLLECTIBLE_BIBLE, UseFlag.USE_NOANIM)
        ::continue::
    end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, function(_, player)
    if not Player.IsAnyEdith(player) then return end

    player:ClearEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
end)

-- ---@param player EntityPlayer
-- mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function (_, _, _, _, _, _, player)
--     Player.SetHoodSprite(player, "gfx/characters/costumes/characterTaintedEdithHoodEOTO.png")
-- end, CollectibleType.COLLECTIBLE_EYE_OF_THE_OCCULT)