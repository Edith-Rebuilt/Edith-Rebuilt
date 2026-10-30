--[[
    Throwable Item Library by Kerkel
    Version 1.6.1
]]

---@class ThrowableItemConfig
---@field ID CollectibleType | Card Active item or card ID
---@field Type ThrowableItemType Active item or card?
---@field LiftFn? fun(player: EntityPlayer, continued: boolean?, slot: ActiveSlot, mimic: CollectibleType?) Called when lifting the item
---@field HideFn? fun(player: EntityPlayer, slot: ActiveSlot, mimic: CollectibleType?) Called when hiding the item, but not when throwing
---@field ThrowFn? fun(player: EntityPlayer, vec: Vector, slot: ActiveSlot, mimic: CollectibleType?) Called when throwing the item
---@field AnimateFn? fun(player: EntityPlayer, state: ThrowableItemState): boolean? Return true to cancel default animation. Lets you play your own, useful for dynamic sprite changing
---@field Flags? ThrowableItemFlag | integer
---@field HoldCondition? fun(player: EntityPlayer, config: ThrowableItemConfig): HoldConditionReturnType Called when checking how an item should behave when attempted to be held. If multiple configs exist for the same item and the current check does not allow for the item to be held, checks the next condition down the list based on priority
---@field Priority? number Order in which the hold condition is checked relative to other configs for the same item. Priority = is 1 by default
---@field Identifier string Previously existing configs with shared identifiers are removed when a new config for the same item is registered with the same identifier. Use this if you wanna luamod

---@class MimicItemConfig
---@field ID CollectibleType
---@field Condition fun(card: ItemConfigCard, player: EntityPlayer): boolean
---@field PrimaryLift? boolean Only lift if the primary pocket slot is filled by an eligible consumable. This active is rendered useless when placed in the pocket slot.
---@field SetVarData? boolean

---@class ChargeConfig
---@field Identifier string | any
---@field Priority? number
---@field Getter fun(player: EntityPlayer): integer
---@field Setter fun(player: EntityPlayer, amt: integer)

local VERSION = 11

---@type table<string, table<string, ThrowableItemConfig>>
local configs = {}
---@type table<CollectibleType, MimicItemConfig>
local mimics = {}
---@type ChargeConfig[]
local charges = {}

if ThrowableItemLib then
    if ThrowableItemLib.Internal.VERSION > VERSION then
        return {Init = function () end}
    end

    configs = ThrowableItemLib.Internal.Configs

    if ThrowableItemLib.Internal.MimicConfigs then
        mimics = ThrowableItemLib.Internal.MimicConfigs
    end

    if ThrowableItemLib.Internal.ChargeConfigs then
        charges = ThrowableItemLib.Internal.ChargeConfigs
    end

    ThrowableItemLib.Internal:ClearCallbacks()
end

ThrowableItemLib = RegisterMod("Throwable Item Library", 1)

ThrowableItemLib.Utility = {}
ThrowableItemLib.Internal = {}
ThrowableItemLib.Internal.VERSION = VERSION
ThrowableItemLib.Internal.CallbackEntries = {}
ThrowableItemLib.Internal.Configs = configs
ThrowableItemLib.Internal.MimicConfigs = mimics
ThrowableItemLib.Internal.ChargeConfigs = charges

---@param tbl table
function ThrowableItemLib.Internal:PrioritySort(tbl)
    for _, v in pairs(tbl) do
        table.sort(v, function (a, b)
            return (a.Priority or 1) > (b.Priority or 1)
        end)
    end
end

---@param id ModCallbacks
---@param fn function
---@param param any
local function AddCallback(id, fn, param)
    table.insert(ThrowableItemLib.Internal.CallbackEntries, {
        ID = id,
        FN = fn,
        FILTER = param,
        PRIORITY = CallbackPriority.DEFAULT
    })
end

---@param id ModCallbacks
---@param priority CallbackPriority | integer
---@param fn function
---@param param any
local function AddPriorityCallback(id, priority, fn, param)
    table.insert(ThrowableItemLib.Internal.CallbackEntries, {
        ID = id,
        FN = fn,
        FILTER = param,
        PRIORITY = priority
    })
end

local game = Game()

---@enum ThrowableItemFlag
ThrowableItemLib.Flag = {
    ---Does not discharge on throw
    NO_DISCHARGE = 1 << 0,
    ---Dischages on hide
    DISCHARGE_HIDE = 1 << 1,
    ---Item can be lifted at any charge
    USABLE_ANY_CHARGE = 1 << 2,
    ---Can not be manually hid
    DISABLE_HIDE = 1 << 3,
    ---Item lift persists when animation is interrupted 
    PERSISTENT = 1 << 4,
    ---Does not trigger item use on throw. Useful for preventing on-use effects
    DISABLE_ITEM_USE = 1 << 5,
    ---Uses PlayerPickup instead of PlayerPickupSparkle
    NO_SPARKLE = 1 << 6,
    ---Disables throw
    DISABLE_THROW = 1 << 11,
    ---@deprecated
    EMPTY_HIDE = 1 << 7,
    ---@deprecated
    EMPTY_THROW = 1 << 8,
    ---@deprecated
    ENABLE_CARD_USE = 1 << 9,
    ---@deprecated
    TRY_HIDE_ANIM = 1 << 10,
}

---@enum ThrowableItemType
ThrowableItemLib.Type = {
    ACTIVE = 1,
    CARD = 2,
}

