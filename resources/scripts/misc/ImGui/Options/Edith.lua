local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local tables = enums.Tables
local variants = enums.EffectVariant
local callbacks = enums.Callbacks
local achievements = enums.Achievements
local pgd = enums.Utils.PGD

local Player = mod.Modules.PLAYER

local ImGuiTables = tables.ImGuiTables

local SaveManager = mod.SaveManager

local function AddEdithOptions()
	local ImGuiMods = mod.ImGuiModules
	local Elements = ImGuiMods.ELEMENTS
	local Unlocks = ImGuiMods.UNLOCKS
	local Menu = Elements.Menu
	local Options = Elements.Options

	if not Unlocks.IsEdithUnlocked(false) then return end

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

return {
	Add = AddEdithOptions,
}