function CustomHealthAPI.Helper.AddPickupCollisionCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_PICKUP_COLLISION, -math.huge, CustomHealthAPI.Mod.PickupCollisionCallbackHandler, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPickupCollisionCallback)

function CustomHealthAPI.Helper.RemovePickupCollisionCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, CustomHealthAPI.Mod.PickupCollisionCallbackHandler)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePickupCollisionCallback)

function CustomHealthAPI.Helper.AddPickupUpdateCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PICKUP_UPDATE, CallbackPriority.EARLY, CustomHealthAPI.Mod.CustomPickupUpdate, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPickupUpdateCallback)

function CustomHealthAPI.Helper.RemovePickupUpdateCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, CustomHealthAPI.Mod.CustomPickupUpdate)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePickupUpdateCallback)

function CustomHealthAPI.Helper.IsHoldingTaintedForgotten(player)
	local forgo = player:GetOtherTwin()
	return forgo and
	       math.abs(forgo.Position.X - player.Position.X) < 0.000001 and
	       math.abs(forgo.Position.Y - player.Position.Y) < 0.000001 and
	       player:IsHoldingItem() and
	       forgo:HasEntityFlags(EntityFlag.FLAG_HELD)
end

function CustomHealthAPI.Helper.CheckIfHeartShouldUseCustomLogic(player, pickup)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return false
	end
	
	if pickup.Price == PickupPrice.PRICE_SPIKES then
		return true
	end

	local hearttype = pickup.SubType
	local redIsDoubled = player:HasCollectible(CollectibleType.COLLECTIBLE_MAGGYS_BOW)
	
	if hearttype == HeartSubType.HEART_FULL then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 4)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 2)
		end
	elseif hearttype == HeartSubType.HEART_HALF then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 2)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 1)
		end
	elseif hearttype == HeartSubType.HEART_SOUL then
		return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player, 2)
	elseif hearttype == HeartSubType.HEART_ETERNAL then
		return CustomHealthAPI.Helper.CheckIfEternalShouldUseCustomLogic(player, 1)
	elseif hearttype == HeartSubType.HEART_DOUBLEPACK then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 8)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 4)
		end
	elseif hearttype == HeartSubType.HEART_BLACK then
		return CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player, 2)
	elseif hearttype == HeartSubType.HEART_GOLDEN then
		return CustomHealthAPI.Helper.CheckIfGoldenShouldUseCustomLogic(player)
	elseif hearttype == HeartSubType.HEART_HALF_SOUL then
		return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player, 1)
	elseif hearttype == HeartSubType.HEART_SCARED then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 4)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 2)
		end
	elseif hearttype == HeartSubType.HEART_BONE then
		return CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player, 1)
	elseif hearttype == HeartSubType.HEART_ROTTEN then
		return CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player, 2)
	else
		return true
	end
end

function CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) then
		return false
	end
	
	local basegameRedCapacity = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) + 
	                            CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player) * 2
	local basegameRedToFullHealth = basegameRedCapacity - CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	
	if basegameRedToFullHealth >= hp then
		return false
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local redMasks = data.RedHealthMasks or {}
	
	local addPriorityOfRed = CustomHealthAPI.PersistentData.HealthDefinitions["RED_HEART"].AddPriority
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if health.Key ~= "RED_HEART" and
			   addPriorityOfRed >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			then
				return true
			end
		end
	end
	
	local customUnoccupiedRedCapacity = CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) * 2
	local customMissingRed = CustomHealthAPI.Helper.GetHealableRedHP(player)
	local customRedToFullHealth = customMissingRed + customUnoccupiedRedCapacity
	
	if customRedToFullHealth <= basegameRedToFullHealth then
		return false
	end
	
	return true
end

function CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "ROTTEN_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) then
		return false
	end
	
	return false
end

function CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "SOUL_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local alabasterChargesToAdd = 0
	local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
	if GetPtrHash(alabasterPlayer) ~= GetPtrHash(player) then
		return true
	end
	for i = 0, 2 do
		if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
		end
	end
	if alabasterChargesToAdd >= hp then
		return false
	end
	local hp = hp - alabasterChargesToAdd
	
	local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	if numShacklesDisabled > 0 then
		if hp <= 2 then
			return false
		end
		hp = hp - 2
	end
	
	local basegameSoulToFullHealth = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) -
	                                 (math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) * 2 +
	                                  CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player) * 2 +
	                                  CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player))
	
	if basegameSoulToFullHealth >= hp then
		return false
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local addPriorityOfSoul = CustomHealthAPI.PersistentData.HealthDefinitions["SOUL_HEART"].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if health.Key ~= "SOUL_HEART" and
				   addPriorityOfSoul >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				then
					return true
				end
			end
		end
	end
	
	local customUnoccupiedSoulCapacity = CustomHealthAPI.Helper.GetRoomForOtherKeys(player) * 2
	local customMissingSoul = CustomHealthAPI.Helper.GetHealableSoulHP(player)
	local customSoulToFullHealth = customMissingSoul + customUnoccupiedSoulCapacity
	
	if customSoulToFullHealth <= basegameSoulToFullHealth then
		return false
	end
	
	return true
