local mod = EdithRebuilt
local edithCallbacks = mod.Enums.Callbacks

local musca = FiendFolio.ITEM.COLLECTIBLE.MUSCA

return {
    ---@param player EntityPlayer
    ---@param params EdithJumpStompParams
    func = function (_, player, params)
        if not player:HasCollectible(musca) then return end

        local rng = player:GetCollectibleRNG(musca)

        for i = 1, 3 do
            local randAngle = rng:RandomInt(360)

            local subType = rng:RandomInt(5) + 1 
            if Epiphany and rng:RandomFloat() < 0.444 then
				subType = rng:RandomInt(4) + 80
			end

            local locust = Isaac.Spawn(
                EntityType.ENTITY_FAMILIAR, 
                FamiliarVariant.BLUE_FLY, 
                subType, 
                player.Position, 
                Vector.FromAngle(randAngle + (120 * i)):Resized(10), 
                player):
            ToFamiliar() ---@cast locust EntityFamiliar

			locust.Player = player
			locust:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			locust:Update()
			local origColl = locust.EntityCollisionClass
			locust.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        end
    end,
    callback = edithCallbacks.BOMB_STOMP_LAND
}