---@enum HoldConditionReturnType
ThrowableItemLib.HoldConditionReturnType = {
    ---Item will be used
    DEFAULT_USE = 1,
    ---Item will be lifted
    ALLOW_HOLD = 2,
    ---Item will neither be lifted nor used
    DISABLE_USE = 3,
}

---@enum ThrowableItemState
ThrowableItemLib.State = {
    LIFT = 1,
    HIDE = 2,
    THROW = 3
}

---@enum ThrowableItemCallback
---Optional `string` key parameter
ThrowableItemLib.Callback = {
    ---Called before lifting a custom throwable item
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* config - `ThrowableItemConfig`
    ---* continue - `boolean`
    ---* slot - `ActiveSlot`
    ---
    ---Returns:
    ---* Return `true` to cancel lift
    PRE_LIFT = "THROWABLE_ITEM_LIBRARY_PRE_LIFT",
    ---Called after lifting a custom throwable item
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* config - `ThrowableItemConfig`
    ---* continue - `boolean`
    ---* slot - `ActiveSlot`
    POST_LIFT = "THROWABLE_ITEM_LIBRARY_POST_LIFT",
    ---Called before hiding a custom throwable item
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* config - `ThrowableItemConfig`
    ---* throw - `boolean`
    ---* slot - `ActiveSlot`
    PRE_HIDE = "THROWABLE_ITEM_LIBRARY_PRE_HIDE",
    ---Called after hiding a custom throwable item
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* config - `ThrowableItemConfig`
    ---* throw - `boolean`
    ---* slot - `ActiveSlot`
    POST_HIDE = "THROWABLE_ITEM_LIBRARY_POST_HIDE",
    ---Called before throwing a custom throwable item
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* config - `ThrowableItemConfig`
    ---* vec - `Vector`
    ---* slot - `ActiveSlot`
    ---* mimic - `CollectibleType?`
    ---Returns:
    ---
    ---* Return `true` to prevent throw entirely
    ---* Return `false` to cancel throw effects
    PRE_THROW = "THROWABLE_ITEM_LIBRARY_PRE_THROW",
    ---Called after throwing a custom throwable item
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* config - `ThrowableItemConfig`
    ---* vec - `Vector`
    ---* slot - `ActiveSlot`
    ---* mimic - `CollectibleType?`
    POST_THROW = "THROWABLE_ITEM_LIBRARY_POST_THROW",
    ---Called after a custom discharge for actives with `DISABLE_ITEM_USE` flag
    ---
    ---Parameters:
    ---* player - `EntityPlayer`
    ---* remainder - `integer`
    ---
    ---Returns:
    ---
    ---* Return `integer` to pass changes to the next call
    POST_CUSTOM_DISCHARGE = "THROWABLE_ITEM_LIBRARY_POST_CUSTOM_DISCHARGE",
}

ThrowableItemLib.Internal.LIFT_FRAME_DELAY = 9

function ThrowableItemLib.Internal:ClearCallbacks()
    for _, v in ipairs(ThrowableItemLib.Internal.CallbackEntries) do
        ThrowableItemLib:RemoveCallback(v.ID, v.FN)
    end
end

---@param entity Entity
function ThrowableItemLib.Internal:GetData(entity)
    local data = entity:GetData()

    data.__THROWABLE_ITEM_LIBRARY = data.__THROWABLE_ITEM_LIBRARY or {}

    ---@class ThrowableItemData
    ---@field HeldConfig ThrowableItemConfig
    ---@field ActiveSlot ActiveSlot?
    ---@field ThrownItem ThrowableItemConfig?
    ---@field ForceInputSlot ActiveSlot
    ---@field Mimic CollectibleType?
    ---@field ScheduleHide boolean
    ---@field UsedPocket boolean
    ---@field UsedMimic boolean
    ---@field ScheduleLift table[]
    ---@field ScheduleHideAnim function
    ---@field LiftFrame integer
    ---@field QuestionMarkCard boolean
    return data.__THROWABLE_ITEM_LIBRARY
end

---@param data ThrowableItemData
function ThrowableItemLib.Internal:ResetHeldData(data)
    data.ActiveSlot = nil
    data.HeldConfig = nil
    data.Mimic = nil
    data.LiftFrame = nil
end

---@param id CollectibleType | Card
---@param type ThrowableItemType
---@return string
function ThrowableItemLib.Internal:GetHeldConfigKey(id, type)
    return (type == ThrowableItemLib.Type.ACTIVE and "ACTIVE_" or "CARD_") .. id
end

---@param player EntityPlayer
---@param data ThrowableItemData
---@param config ThrowableItemConfig?
---@param slot ActiveSlot
function ThrowableItemLib.Internal:TryLift(player, data, config, slot)
    local canLift = config
    and (
        not ThrowableItemLib.Utility:NeedsCharge(player, slot)
        or ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.USABLE_ANY_CHARGE)
    )
    and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD
    and (
        not data.HeldConfig
        or data.ActiveSlot ~= slot
        or data.HeldConfig.Type ~= config.Type
        or data.HeldConfig.ID ~= config.ID
    )

    if canLift then
        ---@cast config ThrowableItemConfig

        if data.HeldConfig then
            ThrowableItemLib.Internal:ResetHeldData(data)
        end

        ThrowableItemLib.Utility:LiftItem(player, config.ID, config.Type, slot)
    else
        -- Base game automatically plays the hide item animation when space is pressed, not much I can do for pocket items
        if data.HeldConfig and (not data.ActiveSlot or data.ActiveSlot == slot) then
            data.ScheduleHide = true
        end
    end