end

function CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "BLACK_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local alabasterChargesToAdd = 0
	local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
	if GetPtrHash(alabasterPlayer) ~= GetPtrHash(player) then
		return true
	end
	for i = 0, 2 do
		if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
		end
	end
	if alabasterChargesToAdd >= hp then
		return false
	end
	local hp = hp - alabasterChargesToAdd
	
	local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	if numShacklesDisabled > 0 then
		if hp <= 2 then
			return false
		end
		hp = hp - 2
	end
	
	return false
end

function CustomHealthAPI.Helper.CheckIfEternalShouldUseCustomLogic(player, hp)
	if not CustomHealthAPI.Helper.CanPickKey(player, "ETERNAL_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfEternalShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local completedEternals = math.floor((CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player) + hp) / 2)
	if completedEternals <= 0 then
		return false
	else
		return true
	end
end

function CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "BONE_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local basegameBoneToFullHealth = math.ceil((CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) -
	                                           (math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) * 2 +
	                                            CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player) * 2 +
	                                            CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player))) / 2)
	
	if basegameBoneToFullHealth >= hp then
		return false
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local addPriorityOfBone = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				return false
			end
		end
	end
	
	return true
end

function CustomHealthAPI.Helper.CheckIfGoldenShouldUseCustomLogic(player)
	return not CustomHealthAPI.Helper.CanPickKey(player, "GOLDEN_HEART")
end

function CustomHealthAPI.Library.GetRedHPToBeSpent(p, hpToAdd)
	local player = p:ToPlayer()
	if player == nil then
		return 0
	end
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_BETHANY_B then
		if player:CanPickRedHearts() then
			local bloodChargeToMax = 99 - player:GetBloodCharge()
			return math.min(bloodChargeToMax, hpToAdd)
		end
		
		return 0
	elseif playerType == PlayerType.PLAYER_THESOUL then
		player = player:GetSubPlayer()
		if player == nil then
			return 0
		end
	end
	
	if player:CanPickRedHearts() then
		local hpData = CustomHealthAPI.Helper.GetSavedata(player)
		if hpData ~= nil then
			local redMasks = hpData.RedHealthMasks
			local addPriorityOfRed = CustomHealthAPI.PersistentData.HealthDefinitions["RED_HEART"].AddPriority
			local hpToOverwrite = 0
			local customMissingRed = 0
			for i = 1, #redMasks do
				local mask = redMasks[i]
				for j = 1, #mask do
					local health = mask[j]
					if health.Key ~= "RED_HEART" and
					   addPriorityOfRed >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
					then
						hpToOverwrite = hpToOverwrite + 2
					else
						local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP
						customMissingRed = customMissingRed + (maxHP - health.HP)
					end
				end
			end
			
			local customUnoccupiedRedCapacity = CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) * 2
			local customRedToFullHealth = customMissingRed + customUnoccupiedRedCapacity
			
			return math.min(customRedToFullHealth + hpToOverwrite, hpToAdd)
		end
	end
	
	return 0
end

function CustomHealthAPI.Library.GetSoulHPToBeSpent(p, hpToAdd, heartKey)
	local player = p:ToPlayer()
	if player == nil then
		return 0
	end
	
	local maxHpOfSoul = math.max(2, CustomHealthAPI.Library.GetInfoOfKey(heartKey, "MaxHP"))
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_BETHANY then
		if player:CanPickSoulHearts() then
			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
	
			local alabasterChargesToAdd = 0
			local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
			for i = 0, 2 do
				if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
				end
			end
			
			local soulChargeToMax = 99 - player:GetSoulCharge()
			return math.min(soulChargeToMax + alabasterChargesToAdd + hpSpentReactivatingShackles, hpToAdd)
		end
		
		return 0
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player, true) or CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
		local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
	
		local alabasterChargesToAdd = 0
		local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
		for i = 0, 2 do
			if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
			end
		end
		
		return alabasterChargesToAdd + hpSpentReactivatingShackles
	elseif playerType == PlayerType.PLAYER_THEFORGOTTEN then
		player = player:GetSubPlayer()
		if player == nil then
			player = p:ToPlayer()

			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
		
			local alabasterChargesToAdd = 0
			local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
			for i = 0, 2 do
				if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
				end
			end
			
			return alabasterChargesToAdd + hpSpentReactivatingShackles
		end
	end
	
	if CustomHealthAPI.Library.CanPickKey(player, heartKey) then
		local hpData = CustomHealthAPI.Helper.GetSavedata(player)
		if hpData ~= nil then
			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
	
			local alabasterChargesToAdd = 0
			local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
			for i = 0, 2 do
				if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - alabasterPlayer:GetActiveCharge(i))
				end
			end
			
			local otherMasks = hpData.OtherHealthMasks
			local addPriorityOfSoul = CustomHealthAPI.PersistentData.HealthDefinitions[heartKey].AddPriority
			local hpToOverwrite = 0
			local customMissingSoul = 0
			for i = 1, #otherMasks do
				local mask = otherMasks[i]
				for j = 1, #mask do
					local health = mask[j]
					if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
						if health.Key ~= heartKey and
						   addPriorityOfSoul >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
						then
							hpToOverwrite = hpToOverwrite + maxHpOfSoul
						else
							local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP
							customMissingSoul = customMissingSoul + (maxHP - health.HP)
						end
					end
				end
			end
			
			local customUnoccupiedSoulCapacity = CustomHealthAPI.Helper.GetRoomForOtherKeys(player) * math.max(2, CustomHealthAPI.PersistentData.HealthDefinitions[heartKey].MaxHP)
			local customSoulToFullHealth = customMissingSoul + customUnoccupiedSoulCapacity
			
			return math.min(customSoulToFullHealth + hpToOverwrite + alabasterChargesToAdd + hpSpentReactivatingShackles, hpToAdd)
		end
	end
	
	return 0
