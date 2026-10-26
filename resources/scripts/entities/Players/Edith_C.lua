-- #region Imports

local mod = EdithRebuilt

local enums = mod.Enums
local utils = enums.Utils
local misc = enums.Misc

local game = utils.Game
local sfx = utils.SFX

local playerType = enums.PlayerType
local edithCallbacks = enums.Callbacks

local modules = mod.Modules
local TREdithMod = modules.TR_EDITH
local TRTarget = modules.TARGET
local TEdithMod = modules.TEDITH
local TargetArrow = modules.TARGET_ARROW
local Helpers = modules.HELPERS
local StatusEffects = modules.STATUS_EFFECTS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local VecDir = modules.VEC_DIR
local Land = modules.LAND
local Bounce = modules.BOUNCE

local BounceResult = Bounce.Result

local params = TREdithMod.GetFlingStrikeParams
local data = mod.DataHolder.GetEntityData
-- #endregion Imports

-- #region Constants

local JARONA_MODE = false
local JARONA_COLOR = Color(1, 1, 1, 1, 0.01, 0.2, 1)

local BASE_RANGE = 9
local HIGH_CHARGE_THRESHOLD = 0.3 

local CHARGE_RATE_BASE = 0.0325
local CHARGE_RATE_SPEED_FACTOR = 0.025

local TARGET_IDLE_FRAMES_TO_RETURN = 20
local TARGET_POP_RELEASE_FRAME = 2
local TARGET_ARRIVAL_DISTANCE = 15
local TARGET_PULL_DIVISOR = 4

local FLING_SPEED = 15
local FLING_DURATION_BASE = 40
local FLING_END_DAMAGE_COOLDOWN = 40
local FLING_END_COOLDOWN = 10

local BURST_RADIUS = 60
local BURST_PUSH_FORCE = 25
local BURST_STUN_BASE = 10
local BURST_STUN_PER_CHARGE = 10
local BURST_DAMAGE_COOLDOWN = 30
local BURST_COOLDOWN = 8
local BURST_SHAKE_BASE = 5
local BURST_SHAKE_PER_CHARGE = 4

local WHITE_FIREPLACE_VARIANT = 4

local STRIKE_RADIUS_PER_CHARGE = 5
local STRIKE_DAMAGE_BASE = 22.5
local STRIKE_DAMAGE_DIVISOR = 1.25
local STRIKE_DAMAGE_CHARGE_FLOOR = 0.5
local STRIKE_KNOCKBACK_BASE = 50

local GRID_HIT_SHAKE_BASE = 3
local GRID_HIT_SHAKE_PER_CHARGE = 5
local DEATH_EXPLOSION_DAMAGE = 100
local DEATH_SHAKE = 12
-- #endregion Constants

-- #region Utils

---@param callback ModCallbacks
---@param fn fun(player: EntityPlayer, ...): any
local function AddTREdithCallback(callback, fn)
    mod:AddCallback(callback, function (_, player, ...)
        if not TREdithMod.IsTREdith(player) then return end

        return fn(player, ...)
    end)
end

---@param player EntityPlayer
---@return number
local function GetFlingCharge(player)
    return TREdithMod.GetFlingBurstCharge(player, false)
end

---@param player EntityPlayer
---@return number
local function GetBurstCharge(player)
    return TREdithMod.GetFlingBurstCharge(player, true)
end

---@param player EntityPlayer
---@return boolean
local function HasHighFlingCharge(player)
    return GetFlingCharge(player) >= HIGH_CHARGE_THRESHOLD
end

---@param ent Entity
---@return boolean
local function IsIgnoredByFling(ent)
    return ent:ToBomb() ~= nil
end
-- #endregion Utils

-- #region CharRegister