end

---@param id CollectibleType
---@param player EntityPlayer
---@return boolean?
function ThrowableItemLib.Internal:MimicCondition(id, player)
    local config = ThrowableItemLib.Internal.MimicConfigs[id]

    if not config then return end

    local card, slot = ThrowableItemLib.Utility:GetFirstCard(player)

    if config.PrimaryLift and slot ~= 0 then return end

    return ThrowableItemLib.Internal.MimicConfigs[id].Condition(
        Isaac.GetItemConfig():GetCard(card),
        player
    )
end

---@param player EntityPlayer
---@param data ThrowableItemData
---@param config ThrowableItemConfig?
---@param slot ActiveSlot
function ThrowableItemLib.Internal:TryMimic(player, data, config, slot)
    if not config then return end

    local item = player:GetActiveItem(slot)

    if (not ThrowableItemLib.Utility:NeedsCharge(player, slot) or ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.USABLE_ANY_CHARGE))
    and ThrowableItemLib.Internal.MimicConfigs[item] and ThrowableItemLib.Internal:MimicCondition(item, player) then
        if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.CARD and data.HeldConfig.ID == config.ID then
            data.ScheduleHide = true
        elseif ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
            ThrowableItemLib.Utility:LiftItem(player, config.ID, ThrowableItemLib.Type.CARD, slot, nil, item)
        end
    end
end

---@param player EntityPlayer
---@param data ThrowableItemData
---@param card boolean?
function ThrowableItemLib.Internal:ThrowItem(player, data, card)
    if card then
        if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_ITEM_USE) then
            player:UseCard(data.HeldConfig.ID, UseFlag.USE_NOANIM)
        end

        if data.Mimic and ThrowableItemLib.Internal.MimicConfigs[data.Mimic] and data.ActiveSlot > -1 then
            if ThrowableItemLib.Internal.MimicConfigs[data.Mimic].PrimaryLift then
                data.ForceInputSlot = data.ActiveSlot
            else
                player:DischargeActiveItem(data.ActiveSlot)
            end

            if REPENTOGON and ThrowableItemLib.Internal.MimicConfigs[data.Mimic].SetVarData then
                ---@diagnostic disable-next-line: undefined-field
                player:GetActiveItemDesc(data.ActiveSlot).VarData = Isaac.GetItemConfig():GetCard(data.HeldConfig.ID).MimicCharge or 4
            end
        end
    else
        if ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_ITEM_USE) then
            if not data.Mimic and not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
                local _, unadjusted = ThrowableItemLib.Utility:GetMaxCharge(player, data.ActiveSlot)
                local targ = player:GetActiveCharge(data.ActiveSlot) - unadjusted
                local remainder = 0
                player:SetActiveCharge(math.max(0, targ), data.ActiveSlot)
                if targ < 0 then
                    remainder = Isaac.GetItemConfig():GetCollectible(data.ThrownItem.ID).ChargeType == 1 and 1 or math.abs(targ)
                    for _, v in ipairs(ThrowableItemLib.Internal.ChargeConfigs) do
                        local amt = v.Getter(player)
                        if amt > 0 then
                            local diff = amt - remainder
                            v.Setter(player, math.max(diff, 0))
                            if remainder == 0 then break end
                            remainder = math.abs(diff)
                        end
                    end
                end
                for _, v in ipairs(Isaac.GetCallbacks(ThrowableItemLib.Callback.POST_CUSTOM_DISCHARGE)) do
                    remainder = v.Function(v.Mod, player, remainder) or remainder
                end
            end
        else
            player:UseActiveItem(data.HeldConfig.ID, UseFlag.USE_NOANIM)

            if not data.Mimic and data.ActiveSlot and data.ActiveSlot > -1 then
                if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
                    player:DischargeActiveItem(data.ActiveSlot)
                end
            end
        end

        if data.ActiveSlot == ActiveSlot.SLOT_POCKET2 then
            player:SetPocketActiveItem(CollectibleType.COLLECTIBLE_NULL, ActiveSlot.SLOT_POCKET2)
        end
    end
end

---@param player EntityPlayer
---@return Vector
function ThrowableItemLib.Utility:GetAimVect(player)
    local data = ThrowableItemLib.Internal:GetData(player)

    if data.LiftFrame and player.FrameCount - data.LiftFrame < ThrowableItemLib.Internal.LIFT_FRAME_DELAY then
        return Vector.Zero
    end

    ---@type Vector
    local returnVect

    if player.ControllerIndex == 0 and Options.MouseControl then
        if Input.IsMouseBtnPressed(0) then
            returnVect = (Input.GetMousePosition(true) - player.Position):Normalized()
        end
    end

    returnVect = returnVect or player:GetShootingInput()

    if returnVect:Length() > 0.001 and not player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK) then
        returnVect = ThrowableItemLib.Utility:CardinalClamp(returnVect)
    end

    return returnVect
end

---@param player EntityPlayer
---@return boolean
function ThrowableItemLib.Utility:IsShooting(player)
    return ThrowableItemLib.Utility:GetAimVect(player):Length() > 0.001
end

