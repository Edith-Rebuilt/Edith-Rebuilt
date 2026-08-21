---@diagnostic disable: undefined-global, param-type-mismatch, missing-return-value
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local room = utils.Room
local misc = enums.Misc
local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local saveManager = mod.SaveManager
local MortisBackdrop = tables.MortisBackdrop
local sounds = enums.SoundEffect
local callbacks = enums.Callbacks
local status = enums.EdithStatusEffects
local VecOne = Vector.One
local data = mod.DataHolder.GetEntityData
local Land = {}

local damageFlags = DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR

---@param ent Entity
---@param dealEnt Entity
---@param damage number
---@param knockback number
function Land.LandDamage(ent, dealEnt, damage, knockback)
	local Helpers = mod.Modules.HELPERS
	if not Helpers.IsEnemy(ent) then return end

	ent:TakeDamage(damage, damageFlags, EntityRef(dealEnt), 0)
	Helpers.TriggerPush(ent, dealEnt, knockback)
end

local LandSounds = {
	Edith = {
		[1] = SoundEffect.SOUND_STONE_IMPACT, 
		[2] = sounds.SOUND_EDITH_STOMP,
		[3] = sounds.SOUND_FART_REVERB,
		[4] = sounds.SOUND_VINE_BOOM,
	},
	TEdith = {
		Hop = {
			[1] = SoundEffect.SOUND_STONE_IMPACT,
			[2] = sounds.SOUND_YIPPEE,
			[3] = sounds.SOUND_SPRING,
		},
		Parry = {
			[1] = SoundEffect.SOUND_ROCK_CRUMBLE,
			[2] = sounds.SOUND_PIZZA_TAUNT,
			[3] = sounds.SOUND_VINE_BOOM,
			[4] = sounds.SOUND_FART_REVERB,
			[5] = sounds.SOUND_SOLARIAN,
			[6] = sounds.SOUND_MACHINE,
			[7] = sounds.SOUND_MECHANIC,
			[8] = sounds.SOUND_KNIGHT,
			[9] = sounds.SOUND_BLOQUEO,
			[10] = sounds.SOUND_NAUTRASH,
			[11] = sounds.SOUND_HAWK_TUAH,
		}
	}
}

---@param tainted boolean
---@param isParryLand? boolean
---@return table
function Land.GetLandSoundTable(tainted, isParryLand)
	local TEdithSounds = LandSounds.TEdith
	return tainted and (isParryLand and TEdithSounds.Parry or TEdithSounds.Hop) or LandSounds.Edith
end

---@param ent Entity
---@param player EntityPlayer
function Land.AddExtraGore(ent, player)
	if not ent:ToNPC() then return end

	local modules = mod.Modules
	local ConfigType = modules.PLAYER.IsEdith(player, true) and ConfigDataTypes.TEDITH or ConfigDataTypes.EDITH
	local enabledExtraGore = modules.HELPERS.GetConfigData(ConfigType).EnableExtraGore

	if not enabledExtraGore then return end

	ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
	ent:MakeBloodPoof(nil, nil, 0.5)
	sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
end

local KeyRequiredChests = {
	[PickupVariant.PICKUP_LOCKEDCHEST] = true,
	[PickupVariant.PICKUP_ETERNALCHEST] = true,
	[PickupVariant.PICKUP_OLDCHEST] = true,
	[PickupVariant.PICKUP_MEGACHEST] = true,
}

---@param pickup EntityPickup
---@return boolean
local function IsKeyRequiredChest(pickup)
	return mod.Modules.HELPERS.When(pickup.Variant, KeyRequiredChests, false)
end

---@param pickup EntityPickup
-- -@return boolean
local function IsChest(pickup)
	local entName = EntityConfig.GetEntity(pickup.Type, pickup.Variant, pickup.SubType):GetName()
	return string.find(entName, "Chest") ~= nil
end

---@param player EntityPlayer
---@return boolean
local function CanUseKey(player)
	return (player:GetNumKeys() > 0 or player:HasGoldenKey())
end

---@param pickup EntityPickup
local function MegaChestManager(player, pickup)
	if not CanUseKey(player) then return end
	if pickup.SubType == 0 then return end
	local sprite = pickup:GetSprite()
	sprite:Play("Idle")

	if not sprite:IsPlaying("UseKey") or sprite:IsFinished("UseKey") then
		sprite:Play("UseKey")
	end

	player:TryUseKey()