end

function CustomHealthAPI.Library.AddCandyHeartBonus(pl, candiesToAdd, seed)
	local player = pl:ToPlayer()
	if player == nil then
		return
	end

	if player:HasCollectible(CollectibleType.COLLECTIBLE_CANDY_HEART) and candiesToAdd > 0 then
		if REPENTOGON then
			player:AddCandyHeartBonus(0, candiesToAdd)
			return
		end
		
		local rng = RNG()
		rng:SetSeed(seed, 35)
		
		local p = player
		local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
		
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
			local forgo = player:GetOtherTwin()
			if forgo ~= nil then
				CustomHealthAPI.Helper.SetPersistentData(forgo, pdata)
				pdata = CustomHealthAPI.Helper.GetPersistentData(forgo)
			end
		end
		
		for i = 1, candiesToAdd do
			local rand = math.random(1, 6)
			if rand == 1 then
				pdata.FakeCandyHeartDamage = (pdata.FakeCandyHeartDamage or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			elseif rand == 2 then
				pdata.FakeCandyHeartTears = (pdata.FakeCandyHeartTears or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
			elseif rand == 3 then
				pdata.FakeCandyHeartSpeed = (pdata.FakeCandyHeartSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SPEED)
			elseif rand == 4 then
				pdata.FakeCandyHeartShotSpeed = (pdata.FakeCandyHeartShotSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			elseif rand == 5 then
				pdata.FakeCandyHeartRange = (pdata.FakeCandyHeartRange or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_RANGE)
			else
				pdata.FakeCandyHeartLuck = (pdata.FakeCandyHeartLuck or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_LUCK)
			end
		end

		p:EvaluateItems()
	end
end

function CustomHealthAPI.Library.AddSoulLocketBonus(pl, locketsToAdd, seed)
	local player = pl:ToPlayer()
	if player == nil then
		return
	end

	if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_LOCKET) and locketsToAdd > 0 then
		if REPENTOGON then
			player:AddSoulLocketBonus(0, locketsToAdd)
			return
		end
		
		local rng = RNG()
		rng:SetSeed(seed, 40)
		
		local p = player
		local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
		
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
			local forgo = player:GetOtherTwin()
			if forgo ~= nil then
				CustomHealthAPI.Helper.SetPersistentData(forgo, pdata)
				pdata = CustomHealthAPI.Helper.GetPersistentData(forgo)
			end
		end
		
		for i = 1, locketsToAdd do
			local rand = math.random(1, 6)
			if rand == 1 then
				pdata.FakeSoulLocketDamage = (pdata.FakeSoulLocketDamage or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			elseif rand == 2 then
				pdata.FakeSoulLocketTears = (pdata.FakeSoulLocketTears or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
			elseif rand == 3 then
				pdata.FakeSoulLocketSpeed = (pdata.FakeSoulLocketSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SPEED)
			elseif rand == 4 then
				pdata.FakeSoulLocketShotSpeed = (pdata.FakeSoulLocketShotSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			elseif rand == 5 then
				pdata.FakeSoulLocketRange = (pdata.FakeSoulLocketRange or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_RANGE)
			else
				pdata.FakeSoulLocketLuck = (pdata.FakeSoulLocketLuck or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_LUCK)
			end
		end

		p:EvaluateItems()
	end
end

function CustomHealthAPI.Library.IncrementImmaculateConception(pl, amount, seed)
	if not REPENTOGON or amount <= 0 then
		return
	end
	
	local player = pl:ToPlayer()
	if player == nil or not player:HasCollectible(CollectibleType.COLLECTIBLE_IMMACULATE_CONCEPTION) then
		return
	end

	local heartsCollected = player:GetImmaculateConceptionState() + amount
	while heartsCollected >= 15 do
		local flags = player:GetConceptionFamiliarFlags()
		local availableFamiliars = {}
		if flags & ConceptionFamiliarFlag.GUARDIAN_ANGEL ~= ConceptionFamiliarFlag.GUARDIAN_ANGEL then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.GUARDIAN_ANGEL)
		end
		if flags & ConceptionFamiliarFlag.HOLY_WATER ~= ConceptionFamiliarFlag.HOLY_WATER then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.HOLY_WATER)
		end
		if flags & ConceptionFamiliarFlag.RELIC ~= ConceptionFamiliarFlag.RELIC then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.RELIC)
		end
		if flags & ConceptionFamiliarFlag.SWORN_PROTECTOR ~= ConceptionFamiliarFlag.SWORN_PROTECTOR then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.SWORN_PROTECTOR)
		end
		if flags & ConceptionFamiliarFlag.SERAPHIM ~= ConceptionFamiliarFlag.SERAPHIM then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.SERAPHIM)
		end
		if #availableFamiliars > 0 then
			local rng = RNG()
			rng:SetSeed(seed, 40)
			
			local flag = availableFamiliars[rng:RandomInt(#availableFamiliars) + 1]
			local continue = Isaac.RunCallback(ModCallbacks.MC_PRE_PLAYER_GIVE_BIRTH_IMMACULATE, player, flag)
			if continue ~= false then
				player:SetConceptionFamiliarFlags(flags | flag)
				player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS, true)
			end
		end
		
		Isaac.Spawn(5, 10, 3, Game():GetRoom():FindFreePickupSpawnPosition(player.Position), Vector.Zero, player)
		
		heartsCollected = heartsCollected - 15
	end
	player:SetImmaculateConceptionState(heartsCollected)
	player:UpdateIsaacPregnancy(false)
end

CustomHealthAPI.PersistentData.AllowPrePickupCollisionCallback = 0

-- Hijacks MC_PRE_PICKUP_COLLISION by executing it manually and trying to maintain mod compatibility.
-- This (mostly) ensures that any custom logic employed by chapi only runs when the game's internal logic is not going to be skipped.
-- If a mod sets `SkipCollisionEffects`, skip chapi's logic too, and maintain the result for `Collide`.
-- Also when appropriate, manually execute MC_POST_PICKUP_COLLISION.
function CustomHealthAPI.Mod:PickupCollisionCallbackHandler(pickup, collider, ...)
	if CustomHealthAPI.PersistentData.AllowPrePickupCollisionCallback > 0 then
		-- Allow this execution to proceed un-hijacked.
		CustomHealthAPI.PersistentData.AllowPrePickupCollisionCallback = CustomHealthAPI.PersistentData.AllowPrePickupCollisionCallback - 1
		return
	end

	local data = CustomHealthAPI.Helper.GetEntityData(pickup)
	data.CHAPIHeartPickupSpentSpikesCostAlready = nil

	local pickupDef = CustomHealthAPI.Library.GetPickupDefinition(pickup.Variant, pickup.SubType)
	if not pickupDef then return end

	local player = collider:ToPlayer()
	if not player then return end

	-- Manually execute MC_PRE_PICKUP_COLLISION to get desired results from other mods.
	CustomHealthAPI.PersistentData.AllowPrePickupCollisionCallback = CustomHealthAPI.PersistentData.AllowPrePickupCollisionCallback + 1
	local defaultResult = Isaac.RunCallbackWithParam(ModCallbacks.MC_PRE_PICKUP_COLLISION, pickup.Variant, pickup, collider, ...)
	local forceCollide = false

	-- Skip chapi's logic if the game's own logic is also being skipped (via boolean or table return).
	if type(defaultResult) == "boolean" then
		return defaultResult
	elseif type(defaultResult) == "table" then
		if defaultResult.SkipCollisionEffects then
			return defaultResult
		end
		forceCollide = defaultResult.Collide
	elseif REPENTOGON then
		defaultResult = {}
	else
		defaultResult = nil
	end

	-- Run chapi's custom collision logic.
	local chapiResult = CustomHealthAPI.Helper.CustomPickupCollision(pickup, player, pickupDef)

	if chapiResult ~= nil then
		if ModCallbacks.MC_POST_PICKUP_COLLISION then
			-- Manually execute MC_POST_PICKUP_COLLISION if we are skipping the vanilla logic.
			Isaac.RunCallbackWithParam(ModCallbacks.MC_POST_PICKUP_COLLISION, pickup.Variant, pickup, collider, ...)
		end
		if forceCollide then
			return false
		end
		return chapiResult
	else
		return defaultResult
	end
end

function CustomHealthAPI.Helper.CustomPickupCollision(pickup, player, pickupDef)
	if pickupDef.IsHeart then
		if pickupDef.Variant == PickupVariant.PICKUP_HEART and pickupDef.SubType >= 1 and pickupDef.SubType <= 12
		and not CustomHealthAPI.Helper.CheckIfHeartShouldUseCustomLogic(player, pickup) then
			-- Vanilla heart, and we don't need to use custom logic.
			return
		elseif player:IsCoopGhost() then
			return false
		elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and CustomHealthAPI.Helper.IsHoldingTaintedForgotten(player) then
			player = player:GetOtherTwin()
		end
	end
	
	local sprite = pickup:GetSprite()
	
	if sprite:IsPlaying("Collect") or (sprite:IsPlaying("Appear") and not sprite:WasEventTriggered("DropSound")) then
		return true
	end
	
	if pickup.Wait > 0 then
		return not sprite:IsPlaying("Idle") and not sprite:IsPlaying("IdlePanic")
	end
	
	local data = CustomHealthAPI.Helper.GetEntityData(pickup)
	
	-- Pre-Check Prices
	if pickup:IsShopItem() then
		local price = pickup.Price
		local shouldCancelFromAnimOrPrice = not player:IsExtraAnimationFinished() or not CustomHealthAPI.Helper.CanAffordPrice(player, price)
		if (price == PickupPrice.PRICE_SPIKES or price == -10)
		and not data.CHAPIHeartPickupSpentSpikesCostAlready
		and not CustomHealthAPI.Helper.PlayerIsHealthless(player)
		and player:GetPlayerType() ~= PlayerType.PLAYER_JACOB2_B
		and not player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)
		and not player:TakeDamage(2, DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(nil), 30) then
			return true
		elseif shouldCancelFromAnimOrPrice then
			return true
		end
	end
	
	local allowVanillaCode = false
	local removeWithNoAnim = false
	local shouldSetPickedFlags = true
	
	local canCollect = CustomHealthAPI.Helper.CanCollectCustomPickup(player, pickup, pickupDef)
	
	-- Try to collect the pickup
	if pickupDef.IsHeart then
		local isRedHeart = pickupDef.HealthKeys and #pickupDef.HealthKeys == 1 and pickupDef.HealthKeys[1] == "RED_HEART"
		local redIsDoubled = player:HasCollectible(CollectibleType.COLLECTIBLE_MAGGYS_BOW)
		
		local redHealthBefore = player:GetHearts()
		local soulHealthBefore = player:GetSoulHearts()
		
		-- Apple of Sodom stuff
		local sodomAppleMult = player:GetTrinketMultiplier(TrinketType.TRINKET_APPLE_OF_SODOM)
		local canApple = sodomAppleMult > 0 and (isRedHeart or (CustomHealthAPI.REPPLUS_V1_9_7_13 and sodomAppleMult > 1))
		local canRandomApple = false
		local appleOfSodomValue = pickupDef.AppleOfSodomValue or 3
		
		if canApple then
			local applerng = RNG()
			applerng:SetSeed(pickup.InitSeed, 1)
			canRandomApple = applerng:RandomInt(2) == 1
			
			if redIsDoubled and isRedHeart then
				appleOfSodomValue = appleOfSodomValue * 2
			end
		end
		
		-- 1. Apple of Sodom's 50% chance to trigger
		-- 2. Normal collection
		-- 3. The Jar collection for red hearts
		-- 4. Apple of Sodom, but for real this time
		-- 5. Heart cannot be collected, return early
		if canRandomApple then
			CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, appleOfSodomValue)
			removeWithNoAnim = true
			shouldSetPickedFlags = false
		elseif canCollect then
			local playedCollectSound = CustomHealthAPI.Helper.PlaySound(pickupDef.CollectSound)
			if not pickupDef.ManualAddHealth then
				local keys = pickupDef.HealthKeys or {}
				local hp = pickupDef.HealthAmount or 1
				for i, key in ipairs(keys) do
					if hp > 0 and CustomHealthAPI.Helper.CanPickKey(player, key) then
						local hpToSpend = hp
						if i ~= #keys then
							if key == "RED_HEART" then
								hpToSpend = CustomHealthAPI.Library.GetRedHPToBeSpent(player, hp)
							elseif key == "SOUL_HEART" or key == "BLACK_HEART" then
								hpToSpend = CustomHealthAPI.Library.GetSoulHPToBeSpent(player, hp)
							end
						end
						if hpToSpend > 0 then
							hp = hp - hpToSpend
							local mult = 1
							if key == "RED_HEART" and redIsDoubled then
								mult = 2
							end
							CustomHealthAPI.Library.AddHealth(player, key, hpToSpend * mult, true)
							if not playedCollectSound then
								CustomHealthAPI.Library.PlayHealthCollectSound(key)
							end
						end
					end
				end
			end
			if pickupDef.OnCollect then
				pickupDef.OnCollect(player, pickup)
			end
		elseif isRedHeart and player:HasCollectible(CollectibleType.COLLECTIBLE_THE_JAR) and player:GetJarHearts() < 8 then
			player:AddJarHearts(hp)
			SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
		elseif canApple then
			CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, appleOfSodomValue)
			removeWithNoAnim = true
			shouldSetPickedFlags = false
		else
			return pickup:IsShopItem()
		end
		
		-- Candy Heart / Soul Locket
		local allowCandyHeartSoulLocketBonus = pickupDef.AllowCandyHeartSoulLocketBonus
		if type(allowCandyHeartSoulLocketBonus) == "function" then
			allowCandyHeartSoulLocketBonus = allowCandyHeartSoulLocketBonus(pickup, player)
		end
		if allowCandyHeartSoulLocketBonus ~= false then
			local redHealthAfter = player:GetHearts()
			local soulHealthAfter = player:GetSoulHearts()
			CustomHealthAPI.Library.AddCandyHeartBonus(player, redHealthAfter - redHealthBefore, pickup.InitSeed)
			CustomHealthAPI.Library.AddSoulLocketBonus(player, soulHealthAfter - soulHealthBefore, pickup.InitSeed)
		end

		-- Immaculate Conception
		local allowImmaculateConception = pickupDef.AllowImmaculateConception
		if type(allowImmaculateConception) == "function" then
			allowImmaculateConception = allowImmaculateConception(pickup, player)
		end
		if allowImmaculateConception ~= false then
			CustomHealthAPI.Library.IncrementImmaculateConception(player, 1, pickup.InitSeed)
		end
	elseif canCollect then
		CustomHealthAPI.Helper.PlaySound(pickupDef.CollectSound)
		if pickupDef.OnCollect then
			allowVanillaCode = pickupDef.OnCollect(player, pickup)
		end
	else
		return pickup:IsShopItem()
	end
	
	-- From this point onward, the pickup has been collected.
	
	-- Kill/remove pickup, play animations
	pickup.Touched = true
	pickup.Velocity = Vector.Zero
	pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	pickup:Die()
	data.ChapiPlayedCollectSound = true
	
	if pickup:IsShopItem() then
		if not removeWithNoAnim then
			player:AnimatePickup(pickup:GetSprite())
		end
		pickup:Remove()
		CustomHealthAPI.Library.TriggerRestock(pickup)
	elseif removeWithNoAnim then
		pickup:Remove()
	elseif pickup:Exists() then
		sprite:Play("Collect", true)
	end
	
	-- Pay prices
	if pickup:IsShopItem() then
		local price = pickup.Price
		if price > 0 then
			player:AddCoins(-price)
		elseif price == PickupPrice.PRICE_SOUL then
			player:TryRemoveTrinket(TrinketType.TRINKET_YOUR_SOUL)
		elseif CustomHealthAPI.Helper.IsHealthPickupPrice(price) then
			CustomHealthAPI.Helper.PayHealthPickupPrice(pickup, player)
		elseif price == PickupPrice.PRICE_FREE then
			CustomHealthAPI.Helper.TryRemoveStoreCredit(player)
		end
		if ModCallbacks.MC_POST_PICKUP_SHOP_PURCHASE then
			Isaac.RunCallbackWithParam(ModCallbacks.MC_POST_PICKUP_SHOP_PURCHASE, pickup.Variant, pickup, player, price)
		end
	end
	
	-- Redemption
	if pickup.SpawnGridIndex > -1 and Game():GetRoom():GetType() == RoomType.ROOM_DEVIL
	and player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_REDEMPTION) == 1 then
		for _, redemption in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.REDEMPTION)) do
			local parent = redemption.Parent
			if parent and GetPtrHash(parent) == GetPtrHash(player) then
				redemption:GetSprite():Play("Fail", true)
				redemption:ToEffect().State = 3
			end
		end
		player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_REDEMPTION)
		SFXManager():Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1.0)
	end
	
	-- Options pickups
	if pickup.OptionsPickupIndex ~= 0 then
		for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
			if entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex and GetPtrHash(entity) ~= GetPtrHash(pickup) then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)
				entity:Remove()
			end
		end
	end
	
	-- Game state flags
	if shouldSetPickedFlags and not pickupDef.NoSetGameStateFlags then
		if pickupDef.IsHeart then
			Game():GetLevel():SetHeartPicked()
			Game():ClearStagesWithoutHeartsPicked()
		end
		if pickupDef.IsHeart or pickupDef.IsBomb or pickupDef.IsCoin then
			Game():SetStateFlag(GameStateFlag.STATE_HEART_BOMB_COIN_PICKED, true)
		end
	end
	
	if not allowVanillaCode then
		return true
	end
