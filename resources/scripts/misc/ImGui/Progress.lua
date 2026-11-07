local mod = EdithRebuilt
local enums = mod.Enums
local achievements = enums.Achievements
local pgd = enums.Utils.PGD

local function AddProgressBars()
    local ImGuiMods = mod.ImGuiModules
    local Elements = ImGuiMods.ELEMENTS
    local Unlocks = ImGuiMods.UNLOCKS

    local Menu = Elements.Menu
    local isEdithUnlocked = Unlocks.IsEdithUnlocked
    local ResetUnlocks = Unlocks.ResetUnlocks

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

    local ImGuiMods = mod.ImGuiModules
    local Elements = ImGuiMods.ELEMENTS
    local Unlocks = ImGuiMods.UNLOCKS

    local Menu = Elements.Menu

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

    local ImGuiMods = mod.ImGuiModules
    local Elements = ImGuiMods.ELEMENTS
    local Unlocks = ImGuiMods.UNLOCKS

    local Menu = Elements.Menu
    local isEdithUnlocked = Unlocks.IsEdithUnlocked
    local ResetUnlocks = Unlocks.ResetUnlocks

	local bars = Menu.ProgressBar
	local totaledithUnlocks = GetEdithUnlockedAchs() / 15
	local totaltedithUnlocks = GetTEdithUnlockedAchs() / 7
	local totalgeneralUnlocks = (GetEdithUnlockedAchs() + GetTEdithUnlockedAchs() + (isEdithUnlocked(true) and 1 or 0)) / 23

	ImGui.UpdateData(bars.Edith, ImGuiData.Value, totaledithUnlocks)
	ImGui.UpdateData(bars.TEdith, ImGuiData.Value, totaltedithUnlocks)
	ImGui.UpdateData(bars.General, ImGuiData.Value, totalgeneralUnlocks)
end

return {
	Add = AddProgressBars,
	Update = UpdateProgressBar,
}