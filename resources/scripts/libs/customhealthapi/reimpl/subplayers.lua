function CustomHealthAPI.Helper.SplitSubPlayerInfo(player)
	-- THIS FUNCTION HAS BEEN WRITTEN ASSUMING THE PLAYER IS THE FORGOTTEN
	-- IF THEY ARE NOT, WELL FUCK
	
	--[[local maindata = CustomHealthAPI.Helper.GetSavedata(player)
	maindata.SubPlayerInfo = {}
	local subdata = maindata.SubPlayerInfo
	
	local mainRedMasks = maindata.RedHealthMasks
	local subRedMasks = subdata.RedHealthMasks
	for i = #subRedMasks, 1, -1 do
		local mask = subRedMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainRedMasks[i], 1, health)
		end
	end
	
	local mainOtherMasks = maindata.OtherHealthMasks
	local subOtherMasks = subdata.OtherHealthMasks
	for i = #subOtherMasks, 1, -1 do
		local mask = subOtherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainOtherMasks[i], 1, health)
		end
	end
	
	local mainOverlays = maindata.Overlays
	local subOverlays = subdata.Overlays
	for k,v in subOverlays do
		mainOverlays[k] = mainOverlays[k] + v
		if k == "ETERNAL_HEART" then
			mainOverlays[k] = mainOverlays[k] % 2
		end
	end]]--
end

function CustomHealthAPI.Helper.CollapseSubPlayerInfo(player)
	-- THIS FUNCTION HAS BEEN WRITTEN ASSUMING THE PLAYER WAS THE FORGOTTEN
	-- IF THEY ARE NOT, WELL FUCK
	
	--[[local maindata = CustomHealthAPI.Helper.GetSavedata(player)
	local subdata = maindata.SubPlayerInfo
	
	if maindata.MainPlayerType == PlayerType.PLAYER_THESOUL then
		local temp = maindata
		maindata = subdata
		subdata = temp
	end
	
	local mainRedMasks = maindata.RedHealthMasks
	local subRedMasks = subdata.RedHealthMasks
	for i = #subRedMasks, 1, -1 do
		local mask = subRedMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainRedMasks[i], 1, health)
		end
	end
	
	local mainOtherMasks = maindata.OtherHealthMasks
	local subOtherMasks = subdata.OtherHealthMasks
	for i = #subOtherMasks, 1, -1 do
		local mask = subOtherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainOtherMasks[i], 1, health)
		end
	end
	
	local mainOverlays = maindata.Overlays
	local subOverlays = subdata.Overlays
	for k, v in pairs(subOverlays) do
		mainOverlays[k] = mainOverlays[k] + v
		if k == "ETERNAL_HEART" then
			mainOverlays[k] = mainOverlays[k] % 2
		end
	end
	
	CustomHealthAPI.Helper.GetSavedata(player) = maindata
	maindata.SubPlayerInfo = nil
	maindata.MainPlayerIndex = nil
	maindata.SubPlayerIndex = nil
	maindata.MainPlayerType = nil
	maindata.SubPlayerType = nil]]--
end

function CustomHealthAPI.Helper.CheckIfSwapSubPlayerInfo(player)
	local maindata = CustomHealthAPI.Helper.GetSavedata(player)
	local subdata = CustomHealthAPI.Helper.GetSavedata(player:GetSubPlayer())
	
	local expectedPlayerType = maindata.PlayerType
	local expectedSubplayerType = subdata.PlayerType
	
	local actualPlayerType = player:GetPlayerType()
	local actualSubplayerType = player:GetSubPlayer():GetPlayerType()
	
	if expectedPlayerType == actualSubplayerType and expectedSubplayerType == actualPlayerType then
		CustomHealthAPI.Helper.SetSavedata(player, subdata)
		CustomHealthAPI.Helper.SetSavedata(player:GetSubPlayer(), maindata)
		
		local mainqueued = maindata.CurrentQueuedItem
		local subqueued = subdata.CurrentQueuedItem
		
		maindata.CurrentQueuedItem = subqueued
		subdata.CurrentQueuedItem = mainqueued
		
		local mainotherdata = CustomHealthAPI.Helper.GetOtherData(player)
		local subotherdata = CustomHealthAPI.Helper.GetOtherData(player:GetSubPlayer())
		
		CustomHealthAPI.Helper.SetOtherData(player, subotherdata)
		CustomHealthAPI.Helper.SetOtherData(player:GetSubPlayer(), mainotherdata)
	end
end

function CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end

	local data = CustomHealthAPI.Helper.GetSavedata(player)
	--[[if player:GetSubPlayer() ~= nil and data.SubPlayerInfo == nil then
		CustomHealthAPI.Helper.SplitSubPlayerInfo(player)
	elseif player:GetSubPlayer() == nil and data.SubPlayerInfo ~= nil then
		CustomHealthAPI.Helper.CollapseSubPlayerInfo(player)
	end]]--
	
	local subplayer = player:GetSubPlayer()
	if subplayer ~= nil and CustomHealthAPI.Helper.GetSavedata(subplayer) ~= nil then
		CustomHealthAPI.Helper.CheckIfSwapSubPlayerInfo(player)
	end
end

function CustomHealthAPI.Helper.CheckSubPlayerInfo()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	end
end
