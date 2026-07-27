local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local tables = enums.Tables
local jumpTags = tables.JumpTags
local parryTypes = enums.ParryTypes
local misc = enums.Misc
local modules = mod.Modules
local VecDir = modules.VEC_DIR
local maths = modules.MATHS
local land = modules.LAND
local Player = modules.PLAYER
local TargetArrow = modules.TARGET_ARROW
local TEdithMod = modules.TEDITH
local Helpers = modules.HELPERS
local effects = modules.STATUS_EFFECTS
local BitMask = modules.BIT_MASK
local Jump = modules.JUMP
local data = mod.DataHolder.GetEntityData

local Colors = {
	Cooldown = Color(1, 1, 1, 1, 0.3),
	HopDashStop = Color(1, 1, 1, 1, 0, 0.1, 0.3),
	Redirection = Color(1, 1, 1, 1, 0.3, 0.3, 0.3),
}

---@param ent Entity
mod:AddCallback(enums.Callbacks.PERFECT_PARRY_KILL, function(_, _, ent)
	data(ent).KilledByParry = true
end)

mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	if npc:IsBoss() then return end
	if not effects.EntHasStatusEffect(npc, "Cinder") then return end
	if not data(npc).KilledByParry then return end

	return true
end)

---@param player EntityPlayer
---@param forceStopHops boolean
local function ResetTEdithPlayer(player, forceStopHops)
	Helpers.ChangeColor(player, nil, nil, nil, 1)
	data(player).PressCount = 0
	if forceStopHops then
		TEdithMod.StopTEdithHops(player, 0, true, true, true)
	end
end

---@param player EntityPlayer
local function ManageLeoEffect(player)
	local Peffects = player:GetEffects()

	if player.CanFly then
		if not Peffects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_LEO) then
			Peffects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_LEO, false, 1)
		end
	else
		Peffects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_LEO, -1)
	end
end

---@param player EntityPlayer
---@param arrow EntityEffect?
---@param HopParams table
local function ManageHopDashCharge(player, arrow, HopParams)
	if arrow then
		TEdithMod.HopDashChargeManager(player, arrow, HopParams)
	else
		TEdithMod.HopDashMovementManager(player, HopParams)
		if TEdithMod.GetHopDashCharge(player, false) < 10 then
			HopParams.HopMoveCharge = 0
			HopParams.HopStaticCharge = 0
			HopParams.HopDirection = Vector.Zero
		end
	end
end

---@param player EntityPlayer
local function SetEdithSprite(player)
	if player.FrameCount > 0 then return end
	Player.SetCustomSprite(player, true)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	if not Player.IsEdith(player, true) then return end	
	if Helpers.IsDSSMenuOpen() then return end

	local HopParams = TEdithMod.GetHopParryParams(player)
	local arrow = TargetArrow.GetEdithTarget(player, true)

	SetEdithSprite(player)
	ManageLeoEffect(player)
	ManageHopDashCharge(player, arrow, HopParams)
	TEdithMod.ParryCooldownManager(player, HopParams)
end)

---@param player EntityPlayer
---@param playerData table
---@param HopParams table
---@param IsGrudge boolean
---@param jumpData JumpData
local function ManageParryInput(player, playerData, HopParams, IsGrudge, jumpData)
	HopParams.IsParryJump = HopParams.IsParryJump or false

	if Helpers.IsKeyStompTriggered(player) then
		local isParryJump = Jump.IsSpecificJump(JumpLib:GetData(player), jumpTags.TEdithJump)
		local cooldown = HopParams.ParryCooldown
		local maxCooldown =  playerData.MaxParryCooldown

		if cooldown == 0 and not isParryJump and not HopParams.IsParryJump then
			TEdithMod.ParryTriggerManager(player, IsGrudge, HopParams, jumpData)
		elseif maxCooldown and (HopParams.ParryCooldown > 0 and HopParams.ParryCooldown >= maxCooldown - 6) then
			player:SetColor(Colors.Cooldown, 3, 1, true, false)
			playerData.StoredInput = true
		end
	elseif playerData.StoredInput and HopParams.ParryCooldown <= 0 then
		TEdithMod.ParryTriggerManager(player, IsGrudge, HopParams, jumpData)
		playerData.StoredInput = false
	end
end