end

function CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
    -- thank you decomp
	SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 1, 0, false, 1)
    
	local rng = RNG()
	rng:SetSeed(pickup.InitSeed, 45)
	
	local explo = Isaac.Spawn(1000, 2, 3, pickup.Position, Vector.Zero, nil)
	explo:Update()
	
	local splat = Isaac.Spawn(1000, 7, 0, pickup.Position, Vector.Zero, nil)
	splat:Update()
	
    local numGibs = rng:RandomInt(3) + mod
    for i = 1, numGibs do
		local gibpos = pickup.Position + Vector.FromAngle(rng:RandomFloat() * 360) * 0.5 * pickup.Size
		local gibvel = Vector.FromAngle(rng:RandomFloat() * 360) * (rng:RandomFloat() * 4.0 + 2.0)
		
---@diagnostic disable-next-line: param-type-mismatch
		local gib = Isaac.Spawn(1000, 5, 0, gibpos, gibvel, nil)
		gib:Update()
    end
	
    local numSpiders = rng:RandomInt(3) + mod
    for i = 1, numSpiders do
		local targetoffset = Vector.FromAngle(rng:RandomFloat() * 360) * (rng:RandomFloat() / 2 + 0.5) * 15
		player:ThrowBlueSpider(pickup.Position, pickup.Position + Vector(0, 60) + targetoffset)
    end
	
	Game():ButterBeanFart(pickup.Position, 100.0, player, true, false)