---@param vector Vector
function ThrowableItemLib.Utility:CardinalClamp(vector)
    return Vector.FromAngle(((vector:GetAngleDegrees() + 45) // 90) * 90)
end

---@param flags integer
---@param flag integer
---@return boolean
function ThrowableItemLib.Utility:HasFlags(flags, flag)
    return flags & flag ~= 0
end

---@param player EntityPlayer
---@param slot ActiveSlot
---@return integer, integer Unadjusted
function ThrowableItemLib.Utility:GetMaxCharge(player, slot)
    local item = player:GetActiveItem(slot)

    if not item or item == 0 then
        return 0, 0
    end

    local config = Isaac.GetItemConfig():GetCollectible(item)
    ---@diagnostic disable-next-line: undefined-field
    local charge = REPENTOGON and player:GetActiveMaxCharge(slot) or config.MaxCharges

    if config.ChargeType == 1 then
        return charge > 0 and 1 or 0, charge
    end

    return charge, charge
end

---@param player EntityPlayer
---@param slot ActiveSlot
function ThrowableItemLib.Utility:GetMinCharge(player, slot)
    return REPENTOGON and player:GetActiveMinUsableCharge(slot)
    or ThrowableItemLib.Utility:GetMaxCharge(player, slot)
end

---@param player EntityPlayer
---@param slot ActiveSlot
function ThrowableItemLib.Utility:NeedsCharge(player, slot)
    local charge = player:GetActiveCharge(slot)
    local timed = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(slot)).ChargeType == 1
    for _, v in ipairs(ThrowableItemLib.Internal.ChargeConfigs) do
        if v.Identifier == 1 or v.Identifier == 2 then -- not pretty because its late. mods will use callback that automatically affects this return
            local amt = v.Getter(player)
            if amt > 0 and timed then
                charge = math.huge
                break
            end
            charge = charge + amt
        end
    end
    return charge < ThrowableItemLib.Utility:GetMinCharge(player, slot)
end

---@param player EntityPlayer
---@return Card, integer
function ThrowableItemLib.Utility:GetFirstCard(player)
    for i = 0, 3 do
        local card = player:GetCard(i)

        if card > Card.CARD_NULL then
            return card, i
        end
    end

    return Card.CARD_NULL, 0
end

---@param player EntityPlayer
---@param id CollectibleType | Card
---@param type ThrowableItemType
---@param slot? ActiveSlot
---@param continue? boolean
---@param mimic? CollectibleType
function ThrowableItemLib.Utility:LiftItem(player, id, type, slot, continue, mimic)
    local key = ThrowableItemLib.Internal:GetHeldConfigKey(id, type)
    local config = ThrowableItemLib.Utility:GetConfig(player, key)
    if not config then return end

    if Isaac.RunCallbackWithParam(ThrowableItemLib.Callback.PRE_LIFT, key, player, config, continue, slot or -1) then return end

    local data = ThrowableItemLib.Internal:GetData(player)

    data.HeldConfig = config
    data.ActiveSlot = slot
    data.Mimic = mimic
    data.LiftFrame = player.FrameCount

    if not (config.AnimateFn and config.AnimateFn(player, ThrowableItemLib.State.LIFT)) then
        if type == ThrowableItemLib.Type.ACTIVE then
            player:AnimateCollectible(config.ID, "LiftItem", ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.NO_SPARKLE) and "PlayerPickup" or "PlayerPickupSparkle")
        else
            player:AnimateCard(config.ID, "LiftItem")
        end
    end

    -- if REPENTOGON then
    --     ---@diagnostic disable-next-line: undefined-field
    --     player:SetItemState(type == ThrowableItemLib.Type.ACTIVE and config.ID or 0)
    -- end

    if config.LiftFn then
        config.LiftFn(player, continue, data.ActiveSlot, data.Mimic)
    end

    Isaac.RunCallbackWithParam(ThrowableItemLib.Callback.POST_LIFT, key, player, config, continue, slot or -1)
end

---@param player EntityPlayer
---@param id CollectibleType | Card
---@param type ThrowableItemType
---@param slot? ActiveSlot
---@param continue? boolean
---@param mimic? CollectibleType
function ThrowableItemLib.Utility:ScheduleLift(player, id, type, slot, continue, mimic)
    local data = ThrowableItemLib.Internal:GetData(player)
    data.ScheduleLift = data.ScheduleLift or {}
    table.insert(data.ScheduleLift, {player, id, type, slot, continue, mimic})
end

---@param player EntityPlayer
---@return ThrowableItemConfig
function ThrowableItemLib.Utility:GetLiftedItem(player)
    return ThrowableItemLib.Internal:GetData(player).HeldConfig
end

---@param player EntityPlayer
---@return boolean
function ThrowableItemLib.Utility:IsItemLifted(player)
    return not not ThrowableItemLib.Utility:GetLiftedItem(player)
end

---@param player EntityPlayer
---@param data ThrowableItemData
function ThrowableItemLib.Internal:ThrowCard(player, data)
    if data.Mimic then
        ThrowableItemLib.Internal:ThrowItem(player, data, true)
    else
        if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
            if REPENTOGON then
                ---@diagnostic disable-next-line: undefined-field
                player:RemovePocketItem(PillCardSlot.PRIMARY)
            else
                player:SetCard(0, 0)
            end
        end

        if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_ITEM_USE) then
            player:UseCard(data.HeldConfig.ID, UseFlag.USE_NOANIM)
        end
    end
end

