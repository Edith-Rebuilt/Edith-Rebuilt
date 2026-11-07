local mod = EdithRebuilt
local SaveManager = mod.SaveManager


local function AddMiscOptions(ResetSaveData)
    local ImGuiMods = mod.ImGuiModules
    local Elements = ImGuiMods.ELEMENTS
    local Unlocks = ImGuiMods.UNLOCKS

    local Menu = Elements.Menu
    local Options = Elements.Options

    if not Unlocks.IsEdithUnlocked(false) then return end

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
	if Unlocks.IsEdithUnlocked(true) then
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

return {
	Add = AddMiscOptions,
}