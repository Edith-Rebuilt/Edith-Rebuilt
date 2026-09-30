local mod = EdithRebuilt

local enums = mod.Enums

local utils = enums.Utils
local tables = enums.Tables
local Trenums = enums.Epiphany
local TRCallbacks = Trenums.Callbacks
local misc = enums.Misc

local game = utils.Game
local sfx = utils.SFX

local playerType = Trenums.PlayerType
local modules = mod.Modules

local TREdithMod = modules.TR_EDITH
local TRTarget = modules.TARGET
local TEdithMod = modules.TEDITH
local TargetArrow = modules.TARGET_ARROW
local Helpers = modules.HELPERS
local StatusEffects = modules.STATUS_EFFECTS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local Land = modules.LAND

local params = TREdithMod.GetFlingStrikeParams
local data = mod.DataHolder.GetEntityData

local TrEdithInfo = {
    charName = "EDITH", --Internal character name (REQUIRED)
    charID = playerType.PLAYER_EDITH_C, -- Character ID (REQUIRED)
    costume = "gfx/EdithTaintedAnim.anm2", -- Main costume (REQUIRED)
    -- extraCostume = {Isaac.GetCostumeIdByPath("gfx/characters/character_opensauce_extra.anm2")}, -- Extra costume (e.g. Maggy's Hair)
    menuGraphics = "gfx/Epiphany/ui/menu_edith.anm2", -- Character menu graphics (portrait, text) (REQUIRED)
    coopMenuSprite = "gfx/Epiphany/ui/Coop/coop_menu_opensauce.anm2", -- Co-op menu icon (REQUIRED)
    unlockChecker = function() return true end, -- function that returns whether the character is unlocked. Defaults to always returning true.
    floorTutorial = "gfx/grid/tutorial_opensauce.anm2"
}

local function AddTrEdith()
    if not Epiphany then return end
    if not Epiphany.API then return end

    Epiphany.API.AddCharacter(TrEdithInfo)
    mod:RemoveCallback(ModCallbacks.MC_POST_NEW_LEVEL, AddTrEdith)
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, AddTrEdith)

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddPriorityCallback(ModCallbacks.MC_INPUT_ACTION, CallbackPriority.IMPORTANT, function(_, entity, input, action)
    if not entity then return end

    local player = entity:ToPlayer()

    if not player then return end
    if not TREdithMod.IsTREdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    player.Color = Color(1, 1, 1, 1, 0.5, 0, 0, 0.3, 0, 0, 0.4)
end)

---@param player EntityPlayer
local function HandleTargetSpawn(player)
	if player.FrameCount == 0 then return end
	if player.ControlsCooldown > 0 then return end
	if not TargetArrow.IsEdithTargetMoving(player) then return end
    if params(player).IsFlinging then return end

    TRTarget.SpawnTREdithTarget(player)
end

---@param player EntityPlayer
---@param charge number
local function ChargeFling(player, charge)
    if not Helpers.IsKeyStompPressed(player) then return end
    if params(player).IsFlinging then return end

    TREdithMod.AddFlingCharge(player, charge)
end

---@param flingParams TREdithFlingStrikeParams
local function ManageCounters(flingParams)
    flingParams.Cooldown = math.max(flingParams.Cooldown - 1, 0)

    if flingParams.IsFlinging then
        flingParams.FlingDuration = math.max(flingParams.FlingDuration - 1, 0)
    end
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local flingParams = params(player)
    local speed = player.MoveSpeed - 1

    ManageCounters(flingParams)
    ChargeFling(player, 0.025 + (0.025 * (speed * speed)))
end)

---@param IsParryLand boolean
---@return FeedbackLandParams
local function GetTEdithLandParams(IsParryLand)
    local TEdithData = mod.Modules.HELPERS.GetConfigData(enums.ConfigDataTypes.TEDITH) ---@cast TEdithData TEdithData
    return {
        Size = IsParryLand and 0.7 or 0.5,
        SoundPick = IsParryLand and TEdithData.ParrySound or TEdithData.HopSound,
        Volume = 1, --GetVolume(TEdithData.Volume) * (IsParryLand and 1.5 or 1),
        ScreenShakeIntensity = IsParryLand and 6 or 3,
        GibAmount = not TEdithData.DisableSaltGibs and (IsParryLand and 6 or 2) or 0,
        GibSpeed = 2,
    }
end

---@param player EntityPlayer
local function FlingSpecialEffects(player)
    Land.SpawnLandGFX(player, GetTEdithLandParams(false), Helpers.IsChap4())
    Helpers.SpawnSaltGib(player, 3, 4, player.Color, true)
    sfx:Play(SoundEffect.SOUND_SHELLGAME)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function SetFlingParams(player, flingParams)
    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    flingParams.IsFlinging = true
    flingParams.FlingDirection = TRTarget.GetEdithTargetDirection(player)
    flingParams.FlingDuration = math.ceil((45 * charge) * Player.GetPlayerRange(player) / 9)
    flingParams.FlingVel = flingParams.FlingDirection * 15 * charge
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerFling(player, flingParams)
    if flingParams.IsFlinging then return end

    SetFlingParams(player, flingParams)
    FlingSpecialEffects(player)

    TRTarget.RemoveEdithTarget(player)
end

local puffSize = Vector(0.6, 0.6)