---@param player EntityPlayer
---@param HopParams table
---@param MiscConfig MiscData
local function ManageGrudgeEffects(player, HopParams, MiscConfig)
	if not Helpers.IsGrudgeChallenge() then return end
	if not HopParams.GrudgeDash then return end
	if data(player).IsRedirectioningMove then return end

	if MiscConfig and MiscConfig.EnableShakescreen and HopParams.HopMoveCharge > 50 then
		game:ShakeScreen(2)
	end
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.3, 0, false, 1.2)
end

---@param player EntityPlayer
---@param HopParams table
---@param arrow EntityEffect?
local function ManageHeadDirection(player, HopParams, arrow)
	if Player.IsPlayerShooting(player) then return end

	local faceDirection = VecDir.VectorToDirection(HopParams.HopDirection)
	local chosenDir = faceDirection or Direction.DOWN

	if HopParams.IsHoping or (arrow and arrow.Visible == true) then
		chosenDir = faceDirection or Direction.DOWN
	elseif VecDir.VectorEquals(HopParams.HopDirection, Vector.Zero) then
		chosenDir = Direction.DOWN
	end

	player:SetHeadDirection(chosenDir, 1, true)
end

local StopDashAnimations = {
	["MinecartEnter"] = true,
	["TeleportUp"] = true,
	["TeleportDown"] = true,
}

local function ManageStopAnimations(player)
	if not Helpers.When(player:GetSprite():GetAnimation(), StopDashAnimations, false) then return end

	TEdithMod.StopTEdithHops(player, 0, true, true)
end

---@param player EntityPlayer
---@param pData table
---@param arrow EntityEffect?
---@param isArrowMoving boolean
local function ManageTargetCleanup(player, pData, arrow, isArrowMoving)
	if not arrow or isArrowMoving then return end

	if pData.IsRedirectioningMove then
		if pData.PressCount <= 10 then
			TargetArrow.RemoveEdithTarget(player, true)
			TEdithMod.StopTEdithHops(player, 20, false, true, true)
			player:MultiplyFriction(0.05)
			player:SetColor(Colors.HopDashStop, 5, 1000, true, false)
		elseif pData.PressCount >= 9 then
			TargetArrow.RemoveEdithTarget(player, true)
		end
	else
		TargetArrow.RemoveEdithTarget(player, true)
	end

	pData.PressCount = 0
end

---@param player EntityPlayer
---@param pData table
---@param isArrowMoving boolean
local function ManageRedirectionInput(player, pData, isArrowMoving)
	if not isArrowMoving then return end

	pData.PressCount = pData.PressCount + 1

	if not pData.IsRedirectioningMove then return end

	if pData.PressCount == 5 then
		player:SetColor(Colors.Redirection, 5, 1000, true, false)
	elseif pData.PressCount <= 2 then
		player:SetMinDamageCooldown(20)
		player:MultiplyFriction(0.05)
	end
end

---@param player EntityPlayer
---@param isArrowMoving boolean
local function ArrowSpawnManager(player, isArrowMoving)
	if not isArrowMoving then return end 
	if player.ControlsCooldown > 0 then return end
	TargetArrow.SpawnEdithTarget(player, true)
end

---@param player EntityPlayer
---@param pData table
---@param arrow EntityEffect
local function SetRedirectValues(player, pData, arrow)
	local CanRedirectMove = TEdithMod.GetHopDashCharge(player, false) > 0 and TEdithMod.GetHopDashCharge(player, true) <= 0

	pData.IsRedirectioningMove = CanRedirectMove and (arrow ~= nil)
	pData.PressCount = pData.PressCount or 0
end

---@param player EntityPlayer
local function PitfallJumpStop(player)
	if not player:GetSprite():IsPlaying("FallIn") then return end
	TEdithMod.StopTEdithHops(player, 9, true, true, true)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)	
	if not Player.IsEdith(player, true) then return end

	local HopParams = TEdithMod.GetHopParryParams(player)
	local MiscConfig = Helpers.GetConfigData("MiscData") ---@cast MiscConfig MiscData
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local IsGrudge = Helpers.IsGrudgeChallenge()
	local isArrowMoving = TargetArrow.IsEdithTargetMoving(player)
	local pData = data(player)

	TEdithMod.ArrowMovementManager(player, HopParams)

	ManageParryInput(player, data(player), HopParams, IsGrudge, JumpLib:GetData(player))
	if HopParams.IsHoping then
		TEdithMod.ResetHopDashCharge(player, false, true)
	end

	PitfallJumpStop(player)
	SetRedirectValues(player, pData, arrow)
	ManageTargetCleanup(player, pData, arrow, isArrowMoving)
	ArrowSpawnManager(player, isArrowMoving)
	ManageRedirectionInput(player, pData, isArrowMoving)
	ManageGrudgeEffects(player, HopParams, MiscConfig)
	ManageHeadDirection(player, HopParams, arrow)
	ManageStopAnimations(player)
