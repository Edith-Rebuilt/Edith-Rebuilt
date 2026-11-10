local mod = EdithRebuilt
local girlDinner = FiendFolio.ITEM.COLLECTIBLE.GIRL_DINNER

local Player = mod.Modules.PLAYER

return {
    {
        ---@param pickup EntityPickup
        ---@param collider Entity
        func = function (_, pickup, collider)
            if pickup.SubType ~= girlDinner then return end

            local player = collider:ToPlayer()

            if not player then return end
            if not Player.IsAnyEdith(player) then return end
            FiendFolio:GetEntityData(player).randomGirlDecided = true

            -- print("GIRL DINNER")
            -- return false

        end,
        priority = CallbackPriority.IMPORTANT,
        callback = ModCallbacks.MC_PRE_PICKUP_COLLISION,
        param = PickupVariant.PICKUP_COLLECTIBLE
    }
}