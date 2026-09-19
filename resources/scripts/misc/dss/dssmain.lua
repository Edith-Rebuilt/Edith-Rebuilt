---@diagnostic disable: undefined-field
local DSSModName = "Dead Sea Scrolls (Edith: Rebuilt)"
local mod = EdithRebuilt
local saveManager = mod.SaveManager
local MenuProvider = {}

function MenuProvider.SaveSaveData()
    saveManager.GetPersistentSave()
end

function MenuProvider.GetPaletteSetting()
    return saveManager.GetPersistentSave().MenuPalette
end

function MenuProvider.SavePaletteSetting(var)
    saveManager.GetPersistentSave().MenuPalette = var
end

function MenuProvider.GetGamepadToggleSetting()
    return saveManager.GetPersistentSave().GamepadToggle
end

function MenuProvider.SaveGamepadToggleSetting(var)
    saveManager.GetPersistentSave().GamepadToggle = var
end

function MenuProvider.GetMenuKeybindSetting()
    return saveManager.GetPersistentSave().MenuKeybind
end

function MenuProvider.SaveMenuKeybindSetting(var)
    saveManager.GetPersistentSave().MenuKeybind = var
end

function MenuProvider.GetMenuHintSetting()
    return saveManager.GetPersistentSave().MenuHint
end

function MenuProvider.SaveMenuHintSetting(var)
    saveManager.GetPersistentSave().MenuHint = var
end

function MenuProvider.GetMenuBuzzerSetting()
    return saveManager.GetPersistentSave().MenuBuzzer
end

function MenuProvider.SaveMenuBuzzerSetting(var)
    saveManager.GetPersistentSave().MenuBuzzer = var
end

function MenuProvider.GetMenusNotified()
    return saveManager.GetPersistentSave().MenusNotified
end

function MenuProvider.SaveMenusNotified(var)
    saveManager.GetPersistentSave().MenusNotified = var
end

function MenuProvider.GetMenusPoppedUp()
    return saveManager.GetPersistentSave().MenusPoppedUp
end

function MenuProvider.SaveMenusPoppedUp(var)
    saveManager.GetPersistentSave().MenusPoppedUp = var
end

local dssmenucore = include("resources.scripts.misc.dss.dssmenucore")
local dssmod = dssmenucore.init(DSSModName, MenuProvider)
local edithDir = {
    main = {
        title = "edith: rebuilt",
        buttons = {
            {str = "resume game", action = "resume"},
            {str = "settings", dest = "menuOptions" },
            dssmod.changelogsButton
        },
        tooltip = dssmod.menuOpenToolTip
    },
    menuOptions = {
        title = "menu options",
        buttons = {
            dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            dssmod.paletteButton,
            dssmod.menuHintButton,
            dssmod.menuBuzzerButton
        },
    },
}

local edithDirKey = {
    Item = edithDir.main,
    Main = "main",
    Idle = false,
    MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
    Path = {}
}

DeadSeaScrollsMenu.AddMenu(
    "Edith: Rebuilt",
    {
        Run = dssmod.runMenu,
        Open = dssmod.openMenu,
        Close = dssmod.closeMenu,
        Directory = edithDir,
        DirectoryKey = edithDirKey
    }
)
