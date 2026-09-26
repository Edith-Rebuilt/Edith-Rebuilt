---@diagnostic disable: undefined-global
local scriptsPath = "resources.scripts."
local EpiphanyPath = scriptsPath .. "compat.contentModules.Epiphany.scripts."

if not Epiphany then return end

EdithRebuilt_TarnishedEdith = RegisterMod("Edith: Rebuilt (Tarnished Edith)", 1) --[[@as ModReference]]

local version = {
    1,
    0,
    0,
    ""
}

include(EpiphanyPath .. "definitions")

EdithRebuilt_TarnishedEdith.Modules = {
    TR_EDITH = include("resources.scripts.compat.contentModules.Epiphany.scripts.functions.TREdith"),
    TARGET = include("resources.scripts.compat.contentModules.Epiphany.scripts.functions.Target"),
}

include(EpiphanyPath .. "entities.players.Edith_C")

local beta = true
EdithRebuilt_TarnishedEdith.Version = "v" .. version[1].. "." .. version[2] .. "." .. version[3] .. version[4] .. (beta and "Beta" or "")

local message = "Edith Rebuilt Tarnished Edith module " .. EdithRebuilt_TarnishedEdith.Version .. " loaded correctly"


Isaac.DebugString(message)
print(message)