---@param player EntityPlayer
---@param config table
function ThrowableItemLib.Internal:AnimateHide(player, config, throw)
    if not (config.AnimateFn and config.AnimateFn(player, throw and ThrowableItemLib.State.THROW or ThrowableItemLib.State.HIDE)) then
        if config.Type == ThrowableItemLib.Type.ACTIVE then
            player:AnimateCollectible(config.ID, "HideItem", ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.NO_SPARKLE) and "PlayerPickup" or "PlayerPickupSparkle")
        else
            player:AnimateCard(config.ID, "HideItem")
        end
    end
end

---@param player EntityPlayer
---@param throw? boolean
function ThrowableItemLib.Utility:HideItem(player, throw)
    local data = ThrowableItemLib.Internal:GetData(player)
    local config = data.HeldConfig
    if not config then return end

    local key = ThrowableItemLib.Internal:GetHeldConfigKey(config.ID, config.Type)
    local slot = data.ActiveSlot or -1

    Isaac.RunCallbackWithParam(ThrowableItemLib.Callback.PRE_HIDE, key, player, config, throw, slot)

    local active = config.Type == ThrowableItemLib.Type.ACTIVE

    data.ThrownItem = throw and config or nil

    if not data.Mimic or not throw then
        ThrowableItemLib.Internal:AnimateHide(player, config, throw)
    else
        data.ScheduleHideAnim = function ()
            ThrowableItemLib.Internal:AnimateHide(player, config, throw)
        end
    end

    if throw then
        if active then
            ThrowableItemLib.Internal:ThrowItem(player, data)
        else
            ThrowableItemLib.Internal:ThrowCard(player, data)
        end
    else
        if config.HideFn then
            config.HideFn(player, data.ActiveSlot, data.Mimic)
        end

        if ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.DISCHARGE_HIDE) then
            if active then
                ThrowableItemLib.Internal:ThrowItem(player, data)
            else
                ThrowableItemLib.Internal:ThrowCard(player, data)
            end
        end
    end

    ThrowableItemLib.Internal:ResetHeldData(data)

    Isaac.RunCallbackWithParam(ThrowableItemLib.Callback.POST_HIDE, key, player, config, throw, slot)
end

---@param player EntityPlayer
---@param key string
function ThrowableItemLib.Utility:GetConfig(player, key)
    if not ThrowableItemLib.Internal.Configs[key] then return end

    local lastConfig

    for _, v in pairs(ThrowableItemLib.Internal.Configs[key]) do
        lastConfig = v

        if not v.HoldCondition or (v.HoldCondition(player, v) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD) then
            break
        end
    end

    return lastConfig
end

---@param player EntityPlayer
---@return ThrowableItemConfig?
function ThrowableItemLib.Utility:GetThrowableActiveConfig(player)
    local data = ThrowableItemLib.Internal:GetData(player)

    return data.HeldConfig
    and data.HeldConfig.Type == ThrowableItemLib.Type.ACTIVE
    and data.ActiveSlot == ActiveSlot.SLOT_PRIMARY
    and data.HeldConfig
    or ThrowableItemLib.Utility:GetConfig(player, ThrowableItemLib.Internal:GetHeldConfigKey(player:GetActiveItem(ActiveSlot.SLOT_PRIMARY), ThrowableItemLib.Type.ACTIVE))
end

---@param player EntityPlayer
---@param activeSlot ActiveSlot
---@param mimic? CollectibleType
---@return ThrowableItemConfig?
function ThrowableItemLib.Utility:GetThrowableCardConfig(player, activeSlot, mimic)
    local data = ThrowableItemLib.Internal:GetData(player)

    if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.CARD then
        return data.HeldConfig
    end

    local card, slot = ThrowableItemLib.Utility:GetFirstCard(player)

    if slot < 0 then
        return
    end

    if mimic then
        if not ThrowableItemLib.Internal:MimicCondition(mimic, player) then
            return
        end
    elseif activeSlot == -1
    and not ThrowableItemLib.Internal:MimicCondition(player:GetActiveItem(activeSlot), player) then
        return
    end

    return ThrowableItemLib.Utility:GetConfig(player, ThrowableItemLib.Internal:GetHeldConfigKey(card, ThrowableItemLib.Type.CARD))
end

---@param player EntityPlayer
---@return ThrowableItemConfig?, ActiveSlot?
function ThrowableItemLib.Utility:GetThrowablePocketConfig(player)
    local data = ThrowableItemLib.Internal:GetData(player)

    if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.ACTIVE and data.ActiveSlot == ActiveSlot.SLOT_POCKET then
        return data.HeldConfig, data.ActiveSlot
    end

    if player:GetCard(0) ~= Card.CARD_NULL or player:GetPill(0) ~= PillColor.PILL_NULL then return end

    local slot = ActiveSlot.SLOT_POCKET

    if REPENTOGON then
        slot = player:GetPocketItem(PillCardSlot.PRIMARY):GetSlot() - 1
        if slot == -1 then return end
    else
        if player:GetActiveItem(ActiveSlot.SLOT_POCKET2) ~= 0 then -- Prioritize pocket2. I wish there was more I can do
            slot = ActiveSlot.SLOT_POCKET2
        else
            slot = ActiveSlot.SLOT_POCKET
        end
    end

    return ThrowableItemLib.Utility:GetConfig(player, ThrowableItemLib.Internal:GetHeldConfigKey(player:GetActiveItem(slot), ThrowableItemLib.Type.ACTIVE)), slot
end

