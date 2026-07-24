local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local saltTypes = enums.SaltTypes
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpParams = tables.JumpParams
local modules = mod.Modules
local Player = modules.PLAYER
local Math = modules.MATHS
local helpers = modules.HELPERS
local RNGMod = modules.RNG
local Edith = modules.EDITH
local Land = modules.LAND
local BitMask = modules.BIT_MASK
local Creeps = modules.CREEPS
local Jump = modules.JUMP
local utils = enums.Utils
local sfx = utils.SFX
local game = utils.Game
local data = mod.DataHolder.GetEntityData

local HOOD = {
    DAMAGE_BASE_MULT = 1.5,
    DAMAGE_FINAL_MULT = 3,
    TIMER_CLEAR_ROOM = 10,
    TIMER_COMBAT_ROOM = 240,
}

local maxCreep = 10
local saltDegrees = 360 / maxCreep

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = helpers.GetPlayerFromTear(tear)
    if not player then return end
    if Player.IsAnyEdith(player) then return end
    if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
    helpers.ForceSaltTear(tear, false)
end)

---@param playerData table
local function DecreaseHoodTimer(playerData)
    playerData.HoodJumpTimer = Math.Clamp((playerData.HoodJumpTimer or 0) - 1, 0, 90)
end

---@param player EntityPlayer
---@param playerData table
local function ManageFinishedCooldown(player, playerData)
    if playerData.HoodJumpTimer ~= 1 then return end

    local EdithSave = helpers.GetConfigData("EdithData") --[[@as EdithData]]
    local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]
    local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * RNGMod.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch

    sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
    Player.SetColorCooldown(player, 0.6, 5)
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
    if JumpLib:GetData(player).Jumping then return end

    local playerData = data(player)
    DecreaseHoodTimer(playerData)
    ManageFinishedCooldown(player, playerData)
end)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    local playerData = data(player)
    if Player.IsAnyEdith(player) then return end
    if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
    if not playerData.HoodJumpTimer or playerData.HoodJumpTimer ~= 0 then return end
    if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end

    playerData.HoodJumpTimer = game:GetRoom():IsClear() and HOOD.TIMER_CLEAR_ROOM or HOOD.TIMER_COMBAT_ROOM
    Jump.InitEdithJump(player, jumpTags.EdithsHoodJump)
end)

---@param player EntityPlayer
---@param params EdithJumpStompParams
local function SetJumpParams(player, params)
    params.Damage = (player.Damage * HOOD.DAMAGE_BASE_MULT) * HOOD.DAMAGE_FINAL_MULT
    params.Radius = 40
    params.Knockback = 15
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
local function TriggerLandEffects(player, params, jumpData)
    local playerData = data(player)
    playerData.HoodLand = true
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), Color.Default, jumpData)
    playerData.HoodLand = false
    Land.EdithStomp(player, params, false)
    Land.TriggerLandenemyJump(player, params.StompedEntities, params.Knockback, 10, 1.8)
end

---@param player EntityPlayer
local function SpawnSaltCreep(player)
    for i = 1, maxCreep do
        Creeps.SpawnSaltCreep(player, player.Position + Vector(0, 30):Rotated(saltDegrees * i), 0.1, 5, 1, 3, saltTypes.EDITHS_HOOD)
    end
end

---@param player EntityPlayer
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, player, jumpData)
    if Player.IsAnyEdith(player) then return end

    local params = Edith.GetJumpStompParams(player)
    SetJumpParams(player, params)
    TriggerLandEffects(player, params, jumpData)
    SpawnSaltCreep(player)
    player:SetMinDamageCooldown(30)
end, jumpParams.EdithsHoodJump)

mod:AddCallback(PRE_NPC_KILL.ID, function(_, npc, source)
    local player = helpers.GetPlayerFromRef(source)
    if not player then return end
	if not data(npc).SaltType then return end
    if not BitMask.HasBitFlags(data(npc).SaltType, saltTypes.EDITHS_HOOD --[[@as BitSet128]]) then return end

    helpers.SpawnSaltTears(player, npc, player:GetCollectibleRNG(items.COLLECTIBLE_EDITHS_HOOD), 4, 8)
end)