local TrEdithInfo = {
    charName = "EDITH", -- Internal character name (REQUIRED)
    charID = playerType.PLAYER_EDITH_C, -- Character ID (REQUIRED)
    costume = "gfx/EdithTarnishedAnim.anm2", -- Main costume (REQUIRED)
    extraCostume = {Isaac.GetCostumeIdByPath("gfx/characters/EdithTarnishedHood.anm2")}, -- Extra costume (e.g. Maggy's Hair)
    menuGraphics = "gfx/Epiphany/ui/menu_edith.anm2", -- Character menu graphics (portrait, text) (REQUIRED)
    coopMenuSprite = "gfx/Epiphany/ui/Coop/coop_menu_opensauce.anm2", -- Co-op menu icon (REQUIRED)
    unlockChecker = function() return true end, -- Whether the character is unlocked. Defaults to always true.
    floorTutorial = "gfx/Epiphany/grid/tutorial_Edith.anm2"
}

local function AddTREdith()
    if not (Epiphany and Epiphany.API) then return end

    Epiphany.API.AddCharacter(TrEdithInfo)
    mod:RemoveCallback(ModCallbacks.MC_POST_NEW_LEVEL, AddTREdith)
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, AddTREdith)

-- #endregion CharRegister

-- #region TargetCharge

---@param player EntityPlayer
local function HandleTargetSpawn(player)
    if player.FrameCount == 0 then return end
    if player.ControlsCooldown > 0 then return end
    if not TargetArrow.IsEdithTargetMoving(player) then return end
    if params(player).IsFlinging then return end

    TRTarget.SpawnTREdithTarget(player)
end

---@param player EntityPlayer
---@param targetData table
local function ManageTargetCounter(player, targetData)
    if Player.IsPlayerMoving(player) then
        targetData.Count = 0
        targetData.Returning = false
        return
    end

    targetData.Count = targetData.Count + 1
end

---@param target EntityEffect
---@param targetData table
local function ReturnTarget(target, targetData)
    if targetData.Count < TARGET_IDLE_FRAMES_TO_RETURN then return end

    local sprite = target:GetSprite()

    if not targetData.NotPlayPop and not sprite:IsPlaying("Pop") then
        sprite:Play("Pop", false)
    end

    if sprite:GetFrame() ~= TARGET_POP_RELEASE_FRAME then return end

    sprite:Play("Idle")

    targetData.Returning = true
    targetData.NotPlayPop = true
end

---@param player EntityPlayer
---@param target EntityEffect
---@param targetData table
local function ApplyReturnVel(player, target, targetData)
    if not targetData.Returning then return end

    local distance = TRTarget.GetEdithTargetDistance(player)

    if distance <= TARGET_ARRIVAL_DISTANCE then
        TRTarget.RemoveEdithTarget(player)
        return
    end

    target.Velocity = target.Velocity - TRTarget.GetEdithTargetDirection(player) * distance / TARGET_PULL_DIVISOR
end

---@param player EntityPlayer
local function ManageTargetReturn(player)
    local target = TRTarget.GetTREdithTarget(player)
    if not target then return end

    local targetData = data(target)

    targetData.Count = targetData.Count or 0
    targetData.Returning = targetData.Returning or false

    ManageTargetCounter(player, targetData)
    ReturnTarget(target, targetData)
    ApplyReturnVel(player, target, targetData)
end

---@param player EntityPlayer
---@param charge number
local function ChargeFling(player, charge)
    if not Helpers.IsKeyStompPressed(player) then return end
    if params(player).IsFlinging then return end

    TREdithMod.AddFlingCharge(player, charge)
    ManageTargetReturn(player)
end
-- #endregion TargetCharge

-- #region PEffectUpdate

---@param flingParams TREdithFlingStrikeParams
local function ManageCounters(flingParams)
    flingParams.Cooldown = math.max(flingParams.Cooldown - 1, 0)

    if not flingParams.IsFlinging then return end

    flingParams.FlingDuration = math.max(flingParams.FlingDuration - 1, 0)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function AfterImages(player, flingParams)
    if not flingParams.IsFlinging then return end

    player:CreateAfterimage(1 + math.ceil(4 * flingParams.FlingMoveCharge), player.Position)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function SetFlingFaceDirection(player, flingParams)
    if Player.IsPlayerShooting(player) then return end

    local target = TRTarget.GetTREdithTarget(player)
    local faceDir = target and TRTarget.GetEdithTargetDirection(player)
        or flingParams.IsFlinging and flingParams.FlingDirection

    if not faceDir then return end
	player:SetHeadDirection(VecDir.VectorToDirection(faceDir), 1, true)
end

local readyColor = Color(1, 1, 1, 1, 0.3)

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function ManageFlingBurstReady(player, flingParams)
    if flingParams.Cooldown ~= 1 then return end

    sfx:Play(SoundEffect.SOUND_BEEP)
    player:SetColor(readyColor, 5, 1000, true, true)
