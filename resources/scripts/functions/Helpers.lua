---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local room = utils.Room
local misc = enums.Misc
local tables = enums.Tables
local ConfigDataTypes = enums.ConfigDataTypes
local saveManager = mod.SaveManager
local data = mod.DataHolder.GetEntityData

local Helpers = {}

function Helpers.IsDSSMenuOpen()
	return DeadSeaScrollsMenu.IsOpen() ~= nil
end

function Helpers.GetScreenCenter()
	local pos = room:WorldToScreenPosition(Vector(0,0)) - room:GetRenderScrollOffset() - game.ScreenShakeOffset	
	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)
	return Vector(rx * 2 + 13 * 26, ry * 2 + 7 * 26) / 2
end 

--[[Perform a Switch/Case-like selection.  
    `value` is used to index `cases`.  
    When `value` is `nil`, returns `default`.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value?    In
---@param cases     { [In]: Out }
---@param default?  Default
---@return Out|Default
function Helpers.When(value, cases, default)
    return value and cases[value] or default
end

--[[Perform a Switch/Case-like selection, like @{EdithRebuilt.When}, but takes a
    table of functions and runs the found matching case to return its result.  
    `value` is used to index `cases`.
    When `value` is `nil`, returns `default`, or runs it and returns its value if
    it is a function.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value? In
---@param cases { [In]: fun(): Out }
---@param default?  fun(): Default
---@return Out|Default
function Helpers.WhenEval(value, cases, default)
    local f = Helpers.When(value, cases)
    local v = (f and f()) or (default and default())
    return v
end

function Helpers.IsMirrorWorld()
	return room:IsMirrorWorld() or FFGRACE and FFGRACE:IsBoilerMirrorWorld()
end

---Helper grid destroyer function
---@param entity Entity
---@param radius number
function Helpers.DestroyGrid(entity, radius)
    radius = radius or entity.Size
    for i = 0, (room:GetGridSize()) do
		local grid = room:GetGridEntity(i)

		if not grid then goto continue end
		if (entity.Position - grid.Position):LengthSquared() > radius * radius then goto continue end
		if grid:GetType() == GridEntityType.GRID_DOOR then goto continue end

		grid:DestroyWithSource(false, EntityRef(entity))

		::continue::
    end
end

local baseRange = 6.5
local baseHeight = -23.45
local baseMultiplier = -70 / baseRange

---@param tear EntityTear
---@param rng RNG
local function ApplySharedTearPhysics(tear, rng)
	local ModRNG = mod.Modules.RNG
    local fallSpeedVar = ModRNG.RandomFloat(rng, 1.8, 2.2)
    tear.Height = baseHeight * 3
    tear.Velocity = tear.Velocity * ModRNG.RandomFloat(rng, 0.2, 0.6)
    tear.FallingAcceleration = ModRNG.RandomFloat(rng, 0.7, 1.6) * 3
    tear.FallingSpeed = baseMultiplier * fallSpeedVar
    tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
    tear.Scale = tear.CollisionDamage / 3.5
end

---@class TearConfig
---@field variant integer
---@field position Vector
---@field velocity Vector
---@field apply fun(tear: EntityTear, player: EntityPlayer)

---@param player EntityPlayer
---@param rng RNG
---@param minTears integer
---@param maxTears integer
---@param config TearConfig
function Helpers.ShootArchedTear(player, rng, minTears, maxTears, config)
    for _ = 1, rng:RandomInt(minTears, maxTears) do
        local tear = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            config.variant, 0,
            config.position,
            rng:RandomVector() * config.velocity:Length(),
            player
        ):ToTear() ---@cast tear EntityTear

        ApplySharedTearPhysics(tear, rng)
        config.apply(tear, player)
    end
end

---Makes the tear to receive a boost, increasing its speed and damage
---@param tear EntityTear	
---@param speed number
---@param dmgMult number
function Helpers.BoostTear(tear, speed, dmgMult)
	if data(tear).FakeLudo then return end
	local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end

	local nearEnemy = Helpers.GetNearestEnemy(player)

	if nearEnemy then
		tear.Velocity = (nearEnemy.Position - tear.Position)
	end

	tear.CollisionDamage = tear.CollisionDamage * dmgMult
	tear.Velocity = tear.Velocity:Resized(speed)
	tear:AddTearFlags(TearFlags.TEAR_KNOCKBACK)
end

--- returns a `ConfigDataTypes`, used for mod's menu data management
---@param Type ConfigDataTypes
function Helpers.GetConfigData(Type)
	if not saveManager:IsLoaded() then return end
	local config = saveManager:GetSettingsSave()

	if not config then return end

	local switch = {
		[ConfigDataTypes.EDITH] = config.EdithData --[[@as EdithData]], 
		[ConfigDataTypes.TEDITH] = config.TEdithData --[[@as TEdithData]], 
		[ConfigDataTypes.MISC] = config.MiscData --[[@as MiscData]], 
	}

	return Helpers.When(Type, switch)
end

---Converts seconds to game update frames
---@param seconds number
function Helpers.SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

---@param player EntityPlayer
function Helpers.GetNearestEnemy(player)
    local closestDistance = math.huge
    local closestEnemy
    local playerPos = player.Position

    for _, enemy in ipairs(Helpers.GetEnemies()) do
        if enemy:HasEntityFlags(EntityFlag.FLAG_CHARM) then goto continue end

        local enemyPos = enemy.Position
        local distanceToPlayer = enemyPos:DistanceSquared(playerPos)

        if distanceToPlayer >= closestDistance*closestDistance then goto continue end
        if not room:CheckLine(playerPos, enemyPos, LineCheckMode.PROJECTILE, 0, false, false) then goto continue end

        closestEnemy = enemy
        closestDistance = distanceToPlayer
        ::continue::
    end

    return closestEnemy
end

---@param ent Entity
---@return boolean
function Helpers.IsEnemy(ent)
	return (not ent:HasEntityFlags(EntityFlag.FLAG_CHARM) and ent:IsEnemy() and ent:IsActiveEnemy() and ent:IsVulnerableEnemy())
end

function Helpers.IsVestigeChallenge()
	return Isaac.GetChallenge() == enums.Challenge.CHALLENGE_VESTIGE or Helpers.GetConfigData(ConfigDataTypes.EDITH).EnableVestigeMode
end

function Helpers.IsGrudgeChallenge()
	return Isaac.GetChallenge() == enums.Challenge.CHALLENGE_GRUDGE or Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableGrudgeMode
end

---@param ent Entity
---@return number
function Helpers.GetPushFactor(ent)
	return math.max(0.01, 1 + (5 - ent.Mass) * 1/250)
end	

---Triggers a push to `pushed` from `pusher`
---@param pushed Entity
---@param pusher Entity
---@param strength number
function Helpers.TriggerPush(pushed, pusher, strength)
	pushed:AddVelocity(((pusher.Position - pushed.Position) * -1):Resized(strength))	
end

---Changes `Entity` velocity so now it goes to `Target`'s Position, `strenght` determines how fast it'll go
---@param Entity Entity
---@param Target Entity
---@param strenght number
---@return Vector
function Helpers.ChangeVelToTarget(Entity, Target, strenght)
	return ((Entity.Position - Target.Position) * -1):Normalized():Resized(strenght)
end

--- Helper function that returns a table containing all existing enemies in room
---@return Entity[]
function Helpers.GetEnemies()
    local enemyTable = {}
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if not Helpers.IsEnemy(ent) then goto continue end
        table.insert(enemyTable, ent)
		::continue::
    end
    return enemyTable
end

---@param entity Entity
---@return EntityPlayer?
function Helpers.GetPlayerFromTear(entity)
	local check = entity.Parent or entity.SpawnerEntity

	if not check then return end
	local checkType = check.Type

	local ent = nil

	if checkType == EntityType.ENTITY_PLAYER then
		ent = Helpers.GetPtrHashEntity(check):ToPlayer()
	elseif checkType == EntityType.ENTITY_FAMILIAR then
		ent = check:ToFamiliar().Player
	end

	return ent
end

---@param entity Entity|EntityRef
---@return Entity?
function Helpers.GetPtrHashEntity(entity)
	if not entity then return end
	entity = entity.Entity or entity

	for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
		if GetPtrHash(entity) == GetPtrHash(matchEntity) then
			return matchEntity
		end
	end
	return nil
end

---Returns `true` if Dogma's appear cutscene is playing
---@return boolean
function Helpers.IsDogmaAppearCutscene()
	local TV = Isaac.FindByType(EntityType.ENTITY_GENERIC_PROP, 4)[1]
	local Dogma = Isaac.FindByType(EntityType.ENTITY_DOGMA)[1]

	if not TV then return false end
	return TV:GetSprite():IsPlaying("Idle2") and Dogma ~= nil
end

---@param EntityRef EntityRef
---@return EntityPlayer?
function Helpers.GetPlayerFromRef(EntityRef)
	local ent = EntityRef.Entity

	if not ent then return nil end
	local familiar = ent:ToFamiliar()
	return ent:ToPlayer() or Helpers.GetPlayerFromTear(ent) or familiar and familiar.Player 
end

---Helper function to directly change `entity`'s color
---@param entity Entity
---@param red? number
---@param green? number
---@param blue? number
---@param alpha? number
function Helpers.ChangeColor(entity, red, green, blue, alpha)
	local color = entity.Color
	local Red = red or color.R
	local Green = green or color.G
	local Blue = blue or color.B
	local Alpha = alpha or color.A

	color:SetTint(Red, Green, Blue, Alpha)

	entity.Color = color
end

local backdropColors = tables.BackdropColors
local MortisBackdrop = tables.MortisBackdrop
local ColorRed = Color(1, 0, 0)

---@param effect EntityEffect
function Helpers.SetBloodEffectColor(effect)
    local IsMortis = Helpers.IsLJMortis()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local color = Color.Default
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = Helpers.GetWaterEffectColor()
		end,
		[EffectVariant.POOF02] = function()
			if IsMortis then
				color = Helpers.When(Helpers.GetMortisDrop(), tables.MortisBackdropColor, Color.Default)
            else
                color = backdropColors[BackDrop] or ColorRed
			end
		end,
		[EffectVariant.POOF01] = function()
			if hasWater then
				color = backdropColors[BackDrop]
			end
		end
	}
	Helpers.WhenEval(effect.Variant, switch)
    effect:SetColor(color, -1, 100, false, false)
end

---Function used to spawn Tainted Edith's birthright fire jets
---@param position Vector
---@param damage number
---@param mult? number
---@param scale? number
function Helpers.SpawnFireJet(position, damage, mult, scale)
	local Fire = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.FIRE_JET,
		0,
		position,
		Vector.Zero,
		nil
	)
	Fire.SpriteScale = Fire.SpriteScale * (scale or 1)
	Fire.CollisionDamage = damage * (mult or 1)

	return Fire
end

--Checks if player is pressing Edith's jump button
---@param player EntityPlayer
---@return boolean
function Helpers.IsKeyStompPressed(player)
	local customButtom = Helpers.GetConfigData(ConfigDataTypes.MISC).CustomActionKey
	local ctrlIdx = player.ControllerIndex

	local k_stomp =
		Input.IsButtonPressed(customButtom, ctrlIdx) or
        Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, ctrlIdx) or
        Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, ctrlIdx) or
		Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, ctrlIdx) or
        Input.IsActionPressed(ButtonAction.ACTION_DROP, ctrlIdx)
		return k_stomp
