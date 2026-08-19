local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local tables = enums.Tables
local jumpTags = tables.JumpTags
local modules = mod.Modules
local EdithMod = modules.EDITH
local Helpers = modules.HELPERS
local Jump = modules.JUMP
local BitMask = modules.BIT_MASK
local Maths = modules.MATHS
local TargetArrow = modules.TARGET_ARROW
local Player = modules.PLAYER
local Land = modules.LAND
local sfx = enums.Utils.SFX
local data = mod.DataHolder.GetEntityData

local EFFIGY = {
    MIN_USE_CHARGE = 1,
    MAX_CHARGE = 64,
    HOP_COOLDOWN = 15,
    JUMP_COOLDOWN = 120,
    HOP_CHARGE_COST = 1,
    JUMP_CHARGE_COST = 6,
    HOP_DAMAGE_MULT = 3,
    JUMP_DAMAGE_MULT = 10,
    JUMP_DAMAGE_FLAT = 5,
    BLINK_INTERVAL = 20,
    STATE = {
        NORMAL = 0,
        STATUE = 1,
    },
}

mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MIN_USABLE_CHARGE, function()
    return EFFIGY.MIN_USE_CHARGE
end, items.COLLECTIBLE_EFFIGY)

---@param player EntityPlayer
---@return integer
local function GetEffigyState(player)
    local slot = Helpers.GetEffigySlot(player)
    return slot == -1 and EFFIGY.STATE.NORMAL or player:GetActiveItemDesc(slot).VarData
end


---@param player EntityPlayer
---@return boolean
local function IsLilith(player)
    local type = player:GetPlayerType()
    return type == PlayerType.PLAYER_LILITH or type == PlayerType.PLAYER_LILITH_B
end

---@param player EntityPlayer
---@param varData integer
local function UpdateShotCapacity(player, varData)
    if IsLilith(player) then return end
    player:SetCanShoot(varData == EFFIGY.STATE.STATUE)
end

---@param player EntityPlayer
---@param varData integer
local function EffigyCostumeManager(player, varData)
    if varData == EFFIGY.STATE.NORMAL then
        player:AddNullItemEffect(enums.NullItemID.EFFIGY, true)
    else
        player:GetEffects():RemoveNullEffect(enums.NullItemID.EFFIGY, -1)
    end
end

---@param player EntityPlayer
---@param varData integer
---@param slot ActiveSlot
---@return integer
local function ChangeEffigyState(player, varData, slot)
    local newState = varData == EFFIGY.STATE.NORMAL and EFFIGY.STATE.STATUE or EFFIGY.STATE.NORMAL
    player:SetActiveVarData(newState, slot)
    UpdateShotCapacity(player, varData)
    EffigyCostumeManager(player, varData)
    return varData
end

---@param jumpData JumpData
---@return boolean
local function IsEffigyJump(jumpData)
    return Jump.IsSpecificJump(jumpData, jumpTags.EffigyHop) or Jump.IsSpecificJump(jumpData, jumpTags.EffigyJump)
end

---@param player EntityPlayer
local function ManageEffigyBigJump(player)
    if not Helpers.IsKeyStompTriggered(player) then return end
    if data(player).EffigyJumpCooldown > 0 then return end
    Jump.InitEdithJump(player, jumpTags.EffigyJump, true)
end

---@param player EntityPlayer
local function ManageEffigyHop(player)
    if not TargetArrow.IsEdithTargetMoving(player) then return end
    if data(player).EffigyHopCooldown > 0 then return end
    Jump.InitEdithJump(player, jumpTags.EffigyHop, false)
end

---@param player EntityPlayer
local function JumpUpdateManager(player)
    if Player.IsAnyEdith(player) then return end
    if GetEffigyState(player) == EFFIGY.STATE.NORMAL then return end
    if Jump.IsJumping(player) then return end

    local pData = data(player)

    pData.EffigyHopCooldown = pData.EffigyHopCooldown or 0
    pData.EffigyJumpCooldown = pData.EffigyJumpCooldown or 0

    ManageEffigyHop(player)
    ManageEffigyBigJump(player)
end

local function ResetStatueStateOnDischarge(player)
    if Helpers.GetEffigyCharge(player) > 0 then return end
    local state = GetEffigyState(player)
    if state == EFFIGY.STATE.NORMAL then return end
    ChangeEffigyState(player, state, Helpers.GetEffigySlot(player))
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    JumpUpdateManager(player)
    ResetStatueStateOnDischarge(player)
end)

---@param player EntityPlayer
---@param flag UseFlag
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flag, slot)
    if BitMask.HasBitFlags(flag, UseFlag.USE_CARBATTERY --[[@as BitSet128]]) then return end

    ChangeEffigyState(player, player:GetActiveItemDesc(slot).VarData, slot)
    player:SetMinDamageCooldown(30)

    if GetEffigyState(player) == EFFIGY.STATE.STATUE then
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            for _ = 1, 6 do
                player:AddWisp(items.COLLECTIBLE_EFFIGY, player.Position, true, true)
            end
        end
    else
        for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, items.COLLECTIBLE_EFFIGY)) do
            ent:Kill()
        end
    end

    return { Discharge = false, Remove = false, ShowAnim = true }
end, items.COLLECTIBLE_EFFIGY)

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, input, action)
    if not entity then return end
    local player = entity:ToPlayer()
    if not player then return end
    if Player.IsAnyEdith(player) then return end
    if GetEffigyState(player) == EFFIGY.STATE.NORMAL then return end
    if not data(player).EffigyHopCooldown then return end
    if data(player).EffigyHopCooldown <= 0 then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end
    return tables.OverrideActions[action]
