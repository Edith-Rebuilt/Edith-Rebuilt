--[[
    Módulo BOUNCE (mod.Modules.BOUNCE) - Rebotes del Fling de TR. Edith.

    Este módulo NO registra callbacks. El script del personaje debe:
      1) MC_PRE_PLAYER_UPDATE        -> Bounce.ResolveDoorCollision(player, flingParams)
                                        y DESPUÉS Bounce.SnapshotMotion(player)
      2) MC_PRE_PLAYER_GRID_COLLISION -> Bounce.ResolveGridCollision(player, flingParams, grid)
      3) Al golpear un enemigo        -> Bounce.TriggerEnemyBounce(player, flingParams, ent, hash)

    Las puertas NO pasan por el callback de grid: se detectan de forma predictiva
    (swept test contra cada puerta, abierta o cerrada) en ResolveDoorCollision.

    DEBUG = true imprime logs en la consola de Isaac (~).
]]

local mod = EdithRebuilt

local room = mod.Enums.Utils.Room

local data = mod.DataHolder.GetEntityData

local Bounce = {}

---@enum BounceResult
Bounce.Result = {
    IGNORED = 0,    -- no intervenimos: el motor resuelve la colisión normal
    SUPPRESSED = 1, -- cancelar la resolución del motor, sin rebote nuevo
    BOUNCED = 2,    -- rebote real aplicado: cancelar resolución y disparar STRIKE_HIT_GRID
}

local Result = Bounce.Result

-------------------------------------------------------------------------------
-- CONSTANTES
-------------------------------------------------------------------------------
local DEBUG = true

local GRID_SIZE = 40
local BASE_PLAYER_SIZE = 10
local BOUNCE_WINDOW_BASE = 18 -- frames de ventana "misma pared" con Size = BASE_PLAYER_SIZE
local MIN_SPEED = 0.01
local SAME_WALL_DOT = 0.5
local RESTITUTION = 1
local ENEMY_PUSH_MARGIN = 2
local DOOR_PUSH_MARGIN = 2

-------------------------------------------------------------------------------
-- UTILIDADES
-------------------------------------------------------------------------------

---@param tag string
---@param fmt string
local function Log(tag, fmt, ...)
    if not DEBUG then return end
    print(string.format("[%s f=%d] " .. fmt, tag, Isaac.GetFrameCount(), ...))
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

---Intersección rayo-caja. Devuelve t y la normal del lado por el que se entra.
---@param origin Vector
---@param dir Vector
---@param boxMin Vector
---@param boxMax Vector
---@return number? t
---@return Vector? normal
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

-------------------------------------------------------------------------------
-- ESTADO PREVIO
-------------------------------------------------------------------------------
---Guarda posición y velocity ANTES de que el motor mueva al jugador este frame.
---@param player EntityPlayer
function Bounce.SnapshotMotion(player)
    local pData = data(player)
    pData.PrevPosition = Vector(player.Position.X, player.Position.Y)
    pData.PrevVelocity = Vector(player.Velocity.X, player.Velocity.Y)
end

---@param player EntityPlayer
---@param pData table
---@return Vector prevPos
---@return Vector prevVel
local function GetPreviousState(player, pData)
    return pData.PrevPosition or player.Position, pData.PrevVelocity or player.Velocity
end

-------------------------------------------------------------------------------
-- REFLEXIÓN COMPARTIDA
-------------------------------------------------------------------------------
---Única función que refleja la velocity (grid y enemigos).
---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@param vel Vector
---@param normal Vector
local function ApplyReflection(player, flingParams, vel, normal)
    local reflectVel = ReflectVelocity(vel, normal, RESTITUTION)

    player.Velocity = reflectVel
    flingParams.FlingDirection = reflectVel:Normalized()
    flingParams.FlingVel = reflectVel
end

-------------------------------------------------------------------------------
-- GRID
-------------------------------------------------------------------------------
---Las puertas se resuelven aparte (ResolveDoorCollision), no por el callback de grid.
---@param grid GridEntity
---@return boolean
local function IsDoor(grid)
    return grid:ToDoor() ~= nil
end

---¿Hay otra celda sólida pegada a esta cara? Si la hay, la cara es interna y no se puede golpear.
---@param grid GridEntity
---@param normal Vector
---@return boolean
local function IsFaceBlocked(grid, normal)
    local neighbor = Game():GetRoom():GetGridEntityFromPos(grid.Position + normal * GRID_SIZE)
    if not neighbor then return false end
    if neighbor:ToDoor() then return true end

    local collClass = neighbor.CollisionClass
    return collClass ~= GridCollisionClass.COLLISION_NONE and collClass ~= GridCollisionClass.COLLISION_PIT