end

local function tearsUp(firedelay, val)
	local currentTears = 30 / (firedelay + 1)
	local newTears = currentTears + val
	return math.max((30 / newTears) - 1, -0.99)
end

if not REPENTOGON then
	function CustomHealthAPI.Helper.AddCandiesAndLocketsCacheCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.CandiesAndLocketsCacheCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddCandiesAndLocketsCacheCallback)

	function CustomHealthAPI.Helper.RemoveCandiesAndLocketsCacheCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.CandiesAndLocketsCacheCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveCandiesAndLocketsCacheCallback)
end

-- Not used with REPENTOGON
function CustomHealthAPI.Mod:CandiesAndLocketsCacheCallback(player, flag)
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	
	if flag == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + 0.02 * (pdata.FakeCandyHeartSpeed or 0)
		player.MoveSpeed = player.MoveSpeed + 0.04 * (pdata.FakeSoulLocketSpeed or 0)
	elseif flag == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage + 0.1 * (pdata.FakeCandyHeartDamage or 0)
		player.Damage = player.Damage + 0.2 * (pdata.FakeSoulLocketDamage or 0)
	elseif flag == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = tearsUp(player.MaxFireDelay, 0.05 * (pdata.FakeCandyHeartTears or 0))
		player.MaxFireDelay = tearsUp(player.MaxFireDelay, 0.1 * (pdata.FakeSoulLocketTears or 0))
	elseif flag == CacheFlag.CACHE_RANGE then
		local basemulti = 1
		if REPENTOGON then
			basemulti = basemulti * player:GetD8RangeModifier()
		end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
			basemulti = basemulti * 0.8
		end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) or 
		   player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) or
		   player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY)
		then
			basemulti = basemulti * 0.8
		end
		
		player.TearRange = player.TearRange + 6 * (pdata.FakeCandyHeartRange or 0) * basemulti
		player.TearRange = player.TearRange + 12 * (pdata.FakeSoulLocketRange or 0) * basemulti
	elseif flag == CacheFlag.CACHE_SHOTSPEED then
		player.ShotSpeed = player.ShotSpeed + 0.02 * (pdata.FakeCandyHeartShotSpeed or 0)
		player.ShotSpeed = player.ShotSpeed + 0.04 * (pdata.FakeSoulLocketShotSpeed or 0)
	elseif flag == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + 0.1 * (pdata.FakeCandyHeartLuck or 0)
		player.Luck = player.Luck + 0.2 * (pdata.FakeSoulLocketLuck or 0)
	end
