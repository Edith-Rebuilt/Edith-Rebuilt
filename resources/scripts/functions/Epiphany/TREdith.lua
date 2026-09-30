local mod = EdithRebuilt

local data = mod.DataHolder.GetEntityData

local enums = mod.Enums
local utils = enums.Utils

local room = utils.Room
-- local


local TRenums = enums.Epiphany
local TRCallbacks = TRenums.Callbacks

TREdith = {}

---@class TREdithFlingStrikeParams
---@field StrikeDamage number
---@field StrikeRadius number
---@field StrikeKnockback number
---@field FlingStaticCharge number
---@field FlingMoveCharge number
---@field FlingDirection Vector
---@field FlingStrength number
---@field FlingDuration integer
---@field FlingVel Vector
---@field BurstRadius number
---@field BurstKnockback number
---@field Cooldown integer
---@field IsFlinging boolean
---@field ShovedEntities Entity[]

local function NewFlingShoveParams()
	return {
		StrikeDamage = 0,
		StrikeRadius = 0,
		StrikeKnockback = 0,
		FlingStaticCharge = 0,
		FlingMoveCharge = 0,
		FlingDirection = Vector.Zero,
		FlingStrength = 10,
		FlingDuration = 0,
		FlingVel = Vector.Zero,
		BurstRadius = 0,
		BurstKnockback = 0,
		Cooldown = 0,
		IsFlinging = false,
		ShovedEntities = {},
	} --[[@as TREdithFlingStrikeParams]]
end

---@param player EntityPlayer
function TREdith.GetFlingStrikeParams(player)
	local playerData = data(player)
    playerData.JumpParams = playerData.JumpParams or NewFlingShoveParams()

    return playerData.JumpParams
end

---@param player EntityPlayer
function TREdith.IsTREdith(player)
	return player:GetPlayerType() == mod.Enums.Epiphany.PlayerType.PLAYER_EDITH_C
end

---@param current number
---@param amount number
---@return number
local function AddCharge(current, amount)
    return mod.Modules.MATHS.Clamp(current + amount, 0, 1)
end

---@param player EntityPlayer
---@param charge number
function TREdith.AddFlingCharge(player, charge)
    local flingParams = TREdith.GetFlingStrikeParams(player)

    flingParams.FlingMoveCharge = AddCharge(flingParams.FlingMoveCharge, charge)
    flingParams.FlingStaticCharge = AddCharge(flingParams.FlingStaticCharge, charge)
end

---@param player EntityPlayer
---@param Static boolean --- `true` to get Static charge, otherwise gets Move charge 
---@return number
function TREdith.GetFlingBurstCharge(player, Static)
	local flingParams = TREdith.GetFlingStrikeParams(player)
	local charge = Static and flingParams.FlingStaticCharge or flingParams.FlingMoveCharge

	return charge
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
function TREdith.ManageTREdithBounce(player, flingParams)
    if not flingParams.IsFlinging then return end

    local pos = player.Position
    local vel = player.Velocity
    local speed = vel:Length()
    if speed < 0.01 then return end

    local dir = vel:Normalized()
    local playerRadius = player.Size

    local bestT = 1 
    local bestNormal

    local topLeft = room:GetTopLeftPos()
    local bottomRight = room:GetBottomRightPos()
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

    local cornerTolerance = 0.1 

    if hitX and hitY and math.abs(tX - tY) < cornerTolerance then
        bestT = math.min(tX, tY)
        bestNormal = (normalX + normalY):Normalized()
    elseif hitX and (not hitY or tX < tY) then
        bestT, bestNormal = tX, normalX
    elseif hitY then
        bestT, bestNormal = tY, normalY
    end

    local gridSize = 40
    local steps = math.ceil(speed)

	local hitGrid ---@cast hitGrid GridEntity

    for i = 1, steps do
        local samplePos = pos + dir * (speed * i / steps)
        local gridEntity = room:GetGridEntityFromPos(samplePos)

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

		hitGrid = gridEntity

        ::continue::
    end

    if bestNormal then
        local impactPos = pos + vel * bestT
        local reflectVel = ReflectVelocity(vel, bestNormal, 0.99)
		
        player.Position = impactPos + bestNormal * 5
        flingParams.FlingDirection = reflectVel:Normalized()
        flingParams.FlingVel = reflectVel

		Isaac.RunCallback(TRCallbacks.STRIKE_HIT_GRID, player, hitGrid, flingParams)
    end
end

return TREdith