end

---Normal de impacto contra la celda: swept test, con fallback por diferencia de posición.
---Si el swept test cae en una cara interna (celda vecina sólida), se usa la normal del otro eje.
---@param prevPos Vector
---@param prevVel Vector
---@param grid GridEntity
---@param playerSize number
---@return Vector
local function ComputeBounceNormal(prevPos, prevVel, grid, playerSize)
    local dir = prevVel:Normalized()
    local half = GRID_SIZE / 2 + playerSize
    local center = grid.Position
    local halfExtent = Vector(half, half)

    local _, normal = RaySweptAABBIntersect(prevPos, dir, center - halfExtent, center + halfExtent)

    if not normal then
        local diff = prevPos - center
        if math.abs(diff.X) > math.abs(diff.Y) then
            normal = Vector(diff.X > 0 and 1 or -1, 0)
        else
            normal = Vector(0, diff.Y > 0 and 1 or -1)
        end
    end

    if not IsFaceBlocked(grid, normal) then return normal end

    local altNormal = normal.X ~= 0
        and Vector(0, dir.Y > 0 and -1 or 1)
        or Vector(dir.X > 0 and -1 or 1, 0)

    if IsFaceBlocked(grid, altNormal) then return normal end

    Log("GRID", "CARA_INTERNA n=(%.0f,%.0f) -> n=(%.0f,%.0f)", normal.X, normal.Y, altNormal.X, altNormal.Y)

    return altNormal
end

---¿Esta colisión es la misma pared (celda vecina) que el último rebote real?
---@param pData table
---@param normal Vector
---@param now integer
---@param playerSize number
---@return boolean
local function IsSameWallAsLastBounce(pData, normal, now, playerSize)
    local lastNormal = pData.LastRealBounceNormal
    if not lastNormal then return false end

    local window = math.ceil(BOUNCE_WINDOW_BASE * (playerSize / BASE_PLAYER_SIZE))
    local elapsed = now - (pData.LastRealBounceFrame or -99)

    return elapsed <= window and lastNormal:Dot(normal) > SAME_WALL_DOT
end

---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@param pData table
---@param prevPos Vector
---@param prevVel Vector
---@param normal Vector
---@param now integer
local function ApplyGridBounce(player, flingParams, pData, prevPos, prevVel, normal, now)
    ApplyReflection(player, flingParams, prevVel, normal)
    player.Position = prevPos + normal * player.Size

    pData.LastRealBounceNormal = normal
    pData.LastRealBounceFrame = now
    pData.LastBounceFrame = now -- compartido con el rebote contra enemigos
end

---Llamar desde MC_PRE_PLAYER_GRID_COLLISION (solo si IsFlinging).
---Si devuelve IGNORED, no retornar nada en el callback; en cualquier otro caso, retornar true.
---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@param grid GridEntity
---@return BounceResult
function Bounce.ResolveGridCollision(player, flingParams, grid)
    if not grid or IsDoor(grid) then return Result.IGNORED end

    local pData = data(player)
    local now = Isaac.GetFrameCount()

    -- Un solo procesamiento por frame; si ya rebotamos contra un enemigo este frame, no reflejar de nuevo
    if pData.LastProcessedFrame == now or pData.LastBounceFrame == now then
        Log("GRID", "SUPPRESSED (ya procesado este frame)")
        return Result.SUPPRESSED
    end
    pData.LastProcessedFrame = now

    local prevPos, prevVel = GetPreviousState(player, pData)
    if prevVel:Length() < MIN_SPEED then return Result.IGNORED end

    local normal = ComputeBounceNormal(prevPos, prevVel, grid, player.Size)

    if IsSameWallAsLastBounce(pData, normal, now, player.Size) then
        player.Position = prevPos + pData.LastRealBounceNormal * player.Size
        Log("GRID", "SAME_WALL n=(%.0f,%.0f)", normal.X, normal.Y)
        return Result.SUPPRESSED
    end

    Log("GRID", "REFLECT prevPos=(%.1f,%.1f) prevVel=(%.2f,%.2f) n=(%.0f,%.0f)",
        prevPos.X, prevPos.Y, prevVel.X, prevVel.Y, normal.X, normal.Y)

    ApplyGridBounce(player, flingParams, pData, prevPos, prevVel, normal, now)

    return Result.BOUNCED
end

