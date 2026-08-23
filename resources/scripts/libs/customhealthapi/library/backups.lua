local json = require("json")

function CustomHealthAPI.Library.GetHealthBackup(p)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	
	local savetable = {}
	savetable.Mainplayers = {}
	savetable.Subplayers = {}
	
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local subplayer = player:GetSubPlayer()
		if p == nil or (CustomHealthAPI.Helper.GetPlayerIndex(player) == CustomHealthAPI.Helper.GetPlayerIndex(p)) then
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
				CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
				CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
			end
			savetable.Mainplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)] = {Save = CustomHealthAPI.Helper.GetSavedata(player), Persist = CustomHealthAPI.Helper.GetPersistentData(player)}
			if subplayer ~= nil then
				CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(subplayer)
				if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
					CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(subplayer)
					CustomHealthAPI.Helper.ResyncHealthOfPlayer(subplayer)
				end
				savetable.Subplayers[CustomHealthAPI.Helper.GetPlayerIndex(subplayer)] = {Save = CustomHealthAPI.Helper.GetSavedata(subplayer), Persist = CustomHealthAPI.Helper.GetPersistentData(subplayer)}
			end
			if p ~= nil then break end
		end
	end
	
	if p == nil then
		savetable.Hidden = CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup
		savetable.HiddenSub = CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup
		savetable.RestockInfo = CustomHealthAPI.PersistentData.RestockInfo
	end
	
	local backup = json.encode(savetable)
	return backup
end

function CustomHealthAPI.Library.LoadHealthFromBackup(backup,p)
	if backup == nil then
		return
	end

	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	
	local savetable = json.decode(backup)
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local subplayer = player:GetSubPlayer()
		if p == nil or (CustomHealthAPI.Helper.GetPlayerIndex(player) == CustomHealthAPI.Helper.GetPlayerIndex(p)) then
			local healthData = savetable.Mainplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)]
			if healthData ~= nil then
				CustomHealthAPI.Helper.LoadHealthOfPlayerFromBackup(player, healthData)
			end
			
			if subplayer ~= nil then
				local subHealthData = savetable.Subplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)]
				if subHealthData ~= nil then
					CustomHealthAPI.Helper.LoadHealthOfPlayerFromBackup(subplayer, subHealthData)
				end
			end
			if p ~= nil then break end
		end
	end
	
	if p == nil then
		CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup = savetable.Hidden or CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup
		CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup = savetable.HiddenSub or CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup
		CustomHealthAPI.PersistentData.RestockInfo = savetable.RestockInfo or CustomHealthAPI.PersistentData.RestockInfo
	end
end

function CustomHealthAPI.Helper.LoadHealthOfPlayerFromBackup(player, healthData)
	CustomHealthAPI.Helper.SetSavedata(player, healthData["Save"])
	CustomHealthAPI.Helper.SetPersistentData(player, healthData["Persist"])
	
	if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.HandleUnexpectedMax(player)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	end
	
	player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
	                     CacheFlag.CACHE_FIREDELAY | 
	                     CacheFlag.CACHE_SPEED | 
	                     CacheFlag.CACHE_SHOTSPEED | 
	                     CacheFlag.CACHE_RANGE | 
	                     CacheFlag.CACHE_LUCK)
	
	player:EvaluateItems()
	
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_LOAD_HEALTH_FROM_BACKUP, player:GetPlayerType(), player)
end