end

if not REPENTOGON then
	function CustomHealthAPI.Helper.AddClearCandiesAndLocketsCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.ClearCandiesAndLocketsCallback, CollectibleType.COLLECTIBLE_D4)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddClearCandiesAndLocketsCallback)

	function CustomHealthAPI.Helper.RemoveClearCandiesAndLocketsCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.ClearCandiesAndLocketsCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveClearCandiesAndLocketsCallback)

	function CustomHealthAPI.Mod:ClearCandiesAndLocketsCallback(id, rng, player)
		CustomHealthAPI.Helper.ClearCandiesAndLockets(player)
	end
end

function CustomHealthAPI.Helper.ClearCandiesAndLockets(player)
	if REPENTOGON then return end
	
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		local forgo = player:GetOtherTwin()
		if forgo ~= nil then
			CustomHealthAPI.Helper.SetPersistentData(forgo, pdata)
			pdata = CustomHealthAPI.Helper.GetPersistentData(forgo)
		end
	end
	
	pdata.FakeCandyHeartDamage = nil
	pdata.FakeCandyHeartTears = nil
	pdata.FakeCandyHeartSpeed = nil
	pdata.FakeCandyHeartShotSpeed = nil
	pdata.FakeCandyHeartRange = nil
	pdata.FakeCandyHeartLuck = nil
	
	pdata.FakeSoulLocketDamage = nil
	pdata.FakeSoulLocketTears = nil
	pdata.FakeSoulLocketSpeed = nil
	pdata.FakeSoulLocketShotSpeed = nil
	pdata.FakeSoulLocketRange = nil
	pdata.FakeSoulLocketLuck = nil
	
	player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
	                     CacheFlag.CACHE_FIREDELAY | 
	                     CacheFlag.CACHE_SPEED | 
	                     CacheFlag.CACHE_SHOTSPEED | 
	                     CacheFlag.CACHE_RANGE | 
	                     CacheFlag.CACHE_LUCK)
	
	player:EvaluateItems()
