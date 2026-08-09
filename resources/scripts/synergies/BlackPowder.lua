local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local modules = mod.Modules
local Creeps = modules.CREEPS
local Player = modules.PLAYER
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
---@param IsStomp boolean
local function SpawnPowder(player, IsStomp)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_POWDER) then return end

	local distance = (IsStomp and Player.IsEdithBirthtight(player)) and 90 or 70
	Creeps.SpawnBlackPowder(player, 20, player.Position, distance)
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player)
	SpawnPowder(player, false)
end)

mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BLACK_POWDER):RandomInt(1, 3) ~= 1 then return end
	SpawnPowder(player, true)
end)

-- Solo aplica al stomp: oculta creeps no spawneados por este mod
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	if data(effect).CustomSpawn == true then return end
	effect.Visible = false
	effect:Remove()
end, EffectVariant.PLAYER_CREEP_BLACKPOWDER)
