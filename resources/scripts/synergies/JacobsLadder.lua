local mod = EdithRebuilt
local game = mod.Enums.Utils.Game
local Helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param isStomp boolean
local function ChainLightning(player, ent, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) then return end
    if not Helpers.IsEnemy(ent) then return end

    local mult = (isStomp and Player.IsEdithBirthtight(player)) and 0.5 or 1
    game:ChainLightning(ent.Position, player.Damage * mult, player.TearFlags, player)
end

mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent)
    ChainLightning(player, ent, false)
end)
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent)
    ChainLightning(player, ent, true)
end)
