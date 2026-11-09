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

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
function Parry.TaintedEdithHop(player, HopParams)
    local modules = mod.Modules
    local Land = modules.LAND

    local moveCharge = HopParams.HopMoveCharge / 100
    local birthrightCharge = HopParams.HopMoveBRCharge / 100
    local burnDamage = birthrightCharge * player.Damage / 2
    local burnDuration = math.ceil(birthrightCharge * 123)
    local playerRef = EntityRef(player)
    local cinderDuration = modules.MATHS.SecondsToFrames(
        4 * (moveCharge + birthrightCharge)
    )
    local playerPosition = player.Position

    local capsules = {
        hop = Capsule(playerPosition, VecOne, 0, HopParams.HopRadius),
        slot = Capsule(playerPosition, VecOne, 0, player.Size),
        pickup = Capsule(playerPosition, VecOne, 0, 30),
        shopItem = Capsule(playerPosition, VecOne, 0, player.Size),
    }

    for _, entity in ipairs(Isaac.FindInCapsule(capsules.shopItem, EntityPartition.PICKUP)) do
        Land.PickupManager(player, entity, true)
    end

    for _, entity in ipairs(Isaac.FindInCapsule(capsules.pickup, EntityPartition.PICKUP)) do
        Land.PickupManager(player, entity)
    end

    for _, entity in ipairs(Isaac.FindInCapsule(capsules.slot)) do
        Land.SlotLandManager(player, entity)
    end

    for _, entity in ipairs(Isaac.FindInCapsule(capsules.hop)) do
        Land.HandleEntityInteraction(entity, player, HopParams.HopKnockback)
        Land.LandDamage(entity, player, HopParams.HopDamage, HopParams.HopKnockback)

        if not modules.HELPERS.IsEnemy(entity) then
            goto continue
        end

        local npc = entity:ToNPC()
        if npc then
            npc:ApplyTearflagEffects(entity.Position, player.TearFlags, player, player.Damage)
        end

        modules.STATUS_EFFECTS.SetStatusEffect(
            status.CINDER,
            entity,
            cinderDuration,
            player
        )

        if birthrightCharge > 0 then
            entity:AddBurn(playerRef, burnDuration, burnDamage)
        end

        ::continue::
    end
end

---@param player EntityPlayer
---@return boolean
local function HasBirthright(player)
    return mod.Modules.PLAYER.PlayerHasBirthright(player)
end