end

---@param player EntityPlayer
local function StopStompAnim(player)
	local sprite = player:GetSprite()

	if not sprite:IsPlaying("BigJumpFinish") then return end
	sprite:Stop()
	player:StopExtraAnimation()	
end

local NonTriggerAnimPickupVar = {
	[PickupVariant.PICKUP_COLLECTIBLE] = true,
	[PickupVariant.PICKUP_TRINKET] = true,
	[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
	[PickupVariant.PICKUP_SHOPITEM] = true,
	[PickupVariant.PICKUP_PILL] = true,
	[PickupVariant.PICKUP_TAROTCARD] = true,
	[PickupVariant.PICKUP_LIL_BATTERY] = true,
	[PickupVariant.PICKUP_THROWABLEBOMB] = true,
	[PickupVariant.PICKUP_BED] = true,
	[PickupVariant.PICKUP_MOMSCHEST] = true,
	[PickupVariant.PICKUP_TROPHY] = true,
}

---@param pickup EntityPickup
---@param player EntityPlayer
local function ChestManager(pickup, player)
	if not IsChest(pickup) then return end
	if pickup:GetSprite():GetAnimation() == "Open" then return end
	local openedBombChest = false
	local var = pickup.Variant

	if room:GetType() == RoomType.ROOM_CHALLENGE then
		StopStompAnim(player)
		return
	end

	if var == PickupVariant.PICKUP_MEGACHEST then
		MegaChestManager(player, pickup)
		return
	end

	if var == PickupVariant.PICKUP_BOMBCHEST then
		if mod.Modules.PLAYER.IsEdith(player, false) then
			openedBombChest = true
			pickup:TryOpenChest(player)
			return
		end
	end

	if IsKeyRequiredChest(pickup) then
		local hasClip = player:HasTrinket(TrinketType.TRINKET_PAPER_CLIP)
		local hasPayToPlay = player:HasCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY)
		if hasClip or CanUseKey(player) or hasPayToPlay then
			if not hasClip then
				if hasPayToPlay then
					player:AddCoins(-1)
				else
					player:TryUseKey()
				end
			end
			pickup:TryOpenChest(player)
		end
		return
	end

	if var ~= PickupVariant.PICKUP_BOMBCHEST and not openedBombChest then
		pickup:TryOpenChest()
	end
end

---@param player EntityPlayer
---@param pickup EntityPickup
local function TriggerPickupCollide(player, pickup)
	local var = pickup.Variant
	local IsStopAnimPickup = mod.Modules.HELPERS.When(var, NonTriggerAnimPickupVar, false)
	local IsEternalHeart = (var == PickupVariant.PICKUP_HEART and pickup.SubType == HeartSubType.HEART_ETERNAL)

	if pickup:IsDead() then return end
	if pickup:IsShopItem() then return end

	if IsStopAnimPickup or IsEternalHeart then
		StopStompAnim(player)
	end

	player:ForceCollide(pickup, true)
end

---@param player EntityPlayer
---@param pickup EntityPickup
local function ShopItemManager(player, pickup)
	if not pickup:IsShopItem() then return end
	if not mod.Modules.HELPERS.CanPickupBePurchased(player, pickup) then return end

	StopStompAnim(player)
	player:ForceCollide(pickup, false)
end

---@param player EntityPlayer
---@param ent Entity
---@param isShopItem? boolean
local function PickupManager(player, ent, isShopItem)
	local pickup = ent:ToPickup()

	if not pickup then return end

	if isShopItem then
		ShopItemManager(player, pickup)
	else
		TriggerPickupCollide(player, pickup)
	end

	ChestManager(pickup, player)
end
---@param parent EntityPlayer
---@param ent Entity
local function SlotLandManager(parent, ent)
	local slot = ent:ToSlot()

	if not slot then return end
	if slot:GetState() == SlotState.DESTROYED then return end
	if not mod.Modules.HELPERS.When(ent.Variant, tables.TriggerDamageSlots, false) then return end

	parent:ForceCollide(ent, false)
	parent:TakeDamage(1, 0, EntityRef(ent), 0)
