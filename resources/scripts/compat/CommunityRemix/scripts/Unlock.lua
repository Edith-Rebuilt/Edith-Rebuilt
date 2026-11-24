local mod = EdithRebuilt
local Player = mod.Modules.PLAYER

return {
    {
        func = function (_, mark)
            if mark ~= "InsaneMode" then return end
            if not Player.AnyoneIsEdith() then return end
    
            mod.Enums.Utils.PGD:TryUnlock(EdithRebuilt_SaltHearts.Enums.Achievement.SALT_HEART)
        end,
        callback = ModCallbacks.MC_POST_COMPLETION_EVENT
    } 
} --[=[@as CompatCallbackEntry[]]=] 