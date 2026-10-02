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

---@param velocity Vector
---@param normal Vector
---@param restitution number
---@return Vector
local function ReflectVelocity(velocity, normal, restitution)
    restitution = restitution or 1
    local d = velocity:Dot(normal)
    return (velocity - normal * (2 * d)) * restitution
end


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

	Player.ManageLeoEffect(player)
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
    sfx:Play(Trenums.SoundEffect.SOUND_JARONA, 5)
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function SetFlingParams(player, flingParams)
    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    flingParams.IsFlinging = true
    flingParams.FlingDirection = TRTarget.GetEdithTargetDirection(player)
    flingParams.FlingDuration = math.ceil((40 * (charge * charge)) * Player.GetPlayerRange(player) / 9)
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

        if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
            ent:Kill()
        end

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

    local charge = math.min(1, TREdithMod.GetFlingBurstCharge(player, true) * 2)
    local Capsule = Capsule(player.Position, Vector.One, 0, 60)

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
---@param flingParams TREdithFlingStrikeParams
local function ResetFlingState(player, flingParams)
    if flingParams.FlingDuration == 1 then 
        player:SetMinDamageCooldown(30)
        flingParams.FlingMoveCharge = 0
        flingParams.FlingStaticCharge = 0
        flingParams.StruckEntities = {}
    end

    if flingParams.FlingDuration == 0 and flingParams.IsFlinging == true then
        flingParams.IsFlinging = false
    end
end

---@param player EntityPlayer
---@param ent Entity
---@param hash integer
local function TriggerEnemyBounce(player, ent, hash)
    local flingParams = params(player)

    if not flingParams.IsFlinging then return end
    if not Helpers.IsEnemy(ent) then return end

    flingParams.StruckEntities[hash] = nil

    if flingParams.StrikeDamage > ent.HitPoints then return end

    local pData = data(player)
    local now = Isaac.GetFrameCount()
    if pData.LastBounceFrame == now then return end

    local vel = player.Velocity
    if vel:Length() < 0.01 then return end

    -- Normal = dirección desde el centro del enemigo hacia el jugador (igual que con obstáculos redondos)
    local diff = player.Position - ent.Position
    if diff:Length() < 0.01 then return end
    local normal = diff:Normalized()

    local combinedRadius = player.Size + ent.Size
    local penetration = math.max(combinedRadius - diff:Length(), 0)

    flingParams.StruckEntities[hash] = nil

    local reflectVel = ReflectVelocity(vel, normal, 1)
    player.Velocity = reflectVel
    player.Position = player.Position + normal * (penetration + 2)

    flingParams.FlingDirection = reflectVel:Normalized()
    flingParams.FlingVel = reflectVel

    pData.LastBounceFrame = now

    return true
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function StrikeManager(player, flingParams)
    if not flingParams.IsFlinging then return end

    local charge = TREdithMod.GetFlingBurstCharge(player, false)
    local chargeMod = TEdithMod.HopCurve(charge)

    local StrikeRadius = player.Size + (5 * (Player.GetPlayerRange(player) / 9) * charge)
    local StrikeCapsule = Capsule(player.Position, Vector.One, 0, StrikeRadius)

    flingParams.StrikeDamage = (22.5 + player.Damage) / 1.25 * ((charge * charge) + 0.5)
    flingParams.StrikeKnockback = 50 * player.ShotSpeed * chargeMod

    for _, ent in ipairs(Isaac.FindInCapsule(StrikeCapsule, EntityPartition.ENEMY)) do
        Land.HandleEntityInteraction(ent, player, flingParams.StrikeKnockback)

        if not Helpers.IsEnemy(ent) then goto continue end

        local entHash = GetPtrHash(ent)

        if flingParams.StruckEntities[entHash] then goto continue end

        flingParams.StruckEntities[entHash] = true

        Isaac.RunCallback(TRCallbacks.STRIKE_HIT_ENEMY, player, ent, flingParams)

        player:ForceCollide(player, false)

        Land.LandDamage(ent, player, flingParams.StrikeDamage, flingParams.StrikeKnockback)
        sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

        TriggerEnemyBounce(player, ent, entHash)
        ::continue::
    end
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not TREdithMod.IsTREdith(player) then return end

    HandleTargetSpawn(player)

    local target = TRTarget.GetTREdithTarget(player)
    local isMoving = TargetArrow.IsEdithTargetMoving(player)
    local flingParams = params(player)

    StrikeManager(player, flingParams)
    ResetFlingState(player, flingParams)
    ChargeRelease(player)
    KeepFling(player, flingParams)

    if target then
        EdithMod.TargetMovementManager(player, target, isMoving)
    end
