if not EID then return end

local enums = EdithRebuilt.Enums
local Collectibles = enums.CollectibleType
local PlayerType = enums.PlayerType
local Helpers = EdithRebuilt.Modules.HELPERS
local ShakerIcon = Helpers.IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER)
local IconsSprite = Sprite("gfx/ui/EID/EIDIcons.anm2", true)

EID:setModIndicatorName("Edith: Rebuilt")
EID:addIcon("Edith Rebuilt Icon", "ModIcon", 0, 32, 32, 0, -1, IconsSprite)
EID:setModIndicatorIcon("Edith Rebuilt Icon")

EID:addIcon("Player"..PlayerType.PLAYER_EDITH, "Player", 0, 15, 12, 2, 1, IconsSprite)
EID:addIcon("Player"..PlayerType.PLAYER_EDITH_B, "Player", 1, 15, 12, 2, 1, IconsSprite)

table.insert(EID.TextReplacementPairs, {"ERSalt",
    ShakerIcon ..
    "Any enemy that walks or pass over the salt will get salted #" ..
    ShakerIcon ..
    "Salted enemies will move slower and receive x1.35 times more damage"
})

table.insert(EID.TextReplacementPairs, {"SaltedStatus", ShakerIcon .. "Salted enemies will move slower and receive x1.35 times more damage"})

local SpicesColors = {
    ["ColorSalted"] = KColor(1, 1, 1, 1),
    ["ColorPepper"] = KColor(0.5, 0.5, 0.5, 1),
    ["ColorGarlic"] = KColor(1, 238/255, 188/255, 1),
    ["ColorOregano"] = KColor(113/255, 120/255, 82/255, 1),
    ["ColorCumin"] = KColor(115/255, 84/255, 67/355, 1),
    ["ColorTurmeric"] = KColor(250/255, 198/255, 49/255, 1),
    ["ColorCinnamon"] = KColor(210/255, 105/255, 30/255, 1),
    ["ColorGinger"] = KColor(239/255, 159/255, 89/255, 1),
}

for markup, color in pairs(SpicesColors) do
    EID:addColor(markup, color)
end



local path = "resources.scripts.compat.EID.scripts."

include(path .. "characters")
include(path .. "items")
include(path .. "synergies")
