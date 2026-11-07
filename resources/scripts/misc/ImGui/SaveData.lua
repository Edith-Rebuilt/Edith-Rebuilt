local mod = EdithRebuilt
local SaveManager = mod.SaveManager

---@class EdithData
---@field TargetDesign {Idx: integer, Design: string}
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

local function UpdateImGuiData()
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end

    local ImGuiMods = mod.ImGuiModules
    local Elements = ImGuiMods.ELEMENTS
    local Unlocks = ImGuiMods.UNLOCKS

    local Menu = Elements.Menu
    local isEdithUnlocked = Unlocks.IsEdithUnlocked
    local ResetUnlocks = Unlocks.ResetUnlocks

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

	return true
end

local function InitSaveData()
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

	return true
end

return {
	Update = UpdateImGuiData,
	Reset = ResetSaveData,
	Init = InitSaveData,
}