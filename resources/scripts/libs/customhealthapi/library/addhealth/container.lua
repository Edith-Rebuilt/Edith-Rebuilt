function CustomHealthAPI.Helper.TryConvertingContainerHP(player, key)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	local keyContainingMask = otherMasks[maskIndex]
	
	local addPriority = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	local healthToConvert
	local healthMaskIndex
	local healthIndexInMask
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL and
			   health.Key ~= key and
			   (healthToConvert == nil or addPriorityOfHealth < CustomHealthAPI.PersistentData.HealthDefinitions[healthToConvert.Key].AddPriority)
			then
				healthToConvert = health
				healthMaskIndex = i
				healthIndexInMask = j
			end
		end
	end
	if healthToConvert == nil then
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   health.Key ~= key and
				   addPriorityOfHealth <= addPriority and
				   (healthToConvert == nil or addPriorityOfHealth < CustomHealthAPI.PersistentData.HealthDefinitions[healthToConvert.Key].AddPriority)
				then
					healthToConvert = health
					healthMaskIndex = i
					healthIndexInMask = j
				end
			end
		end
	end
	
	if healthToConvert == nil then
		return
	end
	local healthWasContainer = CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER
	table.remove(otherMasks[healthMaskIndex], healthIndexInMask)
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	if maskIndex == healthMaskIndex and healthWasContainer then
		if maxHP >= 1 then
			table.insert(keyContainingMask, healthIndexInMask, {Key = key, HP = 1, HalfCapacity = false})
		else
			table.insert(keyContainingMask, healthIndexInMask, {Key = key, HP = 0, HalfCapacity = false})
		end
	else
		if maxHP >= 1 then
			table.insert(keyContainingMask, {Key = key, HP = 1, HalfCapacity = false})
		else
			table.insert(keyContainingMask, {Key = key, HP = 0, HalfCapacity = false})
		end
	end
	
	if CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "MaxHP") <= 1 then
			CustomHealthAPI.Helper.HealSoulAnywhere(player, 2)
		else
			CustomHealthAPI.Helper.HealSoulAnywhere(player, healthToConvert.HP)
		end
	end
end

function CustomHealthAPI.Helper.TryInsertingContainerHP(player, key, ignoreRoomForOtherKeys, convertedMaxInsertFront)
	local keyContainingMask = CustomHealthAPI.Helper.GetMaskForKey(player, key)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maxHP = healthDef.MaxHP
	
	if maxHP > 1 and healthDef.AddRemoveContainerByHP then
		-- Try ""healing"" an existing container.
		for i, health in ipairs(keyContainingMask) do
			if health.Key == key and health.HP < maxHP then
				health.HP = health.HP + 1
				return
			end
		end
	end
	
	if CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 or ignoreRoomForOtherKeys then
		local hp = (maxHP > 1 and healthDef.AddRemoveContainerByHP) and 1 or maxHP
		if convertedMaxInsertFront then
			table.insert(keyContainingMask, 1, {Key = key, HP = hp, HalfCapacity = false})
		else
			table.insert(keyContainingMask, {Key = key, HP = hp, HalfCapacity = false})
		end
	else
		CustomHealthAPI.Helper.TryConvertingContainerHP(player, key)
	end
end

function CustomHealthAPI.Helper.PlusContainerMain(player, key, hp, ignoreRoomForOtherKeys, convertedMaxInsertFront)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maxHP = healthDef.MaxHP
	local canHaveHalfCapacity = healthDef.CanHaveHalfCapacity
	
	local hpToAdd = hp
	local hpPer
	local keysToAdd

	if maxHP >= 1 and not healthDef.AddRemoveContainerByHP then
		keysToAdd = math.ceil(hp / maxHP)
		hpPer = maxHP
	elseif maxHP == 0 and canHaveHalfCapacity then
		keysToAdd = math.ceil(hp / 2)
		hpPer = 2
	else
		keysToAdd = hp
		hpPer = 1
	end
	
	while keysToAdd > 0 do
		CustomHealthAPI.Helper.TryInsertingContainerHP(player, key, ignoreRoomForOtherKeys, convertedMaxInsertFront)
		keysToAdd = keysToAdd - 1
		hpToAdd = hpToAdd - hpPer
	end
	
	while CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 do
		if not CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, true) then
			break
		end
	end
	
	return math.max(0, hpToAdd)
end

function CustomHealthAPI.Helper.TryRemoveMaxFromMaskByKey(player, key)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maxHP = healthDef.MaxHP
	local maskIndex = healthDef.MaskIndex
	local mask = otherMasks[maskIndex]
	
	for i = #mask, 1, -1 do
		local health = mask[i]
		if health.Key == key then
			if maxHP >= 1 and healthDef.AddRemoveContainerByHP and health.HP > 1 then
				health.HP = health.HP - 1
			else
				table.remove(mask, i)
			end
			return true
		end
	end
end

function CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromMask(player, maskIndex, removingBone, removingBroken, avoidRemovingBone)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	local mask = otherMasks[maskIndex]
	
	local lowestPriorityHealth
	local lowestPriority
	local indexOfLowestPriority
	for i = #mask, 1, -1 do
		local health = mask[i]
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and not healthDef.ExplicitRemovalOnly then
			local isBroken = healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			local maxHP = healthDef.MaxHP
			
			local checkForRemoval = false
			if isBroken then
				if removingBroken then
					checkForRemoval = true
				end
			elseif maxHP == 0 then
				if not (removingBone or removingBroken) then
					checkForRemoval = true
				end
			else
				if not (removingBroken or avoidRemovingBone) then
					checkForRemoval = true
				end
			end
			
			if checkForRemoval then
				local removePriorityOfHealth = healthDef.RemovePriority
				if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
					lowestPriorityHealth = health
					lowestPriority = removePriorityOfHealth
					indexOfLowestPriority = i
				end
			end
		end
	end
	
	if lowestPriority ~= nil then
		table.remove(mask, indexOfLowestPriority)
		return true
	end
	return false
end

function CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromAnywhere(player, removingBone, removingBroken, avoidRemovingBone)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local lowestPriorityHealth
	local lowestPriority
	local maskIndexOfLowestPriority
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and not healthDef.ExplicitRemovalOnly then
				local isBroken = healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
				local maxHP = healthDef.MaxHP
				
				local checkForRemoval = false
				if isBroken then
					if removingBroken then
						checkForRemoval = true
					end
				elseif maxHP == 0 then
					if not (removingBone or removingBroken) then
						checkForRemoval = true
					end
				else
					if not (removingBroken or avoidRemovingBone) then
						checkForRemoval = true
					end
				end
				
				if checkForRemoval then
					local removePriorityOfHealth = healthDef.RemovePriority
					if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
						lowestPriorityHealth = health
						lowestPriority = removePriorityOfHealth
						maskIndexOfLowestPriority = i
					end
				end
			end
		end
	end
	
	return CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromMask(player, maskIndexOfLowestPriority, removingBone, removingBroken, avoidRemovingBone)
end

function CustomHealthAPI.Helper.HasRemovableMaxHP(player, key, avoidRemovingBone)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local removingBone = maxHP > 0
	local removingBroken = CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and (key == health.Key or not healthDef.ExplicitRemovalOnly) then
				local isBroken = healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
				local maxHP = healthDef.MaxHP
				
				if isBroken then
					if removingBroken then
						return true
					end
				elseif maxHP == 0 then
					if not (removingBone or removingBroken) then
						return true
					end
				else
					if not (removingBroken or avoidRemovingBone) then
						return true
					end
				end
			end
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.OtherMaskHasMaxForRemoval(player, maskIndex, key, avoidRemovingBone)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	local mask = otherMasks[maskIndex]
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local removingBone = maxHP > 0
	local removingBroken = CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	
	for i = 1, #mask do
		local health = mask[i]
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and (key == health.Key or not healthDef.ExplicitRemovalOnly) then
			local isBroken = healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			local maxHP = healthDef.MaxHP
			
			if isBroken then
				if removingBroken then
					return true
				end
			elseif maxHP == 0 then
				if not (removingBone or removingBroken) then
					return true
				end
			else
				if not (removingBroken or avoidRemovingBone) then
					return true
				end
			end
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.MinusContainerMain(player, key, hp, avoidRemovingBone)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maskIndex = healthDef.MaskIndex
	local maxHP = healthDef.MaxHP
	local canHaveHalfCapacity = healthDef.CanHaveHalfCapacity
	
	local hpToRemove = hp
	local hpPer
	local keysToRemove
	
	if maxHP >= 1 and not healthDef.AddRemoveContainerByHP then
		keysToRemove = math.ceil(hp / maxHP)
		hpPer = maxHP
	elseif maxHP == 0 and canHaveHalfCapacity then
		keysToRemove = math.ceil(hp / 2)
		hpPer = 2
	else
		keysToRemove = hp
		hpPer = 1
	end
	
	local removingBone = maxHP > 0
	local removingBroken = healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	while keysToRemove > 0 do
		if not CustomHealthAPI.Helper.HasRemovableMaxHP(player, key, avoidRemovingBone) then
			break
		end
		
		local removed = CustomHealthAPI.Helper.TryRemoveMaxFromMaskByKey(player, key)
		if not removed then
			if CustomHealthAPI.Helper.OtherMaskHasMaxForRemoval(player, maskIndex, key, avoidRemovingBone) then
				removed = CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromMask(player, maskIndex, removingBone, removingBroken, avoidRemovingBone)
			else
				removed = CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromAnywhere(player, removingBone, removingBroken, avoidRemovingBone)
			end
			if not removed then
				break
			end
		end
		
		keysToRemove = keysToRemove - 1
		hpToRemove = hpToRemove - hpPer
	end
	
	while CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 do
		if not CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, true) then
			break
		end
	end
	
	return math.max(0, hpToRemove) * -1
end

function CustomHealthAPI.Helper.AddContainerMain(player, key, hp, avoidRemovingBone, convertedMaxInsertFront)
	if hp > 0 then
		return CustomHealthAPI.Helper.PlusContainerMain(player, key, hp, false, convertedMaxInsertFront)
	elseif hp < 0 then
		return CustomHealthAPI.Helper.MinusContainerMain(player, key, math.abs(hp), avoidRemovingBone)
	end
	return 0
end
