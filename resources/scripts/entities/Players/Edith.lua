---@diagnostic disable: undefined-field, undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local JumpParams = tables.JumpParams
local modules = mod.Modules
local EdithMod = modules.EDITH
local Land = modules.LAND
local TargetArrow = modules.TARGET_ARROW
local effects = modules.STATUS_EFFECTS
local helpers = modules.HELPERS
local Player = modules.PLAYER
local ModRNG = modules.RNG
local Jump = modules.JUMP
local StatusEffects = modules.STATUS_EFFECTS
local data = mod.DataHolder.GetEntityData
local params = EdithMod.GetJumpStompParams

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
local function EdithTeleportManager(player)
	if not player:GetSprite():IsPlaying("TeleportDown") then return end
	JumpLib:QuitJump(player)
	TargetArrow.RemoveEdithTarget(player, false)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
	local pData = data(player)

	pData.BaseSpriteScale = player.SpriteScale
	pData.JumpCount = 0
end)

---@param player EntityPlayer
local function SetInitJumpState(player)
	if helpers.IsVestigeChallenge() then return end
	if not helpers.IsKeyStompPressed(player) then return end
	if not EdithMod.GetJumpStompParams(player).CanJump then return end
	if Jump.IsJumping(player) then return end
	data(player).InitJump = true
end

---@param player EntityPlayer
---@param pData table
---@param jumpParams EdithJumpStompParams
local function TriggerEdithJump(player, pData, jumpParams)
	if pData.JumpCount ~= 0 then return end
	pData.InitJump = false
	player.SpriteScale = pData.BaseSpriteScale
	EdithMod.JumpTriggerManager(player, helpers.IsVestigeChallenge())
	jumpParams.CanJump = false
end

---@param pData table
local function ManageStretchSquashCounter(pData)
	pData.JumpCount = pData.JumpCount or 0
	pData.JumpCount = math.min(pData.JumpCount + 1, 8)

	if pData.JumpCount < 8 then return end
	pData.JumpCount = 0
end

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
		}
	}
}

---@param player EntityPlayer
---@param pData table
local function ManageStretchSquashScale(player, pData)
	local VecScale = FrameScale.BeforeJump[pData.JumpCount]

	if not VecScale then return end
	player.SpriteScale = pData.BaseSpriteScale * VecScale 
end

---@param player EntityPlayer
---@param pData table
local function ManageJumpStretchSquash(player, pData)
	if Jump.IsJumping(player) then return end
	if not pData.InitJump then return end

	local jumpParams = params(player)

	if jumpParams.Cooldown ~= 0 then return end
	if not jumpParams.CanJump then return end 

	ManageStretchSquashCounter(pData)
	TriggerEdithJump(player, pData, jumpParams)
	ManageStretchSquashScale(player, pData)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
	data(player).BaseSpriteScale = player.SpriteScale
end, CacheFlag.CACHE_SIZE)

---@param player EntityPlayer
local function HandleEdithInit(player)
	if player.FrameCount ~= 0 then return end

	Player.SetCustomSprite(player, false)
	if helpers.GetConfigData(enums.ConfigDataTypes.EDITH).SaltShakerSlot == 1 then
		player:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_SALTSHAKER)
		player:SetPocketActiveItem(enums.CollectibleType.COLLECTIBLE_SALTSHAKER, ActiveSlot.SLOT_POCKET, false)
	end
end

---@param player EntityPlayer
---@param state EdithUpdateState
local function HandleTargetSpawn(player, state)
	if player.FrameCount == 0 then return end
	if player.ControlsCooldown > 0 then return end
	local shouldSpawn = state.isMoving or state.isKeyStompPressed or (state.hasMarked and state.isShooting)
	if shouldSpawn and not state.isPitfall and not state.jumpData.Tags.EdithRebuilt_FlatStoneLand then
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

---@param player EntityPlayer
local function TriggerEdithJumpAnim(player)
	if not helpers.IsKeyStompPressed(player) then return end
	if player:GetSprite():IsPlaying("JumpStart") then return end
	if Jump.IsJumping(player) then return end
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	if not Player.IsEdith(player, false) then return end

	if player:IsDead() or helpers.IsDSSMenuOpen() then
		TargetArrow.RemoveEdithTarget(player)
		return
	end

	local pData = data(player)
	pData.BaseSpriteScale = pData.BaseSpriteScale or Vector.One

	local state = {
		isMoving = TargetArrow.IsEdithTargetMoving(player),
		isKeyStompPressed = helpers.IsKeyStompPressed(player),
		hasMarked  = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED),
		isShooting = Player.IsPlayerShooting(player),
		jumpData = JumpLib:GetData(player),
		isPitfall = JumpLib:IsPitfalling(player),
		isJumping = Jump.IsJumping(player),
		isVestige = helpers.IsVestigeChallenge(),
		jumpParams = params(player),
	} ---@cast state EdithUpdateState

	if not state.isPitfall then
		SetInitJumpState(player)
		ManageJumpStretchSquash(player, pData)
		HandleEdithInit(player)
		HandleTargetSpawn(player, state)
		TriggerEdithJumpAnim(player)
	end
	EdithTeleportManager(player)
	EdithMod.CustomDropBehavior(player, state.jumpParams)
	EdithMod.DashItemBehavior(player)

	HandleTargetManagers(player, TargetArrow.GetEdithTarget(player), state)
end)

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, function(_, player)
	local jumpParams = params(player)

	jumpParams.JumpStartPos = player.Position
	jumpParams.JumpStartDist = TargetArrow.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end

	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	jumpParams.CoalBonus = ModRNG.RandomFloat(rng, 0.5, 0.6) * jumpParams.JumpStartDist / 40
end, JumpParams.EdithJump)

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
    player:SetMinDamageCooldown(25)
    player:MultiplyFriction(0.1)
end

---@param player EntityPlayer
local function ResetPropulsionState(player)
	local playerData = data(player)

    params(player).RocketLaunch = false
    playerData.RocketPropulsion = false
    playerData.BombPropulsion = false
end

---@param player EntityPlayer
local function ResetEdithScale(player)
	if Jump.IsJumping(player) then return end
	player.SpriteScale = data(player).BaseSpriteScale
end	

---@param player EntityPlayer
---@param jumpData JumpData
---@param pitfall boolean
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, player, jumpData, pitfall)
    local edithTarget = TargetArrow.GetEdithTarget(player)
	ResetEdithScale(player)

	if not edithTarget then return end

	local jumpParams = params(player)

    if pitfall then
        TargetArrow.RemoveEdithTarget(player)
		jumpParams.BombStomp = false
        return
    end

	if Player.IsInTrapdoor(player) then return end

	Land.TriggerLandAnimation(player)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), player.Color, jumpData)
    ExecuteStompSequence(player, jumpParams)
    ApplyLandingState(player, edithTarget)
    ResetPropulsionState(player)

	jumpParams.IsCriticalStomp = false

    EdithMod.StompTargetRemover(player)
end, JumpParams.EdithJump)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	if not Player.IsEdith(player, false) then return end

	local jumpParams = params(player)

	if jumpParams.RocketLaunch then return end
	EdithMod.CooldownUpdate(player, jumpParams)
end)

---@param ent Entity
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_KILL, function(_, _, ent)
	data(ent).KilledByStomp = true
end)

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function (_, npc)
	if npc:IsBoss() then return end
	if not effects.EntHasStatusEffect(npc, "Salt") then return end
	if not data(npc).KilledByStomp then return end

	return true
end)

local function JumpInitScale(player)
	local frame = Jump.GetJumpFrame(player)
	local VecScale = FrameScale.AfterJump[frame]
	local pData = data(player)

	if not VecScale then 
		player.SpriteScale = pData.BaseSpriteScale
		return
	end
	player.SpriteScale = pData.BaseSpriteScale * VecScale
