if REPENTOGON then
function CustomHealthAPI.Helper.AddInitializeHealthCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, CustomHealthAPI.Mod.InitializeHealthCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddInitializeHealthCallback)

function CustomHealthAPI.Helper.RemoveInitializeHealthCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, CustomHealthAPI.Mod.InitializeHealthCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveInitializeHealthCallback)

function CustomHealthAPI.Mod:InitializeHealthCallback(player)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
end
end

function CustomHealthAPI.Helper.InitializeRedHealthMasks(player)
	local total = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local rotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	local red = total - (rotten * 2)
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "ROTTEN_HEART", rotten * 2, true, false, false, true, true)
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", red, true, false, false, true, true)
	
	--[[local data = CustomHealthAPI.Helper.GetSavedata(player, true)
	
	local order = CustomHealthAPI.Helper.GetRedHealthOrder()
	data.RedHealthMasks = {}
	
	local isKeeper = CustomHealthAPI.Helper.PlayerHasCoinHealth(player)
	for i = 1, #order do
		local sort = order[i]
		data.RedHealthMasks[i] = {}

		for j = 1, #sort do
			if sort[j] == "RED_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2
				while numHearts > 0 do
					table.insert(data.RedHealthMasks[i], {Key = "RED_HEART", HP = (numHearts >= 2 and 2) or 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "COIN_HEART" and isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
				while numHearts > 0 do
					table.insert(data.RedHealthMasks[i], {Key = "COIN_HEART", HP = (numHearts >= 2 and 2) or 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "ROTTEN_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
				while numHearts > 0 do
					table.insert(data.RedHealthMasks[i], {Key = "ROTTEN_HEART", HP = 1})
					numHearts = numHearts - 1
				end
			end
		end
	end]]--
end

function CustomHealthAPI.Helper.InitializeOtherHealthMasks(player)
	local totalSoul = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
	local bone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
	
	local soulIndex = 0
	local soulSkippedIndices = 0
	while totalSoul > 0 or bone > 0 do
		if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 1)
			bone = bone - 1
			soulSkippedIndices = soulSkippedIndices + 1
		elseif CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, (soulIndex - soulSkippedIndices) * 2 + 1) then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", math.min(2, totalSoul), false, false, true)
			totalSoul = totalSoul - 2
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", math.min(2, totalSoul), false, false, true)
			totalSoul = totalSoul - 2
		end
		soulIndex = soulIndex + 1
	end
	
	local empty = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local broken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", math.ceil(empty / 2) * 2)
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", broken)
	
	--[[local data = CustomHealthAPI.Helper.GetSavedata(player, true)
	
	local order = CustomHealthAPI.Helper.GetOtherHealthOrder()
	data.OtherHealthMasks = {}
	
	local isKeeper = CustomHealthAPI.Helper.PlayerHasCoinHealth(player)
	for i = 1, #order do
		local sort = order[i]
		data.OtherHealthMasks[i] = {}
		for j = 1, #sort do
			if sort[j] == "EMPTY_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "EMPTY_HEART", HP = 0, HalfCapacity = false}) --numHearts == 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "EMPTY_COIN_HEART" and isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "EMPTY_COIN_HEART", HP = 0, HalfCapacity = false}) --numHearts == 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "SOUL_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
				local soulIndex = 0
				local soulSkippedIndices = 0
				while numHearts > 0 do
					if not CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
						if not CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, (soulIndex - soulSkippedIndices) * 2 + 1) then
							data.OtherHealthMasks[i][soulIndex+1] = {Key = "SOUL_HEART", HP = (numHearts >= 2 and 2) or 1}
						end
						numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
					else
						soulSkippedIndices = soulSkippedIndices + 1
					end
					soulIndex = soulIndex + 1
				end
			elseif sort[j] == "BLACK_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
				local soulIndex = 0
				local soulSkippedIndices = 0
				while numHearts > 0 do
					if not CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
						if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, (soulIndex - soulSkippedIndices) * 2 + 1) then
							data.OtherHealthMasks[i][soulIndex+1] = {Key = "BLACK_HEART", HP = (numHearts >= 2 and 2) or 1}
						end
						numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
					else
						soulSkippedIndices = soulSkippedIndices + 1
					end
					soulIndex = soulIndex + 1
				end
			elseif sort[j] == "BONE_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
				local soulIndex = 0
				while numHearts > 0 do
					if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
						data.OtherHealthMasks[i][soulIndex+1] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false}
						numHearts = numHearts - 1
					end
					soulIndex = soulIndex + 1
				end
			elseif sort[j] == "BROKEN_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "BROKEN_HEART", HP = 0, HalfCapacity = false})
					numHearts = numHearts - 1
				end
			elseif sort[j] == "BROKEN_COIN_HEART" and isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "BROKEN_COIN_HEART", HP = 0, HalfCapacity = false})
					numHearts = numHearts - 1
				end
			end
		end
	end]]--
