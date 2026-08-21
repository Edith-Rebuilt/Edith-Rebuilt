CustomHealthAPI.PersistentData.HealthDefinitions = CustomHealthAPI.PersistentData.HealthDefinitions or {}
CustomHealthAPI.PersistentData.PickupDefinitions = CustomHealthAPI.PersistentData.PickupDefinitions or {}
CustomHealthAPI.PersistentData.PickupToHeartKeys = CustomHealthAPI.PersistentData.PickupToHeartKeys or {}
CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth = CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth or {}
CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth = CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth or {}

function CustomHealthAPI.Library.RegisterPickup(typ, var, subt, keys)
	CustomHealthAPI.PersistentData.PickupToHeartKeys[typ] = CustomHealthAPI.PersistentData.PickupToHeartKeys[typ] or {}
	CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var] = CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var] or {}
	CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var][subt] = CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var][subt] or {}
	
	for _, key in pairs(keys or {}) do
		local keyExists = false
		for _, existingKey in ipairs(CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var][subt]) do
			if key == existingKey then
				keyExists = true
				break
			end
		end
		if not keyExists then
			table.insert(CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var][subt], key)
		end
	end
end

function CustomHealthAPI.Library.RegisterPickupEntity(var, subt, info)
	if info == nil then
		return
	end

	local def = {
		Variant = var,
		SubType = subt,
		
		DropSound = info.DropSound,
		CollectSound = info.CollectSound,
		
		OnDrop = info.OnDrop,
		CanCollect = info.CanCollect,
		OnCollect = info.OnCollect,
		
		IsHeart = info.IsHeart or var == PickupVariant.PICKUP_HEART,
		IsCoin = info.IsCoin or info.IsPenny or var == PickupVariant.PICKUP_COIN,
		IsKey = info.IsKey or var == PickupVariant.PICKUP_KEY,
		IsBomb = info.IsBomb or var == PickupVariant.PICKUP_BOMB,
		IsBattery = info.IsBattery or var == PickupVariant.PICKUP_BATTERY,
		
		AllowMagneto = info.AllowMagneto ~= false,
	}

	if def.IsHeart then
		def.ManualAddHealth = info.ManualAddHealth
		def.HealthKeys = info.HealthKeys
		def.HealthAmount = info.HealthAmount
		def.AppleOfSodomValue = info.AppleOfSodomValue
		def.NoKeeperFly = info.NoKeeperFly
		def.AllowCandyHeartSoulLocketBonus = (info.AllowCandyHeartSoulLocketBonus == nil) and true or info.AllowCandyHeartSoulLocketBonus
		def.AllowImmaculateConception = (info.AllowImmaculateConception == nil) and true or info.AllowImmaculateConception
		CustomHealthAPI.Library.RegisterPickup(EntityType.ENTITY_PICKUP, var, subt, info.HealthKeys)
	end

	CustomHealthAPI.PersistentData.PickupDefinitions[var] = CustomHealthAPI.PersistentData.PickupDefinitions[var] or {}
	CustomHealthAPI.PersistentData.PickupDefinitions[var][subt] = def
end

function CustomHealthAPI.Library.RegisterHeartPickup(var, subt, info)
	if info == nil then
		return
	end
	info.IsHeart = true
	CustomHealthAPI.Library.RegisterPickupEntity(var, subt, info)
end

