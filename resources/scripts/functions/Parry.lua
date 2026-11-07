---@diagnostic disable: undefined-global, param-type-mismatch, missing-return-value
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local misc = enums.Misc
local ConfigDataTypes = enums.ConfigDataTypes
local callbacks = enums.Callbacks
local status = enums.EdithStatusEffects
local VecOne = Vector.One
local data = mod.DataHolder.GetEntityData
local Parry = {}

---Tainted Edith hop land behavior
---@param parent EntityPlayer
---@param HopParams TEdithHopParryParams
function Parry.TaintedEdithHop(parent, HopParams)
    local modules = mod.Modules
    local Land = modules.LAND
	local Charge = HopParams.HopMoveCharge / 100
	local BRCharge = HopParams.HopMoveBRCharge / 100
	local burnDamage, burnDuration = BRCharge * parent.Damage / 2, math.ceil(BRCharge * 123)
	local PlayerRef = EntityRef(parent)
	local CinderDuration = modules.MATHS.SecondsToFrames(4 * (Charge + BRCharge))
	local playerPos = parent.Position
	local Capsules = {
		Hop = Capsule(playerPos, VecOne, 0, HopParams.HopRadius),
		Slot = Capsule(playerPos, VecOne, 0, parent.Size),
		Pickup = Capsule(playerPos, VecOne, 0, 30),
		ShopItem = Capsule(playerPos, VecOne, 0, parent.Size)
	}

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.ShopItem, EntityPartition.PICKUP)) do
		Land.PickupManager(parent, ent, true)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Pickup, EntityPartition.PICKUP)) do
		Land.PickupManager(parent, ent)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Slot)) do
		Land.SlotLandManager(parent, ent)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Hop)) do
		Land.HandleEntityInteraction(ent, parent, HopParams.HopKnockback)
		Land.LandDamage(ent, parent, HopParams.HopDamage, HopParams.HopKnockback)

		if not modules.HELPERS.IsEnemy(ent) then goto continue end

        local npc = ent:ToNPC()

        if npc then
            npc:ApplyTearflagEffects(ent.Position, parent.TearFlags, parent, parent.Damage)
        end

        modules.STATUS_EFFECTS.SetStatusEffect(status.CINDER, ent, CinderDuration, parent)
        if BRCharge > 0 then
            ent:AddBurn(PlayerRef, burnDuration, burnDamage)
        end

        ::continue::
	end
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
    local modules = mod.Modules
	local PickupCapsule = Capsule(player.Position, Vector.One, 0, 20)
	local SlotCapsule = Capsule(player.Position, Vector.One, 0, player.Size)

	for _, entity in ipairs(Isaac.FindInCapsule(PickupCapsule)) do
		modules.LAND.PickupManager(player, entity, false)
	end

	for _, entity in ipairs(Isaac.FindInCapsule(SlotCapsule)) do
		modules.LAND.SlotLandManager(player, entity)
	end

	if ent:ToTear() then return end

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
---@param hasBirthright boolean
---@param cinderMult number
local function ParryEnemy(player, ent, HopParams, hasBirthright, cinderMult)
	local Helpers = mod.Modules.HELPERS
	local PlayerRef = EntityRef(player)
	local damageFlag = hasBirthright and DamageFlag.DAMAGE_FIRE or 0

	sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

	for _ = 1, mod.Modules.PLAYER.GetNumTears(player) do
		ent:TakeDamage(HopParams.ParryDamage * cinderMult, damageFlag, PlayerRef, 0)
	end

	if hasBirthright then
		ent:AddBurn(PlayerRef, 123, 5)
	end

	if ent.HitPoints <= HopParams.ParryDamage then
		Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY_KILL, player, ent)
		mod.Modules.LAND.AddExtraGore(ent, player)
	end

	if HopParams.IsBlazingParry then
		Helpers.SpawnFireJet(ent.Position, HopParams.ParryDamage, 1, 1)
	end

	if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
		ent:Kill()
	end
end

---@param ent Entity
---@param bomb EntityBomb?
local function ParryNeutralEntity(ent, bomb)
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

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param IsTaintedEdith any
local function PerfectParryManager(player, ent, HopParams, IsTaintedEdith)
	if ent:ToTear() then return end

    local modules = mod.Modules
	local Player = modules.PLAYER
	local hasBirthright = Player.PlayerHasBirthright(player)
	local proj = ent:ToProjectile()
	local bomb = ent:ToBomb()
	local shouldTriggerFireJets = IsTaintedEdith and hasBirthright or Player.IsJudasWithBirthright(player)
	local cinderMult = modules.STATUS_EFFECTS.EntHasStatusEffect(ent, "Cinder") and 1.25 or 1

	Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent, HopParams)

	if proj then
		ProjectilePerfectParry(player, proj, shouldTriggerFireJets)
	elseif modules.HELPERS.IsEnemy(ent) then
		ParryEnemy(player, ent, HopParams, hasBirthright, cinderMult)
	else
		ParryNeutralEntity(ent, bomb)
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
    local modules = mod.Modules
	local Maths = modules.MATHS
    local rawFormula = (13.5 + player.Damage) / 1.5
    local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.25 or 1
    local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
    local multishotMult = Maths.Round(Maths.exp(modules.PLAYER.GetNumTears(player), 1, 0.5), 2)
    local damageFormula = (rawFormula * birthrightMult) * (hasBirthcake and 1.15 or 1) * multishotMult

    if isTaintedEdith then
		local heat = hopParams.ParryHeat
		local heatBonus = 1 + (1.5 + heat) / 3
		local damageIncrease = 1 + (hopParams.HopStaticCharge + hopParams.HopStaticBRCharge) / 400

        damageFormula = damageFormula * heatBonus * damageIncrease
    end
    return damageFormula, hasBirthcake
end

local function CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake)
    if not isTaintedEdith then return 0 end
    if not perfectParry then return 25 end
    local base = hasBirthcake and 10 or 12
    return base
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith boolean
---@param capsules {imprecise: Capsule, perfect: Capsule, tear: Capsule}
---@return boolean
---@return boolean
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
    mod.Modules.LAND.TriggerLandenemyJump(player, enemies, knockback, 8, 2)
end

---Helper function used to manage Tainted Edith and Burnt Hood's parry-lands
---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith? boolean
---@return boolean perfectParry
---@return boolean enemiesInImpreciseParry
function Parry.ParryLandManager(player, hopParams, isTaintedEdith)
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

    local iFrames = (perfectParry and 30 or 25) + math.ceil((hopParams.HopStaticCharge + hopParams.HopStaticBRCharge * 0.25) / 4)

    player:SetMinDamageCooldown(iFrames)
    TriggerParryShockwave(player, perfectParry)

	local Helpers = mod.Modules.HELPERS

    if perfectParry and Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableParryFlash then
        Helpers.TriggerPerfectParryFlash(player)
    end

	local heatAdd = math.ceil(6 * (5 * hopParams.ParryHeat))

    hopParams.ParryCooldown = CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake) + heatAdd

    data(player).MaxParryCooldown = hopParams.ParryCooldown or 0
    hopParams.IsParryJump = false
    hopParams.ParriedEnemies = {}
    hopParams.ImpreciseParriedEnemies = {}
    return perfectParry, enemiesInImpreciseParry
end

return Parry