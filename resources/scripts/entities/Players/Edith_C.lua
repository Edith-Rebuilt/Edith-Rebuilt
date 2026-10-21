local mod = EdithRebuilt

local enums = mod.Enums
local utils = enums.Utils
local misc = enums.Misc
local Trenums = enums.Epiphany
local TRCallbacks = Trenums.Callbacks

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
local VecDir = modules.VEC_DIR
local Land = modules.LAND
local Bounce = modules.BOUNCE

local BounceResult = Bounce.Result

local params = TREdithMod.GetFlingStrikeParams
local data = mod.DataHolder.GetEntityData

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

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    if not (Epiphany and Epiphany.API) then return end

    Epiphany.API.AddCharacter(TrEdithInfo)
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
    if targetData.Count < 20 then return end

    local sprite = target:GetSprite()

    if not targetData.NotPlayPop and not sprite:IsPlaying("Pop") then
        sprite:Play("Pop", false)
    end

    if sprite:GetFrame() ~= 2 then return end

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

    if distance <= 15 then
        TRTarget.RemoveEdithTarget(player)
        return
    end

    target.Velocity = target.Velocity - TRTarget.GetEdithTargetDirection(player) * distance / 4
end

---Si el jugador deja de moverse mientras carga, el target vuelve hacia él.
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

    if faceDir then
        player:SetHeadDirection(VecDir.VectorToDirection(faceDir), 1, true)
    end
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
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    local flingParams = params(player)
    local speed = player.MoveSpeed - 1

    Player.ManageLeoEffect(player)
    ManageCounters(flingParams)
    ManageFlingBurstReady(player, flingParams)
    ChargeFling(player, 0.025 + (0.025 * (speed * speed)))
    AfterImages(player, flingParams)
    SetFlingFaceDirection(player, flingParams)
end)

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
    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    flingParams.IsFlinging = true
    flingParams.FlingDirection = TRTarget.GetEdithTargetDirection(player)
    flingParams.FlingDuration = math.ceil((40 * charge * charge) * Player.GetPlayerRange(player) / 9)
    flingParams.FlingVel = flingParams.FlingDirection * 15 * charge
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerFling(player, flingParams)
    if flingParams.IsFlinging then return end

    SetFlingParams(player, flingParams)
    Land.SpawnLandGFX(player, GetFlingLandParams(), Helpers.IsChap4())
    sfx:Play(SoundEffect.SOUND_SHELLGAME)

    TRTarget.RemoveEdithTarget(player)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function KeepFling(player, flingParams)
    if flingParams.FlingDuration <= 0 then return end

    player.Velocity = flingParams.FlingVel
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function ResetFlingState(player, flingParams)
    if flingParams.FlingDuration == 1 then
        player:SetMinDamageCooldown(30)
        flingParams.FlingMoveCharge = 0
        flingParams.FlingStaticCharge = 0
        flingParams.Cooldown = 15
        flingParams.StruckEntities = {}
    end

    if flingParams.FlingDuration == 0 and flingParams.IsFlinging then
        flingParams.IsFlinging = false
    end
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

---@param player EntityPlayer
---@param charge number
---@param capsule Capsule
local function BurstKnockback(player, charge, capsule)
    local shotSpeed = player.ShotSpeed

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, misc.ParryPartitions)) do
        Helpers.TriggerPush(ent, player, 25)

        if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
            ent:Kill()
        end

        if Helpers.IsEnemy(ent) then
            data(ent).HitStunDuration = 5 + math.ceil((10 * charge) * shotSpeed)
        end
    end
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerBurst(player, flingParams)
    if flingParams.FlingStaticCharge <= 0 then return end
    if flingParams.Cooldown > 0 then return end

    local charge = math.min(1, TREdithMod.GetFlingBurstCharge(player, true))

    BurstSpecialEffects(player, charge)
    BurstKnockback(player, charge, Capsule(player.Position, Vector.One, 0, 60))

    player:SetMinDamageCooldown(30)

    flingParams.FlingMoveCharge = 0
    flingParams.Cooldown = 15
end

mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function (_, npc)
    local npcData = data(npc)

    if not (npcData.HitStunDuration and npcData.HitStunDuration > 0) then return end

    npcData.HitStunDuration = npcData.HitStunDuration - 1

    if npcData.HitStunDuration <= 0 then return end
    npc.State = NpcState.STATE_APPEAR
    return true