function CustomHealthAPI.Library.RegisterRedHealth(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART
	if key == "COIN_HEART" then
		kind = CustomHealthAPI.Enums.HealthKinds.COIN
	end

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Key = key,
		Type = CustomHealthAPI.Enums.HealthTypes.RED, 
		Kind = kind,
		MaxHP = math.max(1, math.floor(info.MaxHP + 0.5)),
		AnimationFilenames = info.AnimationFilenames,
		AnimationNames = info.AnimationNames,
		SortOrder = info.SortOrder,
		AddPriority = info.AddPriority,
		HealFlashRO = info.HealFlashRO, 
		HealFlashGO = info.HealFlashGO, 
		HealFlashBO = info.HealFlashBO,
		ProtectsDealChance = info.ProtectsDealChance,
		PrioritizeHealing = info.PrioritizeHealing,
		DamageGate = info.DamageGate,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings,  -- deprecated
		CollectSound = info.CollectSound,
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	for _, pickup in pairs(info.PickupEntities or {}) do
		CustomHealthAPI.Library.RegisterPickup(pickup.ID, pickup.Var, pickup.Sub, {key})
	end
	
	CustomHealthAPI.Helper.InitializeRedHealthOrder()
	table.insert(CustomHealthAPI.Constants.Health.RED,key)
end

function CustomHealthAPI.Library.RegisterSoulHealth(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Key = key,
		Type = CustomHealthAPI.Enums.HealthTypes.SOUL,
		Kind = kind,
		MaxHP = math.max(1, math.floor(info.MaxHP + 0.5)),
		AnimationFilename = info.AnimationFilename,
		AnimationName = info.AnimationName,
		SortOrder = info.SortOrder,
		AddPriority = info.AddPriority,
		HealFlashRO = info.HealFlashRO, 
		HealFlashGO = info.HealFlashGO, 
		HealFlashBO = info.HealFlashBO,
		PrioritizeHealing = info.PrioritizeHealing,
		DamageGate = info.DamageGate,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings,  -- deprecated
		CollectSound = info.CollectSound,
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	for _, pickup in pairs(info.PickupEntities or {}) do
		CustomHealthAPI.Library.RegisterPickup(pickup.ID, pickup.Var, pickup.Sub, {key})
	end
	
	CustomHealthAPI.Helper.InitializeOtherHealthOrder()
	table.insert(CustomHealthAPI.Constants.Health.SOUL,key)
end

function CustomHealthAPI.Library.RegisterHealthContainer(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART
	if key == "EMPTY_COIN_HEART" then
		kind = CustomHealthAPI.Enums.HealthKinds.COIN
	elseif key == "BROKEN_HEART" or key == "BROKEN_COIN_HEART" or info.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
		kind = CustomHealthAPI.Enums.HealthKinds.NONE
	end

	if info.DamageGate == nil then
		info.DamageGate = info.MaxHP > 0
	end

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Key = key,
		Type = CustomHealthAPI.Enums.HealthTypes.CONTAINER,
		KindContained = kind,
		MaxHP = math.max(0, math.floor(info.MaxHP + 0.5)),
		AnimationFilename = info.AnimationFilename,
		AnimationName = info.AnimationName,
		LayeredAnimationFilename = info.LayeredAnimationFilename,
		LayeredAnimationName = info.LayeredAnimationName,
		SortOrder = info.SortOrder,
		AddPriority = info.AddPriority,
		RemovePriority = info.RemovePriority,
		ExplicitRemovalOnly = info.ExplicitRemovalOnly,
		HealFlashRO = info.HealFlashRO, 
		HealFlashGO = info.HealFlashGO, 
		HealFlashBO = info.HealFlashBO,
		AddRemoveContainerByHP = info.AddRemoveContainerByHP,
		ForceBleedingIfFilled = info.ForceBleedingIfFilled,
		CanHaveHalfCapacity = info.CanHaveHalfCapacity,
		ProtectsDealChance = info.ProtectsDealChance,
		DamageGate = info.DamageGate,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings,  -- deprecated
		CollectSound = info.CollectSound,
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	for _, pickup in pairs(info.PickupEntities or {}) do
		CustomHealthAPI.Library.RegisterPickup(pickup.ID, pickup.Var, pickup.Sub, {key})
	end
	
	CustomHealthAPI.Helper.InitializeOtherHealthOrder()
	table.insert(CustomHealthAPI.Constants.Health.CONTAINER,key)
end

function CustomHealthAPI.Library.RegisterHealthOverlay(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART
	
	if not info.OverlayFlags then
		info.OverlayFlags = CustomHealthAPI.Enums.OverlayFlagSets.GOLDEN
	elseif type(info.OverlayFlags) ~= "table" then
		info.OverlayFlags = {info.OverlayFlags}
	end
	
	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Key = key,
		Type = CustomHealthAPI.Enums.HealthTypes.OVERLAY,
		Kind = kind,
		MaxHP = info.MaxHP and math.max(0, math.floor(info.MaxHP + 0.5)) or 0,
		AnimationFilename = info.AnimationFilename,
		AnimationName = info.AnimationName,
		OverlayLayerOrder = info.OverlayLayerOrder or 0,
		AllowSharedOverlayLayer = info.AllowSharedOverlayLayer ~= false,
		OverlayMode = info.OverlayMode or CustomHealthAPI.Enums.OverlayMode.NORMAL,
		OverlayFlags = info.OverlayFlags,
		SortOrder = info.SortOrder or 0,
		AddPriority = info.AddPriority or 0,
		HealFlashRO = info.HealFlashRO, 
		HealFlashGO = info.HealFlashGO, 
		HealFlashBO = info.HealFlashBO,
		IgnoreBleeding = info.IgnoreBleeding,
		DamageGate = info.DamageGate,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings,  -- deprecated
		CollectSound = info.CollectSound,
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	for _, pickup in pairs(info.PickupEntities or {}) do
		CustomHealthAPI.Library.RegisterPickup(pickup.ID, pickup.Var, pickup.Sub, {key})
	end
	
	CustomHealthAPI.Helper.InitializeOverlayHealthLayerOrders()
	table.insert(CustomHealthAPI.Constants.Health.OVERLAY,key)
end

function CustomHealthAPI.Library.RegisterAfterHealthIcon(key, info)
	if info == nil then
		return
	end

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Key = key,
		Type = CustomHealthAPI.Enums.HealthTypes.AFTER_HEALTH_ICON,
		SortOrder = info.SortOrder,
		ShouldRenderFunc = info.ShouldRenderFunc,
		OnRenderFunc = info.OnRenderFunc,
	}
	
	CustomHealthAPI.Helper.InitializeAfterHealthIconOrder()
end

function CustomHealthAPI.Library.RegisterBelowHealthIcon(key, info)
	if info == nil then
		return
	end

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Key = key,
		Type = CustomHealthAPI.Enums.HealthTypes.BELOW_HEALTH_ICON,
		SortOrder = info.SortOrder,
		ShouldRenderFunc = info.ShouldRenderFunc,
		OnRenderFunc = info.OnRenderFunc,
		RowsUsed = info.RowsUsed,
		OffsetAsHP = info.OffsetAsHP,
		IgnoreUnknownCurse = info.IgnoreUnknownCurse
	}
	
	CustomHealthAPI.Helper.InitializeBelowHealthIconOrder()
end

function CustomHealthAPI.Helper.UpdateHealthDefinitionsFromOldVersions()
	for key, info in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		if info.Type == CustomHealthAPI.Enums.HealthTypes.RED then
			info.Key = info.Key or key
		elseif info.Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			info.Key = info.Key or key
		elseif info.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			info.Key = info.Key or key
			if info.DamageGate == nil then
				info.DamageGate = info.MaxHP > 0
			end
		elseif info.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
			info.Key = info.Key or key
			info.MaxHP = info.MaxHP or 0
			info.OverlayLayerOrder = info.OverlayLayerOrder or 0
			info.AllowSharedOverlayLayer = info.AllowSharedOverlayLayer ~= false
			info.OverlayMode = info.OverlayMode or CustomHealthAPI.Enums.OverlayMode.NORMAL
			info.OverlayFlags = info.OverlayFlags or CustomHealthAPI.Enums.OverlayFlagSets.GOLDEN
			info.SortOrder = info.SortOrder or 0
			info.AddPriority = info.AddPriority or 0
		end
		
		for _, pickup in pairs(info.PickupEntities or {}) do
			CustomHealthAPI.Library.RegisterPickup(pickup.ID, pickup.Var, pickup.Sub, {key})
		end
	end
end
CustomHealthAPI.Helper.UpdateHealthDefinitionsFromOldVersions()

function CustomHealthAPI.Library.DefineContainerForRedHealth(redKey, containerKey, animationFilename, animationNames)
	if CustomHealthAPI.PersistentData.HealthDefinitions[redKey] and CustomHealthAPI.PersistentData.HealthDefinitions[redKey].Type == CustomHealthAPI.Enums.HealthTypes.RED then
		local redHealth = CustomHealthAPI.PersistentData.HealthDefinitions[redKey]
		redHealth.AnimationFilenames[containerKey] = animationFilename
		redHealth.AnimationNames[containerKey] = animationNames
	end
end

function CustomHealthAPI.Library.RegisterCharacterAsRedHealthless(playertype)
    --disabling as this is currently untested for modded characters
	--CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playertype] = true
end

function CustomHealthAPI.Library.RegisterCharacterAsConvertingMaxHealth(playertype, keyToConvertTo)
    --disabling as this is currently untested for modded characters
	--CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] = keyToConvertTo
