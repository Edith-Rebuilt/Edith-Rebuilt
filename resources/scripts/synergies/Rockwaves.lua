local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
local function ParryRockwaves(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end

    for rocks = 1, 6 do
        CustomShockwaveAPI:SpawnCustomCrackwave(
            player.Position,
            player,
            20,
            rocks * (360 / 6),
            1,
            1,
            player.Damage
        )
    end
end

---@param player EntityPlayer
local function StompRockwaves(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end

    local hasBirthright = Player.IsEdithBirthtight(player)
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