end

function CustomHealthAPI.Helper.CanCollectCustomPickup(player, pickup, pickupDef)
	pickupDef = pickupDef or CustomHealthAPI.Library.GetPickupDefinition(pickup.Variant, pickup.SubType)
	local canCollect = true
	if pickupDef.CanCollect then
		canCollect = pickupDef.CanCollect(player, pickup)
	elseif pickupDef.IsHeart then
		canCollect = CustomHealthAPI.Helper.CanPickAnyKey(player, pickupDef.HealthKeys)
	end
	return canCollect
end

function CustomHealthAPI.Helper.CustomPickupKeeperFlyCheck(pickup)
	local keeper = false
	local nonkeeper = false

	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local ptype = player:GetPlayerType()
		if ptype == PlayerType.PLAYER_KEEPER or ptype == PlayerType.PLAYER_KEEPER_B then
			keeper = true
		else
			nonkeeper = true
		end
	end

	if keeper and not nonkeeper then
		for i = 1, 2 do
			local afly = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, 0, pickup.Position, Vector.Zero, pickup)
			afly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			afly:Update()
		end
		pickup:Remove()
	end
end

function CustomHealthAPI.Helper.CustomPickupMagnetoCheck(pickup, pickupDef)
	local closestPlayer = nil
	local closestDistance = nil

	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MAGNETO) or player:HasTrinket(TrinketType.TRINKET_SUPER_MAGNET) then
			if not pickupDef or CustomHealthAPI.Helper.CanCollectCustomPickup(player, pickup, pickupDef) then
				local dist = pickup.Position:Distance(player.Position)
				if not closestPlayer or not closestDistance or dist < closestDistance then
					closestPlayer = player
					closestDistance = dist
				end
			end
		end
	end

	local data = CustomHealthAPI.Helper.GetEntityData(pickup)

	if closestPlayer then
		local vec = (closestPlayer.Position - pickup.Position):Resized(2)
		pickup.Velocity = pickup.Velocity:Lerp(vec, 0.2)
		data.ChapiAffectedByMagneto = data.ChapiAffectedByMagneto or pickup.GridCollisionClass
		pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	elseif data.ChapiAffectedByMagneto then
		pickup.GridCollisionClass = data.ChapiAffectedByMagneto
		data.ChapiAffectedByMagneto = nil
	end