end)

---@param isLevelCallback boolean
local function RoomFloorStopManager(isLevelCallback)
	local isDungeon = game:GetRoom():GetType() == RoomType.ROOM_DUNGEON
	local forceStop = isLevelCallback or isDungeon

	Player.ForEachPlayerType(function(player)
		ResetTEdithPlayer(player, forceStop)
	end, enums.PlayerType.PLAYER_EDITH_B)
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
	Player.ForEachPlayerType(function (player)
		if utils.Level:GetCurrentRoomDesc().Data.Name ~= "Mirror Room" then return end

		local room = game:GetRoom()
		local params = TEdithMod.GetHopParryParams(player)

		for i = 0, DoorSlot.NUM_DOOR_SLOTS do
			local door = room:GetDoor(i)

			if not door then goto continue end
			if not string.find(door:GetSprite():GetLayer(0):GetSpritesheetPath(), "mirror") then break end

			if door.Position:DistanceSquared(player.Position) > 1600 then break end
			params.HopDirection.X = -params.HopDirection.X
			player:SetHeadDirection(VecDir.VectorToDirection(params.HopDirection), 2, true)
			::continue::
		end
	end, enums.PlayerType.PLAYER_EDITH_B)

	RoomFloorStopManager(false)
end)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
	RoomFloorStopManager(true)
end)

local damageBase = 5.25
local VecOne = Vector.One

---@param player EntityPlayer
---@param jumpData JumpData
---@param params TEdithHopParryParams
local function OnHopLand(player, jumpData, params)
	if not Jump.IsSpecificJump(jumpData, jumpTags.TEdithHop) then return end

	local tearRange = player.TearRange / 40
	local Knockbackbase = (player.ShotSpeed * 10) + 8
	local Charge = TEdithMod.GetHopDashCharge(player, false, false)
	local chargeDiv = Charge / 100
	local BRCharge = params.HopMoveBRCharge / 100
	local BRMult = 1 + BRCharge
	local damageFormula = (((damageBase + player.Damage) / 2) * (TEdithMod.HopCurve(chargeDiv))) * BRMult

	params.HopDamage = damageFormula
	params.HopKnockback = Knockbackbase * maths.exp(chargeDiv, 1, 1.5)
	params.HopRadius = math.min((30 + (tearRange - 9)), 35)

	player:SpawnWaterImpactEffects(player.Position, VecOne, 1)
	land.LandFeedbackManager(player, land.GetLandSoundTable(true), misc.BurntSaltColor, jumpData)
	land.TaintedEdithHop(player, params)
end

---@param player EntityPlayer
---@param jumpData JumpData
---@param params TEdithHopParryParams
local function OnParryLand(player, jumpData, params)
	if not Jump.IsSpecificJump(jumpData, jumpTags.TEdithJump) then return end

	if TargetArrow.GetEdithTarget(player, true) then
		TEdithMod.ResetHopDashCharge(player, true, true)
	end

	local perfectParry, _ = land.ParryLandManager(player, params, true)

	land.LandFeedbackManager(player, land.GetLandSoundTable(true, perfectParry), misc.BurntSaltColor, jumpData, perfectParry)
end

local ParryTypeBonusCharge = {
	[parryTypes.IMPRECISE] = 15,
	[parryTypes.PERFECT] = 25,
}

mod:AddCallback(enums.Callbacks.POST_PARRY_LAND, function(_, player)
	local parryType = TEdithMod.GetParryType(TEdithMod.GetHopParryParams(player))
	local chargeBonus = Helpers.When(parryType, ParryTypeBonusCharge, 0)

	TEdithMod.AddHopDashCharge(player, chargeBonus, 0.75)
end)

