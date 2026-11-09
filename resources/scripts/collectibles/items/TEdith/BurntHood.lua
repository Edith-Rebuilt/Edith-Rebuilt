local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType

local modules = mod.Modules
local TEdith = modules.TEDITH
local Land = modules.LAND
local Jump = modules.JUMP
local ParryHop = modules.PARRY_HOP
local Maths = modules.MATHS

local VecOne = Vector.One
local VecZero = Vector.Zero

local edithCallbacks = enums.Callbacks

local Pallete = EdithRebuilt.Pallete
local embers ---@cast embers ParticleEmitter

local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
local function GetParryUses(player)
	local slot = player:GetActiveItemSlot(items.COLLECTIBLE_BURNT_HOOD)

	if slot < 0 then return -1 end

	local varData = player:GetActiveItemDesc(slot).VarData
	return varData
end

-- local function Get

---@param player EntityPlayer
---@param quantity integer
local function AddParryUses(player, quantity)
	local slot = player:GetActiveItemSlot(items.COLLECTIBLE_BURNT_HOOD)

	if slot < 0 then return -1 end
	player:SetActiveVarData(Maths.Clamp(GetParryUses(player) + quantity, 0, 6), slot)
end

mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function(_, itemID, player, varData, currentMaxCharge)
	return currentMaxCharge + (15 * GetParryUses(player))
end, items.COLLECTIBLE_BURNT_HOOD)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
	if Jump.IsJumping(player) then return end
    Jump.InitTaintedEdithParryJump(player, "BrokenHoodParry")
end, items.COLLECTIBLE_BURNT_HOOD)

---@param player EntityPlayer
---@param jumpData JumpData
---@return boolean?
local function TriggerParry(player, jumpData)
	local params = TEdith.GetHopParryParams(player)

	params.ParryDamage = params.ParryDamage * GetParryUses(player)

	local PerfectParry = ParryHop.ParryLandManager(player, params, false)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, PerfectParry), Color.Default, jumpData, PerfectParry)

	return PerfectParry
end

---@param player EntityPlayer
local function TriggerPerfectParryReward(player)
	player:SetMinDamageCooldown(30)
	player:SetActiveCharge(
		15,
		player:GetActiveItemSlot(items.COLLECTIBLE_BURNT_HOOD)
	)
end	

---@param player EntityPlayer
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player, jumpData)
	local pData = data(player)
	pData.BurntHoodLand = true

	if not TriggerParry(player, jumpData) then return end

	AddParryUses(player, 1)
	TriggerPerfectParryReward(player)
	pData.HoodCooldown = 30
end, { tag = "BrokenHoodParry" })
	
---@param player EntityPlayer
---@param params TEdithHopParryParams
mod:AddCallback(edithCallbacks.POST_PARRY_LAND, function(_, player, params)
	local pData = data(player)
	if not pData.BurntHoodLand then return end

	params.ParryDamage = params.ParryDamage * Maths.exp(GetParryUses(player) + 1, 1, 1.3)
	pData.BurntHoodLand = false
end)

---@param player EntityPlayer
local function HoodCooldownManager(player)
	local slot = player:GetActiveItemSlot(items.COLLECTIBLE_BURNT_HOOD)

	if slot < 0 then return end
	if player:GetActiveCharge(slot) < player:GetActiveMaxCharge(slot) then return end
	if GetParryUses(player) <= 0 then return end

	local pData = data(player)
	pData.HoodCooldown = pData.HoodCooldown or 0
	pData.HoodCooldown = math.max(pData.HoodCooldown - 1, 0)

	if pData.HoodCooldown <= 0 then
		AddParryUses(player, -1)
		pData.HoodCooldown = 30
	end
end

local function EmbersManager(player)
	print(player:HasCollectible(items.COLLECTIBLE_BURNT_HOOD))

	if player:HasCollectible(items.COLLECTIBLE_BURNT_HOOD) then
		embers = embers or Pallete:CreateParticleEmitter("gfx/effects/TinyBug.png")
	else
		if embers then
			embers:Destroy()
			embers = nil
		end
	end

	print(embers)
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	HoodCooldownManager(player)
	EmbersManager(player)
end)

local hoodSprite = Sprite("gfx/items/collectibles/BurntHood.anm2", true)
hoodSprite:Play("Idle")

local offsetVec = Vector(16, 16)
HudHelper.RegisterHUDElement({
	ItemID = items.COLLECTIBLE_BURNT_HOOD,
	OnRender = function (player, _, _, position, _, scale)
		local offset = offsetVec * scale
		local parryUses = GetParryUses(player)
		local redTint = 0.15 * GetParryUses(player)

        hoodSprite:Render((position) + offset, VecZero, VecZero)
		hoodSprite.Scale = VecOne * scale
		hoodSprite.Color = Color(1 + redTint, 1, 1, 1, 0.3 * (redTint))

		if not embers then return end

		if parryUses < 1 and embers:IsPlaying() then 
			embers:Stop()
			return
		end

		if not embers:IsPlaying() then
			embers:Play()
		end

		-- print(Game():GetRoom():GetCamera().)

		embers.ParticleRate = 2 * parryUses
		embers.StartSpeed = { Min = 3, Max = 6 + (2 * (parryUses/6)) }
		-- embers.Position = Isaac.WorldToScreen(position)
		embers.Position = Isaac.RenderToWorld(position + Vector(player.Velocity.X, 0)) + (Vector(20, 40))
		-- embers.
		-- embers.IsWorldSpace = false
		embers.DirectionSpread = 15
		embers.StartColor = { Min = KColor(1, 0.3, 0, 1), Max = KColor(1, 0.8, 0, 1) }
		embers.StartSize = { Min = Vector(0.8, 0.8) * scale, Max = Vector(1, 1) * scale}
		embers.PersistAcrossRooms = true
	end
}, HudHelper.HUDType.ACTIVE_ID)