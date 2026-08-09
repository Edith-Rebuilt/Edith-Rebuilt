local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param isStomp boolean
local function SpawnSmokeCloud(player, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_JUPITER) then return end

    local hasBirthright = isStomp and Player.IsEdithBirthtight(player)

    local smokeCloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0,
        player.Position, Vector.Zero, player
    ):ToEffect() ---@cast smokeCloud EntityEffect

    local randomScale = smokeCloud:GetDropRNG():RandomFloat() * 0.3
    local baseScale = hasBirthright and 2 or 1.5
    local timeOut = hasBirthright and 140 or 70

    smokeCloud.SpriteScale = Vector(baseScale + randomScale, baseScale + randomScale)
    smokeCloud:SetTimeout(timeOut)
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) SpawnSmokeCloud(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) SpawnSmokeCloud(player, true)  end)
