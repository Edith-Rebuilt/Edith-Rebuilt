if REPENTOGON then
Isaac.ReworkCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET)
Isaac.ReworkTrinket(TrinketType.TRINKET_MOTHERS_KISS)

function CustomHealthAPI.Helper.AddBlockGulletCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_INIT, -1 * math.huge, CustomHealthAPI.Mod.BlockGulletCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddBlockGulletCallback)

function CustomHealthAPI.Helper.RemoveBlockGulletCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_INIT, CustomHealthAPI.Mod.BlockGulletCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveBlockGulletCallback)

function CustomHealthAPI.Mod:BlockGulletCallback(player)
	CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, CollectibleType.COLLECTIBLE_GREEDS_GULLET)
	CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, TrinketType.TRINKET_MOTHERS_KISS)
end

function CustomHealthAPI.Helper.GetGreedsGulletHearts(player)
	local numGulletingHearts = 0
	if player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) then
		local numCoins = player:GetNumCoins()
		if numCoins < 99 then
			numGulletingHearts = math.floor(numCoins / 25)
		elseif numCoins <= 100 then
			numGulletingHearts = 4
		else
			numGulletingHearts = math.floor((numCoins - 100) / 100) + 4
		end
	end
	if player:HasTrinket(TrinketType.TRINKET_MOTHERS_KISS) then
		local canMomsBox = false
		local t0 = player:GetTrinket(0)
		local t1 = player:GetTrinket(1)
		local smeltedKisses = player:GetSmeltedTrinkets({TrinketType.TRINKET_MOTHERS_KISS})[TrinketType.TRINKET_MOTHERS_KISS]
		if (t0 & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
			local num = 1
			if (t0 & TrinketType.TRINKET_GOLDEN_FLAG) == TrinketType.TRINKET_GOLDEN_FLAG then
				num = 2
			end
			numGulletingHearts = numGulletingHearts + num
			canMomsBox = true
		end
		if (t1 & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
			local num = 1
			if (t1 & TrinketType.TRINKET_GOLDEN_FLAG) == TrinketType.TRINKET_GOLDEN_FLAG then
				num = 2
			end
			numGulletingHearts = numGulletingHearts + num
			canMomsBox = true
		end
		if smeltedKisses.trinketAmount > 0 then
			numGulletingHearts = numGulletingHearts + smeltedKisses.trinketAmount
			canMomsBox = true
		end
		if smeltedKisses.goldenTrinketAmount > 0 then
			numGulletingHearts = numGulletingHearts + smeltedKisses.trinketAmount * 2
			canMomsBox = true
		end
		if canMomsBox and player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_BOX) then
			numGulletingHearts = numGulletingHearts + 1
		end
	end
	return numGulletingHearts
end

function CustomHealthAPI.Helper.HandleGreedsGulletSyncing(player)
	local playertype = player:GetPlayerType()
	if playertype == PlayerType.PLAYER_THESOUL or playertype == PlayerType.PLAYER_THESOUL_B then
		return
	end

	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	
	if not (CustomHealthAPI.Helper.IsFoundSoul(player) or 
	        player:IsCoopGhost() or 
			Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.PRE_SYNC_GULLET_HEARTS, player:GetPlayerType(), player) ~= nil)
	then
		::testGulletHearts::
		local numGulletingHearts = CustomHealthAPI.Helper.GetGreedsGulletHearts(player)
		local diffGullet = numGulletingHearts - (pdata.LastNumGulletHearts or 0) + (pdata.GreedsGulletOverflow or 0)
		pdata.LastNumGulletHearts = numGulletingHearts
		
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.COIN then
			if diffGullet > 0 then
				local roomToAdd = math.ceil(player:GetHeartLimit() / 2) - math.ceil(player:GetMaxHearts() / 2)
				pdata.GreedsGulletOverflow = math.max(0, diffGullet - roomToAdd)
				player:AddMaxHearts(math.min(diffGullet, roomToAdd) * 2)
			else
				while diffGullet < 0 and (pdata.GreedsGulletOverflow or 0) > 0 do
					diffGullet = diffGullet + 1
					pdata.GreedsGulletOverflow = pdata.GreedsGulletOverflow - 1
				end
				if diffGullet < 0 then
					player:AddMaxHearts(diffGullet * 2)
				end
			end
			
			local numGulletedHearts = math.ceil(player:GetMaxHearts() / 2)
			if numGulletedHearts + (pdata.GreedsGulletOverflow or 0) < numGulletingHearts then
				local hasGullet = player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET)
				repeat
					if player:HasTrinket(TrinketType.TRINKET_MOTHERS_KISS) then
						local t0 = player:GetTrinket(0)
						local t1 = player:GetTrinket(1)
						if (t0 & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
							player:TryRemoveTrinket(t0)
						elseif (t1 & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
							player:TryRemoveTrinket(t1)
						else
							local smeltedKisses = player:GetSmeltedTrinkets({TrinketType.TRINKET_MOTHERS_KISS})[TrinketType.TRINKET_MOTHERS_KISS]
							if smeltedKisses.trinketAmount > 0 then
								player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOTHERS_KISS)
							else
								player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOTHERS_KISS + TrinketType.TRINKET_GOLDEN_FLAG)
							end
						end
						numGulletingHearts = CustomHealthAPI.Helper.GetGreedsGulletHearts(player)
					elseif hasGullet then
						if numGulletingHearts >= 5 then
							player:AddCoins(-100)
						elseif numGulletingHearts == 4 then
							player:AddCoins(-24)
						else
							player:AddCoins(-25)
						end
						numGulletingHearts = numGulletingHearts - 1
					else
						break
					end
				until (numGulletedHearts + (pdata.GreedsGulletOverflow or 0) >= numGulletingHearts)
				goto testGulletHearts -- check for any additional removals
			end
		elseif healthtype == HealthType.RED or healthtype == HealthType.SOUL or healthtype == HealthType.BONE then
			local key
			if healthtype == HealthType.RED then
				key = "EMPTY_HEART"
			elseif healthtype == HealthType.SOUL then
				key = "SOUL_HEART"
			elseif healthtype == HealthType.BONE then
				key = "BONE_HEART"
			end
			key = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.GET_GULLET_HEART_KEY, player:GetPlayerType(), player, key) or key
			
			local keyTyp = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
			local keyMaxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
			if keyTyp == CustomHealthAPI.Enums.HealthTypes.SOUL or 
			   (keyTyp == CustomHealthAPI.Enums.HealthTypes.CONTAINER and CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE)
			then
				local data = CustomHealthAPI.Helper.GetSavedata(player)
				local otherHealthMasks = data.OtherHealthMasks or {}
				
				if diffGullet > 0 then
					local keyPriority = CustomHealthAPI.Library.GetInfoOfKey(key, "AddPriority")
					local roomToAdd = CustomHealthAPI.Helper.GetRoomForOtherKeys(player)
					local totalOther = 0
					for i = 1, #otherHealthMasks do
						local mask = otherHealthMasks[i]
						for j = 1, #mask do
							local health = mask[j]
							local healthTyp = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
							local healthPriority = CustomHealthAPI.Library.GetInfoOfHealth(health, "AddPriority")
							if key ~= health.Key then
								if keyTyp == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
									if healthTyp == CustomHealthAPI.Enums.HealthTypes.SOUL then
										roomToAdd = roomToAdd + 1
									elseif healthTyp == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
										   healthPriority <= keyPriority
									then
										roomToAdd = roomToAdd + 1
									end
								elseif keyTyp == CustomHealthAPI.Enums.HealthTypes.SOUL then
									if healthTyp == CustomHealthAPI.Enums.HealthTypes.SOUL and
									   healthPriority <= keyPriority
									then
										roomToAdd = roomToAdd + 1
									end
								end
							end
						end
					end
					pdata.GreedsGulletOverflow = math.max(0, diffGullet - roomToAdd)
					CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
					CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
					CustomHealthAPI.Helper.UpdateHealthMasks(player, key, math.min(diffGullet, roomToAdd) * ((keyMaxHP > 0 and keyMaxHP) or 2), true, false, true, true)
					CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
					CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
					CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
				else
					while diffGullet < 0 and (pdata.GreedsGulletOverflow or 0) > 0 do
						diffGullet = diffGullet + 1
						pdata.GreedsGulletOverflow = pdata.GreedsGulletOverflow - 1
					end
					if diffGullet < 0 then
						CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
						CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
						CustomHealthAPI.Helper.UpdateHealthMasks(player, key, diffGullet * ((keyMaxHP > 0 and keyMaxHP) or 2), true, false, true, true)
						CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
						CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
						CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					end
				end
				
				local numGulletedHearts = 0
				for i = 1, #otherHealthMasks do
					local mask = otherHealthMasks[i]
					for j = 1, #mask do
						local health = mask[j]
						local healthTyp = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
						if keyTyp == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthTyp == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
						   CustomHealthAPI.Library.GetInfoOfHealth(health, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE 
						then
							local healthMaxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
							if (keyMaxHP > 0 and healthMaxHP > 0) or (keyMaxHP <= 0 and healthMaxHP <= 0) then
								numGulletedHearts = numGulletedHearts + 1
							end
						elseif keyTyp == CustomHealthAPI.Enums.HealthTypes.SOUL and healthTyp == CustomHealthAPI.Enums.HealthTypes.SOUL then
							numGulletedHearts = numGulletedHearts + 1
						end
					end
				end
				if numGulletedHearts + (pdata.GreedsGulletOverflow or 0) < numGulletingHearts then
					local hasGullet = player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET)
					repeat
						if player:HasTrinket(TrinketType.TRINKET_MOTHERS_KISS) then
							local t0 = player:GetTrinket(0)
							local t1 = player:GetTrinket(1)
							if (t0 & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
								player:TryRemoveTrinket(t0)
							elseif (t1 & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
								player:TryRemoveTrinket(t1)
							else
								local smeltedKisses = player:GetSmeltedTrinkets({TrinketType.TRINKET_MOTHERS_KISS})[TrinketType.TRINKET_MOTHERS_KISS]
								if smeltedKisses.trinketAmount > 0 then
									player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOTHERS_KISS)
								else
									player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOTHERS_KISS + TrinketType.TRINKET_GOLDEN_FLAG)
								end
							end
							numGulletingHearts = CustomHealthAPI.Helper.GetGreedsGulletHearts(player)
						elseif hasGullet then
							if numGulletingHearts >= 5 then
								player:AddCoins(-100)
							elseif numGulletingHearts == 4 then
								player:AddCoins(-24)
							else
								player:AddCoins(-25)
							end
							numGulletingHearts = numGulletingHearts - 1
						else
							break
						end
					until (numGulletedHearts + (pdata.GreedsGulletOverflow or 0) >= numGulletingHearts)
					goto testGulletHearts -- check for any additional removals
				end
			end
		end
		
		Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SYNC_GULLET_HEARTS, player:GetPlayerType(), player)
	else
		local numGulletingHearts = CustomHealthAPI.Helper.GetGreedsGulletHearts(player)
		pdata.LastNumGulletHearts = numGulletingHearts
	end