-------------------------------------------------------------------------------
-- PUERTAS (detección predictiva, sin callback de grid)
-------------------------------------------------------------------------------
-- Normal hacia el interior de la sala según el lado de la puerta (slot % 4):
-- izquierda, arriba, derecha, abajo
local DOOR_NORMALS = { [0] = Vector(1, 0), Vector(0, 1), Vector(-1, 0), Vector(0, -1) }

---Puerta más cercana contra la que choca el movimiento de este frame.
---Abiertas o cerradas: durante el Fling ninguna puerta se puede atravesar.
---Solo cuenta si el jugador se mueve hacia la puerta (vel · normal < 0).
---@param pos Vector
---@param vel Vector
---@param playerSize number
---@return GridEntityDoor? door
---@return Vector? normal
---@return number? t distancia hasta el impacto
local function FindDoorHit(pos, vel, playerSize)
    local dir = vel:Normalized()
    local half = GRID_SIZE / 2 + playerSize
    local halfExtent = Vector(half, half)

    local bestDoor, bestNormal, bestT = nil, nil, vel:Length()

    for slot = 0, DoorSlot.DOWN1 do
        local door = room:GetDoor(slot)

        if not door then goto continue end

        local normal = DOOR_NORMALS[slot % 4]

        if vel:Dot(normal) >= 0 then goto continue end

        local center = door.Position
        local t = RaySweptAABBIntersect(pos, dir, center - halfExtent, center + halfExtent)

        if not t then goto continue end
        if t > bestT then goto continue end

        bestDoor, bestNormal, bestT = door, normal, t
        ::continue::
    end

    return bestDoor, bestNormal, bestT
end

---Llamar al inicio de MC_PRE_PLAYER_UPDATE (antes de SnapshotMotion) mientras haya Fling.
---Refleja contra cualquier puerta (abierta o cerrada) ANTES de que el motor mueva al jugador.
---Devuelve la puerta contra la que rebotó, o nil si no hubo rebote.
---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@return GridEntityDoor?
function Bounce.ResolveDoorCollision(player, flingParams)
    local pData = data(player)
    local now = Isaac.GetFrameCount()
    if pData.LastBounceFrame == now then return nil end

    local vel = player.Velocity
    if vel:Length() < MIN_SPEED then return nil end

    local door, normal, t = FindDoorHit(player.Position, vel, player.Size)
    if not (door and normal and t) then return nil end

    Log("DOOR", "REFLECT vel=(%.2f,%.2f) n=(%.0f,%.0f) t=%.1f", vel.X, vel.Y, normal.X, normal.Y, t)

    ApplyReflection(player, flingParams, vel, normal)
    player.Position = player.Position + vel:Normalized() * t + normal * DOOR_PUSH_MARGIN

    pData.LastRealBounceNormal = normal
    pData.LastRealBounceFrame = now
    pData.LastBounceFrame = now

    return door
end

-------------------------------------------------------------------------------
-- ENEMIGOS
-------------------------------------------------------------------------------
---Normal radial (centro del enemigo hacia el jugador) y penetración.
---@param player EntityPlayer
---@param ent Entity
---@return Vector? normal
---@return number penetration
local function ComputeEnemyNormal(player, ent)
    local diff = player.Position - ent.Position
    local dist = diff:Length()
    if dist < MIN_SPEED then return nil, 0 end

    return diff:Normalized(), math.max(player.Size + ent.Size - dist, 0)
end

---Llamar tras golpear a un enemigo durante el Fling.
---@param player EntityPlayer
---@param flingParams TREdithFlingStrikeParams
---@param ent Entity
---@param hash integer
function Bounce.TriggerEnemyBounce(player, flingParams, ent, hash)
    flingParams.StruckEntities[hash] = nil
    if flingParams.StrikeDamage > ent.HitPoints then return end

    local pData = data(player)
    local now = Isaac.GetFrameCount()
    if pData.LastBounceFrame == now then
        Log("ENEMY", "SKIP (ya rebotó este frame)")
        return
    end

    local vel = player.Velocity
    if vel:Length() < MIN_SPEED then return end

    local normal, penetration = ComputeEnemyNormal(player, ent)
    if not normal then return end

    Log("ENEMY", "REFLECT vel=(%.2f,%.2f) n=(%.2f,%.2f) pen=%.1f",
        vel.X, vel.Y, normal.X, normal.Y, penetration)

    ApplyReflection(player, flingParams, vel, normal)
    player.Position = player.Position + normal * (penetration + ENEMY_PUSH_MARGIN)

    pData.LastBounceFrame = now
end

return Bounce