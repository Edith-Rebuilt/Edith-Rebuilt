local mod = EdithRebuilt
local enums = mod.Enums
local edithCallbacks = enums.Callbacks

local modules = mod.Modules
local Player = modules.PLAYER
local Helpers = modules.HELPERS

local bridgeBombs = FiendFolio.ITEM.COLLECTIBLE.BRIDGE_BOMBS

local utils = enums.Utils
local room = utils.Room
local sfx = utils.SFX

return {
	{
		---@param player EntityPlayer
		---@param params EdithJumpStompParams
		func = function(_, player, params)
            if not player:HasCollectible(bridgeBombs) then return end
            if room:GetType() == RoomType.ROOM_BOSS and room:GetBossID() == BossType.MEGA_SATAN then return end

            local pos = player.Position
            local radius = mod.Modules.HELPERS.GetBombRadiusFromDamage(params.Damage)
            local MakeBridge = false

            Helpers.ForEachGridInRadius(pos, radius, function (grid)
                local pit = grid:ToPit()

                if not pit then return end
                pit:MakeBridge(nil)
                MakeBridge = true
            end)

            if MakeBridge then
                sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 1.0, 0, false, 1.0)
            end
        end,
		callback = edithCallbacks.BOMB_STOMP_LAND
	}
}