end

function CustomHealthAPI.Helper.InitializeOverlays(player)
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "ETERNAL_HEART", CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player))
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "GOLDEN_HEART", CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player))
end

function CustomHealthAPI.Helper.GetRedHealthMask(player, i)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	return data.RedHealthMasks[i]
end

function CustomHealthAPI.Helper.GetOtherHealthMask(player, i)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	return data.OtherHealthMasks[i]
end

function CustomHealthAPI.Helper.CheckIfPlayerRespawned(player)
	local revived = false
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	
	local subPlayer = player:GetSubPlayer()
	local playertype = player:GetPlayerType()
	if player:IsDead() then
		pdata.IsDead = true
		
		-- revives before dead cat that keep current hp
		pdata.CanEarlyRevive = (player:GetCard(0) == Card.CARD_SOUL_LAZARUS or player:GetCard(1) == Card.CARD_SOUL_LAZARUS or player:GetEffects():HasNullEffect(NullItemID.ID_LAZARUS_SOUL_REVIVE)) or
		                       player:HasCollectible(CollectibleType.COLLECTIBLE_1UP) or
		                       player:GetPlayerType() == PlayerType.PLAYER_LAZARUS
		
		-- other early revives
		pdata.CanDeadCat = player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_CAT)
		pdata.CanInnerChild = player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_CHILD)
		
		-- FUCK YOU
		pdata.CanGuppysCollar = player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR)
		
		-- revives after guppys collar but before broken ankh that clear hp
		pdata.CanLazarusRags = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_LAZARUS_RAGS)
		pdata.CanAnkh = player:HasCollectible(CollectibleType.COLLECTIBLE_ANKH)
		
		-- DOUBLE FUCK YOU
		pdata.CanBrokenAnkh = player:HasTrinket(TrinketType.TRINKET_BROKEN_ANKH)
		
		-- everything after
		pdata.CanJudasShadow = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_JUDAS_SHADOW)
		pdata.CanMissingPoster = player:GetTrinketMultiplier(TrinketType.TRINKET_MISSING_POSTER)
		pdata.CanTaintedLostBirthright = (playertype == PlayerType.PLAYER_THELOST_B and player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) or 0
	elseif pdata.IsDead then
		local clearingHP
		if pdata.IsCustomRevive or pdata.CanEarlyRevive then
			clearingHP = false
		elseif pdata.CanDeadCat then
			clearingHP = true
		elseif pdata.CanInnerChild then
			clearingHP = false
		elseif pdata.CanGuppysCollar then
			-- guppys collar throws everything into chaos because it's random
			-- and then broken anhk rolls into the function and makes everything even worse
			-- good thing broken ankh turns you into ???/tainted ??? so you dont have heart containers anyways
			-- so i can just pretend that if you respawned into ???/tainted ??? health got cleared
			-- stupid nasty hack that could maybe break with RGON healthtype-changing stuff but my hands are tied
			if pdata.CanLazarusRags > 0 and pdata.CanLazarusRags > player:GetCollectibleNum(CollectibleType.COLLECTIBLE_LAZARUS_RAGS) then
				clearingHP = false
			elseif (pdata.CanAnkh or pdata.CanBrokenAnkh) and (playertype == PlayerType.PLAYER_BLUEBABY or playertype == PlayerType.PLAYER_BLUEBABY_B) then
				clearingHP = true
			elseif pdata.CanJudasShadow > 0 and pdata.CanJudasShadow > player:GetCollectibleNum(CollectibleType.COLLECTIBLE_JUDAS_SHADOW) then
				clearingHP = true
			elseif pdata.CanMissingPoster > 0 and pdata.CanMissingPoster > player:GetTrinketMultiplier(TrinketType.TRINKET_MISSING_POSTER) then
				clearingHP = true
			elseif pdata.CanTaintedLostBirthright > 0 and pdata.CanTaintedLostBirthright > player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
				clearingHP = true
			else
				clearingHP = false
			end
		elseif pdata.CanLazarusRags > 0 then
			clearingHP = false
		else
			-- ankh, broken ankh, judas shadow, missing poster, tainted lost birthright
			clearingHP = true
		end
		if clearingHP then
			CustomHealthAPI.Helper.ClearSavedata(player)
			if subPlayer ~= nil then
				CustomHealthAPI.Helper.ClearSavedata(subPlayer)
			end
		end
		pdata.IsDead = nil
		pdata.IsCustomRevive = nil
		pdata.CanEarlyRevive = nil
		pdata.CanDeadCat = nil
		pdata.CanInnerChild = nil
		pdata.CanGuppysCollar = nil
		pdata.CanLazarusRags = nil
		pdata.CanAnkh = nil
		pdata.CanBrokenAnkh = nil
		pdata.CanJudasShadow = nil
		pdata.CanMissingPoster = nil
		pdata.CanTaintedLostBirthright = nil
		revived = true
	end
	
	if subPlayer ~= nil then
		local subpdata = CustomHealthAPI.Helper.GetPersistentData(subPlayer, true)
		
		if subPlayer:IsDead() then
			subpdata.IsDead = true
		elseif subpdata.IsDead then
			CustomHealthAPI.Helper.ClearSavedata(player)
			CustomHealthAPI.Helper.ClearSavedata(subPlayer)
			subpdata.IsDead = nil
			revived = true
		end
	end
	
	return revived