---@param ent Entity
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, jumpData)
	local player = ent:ToPlayer()

	if not player then return end

	local HopParams = TEdithMod.GetHopParryParams(player)

	TEdithMod.BlazingParryManager(player, HopParams)
	OnHopLand(player, jumpData, HopParams)
	OnParryLand(player, jumpData, HopParams)
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@param source EntityRef
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (_, player, _, flags, source)
	if source.Type == EntityType.ENTITY_SLOT then return end
	if not Player.IsEdith(player, true) then return end

	local HopParams = TEdithMod.GetHopParryParams(player)

	if data(player).IsRedirectioningMove then return end
	if not (HopParams.IsHoping == true and HopParams.HopMoveCharge >= 20) then return end
	if BitMask.HasBitFlags(flags, DamageFlag.DAMAGE_RED_HEARTS --[[@as BitSet128]]) then return end
	return false
end)

---@param playerData table
local function SetChargeBars(playerData)
	playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)
	playerData.BRChargeBar = playerData.BRChargeBar or Sprite("gfx/TEdithBRChargebar.anm2", true)
end	

local function GetMainChargeOffset(player, playerData)
	local isBRChargeBarAnimFinished = Player.PlayerHasBirthright(player) and not playerData.BRChargeBar:IsFinished("Disappear")

	return isBRChargeBarAnimFinished and misc.ChargeBarleftVector or misc.ChargeBarcenterVector
end

local function RenderChargeBars(playerData, playerpos, offset, dashCharge, dashBRCharge)
	HudHelper.RenderChargeBar(playerData.ChargeBar, dashCharge, 100, playerpos + offset)
	HudHelper.RenderChargeBar(playerData.BRChargeBar, dashBRCharge, 100, playerpos + misc.ChargeBarrightVector)
end

local function GetPlayerRenderPos(player)
	local playerpos = game:GetRoom():WorldToScreenPosition(player.Position)
	if game:GetRoom():IsMirrorWorld() then
		playerpos.X = (Helpers.GetScreenCenter().X * 2 - playerpos.X)
	end

	return playerpos
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if Helpers.IsDSSMenuOpen() then return end

	Player.ForEachPlayerType(function(player)
		if RoomTransition:GetTransitionMode() == 3 then return end

		local hopParams = TEdithMod.GetHopParryParams(player)
		local playerData = data(player)
		local dashCharge = hopParams.HopStaticCharge
		local dashBRCharge = hopParams.HopStaticBRCharge

		if not dashCharge or not dashBRCharge then return end

		SetChargeBars(playerData)
		local playerpos = GetPlayerRenderPos(player)
		local offset = GetMainChargeOffset(player, playerData)

		RenderChargeBars(playerData, playerpos, offset, dashCharge, dashBRCharge)
	end, enums.PlayerType.PLAYER_EDITH_B)
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function(_, player, _, grid)
	if not grid then return end
	if not Player.IsEdith(player, true) then return end

	local playerData = data(player)
	local params = TEdithMod.GetHopParryParams(player)
	local isMoving = params.IsHoping or params.GrudgeDash
	local rock = grid:ToRock()
	local poop = grid:ToPoop()
	local tnt = grid:ToTNT()
	local IsJumping = Jump.IsJumping(player)

	if not isMoving then return end

	if rock or poop or tnt then
		grid:Destroy()
	else
		if not IsJumping then
			TEdithMod.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget, true)
		end
	end
end)

---@param player EntityPlayer
---@param collider Entity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function(_, player, collider)
	if not Player.IsEdith(player, true) then return end
	if collider.Type ~= EntityType.ENTITY_FIREPLACE then return end
	if collider.Variant ~= 4 then return end
	if player:HasInstantDeathCurse() then return end

	TEdithMod.StopTEdithHops(player, 20, true, true, true)
end)

---@param fam EntityFamiliar
local function IsWisp(fam)
	local var = fam.Variant
	return var == FamiliarVariant.WISP or var == FamiliarVariant.ITEM_WISP
end

---@param player EntityPlayer
---@param ent Entity
local function StopVel(player, ent)
	if not Player.IsEdith(player, true) then return end
	if ent.Velocity:Length() <= 50 then return end
	ent.Velocity = Vector.Zero
end

---@param fam EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (_, fam)
	if not IsWisp(fam) then return end
	StopVel(fam.Player, fam)
end)

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
	StopVel(npc:GetPlayerTarget():ToPlayer() --[[@as EntityPlayer]], npc)
end, EntityType.ENTITY_WILLO)