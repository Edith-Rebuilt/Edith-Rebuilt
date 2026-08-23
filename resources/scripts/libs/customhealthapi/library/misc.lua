function CustomHealthAPI.Library.ResetPlayerData(player, includeOtherData)
	CustomHealthAPI.Helper.ClearSavedata(player)
	
	if includeOtherData then
		CustomHealthAPI.Helper.ClearOtherData(player)
	end
	
	local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
	CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i] = nil
	
	local subPlayer = player:GetSubPlayer()
	
	if subPlayer ~= nil then
		CustomHealthAPI.Helper.ClearSavedata(subPlayer)
		if includeOtherData then
			CustomHealthAPI.Helper.ClearOtherData(subPlayer)
		end
	end
end

function CustomHealthAPI.Library.GetPickupHeartKeys(pickup)
	if CustomHealthAPI.PersistentData.PickupToHeartKeys[pickup.Type] and CustomHealthAPI.PersistentData.PickupToHeartKeys[pickup.Type][pickup.Variant] then 
		return CustomHealthAPI.PersistentData.PickupToHeartKeys[pickup.Type][pickup.Variant][pickup.SubType]
	end
	return {}
end

function CustomHealthAPI.Library.PlayHealthCollectSound(key)
	local def = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	if def then
		return CustomHealthAPI.Helper.PlaySound(def.CollectSound)
	end
end

function CustomHealthAPI.Library.PlayCustomPickupCollectSound(pickupVar, pickupSubt)
	local def = CustomHealthAPI.Library.GetPickupDefinition(pickupVar, pickupSubt)
	if def then
		return CustomHealthAPI.Helper.PlaySound(def.CollectSound)
	end
end

function CustomHealthAPI.Library.GetPickupDefinition(pickupVar, pickupSubt)
	local tab = CustomHealthAPI.PersistentData.PickupDefinitions[pickupVar]
	if tab then
		return tab[pickupSubt] or tab[-1]
	end
end
