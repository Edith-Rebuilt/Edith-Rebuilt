local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local modules = mod.Modules
local Player = modules.PLAYER
local StompUtils = modules.STOMP_UTILS
local Jump = modules.JUMP
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
---@param params TEdithHopParryParams|EdithJumpStompParams
---@param isStomp boolean
local function ChocolateMilkMult(player, params, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then return end

    local baseMult = (isStomp and Player.IsEdithBirthtight(player)) and 2.5 or 2
    local chocoMult = data(player).ChocoMult or 0
    local damage = StompUtils.GetDamage(params)

    if chocoMult > 0 then
        StompUtils.SetDamage(params, damage * (baseMult * chocoMult))
    end

    data(player).ChocoMult = 0
end

---@param player EntityPlayer
---@param params TEdithHopParryParams
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, _, params)
    ChocolateMilkMult(player, params, false)
end)

---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player, params)
    ChocolateMilkMult(player, params, true)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if Jump.Jumping then return end
    if not Player.IsPlayerShooting(player) then return end

    local weapon = player:GetWeapon(1)
    if not weapon then return end

    data(player).ChocoMult = weapon:GetCharge() / weapon:GetMaxCharge()
end)
