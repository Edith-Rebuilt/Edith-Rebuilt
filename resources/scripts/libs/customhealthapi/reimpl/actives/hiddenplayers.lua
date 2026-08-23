CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup = CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup or {}
CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup = CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup or {}
CustomHealthAPI.PersistentData.HiddenPlayers = CustomHealthAPI.PersistentData.HiddenPlayers or {}

function CustomHealthAPI.Helper.AddClearHiddenPlayersCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Mod.ClearHiddenPlayersCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddClearHiddenPlayersCallback)

function CustomHealthAPI.Helper.RemoveClearHiddenPlayersCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Mod.ClearHiddenPlayersCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveClearHiddenPlayersCallback)

function CustomHealthAPI.Mod:ClearHiddenPlayersCallback()
	CustomHealthAPI.PersistentData.HiddenPlayers = {}
end

function CustomHealthAPI.Helper.AddFlipCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.FlipCallback, CollectibleType.COLLECTIBLE_FLIP)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddFlipCallback)

function CustomHealthAPI.Helper.RemoveFlipCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.FlipCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveFlipCallback)

function CustomHealthAPI.Mod:FlipCallback(id, rng, player)
	local playertype = player:GetPlayerType()
	if playertype == PlayerType.PLAYER_LAZARUS_B or playertype == PlayerType.PLAYER_LAZARUS2_B then
		local ptrhash = GetPtrHash(player)
		CustomHealthAPI.PersistentData.HiddenPlayers[ptrhash] = EntityRef(player)
		CustomHealthAPI.PersistentData.MantlesToBeReset[player.Index] = true
		CustomHealthAPI.PersistentData.MantlesToBeResetOnPeffect[player.Index] = true

		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[CustomHealthAPI.Helper.GetPlayerIndex(player)] = {Save = CustomHealthAPI.Helper.GetSavedata(player), Persist = CustomHealthAPI.Helper.GetPersistentData(player)}
	end
end

function CustomHealthAPI.Helper.AddEsauJrCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.EsauJrCallback, CollectibleType.COLLECTIBLE_ESAU_JR)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddEsauJrCallback)

function CustomHealthAPI.Helper.RemoveEsauJrCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.EsauJrCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveEsauJrCallback)

function CustomHealthAPI.Mod:EsauJrCallback(id, rng, player)
	local ptrhash = GetPtrHash(player)
	CustomHealthAPI.PersistentData.HiddenPlayers[ptrhash] = EntityRef(player)
	CustomHealthAPI.PersistentData.MantlesToBeReset[player.Index] = true
	CustomHealthAPI.PersistentData.MantlesToBeResetOnPeffect[player.Index] = true
	
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[CustomHealthAPI.Helper.GetPlayerIndex(player)] = {Save = CustomHealthAPI.Helper.GetSavedata(player), Persist = CustomHealthAPI.Helper.GetPersistentData(player)}
	local subplayer = player:GetSubPlayer()
	if subplayer ~= nil then
		CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[CustomHealthAPI.Helper.GetPlayerIndex(player)] = {Save = CustomHealthAPI.Helper.GetSavedata(subplayer), Persist = CustomHealthAPI.Helper.GetPersistentData(subplayer)}
	end
end
