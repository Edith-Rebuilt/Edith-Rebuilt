local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local sfx = utils.SFX
local tables = enums.Tables
local JumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local data = mod.DataHolder.GetEntityData
local Edith = {}

---@class EdithJumpStompParams
---@field Damage number
---@field Radius number
---@field Knockback number
---@field CanJump false
---@field Cooldown integer
---@field JumpStartPos Vector
---@field JumpStartDist number
---@field CoalBonus number
---@field BombStomp boolean
---@field RocketLaunch boolean
---@field IsDefensiveStomp boolean
---@field IsCriticalStomp boolean
---@field StompedEntities Entity[]

local function NewJumpStompParams()
	return {
		Damage = 0,
		Radius = 0,
		Knockback = 0,
		CanJump = false,
		Cooldown = 0,
		JumpStartPos = Vector(0, 0),
		JumpStartDist = 0,
		CoalBonus = 0,
		BombStomp = false,
		RocketLaunch = false,
		IsDefensiveStomp = false,
		IsCriticalStomp = false,
		StompedEntities = {},
	} --[[@as EdithJumpStompParams]]
end

---@param player EntityPlayer
function Edith.GetJumpStompParams(player)
	local playerData = data(player)
    playerData.JumpParams = playerData.JumpParams or NewJumpStompParams()

    return playerData.JumpParams
end

---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function Edith.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

---@param speed number
---@return integer
function Edith.GetStompCooldown(speed)
	return math.ceil(16 + (speed - 1) * -8)
end

---@param player EntityPlayer
---@param vestige boolean
function Edith.JumpTriggerManager(player, vestige)
	mod.Modules.JUMP.InitEdithJump(player, JumpTags.EdithJump, vestige)
end

---@param player EntityPlayer
---@return Direction
local function GetHeadDirection(player)
    local TargetArrow = mod.Modules.TARGET_ARROW
    if TargetArrow.GetEdithTargetDistanceSquared(player) <= 25 then
        return Direction.DOWN
    end
    return mod.Modules.VEC_DIR.VectorToDirection(TargetArrow.GetEdithTargetDirection(player))
end

---@param jumping boolean
---@param shooting boolean
---@param keyStomp boolean
---@return boolean
local function ShouldUpdateHeadDirection(jumping, shooting, keyStomp)
    return jumping or not shooting or keyStomp
end

---@param player EntityPlayer
---@param jumping boolean
---@param shooting boolean
---@param keyStomp boolean
function Edith.HeadDirectionManager(player, jumping, shooting, keyStomp)
    if not ShouldUpdateHeadDirection(jumping, shooting, keyStomp) then return end
    player:SetHeadDirection(GetHeadDirection(player), 1, true)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.CustomDropBehavior(player, jumpParams)
	if not mod.Modules.PLAYER.IsEdith(player, false) then return end	
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
	if jumpParams.Cooldown < 1 then return end

	player:SetActionHoldDrop(119)
end

---@param player EntityPlayer
---@param effects TemporaryEffects
---@param direction Vector
---@param distance number
local function HandleMarsAndPonyDash(player, effects, direction, distance)
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local hasAnyPonyEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_PONY)
		or effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY)

	if hasMarsEffect or hasAnyPonyEffect then
		Edith.EdithDash(player, direction, distance, 50)
	end

	if player.Velocity:LengthSquared() <= 9 then
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_PONY, -1)
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY, -1)
	end
end

---@param player EntityPlayer
---@param direction Vector
---@param distance number
local function HandleMovementBasedActiveDash(player, direction, distance)
	local primaryActiveSlot = player:GetActiveItemDesc(ActiveSlot.SLOT_PRIMARY)
	local activeItem = primaryActiveSlot.Item

	if activeItem == 0 then return end
	if not tables.MovementBasedActives[activeItem] then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then return end

	local maxItemCharge = Isaac.GetItemConfig():GetCollectible(activeItem).MaxCharges
	local totalItemCharge = primaryActiveSlot.Charge + primaryActiveSlot.BatteryCharge

	if totalItemCharge < maxItemCharge then return end

	Edith.EdithDash(player, direction, distance, 50)
	player:UseActiveItem(activeItem)
	player:SetActiveCharge(totalItemCharge - maxItemCharge, ActiveSlot.SLOT_PRIMARY)
end