end

function CustomHealthAPI.Library.GetInfoOfKey(key, var)
	local info = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	if info then
		return info[var]
	end
	return nil
end

function CustomHealthAPI.Library.GetInfoOfHealth(health, var)
	if health and health.Key then
		return CustomHealthAPI.Library.GetInfoOfKey(health.Key, var)
	end
	return nil
end

-- Just adding this for consistency so outside users that don't want to call the table can call this
function CustomHealthAPI.Library.GetHealthDefinition(key)
	return CustomHealthAPI.PersistentData.HealthDefinitions[key]
end

-- Requires an EntityPickup, and returns the CHAPI Health key if the entity is a registered heart
function CustomHealthAPI.Library.GetKeyOfPickup(pickup)
	if pickup.ToPickup ~= nil then pickup = pickup:ToPickup() end
	if pickup then
		local typ = pickup.Type
		local var = pickup.Variant
		local subt = pickup.SubType
		if CustomHealthAPI.PersistentData.PickupToHeartKeys[typ] and CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var] then
			return CustomHealthAPI.PersistentData.PickupToHeartKeys[typ][var][subt]
		end
	end
	return nil;
end

-- Requires an EntityPickup, and returns the CHAPI Health definition if the entity is a registered heart
function CustomHealthAPI.Helper.GetHealthOfPickup(pickup)
	if pickup.ToPickup ~= nil then pickup = pickup:ToPickup() end
	if pickup then
		local key = CustomHealthAPI.Library.GetKeyOfPickup(pickup)
		if key then
			return CustomHealthAPI.PersistentData.HealthDefinitions[key]
		end
	end
	return nil;
