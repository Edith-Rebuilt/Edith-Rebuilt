local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER

local NEPTUNUS = {
    BASE_DAMAGE   = 15,
    BASE_SIZE     = 2.5,
    BASE_DURATION = 150,
}

---@param weapon Weapon
---@return number
local function GetChargePercent(weapon)
    return weapon:GetCharge() / weapon:GetMaxCharge()
end

---@param player EntityPlayer
---@param chargePercent number
---@param damageMult number
---@param durationMult number
local function SpawnWaterCreep(player, chargePercent, damageMult, durationMult)
    local water = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL,
        0,
        player.Position,
        Vector.Zero,
        player
    ):ToEffect() ---@cast water EntityEffect

    water.CollisionDamage = (NEPTUNUS.BASE_DAMAGE * damageMult) * chargePercent
    water.Size = water.Size * (NEPTUNUS.BASE_SIZE * chargePercent)
    water.SpriteScale = water.SpriteScale * water.Size
    water:SetTimeout(math.ceil((NEPTUNUS.BASE_DURATION * durationMult) * chargePercent))
    water:Update()
end

---@param player EntityPlayer
---@param isStomp boolean
local function NeptunusLand(player, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_NEPTUNUS) then return end

    local weapon = player:GetWeapon(1)
    if not weapon then return end

    local hasBirthright = isStomp and Player.IsEdithBirthtight(player)
    SpawnWaterCreep(player, GetChargePercent(weapon), hasBirthright and 2 or 1, hasBirthright and 1.5 or 1)
end

mod:AddCallback(callbacks.PERFECT_PARRY,   function(_, player) NeptunusLand(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) NeptunusLand(player, true)  end)