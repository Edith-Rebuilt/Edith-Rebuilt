CustomHealthAPI.PersistentData.UsingGenesis = CustomHealthAPI.PersistentData.UsingGenesis or false

function CustomHealthAPI.Helper.AddUseGenesisCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.UseGenesisCallback, CollectibleType.COLLECTIBLE_GENESIS)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUseGenesisCallback)

function CustomHealthAPI.Helper.RemoveUseGenesisCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseGenesisCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUseGenesisCallback)

function CustomHealthAPI.Mod:UseGenesisCallback()
	CustomHealthAPI.PersistentData.UsingGenesis = true
	if not REPENTOGON then CustomHealthAPI.PersistentData.GlowingHourglassBackup = CustomHealthAPI.Library.GetHealthBackup() end
end

function CustomHealthAPI.Helper.AddGenesisPlayerInitCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_INIT, CustomHealthAPI.Enums.CallbackPriorities.FIRST, CustomHealthAPI.Mod.GenesisPlayerInit)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddGenesisPlayerInitCallback)

function CustomHealthAPI.Helper.RemoveGenesisPlayerInitCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_INIT, CustomHealthAPI.Mod.GenesisPlayerInit)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveGenesisPlayerInitCallback)

function CustomHealthAPI.Mod:GenesisPlayerInit(player)
	if CustomHealthAPI.PersistentData.UsingGenesis then
		CustomHealthAPI.Helper.ClearPlayerHealthForGenesis(player)
	end
end

function CustomHealthAPI.Helper.ClearPlayerHealthForGenesis(player)
	CustomHealthAPI.Mod:ClearGetDataCache(player)
	CustomHealthAPI.Helper.ClearSavedata(player)
	CustomHealthAPI.Helper.ClearOtherData(player)
	CustomHealthAPI.Helper.ClearCandiesAndLockets(player)
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
end

function CustomHealthAPI.Helper.RunPostGenesisCallbacks()
	CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup = {}
	CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup = {}
	
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_GENESIS, player:GetPlayerType(), player)
	end
	Isaac.RunCallback(CustomHealthAPI.Enums.Callbacks.POST_GENESIS)
end

function CustomHealthAPI.Helper.ClearHealthForGenesis()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.ClearPlayerHealthForGenesis(player)
	end

	CustomHealthAPI.Helper.RunPostGenesisCallbacks()
end