end

local stompBehavior = {
    [EntityType.ENTITY_TEAR] = function(ent, parent, _, _)
		local modules = mod.Modules

        if modules.PLAYER.IsEdith(parent, true) then return end
        local tear = ent:ToTear()
        if not tear then return end
        modules.HELPERS.BoostTear(tear, 25, 1.5)
    end,
    [EntityType.ENTITY_FIREPLACE] = function(ent, _, _, var)
        if var == 4 then return end
        ent:Die()
    end,
    [EntityType.ENTITY_FAMILIAR] = function(ent, parent, knockback, var)
		local Helpers = mod.Modules.HELPERS

        if not Helpers.When(var, tables.PhysicsFamiliar, false) then return end
        Helpers.TriggerPush(ent, parent, knockback * 1.3)

        local fam = ent:ToFamiliar()
        if not fam then return end

        if var == FamiliarVariant.CUBE_BABY then
            fam:TryThrow(EntityRef(parent), fam.Velocity, 0)
        end
    end,
    [EntityType.ENTITY_BOMB] = function(ent, parent, knockback, _)
		local modules = mod.Modules

        if modules.PLAYER.IsEdith(parent, true) then return end
        modules.HELPERS.TriggerPush(ent, parent, knockback)
    end,
    [EntityType.ENTITY_SHOPKEEPER] = function(ent, parent, _, _)
        if mod.Modules.PLAYER.IsEdith(parent, true) then return end
        ent:Kill()
    end,
    [EntityType.ENTITY_MOVABLE_TNT] = function(ent, _, _, _)
        ent:Kill()
    end,
}

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number
function Land.HandleEntityInteraction(ent, parent, knockback)
    local fn = stompBehavior[ent.Type]
    if not fn then return end
    fn(ent, parent, knockback, ent.Variant)
end

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
	Land.LandDamage(ent, parent, damage, knockback * pushMult)
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number	
local function EntityInteractHandler(ent, parent, knockback)
	local isSalted = mod.Modules.STATUS_EFFECTS.EntHasStatusEffect(ent, status.SALTED)
	local knockbackMult = isSalted and 1.5 or 1

	Land.HandleEntityInteraction(ent, parent, knockback * knockbackMult)

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

	if not mod.Modules.HELPERS.IsEnemy(ent) then return end

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

	Land.AddExtraGore(ent, parent)
end

---Custom Edith stomp behavior
---@param parent EntityPlayer
---@param params EdithJumpStompParams
---@param breakGrid boolean
function Land.EdithStomp(parent, params, breakGrid)
	local modules = mod.Modules
	local maths = modules.MATHS
	local Helpers = modules.HELPERS
	local Player = modules.PLAYER
	local playerPos = parent.Position
	local saltedTime = maths.Round(maths.Clamp(120 * (Player.GetplayerTears(parent) / 2.73), 60, 360))
	local numTears = Player.GetNumTears(parent)

	local Capsules = {
		Stomp = Capsule(playerPos, VecOne, 0, params.Radius),
		ShopItem = Capsule(playerPos, VecOne, 0, parent.Size),
		Pickup = Capsule(playerPos, VecOne, 0, 30),
		Slot = Capsule(playerPos, VecOne, 0, parent.Size),
	}

	params.StompedEntities = Isaac.FindInCapsule(Capsules.Stomp)

	if not params.IsDefensiveStomp then
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP, parent, params)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Pickup, EntityPartition.PICKUP)) do
		PickupManager(parent, ent)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.ShopItem, EntityPartition.PICKUP)) do
		PickupManager(parent, ent, true)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Slot)) do
		SlotLandManager(parent, ent)
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
function Land.BombLandManager(player, params)
	local Player = mod.Modules.PLAYER
	local isEdith = Player.IsEdith(player, false)
	local isTEdith = Player.IsEdith(player, true)
	local isBombLand = isEdith and params.BombStomp or isTEdith and params.ParryBomb or false

	if not isBombLand then return end

	TriggerBombExplosion(player, params)
    UpdateBombState(player, params, isEdith, isTEdith)
end

