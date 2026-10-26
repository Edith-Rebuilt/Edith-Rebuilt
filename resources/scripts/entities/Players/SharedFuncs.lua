-- #region Imports
local mod = EdithRebuilt
local enums = mod.Enums

local tables = enums.Tables
local utils = enums.Utils
local challenges = enums.Challenge

local pool = utils.ItemPool
local room = utils.Room

local modules = mod.Modules
local Player = modules.PLAYER
local Helpers = modules.HELPERS
local TargetArrow = modules.TARGET_ARROW
local BitMask = modules.BIT_MASK

local costumes = enums.NullItemID
-- #endregion Imports

-- #region Constants
local TEAR_MASS_MULTIPLIER = 10
local MARKED_TEAR_SPEED_MULTIPLIER = 10
local SPRITE_LAYER_COUNT = 14
local VERSUS_SCREEN_PORTRAIT_LAYER = 12
local NIGHTMARE_PORTRAIT_LAYER = 6

local VESTIGE_PORTRAIT_PATH = "gfx/ui/stage/EdithPortraitVestige.png"
local GRUDGE_PORTRAIT_PATH = "gfx/ui/stage/TEdithPortraitGrudge.png"

local ModCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
    [costumes.TR_EDITH] = true,
}

local WhitelistCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
    [costumes.TR_EDITH] = true,
    [CollectibleType.COLLECTIBLE_HOLY_MANTLE] = true,
    [CollectibleType.COLLECTIBLE_FATE] = true,
    [CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS] = true,
    [CollectibleType.COLLECTIBLE_GAMEKID] = true,
    [CollectibleType.COLLECTIBLE_EYE_OF_THE_OCCULT] = true,
    [CollectibleType.COLLECTIBLE_NUMBER_ONE] = true,
}

local ReloadCostumeItems = {
    [CollectibleType.COLLECTIBLE_D4] = true,
    [CollectibleType.COLLECTIBLE_D100] = true,
}

local RemovedCollectibles = {
    CollectibleType.COLLECTIBLE_NIGHT_LIGHT,
    CollectibleType.COLLECTIBLE_MONTEZUMAS_REVENGE,
    CollectibleType.COLLECTIBLE_SUPLEX,
}

local InitParams = {
    [enums.PlayerType.PLAYER_EDITH] = {
        ANM2 = "gfx/EdithAnim.anm2",
        Costume = costumes.EDITH,
    },
    [enums.PlayerType.PLAYER_EDITH_B] = {
        ANM2 = "gfx/EdithTaintedAnim.anm2",
        Costume = costumes.T_EDITH,
    },
}
-- #endregion Constants

-- #region Helpers
local function IsStatue(player)
    return Player.IsAnyEdith(player) or Player.IsEffigyStatue(player)
end

local function AddPlayerCallback(callback, filter, fn)
    mod:AddCallback(callback, function(_, player, ...)
        if not filter(player) then return end
        return fn(player, ...)
    end)
end

local function AddTearCallback(callback, fn)
    mod:AddCallback(callback, function(_, tear)
        local player = Helpers.GetPlayerFromTear(tear)

        if not player then return end
        if not Player.IsAnyEdith(player) then return end

        return fn(tear, player)
    end)
end

local function GetPortraitPath()
    local challenge = Isaac.GetChallenge()

    if challenge == challenges.CHALLENGE_VESTIGE then return VESTIGE_PORTRAIT_PATH end
    if challenge == challenges.CHALLENGE_GRUDGE then return GRUDGE_PORTRAIT_PATH end
end

local function ReplacePortrait(sprite, layer)
    local path = GetPortraitPath()

    if not path then return end

    sprite:ReplaceSpritesheet(layer, path, true)
end

local function RemoveEdithEffects(player)
    local effects = player:GetEffects()

    if effects:HasNullEffect(costumes.EDITH) then
        effects:RemoveNullEffect(costumes.EDITH, -1)
    elseif effects:HasNullEffect(costumes.T_EDITH) then
        effects:RemoveNullEffect(costumes.T_EDITH)
    end
end

