local Maths = {}

---Expontential function
---@param number number
---@param coeffcient number
---@param power number
---@return integer
function Maths.exp(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

---Converts seconds to game update frames
---@param seconds number
---@return number
function Maths.SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

---Logaritmic function
---@param x number
---@param base number
---@return number?
function Maths.Log(x, base)
    if x <= 0 or base <= 1 then
        return nil
    end

    local logNatural = math.log(x)
    local logBase = math.log(base)

    return logNatural / logBase
end

--- Rounds a number to the closest number of decimal places given.
--- Defaults to rounding to the nearest integer. 
--- (from Library of Isaac)
---@param n number
---@param decimalPlaces integer? @Default: 0
---@return number
function Maths.Round(n, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10^(decimalPlaces or 0)
	return math.floor(n * mult + 0.5) / mult
end

--- Helper function to clamp a number into a range (from Library of Isaac).
---@param a number
---@param min number
---@param max number
---@return number
function Maths.Clamp(a, min, max)
	if min > max then
		local temp = min
		min = max
		max = temp
	end

	return math.max(min, math.min(a, max))
end

---Function used to calculate Tainted Edith's hop height
---@generic growth, offset, curve
---@param const number
---@param var number
---@param params { growth: number, offset: number, curve: number }
---@return number
function Maths.HopHeightCalc(const, var, params)
    -- Validaciones estrictas
    assert(type(var) == "number", "var should be a number")
    assert(var >= 0 and var <= 100, "var should be a number between 0 and 100")

    -- Caso exclusivo cuando variable es exactamente 100
    if var == 100 then return const end

	local limit = 0.999999
    local growth = math.max(0, params.growth or 1) 
    local offset = Maths.Clamp(params.offset or 0, -1, 1) 
    local curve = math.max(0.1, math.min(params.curve or 1, 10))
	local formula = (var / 100) ^ curve * growth + offset
    local progresion = math.min(formula, limit)

    -- Resultado final garantizado que nunca iguala la constante
    return const * Maths.Clamp(progresion, 0, limit)
end

return Maths