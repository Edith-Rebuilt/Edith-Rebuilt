local mainEnums = EdithRebuilt.Enums

EdithRebuilt_SaltHearts.Enums = {
    HeartSubType = {
        SALT_HEART = Isaac.GetEntitySubTypeByName("Salt Heart (pickup)"),
        SALT_HEART_2_THIRDS = Isaac.GetEntitySubTypeByName("Salt Heart (pickup 2/3)"),
        SALT_HEART_1_THIRD = Isaac.GetEntitySubTypeByName("Salt Heart (pickup 1/3)"),
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