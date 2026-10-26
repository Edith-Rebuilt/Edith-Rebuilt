---@diagnostic disable: undefined-field, undefined-global

-- #region Imports
local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local JumpParams = tables.JumpParams

local modules = mod.Modules
local EdithMod = modules.EDITH
local Land = modules.LAND
local TargetArrow = modules.TARGET_ARROW
local StatusEffects = modules.STATUS_EFFECTS
local helpers = modules.HELPERS
local Player = modules.PLAYER
local ModRNG = modules.RNG
local Jump = modules.JUMP

local room = enums.Utils.Room
local jumpCallbacks = JumpLib.Callbacks
local data = mod.DataHolder.GetEntityData
local params = EdithMod.GetJumpStompParams
-- #endregion Imports

-- #region Constants
local JUMP_WINDUP_FRAMES = 8 
local SALT_SHAKER_POCKET_SLOT = 1 

local LANDING_DAMAGE_COOLDOWN = 25
local LANDING_FRICTION_MULT = 0.1

local COAL_BONUS_MIN = 0.5
local COAL_BONUS_MAX = 0.6
local COAL_DISTANCE_DIVISOR = 40

local MOMS_HEELS_DAMAGE = 12

local BIRTHCAKE_SALT_CHANCE = 0.25
local BIRTHCAKE_SALT_FRAMES = 120

local MAX_FALL_SCALE = Vector(0.7, 1.3)
-- #endregion Constants

-- #region Utilidades

---@param callback any
---@param fn fun(player: EntityPlayer, ...): any
---@param filter any?
local function AddEdithCallback(callback, fn, filter)
	local function wrapped(_, player, ...)
		if not Player.IsEdith(player, false) then return end

		return fn(player, ...)
	end

	if filter == nil then
		mod:AddCallback(callback, wrapped)
	else
		mod:AddCallback(callback, wrapped, filter)
	end
end

---@param pData table
---@return boolean
local function IsInJumpWindup(pData)
	return (pData.JumpCount or 0) > 0
end
-- #endregion Utilidades

-- #region Escala del sprite
local FrameScale = {
	BeforeJump = {
		[1] = Vector(1.05, 0.95),
		[2] = Vector(1.1, 0.9),
		[3] = Vector(1.15, 0.85),
		[4] = Vector(1.2, 0.8),
		[5] = Vector(1.25, 0.75),
		[6] = Vector(1.3, 0.7),
		[7] = Vector(1.35, 0.65),
	},
	AfterJump = {
		[1] = Vector(0.95, 1.05),
		[2] = Vector(0.9, 1.1),
		[3] = Vector(0.85, 1.15),
		[4] = Vector(0.8, 1.2),
		[5] = Vector(0.85, 1.15),
		[6] = Vector(0.9, 1.1),
		[7] = Vector(0.95, 1.05),
	},
	OnFalling = {
		[false] = {
			[5] = Vector(0.95, 1.05),
			[6] = Vector(0.9, 1.1),
			[7] = Vector(0.85, 1.15),
			[8] = Vector(0.8, 1.2),
			[9] = Vector(0.75, 1.25),
			[10] = Vector(0.7, 1.3),
		},
		[true] = {
			[1] = Vector(0.9, 1.1),
			[2] = Vector(0.8, 1.2),
			[3] = Vector(0.7, 1.3),
		},
	},
}

---@param player EntityPlayer
---@param pData table
local function ManageStretchSquashScale(player, pData)
	local vecScale = FrameScale.BeforeJump[pData.JumpCount]
	if not vecScale then return end

	player.SpriteScale = pData.BaseSpriteScale * vecScale
end

---@param player EntityPlayer
local function JumpInitScale(player)
	local baseScale = data(player).BaseSpriteScale
	local vecScale = FrameScale.AfterJump[Jump.GetJumpFrame(player)]

	player.SpriteScale = vecScale and baseScale * vecScale or baseScale
end

---@param player EntityPlayer
local function JumpFallScale(player)
	local canFly = player.CanFly
	local frame = Jump.GetFallFrame(player)
	local startFrame = canFly and 1 or 5

	if frame < startFrame then return end
	if canFly and params(player).IsDefensiveStomp then return end

	local vecScale = FrameScale.OnFalling[canFly][frame] or MAX_FALL_SCALE

	player.SpriteScale = data(player).BaseSpriteScale * vecScale
end

---@param player EntityPlayer
local function ResetEdithScale(player)
	if Jump.IsJumping(player) then return end

	player.SpriteScale = data(player).BaseSpriteScale
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function (_, player)
	local pData = data(player)

	pData.BaseSpriteScale = player.SpriteScale
	pData.JumpCount = 0
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player)
	data(player).BaseSpriteScale = player.SpriteScale
