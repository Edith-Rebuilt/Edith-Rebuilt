local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local tables = enums.Tables
local Player = mod.Modules.PLAYER
local variants = enums.EffectVariant
local ImGuiTables = tables.ImGuiTables
local callbacks = enums.Callbacks
local achievements = enums.Achievements
local RenderMenu = true
local SaveManager = mod.SaveManager
local pgd = enums.Utils.PGD
local data = mod.DataHolder.GetEntityData
local ImGuiMod = {}

---@class EdithData
---@field TargetDesign {Idx: integer	, Design: string}
---@field TargetColor table
---@field TargetLine boolean
---@field RGBMode boolean
---@field RGBSpeed number
---@field EnableExtraGore boolean
---@field EnableVestigeMode boolean
---@field DisableSaltGibs boolean
---@field StompSound number
---@field StompVolume number
---@field JumpCooldownSound number
---@field DropKey2Jump boolean
---@field TrainingMode boolean
---@field CustomStompDmgMult number
---@field DefensiveStompWindow integer
---@field CustomJumpButton Keyboard|integer
---@field SaltShakerSlot integer

---@class TEdithData
---@field ArrowDesign number
---@field ArrowColor table
---@field EnableHopdashTrail boolean
---@field TrailDesign number
---@field TrailColor table
---@field RGBMode boolean
---@field RGBSpeed number
---@field EnableParryFlash boolean
---@field ParryFlashColor {r: number, g: number, b: number, a: number}
---@field ParryFlashContrast number
---@field ParryFlashBrightness number
---@field EnableExtraGore boolean
---@field EnableGrudgeMode boolean
---@field DisableSaltGibs boolean
---@field HopSound number
---@field ParrySound number
---@field Volume number
---@field ParryCooldownSound number

---@class MiscData
---@field CustomActionKey Keyboard
---@field EnableShakescreen boolean

local function ResetUnlocks()
	for _, achievement in pairs(achievements) do
		Isaac.ExecuteCommand("lockachievement " .. tostring(achievement))
	end
end

local function isEdithUnlocked(tainted)
	local ach = tainted and achievements.ACHIEVEMENT_TAINTED_EDITH or achievements.ACHIEVEMENT_EDITH
	return pgd:Unlocked(ach)
end

local MainPrefix = "EdithRebuilt_"
local Prefixes = {
	Menu = MainPrefix .. "Menu_",
	Window = MainPrefix .. "Window_",
	TabBar = MainPrefix .. "TabBar_",
	Tab = MainPrefix .. "Tab_",
	Separator = MainPrefix .. "Separator_",
	ProgressBar = MainPrefix .. "ProgressBar_",
	Button = MainPrefix .. "Button_",
	Edith = {
		Visuals = MainPrefix .. "Edith_" .. "Visuals_",
		Sounds = MainPrefix .. "Edith_" .. "Sounds_" ,
		Gameplay = MainPrefix .. "Edith_" .. "Gameplay_",
	},
	TEdith = {
		Visuals = MainPrefix .. "Tainted_Edith_" .. "Visuals_",
		Sounds = MainPrefix .. "Tainted_Edith_" .. "Sounds_",
		Gameplay = MainPrefix .. "Tainted_Edith_" .. "Gameplay_",
	},
	Misc = {
		Input = MainPrefix .. "Misc_" .. "Input_",
		ResetData = MainPrefix .. "Misc_" .. "ResetData_",
		Misc = MainPrefix .. "Misc_" .. "Misc_",
	}
}

local elementTab = {}
local Elements = {
	Menu = {
		SubMenu = {
			Settings = Prefixes.Menu .. "Settings",
			Credits = Prefixes.Menu .. "Credits",
			Progress = Prefixes.Menu .. "Progress",
			Changelog = Prefixes.Menu .. "Changelog",
		},
		Windows = {
			Settings = Prefixes.Window .. "Settings",
			Credits = Prefixes.Window .. "Credits",
			Progress = Prefixes.Window .. "Progress",
			Changelog = Prefixes.Window .. "Changelog",
		},
		TabBars = {
			Settings = Prefixes.TabBar .. "Settings",
			Edith = Prefixes.TabBar .. "Edith",
			TEdith = Prefixes.TabBar .. "Tainted_Edith",
			Credits = Prefixes.TabBar .. "Credits",
			Changelog = Prefixes.TabBar .. "Changelog"
		},
		Tabs = {
			Edith = {
				Main = Prefixes.Tab .. "Edith_Main",
				Visuals = Prefixes.Tab .. "Edith_Visuals",
				Sounds = Prefixes.Tab .. "Edith_Sounds",
				Gameplay = Prefixes.Tab .. "Edith_Gameplay"
			},
			TEdith = {
				Main = Prefixes.Tab .. "Tainted_Edith_Main",
				Visuals = Prefixes.Tab .. "Tainted_Edith_Visuals",
				Sounds = Prefixes.Tab .. "Tainted_Edith_Sounds",
				Gameplay = Prefixes.Tab .. "TaintedEdith_Gameplay"
			},
			Misc = {
				Main = Prefixes.Tab .. "Misc_Main"
			},
			Credits = {
				Resources = Prefixes.Tab .. "Resources",
				Contributors = Prefixes.Tab .. "Contributors",
				Testers = Prefixes.Tab .. "Testers",
				Team = Prefixes.Tab .. "Team"
			},
		},
		Separator = {
			Edith = {
				Visuals = {
					Target = Prefixes.Separator .. "Edith_Visual_Target",
					RGB = Prefixes.Separator .. "Edith_Visual_RGB",
					Stomp = Prefixes.Separator .. "Edith_Visua_lStomp,"
				},
				Sounds = {
					Stomp = Prefixes.Separator .. "Edith_Sounds_Stomp",
					Cooldown = Prefixes.Separator .. "Edith_Sounds_Cooldown"
				},
				Gameplay = {
					Stomp = Prefixes.Separator .. "Edith_Gameplay_Misc",
					Salt_Shaker = Prefixes.Separator .. "Edith_Gameplay_Salt_Shaker",
					Vestige_Mode = Prefixes.Separator .. "Edith_Gameplay_Vestige_Mode",
				}
			},
			TEdith = {
				Visuals = {
					Arrow = Prefixes.Separator .. "Tainted_Edith_Visual_Arrow",
					Trail = Prefixes.Separator .. "Tainted_Edith_Visual_Trail",
					RGB = Prefixes.Separator .. "Tainted_Edith_Visual_RGB",
					HopParry = Prefixes.Separator .. "Tainted_Edith_Visual_HopParry",
					ParryFlash = Prefixes.Separator .. "Tainted_Edith_Visual_HopParry"
				},
				Sounds = {
					HopParry = Prefixes.Separator .. "Tainted_Edith_Sounds_HopParry",
					Cooldown = Prefixes.Separator .. "Tainted_Edith_Sounds_Cooldown"
				},
				-- I'll eventually add this
				Gameplay = {
					-- Inputs = Prefixes.Separator .. "TEdith_Gameplay_Inputs",
					-- Training = Prefixes.Separator .. "TEdith_GameplayTraining"
					Grudge_Mode = Prefixes.Separator .. "TEdith_Gameplay_Grudge_Mode"
				}
			},
			Misc = {
				Input = Prefixes.Separator .. "Misc_Input",
				ResetData = Prefixes.Separator .. "Misc_ResetData",
				Misc = Prefixes.Separator .. "Misc_Misc",
			},
		},
		ProgressBar = {
			Edith = Prefixes.ProgressBar .. "Edith",
			TEdith = Prefixes.ProgressBar .. "TEdith",
			General = Prefixes.ProgressBar .. "General"
		},
		Buttons = {
			ClearUnlocks = Prefixes.Button .. "ClearUnloocks",
			UnlockAll = Prefixes.Button .. "UnlockAll"
		}
	},
	Options = {
		Edith = {
		Visuals = {
			TargetDesign = Prefixes.Edith.Visuals .. "TargetDesign",
			TargetColor = Prefixes.Edith.Visuals .. "TargetColor",
			TargetLine = Prefixes.Edith.Visuals .. "TargetLine",
			SetRGBMode = Prefixes.Edith.Visuals .. "SetRGBMode",
			SetRGBSpeed = Prefixes.Edith.Visuals .. "SetRGBSpeed",
			EnableExtraGore = Prefixes.Edith.Visuals .. "EnableExtraGore",
			DisableSaltGibs = Prefixes.Edith.Visuals .. "DisableGibs",
		},
		Sounds = {
			SetStompSound = Prefixes.Edith.Sounds .. "SetStompSound",
			SetStompVolume = Prefixes.Edith.Sounds .. "SetStompVolume",
			SetJumpCooldownSound = Prefixes.Edith.Sounds .. "SetJumpCooldownSound",
		},
		Gameplay = {
			EnableDropKey2Jump = Prefixes.Edith.Gameplay .. "EnableDropKey2Jump",
			CustomJumpKey = Prefixes.Edith.Gameplay .. "CustomJumpKey",
			SaltShakerSlot = Prefixes.Edith.Gameplay .. "SaltShaker",
			EnableVestigeMode = Prefixes.Edith.Gameplay .. "EnableVestigeMode",
			-- EnableTrainingMode = Prefixes.Edith.Gameplay .. "EnableTrainingMode",
			DefensiveStompWindow = Prefixes.Edith.Gameplay .. "DefensiveStompWindow",
		}
	},
	TEdith = {
		Visuals = {
			ArrowDesign = Prefixes.TEdith.Visuals .. "ArrowDesign",
			ArrowColor = Prefixes.TEdith.Visuals .. "ArrowColor",
			EnableHopdashTrail = Prefixes.TEdith.Visuals .. "EnableHopdashTrail",
			TrailDesign = Prefixes.TEdith.Visuals .. "TrailDesign",
			TrailColor = Prefixes.TEdith.Visuals .. "TrailColor",
			SetRGBMode = Prefixes.TEdith.Visuals .. "SetRGBMode",
			SetRGBSpeed = Prefixes.TEdith.Visuals .. "SetRGBSpeed",
			EnableParryFlash = Prefixes.TEdith.Visuals .. "EnableParryFlash",
			ParryFlashColor = Prefixes.TEdith.Visuals .. "ParryFlashColor",
			ParryFlashContrast = Prefixes.TEdith.Visuals .. "ParryFlashContrast",
			ParryFlashBrightness = Prefixes.TEdith.Visuals .. "ParryFlashBrightness",
			EnableExtraGore = Prefixes.TEdith.Visuals .. "EnableExtraGore",
			DisableSaltGibs = Prefixes.TEdith.Visuals .. "DisableSaltGibs",
		},
		Sounds = {
			SetHopSound = Prefixes.TEdith.Sounds .. "SetHopSound",
			SetParrySound = Prefixes.TEdith.Sounds .. "SetParrySound",
			SetVolume = Prefixes.TEdith.Sounds .. "SetVolume",
			SetParryCooldownSound = Prefixes.TEdith.Sounds .. "SetParryCooldownSound",
		},
		Gameplay = {
			EnableGrudgeMode = Prefixes.TEdith.Sounds .. "EnableGrudgeMode",
		}
	},
	Misc = {
		CustomActionKey = Prefixes.Misc.Input .. "CustomActionKey",
		ResetEdithData = Prefixes.Misc.ResetData .. "ResetEdithData",
		ResetTEdithData = Prefixes.Misc.ResetData .. "ResetTaintedEdithData",
		EnableShakescreen = Prefixes.Misc.Misc .. "EnableShakescreen",
	}
	}
}