---Tainted Edith hop land behavior
---@param parent EntityPlayer
---@param HopParams TEdithHopParryParams
function Land.TaintedEdithHop(parent, HopParams)
	local Charge = HopParams.HopMoveCharge / 100
	local BRCharge = HopParams.HopMoveBRCharge / 100
	local burnDamage, burnDuration = BRCharge * parent.Damage / 2, math.ceil(BRCharge * 123)
	local PlayerRef = EntityRef(parent)
	local CinderDuration = mod.Modules.MATHS.SecondsToFrames(4 * (Charge + BRCharge))
	local playerPos = parent.Position
	local Capsules = {
		Hop = Capsule(playerPos, VecOne, 0, HopParams.HopRadius),
		Slot = Capsule(playerPos, VecOne, 0, parent.Size),
		Pickup = Capsule(playerPos, VecOne, 0, 30),
		ShopItem = Capsule(playerPos, VecOne, 0, parent.Size)
	}

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.ShopItem, EntityPartition.PICKUP)) do
		PickupManager(parent, ent, true)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Pickup, EntityPartition.PICKUP)) do
		PickupManager(parent, ent)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Slot)) do
		SlotLandManager(parent, ent)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Hop)) do
		Land.HandleEntityInteraction(ent, parent, HopParams.HopKnockback)
		Land.LandDamage(ent, parent, HopParams.HopDamage, HopParams.HopKnockback)

		if mod.Modules.HELPERS.IsEnemy(ent) then
			local npc = ent:ToNPC()

			if npc then
				npc:ApplyTearflagEffects(ent.Position, parent.TearFlags, parent, parent.Damage)
			end

			mod.Modules.STATUS_EFFECTS.SetStatusEffect(status.CINDER, ent, CinderDuration, parent)
			if BRCharge > 0 then
				ent:AddBurn(PlayerRef, burnDuration, burnDamage)
			end
		end
	end
end

---Function made to adjust landing volumes
---@param Percent number
---@return number
local function GetVolume(Percent)
	return (Percent / 100) ^ 2
end

---@param sound SoundEffect
---@param volume number
---@param IsChap4 boolean
---@param hasWater boolean
local function SfxFeedbackManager(sound, volume, IsChap4, hasWater)
    if isEdithJump and isVestige then
        sound = enums.SoundEffect.SOUND_EDITH_STOMP
    end

	sfx:Play(sound, volume)

	if hasWater then
		sfx:Play(enums.SoundEffect.SOUND_EDITH_STOMP_WATER, volume - 0.5)
	end

	if IsChap4 then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume)
	end
end

local EFFECT = {
    PLAYBACK_BASE = 1.3,
    PLAYBACK_VARIANCE = 1.5,
    RAND_SIZE_MIN = 0.8,
    RAND_SIZE_MAX = 1.0,
}

---@param hasWater boolean
---@param IsChap4 boolean
---@return EffectVariant, number
local function GetEffectVariantAndSubType(hasWater, IsChap4)
    if hasWater then return EffectVariant.BIG_SPLASH, 2 end
    return EffectVariant.POOF02, (IsChap4 and 3 or 1)
end

local jumpTags = enums.Tables.JumpTags

local EdithJumps = {
	jumpTags.EdithJump,
	jumpTags.EdithsHoodJump,
	jumpTags.EffigyHop,
	jumpTags.EffigyJump,
	jumpTags.SoulOfEdith
}

---@param jumpData JumpData
---@return boolean
local function IsEdithJump(jumpData)
	for _, tag in ipairs(EdithJumps) do
		if jumpData.Tags[tag] == true then
			return true
		end
	end

	return false
end

---@class FeedbackLandParams
---@field Size number
---@field SoundPick number
---@field Volume number
---@field ScreenShakeIntensity number
---@field GibAmount number
---@field GibSpeed number

