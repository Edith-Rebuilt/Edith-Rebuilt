local fiendFolioPath = "resources.scripts.compat.FiendFolio.scripts."

local function FiendFolioCompat()
	EdithRebuilt.PatchesLoader.LoadScripts({
		fiendFolioPath .. "FuzzyPickle",
		fiendFolioPath .. "GirlDinner",
		fiendFolioPath .. "OldTestament",
		fiendFolioPath .. "StackableItems",

		fiendFolioPath .. "Bombs.ParalellBombs",
		fiendFolioPath .. "Bombs.FabergeBombs",
		fiendFolioPath .. "Bombs.BridgeBombs",
		fiendFolioPath .. "Bombs.Musca",

		fiendFolioPath .. "FiendishMark.SodiumSulfate",
	})
end

EdithRebuilt.PatchesLoader.RegisterPatch("FiendFolio", FiendFolioCompat)