end

function CustomHealthAPI.Helper.AddPreKeeperMothersKissHealCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_ADD_TRINKET, math.huge, CustomHealthAPI.Mod.PreKeeperMothersKissHealCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreKeeperMothersKissHealCallback)

function CustomHealthAPI.Helper.RemovePreKeeperMothersKissHealCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_ADD_TRINKET, CustomHealthAPI.Mod.PreKeeperMothersKissHealCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreKeeperMothersKissHealCallback)

function CustomHealthAPI.Mod:PreKeeperMothersKissHealCallback(player, id, firstTime)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS and firstTime and player:GetHealthType() == HealthType.COIN then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		data.RedHeartsBeforeMothersKiss = player:GetHearts()
	end
end

function CustomHealthAPI.Helper.AddMothersKissHealCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_TRIGGER_TRINKET_ADDED, -1 * math.huge, CustomHealthAPI.Mod.MothersKissHealCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddMothersKissHealCallback)

function CustomHealthAPI.Helper.RemoveMothersKissHealCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_TRIGGER_TRINKET_ADDED, CustomHealthAPI.Mod.MothersKissHealCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveMothersKissHealCallback)

function CustomHealthAPI.Mod:MothersKissHealCallback(player, id, firstTime, innate)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS and firstTime and not innate then
		CustomHealthAPI.Helper.HandleGreedsGulletSyncing(player)

		local num = 2
		if (id & TrinketType.TRINKET_GOLDEN_FLAG) == TrinketType.TRINKET_GOLDEN_FLAG then
			num = 4
		end
		if player:GetHealthType() == HealthType.COIN then
			local data = CustomHealthAPI.Helper.GetOtherData(player)
			if data.RedHeartsBeforeMothersKiss ~= nil then
				local redHearts = player:GetHearts()
				if redHearts ~= data.RedHeartsBeforeMothersKiss + 2 then
					player:AddHearts(data.RedHeartsBeforeMothersKiss + 2 - redHearts)
				end
			end
			data.RedHeartsBeforeMothersKiss = nil
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", num)
			CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		end
	end