---@param player EntityPlayer
---@return FeedbackLandParams
local function GetEdithLandParams(player)
	local modules = mod.Modules
	local Edith = modules.EDITH
    local Helpers = modules.HELPERS
    local d = data(player)

    local IsEdithsHood = d.HoodLand
    local isRocketLaunch = d.RocketLaunch
    local isDefensive = Edith.GetJumpStompParams(player).IsDefensiveStomp or IsEdithsHood
    local EdithData = Helpers.GetConfigData(ConfigDataTypes.EDITH) ---@cast EdithData EdithData

    local sizeBase = IsSoulOfEdith and 0.8 or (isDefensive and 0.6 or 0.7)
    return {
        Size = sizeBase * (isRocketLaunch and 1.25 or 1),
        SoundPick = EdithData.StompSound,
        Volume = GetVolume(EdithData.StompVolume) * (isDefensive and 1.5 or 2),
        ScreenShakeIntensity = isDefensive and 6 or (isRocketLaunch and 14 or 10),
        GibAmount = EdithData.DisableSaltGibs and 0 or (isRocketLaunch and 14 or 10),
        GibSpeed = isDefensive and 2 or 3,
    }
end

---@param IsParryLand boolean
---@return FeedbackLandParams
local function GetTEdithLandParams(IsParryLand)
    local TEdithData = mod.Modules.HELPERS.GetConfigData(ConfigDataTypes.TEDITH) ---@cast TEdithData TEdithData
    return {
        Size = IsParryLand and 0.7 or 0.5,
        SoundPick = IsParryLand and TEdithData.ParrySound or TEdithData.HopSound,
        Volume = GetVolume(TEdithData.Volume) * (IsParryLand and 1.5 or 1),
        ScreenShakeIntensity = IsParryLand and 6 or 3,
        GibAmount = not TEdithData.DisableSaltGibs and (IsParryLand and 6 or 2) or 0,
        GibSpeed = 2,
    }
end