---@param player EntityPlayer
function Edith.DashItemBehavior(player)
	local targetArrow = mod.Modules.TARGET_ARROW
	local edithTarget = targetArrow.GetEdithTarget(player)
	if not edithTarget then return end

	local effects = player:GetEffects()
	local direction = targetArrow.GetEdithTargetDirection(player, false)
	local distance = targetArrow.GetEdithTargetDistance(player)

	HandleMarsAndPonyDash(player, effects, direction, distance)
	HandleMovementBasedActiveDash(player, direction, distance)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.DefensiveStompManager(player, jumpParams)
	local modules = mod.Modules
	local Helpers = modules.HELPERS
	local config = Helpers.GetConfigData("EdithData") ---@cast config EdithData

	if not config then return end
	if Helpers.IsVestigeChallenge() then return end
	if not Helpers.IsKeyStompPressed(player) then return end
	if mod.Modules.JUMP.GetJumpFrame(player) ~= config.DefensiveStompWindow then return end

	jumpParams.IsDefensiveStomp = true

	modules.PLAYER.SetColorCooldown(player, -0.8, 10)
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 1, 0, false, 0.8)
end

---@param player EntityPlayer
---@param distance number
---@return boolean
local function ShouldTriggerFall(player, distance)
    local TargetArrow = mod.Modules.TARGET_ARROW
    return (TargetArrow.IsEdithTargetMoving(player) and distance <= 3600) or distance <= 100
end

---@param jumpdata JumpData
---@return number
local function GetFallSpeed(jumpdata)
    return 15 + (jumpdata.Height / 10)
end

---@param ent Entity
---@param jumpdata JumpData
function Edith.ApplyFallPhysics(ent, jumpdata)
    ent:MultiplyFriction(0.5)
    JumpLib:SetSpeed(ent, GetFallSpeed(jumpdata))
end

---@param jumpdata JumpData
local function PlayFallSound(jumpdata)
    if jumpdata.Fallspeed > 9 then return end
    sfx:Play(SoundEffect.SOUND_SHELLGAME)
end

---@param player EntityPlayer
---@param jumpdata JumpData
---@param jumpParams EdithJumpStompParams
function Edith.FlightFallBehavior(player, jumpdata, jumpParams)
    if jumpParams.IsDefensiveStomp then return end
    if not player.CanFly then return end

    local distance = mod.Modules.TARGET_ARROW.GetEdithTargetDistanceSquared(player)
    if not ShouldTriggerFall(player, distance) then return end
    if not JumpLib:IsFalling(player) then return end

    Edith.ApplyFallPhysics(player, jumpdata)
    PlayFallSound(jumpdata)
end

---@param player EntityPlayer
local function SpawnRocket(player)
	local TargetArrow = mod.Modules.TARGET_ARROW
	local TargetAnglev = TargetArrow.GetEdithTargetDirection(player, false):GetAngleDegrees()
	local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_ROCKET, 0, player.Position, Vector.Zero, player):ToBomb() ---@cast bomb EntityBomb
	bomb:SetRocketAngle(TargetAnglev)
	bomb:SetRocketSpeed(40)
	data(player).RocketPropulsion = true
	data(bomb).IsEdithRocket = true
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function RocketInAJarManager(player, jumpParams)
	local pData = data(player)

	if pData.RocketPropulsion then return end

	if mod.Modules.PLAYER.ShouldConsumeBomb(player) then
		player:AddBombs(-1)
	end

	SpawnRocket(player)

	sfx:Play(SoundEffect.SOUND_ROCKET_LAUNCH)

	Edith.ExplosionRecoil(player, jumpParams)
end	

---@param player EntityPlayer
---@param jumpData JumpData
---@param jumpParams EdithJumpStompParams
function Edith.BombFall(player, jumpData, jumpParams)
	local modules = mod.Modules
	local Helpers = modules.HELPERS

	if Helpers.IsVestigeChallenge() then return end
	if jumpParams.IsDefensiveStomp then return end
	if not jumpParams.BombStomp then 
		if jumpParams.RocketLaunch and not data(player).BombPropulsion then
			RocketInAJarManager(player, jumpParams)
		end
		return
	end

	local canFly = player.CanFly
	local speedBase = canFly and 20 or 10

	if canFly and modules.JUMP.GetFallFrame(player) == 0 then
		sfx:Play(SoundEffect.SOUND_SHELLGAME)
	end

	JumpLib:SetSpeed(player, speedBase + (jumpData.Height / 10))
	player:MultiplyFriction(0.5)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param bomb? EntityBomb
function Edith.ExplosionRecoil(player, jumpParams, bomb)
	if not mod.Modules.JUMP.IsJumping(player) then return end

	local edithFlags = jumpFlags.EdithJump
	local newFlags = mod.Modules.BIT_MASK.RemoveBitFlags(edithFlags, JumpLib.Flags.GRIDCOLL_NO_WALLS)

	JumpLib:Jump(player, {
		Height = 15,
		Speed = 2,
		Tags = JumpTags.EdithJump,
		Flags = newFlags,
	})

	local velTarget = (
		bomb and (player.Position - bomb.Position) or
		-player.Velocity
	):Resized(15)

	player.Velocity = velTarget
	jumpParams.RocketLaunch = true