end

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (player)
    local flingParams = params(player)
    local speed = player.MoveSpeed - 1

    Player.ManageLeoEffect(player)
    ManageCounters(flingParams)
    ManageFlingBurstReady(player, flingParams)
    ChargeFling(player, CHARGE_RATE_BASE + (CHARGE_RATE_SPEED_FACTOR * (speed * speed)))
    AfterImages(player, flingParams)
    SetFlingFaceDirection(player, flingParams)
end)
-- #endregion PEffectUpdate

-- #region Fling

---@return FeedbackLandParams
local function GetFlingLandParams()
    local config = Helpers.GetConfigData(enums.ConfigDataTypes.TEDITH) ---@cast config TEdithData

    return {
        Size = 0.5,
        SoundPick = config.HopSound,
        Volume = 1,
        ScreenShakeIntensity = 3,
        GibAmount = config.DisableSaltGibs and 0 or 2,
        GibSpeed = 2,
    }
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function SetFlingParams(player, flingParams)
    local charge = GetFlingCharge(player)

    flingParams.IsFlinging = true
    flingParams.FlingDirection = TRTarget.GetEdithTargetDirection(player)
    flingParams.FlingDuration = math.ceil((FLING_DURATION_BASE * charge * charge) * Player.GetPlayerRange(player) / BASE_RANGE)
    flingParams.FlingVel = flingParams.FlingDirection * FLING_SPEED * charge
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerFling(player, flingParams)
    if flingParams.IsFlinging then return end

    SetFlingParams(player, flingParams)
    Land.SpawnLandGFX(player, GetFlingLandParams(), Helpers.IsChap4())
    sfx:Play(SoundEffect.SOUND_SHELLGAME)

    if JARONA_MODE then
        sfx:Play(enums.SoundEffect.SOUND_JARONA)
    end

    TRTarget.RemoveEdithTarget(player)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function KeepFling(player, flingParams)
    if flingParams.FlingDuration <= 0 then return end

    if JARONA_MODE then
        player:SetColor(JARONA_COLOR, 5, 1000, true, true)
    end

    player.Velocity = flingParams.FlingVel
end

---Limpieza común al terminar el Fling (por duración o por cambio de sala).
---@param flingParams TREdithFlingStrikeParams
local function ClearFlingState(flingParams)
    flingParams.FlingMoveCharge = 0
    flingParams.StruckEntities = {}
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function ResetFlingState(player, flingParams)
    if flingParams.FlingDuration == 1 then
        ClearFlingState(flingParams)
        player:SetMinDamageCooldown(FLING_END_DAMAGE_COOLDOWN)
        flingParams.FlingStaticCharge = 0
        flingParams.Cooldown = FLING_END_COOLDOWN
    end

    if flingParams.FlingDuration == 0 and flingParams.IsFlinging then
        flingParams.IsFlinging = false
    end
end

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (player)
    if not params(player).IsFlinging then return end

    return false
end)

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_PRE_PLAYER_POCKET_ITEMS_SWAP, function (player)
    if params(player).IsFlinging then return end

    return true
end)

local BlockedPickupVariants = {
    [PickupVariant.PICKUP_COLLECTIBLE] = true,
    [PickupVariant.PICKUP_SHOPITEM] = true,
    [PickupVariant.PICKUP_TRINKET] = true,
    [PickupVariant.PICKUP_TAROTCARD] = true,
    [PickupVariant.PICKUP_PILL] = true,
}

---@param pickup EntityPickup
local function IsBlockedPickup(pickup)
	return (Helpers.When(pickup.Variant, BlockedPickupVariants) or pickup:IsShopItem())
end

---@param player EntityPlayer
---@param collider Entity
AddTREdithCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function (player, collider)
    local pickup = collider:ToPickup()

	if not params(player).IsFlinging then return end
    if IsIgnoredByFling(collider) then return true end
    if not pickup then return end
    if not HasHighFlingCharge(player) then return end
    if not IsBlockedPickup(pickup) then return end

    pickup.Wait = 1

    return true
end)

-- #endregion Fling

-- #region Burst

local puffSize = Vector(0.6, 0.6)

