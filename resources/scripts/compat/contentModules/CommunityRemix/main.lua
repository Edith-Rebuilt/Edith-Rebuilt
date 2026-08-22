if not communityRemix then return end

EdithRebuilt_SaltHearts = RegisterMod("Edith: Rebuilt (Salt Hearts)", 1) --[[@as ModReference]]


local version = {
    1,
    0,
    0,
    ""
}

local beta = true
EdithRebuilt_SaltHearts.Version = "v" .. version[1].. "." .. version[2] .. "." .. version[3] .. version[4] .. (beta and "Beta" or "")

local message = "Edith Rebuilt Salt Hearts module " .. EdithRebuilt_SaltHearts.Version .. " loaded correctly"

include("resources.scripts.libs.customhealthapi.core")

Isaac.DebugString(message)
print(message)
