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
---@param failsafeFunc function? Takes 0 arguments, called if the mod global is `nil`
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
		else
			if patch.FailsafeFunc then
				patch.FailsafeFunc()
			end
		end
	end

	loader.AppliedPatches = true
end

---@class CompatCallbackEntry
---@field callback ModCallbacks|string
---@field func function
---@field param any?
---@field priority integer?

---@param entry CompatCallbackEntry
---@param modRef? ModReference modreference of the module, defaults to `EdithRebuilt`
function loader.RegisterCallbackEntry(entry, modRef)
	modRef = modRef or mod

	if entry.priority then
		modRef:AddPriorityCallback(entry.callback, entry.priority, entry.func, entry.param)
	else
		modRef:AddCallback(entry.callback, entry.func, entry.param)
	end
end

---@param paths string[]
---@param modRef? ModReference
function loader.LoadScripts(paths, modRef)
	for _, path in ipairs(paths) do
		local script = include(path)

		if not script then goto continue end

		local entries = script.callback and { script } or script

		for _, entry in ipairs(entries) do
			loader.RegisterCallbackEntry(entry, modRef)
		end

		::continue::
	end
end

EdithRebuilt.PatchesLoader = loader

local patches = {
	"EID.main",
	"CommunityRemix.main",
	"Birthwrong.main",
	"FiendFolio.main",
	"Epiphany.main",
	"Birthcake",
	"RunicTablet",
	"TheFuture",
}

for _, fileName in ipairs(patches) do
	include("resources.scripts.compat." .. fileName)
end

mod:AddPriorityCallback(ModCallbacks.MC_POST_MODS_LOADED, CallbackPriority.LATE, loader.ApplyPatches)

local reloadCallbacks = {
	ModCallbacks.MC_POST_RENDER,
	-- ModCallbacks.MC_MAIN_MENU_RENDER,
}

for _, callback in ipairs(reloadCallbacks) do
	mod:AddCallback(callback, function ()
		if loader.AppliedPatches then return end
		loader:ApplyPatches()
	end)
end