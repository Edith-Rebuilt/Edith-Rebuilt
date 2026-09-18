local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local Player = modules.PLAYER


local function ShootFireRockTears(player, rng)
	local FireRock = {
		variant = TearVariant.ROCK,
		position = player.Position,
		velocity = rng:RandomVector():Resized(20) + player.Velocity,
		apply = function(tear)
			tear:AddTearFlags(TearFlags.TEAR_BURN)
			Helpers.ChangeColor(tear, 1, 0.2, 0)
		end,
	}

    local judasBirthrightAdd = Player.IsJudasWithBirthright(player) and 4 or 0

	Helpers.ShootArchedTear(player, rng, 8 + judasBirthrightAdd, 12 + judasBirthrightAdd, FireRock)
end

---@param player EntityPlayer
---@param ring integer
local function SpawnRockRing(player, ring)
    local dist = ring * 20
    for rock = 1, 6 do
        CustomShockwaveAPI:SpawnCustomCrackwave(
            player.Position,
            player,
            dist,
            rock * (360 / 6),
            1,
            ring,
            player.Damage / 2
        )
    end
end

---@param player EntityPlayer
local function RockWavesRing(player)
    SpawnRockRing(player, 1)
    SpawnRockRing(player, 2)
    if Player.IsJudasWithBirthright(player) then
        SpawnRockRing(player, 3)
    end
end

---@param rng RNG
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player)
	ShootFireRockTears(player, rng)
	RockWavesRing(player)

	return true
end, items.COLLECTIBLE_DIVINE_WRATH)