---@param player EntityPlayer
---@param charge number
local function BurstSpecialEffects(player, charge)
    game:ShakeScreen(BURST_SHAKE_BASE + math.ceil(BURST_SHAKE_PER_CHARGE * charge))

    local cloud = StatusEffects.SpawnSpicePuff(player, RNG(Random()))

    cloud.Color = Color(1, 1, 1, 1, 0.3, 0.3, 0.3)
    cloud.SpriteScale = puffSize + (puffSize / 2) * charge
end

---@param player EntityPlayer
---@param ent Entity
---@param stunFrames integer
local function BurstHitEntity(player, ent, stunFrames)
    Helpers.TriggerPush(ent, player, BURST_PUSH_FORCE)

    if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= WHITE_FIREPLACE_VARIANT then
        ent:Kill()
    end

    if Helpers.IsEnemy(ent) then
        data(ent).HitStunDuration = stunFrames
    end
end

---@param player EntityPlayer
---@param charge number
---@param capsule Capsule
local function BurstKnockback(player, charge, capsule)
    local stunFrames = BURST_STUN_BASE + math.ceil((BURST_STUN_PER_CHARGE * charge) * player.ShotSpeed)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, misc.ParryPartitions)) do
        if not IsIgnoredByFling(ent) then
            BurstHitEntity(player, ent, stunFrames)
        end
    end
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerBurst(player, flingParams)
    if flingParams.FlingStaticCharge <= 0 then return end
    if flingParams.Cooldown > 0 then return end

    local charge = math.min(1, GetBurstCharge(player))

    BurstSpecialEffects(player, charge)
    BurstKnockback(player, charge, Capsule(player.Position, Vector.One, 0, BURST_RADIUS))

    player:SetMinDamageCooldown(BURST_DAMAGE_COOLDOWN)

    flingParams.FlingMoveCharge = 0
    flingParams.Cooldown = BURST_COOLDOWN
end

mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function (_, npc)
    local npcData = data(npc)

    if not (npcData.HitStunDuration and npcData.HitStunDuration > 0) then return end

    npcData.HitStunDuration = npcData.HitStunDuration - 1

    if npcData.HitStunDuration <= 0 then return end

    return true
end)

---@param player EntityPlayer
local function ChargeRelease(player)
    if GetFlingCharge(player) <= 0 then return end
    if Helpers.IsKeyStompPressed(player) then return end

    local target = TRTarget.GetTREdithTarget(player)
    local flingParams = params(player)

    if target and not data(target).Returning then
        TriggerFling(player, flingParams)
    else
        TriggerBurst(player, flingParams)

        if target then
            TRTarget.RemoveEdithTarget(player)
        end
    end

    flingParams.FlingStaticCharge = 0
end
-- #endregion Burst

-- #region Strike

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@param charge number
local function UpdateStrikeStats(player, flingParams, charge)
    flingParams.StrikeDamage = (STRIKE_DAMAGE_BASE + player.Damage) / STRIKE_DAMAGE_DIVISOR * ((charge * charge) + STRIKE_DAMAGE_CHARGE_FLOOR)
    flingParams.StrikeKnockback = STRIKE_KNOCKBACK_BASE * player.ShotSpeed * TEdithMod.HopCurve(charge)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@param ent Entity
local function StrikeEnemy(player, flingParams, ent)
    local entHash = GetPtrHash(ent)

    if flingParams.StruckEntities[entHash] then return end

    flingParams.StruckEntities[entHash] = true

    Isaac.RunCallback(edithCallbacks.STRIKE_HIT_ENEMY, player, ent, flingParams)

    Land.LandDamage(ent, player, flingParams.StrikeDamage, flingParams.StrikeKnockback)
    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

    Bounce.TriggerEnemyBounce(player, flingParams, ent, entHash)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function StrikeManager(player, flingParams)
    if not flingParams.IsFlinging then return end

    local charge = GetFlingCharge(player)
    local strikeRadius = player.Size + (STRIKE_RADIUS_PER_CHARGE * (Player.GetPlayerRange(player) / BASE_RANGE) * charge)
    local strikeCapsule = Capsule(player.Position, Vector.One, 0, strikeRadius)

    UpdateStrikeStats(player, flingParams, charge)

    for _, ent in ipairs(Isaac.FindInCapsule(strikeCapsule, EntityPartition.ENEMY)) do
        if IsIgnoredByFling(ent) then goto continue end
		Land.HandleEntityInteraction(ent, player, flingParams.StrikeKnockback)

		if not Helpers.IsEnemy(ent) then goto continue end
		StrikeEnemy(player, flingParams, ent)

		::continue::
    end
