local mod = EdithRebuilt
local Player = mod.Modules.PLAYER

local Achievement = Isaac.GetAchievementIdByName("Salt Hearts")

mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, function(_, mark)
    if mark ~= "InsaneMode" then return end
    if not Player.AnyoneIsEdith() then return end

    mod.Enums.Utils.PGD:TryUnlock(Achievement)
end)