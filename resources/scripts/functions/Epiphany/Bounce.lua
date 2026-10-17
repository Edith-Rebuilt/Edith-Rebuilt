--[[
    Módulo BOUNCE (mod.Modules.BOUNCE) - Rebotes del Fling de TR. Edith.

    Este módulo NO registra callbacks. El script del personaje debe:
      1) MC_PRE_PLAYER_UPDATE        -> Bounce.SnapshotMotion(player)
      2) MC_PRE_PLAYER_GRID_COLLISION -> Bounce.ResolveGridCollision(player, flingParams, grid)
      3) Al golpear un enemigo        -> Bounce.TriggerEnemyBounce(player, flingParams, ent, hash)

    DEBUG = true imprime logs en la consola de Isaac (~).
]]

local mod = EdithRebuilt

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

-------------------------------------------------------------------------------
-- UTILIDADES
-------------------------------------------------------------------------------
---Resuelto al llamar (no al cargar) para no depender del orden de carga de módulos.
---@param player EntityPlayer
---@return table
local function GetData(player)
    return mod.DataHolder.GetEntityData(player)
end

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
    local pData = GetData(player)
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
---Las puertas abiertas no cuentan como colisión.
---@param grid GridEntity
---@return boolean
local function IsPassableGrid(grid)
    local door = grid:ToDoor()
    return door ~= nil and door:IsOpen()
end

---Normal de impacto contra la celda: swept test, con fallback por diferencia de posición.
---@param prevPos Vector
---@param prevVel Vector
---@param grid GridEntity
---@param playerSize number
---@return Vector
local function ComputeBounceNormal(prevPos, prevVel, grid, playerSize)
    local half = GRID_SIZE / 2 + playerSize
    local center = grid.Position
    local halfExtent = Vector(half, half)

    local _, normal = RaySweptAABBIntersect(prevPos, prevVel:Normalized(), center - halfExtent, center + halfExtent)
    if normal then return normal end

    local diff = prevPos - center
    if math.abs(diff.X) > math.abs(diff.Y) then
        return Vector(diff.X > 0 and 1 or -1, 0)
    end
    return Vector(0, diff.Y > 0 and 1 or -1)
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
    if not grid or IsPassableGrid(grid) then return Result.IGNORED end

    local pData = GetData(player)
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

    local pData = GetData(player)
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