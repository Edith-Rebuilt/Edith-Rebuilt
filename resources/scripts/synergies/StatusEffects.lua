local mod = EdithRebuilt
local Callbacks = mod.Enums.Callbacks
local bitMask = mod.Modules.BIT_MASK

---@param player EntityPlayer
---@param entity Entity
local function ApplyTearflagEffects(player, entity)
	if not entity:IsEnemy() then return end

	local flag = player:GetTearHitParams(WeaponType.WEAPON_BRIMSTONE).TearFlags
	local ent = entity:ToNPC() ---@cast ent EntityNPC
	ent:ApplyTearflagEffects(ent.Position, flag, player, player.Damage)
end

mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, entity) ApplyTearflagEffects(player, entity) end)
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, entity) ApplyTearflagEffects(player, entity) end)