---@param config ThrowableItemConfig
function ThrowableItemLib:RegisterThrowableItem(config)
    config.Flags = config.Flags or 0
    config.Priority = config.Priority or 1

    local key = ThrowableItemLib.Internal:GetHeldConfigKey(config.ID, config.Type)

    ThrowableItemLib.Internal.Configs[key] = ThrowableItemLib.Internal.Configs[key] or {}

    for k, v in pairs(ThrowableItemLib.Internal.Configs[key]) do
        if v.Identifier == config.Identifier then
            ThrowableItemLib.Internal.Configs[key][k] = nil
        end
    end

    table.insert(ThrowableItemLib.Internal.Configs[key], config)

    ThrowableItemLib.Internal:PrioritySort(ThrowableItemLib.Internal.Configs)
end

---@param config MimicItemConfig
function ThrowableItemLib.Utility:RegisterMimicItem(config)
    ThrowableItemLib.Internal.MimicConfigs[config.ID] = config
end

---@param config ChargeConfig
function ThrowableItemLib.Utility:RegisterCharge(config)
    config.Priority = config.Priority or 1
    for i = #ThrowableItemLib.Internal.ChargeConfigs, 1, -1 do
        local v = ThrowableItemLib.Internal.ChargeConfigs[i]
        if v.Identifier == config.Identifier then
            table.remove(ThrowableItemLib.Internal.ChargeConfigs, i)
            break
        end
    end
    ThrowableItemLib.Internal.ChargeConfigs[#ThrowableItemLib.Internal.ChargeConfigs + 1] = config
    table.sort(ThrowableItemLib.Internal.ChargeConfigs, function (a, b)
        return a.Priority > b.Priority
    end)
end

---@param player EntityPlayer
---@param config ThrowableItemConfig
---@return HoldConditionReturnType?
function ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config)
    if config.HoldCondition then
        return config.HoldCondition(player, config)
    end
    return ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD
end

---@param entity Entity?
---@param hook InputHook
---@param action ButtonAction
AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, hook, action)
    if hook == InputHook.IS_ACTION_TRIGGERED then
        if action == ButtonAction.ACTION_ITEM then
            local player = entity and entity:ToPlayer()
            if not player or not Input.IsActionTriggered(action, player.ControllerIndex) then return end

            local data = ThrowableItemLib.Internal:GetData(player)
            local type = player:GetPlayerType()

            if data.ForceInputSlot == ActiveSlot.SLOT_PRIMARY then
                data.ForceInputSlot = nil
                return true
            end

            ---@type any
            local active = ThrowableItemLib.Utility:GetThrowableActiveConfig(player)
            active = active and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, active) ~= ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE

            if active then
                return false
            end

            ---@type any
            local card = ThrowableItemLib.Utility:GetThrowableCardConfig(player, ActiveSlot.SLOT_PRIMARY)

            card = card
            and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, card) ~= ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE
            and (
                ThrowableItemLib.Internal:MimicCondition(player:GetActiveItem(ActiveSlot.SLOT_PRIMARY), player)
                or (Options.JacobEsauControls ~= 1 and type == PlayerType.PLAYER_JACOB and Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex))
            )

            if card then
                return false
            end
        elseif action == ButtonAction.ACTION_PILLCARD then
            local player = entity and entity:ToPlayer()
            if not player or not Input.IsActionTriggered(action, player.ControllerIndex) then return end

            local data = ThrowableItemLib.Internal:GetData(player)
            local type = player:GetPlayerType()

            if data.ForceInputSlot == ActiveSlot.SLOT_POCKET then
                data.ForceInputSlot = nil
                return true
            end

            ---@type any
            local pocket = ThrowableItemLib.Utility:GetThrowablePocketConfig(player)

            pocket = pocket and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, pocket) ~= ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE

            if pocket then
                return false
            end

            if type == PlayerType.PLAYER_ESAU and Options.JacobEsauControls ~= 1 then
                ---@type any
                local active = ThrowableItemLib.Utility:GetThrowableActiveConfig(player)
                active = active and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, active) ~= ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE

                if active then
                    return false
                end
            end

            ---@type any
            local card = ThrowableItemLib.Utility:GetThrowableCardConfig(player, ActiveSlot.SLOT_POCKET)

            card = card
            and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, card) ~= ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE
            and (type ~= PlayerType.PLAYER_ESAU or Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex))

            if card then
                return false
            end
        end
    end

    if action == ButtonAction.ACTION_DROP then
        local player = entity and entity:ToPlayer()
        if not player then return end

        local item = ThrowableItemLib.Utility:GetLiftedItem(player)

        if item then
            if hook == InputHook.IS_ACTION_TRIGGERED then
                return false
            elseif item.Type == ThrowableItemLib.Type.CARD then
                if hook == InputHook.GET_ACTION_VALUE then
                    return 0
                end

                return false
            end
        end
    end
end)

