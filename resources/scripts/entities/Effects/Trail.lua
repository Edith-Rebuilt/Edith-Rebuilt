local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local misc = enums.Misc
local Trail = {}
local SaveManager = mod.SaveManager
local Helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local data = mod.DataHolder.GetEntityData

function Trail.ResetTEdithTrail(player)
	local playerData = data(player)

    if not playerData.Trail then return end

    playerData.Trail.Visible = false
	playerData.Trail:Remove()
	playerData.Trail = nil
end

function Trail.SpawnTEdithTrail(player)
	local playerData = data(player)

	if playerData.Trail then return end
	local entityParent = player 
	local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0,		entityParent.Position, Vector.Zero, entityParent):ToEffect()
	
	if not trail then return end
    if not SaveManager then return end
    
    local Settings = SaveManager:GetSettingsSave()
    if not Settings then return end

    local TEdithSettings = Settings.TEdithData
    local trailParams = Helpers.When(TEdithSettings.TrailDesign, tables.TEdithTrailParams)

	trail:FollowParent(entityParent)
	trail.Color = Color(1, 1, 1, 1)
	trail.MinRadius = 0.1
	trail.SpriteScale = Vector.One * trailParams.Size
    trail:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

	local sprite = trail:GetSprite()
	sprite:GetLayer(0):GetBlendMode():SetMode(BlendType.NORMAL)

    sprite:ReplaceSpritesheet(0, misc.TrailPath .. trailParams.Suffix .. ".png", true)

	playerData.Trail = trail 
	data(trail).EdithRebuilTrail = true

    Isaac.RunCallback(enums.Callbacks.TRAIL_SPRITE_CHANGE)
end

function Trail:TrailManagement(player)
    if not Player.IsEdith(player, true) then return end
    if not SaveManager then return end

    local TEdithSettings = Helpers.GetConfigData("TEdithData")    

    if not TEdithSettings then return end

    if TEdithSettings.EnableHopdashTrail then
        Trail.SpawnTEdithTrail(player)
    else
        Trail.ResetTEdithTrail(player)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Trail.TrailManagement)

function Trail:OnTrailSpriteChange(trail)
    if not trail then return end
    if not SaveManager then return end

    local Settings = SaveManager:GetSettingsSave()
    if not Settings then return end

    local TEdithSettings = Settings.TEdithData
    local trailParams = Helpers.When(TEdithSettings.TrailDesign, tables.TEdithTrailParams)

    trail.SpriteScale = Vector.One * trailParams.Size
    trail:GetSprite():ReplaceSpritesheet(0, misc.TrailPath .. trailParams.Suffix .. ".png", true)
end
mod:AddCallback(enums.Callbacks.TRAIL_SPRITE_CHANGE, Trail.OnTrailSpriteChange)

function Trail:OnNewRoom()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if not Player.IsEdith(player, true) then goto continue end
        Trail.ResetTEdithTrail(player)

        ::continue::
    end 
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Trail.OnNewRoom)