local function RestoreDefaultSprite(player)
    local playerConfig = EntityConfig.GetPlayer(player:GetPlayerType())
    local entityConfig = EntityConfig.GetEntity(player.Type, player.Variant, player.SubType)

    if not playerConfig or not entityConfig then return end

    local sprite = player:GetSprite()

    sprite:Load(entityConfig:GetAnm2Path(), true)

    for layer = 0, SPRITE_LAYER_COUNT do
        sprite:ReplaceSpritesheet(layer, playerConfig:GetSkinPath(), true)
    end
end
-- #endregion Helpers

-- #region Input
mod:AddPriorityCallback(ModCallbacks.MC_INPUT_ACTION, CallbackPriority.IMPORTANT, function(_, entity, input, action)
    if not entity then return end

    local player = entity:ToPlayer()

    if not player then return end
    if not Player.IsAnyEdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)
-- #endregion Input

-- #region Costumes
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, function(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end
    if Helpers.When(itemconfig.Costume.ID, WhitelistCostumes, false) then return end

    return true
end)

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_REMOVE_COSTUME, function(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end
    if not Helpers.When(itemconfig.Costume.ID, ModCostumes, false) then return end

    return true
end)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, id, _, player)
    if not Player.IsAnyEdith(player) then return end
    if not ReloadCostumeItems[id] then return end

    Player.SetCustomSprite(player, Player.IsEdith(player, true))
end)
-- #endregion Costumes

-- #region Player
AddPlayerCallback(ModCallbacks.MC_POST_PLAYER_INIT, Player.IsAnyEdith, function(player)
    local params = InitParams[player:GetPlayerType()]

    if not params then return end

    Player.SetNewANM2(player, params.ANM2)
    player:AddNullItemEffect(params.Costume, true)
end)

AddPlayerCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, IsStatue, function(player)
    Player.WaterCurrentManager(player)

    if Player.IsAnyEdith(player) then
        Player.ManageEdithWeapons(player)
    end
end)

AddPlayerCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, IsStatue, function(player)
    player:ClearEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
end)

AddPlayerCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, IsStatue, function(_, _, grid)
    if not grid then return end
    if grid:GetType() ~= GridEntityType.GRID_ROCK_SPIKED then return end

    return true
end)

AddPlayerCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, IsStatue, function(_, _, flags)
    local roomType = room:GetType()
    local isAcid = BitMask.HasBitFlags(flags, DamageFlag.DAMAGE_ACID --[[@as BitSet128]])
    local isSpike = BitMask.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES --[[@as BitSet128]])
    local isSafeRoom = roomType == RoomType.ROOM_SACRIFICE or roomType == RoomType.ROOM_DEVIL

    if isAcid or (isSpike and not isSafeRoom) then
        return false
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, function(_, player)
    if Player.IsAnyEdith(player) then return end

    RemoveEdithEffects(player)
    RestoreDefaultSprite(player)
end)
-- #endregion Player

-- #region Tears
AddTearCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(tear)
    if tear.FrameCount ~= 1 then return end

    tear.Mass = tear.Mass * TEAR_MASS_MULTIPLIER
end)

AddTearCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(tear, player)
    local isTainted = Player.IsEdith(player, true)

    Helpers.ForceSaltTear(tear, isTainted)

    if isTainted then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end

    local target = TargetArrow.GetEdithTarget(player)

    if not target then return end

    local direction = (target.Position - tear.Position):Normalized()

    tear.Velocity = direction:Resized(player.ShotSpeed * MARKED_TEAR_SPEED_MULTIPLIER)
end)
-- #endregion Tears

-- #region Game
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    if not Player.AnyoneIsEdith() then return end

    for _, collectible in ipairs(RemovedCollectibles) do
        pool:RemoveCollectible(collectible)
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if room:GetType() ~= RoomType.ROOM_DUNGEON then return end

    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if Player.IsAnyEdith(player) then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_BIBLE, UseFlag.USE_NOANIM)
        end
    end
end)
-- #endregion Game

-- #region Portraits
mod:AddCallback(ModCallbacks.MC_POST_BOSS_INTRO_SHOW, function()
    ReplacePortrait(RoomTransition:GetVersusScreenSprite(), VERSUS_SCREEN_PORTRAIT_LAYER)
end)

mod:AddCallback(ModCallbacks.MC_POST_NIGHTMARE_SCENE_SHOW, function()
    ReplacePortrait(NightmareScene.GetBackgroundSprite(), NIGHTMARE_PORTRAIT_LAYER)
end)
-- #endregion Portraits