end

-- Requires an EntityPickup, and returns the CHAPI Pickpup definition if the entity is a registered pickup
function CustomHealthAPI.Helper.GetPickupDefinition(pickup)
	if pickup.ToPickup ~= nil then pickup = pickup:ToPickup() end
	if pickup then
		local var = pickup.Variant
		local subt = pickup.SubType
		if CustomHealthAPI.PersistentData.PickupDefinitions[var] then
			return CustomHealthAPI.PersistentData.PickupDefinitions[var][subt]
		end
	end
	return nil;
end

function CustomHealthAPI.Helper.QueryHealthDefinitions(condFunc)
	local defs = {}

	for key, health in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		if condFunc(health) then
			table.insert(defs, health)
		end
	end

	return defs
end

-- Generic comparator.
-- Returns `true` if a < b, `false` if a > b, or `nil` if a == b.
-- Optional "descending" boolean flips the boolean returns.
-- nil is considered "less" than any non-nil value.
-- Compares tables by recursing into them.
-- Otherwise, the two things need to be the same type to compare them.
function CustomHealthAPI.Helper.CompareAny(a, b, descending)
	if descending == nil then
		descending = false
	end
	if not a or not b or type(a) == "boolean" or type(b) == "boolean" then
		if not a and b then
			return not descending
		elseif a and not b then
			return descending
		end
	elseif type(a) == "table" or type(b) == "table" then
		if type(a) ~= "table" then
			a = {a}
		end
		if type(b) ~= "table" then
			b = {b}
		end
		for i=1, math.min(#a, #b)+1 do
			local result = CustomHealthAPI.Helper.CompareAny(a[i], b[i], descending)
			if result ~= nil then
				return result
			end
		end
	elseif type(a) ~= type(b) then
		return  -- Can't compare
	elseif a < b then
		return not descending
	elseif a > b then
		return descending
	end
end

-- Provided a table and a list of attributes contained within the table, returns `true` if a < b, `false` if a > b, or `nil` if a == b.
-- descendingAttrs is an optional boolean/table to reverse the ordering for specific attributes.
function CustomHealthAPI.Helper.CompareByAttributes(a, b, attributes, descendingAttrs)
	local descendingAttrsIsTable = type(descendingAttrs) == "table"
	for i, k in ipairs(attributes) do
		local descending
		if descendingAttrsIsTable then
			descending = descendingAttrs[i] == true
		else
			descending = descendingAttrs == true
		end
		
		local result = CustomHealthAPI.Helper.CompareAny(a[k], b[k], descending)
		if result ~= nil then
			return result
		end
	end
end

-- Provided a table and a list of attributes contained within the table, sorts the table, in ascending order by default.
-- descendingAttrs is an optional boolean/table to reverse the ordering for specific attributes.
function CustomHealthAPI.Helper.SortByAttributes(tab, attributes, descendingAttrs)
	table.sort(tab, function(a, b)
		return CustomHealthAPI.Helper.CompareByAttributes(a, b, attributes, descendingAttrs)
	end)
end
