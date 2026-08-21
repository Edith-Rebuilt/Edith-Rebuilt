function CustomHealthAPI.Library.CanPickHeart(player, pickup)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	local id = pickup.Type
	local var = pickup.Variant
	local subt = pickup.SubType
	
	if id == EntityType.ENTITY_PICKUP then
		local pickupDef = CustomHealthAPI.Library.GetPickupDefinition(var, subt)
		if pickupDef then
			return CustomHealthAPI.Helper.CanCollectCustomPickup(player, pickup, pickupDef)
		end
	end
	
	if CustomHealthAPI.PersistentData.PickupToHeartKeys[id] and 
	   CustomHealthAPI.PersistentData.PickupToHeartKeys[id][var]
	then
		return CustomHealthAPI.Helper.CanPickAnyKey(player, CustomHealthAPI.PersistentData.PickupToHeartKeys[id][var][subt])
	end
end

function CustomHealthAPI.Library.CanPickKey(player, key)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	return CustomHealthAPI.Helper.CanPickKey(player, key)
end

function CustomHealthAPI.Helper.CanPickKey(player, key)
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	
	local canpick = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.CAN_PICK_HEALTH, player:GetPlayerType(), player, key)
	if canpick ~= nil then
		return canpick
	end
	
	if typ == CustomHealthAPI.Enums.HealthTypes.RED then
		return CustomHealthAPI.Helper.CanPickRed(player, key)
	elseif typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
		return CustomHealthAPI.Helper.CanPickSoul(player, key)
	elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		return CustomHealthAPI.Helper.CanPickContainer(player, key)
	elseif typ == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
		return CustomHealthAPI.Helper.CanPickOverlay(player, key)
	end
end

function CustomHealthAPI.Helper.CanPickAnyKey(player, keys)
	for _, key in ipairs(keys or {}) do
		if CustomHealthAPI.Helper.CanPickKey(player, key) then
			return true
		end
	end
end

function CustomHealthAPI.Helper.CanPickRed(player, key)
	if player:GetPlayerType() == PlayerType.PLAYER_BETHANY_B then
		return player:GetBloodCharge() < 99 and key == "RED_HEART"
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CanPickRed(player:GetOtherTwin(), key)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "ROTTEN_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts(player)
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts(player)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) then
		return false
	end
	
	if CustomHealthAPI.Helper.PlayerIsTheSoul(player) then
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			return CustomHealthAPI.Helper.CanPickRed(subplayer, key)
		else
			return false
		end
	end
	
	if CustomHealthAPI.Helper.GetRedCapacity(player) > CustomHealthAPI.Helper.GetTotalRedHP(player, true) then
		return true
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local redMasks = data.RedHealthMasks or {}
	
	local addPriorityOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if health.Key ~= key and
			   addPriorityOfKey >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			then
				return true
			elseif health.HP < CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") then
				return true
			end
		end
	end

	return false
end

function CustomHealthAPI.Helper.CanPickSoul(player, key)
	if player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return player:GetSoulCharge() < 99
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CanPickSoul(player:GetOtherTwin(), key)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "BLACK_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts(player)
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts(player)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			return CustomHealthAPI.Helper.CanPickSoul(subplayer, key)
		else
			return false
		end
	end
	
	local alabasterChargesToAdd = 0
	local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
	for i = 0, 2 do
		if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
		end
	end
	if alabasterChargesToAdd > 0 then
		return true
	end
	
	if CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 then
		return true
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local addPriorityOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if health.Key ~= key and
				   addPriorityOfKey >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				then
					return true
				elseif health.HP < CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") then
					return true
				end
			end
		end
	end

	return false
end

function CustomHealthAPI.Helper.CanPickContainer(player, key)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CanPickContainer(player:GetOtherTwin(), key)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") >= 1 and not CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts(player)
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			return CustomHealthAPI.PersistentData.GetHeartLimit(player) > 0
		elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
			return CustomHealthAPI.PersistentData.GetHeartLimit(player) - math.ceil(CustomHealthAPI.PersistentData.GetMaxHearts / 2) > 0
		else
			return false
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsTheSoul(player) then
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			return CustomHealthAPI.Helper.CanPickContainer(subplayer, key)
		else
			return false
		end
	elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) and
	       CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 0
	then
		return false
	end
	
	if CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 then
		return true
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local addPriorityOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				return true
			elseif CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
				if health.Key ~= key and
				   addPriorityOfKey >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				then
					return true
				end
			end
		end
	end

	return false
end

function CustomHealthAPI.Helper.CanPickOverlay(player, key)
	if key == "ETERNAL_HEART" then
		return true
	end
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "GOLDEN_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts(player)
		else
			return false
		end
	end
	return CustomHealthAPI.Helper.GetRoomInOverlayLayer(player, key) > 0
end