end

function CustomHealthAPI.Helper.AddResetRecursiveInitPreventionCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetRecursiveInitPreventionCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddResetRecursiveInitPreventionCallback)

function CustomHealthAPI.Helper.RemoveResetRecursiveInitPreventionCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetRecursiveInitPreventionCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveResetRecursiveInitPreventionCallback)

local avoidRecursive = false
function CustomHealthAPI.Mod:ResetRecursiveInitPreventionCallback()
	if avoidRecursive then
		print("Custom Health API ERROR: Initiatize recursive prevention failed.")
		avoidRecursive = false
	end
end

function CustomHealthAPI.Helper.InitializeEmptyHealthMasks(player)
	local data = CustomHealthAPI.Helper.ResetSavedata(player)
	
	local redorder = CustomHealthAPI.Helper.GetRedHealthOrder()
	data.RedHealthMasks = {}
	for i = 1, #redorder do
		data.RedHealthMasks[i] = {}
	end
	
	local otherorder = CustomHealthAPI.Helper.GetOtherHealthOrder()
	data.OtherHealthMasks = {}
	for i = 1, #otherorder do
		data.OtherHealthMasks[i] = {}
	end
	
	local overlaylayers = CustomHealthAPI.Helper.GetOverlayHealthLayerOrders()
	data.OverlayHealthMaskLayers = {}
	for i, order in ipairs(overlaylayers) do
		data.OverlayHealthMaskLayers[i] = {}
		for j = 1, #order do
			data.OverlayHealthMaskLayers[i][j] = {}
		end
	end
	
	-- Legacy
	data.Overlays = {
		ETERNAL_HEART = 0,
		GOLDEN_HEART = 0,
	}
	
	data.PlayerType = player:GetPlayerType()