---@param player EntityPlayer
---@param charge number
local function BurstSpecialEffects(player, charge)
    game:ShakeScreen(5 + math.ceil(4 * charge))

    local cloud = StatusEffects.SpawnSpicePuff(player, RNG(Random()))

    cloud.Color = Color(1, 1, 1, 1, 0.3, 0.3, 0.3)
    cloud.SpriteScale = puffSize + (puffSize / 2) * charge
end

local function BurstKnockback(player, charge, Capsule)
    local modCharge = TEdithMod.HopCurve(charge)

    for _, ent in ipairs(Isaac.FindInCapsule(Capsule, misc.ParryPartitions --[[@as EntityPartition]])) do
        Helpers.TriggerPush(ent, player, 50 * modCharge)

        if Helpers.IsEnemy(ent) then
            data(ent).HitStunDuration = 8 + math.ceil(5 * modCharge)
        end
    end
end 

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerBurst(player, flingParams)
    if flingParams.FlingStaticCharge <= 0 then return end
    if flingParams.Cooldown > 0 then return end

    local charge = TREdithMod.GetFlingBurstCharge(player, true)
    local Capsule = Capsule(player.Position, Vector.One, 0, 50)

    BurstSpecialEffects(player, charge)
    BurstKnockback(player, charge, Capsule)

    player:SetMinDamageCooldown(30)

    flingParams.FlingMoveCharge = 0
    flingParams.Cooldown = 15
end

mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function (_, npc)
    local npcData = data(npc)

    if not (npcData.HitStunDuration and npcData.HitStunDuration > 0) then return end

    npcData.HitStunDuration = npcData.HitStunDuration - 1

    if npcData.HitStunDuration > 0 then
        return true
    end
end)

---@param player EntityPlayer
local function ChargeRelease(player)
    if not (TREdithMod.GetFlingBurstCharge(player, false) > 0 and not Helpers.IsKeyStompPressed(player)) then return end

    local target = TRTarget.GetTREdithTarget(player)
    local flingParams = params(player)

    if target then
        TriggerFling(player, flingParams)
    else
        TriggerBurst(player, flingParams)
    end

    flingParams.FlingStaticCharge = 0
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function KeepFling(player, flingParams)
    if flingParams.FlingDuration <= 0 then return end

    player.Velocity = flingParams.FlingVel
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    HandleTargetSpawn(player)

    local target = TRTarget.GetTREdithTarget(player)
    local isMoving = TargetArrow.IsEdithTargetMoving(player)
    local flingParams = params(player)

    if flingParams.FlingDuration == 1 then
        player:SetMinDamageCooldown(30)
        flingParams.FlingMoveCharge = 0
        flingParams.FlingStaticCharge = 0
    end

    if flingParams.FlingDuration == 0 and flingParams.IsFlinging == true then
        flingParams.IsFlinging = false
    end

    ChargeRelease(player)

    TREdithMod.ManageTREdithBounce(player, flingParams)
    KeepFling(player, flingParams)

    if target then
        EdithMod.TargetMovementManager(player, target, isMoving)
    end
end)

local function TriggerGridHitEffects(player)
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    game:ShakeScreen(3 + math.ceil(5 * TREdithMod.GetFlingBurstCharge(player, false)))
    Helpers.SpawnSaltGib(player, 3, 4, player.Color, false)
end

---@param player EntityPlayer
---@param grid GridEntity
---@param flingParams TREdithFlingStrikeParams
mod:AddCallback(TRCallbacks.STRIKE_HIT_GRID, function (_, player, grid, flingParams)
    TriggerGridHitEffects(player)
end)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	Player.ForEachPlayerType(function(player)
		if RoomTransition:GetTransitionMode() == 3 then return end

		local flingParams = params(player)   
		local playerData = data(player)
		local FlingCharge = flingParams.FlingStaticCharge

		if not FlingCharge then return end

        playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)

		local playerpos = Player.GetPlayerRenderPos(player)

		HudHelper.RenderChargeBar(playerData.ChargeBar, FlingCharge, 1, playerpos + misc.ChargeBarcenterVector)
	end, playerType.PLAYER_EDITH_C)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    if params(player).IsFlinging then
        return false
    end
end)

---@param player EntityPlayer
---@param collider Entity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function (_, player, collider)
    if not TREdithMod.IsTREdith(player) then return end
    if not Helpers.IsEnemy(collider) then return end

    local flingParams = params(player)

    if not flingParams.IsFlinging then return end

    local rawFormula = (12 + player.Damage) / 1.5
    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    flingParams.ShoveDamage = rawFormula * (TEdithMod.HopCurve(charge) + 0.5) 

    Land.LandDamage(collider, player, flingParams.ShoveDamage, 30 * player.ShotSpeed * charge)
    Helpers.TriggerPush(collider, player, 30 * player.ShotSpeed)
    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

    return true
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
	Player.ForEachPlayerType(function(player)
		Helpers.ChangeColor(player, nil, nil, nil, 1)
		TRTarget.RemoveEdithTarget(player)
		params(player).IsFlinging = false
	end, playerType.PLAYER_EDITH_C)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    Player.ForEachPlayerType(function(player)
		Helpers.ChangeColor(player, nil, nil, nil, 1)
		TRTarget.RemoveEdithTarget(player)
		params(player).FlingDuration = 0
	end, playerType.PLAYER_EDITH_C)
end)