end, CacheFlag.CACHE_SIZE)
-- #endregion Escala del sprite

-- #region Inicio del salto
---@param player EntityPlayer
---@param state EdithUpdateState
local function SetInitJumpState(player, state)
	if state.isVestige then return end
	if not state.isKeyStompPressed then return end
	if not state.jumpParams.CanJump then return end
	if state.isJumping then return end

	data(player).InitJump = true
end

---@param pData table
local function ManageStretchSquashCounter(pData)
	pData.JumpCount = ((pData.JumpCount or 0) + 1) % JUMP_WINDUP_FRAMES
end

---@param player EntityPlayer
---@param pData table
---@param state EdithUpdateState
local function TriggerEdithJump(player, pData, state)
	if pData.JumpCount ~= 0 then return end

	pData.InitJump = false
	player.SpriteScale = pData.BaseSpriteScale

	EdithMod.JumpTriggerManager(player, state.isVestige)
	state.jumpParams.CanJump = false
end

---@param player EntityPlayer
---@param pData table
---@param state EdithUpdateState
local function ManageJumpStretchSquash(player, pData, state)
	if state.isJumping then return end
	if not pData.InitJump then return end
	if state.jumpParams.Cooldown ~= 0 then return end
	if not state.jumpParams.CanJump then return end

	ManageStretchSquashCounter(pData)
	TriggerEdithJump(player, pData, state)
	ManageStretchSquashScale(player, pData)
end
-- #endregion Inicio del salto

-- #region Target
---@param player EntityPlayer
---@param state EdithUpdateState
local function HandleTargetSpawn(player, state)
	if player.FrameCount == 0 then return end
	if player.ControlsCooldown > 0 then return end
	if state.jumpData.Tags.EdithRebuilt_FlatStoneLand then return end

	local shouldSpawn = state.isMoving or state.isKeyStompPressed or (state.hasMarked and state.isShooting)

	if shouldSpawn then
		TargetArrow.SpawnEdithTarget(player)
	end
end

---@param player EntityPlayer
---@param target EntityEffect?
---@param state EdithUpdateState
local function HandleTargetManagers(player, target, state)
	if not target then return end

	EdithMod.TargetMovementManager(player, target, state.isMoving)
	EdithMod.HeadDirectionManager(player, state.isJumping, state.isShooting, state.isKeyStompPressed)
end
-- #endregion Target

-- #region Update principal
---@class EdithUpdateState
---@field isMoving boolean
---@field isKeyStompPressed boolean
---@field hasMarked boolean
---@field isShooting boolean
---@field jumpData JumpData
---@field isPitfall boolean
---@field isJumping boolean
---@field isVestige boolean
---@field jumpParams EdithJumpStompParams

---@param player EntityPlayer
---@return EdithUpdateState
local function BuildUpdateState(player)
	return {
		isMoving = TargetArrow.IsEdithTargetMoving(player),
		isKeyStompPressed = helpers.IsKeyStompPressed(player),
		hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED),
		isShooting = Player.IsPlayerShooting(player),
		jumpData = JumpLib:GetData(player),
		isPitfall = JumpLib:IsPitfalling(player),
		isJumping = Jump.IsJumping(player),
		isVestige = helpers.IsVestigeChallenge(),
		jumpParams = params(player),
	}
end

---@param player EntityPlayer
local function HandleEdithInit(player)
	if player.FrameCount ~= 0 then return end

	Player.SetCustomSprite(player, false)

	if helpers.GetConfigData(enums.ConfigDataTypes.EDITH).SaltShakerSlot == SALT_SHAKER_POCKET_SLOT then
		player:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_SALTSHAKER)
		player:SetPocketActiveItem(enums.CollectibleType.COLLECTIBLE_SALTSHAKER, ActiveSlot.SLOT_POCKET, false)
	end
end

---@param player EntityPlayer
local function EdithTeleportManager(player)
	if not player:GetSprite():IsPlaying("TeleportDown") then return end

	JumpLib:QuitJump(player)
	TargetArrow.RemoveEdithTarget(player, false)
end