end

---@param player EntityPlayer
local function TREdithTrapdoor(player)
    if not HasHighFlingCharge(player) then return end

    local grid = utils.Room:GetGridEntityFromPos(player.Position)
    if not grid then return end

    local trapDoor = grid:ToTrapDoor()
    if not trapDoor then return end

    trapDoor.State = 0
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function UpdateFling(player, flingParams)
    StrikeManager(player, flingParams)
    ResetFlingState(player, flingParams)
    ChargeRelease(player)
    KeepFling(player, flingParams)
end

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (player)
    HandleTargetSpawn(player)

    local target = TRTarget.GetTREdithTarget(player)

    TREdithTrapdoor(player)
    UpdateFling(player, params(player))

    if target then
        EdithMod.TargetMovementManager(player, target, TargetArrow.IsEdithTargetMoving(player))
    end
end)
-- #endregion Strike

-- #region Bounce

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_PRE_PLAYER_UPDATE, function (player)
    local flingParams = params(player)
    if not flingParams.IsFlinging then return end

    local door = Bounce.ResolveDoorCollision(player, flingParams)

    if door then
        Isaac.RunCallback(edithCallbacks.STRIKE_HIT_GRID, player, door, flingParams)
    end

    Bounce.SnapshotMotion(player)
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function (_, player, _index, grid)
    local flingParams = params(player)
    if not flingParams.IsFlinging then return end

    local result = Bounce.ResolveGridCollision(player, flingParams, grid)

    if result == BounceResult.IGNORED then return end

    if result == BounceResult.BOUNCED then
        Isaac.RunCallback(edithCallbacks.STRIKE_HIT_GRID, player, grid, flingParams)
    end

    return true
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(edithCallbacks.STRIKE_HIT_GRID, function (_, player, grid)
    local charge = GetFlingCharge(player)

    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    game:ShakeScreen(GRID_HIT_SHAKE_BASE + math.ceil(GRID_HIT_SHAKE_PER_CHARGE * charge))

    if HasHighFlingCharge(player) and not grid:ToDoor() then
        grid:DestroyWithSource(false, EntityRef(player))
    end
end)
-- #endregion Bounce

-- #region Death

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (player)
    local pData = data(player)
    if pData.TREdithExplode then return end

    local sprite = player:GetSprite()
    if not (sprite:IsPlaying("Death") and sprite:IsEventTriggered("DeathExplode")) then return end

    game:BombExplosionEffects(player.Position, DEATH_EXPLOSION_DAMAGE)
    game:ShakeScreen(DEATH_SHAKE)

    pData.TREdithExplode = true
end)

---@param player EntityPlayer
AddTREdithCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, function (player)
    data(player).TREdithExplode = false
end)
-- #endregion Death

-- #region Misc

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    Player.ForEachPlayerType(function(player)
        if RoomTransition:GetTransitionMode() == 3 then return end

        local flingCharge = GetBurstCharge(player)
        local playerData = data(player)

        playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)

        HudHelper.RenderChargeBar(playerData.ChargeBar, flingCharge, 1, Player.GetPlayerRenderPos(player) + misc.ChargeBarcenterVector)
    end, playerType.PLAYER_EDITH_C)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    Player.ForEachPlayerType(function(player)
        Helpers.ChangeColor(player, nil, nil, nil, 1)
        TRTarget.RemoveEdithTarget(player)

        local flingParams = params(player)

        flingParams.FlingDuration = 0
        ClearFlingState(flingParams)
    end, playerType.PLAYER_EDITH_C)
end)

---@param tear EntityTear
mod:AddPriorityCallback(ModCallbacks.MC_POST_FIRE_TEAR, CallbackPriority.LATE, function (_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

    if not player then return end
    if not TREdithMod.IsTREdith(player) then return end

    local color = tear.Color

    color:SetTint(1, 157/255, 66/255, 1)
    color:SetOffset(0.7, 47/255, 17/255)

    tear.Color = color
end)
-- #endregion Misc