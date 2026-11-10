local mod = EdithRebuilt
local enums = mod.Enums
local edithCallbacks = enums.Callbacks
local Player = mod.Modules.PLAYER

local fabergeBombs = FiendFolio.ITEM.COLLECTIBLE.FABERGE_BOMBS
local goldenDecrementation = 1

local function getFractionalCoinSpawnMultiplier(player) -- Maybe other things can increase this, I love shitty little random synergies that don't matter, I'm open to ideas
	return math.min(10,
		(1 + 0.3 * math.max(0, player:GetCollectibleNum(fabergeBombs) - 1)) *
		(1.09 ^ player:GetCollectibleNum(FiendFolio.ITEM.COLLECTIBLE.PAK_CHOI)) -- :)
	)
end

return {
	{
		---@param player EntityPlayer
		---@param params EdithJumpStompParams
		func = function(_, player, params)
			if not player:HasCollectible(fabergeBombs) then return end

			local bombData = FiendFolio:GetEntityData(player)
			local frame = enums.Utils.Game:GetFrameCount()
			if bombData.lastFrameFaberged == frame then
				return
			end

			local rng = player:GetCollectibleRNG(fabergeBombs)
			local minSpawns = bombData.FFIsScatter and 1 or 10
			local realDecrementation = player:HasGoldenBomb() and goldenDecrementation or 1
			
			minSpawns = math.max(1, math.ceil(minSpawns * realDecrementation))

			for i = 1, rng:RandomInt(minSpawns, minSpawns * 2) * getFractionalCoinSpawnMultiplier(player) do
				local penny = Isaac.Spawn(5, PickupVariant.PICKUP_COIN, FiendFolio.PICKUP.COIN.LIL_PENNY, player.Position, rng:RandomVector() * (13 + rng:RandomFloat() * 5), player)
				penny:GetSprite():Play("AppearFast")
				FiendFolio:GetEntityData(penny).dangerousMode = player
			end

			if player:HasGoldenBomb() and not bombData.FFIsScatter then
				goldenDecrementation = goldenDecrementation * 0.7
			end

			bombData.lastFrameFaberged = frame
		end,
		callback = edithCallbacks.BOMB_STOMP_LAND
	},
    {
        ---@param player EntityPlayer
		---@param params EdithJumpStompParams
        func = function (_, player, params)
            if not FiendFolio.CanPlayerPlaceFabergeBomb(player) then return end
			player:AddCoins(-3)
			enums.Utils.SFX:Play(SoundEffect.SOUND_CASH_REGISTER)
			return true
        end,
        callback = edithCallbacks.BOMB_STOMP_TRIGGER
    },
	{
		---@param player EntityPlayer
		func = function (_, player)
			if not Player.IsEdith(player, false) then return end 
            if not FiendFolio.CanPlayerPlaceFabergeBomb(player) then return end

			return false
		end,
		callback = ModCallbacks.MC_PRE_PLAYER_USE_BOMB,
		priority = CallbackPriority.IMPORTANT
	}
}