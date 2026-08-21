function CustomHealthAPI.Library.GetHPOfKey(player, key, byActualHP, byBasegameHP, ignoreResyncing, ignoreHPCache)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if not ignoreResyncing then 
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.GetHPOfKey(player:GetOtherTwin(), key, byActualHP, byBasegameHP)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "RED_HEART" or 
		   (CustomHealthAPI.Helper.PlayerHasCoinHealth(player) and key == "COIN_HEART")
		then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
		elseif key == "ROTTEN_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
		elseif key == "SOUL_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		elseif key == "BLACK_HEART" then
			return CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		elseif key == "EMPTY_HEART" or 
		   (CustomHealthAPI.Helper.PlayerHasCoinHealth(player) and key == "EMPTY_COIN_HEART")
		then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		elseif key == "BONE_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		elseif key == "ETERNAL_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
		elseif key == "GOLDEN_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
		elseif key == "BROKEN_HEART" or 
		   (CustomHealthAPI.Helper.PlayerHasCoinHealth(player) and key == "BROKEN_COIN_HEART")
		then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		else
			return 0
		end
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if CustomHealthAPI.Library.GetInfoOfKey(key, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") == CustomHealthAPI.Enums.HealthKinds.NONE
		then
			data.Cached.HPOfKey = data.Cached.HPOfKey or {}
			if data.Cached.HPOfKey[key] ~= nil then
				return data.Cached.HPOfKey[key]
			end
		elseif byActualHP then
			data.Cached.HPOfKeyActual = data.Cached.HPOfKeyActual or {}
			if data.Cached.HPOfKeyActual[key] ~= nil then
				return data.Cached.HPOfKeyActual[key]
			end
		elseif byBasegameHP then
			data.Cached.HPOfKeyBasegame = data.Cached.HPOfKeyBasegame or {}
			if data.Cached.HPOfKeyBasegame[key] ~= nil then
				return data.Cached.HPOfKeyBasegame[key]
			end
		else
			data.Cached.HPOfKey = data.Cached.HPOfKey or {}
			if data.Cached.HPOfKey[key] ~= nil then
				return data.Cached.HPOfKey[key]
			end
		end
	end
	
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	if typ == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
		if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") > 0 then
			return CustomHealthAPI.Helper.GetTotalHPOfKey(player, key, ignoreHPCache)
		else
			return CustomHealthAPI.Helper.GetTotalKeys(player, key, ignoreHPCache)
		end
	elseif typ == CustomHealthAPI.Enums.HealthTypes.RED then
		local redHealthMasks = data.RedHealthMasks or {}
		
		local totalRedHP = 0
		for i = 1, #redHealthMasks do
			local mask = redHealthMasks[i]
			for j = 1, #mask do
				if mask[j].Key == key then
					local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP")
					if byActualHP then
						totalRedHP = totalRedHP + mask[j].HP
					elseif byBasegameHP then
						if mask[j].HP >= maxHpOfHealth then
							totalRedHP = totalRedHP + 2
						else
							totalRedHP = totalRedHP + 1
						end
					else
						if maxHpOfHealth <= 1 then
							totalRedHP = totalRedHP + 2
						else
							totalRedHP = totalRedHP + mask[j].HP
						end
					end
				end
			end
		end
		
		if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
			if byActualHP then
				data.Cached.HPOfKeyActual[key] = totalRedHP
			elseif byBasegameHP then
				data.Cached.HPOfKeyBasegame[key] = totalRedHP
			else
				data.Cached.HPOfKey[key] = totalRedHP
			end
		end
		
		return totalRedHP
	elseif typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
		local otherHealthMasks = data.OtherHealthMasks or {}
		
		local totalSoulHP = 0
		for i = 1, #otherHealthMasks do
			local mask = otherHealthMasks[i]
			for j = 1, #mask do
				if mask[j].Key == key then
					local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP")
					if byActualHP then
						totalSoulHP = totalSoulHP + mask[j].HP
					elseif byBasegameHP then
						if mask[j].HP >= maxHpOfHealth then
							totalSoulHP = totalSoulHP + 2
						else
							totalSoulHP = totalSoulHP + 1
						end
					else
						if maxHpOfHealth <= 1 then
							totalSoulHP = totalSoulHP + 2
						else
							totalSoulHP = totalSoulHP + mask[j].HP
						end
					end
				end
			end
		end
		
		if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
			if byActualHP then
				data.Cached.HPOfKeyActual[key] = totalSoulHP
			elseif byBasegameHP then
				data.Cached.HPOfKeyBasegame[key] = totalSoulHP
			else
				data.Cached.HPOfKey[key] = totalSoulHP
			end
		end
		
		return totalSoulHP
	elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		local kindContained = CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained")
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local canHaveHalfCapacity = CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity")
		
		if kindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			local otherHealthMasks = data.OtherHealthMasks or {}
			
			local totalMaxHP = 0
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					if mask[j].Key == key then
						totalMaxHP = totalMaxHP + 1
					end
				end
			end
			
			if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
				data.Cached.HPOfKey[key] = totalMaxHP
			end
			
			return totalMaxHP
		elseif maxHP >= 1 then
			local otherHealthMasks = data.OtherHealthMasks or {}
			
			local totalMaxHP = 0
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					if mask[j].Key == key then
						if byActualHP then
							totalMaxHP = totalMaxHP + mask[j].HP
						elseif byBasegameHP then
							totalMaxHP = totalMaxHP + 1
						else
							totalMaxHP = totalMaxHP + mask[j].HP
						end
					end
				end
			end
			
			if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
				if byActualHP then
					data.Cached.HPOfKeyActual[key] = totalMaxHP
				elseif byBasegameHP then
					data.Cached.HPOfKeyBasegame[key] = totalMaxHP
				else
					data.Cached.HPOfKey[key] = totalMaxHP
				end
			end
			
			return totalMaxHP
		else
			local otherHealthMasks = data.OtherHealthMasks or {}
			
			local totalMaxHP = 0
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					if mask[j].Key == key then
						local hasHalfCapacity = mask[j].HalfCapacity
						if byActualHP then
							if hasHalfCapacity then
								totalMaxHP = totalMaxHP + 1
							else
								totalMaxHP = totalMaxHP + 2
							end
						elseif byBasegameHP then
							if hasHalfCapacity then
								totalMaxHP = totalMaxHP + 1
							else
								totalMaxHP = totalMaxHP + 2
							end
						else
							if canHaveHalfCapacity then
								if hasHalfCapacity then
									totalMaxHP = totalMaxHP + 1
								else
									totalMaxHP = totalMaxHP + 2
								end
							else
								totalMaxHP = totalMaxHP + 1
							end
						end
					end
				end
			end
			
			if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
				if byActualHP then
					data.Cached.HPOfKeyActual[key] = totalMaxHP
				elseif byBasegameHP then
					data.Cached.HPOfKeyBasegame[key] = totalMaxHP
				else
					data.Cached.HPOfKey[key] = totalMaxHP
				end
			end
			
			return totalMaxHP
		end
	else 
		return 0
	end
end

function CustomHealthAPI.Library.ClearHPCache(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if data then
		data.Cached = {}
	end
end

function CustomHealthAPI.Helper.GetTotalHP(player, ignoreHPCache, includeOverlayHP)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) + 
		       CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player) + 
		       CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if data.Cached.TotalHP ~= nil then
			return data.Cached.TotalHP
		end
	end
	
	local totalHP = 0
	
	local redHealthMasks = data.RedHealthMasks or {}
	local otherHealthMasks = data.OtherHealthMasks or {}
	
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			totalHP = totalHP + mask[j].HP
		end
	end
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			totalHP = totalHP + mask[j].HP
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached.TotalHP = totalHP
	end
	
	if includeOverlayHP then
		totalHP = totalHP + CustomHealthAPI.Helper.GetTotalOverlayHP(player, ignoreHPCache)
	end
	
	return totalHP
