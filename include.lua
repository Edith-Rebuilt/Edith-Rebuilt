local scriptsPath = "resources/scripts/"
local col = "collectibles/"
local ent = "entities/"
local syn = "synergies/"
local funcs = "functions/"
local compat = "compat/"
local libs = "libs/"
local misc = "misc/"
local effects = "statusEffects/"

local includeFiles = {
	-- Cosas necesarias
	compat .. "EID",
	compat .. "Birthcake",
	compat .. "RunicTablet",
	compat .. "TheFuture",
	compat .. "Birthwrong/Edith",
	compat .. "Birthwrong/TEdith",
	libs .. "prenpckillcallback",
	libs .. "CustomShockwaveAPI",
	libs .. "lhsx",
	funcs .. "functions",
	funcs .. "unlock_functions",
	misc .. "ImGui",
	misc .. "UnlockManager",

	effects .. "Oregano",
	effects .. "Salt",
	effects .. "Cinder",
	effects .. "HydrargyrumCurse",
	effects .. "Garlic",
	effects .. "Cinnamon",
	effects .. "Turmeric",
	effects .. "Ginger",
	effects .. "Pepper",
	effects .. "Cumin",

	-- Items
	col .. "items/Edith/SaltShaker",
	col .. "items/Edith/PepperGrinder",
	col .. "items/Edith/EdithsHood",
	col .. "items/Edith/SulfuricFire",
	col .. "items/Edith/Sal",
	col .. "items/Edith/MoltenCore",
	col .. "items/Edith/GildedStone",
	col .. "items/Edith/FateOfTheUnfaithful",
	col .. "items/Edith/SaltHeart",
	col .. "items/Edith/DivineRetribution",
	col .. "items/Edith/Hydrargyrum",
	col .. "items/Edith/SpicesMix",
	col .. "items/TEdith/BurntHood",
	col .. "items/TEdith/DivineWrath",
	col .. "items/Challenges/Effigy",
	col .. "items/Challenges/ChunkOfBasalt",
	-- Items fin

	-- Trinkets
	col .. "trinkets/Edith/geode",
	col .. "trinkets/Edith/rumblingpebble",
	col .. "trinkets/TEdith/Paprika",
	col .. "trinkets/TEdith/BurntSalt",
	-- Trinkets fin

	col .. "consumables/JackOfClubs",
	col .. "consumables/SaltRocks",
	col .. "consumables/SoulOfEdith",

	-- Entidades
	ent .. "Effects/Creeps",
	ent .. "Effects/Targets",
	ent .. "Effects/Trail",
	-- Entidades fin

	-- Personajes
	ent .. "Players/Edith",
	ent .. "Players/Edith_B",
	ent .. "Players/SharedFuncs",
	-- Personajes fin

	ent .. "Wisps/SaltShaker",
	ent .. "Wisps/SulfuricFire",
	ent .. "Wisps/DivineRetribution",
	ent .. "Wisps/SpicesMix",
	ent .. "Wisps/PepperGrinder",
	ent .. "Wisps/DivineWrath",
	ent .. "Wisps/BurntHood",

	ent .. "Locusts/SaltShaker",
	ent .. "Locusts/PepperGrinder",
	ent .. "Locusts/EdithsHood",
	ent .. "Locusts/Sal",
	ent .. "Locusts/SaltHeart",
	ent .. "Locusts/GildedStone",
	ent .. "Locusts/SpicesMix",
	ent .. "Locusts/ChunkOfBasalt",
	ent .. "Locusts/DivineWrath",
	ent .. "Locusts/Hydrargyrum",

	"challenges/Vestige",
	"challenges/Grudge",

	syn .. "BlackPowder",
	syn .. "Brimstone",
	syn .. "ChocolateMilk",
	syn .. "Damage",
	syn .. "FireMind",
	syn .. "FlatStone",
	syn .. "GodHead",
	syn .. "GodsFlesh",
	syn .. "HeadOfTheKeeper",
	syn .. "HolyLight",
	syn .. "JacobsLadder",
	syn .. "Jupiter",
	syn .. "LittleHorn",
	syn .. "MomsKnife",
	syn .. "Neptunus",
	syn .. "OcularRift",
	syn .. "Peppers",
	syn .. "PlaydoughCookie",
	syn .. "SpiritSword",
	syn .. "StatusEffects",
	syn .. "Technology",
	syn .. "TechX",
	syn .. "Effigy",
	syn .. "Rockwaves",
	syn .. "MysteriousLiquid",
	syn .. "DeadEye",
	syn .. "Ludovico",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end