end)

---@param player EntityPlayer
local function ChargeRelease(player)
    if TREdithMod.GetFlingBurstCharge(player, false) <= 0 then return end
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

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function StrikeManager(player, flingParams)
    if not flingParams.IsFlinging then return end

    local charge = TREdithMod.GetFlingBurstCharge(player, false)
    local chargeMod = TEdithMod.HopCurve(charge)

    local strikeRadius = player.Size + (5 * (Player.GetPlayerRange(player) / 9) * charge)
    local strikeCapsule = Capsule(player.Position, Vector.One, 0, strikeRadius)

    flingParams.StrikeDamage = (22.5 + player.Damage) / 1.25 * ((charge * charge) + 0.5)
    flingParams.StrikeKnockback = 50 * player.ShotSpeed * chargeMod

    for _, ent in ipairs(Isaac.FindInCapsule(strikeCapsule, EntityPartition.ENEMY)) do
        Land.HandleEntityInteraction(ent, player, flingParams.StrikeKnockback)

        if not Helpers.IsEnemy(ent) then goto continue end

        local entHash = GetPtrHash(ent)

        if flingParams.StruckEntities[entHash] then goto continue end

        flingParams.StruckEntities[entHash] = true

        Isaac.RunCallback(TRCallbacks.STRIKE_HIT_ENEMY, player, ent, flingParams)

        Land.LandDamage(ent, player, flingParams.StrikeDamage, flingParams.StrikeKnockback)
        sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

        Bounce.TriggerEnemyBounce(player, flingParams, ent, entHash)
        ::continue::
    end
end

---@param player EntityPlayer
local function TREdithTrapdoor(player)
    if TREdithMod.GetFlingBurstCharge(player, false) < 0.3 then return end

    local gridPos = utils.Room:GetGridEntityFromPos(player.Position)

    if not gridPos then return end

    local trapDoor = gridPos:ToTrapDoor()

    if not trapDoor then return end

    trapDoor.State = 0
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    HandleTargetSpawn(player)

    local target = TRTarget.GetTREdithTarget(player)
    local flingParams = params(player)

    TREdithTrapdoor(player)
    StrikeManager(player, flingParams)
    ResetFlingState(player, flingParams)
    ChargeRelease(player)
    KeepFling(player, flingParams)

    if target then
        EdithMod.TargetMovementManager(player, target, TargetArrow.IsEdithTargetMoving(player))
    end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_UPDATE, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end
    if not params(player).IsFlinging then return end

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
        Isaac.RunCallback(TRCallbacks.STRIKE_HIT_GRID, player, grid, flingParams)
    end

    return true
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(TRCallbacks.STRIKE_HIT_GRID, function (_, player, grid)
    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    game:ShakeScreen(3 + math.ceil(5 * charge))

    if charge >= 0.25 and not grid:ToDoor() then
        grid:DestroyWithSource(false, EntityRef(player))
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    Player.ForEachPlayerType(function(player)
        if RoomTransition:GetTransitionMode() == 3 then return end

        local flingCharge = params(player).FlingStaticCharge
        if not flingCharge then return end

        local playerData = data(player)

        playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)

        HudHelper.RenderChargeBar(playerData.ChargeBar, flingCharge, 1, Player.GetPlayerRenderPos(player) + misc.ChargeBarcenterVector)
    end, playerType.PLAYER_EDITH_C)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end
    if not params(player).IsFlinging then return end

    return false
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    local pData = data(player)
    if pData.TREdithExplode then return end

    local sprite = player:GetSprite()
    if not (sprite:IsPlaying("Death") and sprite:IsEventTriggered("DeathExplode")) then return end

    game:BombExplosionEffects(player.Position, 100)
    game:ShakeScreen(12)

    pData.TREdithExplode = true
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, function(_, player)
    if not TREdithMod.IsTREdith(player) then return end

    data(player).TREdithExplode = false
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    Player.ForEachPlayerType(function(player)
        Helpers.ChangeColor(player, nil, nil, nil, 1)
        TRTarget.RemoveEdithTarget(player)

        local flingParams = params(player)

        flingParams.FlingDuration = 0
        flingParams.FlingMoveCharge = 0
        flingParams.FlingStaticCharge = 0
    end, playerType.PLAYER_EDITH_C)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_POCKET_ITEMS_SWAP, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end
    if params(player).IsFlinging then return end

    return true
end)