local Menu = Elements.Menu
local Options = Elements.Options

if not ImGui.ElementExists("EdithRebuilt") then
	if RenderMenu == false then return end
    ImGui.CreateMenu('EdithRebuilt', '🧂 Edith: Rebuilt')
end

local function AddMenuElement(name, title)
	if RenderMenu == false and ImGui.ElementExists(name) then return end
    ImGui.AddElement("EdithRebuilt", name, ImGuiElement.MenuItem, "\u{f013} " .. title)
end

local MenuElements = {
    { name = Menu.SubMenu.Settings, title = "Settings" },
    { name = Menu.SubMenu.Credits, title = "Credits" },
    { name = Menu.SubMenu.Progress, title = "Progress" },
    { name = Menu.SubMenu.Changelog, title = "Changelog" }
}

for _, Menu in ipairs(MenuElements) do
    AddMenuElement(Menu.name, Menu.title)
end

local windows = {
    { name = Menu.Windows.Settings, title = "Settings" },
    { name = Menu.Windows.Credits, title = "Credits" },
	{ name = Menu.Windows.Progress, title = "Progress"},
	{ name = Menu.Windows.Changelog, title = "Changelog"},
}

for _, window in ipairs(windows) do
	if RenderMenu == false and ImGui.ElementExists(window.name) then return end
    ImGui.CreateWindow(window.name, window.title)
end

local links = {
	{ window = Menu.Windows.Settings, menu = Menu.SubMenu.Settings },
	{ window = Menu.Windows.Credits, menu = Menu.SubMenu.Credits },
	{ window = Menu.Windows.Progress, menu = Menu.SubMenu.Progress },
	{ window = Menu.Windows.Changelog, menu = Menu.SubMenu.Changelog },
}

for _, link in ipairs(links) do
	ImGui.LinkWindowToElement(link.window, link.menu)
end

local function UpdateImGuiData()
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end

	local EdithData = saveData.EdithData ---@cast EdithData EdithData
	local TEdithData = saveData.TEdithData ---@cast TEdithData TEdithData
	local MiscData = saveData.MiscData ---@cast MiscData MiscData
	local Options = Elements.Options
	local EdithOptions = Options.Edith
	local TEdithOptions = Options.TEdith
	local MiscOptions = Options.Misc

	local optionsData = {}

	if isEdithUnlocked(false) then
		local edithData = {
			[MiscOptions.CustomActionKey] = MiscData.CustomActionKey or Keyboard.KEY_Z,
			[MiscOptions.EnableShakescreen] = MiscData.EnableShakescreen or false,

			[EdithOptions.Visuals.TargetDesign] = (EdithData.TargetDesign.Idx - 1) or 0,
			[EdithOptions.Visuals.TargetLine] = EdithData.TargetLine or false,
			[EdithOptions.Visuals.SetRGBMode] = EdithData.RGBMode or false,
			[EdithOptions.Visuals.SetRGBSpeed] = EdithData.RGBSpeed or 0.005,
			[EdithOptions.Visuals.EnableExtraGore] = EdithData.EnableExtraGore or false,
			[EdithOptions.Visuals.DisableSaltGibs] = EdithData.DisableSaltGibs or false,
			[EdithOptions.Sounds.SetStompSound] = (EdithData.StompSound - 1) or 0,
			[EdithOptions.Sounds.SetStompVolume] = EdithData.StompVolume or 100,
			[EdithOptions.Sounds.SetJumpCooldownSound] = (EdithData.JumpCooldownSound - 1) or 0,
			[EdithOptions.Gameplay.DefensiveStompWindow] = EdithData.DefensiveStompWindow or 18,
			[EdithOptions.Gameplay.SaltShakerSlot] = EdithData.SaltShakerSlot or 0,
			[EdithOptions.Gameplay.EnableVestigeMode] = EdithData.EnableVestigeMode or false,
		}

		for k, v in pairs(edithData) do
			optionsData[k] = v
		end

		local targetColor = EdithData.TargetColor

		if ImGui.ElementExists(EdithOptions.Visuals.TargetColor) then
			ImGui.UpdateData(EdithOptions.Visuals.TargetColor, ImGuiData.ColorValues,
			{
				targetColor.Red,
				targetColor.Green,
				targetColor.Blue,
			})
		end
	end

	if isEdithUnlocked(true) then
		local taintedData = {
			[TEdithOptions.Visuals.ArrowDesign] = (TEdithData.ArrowDesign - 1) or 0,
			[TEdithOptions.Visuals.EnableHopdashTrail] = TEdithData.EnableHopdashTrail or false,
			[TEdithOptions.Visuals.TrailDesign] = (TEdithData.TrailDesign - 1) or 0,
			[TEdithOptions.Visuals.SetRGBMode] = TEdithData.RGBMode or false,
			[TEdithOptions.Visuals.SetRGBSpeed] = TEdithData.RGBSpeed or 0.005,
			[TEdithOptions.Visuals.EnableExtraGore] = TEdithData.EnableExtraGore or false,
			[TEdithOptions.Visuals.DisableSaltGibs] = TEdithData.DisableSaltGibs or false,
			[TEdithOptions.Visuals.EnableParryFlash] = TEdithData.EnableParryFlash or false,
			[TEdithOptions.Visuals.ParryFlashContrast] = TEdithData.ParryFlashContrast or 0.4,
			[TEdithOptions.Visuals.ParryFlashBrightness] = TEdithData.ParryFlashBrightness or 0.4,
			[TEdithOptions.Sounds.SetHopSound] = (TEdithData.HopSound - 1) or 0,
			[TEdithOptions.Sounds.SetParrySound] = (TEdithData.ParrySound - 1) or 0,
			[TEdithOptions.Sounds.SetVolume] = TEdithData.Volume or 100,
			[TEdithOptions.Gameplay.EnableGrudgeMode] = TEdithData.EnableGrudgeMode or false
		}

		for k, v in pairs(taintedData) do
			optionsData[k] = v
		end

		local arrowcolor = TEdithData.ArrowColor
		local trailColor = TEdithData.TrailColor
		local ParryFlashColor = TEdithData.ParryFlashColor

		if ImGui.ElementExists(TEdithOptions.Visuals.ArrowColor) then
			ImGui.UpdateData(TEdithOptions.Visuals.ArrowColor, ImGuiData.ColorValues,
			{
				arrowcolor.Red,
				arrowcolor.Green,
				arrowcolor.Blue,
			})
		end

		if ImGui.ElementExists(TEdithOptions.Visuals.TrailColor) then
			ImGui.UpdateData(TEdithOptions.Visuals.TrailColor, ImGuiData.ColorValues,
			{
				trailColor.Red,
				trailColor.Green,
				trailColor.Blue,

			})
		end

		if ImGui.ElementExists(TEdithOptions.Visuals.ParryFlashColor) then
			ImGui.UpdateData(TEdithOptions.Visuals.ParryFlashColor, ImGuiData.ColorValues,
			{
				ParryFlashColor.r,
				ParryFlashColor.g,
				ParryFlashColor.b,
				ParryFlashColor.a,
			})
		end
	end

	for option, newValue in pairs(optionsData) do
		if ImGui.ElementExists(option) then
			ImGui.UpdateData(option, ImGuiData.Value, newValue)
		end
	end

	if ImGui.ElementExists(MiscOptions.CustomActionKey) then
		ImGui.UpdateData(MiscOptions.CustomActionKey, ImGuiData.Value, MiscData.CustomActionKey or Keyboard.KEY_Z)
	end
end

