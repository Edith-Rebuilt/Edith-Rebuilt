local mod = EdithRebuilt
local enums = mod.Enums

local effects = enums.EdithStatusEffects
local SubTypes = enums.SubTypes
local edithCallbacks = enums.Callbacks

local modules = mod.Modules
local RNGMod = modules.RNG
local statusEffect = modules.STATUS_EFFECTS

local sfx = enums.Utils.SFX
local SpiceChamberID = enums.CollectibleType.COLLECTIBLE_SPICE_CHAMBER
local data = mod.DataHolder.GetEntityData

local ChamberSprite = Sprite("gfx/Epiphany/SpiceChamber.anm2", true)
local SelectedSprite = Sprite("gfx/Epiphany/SpiceChamberSelectedSpice.anm2", true)
local FilledSprite = Sprite("gfx/Epiphany/SpiceChamberBlacks.anm2", true)

local VecZero = Vector.Zero
local VecOne = Vector.One

local SpiceRingRadiusVec = Vector(30, 0)

local SPICE_COUNT = 8
local CHAMBER_COOLDOWN_FRAMES = 8
local CHAMBER_DEGREES_PER_FRAME = 360 / CHAMBER_COOLDOWN_FRAMES -- una vuelta completa por cooldown
local CREEP_BASE_COUNT = 10

local HUD_OFFSET_BY_SCALE = {
    [1] = Vector(16, 16),
    [0.5] = Vector(8, 8),
}

local SpiceToCreep = {
    [effects.SALTED] = SubTypes.SALT_CREEP,
    [effects.PEPPERED] = SubTypes.PEPPER_CREEP,
    [effects.GARLIC] = SubTypes.GARLIC_CREEP,
    [effects.OREGANO] = SubTypes.OREGANO_CREEP,
    [effects.CUMIN] = SubTypes.CUMIN_CREEP,
    [effects.TURMERIC] = SubTypes.TURMERIC_CREEP,
    [effects.CINNAMON] = SubTypes.CINNAMON_CREEP,
    [effects.GINGER] = SubTypes.GINGER_CREEP,
}

---@param player EntityPlayer
---@return boolean
local function IsChamberOnCooldown(player)
    return (data(player).ChamberCooldown or 0) > 0
end

---@param player EntityPlayer
local function TickChamberCooldown(player)
    local pData = data(player)

    pData.ChamberCooldown = math.max((pData.ChamberCooldown or 0) - 1, 0)
end

---@param player EntityPlayer
---@return number
local function GetChamberRotation(player)
    local cooldown = data(player).ChamberCooldown or 0
    if cooldown <= 0 then return 0 end

    return -(CHAMBER_COOLDOWN_FRAMES - cooldown) * CHAMBER_DEGREES_PER_FRAME
end

---@param player EntityPlayer
---@param slot ActiveSlot
local function CycleSpice(player, slot)
    local current = player:GetActiveItemDesc(slot).VarData
    local nextSpice = current >= SPICE_COUNT and 1 or current + 1

    player:SetActiveVarData(nextSpice, slot)
end

---@param player EntityPlayer
---@param slot ActiveSlot
local function EnsureSpiceSelected(player, slot)
    if player:GetActiveItemDesc(slot).VarData ~= 0 then return end

    player:SetActiveVarData(1, slot)
end

---@param player EntityPlayer
---@param slot ActiveSlot
local function GetSelectedSpice(player, slot)
    return statusEffect.GetSpiceEffect(player:GetActiveItemDesc(slot).VarData)
end

mod:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, function ()
    return {HideItem = true}
end, SpiceChamberID)

---@param rng RNG
---@param player EntityPlayer
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player, _, slot)
    if IsChamberOnCooldown(player) then return end

    CycleSpice(player, slot)

    sfx:Play(
        enums.SoundEffect.SOUND_REVOLVER_CHANGE_GENERIC,
        1, 2, false,
        RNGMod.RandomFloat(rng, 0.95, 1.05)
    )

    data(player).ChamberCooldown = CHAMBER_COOLDOWN_FRAMES

    return true
end, SpiceChamberID)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    local slot = player:GetActiveItemSlot(SpiceChamberID)
    if slot == -1 then return end

    TickChamberCooldown(player)
    EnsureSpiceSelected(player, slot)
end)

---@param sprite Sprite
---@param scale Vector
---@param rotation number
local function PrepareSprite(sprite, scale, rotation)
    sprite:Play("Idle")
    sprite.Scale = scale
    sprite.Rotation = rotation
end

---@param spice table
---@return Color
local function GetSpiceHudColor(spice)
    local color = spice.Color
    local tint = spice.ID == "Pepper" and color:GetTint() or color:GetOffset()

    return Color(tint.R, tint.G, tint.B)
end

HudHelper.RegisterHUDElement({
    ItemID = SpiceChamberID,
    OnRender = function (player, _, _, position, _, scale, _, slot)
        local renderPos = position + HUD_OFFSET_BY_SCALE[scale]
        local renderScale = VecOne * scale
        local rotation = GetChamberRotation(player)

        PrepareSprite(SelectedSprite, renderScale, 0)
        PrepareSprite(FilledSprite, renderScale, rotation)
        PrepareSprite(ChamberSprite, renderScale, rotation)

        SelectedSprite.Color = GetSpiceHudColor(GetSelectedSpice(player, slot --[[@as ActiveSlot]]))

        -- De atrás hacia adelante
        SelectedSprite:Render(renderPos, VecZero, VecZero)
        FilledSprite:Render(renderPos, VecZero, VecZero)
        ChamberSprite:Render(renderPos, VecZero, VecZero)
    end
}, HudHelper.HUDType.ACTIVE_ID)

---@param ent Entity
---@param spice table
---@param charge number
local function SpawnSpiceCreeps(ent, spice, charge)
    local amount = math.ceil(CREEP_BASE_COUNT * charge)
    local angleStep = 360 / amount
    local ringOffset = SpiceRingRadiusVec * charge
    local creepSubType = SpiceToCreep[spice.ID]

    for i = 1, amount do
        local creep = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.PLAYER_CREEP_RED,
            creepSubType,
            ent.Position + ringOffset:Rotated(angleStep * i),
            VecZero,
            nil
        ):ToEffect() ---@cast creep EntityEffect

        creep.CollisionDamage = 0
    end
end

---@param player EntityPlayer
---@param ent Entity
---@param flingParams TREdithFlingStrikeParams
mod:AddCallback(edithCallbacks.STRIKE_HIT_ENEMY, function (_, player, ent, flingParams)
    local slot = player:GetActiveItemSlot(SpiceChamberID)
    if slot == -1 then return end

    SpawnSpiceCreeps(ent, GetSelectedSpice(player, slot), flingParams.FlingMoveCharge)
end)