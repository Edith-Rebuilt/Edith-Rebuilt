local mod = EdithRebuilt
local enums = mod.Enums
local SubTypes = enums.SubTypes
local Creeps = {}
local data = mod.DataHolder.GetEntityData

---Spawns Salt Creep
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
---@param gibAmount integer
---@param gibSpeed number
---@param spawnType SaltTypes
---@param inheritParentColor? boolean
---@param inheritParentVel? boolean
---@param color Color? Use this param to override salt's color
function Creeps.SpawnSaltCreep(parent, position, damage, timeout, gibAmount, gibSpeed, spawnType, inheritParentColor, inheritParentVel, color)
	gibAmount = gibAmount or 0

	local modules = mod.Modules
	local salt = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		SubTypes.SALT_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect() ---@cast salt EntityEffect

	local saltColor = inheritParentColor and parent.Color or Color.Default
	local timeOutSeconds = modules.MATHS.SecondsToFrames(timeout) or 30

	salt.CollisionDamage = damage or 0
	salt.Color = color or saltColor
	salt:SetTimeout(timeOutSeconds)

	if gibAmount > 0 then
		local gibColor = color or (inheritParentColor and Color.Default or nil)
		modules.HELPERS.SpawnSaltGib(parent, gibAmount, gibSpeed, gibColor, inheritParentVel)
	end

	local saltdata = data(salt)

	saltdata.SpawnType = saltdata.SpawnType or 0
	saltdata.SpawnType = modules.BIT_MASK.AddBitFlags(saltdata.SpawnType, spawnType)
end

---@param salt EntityEffect
---@return SaltTypes
function Creeps.GetSaltSpawnType(salt)
---@diagnostic disable-next-line: return-type-mismatch
	return data(salt).SpawnType or 0
end

---Spawns Pepper creep, used for Pepper Grinder
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
function Creeps.SpawnPepperCreep(parent, position, damage, timeout)
	local pepper = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.PEPPER_CREEP,
		position,
		Vector.Zero,
		parent
	):ToEffect() ---@cast pepper EntityEffect

	pepper.CollisionDamage = damage or 0
	pepper:SetTimeout(mod.Modules.MATHS.SecondsToFrames(timeout) or 30)
end

---Spawns Pepper creep, used for Pepper Grinder
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
function Creeps.SpawnCinderCreep(parent, position, damage, timeout)
	local Cinder = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.CINDER_CREEP,
		position,
		Vector.Zero,
		parent
	):ToEffect() ---@cast Cinder EntityEffect

	Cinder.CollisionDamage = damage or 0
	Cinder:SetTimeout(mod.Modules.MATHS.SecondsToFrames(timeout) or 30)

	return Cinder
end

---Spawns Pepper creep, used for Pepper Grinder
---@param parent Entity
---@param position Vector
---@param timeout number
function Creeps.SpawnOreganoCreep(parent, position, timeout)
	local pepper = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.OREGANO_CREEP,
		position,
		Vector.Zero,
		parent
	):ToEffect() ---@cast pepper EntityEffect

	pepper.CollisionDamage = 0
	pepper:SetTimeout(mod.Modules.MATHS.SecondsToFrames(timeout) or 30)
end

---Custom black powder spawn (Used for Edith's black powder stomp synergy)
---@param parent Entity
---@param quantity number
---@param position Vector
---@param distance number
function Creeps.SpawnBlackPowder(parent, quantity, position, distance)
	quantity = quantity or 20
	local degrees = 360 / quantity
	local blackPowder
	for i = 1, quantity do
		blackPowder = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_BLACKPOWDER, 
			0, 
			position + Vector(0, distance or 60):Rotated(degrees * i),
			Vector.Zero, 
			parent
		)
		if not blackPowder then return end
		data(blackPowder).CustomSpawn = true
	end

	local Pentagram = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.PENTAGRAM_BLACKPOWDER, 
		0, 
		position, 
		Vector.Zero, 
		nil
	):ToEffect() ---@cast Pentagram EntityEffect

	Pentagram.Scale = distance + distance / 2
	Pentagram:Update()
end

return Creeps