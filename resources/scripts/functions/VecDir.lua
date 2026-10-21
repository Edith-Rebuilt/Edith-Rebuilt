local mod = EdithRebuilt
local VecDir = {}

local DIRECTION_BY_QUADRANT = {
    [0] = Direction.RIGHT,
    [1] = Direction.DOWN,
    [2] = Direction.LEFT,
    [3] = Direction.UP,
}

--- Convierte un ángulo en grados a su `Direction` correspondiente (From Library of Isaac, tweaked a bit)
---@param angleDegrees number
---@return Direction
function VecDir.AngleToDirection(angleDegrees)
    return DIRECTION_BY_QUADRANT[math.floor(((angleDegrees + 45) % 360) / 90)]
end

--- Returns a direction corresponding to the direction the provided vector is pointing (from Library of Isaac)
---@param vector Vector
---@return Direction
function VecDir.VectorToDirection(vector)
	return VecDir.AngleToDirection(vector:GetAngleDegrees())
end

---Helper function to check if two vectors are exactly equal (from Library).
---@param v1 Vector
---@param v2 Vector
---@return boolean
function VecDir.VectorEquals(v1, v2)
    return v1.X == v2.X and v1.Y == v1.Y
end

local DEAD_ZONE = 0.3

---@param negative number
---@param positive number
---@return number
local function GetAxisValue(negative, positive)
    if negative > DEAD_ZONE then return -negative end
    if positive > DEAD_ZONE then return positive end
    return 0
end

---Target/Arrow movement manager
---@param input table
---@param resizer? number
---@return Vector
function VecDir.GetMovementVector(input, resizer)
    local mirrorMult = mod.Modules.HELPERS.IsMirrorWorld() and -1 or 1
    local x = GetAxisValue(input.left, input.right) * mirrorMult
    local y = GetAxisValue(input.up, input.down)
	local vec = Vector(x, y):Normalized()

	if resizer then
		vec:Resize(resizer)
	end

    return vec
end

return VecDir