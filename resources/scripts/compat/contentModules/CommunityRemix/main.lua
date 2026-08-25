local scriptsPath = "resources.scripts."
local CRemixPath = scriptsPath .. "compat.contentModules.CommunityRemix.scripts."

if not communityRemix then 
    include(CRemixPath .. "Failsafe")
    return 
end

EdithRebuilt_SaltHearts = RegisterMod("Edith: Rebuilt (Salt Hearts)", 1) --[[@as ModReference]]

local version = {
    1,
    0,
    0,
    ""
}

local beta = false
EdithRebuilt_SaltHearts.Version = "v" .. version[1].. "." .. version[2] .. "." .. version[3] .. version[4] .. (beta and "Beta" or "")

local message = "Edith Rebuilt Salt Hearts module " .. EdithRebuilt_SaltHearts.Version .. " loaded correctly"

include(scriptsPath .. "libs.customhealthapi.core")

include(CRemixPath .. "Enums")
include(CRemixPath .. "Unlock")
include(CRemixPath .. "Health")
include(CRemixPath .. "Replace")

Isaac.DebugString(message)
print(message)
