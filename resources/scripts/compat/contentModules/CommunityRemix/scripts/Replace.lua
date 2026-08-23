local mainMod = EdithRebuilt
local enums = EdithRebuilt_SaltHearts.Enums
local mod = EdithRebuilt_SaltHearts
local mainEnums = mainMod.Enums
local utils = mainEnums.Utils
local room = utils.Room
local level = utils.Level

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if not utils.PGD:Unlocked(enums.Achievement.SALT_HEART) then return end
    if pickup.Variant ~= PickupVariant.PICKUP_HEART then return end
    if pickup.SubType ~= HeartSubType.HEART_SOUL then return end
    if not mainMod.Modules.RNG.RandomBoolean(enums.Utils.RNG, 0.25) then return end

    local roomDesc = level:GetLastRoomDesc()
    local roomFrameCount = room:GetFrameCount()
    local visitedCount = roomDesc.VisitedCount

    if not (roomFrameCount > 0 or visitedCount == 0) then return end

    pickup:Morph(5, PickupVariant.PICKUP_HEART, mod.Enums.HeartSubType.SALT_HEART, true, true)
end)