end)

local function TriggerJudasBirthrightEffect(player, quantity, distance, isBigJump)
    if not Player.IsJudasWithBirthright(player) then return end
    for i = 1, quantity do
        local jet = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 0, player.Position + Vector(0, distance):Rotated(360 * i/quantity), Vector.Zero, player)
        jet.CollisionDamage = player.Damage * (isBigJump and 2 or 1)
    end
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
local function EffigyHopLand(player, jumpParams, jumpData)
    if not Jump.IsSpecificJump(jumpData, jumpTags.EffigyHop) then return end

    jumpParams.Damage = player.Damage * EFFIGY.HOP_DAMAGE_MULT
    jumpParams.Knockback = 20
    jumpParams.Radius = 30

    player:SetActiveCharge(Helpers.GetEffigyCharge(player) - EFFIGY.HOP_CHARGE_COST, Helpers.GetEffigySlot(player))

    TriggerJudasBirthrightEffect(player, 4, 30, false)
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
local function EffigyJumpLand(player, jumpParams, jumpData)
    if not Jump.IsSpecificJump(jumpData, jumpTags.EffigyJump) then return end

    jumpParams.Damage = (player.Damage * EFFIGY.JUMP_DAMAGE_MULT) + EFFIGY.JUMP_DAMAGE_FLAT
    jumpParams.Knockback = 30
    jumpParams.Radius = 50

    data(player).EffigyJumpCooldown = EFFIGY.JUMP_COOLDOWN
    player:SetActiveCharge(Helpers.GetEffigyCharge(player) - EFFIGY.JUMP_CHARGE_COST, Helpers.GetEffigySlot(player))

    TriggerJudasBirthrightEffect(player, 8, 40, true)

    for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, items.COLLECTIBLE_EFFIGY)) do
        ent:Kill()
        for i = 1, 6 do
            Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, ent.Position, Vector.FromAngle((360/6) * i):Resized(10), ent):ToTear()
        end
    end
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
local function EffigyGeneralLand(player, jumpParams, jumpData)
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), player.Color, jumpData)
    Land.EdithStomp(player, jumpParams, true)
    player:MultiplyFriction(0.1)
    player:SetMinDamageCooldown(20)
    data(player).EffigyHopCooldown = EFFIGY.HOP_COOLDOWN
end

mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, entity, jumpData)
    if not IsEffigyJump(jumpData) then return end
    local player = entity:ToPlayer()
    if not player then return end

    local jumpParams = EdithMod.GetJumpStompParams(player)
    EffigyHopLand(player, jumpParams, jumpData)
    EffigyJumpLand(player, jumpParams, jumpData)
    EffigyGeneralLand(player, jumpParams, jumpData)
end)

---@param pData table
---@param field string
local function DecreaseCooldown(pData, field)
    if not pData[field] then return end
    pData[field] = math.max(pData[field] - 1, 0)
end

---@param player EntityPlayer
---@param pData table
local function HopCooldownIndicator(player, pData)
    if not pData.EffigyHopCooldown then return end
    if pData.EffigyHopCooldown ~= 1 then return end
    Player.SetColorCooldown(player, -0.8, 5)
    sfx:Play(SoundEffect.SOUND_BEEP)
end

---@param player EntityPlayer
---@param pData table
local function JumpCooldownIndicator(player, pData)
    if not pData.EffigyJumpCooldown then return end
    if pData.EffigyJumpCooldown > 0 then return end

    pData.EffigyJumpBlink = Maths.Clamp((pData.EffigyJumpBlink or 0) + 1, 0, EFFIGY.BLINK_INTERVAL)

    if pData.EffigyJumpBlink == EFFIGY.BLINK_INTERVAL then
        Player.SetColorCooldown(player, 0.5, 5)
        pData.EffigyJumpBlink = 0
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if GetEffigyState(player) == EFFIGY.STATE.NORMAL then return end
    local pData = data(player)

    JumpCooldownIndicator(player, pData)
    DecreaseCooldown(pData, "EffigyJumpCooldown")
    DecreaseCooldown(pData, "EffigyHopCooldown")
    HopCooldownIndicator(player, pData)
end)

mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function(_, ent, jumpData)
    if not Jump.IsSpecificJump(jumpData, jumpTags.EffigyHop) then return end
    ent.Velocity = ent.Velocity * 1.05
end)

---@param player EntityPlayer
local function OnEffigyGetCostume(player)
    if GetEffigyState(player) == EFFIGY.STATE.NORMAL then return end 
    player:AddNullItemEffect(enums.NullItemID.EFFIGY, true)
end

mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function(_, _, _, first, _, _, player)
    OnEffigyGetCostume(player)

    if not first then return end
    local pData = data(player)
    pData.EffigyJumpCooldown = 0
    pData.EffigyHopCooldown  = 0
    pData.BigJumpUses = 0
end, items.COLLECTIBLE_EFFIGY)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, function(_, player)
    player:GetEffects():RemoveNullEffect(enums.NullItemID.EFFIGY, -1)
end, items.COLLECTIBLE_EFFIGY)

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_NEW_LEVEL, function(_, player, _, levelInit)
    if not levelInit then return end
    local slot = Helpers.GetEffigySlot(player)
    if slot == -1 then return end

    local batteryMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1
    player:SetActiveCharge(EFFIGY.MAX_CHARGE * batteryMult, slot)
end)