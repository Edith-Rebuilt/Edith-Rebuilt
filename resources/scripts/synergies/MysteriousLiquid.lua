local mod = EdithRebuilt
local enums = mod.Enums
local callbacks = enums.Callbacks
local modules = mod.Modules
local Player = modules.PLAYER

---@param player EntityPlayer
local function SpawnMysteriousLiquidCreep(player, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) then return end

    local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_GREEN, 0, player.Position, Vector.Zero, player):ToEffect() --[[@as EntityEffect]]

    local hasBirthright = (isStomp and Player.IsEdithBirthtight(player))

    creep.SpriteScale = creep.SpriteScale * (hasBirthright and 3 or 2)
    creep.Timeout = creep.Timeout * (hasBirthright and 8 or 4)

    creep:Update()
end

mod:AddCallback(callbacks.OFFENSIVE_STOMP, function (_, player)
    SpawnMysteriousLiquidCreep(player, true)
end)

mod:AddCallback(callbacks.POST_PARRY_LAND, function (_, player)
    SpawnMysteriousLiquidCreep(player, true)
end)