end

---Checks if player triggered Edith's jump button
---@param player EntityPlayer
---@return boolean
function Helpers.IsKeyStompTriggered(player)
	local customButtom = Helpers.GetConfigData(ConfigDataTypes.MISC).CustomActionKey
	local ctrlIdx = player.ControllerIndex

	local k_stomp =
		Input.IsButtonTriggered(customButtom, ctrlIdx) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, ctrlIdx) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, ctrlIdx) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, ctrlIdx) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, ctrlIdx)

	return k_stomp
end

---@param base Color
---@param overlay Color
---@return Color
local function BlendGibColor(base, overlay)
    local result = Color(1, 1, 1)
    local bTint = base:GetTint()
    local oTint = overlay:GetTint()
    local bOff  = base:GetOffset()
    local oOff  = overlay:GetOffset()
    local bCol  = base:GetColorize()

    result:SetTint(oTint.R + bTint.R - 1, oTint.G + bTint.G - 1, oTint.B + bTint.B - 1, 1)
    result:SetOffset(oOff.R + bOff.R, oOff.G + bOff.G, oOff.B + bOff.B)
    result:SetColorize(bCol.R, bCol.G, bCol.B, bCol.A)

    return result
end

---@param parent Entity
---@param Number number
---@param speed number?
---@param color Color?
---@param inheritParentVel boolean?
function Helpers.SpawnSaltGib(parent, Number, speed, color, inheritParentVel)
    local finalColor = color and BlendGibColor(parent.Color, color) or Color.Default

    for _ = 1, Number do
        local saltGib = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.TOOTH_PARTICLE,
            0,
            parent.Position,
            RandomVector():Resized(speed or 3),
            parent
        ):ToEffect() ---@cast saltGib EntityEffect

        saltGib.Color = finalColor

        if inheritParentVel then
            saltGib.Velocity = saltGib.Velocity + parent.Velocity
        end
    end