local MortisColors = {
	[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
	[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
	[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
}

---@param Variant EffectVariant
---@param BackDrop BackdropType
---@param IsMortis boolean
---@return Color
local function GetLandEffectColor(Variant, BackDrop, IsMortis)
    local Helpers = mod.Modules.HELPERS
    local backColor = tables.BackdropColors
    local defColor = Color.Default
    local color

    if Variant == EffectVariant.BIG_SPLASH then
        color = Helpers.GetWaterEffectColor()
    elseif Variant == EffectVariant.POOF02 then
        color = BackDrop == BackdropType.DROSS and defColor or backColor[BackDrop]
    end

    if IsMortis then
        color = Helpers.When(Helpers.GetMortisDrop(), tables.MortisBackdropColor, defColor)
    end

    return color or defColor
end

---@param player EntityPlayer
---@param stompGFX Entity
---@param size number
---@param color Color
local function ApplyEffectVisuals(player, stompGFX, size, color)
	local modRNG = mod.Modules.RNG
    local rng = stompGFX:GetDropRNG()
    local randX = modRNG.RandomFloat(rng, EFFECT.RAND_SIZE_MIN, EFFECT.RAND_SIZE_MAX)
    local randY = modRNG.RandomFloat(rng, EFFECT.RAND_SIZE_MIN, EFFECT.RAND_SIZE_MAX)

    stompGFX:GetSprite().PlaybackSpeed = EFFECT.PLAYBACK_BASE * modRNG.RandomFloat(rng, 1, EFFECT.PLAYBACK_VARIANCE)
    stompGFX.SpriteScale = Vector(size * randX, size * randY) * player.SpriteScale.X
    stompGFX.Color = color
end

---@param player EntityPlayer
---@param landParams FeedbackLandParams
---@param IsChap4 boolean
local function SpawnLandGFX(player, landParams, IsChap4)
    local hasWater = room:HasWater()
	local Variant, SubType = GetEffectVariantAndSubType(hasWater, IsChap4)
	local BackDrop = room:GetBackdropType()
	local IsMortis = mod.Modules.HELPERS.IsLJMortis()
	local stompGFX = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        Variant, SubType,
        player.Position, Vector.Zero, player
    )

	ApplyEffectVisuals(player, stompGFX, landParams.Size, GetLandEffectColor(Variant, BackDrop, IsMortis))
end

---@param player EntityPlayer
---@param soundTable table
---@param GibColor Color
---@param jumpData JumpData
---@param IsParryLand? boolean
function Land.LandFeedbackManager(player, soundTable, GibColor, jumpData, IsParryLand)
    if not saveManager:IsLoaded() then return end
    if not saveManager:GetSettingsSave() then return end

    local Helpers = mod.Modules.HELPERS
    local IsChap4 = Helpers.IsChap4()
	local hasWater = room:HasWater()

    local landParams = (
		IsEdithJump(jumpData) and GetEdithLandParams(player) or
		GetTEdithLandParams(IsParryLand)
	)

    SpawnLandGFX(player, landParams, IsChap4)

    if Helpers.GetConfigData(ConfigDataTypes.MISC).EnableShakescreen then
        game:ShakeScreen(landParams.ScreenShakeIntensity)
    end

    if landParams.GibAmount > 0 then
        Helpers.SpawnSaltGib(player, landParams.GibSpeed, landParams.GibSpeed, GibColor or Color(1, 1, 1))
    end

    SfxFeedbackManager(Helpers.When(landParams.SoundPick, soundTable, 1), landParams.Volume, IsChap4, hasWater)
end

---@param player EntityPlayer
---@param enemyTable Entity[]
---@param knockback number
---@param height number
---@param speed number
function Land.TriggerLandenemyJump(player, enemyTable, knockback, height, speed)
	local Helpers = mod.Modules.HELPERS

	for _, ent in ipairs(enemyTable) do
		if not Helpers.IsEnemy(ent) then goto continue end

		local PushFactor = Helpers.GetPushFactor(ent)

		Helpers.TriggerPush(ent, player, knockback * 1.5)
		JumpLib:TryJump(ent, {
			Height = height * PushFactor,
			Speed = speed * PushFactor,
			Tags = "EdithRebuilt_EnemyJump",
			Flags = JumpLib.Flags.COLLISION_GRID
		})
		::continue::
	end
end

---@param player EntityPlayer
local function GetLandAnimationSpeed(player)
	local modules = mod.Modules
	local isEdith = modules.PLAYER.IsEdith(player, false)
	local cooldown = (
		isEdith and 15 / mod.Modules.EDITH.GetStompCooldown(player.MoveSpeed) or
		1
	)
	return cooldown
end

---@param player EntityPlayer
function Land.TriggerLandAnimation(player)
	local modules = mod.Modules 

	if not modules.PLAYER.IsAnyEdith(player) then return end
	if modules.PLAYER.IsInTrapdoor(player) then return end

	player:PlayExtraAnimation("BigJumpFinish")
	player:GetSprite().PlaybackSpeed = math.max(GetLandAnimationSpeed(player), 1)
end	

---@param player EntityPlayer
function Land.TriggerFlatStoneMiniJumps(player, height, speed)
	if not player:ToPlayer() then return end

	JumpLib:TryJump(player, {
		Height = height,
		Speed = speed,
		Tags = "EdithRebuilt_FlatStoneLand"
	})	
end

---@param ent Entity
---@param capsule1 Capsule
---@param capsule2 Capsule
local function IsEntInTwoCapsules(ent, capsule1, capsule2)
	local Capsule1Ents = Isaac.FindInCapsule(capsule1)
	local Capsule2Ents = Isaac.FindInCapsule(capsule2)
	local PtrHashEnt = GetPtrHash(ent)
	local IsInsideCapsule1, IsInsideCapsule2 = false, false

	for _, Entity in ipairs(Capsule1Ents) do
		if PtrHashEnt == GetPtrHash(Entity) then
			IsInsideCapsule1 = true
			break
		end
	end

	for _, Entity in ipairs(Capsule2Ents) do
		if PtrHashEnt == GetPtrHash(Entity) then
			IsInsideCapsule2 = true
			break
		end
	end

	return IsInsideCapsule1 and IsInsideCapsule2
end


---@param ent Entity
---@param HopParams TEdithHopParryParams
local function ParryTearManager(ent, HopParams)
	local tear = ent:ToTear()

	if not tear then return end
	if data(tear).LudoTear then return end

	mod.Modules.HELPERS.BoostTear(tear, 20, 1.5 + ((HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 100))

	if hasBirthright then
		tear:AddTearFlags(TearFlags.TEAR_BURN)
	end
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param ImpreciseParryCapsule Capsule
---@param PerfectParryCapsule Capsule
local function ImpreciseParryManager(player, ent, HopParams, ImpreciseParryCapsule, PerfectParryCapsule)
	local PickupCapsule = Capsule(player.Position, Vector.One, 0, 20)
	local SlotCapsule = Capsule(player.Position, Vector.One, 0, player.Size)

	for _, entity in ipairs(Isaac.FindInCapsule(PickupCapsule)) do
		PickupManager(player, entity, false)
	end

	for _, entity in ipairs(Isaac.FindInCapsule(SlotCapsule)) do
		SlotLandManager(player, entity)
	end

	if ent:ToTear() then return end

	local modules = mod.Modules
	local tearsMult = modules.PLAYER.GetplayerTears(player) / 2.73 
	local CinderTime = modules.MATHS.SecondsToFrames(math.min(4 * tearsMult, 12))
	local Helpers = modules.HELPERS
	local StatusEffect = modules.STATUS_EFFECTS
	local pushMult = StatusEffect.EntHasStatusEffect(ent, enums.EdithStatusEffects.CINDER) and 1.5 or 1

	Helpers.TriggerPush(ent, player, 20 * pushMult)

	if not Helpers.IsEnemy(ent) then return end
	if IsEntInTwoCapsules(ent, ImpreciseParryCapsule, PerfectParryCapsule) then return end

	if HopParams.IsBlazingParry then
		ent:AddBurn(EntityRef(player), 123, 5)
	end

	ent:TakeDamage(HopParams.ParryDamage * 0.25, 0, EntityRef(player), 0)
	StatusEffect.SetStatusEffect(enums.EdithStatusEffects.CINDER, ent, CinderTime, player)
end
local function ProjectilePerfectParry(player, proj, shouldTriggerFireJets)
	local spawner = proj.Parent or proj.SpawnerEntity
	local targetEnt = spawner or mod.Modules.HELPERS.GetNearestEnemy(player) or proj

	proj.FallingAccel = -0.1
	proj.FallingSpeed = 0
	proj.Height = -23
	proj:Deflect((targetEnt.Position - player.Position):Resized(25))

	if shouldTriggerFireJets then
		proj:AddProjectileFlags(ProjectileFlags.FIRE_SPAWN)
	end
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param IsTaintedEdith any
local function PerfectParryManager(player, ent, HopParams, IsTaintedEdith)
	if ent:ToTear() then return end

	local Player = mod.Modules.PLAYER
	local hasBirthright = Player.PlayerHasBirthright(player) 
	local damageFlag = hasBirthright and DamageFlag.DAMAGE_FIRE or 0
	local proj = ent:ToProjectile()
	local bomb = ent:ToBomb()
	local shouldTriggerFireJets = IsTaintedEdith and hasBirthright or Player.IsJudasWithBirthright(player)
	local PlayerRef = EntityRef(player)
	local Helpers = mod.Modules.HELPERS

	local CinderMult = mod.Modules.STATUS_EFFECTS.EntHasStatusEffect(ent, "Cinder") and 1.25 or 1

	Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent, HopParams)

	if proj then
		ProjectilePerfectParry(player, proj, shouldTriggerFireJets)
	elseif Helpers.IsEnemy(ent) then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

		for _ = 1, Player.GetNumTears(player) do
			ent:TakeDamage(HopParams.ParryDamage * CinderMult, damageFlag, PlayerRef, 0)
		end

		if hasBirthright then
			ent:AddBurn(PlayerRef, 123, 5)
		end

		if ent.HitPoints <= HopParams.ParryDamage then
			Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY_KILL, player, ent)
			Land.AddExtraGore(ent, player)
		end

		if HopParams.IsBlazingParry then
			Helpers.SpawnFireJet(ent.Position, HopParams.ParryDamage, 1, 1)
		end

		if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
			ent:Kill()
		end
	else
		if ent.Type == EntityType.ENTITY_STONEY then
			ent:ToNPC().State = NpcState.STATE_SPECIAL
		end

		if ent.Type == EntityType.ENTITY_SHOPKEEPER then
			ent:Kill()
		end

		if bomb then
			bomb:SetExplosionCountdown(0)
			bomb.ExplosionDamage = bomb.ExplosionDamage * 1.25
		end
	end
end

---@param player EntityPlayer
---@param isenemy? boolean
local function TriggerParryShockwave(player, isenemy)
	if not isenemy then return end
	game:MakeShockwave(player.Position, 0.035, 0.025, 2)
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith boolean
---@return number
---@return boolean
local function CalcParryDamage(player, hopParams, isTaintedEdith)
	local Maths = mod.Modules.MATHS
    local rawFormula = (13.5 + player.Damage) / 1.5
    local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.25 or 1
    local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
    local multishotMult = Maths.Round(Maths.exp(mod.Modules.PLAYER.GetNumTears(player), 1, 0.5), 2)
    local damageFormula = (rawFormula * birthrightMult) * (hasBirthcake and 1.15 or 1) * multishotMult

    if isTaintedEdith then
        local damageIncrease = 1 + (hopParams.HopStaticCharge + hopParams.HopStaticBRCharge) / 400
        damageFormula = damageFormula * damageIncrease
    end
    return damageFormula, hasBirthcake
end

local function CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake, staticChargeCooldownBonus)
    if not isTaintedEdith then return 0 end
    if not perfectParry then return 15 end
    local base = hasBirthcake and 10 or 12
    return base - staticChargeCooldownBonus