local function ResetSaveData(isTainted)
	local menuData = SaveManager.GetSettingsSave()
	if not menuData then return end

	local EdithData = menuData.EdithData ---@cast EdithData EdithData
	local TEdithData = menuData.TEdithData ---@cast TEdithData TEdithData

	if isTainted then
		TEdithData.ArrowColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.TrailColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.ArrowDesign = 1
		TEdithData.HopSound = 1
		TEdithData.Volume = 100
		TEdithData.ParrySound = 1
		TEdithData.RGBMode = false
		TEdithData.EnableExtraGore = false
		TEdithData.RGBSpeed = 0.005
		TEdithData.TrailDesign = 1
		TEdithData.ParryFlashColor = {r = 1, g = 1, b = 1, a = 1}
		TEdithData.ParryFlashBrightness = 1
		TEdithData.ParryFlashContrast = 0.4
		TEdithData.EnableGrudgeMode = false
	else
		EdithData.TargetColor = {Red = 1, Green = 1, Blue = 1}
		EdithData.StompSound = 1
		EdithData.StompVolume = 100
		EdithData.EnableExtraGore = false
		EdithData.TargetDesign = {Idx = 1, Design = ""}
		EdithData.DisableSaltGibs = false
		EdithData.RGBMode = false
		EdithData.RGBSpeed = 0.005
		EdithData.TargetLine = false
		EdithData.JumpCooldownSound = 1
		EdithData.DefensiveStompWindow = 18
		EdithData.SaltShakerSlot = 0
		EdithData.EnableVestigeMode = false
	end

	UpdateImGuiData()

	RenderMenu = true
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	UpdateImGuiData()
end)

---@param tabla table
---@param prefijo? string
local function recorrerTablaImGui(tabla, prefijo)
    prefijo = prefijo or ""
    for clave, valor in pairs(tabla) do
        if type(valor) == "table" then
            recorrerTablaImGui(valor, prefijo .. clave .. ".")
        else
			if not ImGui.ElementExists(valor) then
				if not string.find(valor, "Tainted") then
					elementTab[clave] = valor
				end
			end
        end
    end
end

recorrerTablaImGui(Elements)
local function CheckImGuiIntegrity()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then return false end
	end
	return true
end

local function AddTabBars()
	if not isEdithUnlocked(false) then return end

	ImGui.AddTabBar(Elements.Menu.Windows.Settings, Elements.Menu.TabBars.Settings)
	ImGui.AddTab(Elements.Menu.TabBars.Settings, Elements.Menu.Tabs.Edith.Main, "Edith")

	if isEdithUnlocked(true) then
		ImGui.AddTab(Elements.Menu.TabBars.Settings, Elements.Menu.Tabs.TEdith.Main, "Tainted Edith")
	end

	ImGui.AddTab(Elements.Menu.TabBars.Settings, Elements.Menu.Tabs.Misc.Main, "Misc")
end

local function AddEdithOptions()
	if not isEdithUnlocked(false) then return end

	local EdithTabBar = Menu.TabBars.Edith
	local EdithTab = Menu.Tabs.Edith.Main
	local EdithVisuals = Menu.Tabs.Edith.Visuals
	local EdithSounds = Menu.Tabs.Edith.Sounds
	local EdithGameplay = Menu.Tabs.Edith.Gameplay
	local OptionVisuals = Options.Edith.Visuals
	local OptionSounds = Options.Edith.Sounds
	local OptionGameplay = Options.Edith.Gameplay
	local Separator = Menu.Separator.Edith
	local EdithData = SaveManager:GetSettingsSave().EdithData --[[@as EdithData]]

	ImGui.AddTabBar(EdithTab, EdithTabBar)
	ImGui.AddTab(EdithTabBar, EdithVisuals, "Visuals")
	ImGui.AddTab(EdithTabBar, EdithSounds, "Sounds")
	ImGui.AddTab(EdithTabBar, EdithGameplay, "Gameplay")

-- Visuals
	ImGui.AddElement(EdithVisuals, Separator.Visuals.Target, ImGuiElement.SeparatorText, "Target")
	ImGui.AddCombobox(EdithVisuals, OptionVisuals.TargetDesign, "Set Target Design",
		function(index, option)
			EdithData.TargetDesign.Idx = index + 1
			EdithData.TargetDesign.Design = option
			for _, target in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, target)
			end
		end,
	ImGuiTables.TargetDesign, 0, false)

	ImGui.AddInputColor(EdithVisuals, OptionVisuals.TargetColor, "Target Color",
		function(r, g, b)
			EdithData.TargetColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)
	ImGui.SetHelpmarker(OptionVisuals.TargetColor, "Only works when target design is set to Choose Color")
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.TargetLine, "Enable Target line",
		function(check)
			EdithData.TargetLine = check
		end,
	false)

	ImGui.AddElement(EdithVisuals, Separator.Visuals.RGB, ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.SetRGBMode, "Set RGB Mode",
		function(check)
			EdithData.RGBMode = check
		end,
	false)
	ImGui.SetHelpmarker(OptionVisuals.SetRGBMode, "Makes the target cycle between colors \nOnly works when target design is set to Choose Color")

	ImGui.AddSliderFloat(EdithVisuals, OptionVisuals.SetRGBSpeed, "Set RGB Speed",
		function(val)
			EdithData.RGBSpeed = val
		end,
	0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement(EdithVisuals, Separator.Visuals.Stomp, ImGuiElement.SeparatorText, "Stomp")

	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.EnableExtraGore, "Enable stomp kill extra gore",
		function(check)
			EdithData.EnableExtraGore = check
		end,
	false)
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.DisableSaltGibs, "Disable salt gibs",
		function(check)
			EdithData.DisableSaltGibs = check
		end,
	false)
-- Visuals end

-- Sounds
	ImGui.AddElement(EdithSounds, Separator.Sounds.Stomp, ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddCombobox(EdithSounds, OptionSounds.SetStompSound, "Set Stomp Sound",
		function(index)
			EdithData.StompSound = index + 1
		end,
	ImGuiTables.StompSound, 0)
	ImGui.AddSliderInteger(EdithSounds, OptionSounds.SetStompVolume, "Set stomp volume",
		function(index)
			EdithData.StompVolume = index
		end,
	100, 25, 100, "%d%")

	ImGui.AddElement(EdithSounds, Separator.Sounds.Cooldown, ImGuiElement.SeparatorText, "Cooldown")
	ImGui.AddCombobox(EdithSounds, OptionSounds.SetJumpCooldownSound, "Set jump cooldown sound",
		function(index)
			EdithData.JumpCooldownSound = index + 1
		end,
	{"Stone", "Beep"}, 0, true)
-- Sounds end

-- Gameplay
	ImGui.AddElement(EdithGameplay, Separator.Gameplay.Stomp, ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddSliderInteger(EdithGameplay, OptionGameplay.DefensiveStompWindow, "Change Edith's defensive stomp window",
		function(val)
			EdithData.DefensiveStompWindow = val
		end,
	18, 5, 25)

	ImGui.AddElement(EdithGameplay, Separator.Gameplay.Salt_Shaker, ImGuiElement.SeparatorText, "Salt Shaker")
	ImGui.AddCombobox(EdithGameplay, OptionGameplay.SaltShakerSlot, "Salt Shaker's slot",
		function(option)
			EdithData.SaltShakerSlot = option
		end
	, {"Main" , "Pocket"}, EdithData.SaltShakerSlot or 0, true)

	ImGui.SetHelpmarker(OptionGameplay.SaltShakerSlot, "\u{21} This will only work  a new run")

	if pgd:Unlocked(achievements.ACHIEVEMENT_EFFIGY) then
		ImGui.AddElement(EdithGameplay, Separator.Gameplay.Vestige_Mode, ImGuiElement.SeparatorText, "Vestige Mode")

		ImGui.AddCheckbox(EdithGameplay, OptionGameplay.EnableVestigeMode, "Enable Vestige Mode",
			function(check)
				EdithData.EnableVestigeMode = check

				local hoodPath = check and misc.VestigeHoodPath or misc.EdithHoodPath

				for _, player in ipairs(PlayerManager.GetPlayers()) do
					if not Player.IsEdith(player, false) then goto continue end

					if check == true then
						Player.SetChallengeSprite(player, enums.Challenge.CHALLENGE_VESTIGE)
					else
						Player.ResetPlayerSprite(player)
					end

					Player.SetHoodSprite(player, hoodPath)
					::continue::
				end
			end,
		false)
		ImGui.SetHelpmarker(OptionGameplay.EnableVestigeMode, "Change Edith gameplay to be the same as the Vestige challenge")
	end
-- Gameplay end
end

local function AddTaintedEdithOptions()
	if not isEdithUnlocked(true) then return end

	local TEdithTabBar = Menu.TabBars.TEdith
	local TEdithTab = Menu.Tabs.TEdith.Main
	local TEdithVisuals = Menu.Tabs.TEdith.Visuals
	local TEdithSounds = Menu.Tabs.TEdith.Sounds
	local TEdithGameplay = Menu.Tabs.TEdith.Gameplay
	local OptionVisuals = Options.TEdith.Visuals
	local OptionSounds = Options.TEdith.Sounds
	local OptionGameplay = Options.TEdith.Gameplay
	local Separator = Menu.Separator.TEdith
	local TEdithData = SaveManager:GetSettingsSave().TEdithData --[[@as TEdithData]]

	ImGui.AddTabBar(TEdithTab, TEdithTabBar)
	ImGui.AddTab(TEdithTabBar, TEdithVisuals, "Visuals")
	ImGui.AddTab(TEdithTabBar, TEdithSounds, "Sounds")

-- Visuals
	ImGui.AddElement(TEdithVisuals, Separator.Visuals.Arrow, ImGuiElement.SeparatorText, "Arrow")
	ImGui.AddCombobox(TEdithVisuals, OptionVisuals.ArrowDesign, "Set Arrow Design",
		function(index)
			TEdithData.ArrowDesign = index + 1
			for _, arrow in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_B_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, arrow)
			end
		end,
	ImGuiTables.ArrowDesign, 0)
	ImGui.AddInputColor(TEdithVisuals, OptionVisuals.ArrowColor, "Arror Color",
		function(r, g, b)
			TEdithData.ArrowColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.Trail, ImGuiElement.SeparatorText, "Trail")
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.EnableHopdashTrail, "Enable hopdash trail",
		function(check)
			TEdithData.EnableHopdashTrail = check
		end,
	false)
	ImGui.AddCombobox(TEdithVisuals, OptionVisuals.TrailDesign, "Set Target Design",
		function(index)
			TEdithData.TrailDesign = index + 1
			for _, trail in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL)) do
				if not data(trail).EdithRebuilTrail then return end
				Isaac.RunCallback(callbacks.TRAIL_SPRITE_CHANGE, trail)
			end
		end,
	ImGuiTables.TrailDesign, 0, false)
	ImGui.AddInputColor(TEdithVisuals, OptionVisuals.TrailColor, "Trail Color",
		function(r, g, b)
			TEdithData.TrailColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.RGB, ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.SetRGBMode, "Set RGB Mode",
	function(check)
		TEdithData.RGBMode = check
	end, false)
	ImGui.AddSliderFloat(TEdithVisuals, OptionVisuals.SetRGBSpeed, "Set RGB Speed",
		function(index)
			TEdithData.RGBSpeed = index
		end,
	0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.HopParry, ImGuiElement.SeparatorText, "Hop & Parry")

	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.EnableExtraGore, "Enable parry kill extra gore",
		function(check)
			TEdithData.EnableExtraGore = check
		end,
	false)
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.DisableSaltGibs, "Disable salt gibs",
		function(check)
			TEdithData.DisableSaltGibs = check
		end,
	false)

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.ParryFlash, ImGuiElement.SeparatorText, "Parry Flash")

	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.EnableParryFlash, "Enable Parry Flash",
		function(check)
			TEdithData.EnableParryFlash = check
		end,
	false)