end

local WaterBlueColor = Color(0.7, 0.75, 1)
function Helpers.GetWaterEffectColor()
	local waterColor = room:GetFXParams().WaterEffectColor

	return (waterColor.R == 1 and waterColor.G == 1 and waterColor.B == 1) and WaterBlueColor or waterColor
end

---Helper function to find out how large a bomb explosion is based on the damage inflicted.
---@param damage number
---@return number
function Helpers.GetBombRadiusFromDamage(damage)
    if damage > 175 then
        return 105
    elseif damage <= 140 then
        return 75
    else
        return 90
    end
end

---Checks if player is in Last Judgement's Mortis 
---@return boolean
function Helpers.IsLJMortis()
	if not StageAPI then return false end
	if not LastJudgement then return false end

	local stage = LastJudgement.STAGE
	local IsMortis = StageAPI and (stage.Mortis:IsStage() or stage.MortisTwo:IsStage() or stage.MortisXL:IsStage())

	return IsMortis
end

local mortisBackdrop = tables.MortisBackdrop

---@return integer
function Helpers.GetMortisDrop()
	if not Helpers.IsLJMortis() then return 0 end

	if LastJudgement.UsingMorgueisBackdrop then
		return mortisBackdrop.MORGUE
	elseif LastJudgement.UsingMoistisBackdrop then
		return mortisBackdrop.MOIST
	else
		return mortisBackdrop.FLESH
	end
