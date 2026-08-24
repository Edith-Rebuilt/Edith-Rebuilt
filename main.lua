EdithRebuilt = RegisterMod("Edith: Rebuilt", 1) --[[@as table|ModReference]]
local mod = EdithRebuilt
local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

if not REPENTOGON then
	local text = "REPENTOGON is missing"
	local text2 = "check repentogon.com"
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, KColor(2,.5,.5,1), 1, true )
        font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, KColor(2,.5,.5,1), 1, true )
    end)
	return 
end

if not REPENTANCE_PLUS then
	local text = "This mod is meant to be used with the Repentance+ DLC"
	local text2 = "Look for it on steam"
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, KColor(2,.5,.5,1), 1, true )
        font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, KColor(2,.5,.5,1), 1, true )
    end)
	return
end

font:Unload()
font = nil

EdithRebuilt.DataHolder = include("resources.scripts.libs.DataHolder")
EdithRebuilt.TempStatsLib = require("resources.scripts.libs.TempStatsLib")
EdithRebuilt.SaveManager = require("resources.scripts.libs.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)
EdithRebuilt.Hsx = require("resources.scripts.libs.lhsx")

mod.TempStatsLib(function (player)
	return mod.SaveManager.GetRunSave(player)
end)

include("resources.scripts.misc.dss.dssmain")
include("resources.scripts.misc.dss.changelogs")
include("resources.scripts.libs.hud_helper")
include("resources.scripts.libs.prenpckillcallback")
include("resources.scripts.libs.EdithKotryJumpLib").Init()
include("resources.scripts.definitions")
include("resources.scripts.libs.status_effect_library")

EdithRebuilt.Modules = {
	RNG = include("resources.scripts.functions.RNG"),
	HELPERS = include("resources.scripts.functions.Helpers"),
	VEC_DIR = include("resources.scripts.functions.VecDir"),
	MATHS = include("resources.scripts.functions.Maths"),
	TARGET_ARROW = include("resources.scripts.functions.TargetArrow"),
	PLAYER = include("resources.scripts.functions.Player"),
	EDITH = include("resources.scripts.functions.Edith"),
	LAND = include("resources.scripts.functions.Land"),
	TEDITH = include("resources.scripts.functions.TEdith"),
	STATUS_EFFECTS = include("resources.scripts.functions.StatusEffects"),
	CREEPS = include("resources.scripts.functions.Creeps"),
	JUMP = include("resources.scripts.functions.Jump"),
	BIT_MASK = include("resources.scripts.functions.BitMask"),
	STOMP_UTILS = include("resources.scripts.functions.StompUtils"),
}

include("include")

local utils = mod.Enums.Utils
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(utils.Game:GetSeeds():GetStartSeed())
end)

local version = {
	1,
	8,
	3,
	""
}
local beta = false
EdithRebuilt.Version = "v" .. version[1].. "." .. version[2] .. "." .. version[3] .. version[4] .. (beta and "Beta" or "")

Isaac.DebugString("Edith Rebuilt " .. EdithRebuilt.Version .. " loaded correctly")
print("Edith Rebuilt " .. EdithRebuilt.Version .. " loaded correctly")

include("resources.scripts.compat.main")