---@diagnostic disable-next-line: redundant-parameter
	ImGui.AddInputColor(TEdithVisuals, OptionVisuals.ParryFlashColor, "Parry Flash Color", function (r, g, b, a)
		TEdithData.ParryFlashColor = {
			r = r,
			g = g,
			b = b,
			a = a,
		}
	end, 1, 1, 1, 1)

	ImGui.AddSliderFloat(TEdithVisuals, OptionVisuals.ParryFlashBrightness, "Parry Flash Brightness",
		function(val)
			TEdithData.ParryFlashBrightness = val
		end, 0.4, 0, 1
	)

	ImGui.AddSliderFloat(TEdithVisuals, OptionVisuals.ParryFlashContrast, "Parry Flash Contrast",
		function(val)
			TEdithData.ParryFlashContrast = val
		end, 0.4, 0, 1
	)

-- Visuals end

-- Sounds
	ImGui.AddElement(TEdithSounds, Separator.Sounds.HopParry, ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCombobox(TEdithSounds, OptionSounds.SetHopSound, "Set Hop Sound",
		function(index)
			TEdithData.HopSound = index + 1
		end,
	ImGuiTables.HopSound, 0)
	ImGui.AddCombobox(TEdithSounds, OptionSounds.SetParrySound, "Set Parry Sound",
		function(index)
			TEdithData.ParrySound = index + 1
		end,
	ImGuiTables.ParrySound, 0)
	ImGui.AddSliderInteger(TEdithSounds, OptionSounds.SetVolume, "Set stomp volume",
		function(index)
			TEdithData.Volume = index
		end,
	100, 25, 100, "%d%")

	ImGui.AddElement(TEdithSounds, Separator.Sounds.Cooldown, ImGuiElement.SeparatorText, "Cooldown")
	ImGui.AddCombobox(TEdithSounds, OptionSounds.SetParryCooldownSound, "Set parry cooldown sound",
		function(index)
			TEdithData.ParryCooldownSound = index + 1
		end,
	{"Stone", "Beep"}, 0, true)
-- Sounds end

-- Gameplay
	if pgd:Unlocked(achievements.ACHIEVEMENT_CHUNK_OF_BASALT) then
		ImGui.AddTab(TEdithTabBar, TEdithGameplay, "Gameplay")

		ImGui.AddElement(TEdithGameplay, Separator.Gameplay.Grudge_Mode, ImGuiElement.SeparatorText, "Grudge Mode")
		ImGui.AddCheckbox(TEdithGameplay, OptionGameplay.EnableGrudgeMode, "Enable Grudge Mode",
			function(check)
				TEdithData.EnableGrudgeMode = check

				local hoodPath = check and misc.GrudgeHoodPath or misc.TEdithHoodPath

				for _, player in ipairs(PlayerManager.GetPlayers()) do
					if not Player.IsEdith(player, true) then goto continue end

					if check == true then
						Player.SetChallengeSprite(player, enums.Challenge.CHALLENGE_GRUDGE)
					else
						Player.ResetPlayerSprite(player)
					end

					Player.SetHoodSprite(player, hoodPath)
					::continue::
				end
			end,
		false)
		ImGui.SetHelpmarker(OptionGameplay.EnableGrudgeMode, "Change Tainted Edith gameplay to be the same as the Grudge challenge")
	end
-- Gameplay end
end

local function AddMiscOptions()
	if not isEdithUnlocked(false) then return end

	local MiscTab = Menu.Tabs.Misc.Main
	local MiscOptions = Options.Misc
	local Separator = Menu.Separator.Misc
	local MiscData = SaveManager:GetSettingsSave().MiscData --[[@as MiscData]]

	ImGui.AddElement(MiscTab, Separator.Input, ImGuiElement.SeparatorText, "Inputs")

	ImGui.AddInputKeyboard(MiscTab, MiscOptions.CustomActionKey, "Set custom action key",
		function(ID)
			MiscData.CustomActionKey = ID
		end,
	Keyboard.KEY_Z)

	ImGui.AddElement(MiscTab, Separator.ResetData, ImGuiElement.SeparatorText, "Reset Data")
	ImGui.AddButton(MiscTab, MiscOptions.ResetEdithData, "Reset Edith Settings",
		function()
			ResetSaveData(false)
		end,
	true)
	if isEdithUnlocked(true) then
		ImGui.AddButton(MiscTab, MiscOptions.ResetTEdithData, "Reset Tainted Edith Settings",
			function()
				ResetSaveData(true)
			end,
		true)
	end
	ImGui.AddElement(MiscTab, Separator.Misc, ImGuiElement.SeparatorText, "Misc")
	ImGui.AddCheckbox(MiscTab, MiscOptions.EnableShakescreen, "Enable Stomp screen shake",
		function(check)
			MiscData.EnableShakescreen = check
		end,
	false)
end

local function AddContributors()
	local CreditsTabBar = Menu.TabBars.Credits
	local CreditsTabs = Menu.Tabs.Credits

	ImGui.AddTabBar(Menu.Windows.Credits, CreditsTabBar)
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Resources, "Resources")
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Contributors, "Contributors")
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Testers, "Testers")
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Team, "Team")

	ImGui.AddText(CreditsTabs.Resources,
	[[
	Used resources and utilities:

	- JumpLib (Kerkel)
	- Custom Shockwave API (Brakedude)
	- Pre NPC kill callback (Kerkel)
	- Isaac Save Manager (Catinsurance, Benny)
	- HudHelper (Benny, CatWizard)
	- Status Effect Library (Benny)
	- SaveData System (AgentCucco)
	- lhsx (Ilya Kolbin (iskolbin))
	- Salt Shaker Sound Effect (Joshua Hadley):
	- Edith water stomp sound effect (ArtNinja)
	- Nine Sols Perfect Parry sound effect (Red Candle Games)
	- Pizza Tower taunt sound effect (Tour De Pizza)
	- Ultrakill parry sound effect (New Blood, Arsi "Hakita" Patala)
	- Hollow Knight parry sound effect (Team Cherry)
	- Iconoclasts parry sound effect (Joakim Sandberg (Konjak))
	]],
	true)

	ImGui.AddText(CreditsTabs.Contributors,
	[[
	Contributors:

	- JJ: Inspiration to start this project
	- D!Edith team: Inspiration to resume this project
	- Skulldier: Sal concept
	- Marcy: Tainted Edith Birthright idea
	- Sr Kalaka: Edith Sprite
	- Yuls: Tainted Edith sprite base
	]],
	true)

	ImGui.AddText(CreditsTabs.Testers,
	[[
	Testers:

	- ottostrasse
	- Jozin191
	- Tibu
	- SethoJunk
	- Noirsight
	- Sylvy_owo
	- .radiox
	- Edith's No.1 Fan
	- Beth-Null
	]],
	true)

	ImGui.AddText(CreditsTabs.Team,
	[[
	Team:

	- gigamouse: finished Tainted Edith sprite, items sprites
	- Pattowolfx220: Testing, First Tainted Edith sprite, items sprites
	- River Moondrop (HOLA RIVERIO): Costumes sprites
	- Kotry: Project leader, coder, unlock sheets sprites
	]],
	true)
end

local function AddProgressBars()
	if not isEdithUnlocked(false) then return end

	local window = Menu.Windows
	local button = Menu.Buttons
	local progress = window.Progress
	local bars = Menu.ProgressBar

	ImGui.AddProgressBar(progress, bars.General, "General unlocks progress", 0)
	ImGui.AddProgressBar(progress, bars.Edith, "Edith unlocks progress", 0)

	if isEdithUnlocked(true) then
		ImGui.AddProgressBar(progress, bars.TEdith, "Tainted Edith unlocks progress", 0)
	end

	ImGui.AddButton(progress, button.ClearUnlocks, "Clear Unlocks", function ()
		ResetUnlocks()
	end)

	ImGui.AddButton(progress, button.UnlockAll, "Unlock All", function ()
		for _, achievement in ipairs(achievements) do
			pgd:TryUnlock(achievement, true)
		end
	end)
end