end

---@param player EntityPlayer
---@param pickup EntityPickup
function Helpers.CanPickupBePurchased(player, pickup)
	if not pickup:IsShopItem() then return false end

	local price = pickup.Price

	if price < 0 then
		return true
	else
		return player:GetNumCoins() >= price
	end
end

---Checks if player run is in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function Helpers.IsChap4()
	if Helpers.IsLJMortis() then return true end
	return Helpers.When(room:GetBackdropType(), tables.Chap4Backdrops, false)
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function (_, tear)
	local tearData = data(tear)
	if not tearData.IsEdithRebuiltSaltTear then return end

	local var, sprite, Path

	for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		var = ent.Variant
		sprite = ent:GetSprite()

		if not (var == EffectVariant.ROCK_POOF or var == EffectVariant.TOOTH_PARTICLE) then goto continue end
		if ent.Position:DistanceSquared(tear.Position) > 100 then goto continue end

		Path = var == EffectVariant.ROCK_POOF and tearData.ShatterSprite or tearData.SaltGibsSprite

		if var == EffectVariant.TOOTH_PARTICLE then
			if ent.SpawnerEntity then goto continue end
			ent.Color = tear.Color
		end

		sprite:ReplaceSpritesheet(0, misc.TearPath .. Path .. ".png", true)
		::continue::
	end
end)

---@param tear EntityTear
---@param IsBlood boolean
---@param isTainted boolean
local function doEdithTear(tear, IsBlood, isTainted)
	local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end

	local tearData = data(tear)

	if tearData.IsEdithRebuiltSaltTear then return end

	local tearSizeMult = player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and 1 or 0.85

	local path = (isTainted and (IsBlood and "burnt_blood_salt_tears" or "burnt_salt_tears") or (IsBlood and "blood_salt_tears" or "salt_tears"))
	local newSprite = misc.TearPath .. path .. ".png"

	tear.Scale = tear.Scale * tearSizeMult

	tear:ChangeVariant(TearVariant.ROCK)
	
	tearData.ShatterSprite = (isTainted and (IsBlood and "burnt_blood_salt_shatter" or "burnt_salt_shatter") or (IsBlood and "blood_salt_shatter" or "salt_shatter"))
	tearData.SaltGibsSprite = (isTainted and (IsBlood and "burnt_blood_salt_gibs" or "burnt_salt_gibs") or (IsBlood and "blood_salt_gibs" or "salt_gibs"))
	
	tear:GetSprite():ReplaceSpritesheet(0, newSprite, true)
	tear.Color = player.Color
	tearData.IsEdithRebuiltSaltTear = true
end

---Forces tears to look like salt tears. `tainted` argument sets tears for Tainted Edith
---@param tear EntityTear
---@param tainted boolean
function Helpers.ForceSaltTear(tear, tainted)
	local IsBloodTear = Helpers.When(tear.Variant, tables.BloodytearVariants, false)
	doEdithTear(tear, IsBloodTear, tainted)
	tear:Update()