---@param player EntityPlayer
---@param fn fun(action: ButtonAction, index: integer): boolean
function ThrowableItemLib.Utility:GetPocketInput(player, fn)
    local type = player:GetPlayerType()

    if Options.JacobEsauControls == 1 then
        if type == PlayerType.PLAYER_ESAU then
            return Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
            and fn(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
        elseif type == PlayerType.PLAYER_JACOB then
            return not Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
            and fn(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
        end
    elseif type == PlayerType.PLAYER_JACOB then
        return Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
        and fn(ButtonAction.ACTION_ITEM, player.ControllerIndex)
    elseif type == PlayerType.PLAYER_ESAU then
        return Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
        and fn(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
    end

    return fn(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
end

---@param player EntityPlayer
---@param fn fun(action: ButtonAction, index: integer): boolean
function ThrowableItemLib.Utility:GetActiveInput(player, fn)
    local type = player:GetPlayerType()

    if Options.JacobEsauControls == 1 then
        if type == PlayerType.PLAYER_ESAU then
            return Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
            and fn(ButtonAction.ACTION_ITEM, player.ControllerIndex)
        elseif type == PlayerType.PLAYER_JACOB then
            return not Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
            and fn(ButtonAction.ACTION_ITEM, player.ControllerIndex)
        end
    elseif type == PlayerType.PLAYER_JACOB then
        return not Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
        and fn(ButtonAction.ACTION_ITEM, player.ControllerIndex)
    elseif type == PlayerType.PLAYER_ESAU then
        return not Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
        and fn(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
    end

    return fn(ButtonAction.ACTION_ITEM, player.ControllerIndex)
end

---@param player EntityPlayer
AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    local data = ThrowableItemLib.Internal:GetData(player)
    local controlsEnabled = not player:IsDead() and player.ControlsEnabled

    if controlsEnabled then
        if ThrowableItemLib.Utility:GetActiveInput(player, Input.IsActionTriggered) then
            ThrowableItemLib.Internal:TryLift(player, data, ThrowableItemLib.Utility:GetThrowableActiveConfig(player), ActiveSlot.SLOT_PRIMARY)
            ThrowableItemLib.Internal:TryMimic(player, data, ThrowableItemLib.Utility:GetThrowableCardConfig(player, ActiveSlot.SLOT_PRIMARY), ActiveSlot.SLOT_PRIMARY)
        end

        if ThrowableItemLib.Utility:GetPocketInput(player, Input.IsActionTriggered) and not data.UsedPocket then
            local pocket, slot = ThrowableItemLib.Utility:GetThrowablePocketConfig(player)

            ThrowableItemLib.Internal:TryLift(player, data, pocket, slot)

            local card = ThrowableItemLib.Utility:GetThrowableCardConfig(player, ActiveSlot.SLOT_POCKET)

            if card then
                local cardID, cardSlot = ThrowableItemLib.Utility:GetFirstCard(player)

                if cardSlot == 0 then
                    if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.CARD and data.HeldConfig.ID == card.ID then
                        data.ScheduleHide = true
                    elseif ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, card) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
                        ThrowableItemLib.Utility:LiftItem(player, cardID, ThrowableItemLib.Type.CARD)
                    end
                else
                    ThrowableItemLib.Internal:TryMimic(player, data, card, ActiveSlot.SLOT_POCKET)
                end
            end
        end
    end

    data.UsedPocket = nil
    data.ThrownItem = nil

    if data.ScheduleLift and controlsEnabled and not data.HeldConfig and not data.ScheduleHide and player:IsExtraAnimationFinished() then
        if data.ScheduleLift[1] then
            ThrowableItemLib.Utility:LiftItem(table.unpack(data.ScheduleLift[1]))

            local tbl = {}

            for i = 2, #data.ScheduleLift do
                tbl[#tbl + 1] = data.ScheduleLift[i]
            end

            data.ScheduleLift = tbl
        end
    end
end)

---@param player EntityPlayer
AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local data = ThrowableItemLib.Internal:GetData(player)

    if data.ScheduleHide then
        if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_HIDE) then
            ThrowableItemLib.Utility:HideItem(player)
        end
        data.ScheduleHide = false
    end

    if data.ScheduleHideAnim then
        data.ScheduleHideAnim()
        data.ScheduleHideAnim = nil
    end

    if data.HeldConfig then
        if player:IsExtraAnimationFinished() then
            if ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.PERSISTENT) then
                ThrowableItemLib.Utility:LiftItem(player, data.HeldConfig.ID, data.HeldConfig.Type, data.ActiveSlot, true)
            else
                ThrowableItemLib.Internal:ResetHeldData(data)
            end
        elseif ThrowableItemLib.Utility:IsShooting(player) and not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_THROW) then
            local key = ThrowableItemLib.Internal:GetHeldConfigKey(data.HeldConfig.ID, data.HeldConfig.Type)
            local vect = ThrowableItemLib.Utility:GetAimVect(player)
            local config = data.HeldConfig
            local slot = data.ActiveSlot
            local mimic = data.Mimic

            local ret = Isaac.RunCallbackWithParam(ThrowableItemLib.Callback.PRE_THROW, key, player, config, vect, slot or -1, mimic)
            if ret then return end

            if ret ~= false and data.HeldConfig.ThrowFn then
                data.HeldConfig.ThrowFn(player, vect, data.ActiveSlot, data.Mimic)
            end

            ThrowableItemLib.Utility:HideItem(player, true)

            Isaac.RunCallbackWithParam(ThrowableItemLib.Callback.POST_THROW, key, player, config, vect, slot or -1, mimic)
        end
    end
end)

