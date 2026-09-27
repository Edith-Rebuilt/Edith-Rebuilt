local mod = EdithRebuilt
local loader = {}


---@class Patch
---@field Mod string
---@field PatchFunc function
---@field FailsafeFunc function?
---@field Loaded boolean

loader.Patches = {} 
loader.AppliedPatches = false

-- Registers a mod patch
---@param modName string Name of mod global
---@param patchFunc function Takes 0 arguments and applies the patch
---@param failsafeFunc function?
function loader.RegisterPatch(modName, patchFunc, failsafeFunc)
	table.insert(loader.Patches, { Mod = modName, PatchFunc = patchFunc, FailsafeFunc = failsafeFunc, Loaded = false })
end

---@function
function loader.ApplyPatches()
	for _, patch in pairs(loader.Patches) do
		-- check if mod reference is valid by getting it by name from the table of globals
		-- we cannot directly pass the mod reference to RegisterPatch
		-- and then check for it because that mod reference will be nil
		-- if that mod is loaded after ours
		local modExists
		if type(patch.Mod) == "function" then
			modExists = patch.Mod()
		else
			modExists = _G[patch.Mod]
		end

		if modExists and not patch.Loaded then
			patch.PatchFunc()
			patch.Loaded = true

			-- print(table.concat({ "Loaded", tostring(patch.Mod), "patch" }, " "))
		else
			if patch.FailsafeFunc then
				patch.FailsafeFunc()
			end
		end
	end

	loader.AppliedPatches = true
end

EdithRebuilt.PatchesLoader = loader

local patches = {
	"EID.main",
	"Birthcake",
	"RunicTablet",
	"The Future",
	"contentModules.CommunityRemix.main",
	"Birthwrong.main",
	"contentModules.Epiphany.main",
}

for _, fileName in ipairs(patches) do
	include("resources.scripts.compat." .. fileName)
end

mod:AddPriorityCallback(ModCallbacks.MC_POST_MODS_LOADED, CallbackPriority.LATE, loader.ApplyPatches)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	if not loader.AppliedPatches then
		loader:ApplyPatches()
	end
end)