end

---@param tear EntityTear
---@param rng RNG
function Helpers.TurnTearToTerraTear(tear, rng)
	tear.CollisionDamage = tear.CollisionDamage * mod.Modules.RNG.RandomFloat(rng, 0.5, 2)
	tear:AddTearFlags(TearFlags.TEAR_ROCK)
	tear:ChangeVariant(TearVariant.ROCK)
end

---@param wisp Entity
---@param ID CollectibleType
function Helpers.IsModItemWisp(wisp, ID)
	if not wisp:ToFamiliar() then return false end
	return wisp.Variant == FamiliarVariant.WISP and wisp.SubType == ID
end

---@param locust Entity
---@param ID CollectibleType
function Helpers.IsModItemLocust(locust, ID)
	if not locust:ToFamiliar() then return false end
	return locust.Variant == FamiliarVariant.ABYSS_LOCUST and locust.SubType == ID
end

local NoColor = Color(0, 0, 0, 0)

function Helpers.TriggerPerfectParryFlash(player)
	ItemOverlay.Show(enums.Giantbook.PERFECT_PARRY, 3, player)
	ItemOverlay.GetSprite().Color = NoColor
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()	
	if ItemOverlay.GetOverlayID() ~= enums.Giantbook.PERFECT_PARRY then return end

	local overlaySprite = ItemOverlay.GetSprite()
	local frame = overlaySprite:GetFrame()
	
	if frame == 0 then
		local tEdithConfig = Helpers.GetConfigData(ConfigDataTypes.TEDITH) --[[@as TEdithData]]
		local color = tEdithConfig.ParryFlashColor
		local contrast = tEdithConfig.ParryFlashContrast
		local brightness = tEdithConfig.ParryFlashBrightness

		game:SetColorModifier(ColorModifier(color.r, color.g, color.b, color.a, brightness, contrast), true, 1)
		Isaac.CreateTimer(function ()
			room:UpdateColorModifier(true, true, 0.15)
		end, 1, 1, false)
	elseif frame == 5 then
		overlaySprite:Stop(true)
		overlaySprite:Reset()
	end
end)

function Helpers.IsModChallenge()
	return Helpers.IsVestigeChallenge() or Helpers.IsGrudgeChallenge()
end

---@param luck number
---@return number
function Helpers.GetLuckInteractionChance(luck)
	return math.min(0.1 + (0.02 * luck), 0.5)
end

local SULFURIC = {
    DAMAGE_SCALE = 0.175,
    PUSH_FORCE = 20,
    BRIMSTONE_DURATION = 150,
}

---@param player EntityPlayer
---@param judasMult number
---@param carBatteryMult number
---@param ref EntityRef
---@param hitEnemies Entity[]
function Helpers.TriggerSulfuricFireDamage(player, judasMult, carBatteryMult, ref, hitEnemies)
    for _, enemy in pairs(hitEnemies) do
        local damage = player.Damage + (enemy.MaxHitPoints * SULFURIC.DAMAGE_SCALE)
        Helpers.SpawnFireJet(enemy.Position, damage * judasMult * carBatteryMult)
        Helpers.TriggerPush(enemy, player, SULFURIC.PUSH_FORCE)
        enemy:AddBrimstoneMark(ref, SULFURIC.BRIMSTONE_DURATION)
    end
end

---@param player EntityPlayer
---@param npc EntityNPC
function Helpers.SpawnSaltTears(player, npc, rng, min, max)
    rng = rng or player:GetCollectibleRNG(enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD)
    local randomTears = rng:RandomInt(min, max)
    local shotSpeed = player.ShotSpeed

    for _ = 1, randomTears do
        local tear = player:FireTear(npc.Position, rng:RandomVector():Resized(shotSpeed * 10), false, false, false, player, 1.2)
		Helpers.ForceSaltTear(tear, false)
        tear:AddTearFlags(player.TearFlags)
    end
end

---@param player EntityPlayer
---@return integer
function Helpers.GetEffigySlot(player)
    return player:GetActiveItemSlot(enums.CollectibleType.COLLECTIBLE_EFFIGY)
end

---@param player EntityPlayer
---@return integer
function Helpers.GetEffigyCharge(player)
    local slot = Helpers.GetEffigySlot(player)
    if slot == -1 then return 0 end
    return player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
end

return Helpers