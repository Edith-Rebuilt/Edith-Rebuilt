local mod = EdithRebuilt
local SaveManager = mod.SaveManager
local RenderMenu = true
local ImGuiMod = {}

EdithRebuilt.ImGuiModules = {
    ELEMENTS = include("resources.scripts.misc.ImGui.Elements"),
    UNLOCKS = include("resources.scripts.misc.ImGui.Unlocks"),
    SAVE_DATA = include("resources.scripts.misc.ImGui.SaveData"),
    EDITH = include("resources.scripts.misc.ImGui.Options.Edith"),
    T_EDITH = include("resources.scripts.misc.ImGui.Options.TEdith"),
    MISC = include("resources.scripts.misc.ImGui.Options.Misc"),
    CREDITS = include("resources.scripts.misc.ImGui.Credits"),
    CHANGELOGS = include("resources.scripts.misc.ImGui.Changelogs"),
    PROGRESS = include("resources.scripts.misc.ImGui.Progress"),
    MOD_COMPAT = include("resources.scripts.misc.ImGui.ModCompat"),
}

local ImGuiMods = EdithRebuilt.ImGuiModules

local elements = ImGuiMods.ELEMENTS
local saveData = ImGuiMods.SAVE_DATA
local Unlocks = ImGuiMods.UNLOCKS

local menu = elements.Menu

if not ImGui.ElementExists("EdithRebuilt") then
	if RenderMenu == false then return end
    ImGui.CreateMenu('EdithRebuilt', '🧂 Edith: Rebuilt')
end

local function AddMenuElement(name, title)
	if RenderMenu == false and ImGui.ElementExists(name) then return end
    ImGui.AddElement("EdithRebuilt", name, ImGuiElement.MenuItem, "\u{f013} " .. title)
end

local subMenu = menu.SubMenu
local MenuElements = {
    { name = subMenu.Settings, title = "Settings" },
    { name = subMenu.Credits, title = "Credits" },
    { name = subMenu.Progress, title = "Progress" },
    { name = subMenu.Changelog, title = "Changelog" },
    { name = subMenu.ModCompat, title = "Mod Compatibility" }
}

for _, Menu in ipairs(MenuElements) do
    AddMenuElement(Menu.name, Menu.title)
end

local imguiwindow = menu.Windows
local windows = {
    { name = imguiwindow.Settings, title = "Settings" },
    { name = imguiwindow.Credits, title = "Credits" },
	{ name = imguiwindow.Progress, title = "Progress"},
	{ name = imguiwindow.Changelog, title = "Changelog"},
	{ name = imguiwindow.ModCompat, title = "Mod Compatibility"},
}

for _, window in ipairs(windows) do
	if RenderMenu == false and ImGui.ElementExists(window.name) then return end
    ImGui.CreateWindow(window.name, window.title)
end

local links = {
	{ window = imguiwindow.Settings, menu = subMenu.Settings },
	{ window = imguiwindow.Credits, menu = subMenu.Credits },
	{ window = imguiwindow.Progress, menu = subMenu.Progress },
	{ window = imguiwindow.Changelog, menu = subMenu.Changelog },
	{ window = imguiwindow.ModCompat, menu = subMenu.ModCompat },
}

for _, link in ipairs(links) do
	ImGui.LinkWindowToElement(link.window, link.menu)
end

local elementTab = {}

---@param tabla table
---@param prefijo? string
local function recorrerTablaImGui(tabla, prefijo)
    prefijo = prefijo or ""
    for clave, valor in pairs(tabla) do
        if type(valor) == "table" then
            recorrerTablaImGui(valor, prefijo .. clave .. ".")
        else
			if ImGui.ElementExists(valor) then goto continue end
            if string.find(valor, "Tainted") then goto continue end
            elementTab[clave] = valor

            ::continue::
        end
    end
end

recorrerTablaImGui(elements)

local function CheckImGuiIntegrity()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then return false end
	end
	return true
end

local function ResetSaveData(isTainted)
	if saveData.Reset(isTainted) then
		RenderMenu = true
	end
end

local function AddTabBars()
	if not Unlocks.IsEdithUnlocked(false) then return end

    local tabBarSettings = menu.TabBars.Settings
    local Tabs = menu.Tabs

	ImGui.AddTabBar(menu.Windows.Settings, tabBarSettings)
	ImGui.AddTab(tabBarSettings, Tabs.Edith.Main, "Edith")

	if Unlocks.IsEdithUnlocked(true) then
		ImGui.AddTab(tabBarSettings, Tabs.TEdith.Main, "Tainted Edith")
	end

	ImGui.AddTab(tabBarSettings, Tabs.Misc.Main, "Misc")
end

local function OptionsUpdate()
	if not RenderMenu then return end
	if not SaveManager.IsLoaded() then return end
	local settingsSave = SaveManager.GetSettingsSave()

	if not settingsSave then return end
	if CheckImGuiIntegrity() then return end

	AddTabBars()
	ImGuiMods.EDITH.Add()
	ImGuiMods.T_EDITH.Add()
	ImGuiMods.MISC.Add(ResetSaveData)
	ImGuiMods.CREDITS.Add()
    ImGuiMods.PROGRESS.Add()
	ImGuiMods.CHANGELOGS.Add()
	ImGuiMods.MOD_COMPAT.Add()
	ImGuiMods.SAVE_DATA.Update()

	RenderMenu = false
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, ImGuiMods.PROGRESS.Update)
function ImGuiMod.DestroyImGuiOptions()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then goto continue end
		ImGui.RemoveElement(ID)
		::continue::
	end
end

local function InitSaveData()
	RenderMenu = true

	if saveData.Init() then
		ImGuiMod.DestroyImGuiOptions()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, function ()
	RenderMenu = false
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
	local save = SaveManager.GetSettingsSave()

	if not save then return end

	local EdithData = save.EdithData ---@cast EdithData EdithData

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
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, ImGuiMods.SAVE_DATA.Update)
