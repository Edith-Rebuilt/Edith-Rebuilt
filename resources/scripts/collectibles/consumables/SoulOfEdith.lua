local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local sounds = enums.SoundEffect
local utils = enums.Utils
local sfx = utils.SFX
local rng = utils.RNG
local modules = mod.Modules
local Helpers = modules.HELPERS
local Creep = modules.CREEPS
local Land = modules.LAND
local ModRNG = modules.RNG
local EdithMod = modules.EDITH
local data = mod.DataHolder.GetEntityData
local SoulOfEdithJumpTag = enums.Tables.JumpTags.SoulOfEdith
local damageBase = 13.5

mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, function (_, _, player)
	modules.JUMP.InitEdithJump(player, SoulOfEdithJumpTag, false)
    sfx:Play(sounds.SOUND_SOUL_OF_EDITH)
end, card.CARD_SOUL_EDITH)

local function SpawnSaltTears(player)
	for _ = 1, rng:RandomInt(18, 36) do 
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, Isaac.GetRandomPosition(), Vector.Zero, player):ToTear()
		if not tear then return end
		tear.CollisionDamage = tear.CollisionDamage * 1.2
        tear.Height = -600 * ModRNG.RandomFloat(rng, 0.9, 1.1)
		tear.FallingSpeed = 4 * ModRNG.RandomFloat(rng, 0.6, 1.8)
        tear.FallingAcceleration = 2.5 * ModRNG.RandomFloat(rng, 0.6, 1.8)
		tear:AddTearFlags(TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)
		Helpers.ForceSaltTear(tear, false)
		data(tear).IsSoulOfEdithTear = true
    end
end

---@param player EntityPlayer
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player, jumpData)
	local stompParams = EdithMod.GetJumpStompParams(player)

	stompParams.Damage = ((damageBase + player.Damage) / 1.5)
	stompParams.Radius = 50
	stompParams.Knockback = 20

	Land.EdithStomp(player, stompParams, true)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), Color(1, 1, 1, 0), jumpData)

    SpawnSaltTears(player)
end, { tag = SoulOfEdithJumpTag })

mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function(_, tear)
	if not data(tear).IsSoulOfEdithTear then return end

	Creep.SpawnSaltCreep(tear, tear.Position, 3, 5, 5, 3, enums.SaltTypes.SALT_SHAKER, false, false)
end)