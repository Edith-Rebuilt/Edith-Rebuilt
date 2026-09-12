local mod = EdithRebuilt
local enums = mod.Enums
local sfx = enums.Utils.SFX
local modules = mod.Modules
local helpers = modules.HELPERS
local ModRNG = modules.RNG
local Player = modules.PLAYER
local StatusEffects = modules.STATUS_EFFECTS

local PEPPER_GRINDER = {
    PEPPER_STATUS_DURATION = 90,
    DAMAGE_MULT = 0.25,
    DAMAGE_DIV  = 3.5,
}

---@param player EntityPlayer
---@param RNG RNG
local function SpawnPepperCloud(player, RNG)
    local X = ModRNG.RandomFloat(RNG, 0.8, 1)
    local Y = ModRNG.RandomFloat(RNG, 0.8, 1)
    local pitch = ModRNG.RandomFloat(RNG, 0.9, 1.1)
    local pepperCloud = StatusEffects.SpawnSpicePuff(player, RNG)

    pepperCloud.SpriteScale = pepperCloud.SpriteScale * Vector(X, Y)
    helpers.ChangeColor(pepperCloud, 0.4, 0.4, 0.4)
    sfx:Play(enums.SoundEffect.SOUND_PEPPER_GRINDER, 10, 0, false, pitch)
end

---@param player EntityPlayer
local function TriggerEnemyDamage(player)
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
    local isJudasBirthright = Player.IsJudasWithBirthright(player)
    local frames = PEPPER_GRINDER.PEPPER_STATUS_DURATION * (hasCarBattery and 2 or 1)
    local damage = (player.Damage * PEPPER_GRINDER.DAMAGE_MULT) + (player.Damage / PEPPER_GRINDER.DAMAGE_DIV) * isJudasBirthright and 1.5 or 1
    local playerRef = EntityRef(player)

    for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 100, EntityPartition.ENEMY)) do
        helpers.TriggerPush(enemy, player, 20)
        StatusEffects.SetStatusEffect(enums.EdithStatusEffects.PEPPERED, enemy, frames, player)

        if isJudasBirthright then
            enemy:AddBurn(playerRef, 120, player.Damage)
        end

        enemy:TakeDamage(damage, 0, playerRef, 0)
    end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, RNG, player, flag)
    if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end

    TriggerEnemyDamage(player)
    SpawnPepperCloud(player, RNG)

    return true
end, enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER)