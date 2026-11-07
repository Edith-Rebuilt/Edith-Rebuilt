---@diagnostic disable: undefined-global, param-type-mismatch, missing-return-value
local mod = EdithRebuilt

local enums = mod.Enums
local utils = enums.Utils

local game = utils.Game
local sfx = utils.SFX

local callbacks = enums.Callbacks
local status = enums.EdithStatusEffects

local VecOne = Vector.One
local data = mod.DataHolder.GetEntityData

local Stomp = {}

---@param parent EntityPlayer
---@param ent Entity
---@param isDefStomp boolean
---@param SaltedTime boolean
local function SaltEnemyManager(parent, ent, isDefStomp, SaltedTime)
	if not isDefStomp then return end
	mod.Modules.STATUS_EFFECTS.SetStatusEffect(status.SALTED, ent, SaltedTime, parent)
	data(ent).SaltType = data(parent).HoodLand and enums.SaltTypes.EDITHS_HOOD		
end

---@param parent EntityPlayer
---@param ent Entity
---@param damage number
---@param knockback number
local function DamageManager(parent, ent, damage, knockback)
	local FrozenMult = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.2 or 1
	damage = (damage * FrozenMult)

	local pushMult = mod.Modules.STATUS_EFFECTS.EntHasStatusEffect(ent, status.SALTED) and 2 or 1
	mod.Modules.LAND.LandDamage(ent, parent, damage, knockback * pushMult)
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number	
local function EntityInteractHandler(ent, parent, knockback)
	local isSalted = mod.Modules.STATUS_EFFECTS.EntHasStatusEffect(ent, status.SALTED)
	local knockbackMult = isSalted and 1.5 or 1

	mod.Modules.LAND.HandleEntityInteraction(ent, parent, knockback * knockbackMult)

	if ent.Type == EntityType.ENTITY_STONEY then
		ent:ToNPC().State = NpcState.STATE_SPECIAL
	end
end

---@param parent EntityPlayer
---@param ent Entity
---@param params EdithJumpStompParams
---@param saltedTime number
---@param numTears number
---@param maths table
local function HandleStompedEnemy(parent, ent, params, saltedTime, numTears, maths)
	EntityInteractHandler(ent, parent, params.Knockback)
	SaltEnemyManager(parent, ent, params.IsDefensiveStomp, saltedTime)

    local modules = mod.Modules

	if not modules.HELPERS.IsEnemy(ent) then return end

	if not params.IsDefensiveStomp then
		local volume = maths.exp(numTears, 1, 1.4)
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_HIT, parent, ent, params)
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume)
	end

	for _ = 1, numTears do
		DamageManager(parent, ent, params.Damage, params.Knockback)
	end

	if ent.HitPoints > params.Damage then return end

	Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_KILL, parent, ent, params)

	modules.LAND.AddExtraGore(ent, parent)
end

---Custom Edith stomp behavior
---@param parent EntityPlayer
---@param params EdithJumpStompParams
---@param breakGrid boolean
function Stomp.EdithStomp(parent, params, breakGrid)
	local modules = mod.Modules
	local maths = modules.MATHS
	local Helpers = modules.HELPERS
	local Player = modules.PLAYER
    local Land = modules.LAND

	local playerPos = parent.Position
	local saltedTime = maths.Round(maths.Clamp(120 * (Player.GetplayerTears(parent) / 2.73), 60, 360))
	local numTears = Player.GetNumTears(parent)

	local Capsules = {
		ShopItem = Capsule(playerPos, VecOne, 0, parent.Size),
		Pickup = Capsule(playerPos, VecOne, 0, 30),
		Stomp = Capsule(playerPos, VecOne, 0, params.Radius),
		Slot = Capsule(playerPos, VecOne, 0, parent.Size),
	}

	params.StompedEntities = Isaac.FindInCapsule(Capsules.Stomp)

	if not params.IsDefensiveStomp then
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP, parent, params)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Pickup, EntityPartition.PICKUP)) do
		Land.PickupManager(parent, ent)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.ShopItem, EntityPartition.PICKUP)) do
		Land.PickupManager(parent, ent, true)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Slot)) do
		Land.SlotLandManager(parent, ent)
	end

	for _, ent in ipairs(params.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto continue end
		HandleStompedEnemy(parent, ent, params, saltedTime, numTears, maths)
		::continue::
	end

	if breakGrid then
		Helpers.DestroyGrid(parent, params.Radius)
	end
end

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
local function TriggerBombExplosion(player, params)
    if params.RocketLaunch then return end

	local bombDamage = player:HasCollectible(CollectibleType.COLLECTIBLE_MR_MEGA) and 185 or 100

    game:BombExplosionEffects(player.Position, bombDamage, player:GetBombFlags(), Color.Default, player)

	if not mod.Modules.PLAYER.ShouldConsumeBomb(player) then return end
	player:AddBombs(-1)
end

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
---@param isEdith boolean
---@param isTEdith boolean
local function UpdateBombState(player, params, isEdith, isTEdith)
    if isEdith then
        if player:HasCollectible(CollectibleType.COLLECTIBLE_FAST_BOMBS) then
            params.Cooldown = 3
        end
        params.BombStomp = false
    elseif isTEdith then
        params.ParryBomb = false
    end
end

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
function Stomp.BombLandManager(player, params)
	local Player = mod.Modules.PLAYER
	local isEdith = Player.IsEdith(player, false)
	local isTEdith = Player.IsEdith(player, true)
	local isBombLand = isEdith and params.BombStomp or isTEdith and params.ParryBomb or false

	if not isBombLand then return end

	TriggerBombExplosion(player, params)
    UpdateBombState(player, params, isEdith, isTEdith)
end

return Stomp