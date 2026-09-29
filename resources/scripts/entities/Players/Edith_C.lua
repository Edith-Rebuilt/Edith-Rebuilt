local mod = EdithRebuilt

local enums = mod.Enums

local utils = enums.Utils
local tables = enums.Tables
local Trenums = enums.Epiphany
local misc = enums.Misc

local game = utils.Game
local sfx = utils.SFX
local Room = utils.Room

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
    menuGraphics = "gfx/Epiphany/ui/menu_opensauce.anm2", -- Character menu graphics (portrait, text) (REQUIRED)
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

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local flingParams = params(player)

    flingParams.Cooldown = math.max(flingParams.Cooldown - 1, 0)
    if flingParams.IsFlinging then
        flingParams.FlingDuration = math.max(flingParams.FlingDuration - 1, 0)
    end

    local speed = player.MoveSpeed - 1

    ChargeFling(player, 0.025 + (0.025 * (speed * speed)))
end)

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerFling(player, flingParams)
    if flingParams.IsFlinging then return end

    local charge = TREdithMod.GetFlingBurstCharge(player, false)

    flingParams.IsFlinging = true
    flingParams.FlingDirection = TRTarget.GetEdithTargetDirection(player)
    flingParams.FlingDuration = math.ceil((45 * charge) * Player.GetPlayerRange(player) / 9)
    flingParams.FlingVel = flingParams.FlingDirection * 15 * charge

    TRTarget.RemoveEdithTarget(player)
end

local puffSize = Vector(0.6, 0.6)

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function TriggerBurst(player, flingParams)
    if flingParams.FlingStaticCharge <= 0 then return end
    if flingParams.Cooldown > 0 then return end

    local charge = TREdithMod.GetFlingBurstCharge(player, true)

    game:ShakeScreen(5 + math.ceil(4 * charge))

    local Capsule = Capsule(player.Position, Vector.One, 0, 50)
    local cloud = StatusEffects.SpawnSpicePuff(player, RNG(Random()))

    cloud.Color = Color(1, 1, 1, 1, 0.3, 0.3, 0.3)
    cloud.SpriteScale = puffSize + (puffSize / 2) * charge

    for _, ent in ipairs(Isaac.FindInCapsule(Capsule, EntityPartition.ENEMY | EntityPartition.BULLET)) do
        Helpers.TriggerPush(ent, player, 50 * TEdithMod.HopCurve(charge))

        if Helpers.IsEnemy(ent) then
            data(ent).HitStunDuration = 8 + math.ceil(5 * TEdithMod.HopCurve(charge))
        end
    end

    player:SetMinDamageCooldown(30)

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

---@param velocity Vector
---@param normal Vector
---@param restitution number
---@return Vector
local function ReflectVelocity(velocity, normal, restitution)
    restitution = restitution or 1
    local d = velocity:Dot(normal)
    return (velocity - normal * (2 * d)) * restitution
end

