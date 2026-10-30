local mod = EdithRebuilt
local enums = mod.Enums

local PeppercornsID = enums.CollectibleType.COLLECTIBLE_PEPPERCORNS

local statusEffects = enums.EdithStatusEffects

local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local Maths = modules.MATHS
local StatusEffects = modules.STATUS_EFFECTS

local PEPPERCORNS_MIN_AMOUNT = 5
local PEPPERCORNS_MAX_AMOUNT = 8
local PEPPERCORNS_SPREAD_AMOUNT = 15
local PEPPERCORNS_COLOR = Color(0.8, 0.6, 0.6, 1)

local data = mod.DataHolder.GetEntityData

local SPRITE = Sprite()

-- Active item example
ThrowableItemLib:RegisterThrowableItem({
    ID = PeppercornsID,
    Type = ThrowableItemLib.Type.ACTIVE,
    Identifier = "MY_MOD_BIG_ROCK",
    ThrowFn = function (player, vec)
        local rng = player:GetCollectibleRNG(PeppercornsID)

        for _ = 1, rng:RandomInt(PEPPERCORNS_MIN_AMOUNT, PEPPERCORNS_MAX_AMOUNT) do
            local tear = player:FireTear(
                player.Position,
                (vec:Resized(player.ShotSpeed * 10) + RandomVector() * 3 + player:GetTearMovementInheritance(vec)):Rotated(rng:RandomInt(-PEPPERCORNS_SPREAD_AMOUNT, PEPPERCORNS_SPREAD_AMOUNT))
            )

            Helpers.ForceSaltTear(tear, true)

            tear.Scale = (tear.Scale * 0.75) * ModRNG.RandomFloat(rng, 0.9, 1.1)
            tear.Color = PEPPERCORNS_COLOR

            data(tear).Peppercorn = true
        end
    end,
    AnimateFn = function (player, state)
        if state ~= ThrowableItemLib.State.THROW then return end

        player:AnimatePickup(SPRITE, true, "HideItem")
        return true
    end
})

mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function(_, tear)
    if not data(tear).Peppercorn then return end

    local DustCloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.SMOKE_CLOUD,
        1,
        tear.Position,
        Vector.Zero,
        Helpers.GetPlayerFromTear(tear)
    ):ToEffect() ---@cast DustCloud EntityEffect

    DustCloud.Timeout = Maths.SecondsToFrames(5)
    DustCloud.SpriteScale = DustCloud.SpriteScale * tear.Scale
    DustCloud.Scale = DustCloud.Scale * tear.Scale
    DustCloud:Update()

    data(DustCloud).PepperCloud = true
end)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    if not data(effect).PepperCloud then return end

    effect.Color = PEPPERCORNS_COLOR

    local capsule = Capsule(effect.Position, Vector.One, 0, 40 * effect.Scale)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(ent) then goto continue end
        if StatusEffects.EntHasStatusEffect(ent, statusEffects.PEPPERED) then goto continue end

        StatusEffects.SetStatusEffect(statusEffects.PEPPERED, ent, 90, effect)

        ::continue::
    end
end, EffectVariant.SMOKE_CLOUD)