end

---@param player EntityPlayer
---@param soundTab table
---@return number
local function GetJumpSoundPitch(player, soundTab)
    if soundTab.Pitch ~= 1.2 then return soundTab.Pitch end
    return soundTab.Pitch * mod.Modules.RNG.RandomFloat(player:GetDropRNG(), 1, 1.1)
end

---@param jumpParams EdithJumpStompParams
local function ResetStompState(jumpParams)
    jumpParams.StompedEntities = nil
    jumpParams.IsDefensiveStomp = false
end

---@param player EntityPlayer
local function PlayCooldownReadyFeedback(player)
    local EdithSave = mod.Modules.HELPERS.GetConfigData("EdithData") ---@cast EdithSave EdithData
    local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]

    sfx:Play(soundTab.SoundID, 2, 0, false, GetJumpSoundPitch(player, soundTab))
    mod.Modules.PLAYER.SetColorCooldown(player, 0.6, 5)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@return boolean
local function IsCooldownNearReady(player, jumpParams)
    return jumpParams.Cooldown == 1 and player.FrameCount > 20
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.CooldownUpdate(player, jumpParams)
    jumpParams.Cooldown = math.max(jumpParams.Cooldown - 1, 0)
    jumpParams.CanJump = jumpParams.Cooldown == 0

    if not IsCooldownNearReady(player, jumpParams) then return end

	PlayCooldownReadyFeedback(player)
	ResetStompState(jumpParams)
end

---@param bomb EntityBomb
mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, function(_, bomb)
	if not data(bomb).IsEdithRocket then return end
	if JumpLib:GetData(bomb).Height > 15 then return end

	JumpLib:QuitJump(bomb)
end)

---@param target EntityEffect
---@return number
local function GetMovementFriction(target)
    return target:GetSprite():IsPlaying("Blink") and 0.5 or 0.775
end

---@param player EntityPlayer
---@param target EntityEffect
---@param isMoving boolean
function Edith.TargetMovementManager(player, target, isMoving)
    local modules = mod.Modules
	local Player = modules.PLAYER

	if isMoving then
        local input = Player.GetMovementInput(player)
		local velMod = modules.MATHS.exp(player.MoveSpeed, 1, 1.075)

        target.Velocity = (target.Velocity + mod.Modules.VEC_DIR.GetMovementVector(input, 4.35)) * velMod
        target:MultiplyFriction(GetMovementFriction(target))
    else
        target:MultiplyFriction(0.8)
    end

    if Player.HasTanukiStatueEffect(player) then
        target.Velocity = target.Velocity * 0.2
    end
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.StompRadiusManager(player, jumpParams)
    local flightMult = player.CanFly and 1.25 or 1
    local range = mod.Modules.PLAYER.GetPlayerRange(player)
	local rangeMult = range / 9
    local factor = rangeMult - (1 - (rangeMult))
    local RocketLaunchMult = jumpParams.RocketLaunch and 1.2 or 1

    jumpParams.Radius = (((32 + factor) * flightMult) * RocketLaunchMult) * player.SpriteScale.X
end

local DAMAGE_BASE_INIT = 12.75
local DAMAGE_BASE_STEP = 5
local DAMAGE_STAT_DIVISOR = 5.25
local VESTIGE_FLAT = 40

---@param player EntityPlayer
---@param collectible CollectibleType
---@param mult number
---@return number
local function CollectibleMult(player, collectible, mult)
    return player:HasCollectible(collectible) and mult or 1
end

---@return number
local function GetCurrentChapter()
    local chapterDiv = game:IsGreedMode() and 1 or 2
    return math.ceil(level:GetStage() / chapterDiv)
end

---@param chapter number
---@return number
local function GetDamageBase(chapter)
    return DAMAGE_BASE_INIT + (DAMAGE_BASE_STEP * (chapter - 1))
end

---@param player EntityPlayer
---@return number
local function GetDamageStat(player)
    return player.Damage + ((player.Damage / DAMAGE_STAT_DIVISOR) - 1)
end

---@param player EntityPlayer
---@return number
local function GetTerraMult(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return 1 end
    return mod.Modules.RNG.RandomFloat(player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA), 0.5, 2)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@return table