---@param id CollectibleType
---@param player EntityPlayer
---@param flags UseFlag
---@param slot ActiveSlot
AddPriorityCallback(ModCallbacks.MC_PRE_USE_ITEM, CallbackPriority.IMPORTANT, function (_, id, _, player, flags, slot)
    local data = ThrowableItemLib.Internal:GetData(player)

    data.ForceInputSlot = nil

    if data.ThrownItem or (slot ~= -1 and not data.QuestionMarkCard) then return end

    data.QuestionMarkCard = nil

    local config = ThrowableItemLib.Utility:GetConfig(player, ThrowableItemLib.Internal:GetHeldConfigKey(id, ThrowableItemLib.Type.ACTIVE))

    if ThrowableItemLib.Internal:MimicCondition(id, player) then
        local throwConfigCard = ThrowableItemLib.Utility:GetThrowableCardConfig(player, slot, id)

        if throwConfigCard and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, throwConfigCard) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
            config = throwConfigCard
        else
            return
        end
    end

    if not config then return end

    local condition = ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config)

    if condition == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
        ThrowableItemLib.Utility:ScheduleLift(player, config.ID, config.Type, slot ~= -1 and slot or ActiveSlot.SLOT_PRIMARY, nil, 0)
        return true
    elseif condition == ThrowableItemLib.HoldConditionReturnType.DISABLE_USE then
        return true
    end
end)

---@param id CollectibleType
---@param player EntityPlayer
---@param slot ActiveSlot
AddPriorityCallback(ModCallbacks.MC_USE_ITEM, CallbackPriority.LATE, function (_, id, _, player, _, slot)
    local data = ThrowableItemLib.Internal:GetData(player)

    data.QuestionMarkCard = nil

    if data.ScheduleHideAnim then
        data.ScheduleHideAnim()
        data.ScheduleHideAnim = nil
    end

    if slot == ActiveSlot.SLOT_POCKET or slot == ActiveSlot.SLOT_POCKET2 then
        data.UsedPocket = true
    end
end)

if REPENTOGON then
    ---@param id Card
    ---@param player EntityPlayer
    ---@diagnostic disable-next-line: undefined-field
    AddPriorityCallback(ModCallbacks.MC_PRE_USE_CARD, CallbackPriority.EARLY, function (_, id, player)
        local data = ThrowableItemLib.Internal:GetData(player)

        data.UsedPocket = true
        data.ForceInputSlot = nil
        data.QuestionMarkCard = id == Card.CARD_QUESTIONMARK

        if data.UsedMimic then
            data.UsedMimic = nil
            return true
        end

        if data.ThrownItem then return end

        local config = ThrowableItemLib.Utility:GetConfig(player, ThrowableItemLib.Internal:GetHeldConfigKey(id, ThrowableItemLib.Type.CARD))
        if not config then return end

        local condition = ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config)

        if condition == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
            ThrowableItemLib.Utility:ScheduleLift(player, config.ID, config.Type, nil, nil, 0)
            return true
        elseif condition == ThrowableItemLib.HoldConditionReturnType.DISABLE_USE then
            return true
        end
    end)
else
    ---@param player EntityPlayer
    AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local data = ThrowableItemLib.Internal:GetData(player)

        data.UsedPocket = true
        data.ForceInputSlot = nil
        data.QuestionMarkCard = nil

        if data.UsedMimic then
            data.UsedMimic = nil
        end
    end)
end

---@param player EntityPlayer
AddCallback(ModCallbacks.MC_USE_PILL, function (_, _, player)
    local data = ThrowableItemLib.Internal:GetData(player)
    data.UsedPocket = true
end)

ThrowableItemLib.Utility:RegisterMimicItem({
    ID = CollectibleType.COLLECTIBLE_BLANK_CARD,
    Condition = function (card)
        return card:IsCard()
    end,
    PrimaryLift = not REPENTOGON,
    SetVarData = true,
})

ThrowableItemLib.Utility:RegisterMimicItem({
    ID = CollectibleType.COLLECTIBLE_CLEAR_RUNE,
    Condition = function (card)
        return card:IsRune()
    end,
    PrimaryLift = not REPENTOGON,
    SetVarData = true,
})

ThrowableItemLib.Utility:RegisterCharge({
    Identifier = 1,
    Priority = math.huge,
    Getter = function (player)
        return player:GetSoulCharge()
    end,
    Setter = function (player, amt)
        player:SetSoulCharge(amt)
    end
})

ThrowableItemLib.Utility:RegisterCharge({
    Identifier = 2,
    Priority = math.huge,
    Getter = function (player)
        return player:GetBloodCharge()
    end,
    Setter = function (player, amt)
        player:SetBloodCharge(amt)
    end
})

local function RegisterPGO()
    ---@diagnostic disable-next-line: undefined-global
    if FiendFolio then
        ---@diagnostic disable-next-line: undefined-global
        for _, v in ipairs({FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_1, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_2, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_3, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_4, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_5, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_6, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_8, FiendFolio.ITEM.COLLECTIBLE.PERFECTLY_GENERIC_OBJECT_12}) do
            ThrowableItemLib.Utility:RegisterMimicItem({
                ID = v,
                Condition = function (card)
                    ---@diagnostic disable-next-line: undefined-global
                    return FiendFolio.PocketObjectMimicCharges[card.ID]
                end,
                PrimaryLift = true,
            })
        end
    end
end
AddCallback(ModCallbacks.MC_POST_GAME_STARTED, RegisterPGO)
if game:GetFrameCount() > 0 then
    RegisterPGO()
end

for _, v in ipairs(ThrowableItemLib.Internal.CallbackEntries) do
    ThrowableItemLib:AddPriorityCallback(v.ID, v.PRIORITY, v.FN, v.FILTER)
end

return {Init = function () end}