---@param player EntityPlayer
AddEdithCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (player)
	if player:IsDead() then
		TargetArrow.RemoveEdithTarget(player)
		return
	end

	local pData = data(player)
	pData.BaseSpriteScale = pData.BaseSpriteScale or Vector.One

	local state = BuildUpdateState(player)

	if not state.isPitfall then
		SetInitJumpState(player, state)
		ManageJumpStretchSquash(player, pData, state)
		HandleEdithInit(player)
		HandleTargetSpawn(player, state)
	end

	EdithTeleportManager(player)
	EdithMod.CustomDropBehavior(player, state.jumpParams)
	EdithMod.DashItemBehavior(player)

	HandleTargetManagers(player, TargetArrow.GetEdithTarget(player), state)
end)
-- #endregion Update principal

-- #region Durante el salto
---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function ApplyCoalBonus(player, jumpParams)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end

	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	local bonus = ModRNG.RandomFloat(rng, COAL_BONUS_MIN, COAL_BONUS_MAX)

	jumpParams.CoalBonus = bonus * jumpParams.JumpStartDist / COAL_DISTANCE_DIVISOR
end

---@param player EntityPlayer
mod:AddCallback(jumpCallbacks.POST_ENTITY_JUMP, function (_, player)
	local jumpParams = params(player)

	jumpParams.JumpStartPos = player.Position
	jumpParams.JumpStartDist = TargetArrow.GetEdithTargetDistance(player)

	ApplyCoalBonus(player, jumpParams)
end, JumpParams.EdithJump)

---@param player EntityPlayer
---@param jumpdata JumpData
AddEdithCallback(jumpCallbacks.ENTITY_UPDATE_60, function (player, jumpdata)
	local jumpParams = params(player)

	JumpInitScale(player)
	JumpFallScale(player)
	EdithMod.JumpMovement(player, helpers.IsVestigeChallenge(), jumpParams, jumpdata)
	EdithMod.DefensiveStompManager(player, jumpParams)
	EdithMod.FlightFallBehavior(player, jumpdata, jumpParams)
	Jump.SetBombJump(player, jumpParams)
	EdithMod.BombFall(player, jumpdata, jumpParams)
end, JumpParams.EdithJump)
-- #endregion Durante el salto

-- #region Aterrizaje
---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function ExecuteStompSequence(player, jumpParams)
	EdithMod.CriticalStompManager(player, jumpParams)
	EdithMod.StompKnockbackManager(player, jumpParams)
	EdithMod.StompCooldownManager(player, jumpParams)
	EdithMod.StompDamageManager(player, jumpParams)
	EdithMod.StompRadiusManager(player, jumpParams)

	Land.EdithStomp(player, jumpParams, true)

	Land.TriggerLandenemyJump(player, jumpParams.StompedEntities, jumpParams.Knockback, 8, 2)
	Land.BombLandManager(player, jumpParams)
end

---@param player EntityPlayer
---@param edithTarget EntityEffect
local function ApplyLandingState(player, edithTarget)
	edithTarget:GetSprite():Play("Idle")
	player:SetMinDamageCooldown(LANDING_DAMAGE_COOLDOWN)
	player:MultiplyFriction(LANDING_FRICTION_MULT)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function ResetPropulsionState(player, jumpParams)
	local playerData = data(player)

	jumpParams.RocketLaunch = false
	playerData.RocketPropulsion = false
	playerData.BombPropulsion = false
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function HandlePitfallLand(player, jumpParams)
	TargetArrow.RemoveEdithTarget(player)
	jumpParams.BombStomp = false
end

---@param player EntityPlayer
---@param jumpData JumpData
---@param jumpParams EdithJumpStompParams
---@param edithTarget EntityEffect
local function HandleStompLand(player, jumpData, jumpParams, edithTarget)
	Land.TriggerLandAnimation(player)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), player.Color, jumpData)

	ExecuteStompSequence(player, jumpParams)
	ApplyLandingState(player, edithTarget)
	ResetPropulsionState(player, jumpParams)

	jumpParams.IsCriticalStomp = false

	EdithMod.StompTargetRemover(player)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
	if not JumpLib:IsPitfalling(player) then return end

	local sprite = player:GetSprite()

	if sprite:GetAnimation() ~= "JumpOut" then return end
	if sprite:GetFrame() > 1 then return end

	player:MultiplyFriction(0)

	local newPos = room:FindFreePickupSpawnPosition(player.Position, 0, true, false)
	local jumpIntData = JumpLib.Internal:GetData(player)

	jumpIntData.PitPos = newPos
	jumpIntData.JumpPos = newPos
end)