end)

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_UPDATE, function (_, player)
    local pData = data(player)
    pData.PrevPosition = player.Position
    pData.PrevVelocity = player.Velocity
end)

---@param player EntityPlayer
---@param charge number 
local function TriggerGridHitEffects(player, charge)
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    game:ShakeScreen(3 + math.ceil(5 * charge))
    Helpers.SpawnSaltGib(player, 3, 4, player.Color, false)
end

---@param player EntityPlayer
---@param grid GridEntity
---@param charge number 
local function ManageStrikeGridDestroy(player, grid, charge)
    if not grid then return end
    if grid:ToDoor() then return end
    if charge < 0.5 then return end

    grid:DestroyWithSource(false, EntityRef(player))
end

---@param player EntityPlayer
---@param grid GridEntity
---@param flingParams TREdithFlingStrikeParams
mod:AddCallback(TRCallbacks.STRIKE_HIT_GRID, function (_, player, grid, flingParams)
    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    TriggerGridHitEffects(player, charge)
    ManageStrikeGridDestroy(player, grid, charge)
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

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    Player.ForEachPlayerType(function(player)
		Helpers.ChangeColor(player, nil, nil, nil, 1)
		TRTarget.RemoveEdithTarget(player)
		params(player).FlingDuration = 0
	end, playerType.PLAYER_EDITH_C)
end)

-- Intersección rayo-caja con volumen (jugador como círculo de radio playerRadius)
-- Devuelve t y la normal del lado por el que efectivamente entraría
local function RaySweptAABBIntersect(origin, dir, boxMin, boxMax)
    local invDirX = dir.X ~= 0 and 1 / dir.X or math.huge
    local invDirY = dir.Y ~= 0 and 1 / dir.Y or math.huge

    local tx1 = (boxMin.X - origin.X) * invDirX
    local tx2 = (boxMax.X - origin.X) * invDirX
    local ty1 = (boxMin.Y - origin.Y) * invDirY
    local ty2 = (boxMax.Y - origin.Y) * invDirY

    local txMin, txMax = math.min(tx1, tx2), math.max(tx1, tx2)
    local tyMin, tyMax = math.min(ty1, ty2), math.max(ty1, ty2)

    local tmin = math.max(0, txMin, tyMin)
    local tmax = math.min(txMax, tyMax)

    if tmin > tmax then return nil end

    local normal
    if txMin > tyMin then
        normal = Vector(dir.X > 0 and -1 or 1, 0)
    else
        normal = Vector(0, dir.Y > 0 and -1 or 1)
    end

    return tmin, normal
end

local GRID_SIZE = 40

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function (_, player, index, grid)
    local flingParams = params(player)
    if not flingParams.IsFlinging then return end
    if not grid then return end

    local door = grid:ToDoor()
    if door and door:IsOpen() then return end

    local pData = data(player)
    local now = Isaac.GetFrameCount()
    if pData.LastProcessedFrame == now then return true end
    pData.LastProcessedFrame = now

    local prevPos = pData.PrevPosition or player.Position
    local prevVel = pData.PrevVelocity or player.Velocity
    local speed = prevVel:Length()
    if speed < 0.01 then return end

    local dir = prevVel:Normalized()
    local half = GRID_SIZE / 2 + player.Size
    local center = grid.Position

    local t, normal = RaySweptAABBIntersect(prevPos, dir, center - Vector(half, half), center + Vector(half, half))

    if not t then
        local diff = prevPos - center
        normal = math.abs(diff.X) > math.abs(diff.Y) and Vector(diff.X > 0 and 1 or -1, 0) or Vector(0, diff.Y > 0 and 1 or -1)
    end

    local sizeMargin = player.Size 

    -- Si esta normal es básicamente la misma que la del último rebote real y reciente,
    -- es la misma pared (celda vecina) — no reflejar de nuevo, solo reafirmar posición.
    local sameWallAsLastBounce = pData.LastRealBounceNormal
        and (now - (pData.LastRealBounceFrame or -99)) <= math.ceil(18 * (player.Size / 10))
        and pData.LastRealBounceNormal:Dot(normal) > 0.5

    if sameWallAsLastBounce then
        player.Position = prevPos + pData.LastRealBounceNormal * sizeMargin
        return true
    end

    local reflectVel = ReflectVelocity(prevVel, normal, 1)
    player.Velocity = reflectVel
    player.Position = prevPos + normal * (sizeMargin)

    flingParams.FlingDirection = reflectVel:Normalized()
    flingParams.FlingVel = reflectVel

    pData.LastRealBounceNormal = normal
    pData.LastRealBounceFrame = now

    Isaac.RunCallback(TRCallbacks.STRIKE_HIT_GRID, player, grid, flingParams)

    return true
end)