local function AddChangelogs()
	local ChangelogTab = Menu.TabBars.Changelog

	ImGui.AddTabBar(Menu.Windows.Changelog, ChangelogTab)

	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.0", "v1.0")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.1", "v1.1")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.2", "v1.2")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.3", "v1.3")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.4", "v1.4")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.5", "v1.5")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.6", "v1.6")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.7", "v1.7")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.8", "v1.8")
	ImGui.AddTab(ChangelogTab, "EdithRebuilt_v1.9", "v1.9")

	ImGui.AddText("EdithRebuilt_v1.0", [[
v1.0.0
- Initial Release

v1.0.1
- Fixed Tainted Edith's projectile parry not working at all
- Potentially fixed an error that doesn't trigger effect room transition (needs more testing)
- Now Edith won't take damage when pitfalling
- Now Tainted Edith has a chance to spawn Cinder creep when hop-landing (only at 100%)
- Now Edith can correctly interact with beggars and slots

v1.0.2
- Removed a leftover console print when stomping slots and beggars
- Fixed Edith's Marked interactions
- Fixed Edith's lump of coal interaction not working at all
- Now T.Edith's arrow will always have grudge design when playing Grudge challenge
- Now all stomp and parry synergies' functions are anonymous functions 
- Fixed Edith shooting godhead stomp tears
- Second attempt to fix Target doors issue (hopefully it works now)
]], true)

	ImGui.AddText("EdithRebuilt_v1.1", [[
v1.1.0 *Recrystallization update*
- Reimplemented mod's data structure (big change that justified going to 1.1.0)
- (Hopefully) Fixed a rare and hard to reproduce error where Tainted Edith was unable to spawn her arrow 
- Now Tainted Edith's hop-parry params are properly reset when starting a new run
- Now Edith's jump-stomp params are properly reset when starting a new run
- Fixed Edith triggering beggars and donation machines everytime
- Fixed Edith not getting damage when stomping devil beggars and blood donation machines
- Fixed a potential error regarding Tainted Edith trying to hop at nil charge
- Now target door manager will let you go trough open doors in uncleared rooms
- Fixed Edith being unable to go to black markets
- Fixed Edith going to error room in Rotgut's maggot phase 
]], true)

	ImGui.AddText("EdithRebuilt_v1.2", [[
v1.2.0 *Future Memories update*
- Fixed Salt rocks not triggering salted effect to enemies
- Fixed Edith not being able to go to void trough Mega Satan's portal
- Fixed bomb stomp consuming bombs when having dr fetus or epic fetus
- Fixed Salt creep being able to use a nil value to asign salted effect duration
- Fixed Edith being unable to play on Confessionals
- Fixed Tainted Edith's body dissapearing when having flight
- Fixed Edith's Hood not triggering its Landing effect
- Fixed Edith being unable to trigger enemy waves in challenge rooms when stomping stone chests
- Added The Future support
- Added EID support
- Added ingame changelogs
- Increased Edith's defensive stomp window frames (9 > 15)
- Now Defensive stomp frame window can be configured in ImGui Menu 
- Now Pepper creep wont spawn far away from peppered entity
- Now Tainted Edith can consistently interact with blood donation machines, devil beggars and confessionals
- Removed a unused item entry
- Removed leftover prints
]], true)

	ImGui.AddText("EdithRebuilt_v1.3", [[
v1.3.0 *Salt Refinement update Part I*
- Fixed Edith and Tainted Edith losing their costumes when using D4 or D100
- Fixed Edith getting damage from blood donation machines, devil beggars and confessionals when they're destroyed
- Fixed Edith being unable to go to womb, corpse, blue womb, and such
- Fixed Edith not moving to her target when loading the mod with luamod console command
- Fixed an issue were ImGui options weren't properly updated
- Fixed Tainted Edith not unlocking her Greedier unlock
- Improved Edith's grid teleporter interaction
- Removed a trailing char in items.xml
- Removed Gnawed Leaf and Night Light from item pools when playing with Edith
- Properly added Spices Mix unlock
- Now Edith can't use Kamikaze while jumping
- Now players who doesn't have Salt Heart won't get salted status effect
- Now Tainted Edith can hopdsah if the charge is below 10%
- Now custom action key from ImGui's menu works
-- Now it allows to set a custom action button rather than Z
- Now Edith's Salt Shaker can be a pocket active (option added to Imgui Menu)
- Now Tainted Edith's trail options works
- Reworked Multishot stomp synergy
-- Now Edith will jump once, but stomp will deal damage multiple times
-- Increased Stomp's damage reduction from multishot
-- Enemy's damaged sound effect's volume will be higher the more times is dealt damage
]], true)

	ImGui.AddText("EdithRebuilt_v1.4", [[
v1.4.0 *Salt Refinement update Part II*
- Fixed Edith being unable to go Mother's fight
- Fixed Edith's target teleporting Edith to specific points when going trough them in best fight
- Fixed Tainted Edith unlocks in general (im really sorry for that)
- Fixed Costumes not working at all
- Fixed an issue with Helpers.BoostTear()
- Fixed a softlock in rotgut's second phase
- Fixed Grudge Tainted Edith not being able to dash when colliding with a wall
- Added Jupiter's stomp synergy
- Added Jupiter's perfect parry synergy
- Removed Montezuma's Revenge from pools when playing with Edith
- Removed an already unused test from Data Holder script
- Now massive enemies can be pushed
- Now blood clots will follow Edith when she jumps
]], true)

	ImGui.AddText("EdithRebuilt_v1.5", [[
v1.5.0 *Cinder Parries update*
- Tainted Edith rework:
-- Increased Perfect Parry radius (12 > 18)
-- Increased Imprecise Parry radius (35 > 45)
-- Increased Parry Jump speed (now it lands faster)
-- Added an specific parry radius for tear parry, making tear parry easier
-- Reduced Tainted Edith's hopdash and grudgedash speed base (hopdash: 10 > 8, grudgedash: 12 > 9)
-- Now Edith can break rocks at a hop/grudgedash of 85% or more 
-- Now there's a 8 frames cooldown for tainted edith's hop (and grudge dash)
-- Changed how hop cinder creep is spawned
--- Now its spawn chance depends on hop charge (50% chance at 100% charge)
--- Now the creep quantity depends on hop charge (8 at 100%)
--- Now the distance spawn depends on hop charge (30 units at 100%)
- Fixed all kind entities getting burn effect when Tainted Edith with birthright lands near them
- Potentially fixed Edith and Tainted Edith being unable to interact with spikes in devil rooms
- Fixed Tainted Edith getting pickup duplicates
- Reimplemented Stomped enemies jump recoil
-- This should fix that weird issue where enemies suddenly losing their AI

v1.5.1
- Fixed non-enemy entities setting on fire from T. Edith's hop lands with birthright
- Fixed T.Edith not stoping her hops when colliding with a block
- Fixed T.Edith not breaking rocks when having flight
- Fixed T.Edith's chargebars not rendering correctly in mirror dimension
- Fixed T.Edith constantly overriding her color while moving her arrow to a closed door
- Now Tainted Edith's hop cooldown won't restart on entering a new room
- Now Landing from a dash change direction will trigger a hop land interaction
- Now Tained Edith can destroy TNT with her hopdash
- Included T.Edith's jupiter Synergy's  script
- Added T.Edith's multishot parry synergy
-- Works exactly the same as Edith's multishot stomp synergy
]], true)

	ImGui.AddText("EdithRebuilt_v1.6", [[
v1.6.0 *High-Quality Salt update*
- Fixed T.Edith's arrow's grudge design changing its rotation
- Fixed T. Edith's grudge's dash not dealing damage consistently
- Fixed Edith's stomp neptunus synergy not working at all
- Fixed Tainted Edith not interacting correctly with white fireplaces
- Potentially fixed Edith's arrow moving the camera in Beast fight
- Potentially fixed T. Edith's grudge collision with enemies being weird
- Added more checks to T.Edith's Stop hops function
- Added Edith's special land radius for Slots and Pickups
- Added T. Edith's special land radius for Slots and Pickups
- Added Lost contact stomp synergy
- Added Bird's Eye/Ghost Pepper's parry/stomp synergy
- Added Little Horn's parry/stomp synergy
- Improved Edith's flight interaction
- Improved costumes system
- Improved Edith's stomp grid destruction
- Increased Edith's defensive stomp frames window (15 > 18)
- Salted enemy's death effect nullification will only happen when killing with a stomp
- Salted enemy's death effect nullification will only happen with non-boss enemies
- Now Edith will be less pushed by water currents
- Now Edith will only swap active slots when jumping
- Now Edith can drop trinkets when pressing the drop button in jump cooldown
- Now Tainted Edith can destroy fireplaces in Grudge challenge
- Now T. Edith's grudge dash screenshake can be disabled with screenshake option form ImGui Menu
- Now T.Edith parry will apply jump recoil to enemies
- Now Edith/T.Edith can destroy movable TNT
- Spices Mix changes: 
-- Now Spices Mix has a cooldown (5 seconds)
-- Added a flavor text for everytime the Spices Mix is used
--- This flavor text has the name of the spice and its effect in enemies
- Tainted Edith mini-rework:
-- Now Cinder enemies will receive x1.2 times more damage from parries
-- Removed Cinder creep applying cinder status effect
-- T. Edith won't spawn cinder creep on Hop land
-- T. Edith hop land now applies cinder status effect (max 4 seconds, depends on HopDash move charge)
-- Imprecise Parry cinder status effects duration has a max duration of 12 seconds

v1.6.1
- Fixed Geode not triggering its killing enemy effect
- Fixed Soul of Edith not working at all
- Replaced Divine Wrath's sprite
- Now salted enemies drop salt gibs on death
- Now Mod's data holder's clear data function should run earlier
- Improved Chocolate Milk stomp/parry synergy's scripts
- Improved Salt Rocks' gamefeel use
- Increased jack of clubs' explosing chance (40% > 60%)
- Re-added Gnawed Leaf to pools when playing with Edith
- Added Edith's Gnawed leaf interaction
-- Stomp's damage will get a x1.5 damage mult
-- Edith's Damage will be much slower than usual

v1.6.2
- Fixed Edith being able to destroy doors
- Fixed T. Edith's arrow not having its grudge design in Grudge challenge
- Potentially fixed an error when imprecise parrying a troll bomb
- Added an extra check to slot land manger function
- Added Effigy EID description
- Added Chunk of basalt EID description
- Added Mexico's target design

v1.6.3
- Reduced Edith's jump base cooldown frames (18 > 15)
- Tweaked Edith's stomp cooldown manager function
-- Now cooldown should be reduced less on high movement speed (for reference, 2.0 speed sets cooldown to 8 frames)
- Added Ludovico stomp synergy
- Fixed Terra's stomp synergy's shockwaves destroying every enemy 
- Tweaked Terra's stomp synergy
-- Increased shockwaves' damage
-- Increased distance between shockwave rings
- Increased Cindered enemy received damage from parry mult (x1.2 > x1.25)
]], true)

	ImGui.AddText("EdithRebuilt_v1.7", [[
v1.7.0 *Scorched Hops update*
- General:
-- Removed Suplex from pools when playing with any Edith (will be re-added)
-- Now both Ediths will get flight when going to a crawlspace room

- Tainted Edith:
-- Added a custom portrait sprite when playing Grudge challenge
-- Updated Character Selection sprite
-- Now her costume is managed by a null item
-- Now her damage multipler is managed by a null item
-- Movement Rework: 
--- Now Tainted Edith HopDash will behave different depending on how many frames you keep the button
---- 1-4 frames: Tainted Edith will stop her movement and reset the hopdash charge, Edith will flash in blue
---- 5-19 frames: Tainted Edith will stop and spawn her arrow, allowing her to redirect the movement without losing charge, Edith will flash in light grey
---- 20+ frames: The redirect will be cancelled and Tainted Edith charge will be restarted, Edith will flash in black
--- Tweaked Hopdash speed formula to be parabolic (less charge gives more, 50% charge gives 75% of speed, and 80% charge gives 96% of speed)
--- Now Tainted Edith can go trough rooms without stopping her movement
--- Now Tainted Edith can destroy rocks at 50% or more HopDash charge
--- Stopping a hopdash with the parry button will instantly perform a parry land
--- Increased HopDash speed base (8 > 8.5)
--- Reduced GrudgeDash speed base (10 > 9)
--- Removed GrudgeDash speed multiplier
--- Fixed GrudgeDash collision behaving weird
-- Parry:
--- Increased Perfect Parry Radius (18 > 22)
--- Increased Perfect parry i-frames (25 > 30)
--- Increased Imprecise parry i-frames (15 > 20)
--- Increased parry cooldown: 
---- Perfect parry: 10 > 12
---- Birthcake perfect parry: 8 > 10
--- Parry cooldown will be reduced with HopDash static charge (up to 8 frames at 100%)
--- Now HopDash charge increases i-Frames (1 frame every 20%, max 10 frames with Birthright)
--- Added a 6 frames input buffer for the parry
--- Added a perfect parry flash (configurable in ImGui menu)
--- Added Hawk Tuah perfect parry sound effect
--- Now Bombs can be parried (parried bombs increases their damage by x1.25)

- Edith:
-- Added a custom portrait sprite when playing Vestige challenge
-- Now her costume is managed by a null item
-- Now her damage multipler is managed by a null item
-- Updated Character Selection sprite
-- Added Edith's Hood stomp synergy
-- Added Pepper's stomp synergy birthright improvement
-- Now Edith's ImGui Options wont appear when she's locked
-- Reduced Edith's water current drag strenght
-- Increased Edith's target movement speed (Resizer 4 > 4.5)

- Items:
-- Now Divine Retribution grants a full soul heart when having Car Battery
-- Tweaked Sal:
--- Reduced frames between salt creep spawn (15 > 10)
--- Now salt creep deals damage (0.5 per tick)
--- Reduced salt creep duration (3 secs > 2 secs)
-- Tweaked Molten Core:
--- Increased burn radius (60 > 80)
--- Increased damage addition (1 > 1.25)
--- Increased killing's fire jet size (scaled by 2)
-- Tweaked Edith's Hood:
--- Changed cooldown Update Callback (POST_PLAYER_UPDATE > POST_PEFFECT_UPDATE, this should make the cooldown be reduced slower)
--- Reduced stomp cooldown (90 > 60)
--- Now its Damage multiplier is added through XML
--- Increased stomp Damage (increased player's damage mult, 0.75 > 1.5)
--- Now its Damage multiplier is added through XML
--- Increased stomp radius (30 > 40)
--- Increased stomp Knockback (5, 15)
--- Increased stomp i-frames (20 > 30)
--- Reduced Edith's Hood cooldown on clear rooms (10 frames)
-- Tweaked Gilded Stone:
--- Now it grants 1 luck
--- Reduced Penny chance reward (75% > 70%)
--- Increased Dime chance reward (5% > 10%)
-- Reworked Sulfuric Fire:
--- Now using it nearby enemies will grant a fading damage up (2 for 4 seconds, depends on th quantity of hit enemies)
--- Now it pushes enemies on use
--- Killing an enemy while having the damage up will spawn brimstone ball on its position
--- Added a damage mult when using it with Judas while having birthright (x1.5)
--- Added a damage mult when using it while having Car Battery (x1.25)
--- Added a screen shake on use
-- Reworked Chunk of Basalt:
--- Now Isaac will flicker when the dash is ready
--- Now colliding with an enemy while dashing will create a ring of shockwaves around the hit position, dealing player's damage x2
--- Now Colliding with a grid entity will create a ring of shockwaves around the hit position, dealing player's damage x2
--- Enemies near to the collided enemy will get 75% of the collision damage
--- Increased dash damage divider (4 > 5)
-- Reworked Spices Mix:
--- Updated Sprite
--- Now spices can be switched by pressing the Drop key
--- Now the spice info flavor text is displayed when changing spices or pressing the Map button
--- Now a spice jar is rendered Above the item's sprite
--- Moved all spices (status effects in general) to their own scripts
--- Reworked the following spice effects:
---- Oregano:
----- Now enemies spawns oregano creep that slows enemies
----- Now enemies takes damage over time
---- Pepper:
----- Now Pepper creep is spawned on killing a peppered enemy
----- Now Sneezes pushes and damages enemies
----- Now Sneezes have a sound effect
----- Added an sneeze sound effect
---- Cinnamon:
----- Every 20 frames the enemy will cough, pushing enemies and leaving a cinnamon dust cloud for 5 seconds
----- Enemies inside this cloud will get 3 damage every 15 frames
- Trinkets
-- Reworked Burnt Salt:
--- Now every third shot tear will be a burnt salt tear
--- Hitting an enemy with a burnt salt tear will apply Cinder status effect
--- Killing an enemy with Cinder status effect will spawn a circle of cinder creep around it

v1.7.0a
- Fixed Parry flash data not being properly initialized (looks like this also fixed a memory leak lol)

v1.7.1
- General:
-- Fixed Spiked rocks damage negator giving errors
-- Updated ImGui.lua 
- Tainted Edith:
-- Movement: 
--- Removed T. Edith's redirect reset
--- Removed Redirection slide
--- Removed Parry slide
--- Removed single tap stop slide
--- Removed Hopdash cooldown
--- Removed Rock destroy charge limit
--- Reduced Arrow speed when redirecting the hopdash
--- Reduced T. Edith's minimum invulnerability damage charge (30% > 20%)
--- Increased Hopdash land damage
--- Tweaked Hopdash land damage formula

-- Parry:
--- Increased Perfect Parry Radius (22 > 28)
--- Increased Imprecise Parry i-frames (20 > 25)
--- Removed failed parry hopdash charge reduction
--- Increased imprecise parry hopdash bonus (5% > 15%)
--- Increased perfect parry hopdash bonus (20% > 30%)
--- Now Imprecise parries applies jump recoil to enemies
]], true)

	ImGui.AddText("EdithRebuilt_v1.8", [[
v1.8.0 *Burning Flies update*
- General:
-- Renamed achievements (THIS WILL ERASE MOD'S PROGRESS)
-- Great mod's codebase rewrite 
-- Now both Ediths won't be affected by slippery creep
-- Now salt types are stored in flags, allowing to combine them
-- Now Edith can't accidentally take shop/devil deal items
-- Reworked stomp system
-- Reworked Land pickup manager
-- Added Abyss locusts for all mod items
-- Added Book of Virtues wisps for all mod active items
-- Added Effigy's costume
-- Added Edith's Hood's costume
-- Added Vestige Mode and Grudge Mode:
--- Unlocked after beating Vestige and Grudge challenges respectively
--- Play with the same gameplay rules in a normal run
-- Updated StatusEffectsLibrary (v1.12 > v1.13)
-- Updated Save Manager (v2.3.2 > v2.4.1b)
-- Improved Molten Core sprite
-- Improved Gilded Stone sprite
-- Improved Sulfuric Fire sprite
-- Improved Pepper Grinder sprite
-- Improved Hydrargyrum sprite
-- Improved Divine Retribution sprite
-- Improved Sal sprite
-- Improved Faith of the unfaithful sprite
-- Improved Unlock manager
-- Improved water land vfx's color
-- Fixed Jack of Clubs UI sprite being offset 
-- Fixed Death's touch making Salt Tears incredibly giant for one frame
-- Fixed Geode triggering its destroy function more times than intended
-- Fixed ImGui menu constantly giving errors when Edith is locked
-- Fixed Parprika's clouds not dealing damage when having only 1 copy
-- Fixed Burnt Hood not correctly triggering parry effects
-- Fixed Door manager not opening Reflourished's Gehenna's door
-- Fixed Bombstomp not being fast enough when having flight
-- Fixed Edith not having a death sound effect
-- Fixed Edith not spawning a poof effect when going trough a trapdoor
-- Fixed Edith's target moving slow when holding down the jump button while not jumping and moving it in Vestige
-- Fixed T. Edith not getting hopdash charge bonus in Grudge Challenge
-- Fixed T. Edith being invulnerable when falling to a Little's Horn pit while dashing
-- Fixed T. Edith's sprite being pretty offset when going to the minecart
-- Fixed T. Edith going backwards when going to the mirror door
-- Fixed T. Edith being more dragged by water currents while redirecting her hopdash 
-- Fixed T. Edith triggering Grudge sliding vfx while redirecting in water currents

- Edith: 
-- Added a jump animation 
-- Increased height and speed from jump explosion recoil
-- Increased Target's speed
-- Now Target's speed will be affected by Edith's movement speed
-- Fixed Edith's stomp damage not scaling correctly when playing Greed/Greedier mode
-- Fixed Edith's explosive stomps not destroying machines and beggars
-- Fixed Edith droping trinkets when jumping with DROP key
-- Increased Edith's land's pickup radius (20 > 30)
-- Fixed familiars not falling at the same speed as Edith when having flight
-- Now Edith will land on her target more accurately
-- Now Edith's stomp radius scales with size
-- Added Cube Baby stomp interaction
-- General Stomp rebalance:
--- Increased stomp cooldown (base 15 > 16)
--- Increased stomp damage base (12 > 12.75)
--- Reduced chapter's stomp damage increase (6 > 5)
--- Increased flight stomp damage mult (1.25 > 1.3)
--- Reduced stomp radius base (35 > 32)
-- Added Critical stomps:
--- Luck based trigger (10% chance at 0 luck, 50% chance at 20 luck)
--- Increased damage (x1.5)
--- increased knockback (x1.15)
--- Reduced stomp cooldown by 25%
--- Increased screenshake
--- Edith will flash red
-- Added Edith's birthwrong effect:
--- Dissolution, flooded rooms:
---- All rooms will get flooded
---- Standing on water will slowly decrease edith's movement speed (-0.01 every 20 frames)
---- If Movement speed goes below 0.7, Edith won't be able to shoot tears
---- Killing salted enemies with the stomp will increase speed by 0.5
-- Reworked Edith's birthcake effect:
--- Now offensive stomps have a 25% chance of apply salted status effect

- Tainted Edith:
-- Parry: 
--- Fixed Perfect parried projectiles not going to the nearest enemy if its spawner is dead
--- Increased Parry radius (28 > 32)
--- Reduced Parry jump's speed (5.5 > 4.75)
--- Reduced Perfect Parry's hopdash charge bonus (30% > 25%)
--- Added blazing parries:
---- Luck based trigger (10% at 0 luck, 50% at 20 luck)
---- Imprecise parried enemies will get burn status effect
---- Perfect parried enemies will spawn a fire jet on its position
-- HopDash: 
--- Increased Hopdash land damage
--- Increased T. Edith's hopdash land's pickup radius (20 > 30)
--- Now T. Edith's hopdash land applies tear status effects
--- Now Grudge's dash crush will ignore boss armor
--- Fixed Wisps and Willos going pretty far when stopping a hopdash
-- Added T. Edith's birthwrong effect:
--- The sky breaks twice: 
---- Evere 3 frames a rock will fall from the sky
---- These rocks will spawn fire jets on landing
---- 15% of spawn a fire jet wave instead of a single fire jet
---- These rocks and fire jets damage enemies, but can also hurt Tainted Edith

- Items: 
-- Pepper Grinder changes:
--- Now Pepper Grinder is a timed active (4 seconds)
-- Divine Retribution buff:
--- Increased base damage (25 > 40)
--- Increased healing (1 > 2)
-- Molten Core buff:
--- Increased radius (80 > 120)
-- Hydrargyrum's buff: 
--- Reduced Hydrargyrum tears shot interval (15 frames > 10 frames)
--- Increased Mercury creep size
-- Fate of the unfaithful buff:
--- Reduced charges (4 > 3)
-- Salt Shaker changes:
--- Now it properly pushes nearby enemies on use
--- Added vfx
--- Now the salt circle pushes enemies away
-- Gilded Stone rework:
--- Readjusted reward weights
--- Added the following rewards:
---- Double penny
---- Lucky penny
--- Adjusted rock tear chance
---- Now they are more likely to be shot
---- Luck has more weight in the formula
---- Chance capped at 75%
--- Adjusted rock reward chance
---- Now they are more likely to give rewards
---- Coins have more weight in the formula
---- Capped at 50%
-- Effigy rework:
--- Now Effigy has 64 charges
--- On use, Isaac will switch between his normal state and Statue state
--- On Statue state:
---- Isaac is unable to shoot
---- Isaac will be unable to walk, using Edith-like stomps to move:
----- Stomp damage: 3x Player's damage
----- Cooldown: 0.5 seconds (30 update frames)
----- 20 i-frames
----- Consumes 1 charge on land
---- When pressing any jump button (the same used by Edith to jump) Isaac will perform a high jump:
----- Stomp damage: 10x player's damage + 10
----- Cooldown: 4 seconds (120 update frames)
----- 20 i-frames
----- Consumes 5 charges on land
--- When completely discharged, it won't be charged by any means until going to a new floor
-- Burnt Hood buff:
--- Increased Parry radius (28 > 32)

- Trinkets:
-- Geode:
--- Now Geode can spawn soul stones

- Consumables:
-- Salt Rocks buff:
--- Killing an enemy salted with salt rocks will shoot 10-15 salt tears in random directions
--- These salt tears will leave salt creep on land
--- This salt creep can re-trigger the effects listed above

- Misc:
-- Salt creep changes:
--- Only salt shaker creep will push enemies away
--- Reduced salt shaker creep push strenght

v1.8.1
- General:
-- Improved Repentance+ check
-- Added Clear Unlocks and Unlock All buttons to ImGui progress section
-- Fixed T. Edith being completely invulnerable while redirecting her hopdash
-- Fixed Salt Heart being impossible to unlock
-- Fixed Edith Ultra Greedier unlocks not being shown when unlocked

v1.8.1a
- Removed bugged costume manager

v1.8.2
- General:
-- Removed unused debug functions
-- Added Fall From Grace's boiler's mirror world support
-- Added mysterious liquid stomp/parry synergy
-- Added Dead Eye stomp/parry synergy
-- Moved TempStatsLib save init out from Sulfuric Fire's script
-- Improved Salt Shaker's push
-- Improved T. Edith's orbitals fix player detection
-- Reduced Edith/T. Edith's Effigy's use decrease (8 > 4)
-- Fixed Edith/T. Edith using keys on already opened chests
-- Fixed Edith/T. Edith not being able to use coins on chests with Pay to Play
-- Fixed Black Powder's stomp/parry synergy pentagram being giant for a frame
-- Cards, pills and trinkets can no longer be picked by pickup grab extended radius
- Edith: 
-- Removed Edith's jump's pseudoinput-buffer
-- Fixed Edith not being able to jump in flooded mortis rooms (Last Judgment)
-- Fixed Edith being able to trigger a jump when pitfalling
-- Reduced Edith's target speed
-- Increased BombStomp damage when having Mr. Mega
-- Increased Vestige's jump speed
- T. Edith:
-- Improved Status effect stomp/parry synergies
- Stomp/Parry synergies:
-- Improved Edith's birthright detection
-- Added Dead Eye's birthright interaction
-- Added Effigy's birthright interaction
-- Removed birthright checks from T. Edith's rockwave parry synergy
-- Removed LittleHorn.lua and GodsFlesh.lua (these are managed by tearflags)
-- Improved Damage adders' stomp synergies:
--- Moved table outside of the function
--- Added Edith's birthright interaction
-- Changed Rockwaves synergy:
--- Fixed rockwaves more damage when having birthright with T. Edith
--- Increased Edith's Birthright's damage mult (1.4 > 1.5)

v1.8.2a
- Removed an unused module
- Removed a leftover debug renderer

v1.8.3
- General: 
-- General vector math optimization
-- Fixed Edith/T. Edith's Greedier unlock function triggering for other players
-- Added Ludovico's Stomp/Parry synergy
-- Improved Edith/T. Edith costume giver function
-- Removed an unused variable
-- Moved both Vestige and Grudge unlock methods to UnlockManager.lua
-- Improved Rep+ detection message
-- Remade Stomp's pickup grab system:
--- Cards/runes, pills and trinkets can be taken again with this
--- Now Edith must land in almost as close as possible to a shop item to buy it
--- Fixed an error that caused Edith to lose her body for a moment when trying to grab two cards/runes/pills/trinkets at once

- Edith:
-- Fixed Edith triggering stomp synergies when going trough a trapdoor

- Items:
-- Fixed Salt Shaker push area persisting between rooms
-- Effigy:
--- Now a player in effigy state won't be affected by slipperyness
--- Now a player in effigy state will be less dragged by water currents
--- Now a player in effigy state won't receive damage from creep and spikes
--- Now a player in effigy state won't get damage by destroying a spiked rock with a stomp
--- Added Judas' Birthright interaction for Effigy
--- Fixed Effigy consuming more charges than intended with non-Edith Characters
--- Fixed Effigy triggering its effects when falling to a pitfall

- Trinkets:
-- Rumbling Pebble changes:
--- Increased rock scattering spread
--- Now Edith stomps/ T. Edith hops can trigger rock scattering]]
, true)

	ImGui.AddText("EdithRebuilt_v1.9", [[
v1.9.0 *Hot 'n Ready update*
- General:
-- Removed unused colors
-- Minor ImGui optimization
-- Minor Vector math optimization
-- Minor RGB optimization
-- Removed unused colors
-- Now Charmed enemies won't be pushed and damaged by stomps/parries
-- TriggerPickupCollide() won't be called on empty pedestals
-- Added DamageFlag.DAMAGE_RED_HEARTS flag to damaging slots manager function
-- Fixed Dark Judas not having birthright interactions with mod's active items
-- Fixed revived characters having any Edith costume as reviving from her

- Mod Compatibility:
-- Added Custom Health API v0.967 (only loaded if Community Remix is enabled)
-- Added Salt Hearts:
--- Unlocked by beating Community Remix's Insane mode as either Edith or T. Edith
--- Salt Hearts can take 3 hits and acts like soul hearts
--- When depleted, Isaac will get Salted status effect for 4 seconds, leaving creep below him
--- Chance to replace soul hearts:
---- Full salt heart: 25% to replace a Full soul heart
---- 2/3 salt heart: 33.3% to replace a Half soul heart if the general 25% chance is met
---- 1/3 salt heart: 66.6 change to replace a Half soul heart if the general 25% chance is met
-- Added Runic Tablet Support:
--- Increased Damage and Knockback of Soul of Edith's stomp
-- Revamped EID support (WIP)
--- Rewrite of items descriptions
--- Added Character descriptions
--- Added Birthright descriptions 
--- Added Book of Virtues descriptions
--- Added Judas' Birthright descriptions

- Edith:
-- Now Vestige Edith won't be affected by explosion recoil
-- Now vestige Edith won't have flight interaction (will keep increased stomp params)
-- Improved jump animation damage negator check
-- Now falling trough a pit as Edith will bring her to a tile near to the pit
-- Fixed Edith instantly performing a bombstomp when trying to jump after falling trough a pit and having a bombstomp activated

- T. Edith: 
-- Parry:
--- Tweaked ready-to-use parry indicator:
--- Will emit a sound and a strong flash only once, removed intermitent flashes
--- Imprecise parry:
---- Removed bonus hopdash charge
---- Increased parry cooldown frames (15 > 25)
-- Overheat:
--- Overheat will increase everytime a parry is performed (Perfect: 25%, Imprecise: 10%)
--- When overheat:
---- General Parry's damage will be increased (up to x1.5 depending on heat percentage)
---- General Parry's cooldown will be increased (6 frames every 20%)
---- T. Edith will turn progresivelly red and start smoking
---- Heat will be decreased over time (1% every 5 frames, 2% every 5 frames is T. Edith is moving) 
-- Arrow:
--- Increased T. Edith's arrow's sprite thickness 
--- Removed T. Edith's arrow increased speed while redirecting
--- Added T. Edith's arrow's animations:
---- Idle: Normal animation, slow blink
---- Charged: Fast blink, played when hopdash is charged at 100%
---- Pop: Played when starting a hopdash redirection
--- Now T. Edith's arrow will perform a push n' pull effect when triggering a redirection
-- Updated Backdrop tutorial
-- Fixed T. Edith not having the expected shop items interaction
-- Fixed Grudge Edith dealing damage while changing her dash's direction
-- Now Tainted Edith will stop the hopdash when going trough a room at less of 50% of hopdash charge
-- Removed T. Edith's color change from charging Hopdash

- Status Effects:
-- Increased Salted status effect damage mult (1.2 > 1.35)
-- Increased Turmeric infection clouds chance (35% > 40%)
-- Now Enemies in Cummin status effect will move randomly

- Items:
-- Added Judas' Birthright effect for Pepper Grinder
-- Added Judas' Birthright effect for Spices Mix
-- Added Judas' Birthright effect for Fate of the Unfaithful
-- Added Judas' Birthright effect for Divine Wrath

v1.9.0a
- General
-- Fixed Edith's target design 
giving errors due to an 
internal change
-- Revamped DSS changelogs
-- Now DSS menu has a settings section
]])
end

local function OptionsUpdate()
	if not RenderMenu then return end
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end
	if CheckImGuiIntegrity() then return end

	AddTabBars()
	AddEdithOptions()
	AddTaintedEdithOptions()
	AddMiscOptions()
	AddContributors()
	AddProgressBars()
	AddChangelogs()
	UpdateImGuiData()

	RenderMenu = false
end

local ModAchievements = {
	Edith = {
		achievements.ACHIEVEMENT_SALT_SHAKER,
		achievements.ACHIEVEMENT_SALT_HEART,
		achievements.ACHIEVEMENT_SAL,
		achievements.ACHIEVEMENT_DIVINE_RETRIBUTION,
		achievements.ACHIEVEMENT_MOLTEN_CORE,
		achievements.ACHIEVEMENT_PEPPER_GRINDER,
		achievements.ACHIEVEMENT_PEPPER_GRINDER,
		achievements.ACHIEVEMENT_GILDED_STONE,
		achievements.ACHIEVEMENT_HYDRARGYRUM,
		achievements.ACHIEVEMENT_EDITHS_HOOD,
		achievements.ACHIEVEMENT_CHUNK_OF_BASALT,
		achievements.ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL,
		achievements.ACHIEVEMENT_GEODE,
		achievements.ACHIEVEMENT_SULFURIC_FIRE,
		achievements.ACHIEVEMENT_TAINTED_EDITH,
	},
	TEdith = {
		achievements.ACHIEVEMENT_BURNT_HOOD,
		achievements.ACHIEVEMENT_PAPRIKA,
		achievements.ACHIEVEMENT_SALT_ROCKS,
		achievements.ACHIEVEMENT_BURNT_SALT,
		achievements.ACHIEVEMENT_DIVINE_WRATH,
		achievements.ACHIEVEMENT_JACK_OF_CLUBS,
		achievements.ACHIEVEMENT_SOUL_OF_EDITH,
	},
	Misc = {
		achievements.ACHIEVEMENT_THANK_YOU
	}
}

local function GetEdithUnlockedAchs()
	local count = 0
	for _, unlock in ipairs(ModAchievements.Edith) do
		if pgd:Unlocked(unlock) then
			count = count + 1
		end
	end
	return count
end

local function GetTEdithUnlockedAchs()
	local count = 0
	for _, unlock in ipairs(ModAchievements.TEdith) do
		if pgd:Unlocked(unlock) then
			count = count + 1
		end
	end
	return count
end

local function CheckProgressBarIntegrity()
	local boolean = true

	for _, ent in pairs(Menu.ProgressBar) do
		if not ImGui.ElementExists(ent) then
			boolean = false
			break
		end
	end

	return boolean
end

local function UpdateProgressBar()
	if not CheckProgressBarIntegrity() then return end

	local bars = Menu.ProgressBar
	local totaledithUnlocks = GetEdithUnlockedAchs() / 15
	local totaltedithUnlocks = GetTEdithUnlockedAchs() / 7
	local totalgeneralUnlocks = (GetEdithUnlockedAchs() + GetTEdithUnlockedAchs() + (isEdithUnlocked(true) and 1 or 0)) / 23

	ImGui.UpdateData(bars.Edith, ImGuiData.Value, totaledithUnlocks)
	ImGui.UpdateData(bars.TEdith, ImGuiData.Value, totaltedithUnlocks)
	ImGui.UpdateData(bars.General, ImGuiData.Value, totalgeneralUnlocks)
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, UpdateProgressBar)

function ImGuiMod.DestroyImGuiOptions()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then goto continue end
		ImGui.RemoveElement(ID)
		::continue::
	end
end

local function InitSaveData()
	RenderMenu = true

	if not SaveManager and not SaveManager:IsLoaded() then return end
	local menuData = SaveManager.GetSettingsSave()
	if not menuData then return end

	menuData.EdithData = menuData.EdithData or {}
	menuData.TEdithData = menuData.TEdithData or {}
	menuData.MiscData = menuData.MiscData or {}

	local EdithData = menuData.EdithData ---@cast EdithData EdithData
	local TEdithData = menuData.TEdithData ---@cast TEdithData TEdithData
	local MiscData = menuData.MiscData ---@cast MiscData MiscData

	EdithData.TargetColor = EdithData.TargetColor or {Red = 1, Green = 1, Blue = 1}
	EdithData.StompSound = EdithData.StompSound or 1
	EdithData.StompVolume = EdithData.StompVolume or 100
	EdithData.EnableExtraGore = EdithData.EnableExtraGore or false
	EdithData.JumpCooldownSound = EdithData.JumpCooldownSound or 1
	EdithData.TargetDesign = EdithData.TargetDesign or {Idx = 1, Design = ""}
	EdithData.DisableSaltGibs = EdithData.DisableSaltGibs or false
	EdithData.RGBMode = EdithData.RGBMode or false
	EdithData.RGBSpeed = EdithData.RGBSpeed or 0.005
	EdithData.TargetLine = EdithData.TargetLine or false
	EdithData.DefensiveStompWindow = EdithData.DefensiveStompWindow or 18
	EdithData.SaltShakerSlot = EdithData.SaltShakerSlot or 0
	EdithData.EnableVestigeMode = EdithData.EnableVestigeMode or false

	TEdithData.ArrowColor = TEdithData.ArrowColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.ArrowDesign = TEdithData.ArrowDesign or 1
	TEdithData.HopSound = TEdithData.HopSound or 1
	TEdithData.Volume = TEdithData.Volume or 100
	TEdithData.ParrySound = TEdithData.ParrySound or 1
	TEdithData.RGBMode = TEdithData.RGBMode or false
	TEdithData.RGBSpeed = TEdithData.RGBSpeed or 0.005
	TEdithData.EnableExtraGore = TEdithData.EnableExtraGore or false
	TEdithData.EnableHopdashTrail = TEdithData.EnableHopdashTrail or false
	TEdithData.TrailColor = TEdithData.TrailColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.TrailDesign = TEdithData.TrailDesign or 1
	TEdithData.ParryFlashColor = TEdithData.ParryFlashColor or {r = 1, g = 1, b = 1, a = 1}
	TEdithData.ParryFlashBrightness = TEdithData.ParryFlashBrightness or 1
	TEdithData.ParryFlashContrast = TEdithData.ParryFlashContrast or 0.4
	TEdithData.EnableGrudgeMode = TEdithData.EnableGrudgeMode or false

	MiscData.EnableShakescreen = MiscData.EnableShakescreen or true
	MiscData.CustomActionKey = MiscData.CustomActionKey or Keyboard.KEY_Z

	ImGuiMod.DestroyImGuiOptions()
end

mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, function ()
	RenderMenu = false
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end

	local EdithData = saveData.EdithData ---@cast EdithData EdithData

	if type(EdithData.TargetDesign) == "number" then
		EdithData.TargetDesign = {Design = "Choose Color", Idx = 1}
	end
end)

mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, ImGuiMod.DestroyImGuiOptions)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, OptionsUpdate)