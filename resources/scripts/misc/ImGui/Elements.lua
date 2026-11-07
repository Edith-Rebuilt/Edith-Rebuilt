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

local Elements = {
	Menu = {
		SubMenu = {
			Settings = Prefixes.Menu .. "Settings",
			Credits = Prefixes.Menu .. "Credits",
			Progress = Prefixes.Menu .. "Progress",
			Changelog = Prefixes.Menu .. "Changelog",
			ModCompat = Prefixes.Menu .. "ModCompat",
		},
		Windows = {
			Settings = Prefixes.Window .. "Settings",
			Credits = Prefixes.Window .. "Credits",
			Progress = Prefixes.Window .. "Progress",
			Changelog = Prefixes.Window .. "Changelog",
			ModCompat = Prefixes.Window .. "ModCompat"
		},
		TabBars = {
			Settings = Prefixes.TabBar .. "Settings",
			Edith = Prefixes.TabBar .. "Edith",
			TEdith = Prefixes.TabBar .. "Tainted_Edith",
			Credits = Prefixes.TabBar .. "Credits",
			Changelog = Prefixes.TabBar .. "Changelog",
			ModCompat = Prefixes.TabBar .. "ModCompat"
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

return Elements