local function GetStompMultipliers(player, jumpParams)
    local modules = mod.Modules
	local PlayerMod = modules.PLAYER
    local Math = modules.MATHS
    return {
        MultiShot = Math.Round(Math.exp(PlayerMod.GetNumTears(player), 1, 0.5), 2),
        Birthright = PlayerMod.PlayerHasBirthright(player) and 1.25 or 1,
        BloodClot = CollectibleMult(player, CollectibleType.COLLECTIBLE_BLOOD_CLOT, 1.1),
        Flight = player.CanFly and 1.35 or 1,
        RocketLaunch = jumpParams.RocketLaunch and 1.25 or 1,
        TanukiStatue = PlayerMod.HasTanukiStatueEffect(player) and 1.5 or 1,
        Terra = GetTerraMult(player),
		CritStomp = jumpParams.IsCriticalStomp and 1.5 or 1
	}
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
---@return number
local function ComputeRawDamage(player, params)
    local mults = GetStompMultipliers(player, params)
    local chapter = GetCurrentChapter()
    local base = GetDamageBase(chapter) + GetDamageStat(player)

    return (
        base *
        mults.MultiShot *
        mults.Birthright *
        mults.BloodClot *
        mults.Flight *
        mults.RocketLaunch *
        mults.TanukiStatue *
        mults.Terra *
		mults.CritStomp
    ) + (params.CoalBonus or 0) + (params.BombStomp and 100 or 0)
end

---@param player EntityPlayer
---@param rawDamage number
---@return number
local function ResolveFinalDamage(player, rawDamage)
    if mod.Modules.HELPERS.IsVestigeChallenge() then
        return VESTIGE_FLAT + player.Damage / 2
    end
    return math.max(mod.Modules.MATHS.Round(rawDamage, 2), 1)
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompDamageManager(player, params)
    if params.IsDefensiveStomp then
        params.Damage = 0
        return
    end

    params.Damage = ResolveFinalDamage(player, ComputeRawDamage(player, params))
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.StompKnockbackManager(player, jumpParams)
    local flightMult = player.CanFly and 1.15 or 1
	local criticalStompMult = jumpParams.IsCriticalStomp and 1.15 or 1
	jumpParams.Knockback = math.min(50, (7 ^ 1.2) * flightMult * criticalStompMult) * player.ShotSpeed
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.CriticalStompManager(player, jumpParams)
	if jumpParams.IsDefensiveStomp then return end

	local modules = mod.Modules

	jumpParams.IsCriticalStomp = modules.RNG.RandomBoolean(player:GetDropRNG(), modules.HELPERS.GetLuckInteractionChance(player.Luck))
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.StompCooldownManager(player, jumpParams)
    local Cooldown = Edith.GetStompCooldown(player.MoveSpeed)

    jumpParams.Cooldown = (jumpParams.IsDefensiveStomp and math.max(Cooldown - 5, 10) or Cooldown)
end

---@param player EntityPlayer
function Edith.StompTargetRemover(player)
	local modules = mod.Modules
	local TargetArrow = modules.TARGET_ARROW

	if modules.HELPERS.IsKeyStompPressed(player) or TargetArrow.IsEdithTargetMoving(player) then return end

	TargetArrow.RemoveEdithTarget(player)
end

---@param player EntityPlayer
---@param jumpData JumpData
local function PutEdithInTarget(player, jumpData)
	if not JumpLib:IsFalling(player) then return end
	if mod.Modules.MATHS.Round(jumpData.Height, 1) ~= 21.6 then return end
	if mod.Modules.TARGET_ARROW.GetEdithTargetDistanceSquared(player) > 361 then return end

	player:MultiplyFriction(0.2)
	JumpLib:SetSpeed(player, 30)
end

---@param player EntityPlayer
---@param isVestige boolean
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
function Edith.JumpMovement(player, isVestige, jumpParams, jumpData)
	if isVestige then return end
	if jumpParams.RocketLaunch then return end

    local TargetArrow = mod.Modules.TARGET_ARROW
	local targetDirection = TargetArrow.GetEdithTargetDirection(player, false)
	local targetDistance = TargetArrow.GetEdithTargetDistance(player)
	local div = (mod.Modules.HELPERS.IsKeyStompPressed(player) and player.CanFly) and 140 or 100

	Edith.EdithDash(player, targetDirection, targetDistance, div)
	PutEdithInTarget(player, jumpData)
end

---@param familiar EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (_, familiar)
	local player = familiar.Player

	if not mod.Modules.JUMP.IsJumping(player) then return end
	familiar.Velocity = player.Velocity
end, FamiliarVariant.BLOOD_BABY)

local critColor = Color(1, 1, 1, 1, 0.5)

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_HIT, function (_, player, ent, jumpParams)
	if not jumpParams.IsCriticalStomp then return end

	jumpParams.Cooldown = math.ceil(jumpParams.Cooldown * 0.75)
	player:SetColor(critColor, 5, 1000, true, true)
	sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE, 1.5, 2, false, 1.25)

	game:ShakeScreen(14)
end)

---@param ent Entity
---@param jumpParams EdithJumpStompParams
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_KILL, function (_, _, ent, jumpParams)
	if not jumpParams.IsCriticalStomp then return end

	ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
end)

return Edith