end

function CustomHealthAPI.Helper.GetTotalHeartCount(player, isRealCount)
	local numOther = 0
	local ignoredHealth = 0
	if CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
		numOther = 0
	elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		numOther = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) + 
		           CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	else
		numOther = #(CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player))
	end
	
	local ignoredHealth = 0
	if not isRealCount then
		local numLives = player:GetExtraLives()
		local isChance = false
		if REPENTOGON then
			if player:HasChanceRevive() then
				isChance = true
			end
		else
			if player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) or player:HasTrinket(TrinketType.TRINKET_BROKEN_ANKH) then
				isChance = true
			end
		end

		if CustomHealthAPI.PersistentData.CombineLivesOfTwins[player:GetPlayerType()] then
			local twin = player:GetOtherTwin()
			if twin then
				numLives = numLives + twin:GetExtraLives()
				if REPENTOGON then
					if twin:HasChanceRevive() then
						isChance = true
					end
				else
					if twin:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) or twin:HasTrinket(TrinketType.TRINKET_BROKEN_ANKH) then
						isChance = true
					end
				end
			end
		end

		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		local returnTable = CustomHealthAPI.Helper.RunPreRenderLivesCallback(nil, player, numLives, isChance, ignoredHealth)
		if returnTable ~= nil then
			if returnTable.Prevent == true then
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
				return
			end
			if returnTable.Lives ~= nil then
				numLives = returnTable.Lives
			end
			if returnTable.IsChance ~= nil then
				isChance = returnTable.IsChance
			end
			if returnTable.Force ~= nil then
				overrideLivesCheck = returnTable.Force
			end
			if returnTable.IgnoreNumHearts ~= nil then
				ignoredHealth = returnTable.IgnoreNumHearts
			end
			if returnTable.Offset ~= nil then
				renderOffset = returnTable.Offset
			end
		end
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	end
	
	return math.max(0, numOther - ignoredHealth)
