-- A lot of this used to use StageAPI as a reference. Thanks DeadInfinity.

CustomHealthAPI.PersistentData.OldCallbackCompatMods = CustomHealthAPI.PersistentData.OldCallbackCompatMods or {}

function CustomHealthAPI.Library.AddCallback(modID, id, priority, fn, ...)
	if type(id) == "number" then
		id = CustomHealthAPI.Enums.CallbacksOldToNew[id] or id 
	end
	
	if id == CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART then
		CustomHealthAPI.Library.AddCallback(modID, CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_RENDER, priority, function(player, playerSlot, healthIndex, info)
			return fn(player, healthIndex, info.OtherHealth, info.RedHealth, info.Filename, info.Animation, info.Color, info.ExtraOffset)
		end, ...)
		return
	elseif id == CustomHealthAPI.Enums.Callbacks.POST_RENDER_HEART then
		CustomHealthAPI.Library.AddCallback(modID, CustomHealthAPI.Enums.Callbacks.POST_HEALTH_RENDER, priority, function(player, playerSlot, healthIndex, info)
			return fn(player, playerSlot, healthIndex, info.OtherHealth, info.RedHealth, info.Filename, info.Animation, info.Color)
		end, ...)
		return
	elseif type(id) == "number" then
		print("Custom Health API Error: Attempted to add callback with unknown ID " .. id .. ".")
		return
	end

	local modName = modID
	if type(modName) == "table" then
		modName = modName.Name or tostring(modName)
	end
	local oldCallbackCompatMod = CustomHealthAPI.PersistentData.OldCallbackCompatMods[modID] or {Mod = RegisterMod("CHAPI (" .. modName .. ")", 1), Callbacks = {}}
	CustomHealthAPI.PersistentData.OldCallbackCompatMods[modID] = oldCallbackCompatMod

	local compatFunc = function(_, ...)
		return fn(...)
	end
	oldCallbackCompatMod.Mod:AddPriorityCallback(id, priority, compatFunc, ...)
	table.insert(oldCallbackCompatMod.Callbacks, {ID = id, Func = compatFunc})
end

function CustomHealthAPI.Library.UnregisterCallbacks(modID)
	local oldCallbackCompatMod = CustomHealthAPI.PersistentData.OldCallbackCompatMods[modID]
	if oldCallbackCompatMod then
		for _, callback in ipairs(oldCallbackCompatMod.Callbacks) do
			oldCallbackCompatMod.Mod:RemoveCallback(callback.ID, callback.Func)
		end
		oldCallbackCompatMod.Callbacks = {}
	end
end

function CustomHealthAPI.Helper.GetCallbacks(id)
	-- deprecated
	return {}
end

-- load callbacks from previous versions of chapi before the system went through basegame's
for id, callbacks in pairs(CustomHealthAPI.PersistentData.Callbacks or {}) do
	for _, callback in pairs(callbacks) do
		CustomHealthAPI.Library.AddCallback(callback.ModID, id, callback.Priority, callback.Function, table.unpack(callback.Params))
	end
end
CustomHealthAPI.PersistentData.Callbacks = {}