---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param hasBirthright boolean
local function ParryTearManager(ent, HopParams, hasBirthright)
    local tear = ent:ToTear()
    if not tear then return end
    if data(tear).LudoTear then return end

    mod.Modules.HELPERS.BoostTear(
        tear,
        20,
        1.5 + (
            (HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 100
        )
    )

    if hasBirthright then
        tear:AddTearFlags(TearFlags.TEAR_BURN)
    end
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param isInsidePerfectCapsule boolean
local function ImpreciseParryManager(player, ent, HopParams, isInsidePerfectCapsule)
    if ent:ToTear() then return end

    local modules = mod.Modules
    local tearsMultiplier = modules.PLAYER.GetplayerTears(player) / 2.73
    local cinderTime = modules.MATHS.SecondsToFrames(
        math.min(4 * tearsMultiplier, 12)
    )
    local Helpers = modules.HELPERS
    local StatusEffect = modules.STATUS_EFFECTS
    local pushMultiplier =
        StatusEffect.EntHasStatusEffect(ent, status.CINDER) and 1.5 or 1

    Helpers.TriggerPush(ent, player, 20 * pushMultiplier)

    if not Helpers.IsEnemy(ent) then return end
    if isInsidePerfectCapsule then return end

    if HopParams.IsBlazingParry then
        ent:AddBurn(EntityRef(player), 123, 5)
    end

    ent:TakeDamage(HopParams.ParryDamage * 0.25, 0, EntityRef(player), 0)

    StatusEffect.SetStatusEffect(status.CINDER, ent, cinderTime, player)
end

---@param player EntityPlayer
---@param projectile EntityProjectile
---@param shouldTriggerFireJets boolean
local function ProjectilePerfectParry(player, projectile, shouldTriggerFireJets)
    local spawner = projectile.Parent or projectile.SpawnerEntity
    local target = spawner
        or mod.Modules.HELPERS.GetNearestEnemy(player)
        or projectile

    projectile.FallingAccel = -0.1
    projectile.FallingSpeed = 0
    projectile.Height = -23
    projectile:Deflect((target.Position - player.Position):Resized(25))

    if shouldTriggerFireJets then
        projectile:AddProjectileFlags(ProjectileFlags.FIRE_SPAWN)
    end
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param hasBirthright boolean
---@param cinderMultiplier number
local function ParryEnemy(player, ent, HopParams, hasBirthright, cinderMultiplier)
    local Helpers = mod.Modules.HELPERS
    local playerRef = EntityRef(player)
    local damageFlag = hasBirthright and DamageFlag.DAMAGE_FIRE or 0

    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

    for _ = 1, mod.Modules.PLAYER.GetNumTears(player) do
        ent:TakeDamage(
            HopParams.ParryDamage * cinderMultiplier,
            damageFlag,
            playerRef,
            0
        )
    end

    if hasBirthright then
        ent:AddBurn(playerRef, 123, 5)
    end

    if ent.HitPoints <= HopParams.ParryDamage then
        Isaac.RunCallback(callbacks.PERFECT_PARRY_KILL, player, ent)
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
        local npc = ent:ToNPC()
        if npc then
            npc.State = NpcState.STATE_SPECIAL
        end
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
---@param isTaintedEdith boolean
---@param hasBirthright boolean
local function PerfectParryManager(player, ent, HopParams, isTaintedEdith, hasBirthright)
    if ent:ToTear() then return end

    local modules = mod.Modules
    local Player = modules.PLAYER
    local projectile = ent:ToProjectile()
    local bomb = ent:ToBomb()
    local shouldTriggerFireJets =
        (isTaintedEdith and hasBirthright)
        or Player.IsJudasWithBirthright(player)
    local cinderMultiplier =
        modules.STATUS_EFFECTS.EntHasStatusEffect(ent, status.CINDER)
        and 1.25
        or 1

    Isaac.RunCallback(callbacks.PERFECT_PARRY, player, ent, HopParams)

    if projectile then
        ProjectilePerfectParry(player, projectile, shouldTriggerFireJets)
    elseif modules.HELPERS.IsEnemy(ent) then
        ParryEnemy(player, ent, HopParams, hasBirthright, cinderMultiplier)
    else
        ParryNeutralEntity(ent, bomb)
    end
end

---@param player EntityPlayer
---@param hasPerfectParry boolean
local function TriggerParryShockwave(player, hasPerfectParry)
    if not hasPerfectParry then return end
    game:MakeShockwave(player.Position, 0.035, 0.025, 2)
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith boolean
---@return number damage
---@return boolean hasBirthcake
local function CalcParryDamage(player, hopParams, isTaintedEdith)
    local modules = mod.Modules
    local Maths = modules.MATHS

    local rawFormula = (13.5 + player.Damage) / 1.5
    local birthrightMultiplier =
        player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
        and 1.25
        or 1
    local hasBirthcake =
        BirthcakeRebaked
        and player:HasTrinket(BirthcakeRebaked.Birthcake.ID)
        or false
    local multishotMultiplier = Maths.Round(
        Maths.exp(modules.PLAYER.GetNumTears(player), 1, 0.5),
        2
    )
    local damage =
        rawFormula
        * birthrightMultiplier
        * (hasBirthcake and 1.15 or 1)
        * multishotMultiplier

    if isTaintedEdith then
        local heat = hopParams.ParryHeat
        local heatBonus = 1 + (1.5 + heat) / 3
        local chargeBonus =
            1 + (hopParams.HopStaticCharge + hopParams.HopStaticBRCharge) / 400

        damage = damage * heatBonus * chargeBonus
    end

    return damage, hasBirthcake
end

---@param isTaintedEdith boolean
---@param perfectParry boolean
---@param hasBirthcake boolean
---@return number
local function CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake)
    if not isTaintedEdith then return 0 end
    if not perfectParry then return 25 end
    return hasBirthcake and 10 or 12
end

---@param entities Entity[]
---@return table<integer, boolean>
local function BuildEntityHashSet(entities)
    local entitySet = {}

    for _, entity in ipairs(entities) do
        entitySet[GetPtrHash(entity)] = true
    end

    return entitySet
end

