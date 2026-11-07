local mod = EdithRebuilt

local modules = mod.Modules
local Land = modules.LAND
local EdithMod = modules.EDITH
local TEdithMod = modules.TEDITH
local TargetArrow = modules.TARGET_ARROW
local Player = modules.PLAYER
local ParryHop = modules.PARRY_HOP
local Stomp = modules.STOMP

local jumpParams = mod.Enums.Tables.JumpParams

---@param player EntityPlayer
---@param JumpData JumpData
local function ParryFlatStoneMiniJumps(_, player, JumpData)
    if not Player.IsEdith(player, true) then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_FLAT_STONE) then return end
    if JumpData.Tags.EdithRebuilt_FlatStoneLand then return end

    Land.TriggerFlatStoneMiniJumps(player, 7, 1.6)
    TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, ParryFlatStoneMiniJumps, jumpParams.TEdithJump)

---@param player EntityPlayer
---@param JumpData JumpData
local function StompFlatStoneMiniJumps(_, player, JumpData)
    if not Player.IsEdith(player, false) then return end

    local params = EdithMod.GetJumpStompParams(player)

    if params.IsDefensiveStomp then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_FLAT_STONE) then return end
    if JumpData.Tags.EdithRebuilt_FlatStoneLand then return end

    Land.TriggerFlatStoneMiniJumps(player, 7, 1.6)
    TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, StompFlatStoneMiniJumps, jumpParams.EdithJump)

---@param ent Entity
---@param data JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, data, pitfall)
    local player = ent:ToPlayer()
    if not player then return end
    if not Player.IsEdith(player, true) then return end

    Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, true), player.Color, data)
    ParryHop.ParryLandManager(player, TEdithMod.GetHopParryParams(player), true)
    player:MultiplyFriction(0.05)
end, {tag = "EdithRebuilt_FlatStoneLand_Parry"})

---@param ent Entity
---@param data JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, data, pitfall)
    local player = ent:ToPlayer()
    if not player then return end
    if not Player.IsEdith(player, false) then return end

    local params = EdithMod.GetJumpStompParams(player)
    local mult = Player.PlayerHasBirthright(player) and 0.9 or 0.75

    params.Damage = params.Damage * mult
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false, false), player.Color, data)
    Stomp.EdithStomp(player, params, true)
    Land.TriggerLandenemyJump(player, params.StompedEntities, params.Knockback, 6, 1.5)
    player:MultiplyFriction(0.05)
end, {tag = "EdithRebuilt_FlatStoneLand"})
