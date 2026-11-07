---@diagnostic disable: undefined-global, param-type-mismatch, missing-return-value
local mod = EdithRebuilt

local enums = mod.Enums
local utils = enums.Utils

local game = utils.Game
local sfx = utils.SFX
local room = utils.Room

local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local sounds = enums.SoundEffect

local saveManager = mod.SaveManager
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
local function TryOpenKeyChest(pickup, player)
	local hasClip = player:HasTrinket(TrinketType.TRINKET_PAPER_CLIP)
	local hasPayToPlay = player:HasCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY)

	if not (hasClip or CanUseKey(player) or hasPayToPlay) then return end

	if not hasClip then
		if hasPayToPlay then
			player:AddCoins(-1)
		else
			player:TryUseKey()
		end
	end

	pickup:TryOpenChest(player)
end

---@param pickup EntityPickup
---@param player EntityPlayer
local function ChestManager(pickup, player)
	if not IsChest(pickup) then return end
	if pickup:GetSprite():GetAnimation() == "Open" then return end

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
			pickup:TryOpenChest(player)
		end
		return
	end

	if IsKeyRequiredChest(pickup) then
		TryOpenKeyChest(pickup, player)
		return
	end

	pickup:TryOpenChest()
end

---@param player EntityPlayer
---@param pickup EntityPickup
local function TriggerPickupCollide(player, pickup)
	local var = pickup.Variant
	local IsStopAnimPickup = mod.Modules.HELPERS.When(var, NonTriggerAnimPickupVar, false)
	local IsEternalHeart = (var == PickupVariant.PICKUP_HEART and pickup.SubType == HeartSubType.HEART_ETERNAL)

	if pickup:IsDead() then return end
	if pickup:IsShopItem() then return end
	if pickup.SubType == 0 then return end

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
function Land.PickupManager(player, ent, isShopItem)
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
function Land.SlotLandManager(parent, ent)
	local slot = ent:ToSlot()

	if not slot then return end
	if slot:GetState() == SlotState.DESTROYED then return end
	if not mod.Modules.HELPERS.When(ent.Variant, tables.TriggerDamageSlots, false) then return end

	parent:ForceCollide(ent, false)
	parent:TakeDamage(1, DamageFlag.DAMAGE_RED_HEARTS, EntityRef(ent), 0)
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
        sound = sounds.SOUND_EDITH_STOMP
    end

	sfx:Play(sound, volume)

	if hasWater then
		sfx:Play(sounds.SOUND_EDITH_STOMP_WATER, volume - 0.5)
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

-- local MortisColors = {
-- 	[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
-- 	[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
-- 	[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
-- }

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
function Land.SpawnLandGFX(player, landParams, IsChap4)
    local hasWater = room:HasWater()
	local Variant, SubType = GetEffectVariantAndSubType(hasWater, IsChap4)
	local BackDrop = room:GetBackdropType()
	local IsMortis = mod.Modules.HELPERS.IsLJMortis()
	local stompGFX = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        Variant,
		SubType,
        player.Position,
		Vector.Zero,
		player
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

    Land.SpawnLandGFX(player, landParams, IsChap4)

    if Helpers.GetConfigData(ConfigDataTypes.MISC).EnableShakescreen then
        game:ShakeScreen(landParams.ScreenShakeIntensity)
    end

    if landParams.GibAmount > 0 then
        Helpers.SpawnSaltGib(player, landParams.GibSpeed, landParams.GibSpeed, GibColor or Color.Default)
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
		isEdith and 15 / modules.EDITH.GetStompCooldown(player.MoveSpeed) or
		1
	)
	return cooldown
end

---@param player EntityPlayer
function Land.TriggerLandAnimation(player)
	local Player = mod.Modules.PLAYER

	if not Player.IsAnyEdith(player) then return end
	if Player.IsInTrapdoor(player) then return end

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

return Land