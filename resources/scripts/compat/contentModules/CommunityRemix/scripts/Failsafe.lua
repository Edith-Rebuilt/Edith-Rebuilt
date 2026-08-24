local mainMod = EdithRebuilt
local mainEnums = mainMod.Enums
local utils = mainEnums.Utils
local room = utils.Room
local level = utils.Level

local SubType = {
    SALT_HEART = Isaac.GetEntitySubTypeByName("Salt Heart (pickup)"),
    SALT_HEART_2_THIRDS = Isaac.GetEntitySubTypeByName("Salt Heart (pickup 2/3)"),
    SALT_HEART_1_THIRD = Isaac.GetEntitySubTypeByName("Salt Heart (pickup 1/3)"),
}

---@param pickup EntityPickup
local function ReplaceFullSaltHeart(pickup)
    if pickup.SubType ~= SubType.SALT_HEART then return end

    pickup:Morph(5, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL, true, true)
end

---@param pickup EntityPickup
local function ReplaceFractionSaltHeart(pickup)
    if not (pickup.SubType == SubType.SALT_HEART_2_THIRDS or pickup.SubType == SubType.SALT_HEART_1_THIRD) then return end

    pickup:Morph(5, PickupVariant.PICKUP_HEART, HeartSubType.HEART_HALF_SOUL, true, true)
end

mainMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if pickup.Variant ~= PickupVariant.PICKUP_HEART then return end

    local roomFrameCount = room:GetFrameCount()
    local visitedCount = level:GetLastRoomDesc().VisitedCount

    if not (roomFrameCount > 0 or visitedCount == 0) then return end

    ReplaceFullSaltHeart(pickup)
    ReplaceFractionSaltHeart(pickup)
end)