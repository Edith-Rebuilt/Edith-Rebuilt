local mod = EdithRebuilt
local enums = mod.Enums

local tables = enums.Tables
local utils = enums.Utils
local playerType = enums.PlayerType

local pool = utils.ItemPool

local modules = mod.Modules
local Player = modules.PLAYER
local Helpers = modules.HELPERS
local TargetArrow = modules.TARGET_ARROW

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

local function IsStatue(player)
    return Player.IsAnyEdith(player) or Player.IsEffigyStatue(player)
end

local ModCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
    [costumes.TR_EDITH] = true,
}

local whiteListCostumes = {
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
    if not IsStatue(player) then return end

	Player.WaterCurrentManager(player)

    if Player.IsAnyEdith(player) then
        Player.ManageEdithWeapons(player)
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
	if not Player.IsAnyEdith(player) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end)

local tearParams = {
    [playerType.PLAYER_EDITH] = nil,
    [playerType.PLAYER_EDITH_B] = {
        brightness = 0.3,
    }, --[[@as SaltTearParams]]
    [playerType.PLAYER_EDITH_C] = {
        tint = { 1, 207 / 255, 66 / 255 },
        offset = { 0.7, 87 / 255, 17 / 255 },
    }  --[[@as SaltTearParams]]
}

local function EdithMarkedInteraction(player, tear)
    if Player.IsEdith(player, true) then return end
    local target = TargetArrow.GetEdithTarget(player)
    if not target then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end

    tear.Velocity = -((tear.Position - target.Position):Normalized()):Resized(player.ShotSpeed * 10)
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
    if not Player.IsAnyEdith(player) then return end

    Helpers.ForceSaltTear(tear, tearParams[player:GetPlayerType()])
    EdithMarkedInteraction(player, tear)
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

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
	if not Player.IsAnyEdith(player) then return end

    local params = InitParams[player:GetPlayerType()]

    if not params then return end

	Player.SetNewANM2(player, params.ANM2)
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
	if not IsStatue(player) then return end
    if not grid then return end
    if grid:GetType() ~= GridEntityType.GRID_ROCK_SPIKED then return end
	return true
end)

local VestigePath = "gfx/ui/stage/EdithPortraitVestige.png"
local GrudgePath = "gfx/ui/stage/TEdithPortraitGrudge.png"

---@param sprite Sprite
---@param layer integer
local function replacePortrait(sprite, layer)
    local isVestige = Helpers.IsVestigeChallenge()
    local isGrudge = Helpers.IsGrudgeChallenge()
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

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, function(_, player)
    if not IsStatue(player) then return end

    player:ClearEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
end)

local CabraRNG = RNG(math.max(Random(), 1), 35)
local Roll = CabraRNG:RandomInt(1, 100000)

local Cabras = {
    [playerType.PLAYER_EDITH] = Renderer.LoadImage("gfx/characters/secrets/C.png"),
    [playerType.PLAYER_EDITH_B] = Renderer.LoadImage("gfx/characters/secrets/cabra.png"),
    [playerType.PLAYER_EDITH_C] = Renderer.LoadImage("gfx/characters/secrets/kotroid.png"),
}

mod:AddCallback(ModCallbacks.MC_POST_RENDER_CHARACTER_SELECT_PORTRAIT, function(_, PlayerType, sprite, position)
    if Roll ~= 1 then return end

    local cabra = Cabras[PlayerType]
    
    if not cabra then return end

    local height = cabra:GetHeight()
    local width = cabra:GetWidth()

	local scale = sprite.Scale

	local destR = DestinationQuad(
		Vector.Zero,
        Vector.Zero,
        Vector.Zero,
        Vector(40, 40)
	)

	local cabraScale = Vector.One * scale

    local vec = Vector(20, 30)

    if PlayerType == playerType.PLAYER_EDITH_C then
        vec = Vector(25, 19)
    end

    destR:Scale(cabraScale, cabraScale)
    destR:Translate(position - (vec * scale))

	local source = SourceQuad(
		Vector.Zero,
		Vector(width, 0),
		Vector(0, height),
		Vector(width, height)
	)

	cabra:Render(source, destR, KColor(1, 1, 1, 1), Color(1))
end)
