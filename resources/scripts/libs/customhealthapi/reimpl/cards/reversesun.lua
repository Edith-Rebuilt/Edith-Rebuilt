function CustomHealthAPI.Helper.HandleReverseSun(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local otherMasks = data.OtherHealthMasks or {}
	
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].MaskIndex
	local boneContainingMask = otherMasks[maskIndex]
	local bonePriority = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].RemovePriority
	
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				if (maxHpOfHealth <= 0 or removePriorityOfHealth <= bonePriority) and health.Key ~= "BONE_HEART" then
					if i < maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, 1, {Key = "BONE_HEART", HP = 1, HalfCapacity = false, ReverseSun = health})
					elseif i > maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, {Key = "BONE_HEART", HP = 1, HalfCapacity = false, ReverseSun = health})
					else
						mask[j] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false, ReverseSunKey = health.Key, ReverseSun = health}
					end
				end
			end
		end
	end
	
	data.HasReverseSun = true
end

function CustomHealthAPI.Helper.HandleReverseSunSyncing(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if data.HasReverseSun then
		local effects = player:GetEffects()
		if not effects:HasNullEffect(NullItemID.ID_REVERSE_SUN) then
			local otherMasks = data.OtherHealthMasks or {}
			
			local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].MaskIndex
			local boneContainingMask = otherMasks[maskIndex]
			local bonePriority = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].RemovePriority
			
			for i = #boneContainingMask, 1, -1 do
				local health = boneContainingMask[i]
				if health.ReverseSun then
					local maskIndexOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[health.ReverseSun.Key].MaskIndex
					if maskIndexOfKey < maskIndex then
						table.remove(boneContainingMask, i)
						table.insert(otherMasks[maskIndexOfKey], 1, health.ReverseSun)
					elseif maskIndexOfKey > maskIndex then
						table.remove(boneContainingMask, i)
						table.insert(otherMasks[maskIndexOfKey], health.ReverseSun)
					else
						boneContainingMask[i] = health.ReverseSun
					end
				end
			end
			
			
			data.HasReverseSun = nil
		end
	end
end

