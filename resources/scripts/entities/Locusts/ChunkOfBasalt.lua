local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
---@return boolean|table?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, amount, flags, source, countdown)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_CHUNK_OF_BASALT) then return end

    local rng = ent:GetDropRNG()
    local damage = ModRNG.RandomBoolean(rng, 0.8) and amount or 0
    local player = ent:ToFamiliar().Player

    if damage > 0 and ModRNG.RandomBoolean(rng, 0.5) then
        for rocks = 1, 6 do
            CustomShockwaveAPI:SpawnCustomCrackwave(
                ent.Position,
                player,
                30,
                rocks * (360 / 6),
                1,
                1,
                amount
            )
        end
    end

    return {Damage = damage, DamageFlags = flags, DamageCountdown = countdown}
end)
