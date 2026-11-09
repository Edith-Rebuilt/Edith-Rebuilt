local mod = EdithRebuilt
local paralellBombsScript = include("resources.scripts.compat.FiendFolio.Bombs.ParalellBombs")

local function FiendFolioCompat()
    mod:AddCallback(paralellBombsScript.callback, paralellBombsScript.func)
end

EdithRebuilt.PatchesLoader.RegisterPatch("FiendFolio", FiendFolioCompat)