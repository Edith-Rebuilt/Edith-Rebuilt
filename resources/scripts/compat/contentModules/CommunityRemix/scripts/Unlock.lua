local mod = EdithRebuilt
local Player = mod.Modules.PLAYER


EdithRebuilt_SaltHearts:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, function(_, mark)
    if mark ~= "InsaneMode" then return end
    if not Player.AnyoneIsEdith() then return end

    mod.Enums.Utils.PGD:TryUnlock(EdithRebuilt_SaltHearts.Enums.Achievement.SALT_HEART)
end)