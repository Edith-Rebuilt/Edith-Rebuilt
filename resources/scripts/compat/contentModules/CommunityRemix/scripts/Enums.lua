local mainEnums = EdithRebuilt.Enums

EdithRebuilt_SaltHearts.Enums = {
    HeartSubType = {
        SALT_HEART = Isaac.GetEntitySubTypeByName("Salt Heart (pickup)")
    },
    Achievement = {
        SALT_HEART = Isaac.GetAchievementIdByName("Salt Hearts"),
    },
    Utils = {
        RNG = RNG()
    }
}

EdithRebuilt_SaltHearts:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
    EdithRebuilt_SaltHearts.Enums.Utils.RNG:SetSeed(mainEnums.Utils.Game:GetSeeds():GetStartSeed(), 35)
end)