end

function CustomHealthAPI.Helper.GetTotalOverlayHP(player, ignoreHPCache)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if data.Cached.TotalOverlayHP ~= nil then
			return data.Cached.TotalOverlayHP
		end
	end
	
	local totalHP = 0
	
	for overlayLayerIndex, overlayLayer in ipairs(data.OverlayHealthMaskLayers) do
		for overlayMaskIndex, overlayIndexInMask, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, false) do
			totalHP = totalHP + overlay.HP
		end
	end
	
	return totalHP
end

function CustomHealthAPI.Helper.GetTotalRedHP(player, basegameFormat, getFormat, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if basegameFormat then
			if data.Cached.TotalRedHPBasegame ~= nil then
				return data.Cached.TotalRedHPBasegame
			end
		elseif getFormat then
			if data.Cached.TotalRedHPGet ~= nil then
				return data.Cached.TotalRedHPGet
			end
		else
			if data.Cached.TotalRedHP ~= nil then
				return data.Cached.TotalRedHP
			end
		end
	end
	
	local totalRedHP = 0
	
	local redHealthMasks = data.RedHealthMasks or {}
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			if basegameFormat then
				if mask[j].HP >= CustomHealthAPI.PersistentData.HealthDefinitions[mask[j].Key].MaxHP then
					totalRedHP = totalRedHP + 2
				else
					totalRedHP = totalRedHP + 1
				end
			elseif getFormat then
				if CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP") <= 1 then
					totalRedHP = totalRedHP + 2
				else
					totalRedHP = totalRedHP + mask[j].HP
				end
			else
				totalRedHP = totalRedHP + mask[j].HP
			end
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		if basegameFormat then
			data.Cached.TotalRedHPBasegame = totalRedHP
		elseif getFormat then
			data.Cached.TotalRedHPGet = totalRedHP
		else
			data.Cached.TotalRedHP = totalRedHP
		end
	end
	
	return totalRedHP
end

function CustomHealthAPI.Helper.GetTotalSoulHP(player, basegameFormat, getFormat, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if basegameFormat then
			if data.Cached.TotalSoulHPBasegame ~= nil then
				return data.Cached.TotalSoulHPBasegame
			end
		elseif getFormat then
			if data.Cached.TotalSoulHPGet ~= nil then
				return data.Cached.TotalSoulHPGet
			end
		else
			if data.Cached.TotalSoulHP ~= nil then
				return data.Cached.TotalSoulHP
			end
		end
	end
	
	local totalSoulHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks or {}
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if basegameFormat then
					if health.HP >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP then
						totalSoulHP = totalSoulHP + 2
					else
						totalSoulHP = totalSoulHP + 1
					end
				elseif getFormat then
					if CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP") <= 1 then
						totalSoulHP = totalSoulHP + 2
					else
						totalSoulHP = totalSoulHP + health.HP
					end
				else
					totalSoulHP = totalSoulHP + health.HP
				end
			end
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		if basegameFormat then
			data.Cached.TotalSoulHPBasegame = totalSoulHP
		elseif getFormat then
			data.Cached.TotalSoulHPGet = totalSoulHP
		else
			data.Cached.TotalSoulHP = totalSoulHP
		end
	end
	
	return totalSoulHP
end

function CustomHealthAPI.Helper.GetTotalMaxHP(player, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if data.Cached.TotalMaxHP ~= nil then
			return data.Cached.TotalMaxHP
		end
	end
	
	local totalMaxHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks or {}
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0
			then
				if health.HalfCapacity then
					totalMaxHP = totalMaxHP + 1
				else
					totalMaxHP = totalMaxHP + 2
				end
			end
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached.TotalMaxHP = totalMaxHP
	end
	
	return totalMaxHP
end

function CustomHealthAPI.Helper.GetTotalBoneHP(player, basegameFormat, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if basegameFormat then
			if data.Cached.TotalBoneHPBasegame ~= nil then
				return data.Cached.TotalBoneHPBasegame
			end
		else
			if data.Cached.TotalBoneHP ~= nil then
				return data.Cached.TotalBoneHP
			end
		end
	end
	
	local totalBoneHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks or {}
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0
			then
				if basegameFormat then
					totalBoneHP = totalBoneHP + 1
				else
					totalBoneHP = totalBoneHP + health.HP
				end
			end
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if basegameFormat then
			data.Cached.TotalBoneHPBasegame = totalBoneHP
		else
			data.Cached.TotalBoneHP = totalBoneHP
		end
	end
	
	return totalBoneHP
end

function CustomHealthAPI.Helper.GetTotalBrokenHP(player, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		if data.Cached.TotalBrokenHP ~= nil then
			return data.Cached.TotalBrokenHP
		end
	end
	
	local totalBrokenHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks or {}
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			then
				totalBrokenHP = totalBrokenHP + 1
			end
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		data.Cached.TotalBrokenHP = totalBrokenHP
	end
	
	return totalBrokenHP
end

function CustomHealthAPI.Helper.GetTotalHPOfKey(player, key, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		data.Cached.TotalHPOfKey = data.Cached.TotalHPOfKey or {}
		if data.Cached.TotalHPOfKey[key] ~= nil then
			return data.Cached.TotalHPOfKey[key]
		end
	end
	
	local totalHP = 0
	local def = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local isMaxHP = def.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
	                def.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
	                def.MaxHP == 0
	local isBrokenHP = def.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
	                   def.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	local isOverlayHP = def.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY
	for _, health in ipairs(CustomHealthAPI.Helper.GetMaskForKey(player, key)) do
		if health.Key == key then
			if isOverlayHP then
				if def.MaxHP > 0 then
					totalHP = totalHP + health.HP
				else
					totalHP = totalHP + 1
				end
			elseif isBrokenHP then
				totalHP = totalHP + 1
			elseif isMaxHP then
				if health.HalfCapacity then
					totalHP = totalHP + 1
				else
					totalHP = totalHP + 2
				end
			else
				totalHP = totalHP + health.HP
			end
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached.TotalHPOfKey[key] = totalHP
	end
	
	return totalHP
end

function CustomHealthAPI.Helper.GetTotalKeys(player, key, ignoreHPCache)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		data.Cached.TotalKeys = data.Cached.TotalKeys or {}
		if data.Cached.TotalKeys[key] ~= nil then
			return data.Cached.TotalKeys[key]
		end
	end
	
	local totalHealth = 0
	
	for _, health in ipairs(CustomHealthAPI.Helper.GetMaskForKey(player, key)) do
		if health.Key == key then
			totalHealth = totalHealth + 1
		end
	end
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached.TotalKeys[key] = totalHealth
	end
	
	return totalHealth
end

function CustomHealthAPI.Helper.GetTotalKeysInAllMasks(player, maskSet)
	local count = 0
	for maskIdx, hpIdx, health in CustomHealthAPI.Helper.GetHealthMasksIterator(maskSet, false) do
		count = count + 1
	end
	return count
end

function CustomHealthAPI.Helper.GetRedCapacity(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	local totalCapacity = 0
	local otherHealthMasks = data.OtherHealthMasks or {}
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
				totalCapacity = totalCapacity + ((health.HalfCapacity and 1) or 2)
			end
		end
	end
	
	return totalCapacity
end

function CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	local totalContainers = 0
	local otherHealthMasks = data.OtherHealthMasks or {}
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
				totalContainers = totalContainers + 1
			end
		end
	end
	
	local totalRed = 0
	local redHealthMasks = data.RedHealthMasks or {}
	
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			totalRed = totalRed + 1
		end
	end
	
	return totalContainers - totalRed
end

function CustomHealthAPI.Helper.GetHealableRedHP(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	local totalHealableRedHP = 0
	
	local redHealthMasks = data.RedHealthMasks or {}
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			totalHealableRedHP = totalHealableRedHP + (CustomHealthAPI.PersistentData.HealthDefinitions[mask[j].Key].MaxHP - mask[j].HP)
		end
	end
	
	return totalHealableRedHP
end

function CustomHealthAPI.Helper.GetHealableSoulHP(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	local totalHealableSoulHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks or {}
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				totalHealableSoulHP = totalHealableSoulHP + (CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP - health.HP)
			end
		end
	end
	
	return totalHealableSoulHP
end

if REPENTOGON then
	function CustomHealthAPI.Helper.AddHeartLimitCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, CustomHealthAPI.Enums.CallbackPriorities.EARLY, CustomHealthAPI.Mod.HeartLimitCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHeartLimitCallback)

	function CustomHealthAPI.Helper.RemoveHeartLimitCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, CustomHealthAPI.Mod.HeartLimitCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHeartLimitCallback)

	function CustomHealthAPI.Mod:HeartLimitCallback(player)
		local newCap = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.GET_MAX_HP_CAP, player:GetPlayerType(), player)
		if newCap ~= nil then
			return newCap
		end
	end
end

function CustomHealthAPI.Helper.GetTrueHeartLimit(player)
	if not REPENTOGON then
		local newCap = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.GET_MAX_HP_CAP, player:GetPlayerType(), player)
		if newCap ~= nil then
			return newCap
		end
	end

	local limit = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player)
	local brokenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
	return limit + brokenHearts * 2
end

function CustomHealthAPI.Helper.GetRoomForOtherKeys(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	local limit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	
	local otherHealthMasks = data.OtherHealthMasks or {}
	
	local totalOther = 0
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			totalOther = totalOther + 1
		end
	end
	
	return limit - totalOther
end

function CustomHealthAPI.Helper.GetNumOverlayableHearts(player, overlayLayerIndex)
	if not overlayLayerIndex then
		overlayLayerIndex = "GOLDEN_HEART"
	end
	if type(overlayLayerIndex) == "string" then
		overlayLayerIndex = CustomHealthAPI.PersistentData.HealthDefinitions[overlayLayerIndex].OverlayLayerIndex
	end
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	
	local numOverlayable = 0
	
	local redIterator = CustomHealthAPI.Helper.GetHealthMasksIterator(data.RedHealthMasks, false)
	
	for maskIdx, hpIdx, health in CustomHealthAPI.Helper.GetHealthMasksIterator(data.OtherHealthMasks, false) do
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		local hasRedHealth = healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   healthDef.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and redIterator() ~= nil
		
		if CustomHealthAPI.Helper.CanOverlayHealthAtLayer(health.Key, hasRedHealth, overlayLayerIndex) then
			numOverlayable = numOverlayable + 1
		end
	end
	
	return numOverlayable
end

function CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
	local blackNum = 0
	local blackMask = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts(player)
	while blackMask > 0 do
		if blackMask % 2 == 1 then
			blackNum = blackNum + 1
		end
		blackMask = blackMask >> 1
	end
	return blackNum
end

function CustomHealthAPI.Helper.DoesContainerHaveRedHP(player, key, ignoreHPCache)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if not ignoreResyncing then 
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.GetHPOfKey(player:GetOtherTwin(), key, byActualHP, byBasegameHP)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		local numRed = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) / 2)
		local numMax = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2)
		local numBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		if key == "EMPTY_HEART" or 
		   (CustomHealthAPI.Helper.PlayerHasCoinHealth(player) and key == "EMPTY_COIN_HEART")
		then
			return numMax > 0 and numRed > 0
		elseif key == "BONE_HEART" then
			return numBone > 0 and numRed - numMax > 0
		else
			return false
		end
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		data.Cached.KeyHasRedHP = data.Cached.KeyHasRedHP or {}
		if data.Cached.KeyHasRedHP[key] ~= nil then
			return data.Cached.KeyHasRedHP[key]
		end
	end
	
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		local kindContained = CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained")
		local canHaveHalfCapacity = CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity")
		
		if kindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
			local remainingRed = 0
			local redHealthMasks = data.RedHealthMasks
			
			for i = 1, #redHealthMasks do
				local mask = redHealthMasks[i]
				for j = 1, #mask do
					remainingRed = remainingRed + 1
				end
			end
			
			local hasRedHP = false
			local otherHealthMasks = data.OtherHealthMasks
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					local health = mask[j]
					local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
					if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
						if health.Key == key then
							hasRedHP = remainingRed > 0
							break
						else
							remainingRed = remainingRed - 1
						end
					end
				end
			end
			
			if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
				data.Cached.KeyHasRedHP[key] = hasRedHP
			end
			
			return hasRedHP
		end
	end
	
	data.Cached.KeyHasRedHP[key] = false
	return false
end

function CustomHealthAPI.Helper.GetLowestPriorityRedKeyInContainer(player, key, ignoreHPCache)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if not ignoreResyncing then 
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.GetLowestPriorityRedKeyInContainer(player:GetOtherTwin(), key, ignoreHPCache)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		local numRotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
		local numRed = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) / 2) - numRotten
		local numMax = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2)
		local numBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) and key == "EMPTY_COIN_HEART" then
			if numMax > 0 then
				return (numRed > 0 and "RED_HEART") or nil
			else
				return nil
			end
		elseif key == "EMPTY_HEART" then
			if numMax > 0 then
				if numRed > 0 then
					return "RED_HEART"
				elseif numRotten > 0 then
					return "ROTTEN_HEART"
				else
					return nil
				end
			else
				return nil
			end
		elseif key == "BONE_HEART" then
			while numMax > 0 do
				if numRed > 0 then
					numRed = numRed - 1
				elseif numRotten > 0 then
					numRotten = numRotten - 1
				end
				numMax = numMax - 1
			end
			if numBone > 0 then
				if numRed > 0 then
					return "RED_HEART"
				elseif numRotten > 0 then
					return "ROTTEN_HEART"
				else
					return nil
				end
			else
				return nil
			end
		else
			return nil
		end
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	
	if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
		data.Cached = data.Cached or {}
		data.Cached.EarliestRedKeyInKey = data.Cached.EarliestRedKeyInKey or {}
		data.Cached.HasCheckedEarliestRedKeyInKey = data.Cached.HasCheckedEarliestRedKeyInKey or {}
		if data.Cached.HasCheckedEarliestRedKeyInKey[key] then
			return data.Cached.EarliestRedKeyInKey[key]
		end
	end
	
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		local kindContained = CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained")
		local canHaveHalfCapacity = CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity")
		
		if kindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
			local redKeys = {}
			local redHealthMasks = data.RedHealthMasks
			
			for i = 1, #redHealthMasks do
				local mask = redHealthMasks[i]
				for j = 1, #mask do
					table.insert(redKeys, mask[j].Key)
				end
			end
			
			local lowestRedKey = nil
			local lowestRedPriority = math.huge
			local otherHealthMasks = data.OtherHealthMasks
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					local health = mask[j]
					local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
					if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
						if health.Key == key then
							local redKey = redKeys[1]
							if redKey then
								local redPriority = CustomHealthAPI.Library.GetInfoOfKey(redKey, "AddPriority")
								if redPriority <= lowestRedPriority then
									lowestRedKey = redKey
									lowestRedPriority = redPriority
								end
							end
						end
						table.remove(redKeys, 1)
					end
				end
			end
			
			if not (CustomHealthAPI.PersistentData.PreventGetHPCaching or ignoreHPCache) then
				data.Cached.EarliestRedKeyInKey[key] = lowestRedKey
				data.Cached.HasCheckedEarliestRedKeyInKey[key] = true
			end
			
			return lowestRedKey
		end
	end
	
	data.Cached.EarliestRedKeyInKey[key] = nil
	data.Cached.HasCheckedEarliestRedKeyInKey[key] = true
	return nil
end