local mod = EdithRebuilt
local enums = mod.Enums
local trinket = enums.TrinketType
local data = mod.DataHolder.GetEntityData
local baseHeight = -23.45
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local RumblingPebble = {}

---@param rock GridEntityRock
---@param type GridEntityType
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, function(_, rock, type, _, source)
	if source.Type == 0 then return end

	local player = Helpers.GetPlayerFromRef(source)

	if not player then return end
	if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end
	if type == GridEntityType.GRID_ROCK_BOMB then return end

	local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)
	local trinketMult = player:GetTrinketMultiplier(trinket.TRINKET_RUMBLING_PEBBLE)
	local totalrocks = rng:RandomInt(2 + trinketMult, 4 + trinketMult)
	local shootDegree = 360 / totalrocks
	local rangemult = Player.GetPlayerRange(player) / 6.5

	for i = 1, totalrocks do
		local rockTear = player:FireTear(
			rock.Position, 
			Vector.One:Rotated((shootDegree + rng:RandomInt(-40, 40) * i)):Resized(10)
		)

		local FallSpeedVar = ModRNG.RandomFloat(rng, 0.8, 1.2)

		rockTear:AddTearFlags(player.TearFlags | TearFlags.TEAR_ROCK)
		rockTear.FallingAcceleration = ModRNG.RandomFloat(rng, 1.5, 2)
		rockTear.FallingSpeed = (-10 * rangemult) * FallSpeedVar
		rockTear.Height = baseHeight * rangemult
		rockTear.Scale = FallSpeedVar
		rockTear.CollisionDamage = 5.25 * rockTear.Scale

		data(rockTear).IsPebbleTear = true
	end
end)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
	local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end 
	if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end

	local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)

	if not ModRNG.RandomBoolean(rng) then return end

	Helpers.TurnTearToTerraTear(tear, rng)
	data(tear).IsPebbleTear = true
end)

---@param tear EntityTear
---@param grid GridEntity
function RumblingPebble:ShootTear(tear, _, grid)
	if not grid:ToRock() then return end
	if not data(tear).IsPebbleTear then return end

	grid:DestroyWithSource(false, EntityRef(Helpers.GetPlayerFromTear(tear)))
end
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_GRID_COLLISION, RumblingPebble.ShootTear)