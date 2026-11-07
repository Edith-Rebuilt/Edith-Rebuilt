local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local tables = enums.Tables
local pgd = enums.Utils.PGD
local variants = enums.EffectVariant
local callbacks = enums.Callbacks
local achievements = enums.Achievements

local Player = mod.Modules.PLAYER

local ImGuiTables = tables.ImGuiTables

local SaveManager = mod.SaveManager

local data = mod.DataHolder.GetEntityData

local function AddTaintedEdithOptions()
	local ImGuiMods = mod.ImGuiModules
	local Elements = ImGuiMods.ELEMENTS
	local Unlocks = ImGuiMods.UNLOCKS

	local Menu = Elements.Menu
	local Options = Elements.Options

	if not Unlocks.IsEdithUnlocked(true) then return end

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

return {
	Add = AddTaintedEdithOptions,
}