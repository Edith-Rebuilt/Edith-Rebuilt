local mod = EdithRebuilt
local enums = mod.Enums
local TREnums = enums.Epiphany
local TRItems = TREnums.CollectibleType

local modules = mod.Modules
local Maths = modules.MATHS
local RNGMod = modules.RNG

local ChamberSprite = Sprite("gfx/Epiphany/SpiceChamber.anm2", true)
local SelectedSprite = Sprite("gfx/Epiphany/SpiceChamberSelectedSpice.anm2", true)
local FilledSprite = Sprite("gfx/Epiphany/SpiceChamberBlacks.anm2", true)

local sfx = enums.Utils.SFX

local SpiceChamberID = TRItems.COLLECTIBLE_SPICE_CHAMBER

local data = mod.DataHolder.GetEntityData

local offsetVec = {
	[1] = Vector(16, 16),
	[0.5] = Vector(8, 8),
}

mod:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, function ()
    return {HideItem = true}
end, TRItems.COLLECTIBLE_SPICE_CHAMBER)

---@param player EntityPlayer
---@param slot ActiveSlot
local function HandleSpiceCycle(player, slot)
    local current = player:GetActiveItemDesc(slot).VarData
    local next = current >= 8 and 1 or current + 1
    player:SetActiveVarData(next, slot)
end

---@param id CollectibleType
---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, id, rng, player, flags, slot)
    
    local pData = data(player)
    
    if pData.UsedChamber then return end
    HandleSpiceCycle(player, slot)

    sfx:Play(TREnums.SoundEffect.REVOLVER_CHANGE_GENERIC, 1, 2, false, RNGMod.RandomFloat(rng, 0.95, 1.05))

    pData.UsedChamber = true

    return true
end, TRItems.COLLECTIBLE_SPICE_CHAMBER)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if not player:HasCollectible(TRItems.COLLECTIBLE_SPICE_CHAMBER) then return end

    local pData = data(player)

    pData.ChamberFrames = pData.ChamberFrames or 0

    if not pData.UsedChamber then return end

    pData.ChamberFrames = pData.ChamberFrames + 1

    if pData.ChamberFrames % 8 == 0 then
        pData.UsedChamber = false
        pData.ChamberFrames = 0
    end
end)

local Colors = {
    [1] = Color(1, 1, 1),
    [2] = Color(0.5, 0.5, 0.5),
    [3] = Color(1, 238/255, 188/255),
    [4] = Color(113/255, 120/255, 82/255),
    [5] = Color(115/255, 84/255, 67/355),
    [6] = Color(250/255, 198/255, 49/255),
    [7] = Color(210/255, 105/255, 30/255),
    [8] = Color(239/255, 159/255, 89/255),
}

local VecZero = Vector.Zero
local VecOne = Vector.One

HudHelper.RegisterHUDElement({
	ItemID = TRItems.COLLECTIBLE_SPICE_CHAMBER,
	OnRender = function(player, _, _, position, _, scale, _, slot)
        local offset = offsetVec[scale]

        local RenderPos = position + offset
        local RenderScale = VecOne * scale
        local rotation = -(data(player).ChamberFrames or 0) * 45

        ChamberSprite:Play("Idle")
        FilledSprite:Play("Idle")
        SelectedSprite:Play("Idle")

		ChamberSprite.Scale = RenderScale
		FilledSprite.Scale = RenderScale
		SelectedSprite.Scale = RenderScale

        ChamberSprite.Rotation = rotation
        FilledSprite.Rotation = rotation

        SelectedSprite.Color = Colors[player:GetActiveItemDesc(slot).VarData]

        SelectedSprite:Render(RenderPos, VecZero, VecZero)
        FilledSprite:Render(RenderPos, VecZero, VecZero)
        ChamberSprite:Render(RenderPos, VecZero, VecZero)

	end
}, HudHelper.HUDType.ACTIVE_ID)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    local slot = player:GetActiveItemSlot(SpiceChamberID)

    if slot == -1 then return end
    if player:GetActiveItemDesc(slot).VarData ~= 0 then return end

    player:SetActiveVarData(1, slot)
end)