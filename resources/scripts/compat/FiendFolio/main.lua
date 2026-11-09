local mod = EdithRebuilt

---@class CompatCallbackEntry
---@field callback ModCallbacks|string
---@field func function
---@field param any?
---@field priority integer?

---@param entry CompatCallbackEntry
local function RegisterEntry(entry)
	if entry.priority then
		mod:AddPriorityCallback(entry.callback, entry.priority, entry.func, entry.param)
	else
		mod:AddCallback(entry.callback, entry.func, entry.param)
	end
end

---@param paths string[]
local function LoadScripts(paths)
	for _, path in ipairs(paths) do
		local script = include(path)
		local entries = script.callback and { script } or script

		for _, entry in ipairs(entries) do
			RegisterEntry(entry)
		end
	end
end

local function FiendFolioCompat()
	LoadScripts({
		"resources.scripts.compat.FiendFolio.Bombs.ParalellBombs",
		"resources.scripts.compat.FiendFolio.Bombs.FabergeBombs",
	})
end

EdithRebuilt.PatchesLoader.RegisterPatch("FiendFolio", FiendFolioCompat)