---@param player EntityPlayer
---@param jumpData JumpData
---@param pitfall boolean
mod:AddCallback(jumpCallbacks.ENTITY_LAND, function (_, player, jumpData, pitfall)
	ResetEdithScale(player)

	local edithTarget = TargetArrow.GetEdithTarget(player)
	if not edithTarget then return end

	local jumpParams = params(player)

	if pitfall then
		HandlePitfallLand(player, jumpParams)
		return
	end

	if Player.IsInTrapdoor(player) then return end

	HandleStompLand(player, jumpData, jumpParams, edithTarget)
end, JumpParams.EdithJump)
-- #endregion Aterrizaje

-- #region Stomp y Sal
---@param player EntityPlayer
AddEdithCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (player)
	local jumpParams = params(player)

	if jumpParams.RocketLaunch then return end

	EdithMod.CooldownUpdate(player, jumpParams)
end)

---@param ent Entity
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_KILL, function (_, _, ent)
	data(ent).KilledByStomp = true
end)

---NPCs (no jefes) con Sal muertos por un stomp: se cancela su update.
---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function (_, npc)
	if npc:IsBoss() then return end
	if not StatusEffects.EntHasStatusEffect(npc, "Salt") then return end
	if not data(npc).KilledByStomp then return end

	return true
end)
-- #endregion Stomp y Sal

-- #region Daño y objetos
---@param damage number
---@param source EntityRef
---@return boolean?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, _, damage, _, source)
	if source.Type == EntityType.ENTITY_NULL then return end

	local player = helpers.GetPlayerFromRef(source)

	if not player then return end
	if not Player.IsEdith(player, false) then return end
	if not Jump.IsJumping(player) then return end

	local isFamiliarDamage = source.Entity:ToFamiliar() ~= nil
	local isHeelsDamage = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS) and damage == MOMS_HEELS_DAMAGE

	if isFamiliarDamage or isHeelsDamage then
		return false
	end
end)

---Invulnerable durante la preparación del salto.
---@param player EntityPlayer
AddEdithCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (player)
	if not IsInJumpWindup(data(player)) then return end

	return false
end)

---@param ID CollectibleType
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function (_, ID, _, player)
	if helpers.When(ID, tables.RemoveTargetItems, false) then
		TargetArrow.RemoveEdithTarget(player)
	end

	if ID ~= CollectibleType.COLLECTIBLE_KAMIKAZE then return end
	if not Player.IsEdith(player, false) then return end
	if not Jump.IsJumping(player) then return end

	return true
end)

---@param bomb EntityBomb
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function (_, bomb)
	if not bomb:GetSprite():IsPlaying("Explode") then return end

	local radius = helpers.GetBombRadiusFromDamage(bomb.ExplosionDamage)

	for _, ent in ipairs(Isaac.FindInRadius(bomb.Position, radius, EntityPartition.PLAYER)) do
		local player = ent:ToPlayer() ---@cast player EntityPlayer

		if not Player.IsEdith(player, false) then goto continue end
		data(player).BombPropulsion = true
		EdithMod.ExplosionRecoil(player, params(player), bomb)

		::continue::
	end
end)

---@param player EntityPlayer
AddEdithCallback(ModCallbacks.MC_PRE_PLAYER_POCKET_ITEMS_SWAP, function (player)
	if Jump.IsJumping(player) then return end

	return true
end)
-- #endregion Daño y objetos

-- #region Cambio de sala
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
	Player.ForEachPlayerType(function (player)
		helpers.ChangeColor(player, nil, nil, nil, 1)
		TargetArrow.RemoveEdithTarget(player)
		params(player).CanJump = false
	end, enums.PlayerType.PLAYER_EDITH)
end)
-- #endregion Cambio de sala

-- #region Familiares
---@param fam EntityFamiliar
---@param jumpData JumpData
mod:AddCallback(jumpCallbacks.ENTITY_UPDATE_60, function (_, fam, jumpData)
	if not JumpLib:IsFalling(fam) then return end

	local player = fam:ToFamiliar().Player

	if params(player).IsDefensiveStomp then return end
	if not player.CanFly then return end
	if helpers.IsVestigeChallenge() then return end

	EdithMod.ApplyFallPhysics(fam, jumpData)
end, { tag = tables.JumpTags.EdithJump, type = EntityType.ENTITY_FAMILIAR, })
-- #endregion Familiares

-- #region Birthcake
---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_HIT, function (_, player, ent)
	if not BirthcakeRebaked then return end

	local birthcakeID = BirthcakeRebaked.Birthcake.ID

	if not player:HasTrinket(birthcakeID) then return end
	if not ModRNG.RandomBoolean(player:GetTrinketRNG(birthcakeID), BIRTHCAKE_SALT_CHANCE) then return end

	StatusEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, ent, BIRTHCAKE_SALT_FRAMES, player)
end)
-- #endregion Birthcake