---@param player EntityPlayer
---@return {imprecise: Capsule, perfect: Capsule, tear: Capsule}
local function GetParryCapsules(player)
    local playerPos = player.Position	

	return {
        imprecise = Capsule(playerPos, VecOne, 0, misc.ImpreciseParryRadius),
        perfect = Capsule(playerPos, VecOne, 0, misc.PerfectParryRadius),
        tear = Capsule(playerPos, VecOne, 0, misc.TearParryRadius),
    }
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith boolean
---@param capsules {imprecise: Capsule, perfect: Capsule, tear: Capsule}
---@param hasBirthright boolean
---@param perfectEntitySet table<integer, boolean>
---@return boolean perfectParry
---@return boolean enemiesInImpreciseParry
local function ProcessParryHits(player, hopParams, isTaintedEdith, capsules, hasBirthright, perfectEntitySet)
    local perfectParry = false
    local impreciseEntities = Isaac.FindInCapsule(
        capsules.imprecise,
        misc.ParryPartitions
    )
    local enemiesInImpreciseParry = #impreciseEntities > 0

    -- The original module also ran pickup/slot landing interactions from
    -- inside this per-entity loop. Run them once per landing instead.
    if enemiesInImpreciseParry then
        local Land = mod.Modules.LAND
        local pickupCapsule = Capsule(player.Position, VecOne, 0, 20)
        local slotCapsule = Capsule(player.Position, VecOne, 0, player.Size)

        for _, entity in ipairs(Isaac.FindInCapsule(pickupCapsule)) do
            Land.PickupManager(player, entity, false)
        end

        for _, entity in ipairs(Isaac.FindInCapsule(slotCapsule)) do
            Land.SlotLandManager(player, entity)
        end
    end

    -- Tear parries are considered perfect parries, as in the original module.
    for _, entity in ipairs(
        Isaac.FindInCapsule(capsules.tear, EntityPartition.TEAR)
    ) do
        ParryTearManager(entity, hopParams, hasBirthright)
        Isaac.RunCallback(
            callbacks.PERFECT_PARRY,
            player,
            entity,
            hopParams
        )
        perfectParry = true
    end

    for _, entity in ipairs(impreciseEntities) do
        local isInsidePerfectCapsule =
            perfectEntitySet[GetPtrHash(entity)] == true

        ImpreciseParryManager(
            player,
            entity,
            hopParams,
            isInsidePerfectCapsule
        )
    end

    for _, entity in ipairs(hopParams.ParriedEnemies) do
        PerfectParryManager(
            player,
            entity,
            hopParams,
            isTaintedEdith,
            hasBirthright
        )
        perfectParry = true
    end

    return perfectParry, enemiesInImpreciseParry
end

---@param player EntityPlayer
---@param entities Entity[]
---@param knockback number
local function TriggerParryKnockback(player, entities, knockback)
    mod.Modules.LAND.TriggerLandenemyJump(
        player,
        entities,
        knockback,
        8,
        2
    )
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith boolean
---@param perfectParry boolean
---@param hasBirthcake boolean
local function ResolveParryCooldown(player, hopParams, isTaintedEdith, perfectParry, hasBirthcake)
    -- A numeric value supplied by POST_PARRY_LAND takes precedence.
    -- This intentionally accepts 0 as a valid override.
    if hopParams.ParryCooldown == nil then
        local heatAdd = math.ceil(30 * hopParams.ParryHeat)
        hopParams.ParryCooldown =
            CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake)
            + heatAdd
    end

    data(player).MaxParryCooldown = hopParams.ParryCooldown
end

---Manages Tainted Edith and Burnt Hood parry landings.
---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith? boolean
---@return boolean? perfectParry
---@return boolean? enemiesInImpreciseParry
function Parry.ParryLandManager(player, hopParams, isTaintedEdith)
    if not player or not player:ToPlayer() then
        return
    end

    isTaintedEdith = isTaintedEdith == true

    local capsules = GetParryCapsules(player)
    local hasBirthright = HasBirthright(player)
    local damageFormula, hasBirthcake =
        CalcParryDamage(player, hopParams, isTaintedEdith)

    hopParams.ParryDamage = damageFormula
    hopParams.ParriedEnemies = Isaac.FindInCapsule(
        capsules.perfect,
        misc.ParryPartitions
    )
    -- Keep geometric overlap detection independent from callback edits to
    -- the public ParriedEnemies list.
    local perfectEntitySet = BuildEntityHashSet(hopParams.ParriedEnemies)

    hopParams.ImpreciseParriedEnemies = Isaac.FindInCapsule(
        capsules.imprecise,
        misc.ParryPartitions
    )

    -- Clear the output before dispatch so a stale value from a previous
    -- landing cannot accidentally become the next landing's override.
    hopParams.ParryCooldown = nil

    -- Pass the original table: callback mutations affect this landing.
    Isaac.RunCallback(
        callbacks.POST_PARRY_LAND,
        player,
        hopParams
    )

    local perfectParry, enemiesInImpreciseParry = ProcessParryHits(
        player,
        hopParams,
        isTaintedEdith,
        capsules,
        hasBirthright,
        perfectEntitySet
    )

    TriggerParryKnockback(player, hopParams.ImpreciseParriedEnemies, hopParams.ParryKnockback)
    TriggerParryKnockback(player,hopParams.ParriedEnemies,hopParams.ParryKnockback)

    local iFrames =
        (perfectParry and 30 or 25)
        + math.ceil(
            (
                hopParams.HopStaticCharge
                + hopParams.HopStaticBRCharge * 0.25
            ) / 4
        )

    player:SetMinDamageCooldown(iFrames)
    TriggerParryShockwave(player, perfectParry)

    local Helpers = mod.Modules.HELPERS
    if perfectParry
        and Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableParryFlash
    then
        Helpers.TriggerPerfectParryFlash(player)
    end

    ResolveParryCooldown(player, hopParams, isTaintedEdith, perfectParry, hasBirthcake)

    hopParams.IsParryJump = false
    hopParams.ParriedEnemies = {}
    hopParams.ImpreciseParriedEnemies = {}

    return perfectParry, enemiesInImpreciseParry
end

return Parry