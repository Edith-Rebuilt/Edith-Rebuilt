local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType

local modules = mod.Modules
local Helpers = modules.HELPERS

local data = mod.DataHolder.GetEntityData

return {
    {
        ---@param ent Entity
        ---@param amount number
        ---@param flags DamageFlag
        ---@param source EntityRef
        func = function (_, ent, amount, flags, source)
            local player = Helpers.GetPlayerFromRef(source)

            if not player then return end
            if not player:HasCollectible(items.COLLECTIBLE_SODIUM_SULFATE) then return end

            local entData = data(ent)

            entData.SulfateHits = entData.SulfateHits or 0
            entData.SulfateHits = entData.SulfateHits + 1

            local maxHitsToIrritate = ent:IsBoss() and 10 or 3

            if entData.SulfateHits < maxHitsToIrritate then return end

            entData.IrritatedSkin = true
        end,
        callback = ModCallbacks.MC_POST_ENTITY_TAKE_DMG
    },
    {
        func = function (_, ent, amount)
            if not data(ent).IrritatedSkin then return end

            local creep = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.PLAYER_CREEP_RED,
                0,
                ent.Position,
                Vector.Zero,
                ent
            )

            creep.CollisionDamage = amount
            return {Damage = amount * 1.25}
        end,
        callback = ModCallbacks.MC_ENTITY_TAKE_DMG
    },
    {
        ---@param npc EntityNPC
        func = function (_, npc)
            if not data(npc).IrritatedSkin then return end
        
            local color = npc.Color

            color.RO = 0.3

            npc.Color = color
        end,
        callback = ModCallbacks.MC_NPC_UPDATE
    }
}