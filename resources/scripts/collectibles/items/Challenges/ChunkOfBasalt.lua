local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local modules = mod.Modules
local Helpers = modules.HELPERS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local data = mod.DataHolder.GetEntityData

local CHUNK_OF_BASALT = {
    ROCK_DAMAGE_MULT = 2,
    DASH_COOLDOWN = 60,
    DASH_SPEED = 60,
    COOLDOWN_COLOR = Color(0.3, 0.3, 0.3),
    TOTAL_ROCKS = 8,
    VELOCITY_RESET_THRESHOLD = 7,
    VELOCITY_DAMAGE_DIVISOR = 5,
    SPLASH_DAMAGE_MULT = 0.75,
    FLICKER_INTERVAL = 20,
}

---@param player EntityPlayer
---@param playerData table
local function InitBasaltDash(player, playerData)
    if not Helpers.IsKeyStompTriggered(player) then return end
    if player:GetMovementDirection() == Direction.NO_DIRECTION then return end
    if playerData.IsBasaltDash then return end
    if playerData.BasaltCount > 0 then return end

    playerData.IsBasaltDash = true
    playerData.BasaltFlickering = 0
    sfx:Play(SoundEffect.SOUND_SHELLGAME)
    playerData.BasaltCount = CHUNK_OF_BASALT.DASH_COOLDOWN
    EdithMod.EdithDash(player, player:GetMovementInput():Normalized(), CHUNK_OF_BASALT.DASH_SPEED, 2)
end

---@param player EntityPlayer
---@param playerData table
local function ResetBasaltDash(player, playerData)
    local threshold = CHUNK_OF_BASALT.VELOCITY_RESET_THRESHOLD
    if player.Velocity:LengthSquared() > threshold * threshold then return end
    playerData.IsBasaltDash = false
end

---@param player EntityPlayer
---@param playerData table
local function CreateAfterimages(player, playerData)
    if not playerData.IsBasaltDash then return end
    player:CreateAfterimage(5, player.Position)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    local playerData = data(player)

    playerData.BasaltCount = playerData.BasaltCount or CHUNK_OF_BASALT.DASH_COOLDOWN

    ResetBasaltDash(player, playerData)
    CreateAfterimages(player, playerData)
    InitBasaltDash(player, playerData)
end)

---@param playerData table
local function ManageCooldownDowncount(playerData)
    if playerData.IsBasaltDash then return end
    playerData.BasaltCount = math.max((playerData.BasaltCount or 0) - 1, 0)
end

---@param player EntityPlayer
---@param playerData table
local function TriggerFinishedCooldown(player, playerData)
    if playerData.BasaltCount ~= 1 then return end
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    player:SetColor(CHUNK_OF_BASALT.COOLDOWN_COLOR, 5, -1, true, false)
end

---@param player EntityPlayer
---@param playerData table
local function CooldownFlickering(player, playerData)
    if playerData.BasaltCount > 0 then return end
    playerData.BasaltFlickering = (playerData.BasaltFlickering or 0) + 1

    if playerData.BasaltFlickering ~= CHUNK_OF_BASALT.FLICKER_INTERVAL then return end

    Player.SetColorCooldown(player, -0.6, 2)
    playerData.BasaltFlickering = 0
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    local playerData = data(player)

    ManageCooldownDowncount(playerData)
    TriggerFinishedCooldown(player, playerData)
    CooldownFlickering(player, playerData)
end)

---@param player EntityPlayer
---@param collider Entity
local function TriggerCollideEffects(player, collider)
    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
    game:ShakeScreen(6)
    Helpers.TriggerPush(player, collider, 10)
end

---@param player EntityPlayer
---@param collider Entity
local function TriggerDashDamage(player, collider)
    local damageFormula = player.Damage * (player.Velocity:Length() / CHUNK_OF_BASALT.VELOCITY_DAMAGE_DIVISOR)
    local capsule = Capsule(player.Position, Vector.One, 0, 80)
    local playerRef = EntityRef(player)

    collider:TakeDamage(damageFormula, 0, playerRef, 0)
    TriggerCollideEffects(player, collider)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
        if GetPtrHash(ent) ~= GetPtrHash(collider) then
            ent:TakeDamage(damageFormula * CHUNK_OF_BASALT.SPLASH_DAMAGE_MULT, 0, playerRef, 0)
            TriggerCollideEffects(player, ent)
        end
    end
end

---@param player EntityPlayer
local function SpawnShockwaves(player)
    for rocks = 1, CHUNK_OF_BASALT.TOTAL_ROCKS do
        CustomShockwaveAPI:SpawnCustomCrackwave(
            player.Position,
            player,
            40,
            rocks * (360 / CHUNK_OF_BASALT.TOTAL_ROCKS),
            1,
            1,
            player.Damage * CHUNK_OF_BASALT.ROCK_DAMAGE_MULT
        )
    end
end

---@param player EntityPlayer
---@param collider Entity
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function (_, player, collider)
    if not Helpers.IsEnemy(collider) then return end
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    if not data(player).IsBasaltDash then return end

    TriggerDashDamage(player, collider)
    SpawnShockwaves(player)

    player:SetMinDamageCooldown(30)
end)

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player)
    local playerData = data(player)
    if not playerData.IsBasaltDash then return end
    playerData.IsBasaltDash = false
    return false
end)

mod:AddCallback(ModCallbacks.MC_PLAYER_GRID_COLLISION, function(_, player)
    if not data(player).IsBasaltDash then return end
    game:ShakeScreen(10)
    SpawnShockwaves(player)
end)