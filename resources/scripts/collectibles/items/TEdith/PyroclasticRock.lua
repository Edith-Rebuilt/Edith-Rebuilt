local mod = EdithRebuilt
local enums = mod.Enums

local utils = enums.Utils
local room = utils.Room
local game = utils.Game

local Helpers = mod.Modules.HELPERS

local PyroclasticRockID = enums.CollectibleType.COLLECTIBLE_PYROCLASTIC_ROCK

local PYROCLASTIC_ROCK_HEIGHT = 200
local PYROCLASTIC_ROCK_FALLSPEED = 12

---@param player EntityPlayer
---@param ent Entity
local function SpawnPyroclasticRock(player, ent)
    local Rock = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        enums.EffectVariant.EFFECT_PYROCLASTIC_ROCK,
        0,
        ent.Position,
        Vector.Zero,
        player
    )

    Rock.Color = Color.EmberFade

    JumpLib:TryJump(Rock, {
        Height = 0,
        Tags = "EdithRebuilt_PyroclasticRock"
    })

    JumpLib:SetHeight(Rock, PYROCLASTIC_ROCK_HEIGHT)
    JumpLib:SetSpeed(Rock, PYROCLASTIC_ROCK_FALLSPEED)
end

---@param player EntityPlayer
local function ChooseEntity(player)
    local rng = player:GetCollectibleRNG(PyroclasticRockID)
    local roomEnts = Isaac.GetRoomEntities()
    local roll = rng:RandomInt(#roomEnts + 1)
    local ent = roomEnts[roll]

    while not ent or not Helpers.IsEnemy(ent) do
        ent = roomEnts[rng:RandomInt(#roomEnts + 1)]
    end

    return ent
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not player:HasCollectible(PyroclasticRockID) then return end
    if room:IsClear() then return end
    if room:GetFrameCount() % 60 ~= 0 then return end

    SpawnPyroclasticRock(player, ChooseEntity(player))
end)

---@param entity any
---@param jumpData any
---@param pitfall any
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, entity, jumpData, pitfall)
    game:BombExplosionEffects(entity.Position, 100)
    entity:Remove()
end, {tag = "EdithRebuilt_PyroclasticRock"})