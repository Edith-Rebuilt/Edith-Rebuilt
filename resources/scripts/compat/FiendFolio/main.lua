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
		
		if not script then goto continue end

		local entries = script.callback and { script } or script

		for _, entry in ipairs(entries) do
			RegisterEntry(entry)
		end

		::continue::
	end
end

local fiendFolioPath = "resources.scripts.compat.FiendFolio."

local function FiendFolioCompat()
	LoadScripts({
		fiendFolioPath .. "FuzzyPickle",

		fiendFolioPath .. "Bombs.ParalellBombs",
		fiendFolioPath .. "Bombs.FabergeBombs",
		fiendFolioPath .. "Bombs.BridgeBombs",
	})
end

EdithRebuilt.PatchesLoader.RegisterPatch("FiendFolio", FiendFolioCompat)