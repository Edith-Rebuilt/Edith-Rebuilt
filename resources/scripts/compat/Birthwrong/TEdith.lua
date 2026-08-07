---@diagnostic disable: undefined-global
if not Birthwrong then return end

local mod = EdithRebuilt
local enums = mod.Enums
local ModRNG = mod.Modules.RNG
local room = enums.Utils.Room

local PROJ_PARAMS = {
    FIRE_WAVE_CHANCE  = 0.15,
    PROJ_HEIGHT_BASE  = -500,
    PROJ_FALLING_ACCEL = 5,
}

Birthwrong.registerDescription(enums.PlayerType.PLAYER_EDITH_B, "The sky breaks twice", "algo debe de hacer luego lo voy a pensar")

---@param position Vector
---@param rng RNG
local function SpawnProjectile(position, rng)
    local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_ROCK, 0, position, Vector.Zero, nil):ToProjectile() ---@cast proj EntityProjectile

    local fireFlag = ModRNG.RandomBoolean(rng, PROJ_PARAMS.FIRE_WAVE_CHANCE) and ProjectileFlags.FIRE_WAVE or ProjectileFlags.FIRE_SPAWN

    proj:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES | fireFlag)
    proj.Height = PROJ_PARAMS.PROJ_HEIGHT_BASE * ModRNG.RandomFloat(rng, 0.75, 1.25)
    proj.FallingAccel = PROJ_PARAMS.PROJ_FALLING_ACCEL * ModRNG.RandomFloat(rng, 0.75, 1.25)
    proj.Scale = ModRNG.RandomFloat(rng, 1, 3)
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH_B) then return end
    if player.FrameCount % 3 ~= 0 then return end

    SpawnProjectile(room:GetRandomPosition(0), player:GetCollectibleRNG(Birthwrong.birthwrongID))
end)