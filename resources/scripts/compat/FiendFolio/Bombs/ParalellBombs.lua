local mod = EdithRebuilt
local enums = mod.Enums
local edithCallbacks = enums.Callbacks

local utils = enums.Utils
local game = utils.Game
local room = utils.Room

local function GetRoomCenter()
	return room:GetRoomShape() > 8 and Vector(580, 420) or room:GetCenterPos()
end

return {
	{
		---@param player EntityPlayer
		---@param params EdithJumpStompParams
		func = function(_, player, params)
			if not player:HasCollectible(FiendFolio.ITEM.COLLECTIBLE.PARALLEL_BOMBS) then return end

			local roomCenter = GetRoomCenter()
			local explosionPos = room:GetClampedPosition((roomCenter - player.Position) + roomCenter, 0)

			game:BombExplosionEffects(explosionPos, params.Damage / 2)
		end,
		callback = edithCallbacks.BOMB_STOMP_LAND
	},
}