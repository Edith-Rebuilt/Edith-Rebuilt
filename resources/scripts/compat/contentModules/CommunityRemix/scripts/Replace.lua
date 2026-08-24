local mainMod = EdithRebuilt
local enums = EdithRebuilt_SaltHearts.Enums
local mod = EdithRebuilt_SaltHearts
local mainEnums = mainMod.Enums
local utils = mainEnums.Utils
local ModRNG = mainMod.Modules.RNG
local room = utils.Room
local level = utils.Level
local SubTypes = enums.HeartSubType
local RNG = enums.Utils.RNG

---@param pickup EntityPickup
local function ReplaceFullSoulHeart(pickup)
    if pickup.SubType ~= HeartSubType.HEART_SOUL then return end
    if not ModRNG.RandomBoolean(RNG, 0.25) then return end

    pickup:Morph(5, PickupVariant.PICKUP_HEART, SubTypes.SALT_HEART, true, true)
end

---@param pickup EntityPickup
local function ReplaceHalfSoulHeart(pickup)
    if pickup.SubType ~= HeartSubType.HEART_HALF_SOUL then return end
    if not ModRNG.RandomBoolean(RNG, 0.25) then return end

    local SubTypeSalt = ModRNG.RandomBoolean(RNG, 1/3) and SubTypes.SALT_HEART_2_THIRDS or SubTypes.SALT_HEART_1_THIRD
    
    pickup:Morph(5, PickupVariant.PICKUP_HEART, SubTypeSalt, true, true)
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if not utils.PGD:Unlocked(enums.Achievement.SALT_HEART) then return end
    if pickup.Variant ~= PickupVariant.PICKUP_HEART then return end

    local roomFrameCount = room:GetFrameCount()
    local visitedCount = level:GetLastRoomDesc().VisitedCount

    if not (roomFrameCount > 0 or visitedCount == 0) then return end

    ReplaceFullSoulHeart(pickup)
    ReplaceHalfSoulHeart(pickup)
end)