-- Intersección de un segmento (rayo) contra un círculo (obstáculo)
-- Devuelve t (0-1) del punto de impacto en el segmento, o nil si no choca
local function RaySphereIntersect(origin, dir, center, radius)
    local m = origin - center
    local b = m:Dot(dir)
    local c = m:Dot(m) - radius * radius
    if c > 0 and b > 0 then return nil end -- va alejándose, no choca

    local discr = b * b - c
    if discr < 0 then return nil end -- no intersecta

    local t = -b - math.sqrt(discr)
    if t < 0 then t = 0 end
    return t
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
local function ManageTREdithBounce(player, flingParams)
    if not flingParams.IsFlinging then return end

    local pos = player.Position
    local vel = player.Velocity
    local speed = vel:Length()
    if speed < 0.01 then return end

    local dir = vel:Normalized()
    local playerRadius = player.Size

    local bestT = 1 -- normalizado, 1 = llega sin chocar
    local bestNormal

    -- 1) Chequear límites del cuarto
    local topLeft = Room:GetTopLeftPos()
    local bottomRight = Room:GetBottomRightPos()
    local nextPos = pos + vel

    local hitX, hitY = false, false
    local normalX, normalY = Vector(0,0), Vector(0,0)
    local tX, tY = bestT, bestT

    if nextPos.X - playerRadius <= topLeft.X then
        tX = (topLeft.X + playerRadius - pos.X) / vel.X
        if tX >= 0 and tX < bestT then hitX, normalX = true, Vector(1, 0) end
    elseif nextPos.X + playerRadius >= bottomRight.X then
        tX = (bottomRight.X - playerRadius - pos.X) / vel.X
        if tX >= 0 and tX < bestT then hitX, normalX = true, Vector(-1, 0) end
    end

    if nextPos.Y - playerRadius <= topLeft.Y then
        tY = (topLeft.Y + playerRadius - pos.Y) / vel.Y
        if tY >= 0 and tY < bestT then hitY, normalY = true, Vector(0, 1) end
    elseif nextPos.Y + playerRadius >= bottomRight.Y then
        tY = (bottomRight.Y - playerRadius - pos.Y) / vel.Y
        if tY >= 0 and tY < bestT then hitY, normalY = true, Vector(0, -1) end
    end

    local cornerTolerance = 0.1 -- ajustable: qué tan "al mismo tiempo" cuentan como esquina

    if hitX and hitY and math.abs(tX - tY) < cornerTolerance then
        bestT = math.min(tX, tY)
        bestNormal = (normalX + normalY):Normalized()
    elseif hitX and (not hitY or tX < tY) then
        bestT, bestNormal = tX, normalX
    elseif hitY then
        bestT, bestNormal = tY, normalY
    end

    -- 2) Chequear grid entities (rocas, muros de grilla, obstáculos sólidos)
    local gridSize = 40
    local steps = math.ceil(speed)

    for i = 1, steps do
        local samplePos = pos + dir * (speed * i / steps)
        local gridEntity = Room:GetGridEntityFromPos(samplePos)

        if not gridEntity then goto continue end

        local collClass = gridEntity.CollisionClass

        if collClass == GridCollisionClass.COLLISION_NONE then goto continue end        

        local cellCenter = gridEntity.Position
        local combinedRadius = playerRadius + (gridSize / 2)
        local t = RaySphereIntersect(pos, dir, cellCenter, combinedRadius)

        if not t then goto continue end

        local tNorm = t / speed

        if not (tNorm >= 0 and tNorm < bestT) then goto continue end

        local impactPoint = pos + dir * t
        bestT = tNorm
        bestNormal = (impactPoint - cellCenter):Normalized()

        ::continue::
    end

    if bestNormal then
        sfx:Play(SoundEffect.SOUND_STONE_IMPACT)

        game:ShakeScreen(3 + math.ceil(5 * TREdithMod.GetFlingBurstCharge(player, false)))

        local impactPos = pos + vel * bestT
        local reflectVel = ReflectVelocity(vel, bestNormal, 0.99)

        player.Position = impactPos + bestNormal * 5
        flingParams.FlingDirection = reflectVel:Normalized()
        flingParams.FlingVel = reflectVel
    end
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

    ManageTREdithBounce(player, flingParams)
    KeepFling(player, flingParams)

    if target then
        EdithMod.TargetMovementManager(player, target, isMoving)
    end
end)

local function GetPlayerRenderPos(player)
	local playerpos = Room:WorldToScreenPosition(player.Position)
	if Helpers.IsMirrorWorld() then
		playerpos.X = (Helpers.GetScreenCenter().X * 2 - playerpos.X)
	end

	return playerpos
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	Player.ForEachPlayerType(function(player)
		if RoomTransition:GetTransitionMode() == 3 then return end

		local flingParams = params(player)   
		local playerData = data(player)
		local FlingCharge = flingParams.FlingStaticCharge

		if not FlingCharge then return end

        playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)

		local playerpos = GetPlayerRenderPos(player)

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

local baseDamage = 10

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