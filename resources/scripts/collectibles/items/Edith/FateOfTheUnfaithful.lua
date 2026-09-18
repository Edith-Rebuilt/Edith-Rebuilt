local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game, sfx = utils.Game, utils.SFX
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local BitMask = modules.BIT_MASK
local Maths = modules.MATHS
local Helpers = modules.HELPERS
local Player = modules.PLAYER

local FOTU = {
    DISTANCE_PUSH = 50,
    FIRE_DAMAGE = 3,
    PLAYER_DAMAGE_MULT = 1.5,
    PUSH_MAX_DISTANCE = 50,
}

local function TriggerDamage(player)
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
    local playerPos = player.Position
    local playerRef = EntityRef(player)
    local playerDamage = player.Damage * FOTU.PLAYER_DAMAGE_MULT
    local fireDamage = FOTU.FIRE_DAMAGE * (hasCarBattery and 2 or 1)
    local judasMult = Player.IsJudasWithBirthright(player) and 1.25 or 1

    for _, ent in ipairs(Helpers.GetEnemies()) do
        local enemyDist = playerPos:Distance(ent.Position)

        ent:TakeDamage(playerDamage * (Maths.exp(40 / enemyDist, 1, 1.2)) * judasMult, 0, playerRef, 0)
        ent:AddBurn(EntityRef(player), 83, fireDamage)

        if enemyDist > FOTU.PUSH_MAX_DISTANCE then goto continue end
        Helpers.TriggerPush(ent, player, 20 * judasMult)
        ::continue::
    end
end

local function TriggerSpecialEffects(rng)
    game:ShakeScreen(10)
    sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, ModRNG.RandomFloat(rng, 0.95, 1.05))
end

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, rng, player, flag)
    if BitMask.HasBitFlags(flag, UseFlag.USE_CARBATTERY --[[@as BitSet128]]) then return end

    TriggerSpecialEffects(rng)
    TriggerDamage(player)

    return true
end, items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player)
    if not player:GetEffects():GetCollectibleEffect(items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL) then return end

    local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

    player.Damage = player.Damage * (Hascarbattery and 2 or 1.75)
end, CacheFlag.CACHE_DAMAGE)