local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local effects = enums.EdithStatusEffects
local spicesMixID = enums.CollectibleType.COLLECTIBLE_SPICES_MIX
local game = utils.Game
local hud = utils.HUD
local modules = mod.Modules
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG

local SPICES = {
    COUNT = 8,
    FIRST = 1,
    EFFECT_RADIUS = 60,
    PUSH_FORCE = 30,
    SCALE_MIN = 0.85,
    SCALE_MAX = 1.15,
    PLAYBACK_MIN = 0.9,
    PLAYBACK_MAX = 1.1,
}

local Descriptions = {
    [effects.SALTED] = "Slow and weakness, chance to destroy enemy's shots",
    [effects.PEPPERED] = "Enemies sneezes every 2nd hit, leave damaging creep on kill",
    [effects.CUMIN] = "Erratic movement, damaging enemies stops them",
    [effects.OREGANO] = "Slower enemies, slowing creep, constant damage over time",
    [effects.TURMERIC] = "Weaker enemies, infecting clouds on hit",
    [effects.GINGER] = "More pushable enemies, infecting clouds on kill",
    [effects.GARLIC] = "The enemies retreat, scattered shots",
    [effects.CINNAMON] = "Dusty Cough, persistent damaging and slowing cinnamon clouds",
}

local SpicesJar = Sprite("gfx/ui/StatusEffects/EdithRebuiltSpicesMixJar.anm2", true)
SpicesJar:Play("Idle", true)

---@param spice SpiceEffect
local function ShowSpiceInfo(spice)
    local spiceID = spice.ID
    hud:ShowItemText(spiceID, Descriptions[spiceID])
end

---@param player EntityPlayer
---@param slot ActiveSlot
local function InitializeSpiceData(player, slot)
    if player:GetActiveItemDesc(slot).VarData ~= 0 then return end
    player:SetActiveVarData(SPICES.FIRST, slot)
    ShowSpiceInfo(StsEffects.GetSpiceEffect(1))
end

---@param player EntityPlayer
---@param slot ActiveSlot
local function HandleSpiceInfoDisplay(player, slot)
    if not Input.IsActionTriggered(ButtonAction.ACTION_MAP, player.ControllerIndex) then return end
    local spice = StsEffects.GetSpiceEffect(player:GetActiveItemDesc(slot).VarData)
    ShowSpiceInfo(spice)
end

---@param player EntityPlayer
---@param slot ActiveSlot
local function HandleSpiceCycle(player, slot)
    if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end

    local current = player:GetActiveItemDesc(slot).VarData
    local next = current >= SPICES.COUNT and SPICES.FIRST or current + 1
    player:SetActiveVarData(next, slot)

    local spice = StsEffects.GetSpiceEffect(next)
    ShowSpiceInfo(spice)
end

---@param player EntityPlayer
---@param spice SpiceEffect
---@param RNG RNG
local function SpawnSpiceCloud(player, spice, RNG)
    local randCol = spice.Color
    local newColor = spice.ID == "Salted"
        and randCol
        or  Color(randCol.RO, randCol.GO, randCol.BO)

    local puff = StsEffects.SpawnSpicePuff(player, RNG)
    puff.SpriteScale = Vector(
        ModRNG.RandomFloat(RNG, SPICES.SCALE_MIN, SPICES.SCALE_MAX),
        ModRNG.RandomFloat(RNG, SPICES.SCALE_MIN, SPICES.SCALE_MAX)
    )
    puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(RNG, SPICES.PLAYBACK_MIN, SPICES.PLAYBACK_MAX)
    puff:SetColor(newColor, -1, 1000, false, false)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    local slot = player:GetActiveItemSlot(spicesMixID)
    if slot == -1 then return end

    InitializeSpiceData(player, slot)
    HandleSpiceInfoDisplay(player, slot)
    HandleSpiceCycle(player, slot)
end)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, RNG, player, _, slot)
    local spice = StsEffects.GetSpiceEffect(player:GetActiveItemDesc(slot).VarData)
    SpawnSpiceCloud(player, spice, RNG)
    StsEffects.TriggerSpiceEffect(player, spice, SPICES.EFFECT_RADIUS, SPICES.PUSH_FORCE)
    return true
end, spicesMixID)

HudHelper.RegisterHUDElement({
    ItemID = spicesMixID,
    OnRender = function(player, _, _, position, alpha, scale, _, slot)
        if scale < 1 then return end
        SpicesJar.Scale = Vector.One * scale
        SpicesJar.Color = Color(1, 1, 1, alpha)
        SpicesJar:SetFrame("Idle", player:GetActiveItemDesc(slot --[[@as ActiveSlot]]).VarData - 1)
        SpicesJar:Render(position + Vector(16, 16))
    end
}, HudHelper.HUDType.ACTIVE_ID)

mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function(_, _, _, varData)
    return StsEffects.GetSpiceEffect(varData).Cooldown
end, spicesMixID)