end

function CustomHealthAPI.Helper.AddKeeperHPLimitCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, -1 * math.huge, CustomHealthAPI.Mod.KeeperHPLimitCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddKeeperHPLimitCallback)

function CustomHealthAPI.Helper.RemoveKeeperHPLimitCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, CustomHealthAPI.Mod.KeeperHPLimitCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveKeeperHPLimitCallback)

function CustomHealthAPI.Mod:KeeperHPLimitCallback(player, limit, ignoreModifiers)
	if not ignoreModifiers then
		local ptype = player:GetPlayerType()
		if ptype == PlayerType.PLAYER_KEEPER or ptype == PlayerType.PLAYER_KEEPER_B then
			limit = limit + CustomHealthAPI.Helper.GetGreedsGulletHearts(player) * 2
			if player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) then
				local coins = player:GetNumCoins()
				local addedHearts = math.floor(coins / 25)
				if coins == 99 then
					addedHearts = addedHearts + 1
				end
				limit = limit + addedHearts * 2
			end
			return limit
		end
	end
end

function CustomHealthAPI.Helper.AddMothersKissCheckKillCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_TRIGGER_TRINKET_REMOVED, CustomHealthAPI.Mod.MothersKissCheckKillCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddMothersKissCheckKillCallback)

function CustomHealthAPI.Helper.RemoveMothersKissCheckKillCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_TRIGGER_TRINKET_REMOVED, CustomHealthAPI.Mod.MothersKissCheckKillCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveMothersKissCheckKillCallback)

local playersToCheckToKill = {}
function CustomHealthAPI.Mod:MothersKissCheckKillCallback(player, id)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		table.insert(playersToCheckToKill, player)
	end
end

function CustomHealthAPI.Helper.CheckMothersKissKill()
	for _, player in ipairs(playersToCheckToKill) do
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.COIN then
			if player:GetHearts() <= 0 and player:IsExtraAnimationFinished() then
				player:Kill()
			end
		elseif healthtype == HealthType.RED or healthtype == HealthType.SOUL or healthtype == HealthType.BONE then
			if CustomHealthAPI.Helper.GetTotalHP(player) <= 0 and player:IsExtraAnimationFinished() then
				player:Kill()
			end
		end
	end
	playersToCheckToKill = {}
end
end