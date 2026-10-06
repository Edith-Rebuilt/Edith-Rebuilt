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

local data = mod.DataHolder.GetEntityData

local offsetVec = {
	[1] = Vector(16, 16),
	[0.5] = Vector(8, 8),
}

mod:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, function ()
    return {HideItem = true}
end, TRItems.COLLECTIBLE_SPICE_CHAMBER)

mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function (_, id, rng, player)
    local pData = data(player)

    sfx:Play(TREnums.SoundEffect.REVOLVER_CHANGE_GENERIC, 1, 2, false, RNGMod.RandomFloat(rng, 0.95, 1.05))
    
    if pData.UsedChamber == true then return end

    pData.SpiceChamberSpice = pData.SpiceChamberSpice or 0
    pData.SpiceChamberSpice = Maths.Clamp(pData.SpiceChamberSpice + 1, 1, 9)

    if pData.SpiceChamberSpice > 8 then
        pData.SpiceChamberSpice = 1
    end

    pData.UsedChamber = true
end, TRItems.COLLECTIBLE_SPICE_CHAMBER)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if not player:HasCollectible(TRItems.COLLECTIBLE_SPICE_CHAMBER) then return end

    local pData = data(player)

    pData.ChamberFrames = pData.ChamberFrames or 0

    if not pData.UsedChamber then return end

    pData.ChamberFrames = pData.ChamberFrames + 1

    if pData.ChamberFrames % 4 == 0 then
        pData.UsedChamber = false
    end
end)

local Colors = {
    [1] = Color(1, 1, 1, 1, 0.3, 0.3, 0.3),
    [2] = Color(0.5, 0.5, 0.5),
    [3] = Color(0, 0, 0, 1, 1, 238/255, 188/255),
    [4] = Color(0, 0, 0, 1, 113/255, 120/255, 82/255),
    [5] = Color(0, 0, 0, 1, 115/255, 84/255, 67/355),
    [6] = Color(0, 0, 0, 1, 250/255, 198/255, 49/255),
    [7] = Color(0, 0, 0, 1, 210/255, 105/255, 30/255),
    [8] = Color(0, 0, 0, 1, 239/255, 159/255, 89/255),
}

local VecZero = Vector.Zero
local VecOne = Vector.One

HudHelper.RegisterHUDElement({
	ItemID = TRItems.COLLECTIBLE_SPICE_CHAMBER,
	OnRender = function(player, _, _, position, _, scale)
        local offset = offsetVec[scale]

        local RenderPos = position + offset
        local RenderScale = VecOne * scale

        ChamberSprite:Play("Idle")
        FilledSprite:Play("Idle")
        SelectedSprite:Play("Idle")

		ChamberSprite.Scale = RenderScale
		FilledSprite.Scale = RenderScale
		SelectedSprite.Scale = RenderScale

        ChamberSprite.Rotation = data(player).ChamberFrames * 15
        SelectedSprite.Color = Colors[ data(player).SpiceChamberSpice]

        FilledSprite:Render(RenderPos, VecZero, VecZero)
        SelectedSprite:Render(RenderPos, VecZero, VecZero)
        ChamberSprite:Render(RenderPos, VecZero, VecZero)
	end
}, HudHelper.HUDType.ACTIVE_ID)
