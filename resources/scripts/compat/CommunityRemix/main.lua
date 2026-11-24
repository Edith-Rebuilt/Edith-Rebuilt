local scriptsPath = "resources.scripts."
local CRemixPath = scriptsPath .. "compat.CommunityRemix.scripts."

local function CRemixCompat()
    EdithRebuilt_SaltHearts = RegisterMod("Edith: Rebuilt (Salt Hearts)", 1)

    include(scriptsPath .. "libs.customhealthapi.core")

    EdithRebuilt.PatchesLoader.LoadScripts({
		CRemixPath .. "Enums",
		CRemixPath .. "Clot",
		CRemixPath .. "Health",
		CRemixPath .. "Replace",
		CRemixPath .. "Unlock",
	})

    local version = {
        1,
        1,
        0,
        ""
    }

    local beta = false
    EdithRebuilt_SaltHearts.Version = "v" .. version[1].. "." .. version[2] .. "." .. version[3] .. version[4] .. (beta and "Beta" or "")

    local message = "Edith Rebuilt Salt Hearts module " .. EdithRebuilt_SaltHearts.Version .. " loaded correctly"

    Isaac.DebugString(message)
    print(message)
end

local function CRemixFailsafe()
    include(CRemixPath .. "Failsafe")
end

EdithRebuilt.PatchesLoader.RegisterPatch("communityRemix", CRemixCompat, CRemixFailsafe)