end

local function ProcessParryHits(player, hopParams, isTaintedEdith, capsules)
    local perfectParry = false
    local enemiesInImpreciseParry = false

    for _, ent in pairs(Isaac.FindInCapsule(capsules.tear, EntityPartition.TEAR)) do
        ParryTearManager(ent, hopParams)
		Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent, hopParams)
        perfectParry = true
    end

    enemiesInImpreciseParry = #Isaac.FindInCapsule(capsules.imprecise, misc.ParryPartitions) > 0

    for _, ent in pairs(Isaac.FindInCapsule(capsules.imprecise, misc.ParryPartitions)) do
        ImpreciseParryManager(player, ent, hopParams, capsules.imprecise, capsules.perfect)
    end

    for _, ent in pairs(hopParams.ParriedEnemies) do
        PerfectParryManager(player, ent, hopParams, isTaintedEdith)
        perfectParry = true
    end

    return perfectParry, enemiesInImpreciseParry
end

local function TriggerParryKnockback(player, enemies, knockback)
    Land.TriggerLandenemyJump(player, enemies, knockback, 8, 2)
end

---Helper function used to manage Tainted Edith and Burnt Hood's parry-lands
---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith? boolean
---@return boolean perfectParry
---@return boolean enemiesInImpreciseParry
function Land.ParryLandManager(player, hopParams, isTaintedEdith)
	if not player:ToPlayer() then return end

	local capsules = {
        imprecise = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius),
        perfect = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius),
        tear = Capsule(player.Position, Vector.One, 0, misc.TearParryRadius),
    }

    local damageFormula, hasBirthcake = CalcParryDamage(player, hopParams, isTaintedEdith)
    hopParams.ParryDamage = damageFormula
    hopParams.ParriedEnemies = Isaac.FindInCapsule(capsules.perfect, misc.ParryPartitions)
    hopParams.ImpreciseParriedEnemies = Isaac.FindInCapsule(capsules.imprecise, misc.ParryPartitions)

    local perfectParry, enemiesInImpreciseParry = ProcessParryHits(player, hopParams, isTaintedEdith, capsules)

	Isaac.RunCallback(callbacks.POST_PARRY_LAND, player)

    TriggerParryKnockback(player, hopParams.ImpreciseParriedEnemies, hopParams.ParryKnockback)
    TriggerParryKnockback(player, hopParams.ParriedEnemies, hopParams.ParryKnockback)

    local staticChargeCooldownBonus = math.ceil(4 * (hopParams.HopStaticCharge / 100))
    local iFrames = (perfectParry and 30 or 25) + math.ceil((hopParams.HopStaticCharge + hopParams.HopStaticBRCharge * 0.25) / 4)

    player:SetMinDamageCooldown(iFrames)
    TriggerParryShockwave(player, perfectParry)

	local Helpers = mod.Modules.HELPERS

    if perfectParry and Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableParryFlash then
        Helpers.TriggerPerfectParryFlash(player)
    end

    hopParams.ParryCooldown = CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake, staticChargeCooldownBonus)
    data(player).MaxParryCooldown = hopParams.ParryCooldown or 0
    hopParams.IsParryJump = false
    hopParams.ParriedEnemies = {}
    hopParams.ImpreciseParriedEnemies = {}
    return perfectParry, enemiesInImpreciseParry
end

return Land