end

---@param player EntityPlayer
local function JumpFallScale(player)
	local frame = Jump.GetFallFrame(player)
	local canFly = player.CanFly
	local startframe = canFly and 1 or 5

	if frame < startframe then return end
	if canFly and params(player).IsDefensiveStomp then return end

	local mainTable = FrameScale.OnFalling
	local VecScale = mainTable[canFly][frame] or Vector(0.7, 1.3)

	player.SpriteScale = data(player).BaseSpriteScale * VecScale
end

---@param player EntityPlayer
---@param jumpdata JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function (_, player, jumpdata)
	if not Player.IsEdith(player, false) then return end

	local jumpParams = params(player)

	JumpInitScale(player)
	JumpFallScale(player)
	EdithMod.JumpMovement(player, helpers.IsVestigeChallenge(), jumpParams, jumpdata)
	EdithMod.DefensiveStompManager(player, jumpParams)
	EdithMod.FlightFallBehavior(player, jumpdata, jumpParams)
	Jump.SetBombJump(player, jumpParams)
	EdithMod.BombFall(player, jumpdata, jumpParams)
end, JumpParams.EdithJump)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
	Player.ForEachPlayerType(function(player)
		helpers.ChangeColor(player, nil, nil, nil, 1)
		TargetArrow.RemoveEdithTarget(player)
		params(player).CanJump = false
	end, enums.PlayerType.PLAYER_EDITH)
end)

---@param damage number
---@param source EntityRef
---@return boolean?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, _, damage, _, source)
	if source.Type == 0 then return end

	local ent = source.Entity
	local familiar = ent:ToFamiliar()
	local player = helpers.GetPlayerFromRef(source)

	if not player then return end
	if not Player.IsEdith(player, false) then return end
	if not Jump.IsJumping(player) then return end

	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end)

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player)
	if not Player.IsEdith(player, false) then return end
	if data(player).JumpCount <= 0 then return end

	return false
end)

---@param ID CollectibleType
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, ID, _, player)
    if helpers.When(ID, tables.RemoveTargetItems, false) then
        TargetArrow.RemoveEdithTarget(player)
    end

    if ID == CollectibleType.COLLECTIBLE_KAMIKAZE then
        if not Player.IsEdith(player, false) then return end
        if not Jump.IsJumping(player) then return end
        return true
    end
end)

---@param bomb EntityBomb
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
	if not bomb:GetSprite():IsPlaying("Explode") then return end
	local player
	for _, ent in ipairs(Isaac.FindInRadius(bomb.Position, helpers.GetBombRadiusFromDamage(bomb.ExplosionDamage), EntityPartition.PLAYER)) do
		player = ent:ToPlayer() ---@cast player EntityPlayer
		if not Player.IsEdith(player, false) then goto continue end
		data(player).BombPropulsion = true
		EdithMod.ExplosionRecoil(player, params(player), bomb)
		::continue::
	end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_POCKET_ITEMS_SWAP, function(_, player)
	if not Player.IsEdith(player, false) then return end
	if Jump.IsJumping(player) then return end

	return true
end)

---@param fam EntityFamiliar
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function(_, fam, jumpData)
	if not JumpLib:IsFalling(fam) then return end
	local player = fam:ToFamiliar().Player

	if EdithMod.GetJumpStompParams(player).IsDefensiveStomp then return end
	if not player.CanFly then return end

	EdithMod.ApplyFallPhysics(fam, jumpData)
end, {
	tag = tables.JumpTags.EdithJump,
	type = EntityType.ENTITY_FAMILIAR,
})

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent)
	if not (BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID)) then return end

	local rng = player:GetTrinketRNG(BirthcakeRebaked.Birthcake.ID)

	if not ModRNG.RandomBoolean(rng, 0.25) then return end
	StatusEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, ent, 120, player)
end)