end

function CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player, isSubPlayer)
	-- Call this early to trigger repentogon's GetHealthType callback in case it changed.
	local ignored = CustomHealthAPI.Helper.PlayerIsIgnored(player)

	if avoidRecursive then
		return
	end
	avoidRecursive = true
	if type(CustomHealthAPI.PersistentData.PreventResyncing) == "boolean" then
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing and 1 or 0
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1

	local revived = false
	if not isSubPlayer then
		revived = CustomHealthAPI.Helper.CheckIfPlayerRespawned(player)
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	
	local callCache = false
	local callSubCache = false
	if ignored then
		CustomHealthAPI.Helper.ClearSavedata(player)
		avoidRecursive = false
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		
		if revived then
			Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_REVIVED, player:GetPlayerType(), player)
		end
		
		local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
		if CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i] ~= nil and CustomHealthAPI.Helper.GetPersistentData(player, false) == nil then
			CustomHealthAPI.Helper.SetPersistentData(player, CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i]["Persist"])
			
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
								 CacheFlag.CACHE_FIREDELAY | 
								 CacheFlag.CACHE_SPEED | 
								 CacheFlag.CACHE_SHOTSPEED | 
								 CacheFlag.CACHE_RANGE | 
								 CacheFlag.CACHE_LUCK)
			
			player:EvaluateItems()
		end
		
		return
	elseif data == nil then
		local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
		if CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i] ~= nil then
			CustomHealthAPI.Helper.SetSavedata(player, CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i]["Save"])
			CustomHealthAPI.Helper.SetPersistentData(player, CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i]["Persist"])
			data = CustomHealthAPI.Helper.GetSavedata(player)
			
			callCache = true
		end
	end
	
	local subPlayer = player:GetSubPlayer()
	
	if subPlayer ~= nil and not isSubPlayer then
		local subdata = CustomHealthAPI.Helper.GetSavedata(subPlayer)
		if subdata == nil then
			local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
			if CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[i] ~= nil then
				CustomHealthAPI.Helper.SetSavedata(subPlayer, CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[i]["Save"])
				CustomHealthAPI.Helper.SetPersistentData(subPlayer, CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[i]["Persist"])
				CustomHealthAPI.Helper.CheckIfSwapSubPlayerInfo(player)
			
				callSubCache = true
			end
		end
	end
	
	local callCallbacks = false
	if data == nil then
		CustomHealthAPI.Helper.InitializeEmptyHealthMasks(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
		
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.InitializeOtherHealthMasks(player)
		CustomHealthAPI.Helper.InitializeRedHealthMasks(player)
		CustomHealthAPI.Helper.InitializeOverlays(player)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		callCallbacks = true
	end
	
	avoidRecursive = false
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	if subPlayer ~= nil and not isSubPlayer then
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(subPlayer, true)
	end
	
	if callCallbacks then
		Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_INITIALIZE, player:GetPlayerType(), player, isSubPlayer)
	end
	
	if revived then
		Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_REVIVED, player:GetPlayerType(), player)
	end
	
	if callCache then
		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
							 CacheFlag.CACHE_FIREDELAY | 
							 CacheFlag.CACHE_SPEED | 
							 CacheFlag.CACHE_SHOTSPEED | 
							 CacheFlag.CACHE_RANGE | 
							 CacheFlag.CACHE_LUCK)
		
		player:EvaluateItems()
	end
	
	if callSubCache then
		subPlayer:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
							 CacheFlag.CACHE_FIREDELAY | 
							 CacheFlag.CACHE_SPEED | 
							 CacheFlag.CACHE_SHOTSPEED | 
							 CacheFlag.CACHE_RANGE | 
							 CacheFlag.CACHE_LUCK)
		
		subPlayer:EvaluateItems()
	end
end

function CustomHealthAPI.Helper.CheckHealthIsInitialized()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	end
end