end

function CustomHealthAPI.Mod:CustomPickupUpdate(pickup)
	local pickupDef = CustomHealthAPI.Library.GetPickupDefinition(pickup.Variant, pickup.SubType)
	if not pickupDef then return end

	local data = CustomHealthAPI.Helper.GetEntityData(pickup)
	local sprite = pickup:GetSprite()

	if sprite:IsFinished("Collect") then
		pickup:Remove()
		return
	elseif sprite:IsPlaying("Collect") then
		if sprite:GetFrame() <= 1 and not data.ChapiPlayedCollectSound then
			CustomHealthAPI.Helper.PlaySound(pickupDef.CollectSound)
			data.ChapiPlayedCollectSound = true
		end
		pickup.Velocity = Vector.Zero
	elseif sprite:IsEventTriggered("DropSound") then
		CustomHealthAPI.Helper.PlaySound(pickupDef.DropSound)
		if pickupDef.OnDrop then
			pickupDef.OnDrop(pickup)
		end
	end

	if pickupDef.AllowMagneto ~= false then
		-- Can get pulled by default, no need for custom handling.
		if pickupDef.Variant ~= PickupVariant.PICKUP_KEY
		and pickupDef.Variant ~= PickupVariant.PICKUP_BOMB
		and pickupDef.Variant ~= PickupVariant.PICKUP_COIN
		and pickupDef.Variant ~= PickupVariant.PICKUP_HEART
		and pickupDef.Variant ~= PickupVariant.PICKUP_LIL_BATTERY then
			CustomHealthAPI.Helper.CustomPickupMagnetoCheck(pickup, pickupDef)
		end
	end

	if pickupDef.IsHeart and not pickupDef.NoKeeperFly and pickupDef.Variant ~= PickupVariant.PICKUP_HEART then
		CustomHealthAPI.Helper.CustomPickupKeeperFlyCheck(pickup)
	end
end
