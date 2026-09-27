
local function BirthwrongCompat()
    include("resources.scripts.compat.Birthwrong.Edith")
    include("resources.scripts.compat.Birthwrong.TEdith")
end

EdithRebuilt.PatchesLoader.RegisterPatch("Birthwrong", BirthwrongCompat)