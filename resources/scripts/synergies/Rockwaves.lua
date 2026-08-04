local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
local function ParryRockwaves(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end

    local hasBirthright = Player.IsEdith(player, false) and Player.PlayerHasBirthright(player)
    local totalRocks = hasBirthright and 8 or 6
    local totalRings = hasBirthright and 2 or 1
    local shockwaveDamage = (hasBirthright and player.Damage * 1.5 or player.Damage) / 2

    for ring = 1, totalRings do
        local dist = ring == 1 and 40 or 20
        for rocks = 1, totalRocks do
            CustomShockwaveAPI:SpawnCustomCrackwave(
                player.Position,
                player,
                dist,
                rocks * (360 / totalRocks),
                1,
                ring,
                shockwaveDamage
            )
        end
    end
end

---@param player EntityPlayer
local function StompRockwaves(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end

    local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
    local totalRings = hasBirthright and 2 or 1
    local damageMult = hasBirthright and 1.5 or 1.25
    local shockwaveDamage = (player.Damage * damageMult) / 2

    for ring = 1, totalRings do
        local totalRocks = ring == 1 and 6 or 12
        local dist       = ring == 1 and 40 or 70
        for rocks = 1, totalRocks do
            CustomShockwaveAPI:SpawnCustomCrackwave(
                player.Position,
                player,
                dist,
                rocks * (360 / totalRocks),
                1,
                ring,
                shockwaveDamage
            )
        end
    end
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) ParryRockwaves(player) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) StompRockwaves(player) end)
