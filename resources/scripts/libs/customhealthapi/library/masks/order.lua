local redHealthOrder = nil
local otherHealthOrder = nil
local overlayHealthLayerOrders = nil
local overlayHealthLayerFlags = {}
local afterHealthIconOrder = nil
local belowHealthIconOrder = nil

-- Returns the masks set / layer for the given key.
-- The key's specific mask is included within this mask set.
function CustomHealthAPI.Helper.GetMaskSetForKey(player, key)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.RED then
		return data.RedHealthMasks
	elseif healthDef.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
		return data.OverlayHealthMaskLayers[healthDef.OverlayLayerIndex]
	else--if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.SOUL or healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		return data.OtherHealthMasks
	end
end

-- Returns the specific mask that contains the given key.
function CustomHealthAPI.Helper.GetMaskForKey(player, key)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	return CustomHealthAPI.Helper.GetMaskSetForKey(player, key)[healthDef.MaskIndex]
end

-- Returns an iterator function for traversing a set of health masks. Optional boolean to traverse backwards.
function CustomHealthAPI.Helper.GetHealthMasksIterator(maskSet, backwards)
	local maskIndex = backwards and #maskSet or 1
	local mask = maskSet[maskIndex] or {}
	local healthIndex = backwards and #mask or 1
	
	local step = backwards and -1 or 1
	
	local i = 0
	
	return function()
		if not mask then return end
		while not mask[healthIndex] do
			maskIndex = maskIndex + step
			mask = maskSet[maskIndex]
			if not mask then
				return
			end
			healthIndex = backwards and #mask or 1
		end
		local retHealth = mask[healthIndex]
		local retHealthIdx = healthIndex
		healthIndex = healthIndex + step
		i = i + 1
		return maskIndex, retHealthIdx, retHealth, i
	end
end

function CustomHealthAPI.Library.GetHealthInOrder(player, ignoreResyncing, ignoreCache)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if ignoreResyncing then
		CustomHealthAPI.Helper.FinishDamageDesync(player)
	else
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.GetHealthInOrder(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return {}
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	data.Cached = data.Cached or {}
	if data.Cached.HealthInOrder and not ignoreCache then
		return data.Cached.HealthInOrder
	end
	
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	
	local redOrder = {}
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, mask[j])
		end
	end
		
	local healthOrder = {}
	local redIndex = 1
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = redOrder[redIndex], Other = mask[j]})
				redIndex = redIndex + 1
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = nil, Other = mask[j]})
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.insert(healthOrder, {Red = nil, Other = mask[j]})
			end
		end
	end
	
	CustomHealthAPI.Helper.AddOverlaysToHealthOrder(player, healthOrder)
	
	data.Cached.HealthInOrder = healthOrder
	return healthOrder
end

function CustomHealthAPI.Helper.GetOverlayFlagForHealth(key, containsRedHealth)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	
	if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			return CustomHealthAPI.Enums.OverlayFlags.BROKEN
		elseif containsRedHealth then
			return healthDef.MaxHP > 0 and CustomHealthAPI.Enums.OverlayFlags.FILLED_BONE or CustomHealthAPI.Enums.OverlayFlags.FILLED_CONTAINER
		end
		return healthDef.MaxHP > 0 and CustomHealthAPI.Enums.OverlayFlags.EMPTY_BONE or CustomHealthAPI.Enums.OverlayFlags.EMPTY_CONTAINER
	elseif healthDef.Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
		return CustomHealthAPI.Enums.OverlayFlags.SOUL
	elseif healthDef.Type == CustomHealthAPI.Enums.HealthTypes.RED then
		return CustomHealthAPI.Enums.OverlayFlags.RED
	end
	
	return 0
end

function CustomHealthAPI.Helper.CanOverlayHealthAtLayer(key, containsRedHealth, overlayLayerIndex)
	local overlayFlagForHealth = CustomHealthAPI.Helper.GetOverlayFlagForHealth(key, containsRedHealth)
	
	for priority, overlayFlags in ipairs(CustomHealthAPI.Helper.GetOverlayLayerFlags(overlayLayerIndex)) do
		if overlayFlags & overlayFlagForHealth ~= 0 then
			return true, priority
		end
	end
	
	return false
end

local function GetHealthFromOrderEntry(player, tab)
	if tab.Other.Key then
		return tab.Other
	elseif tab.Other[1] and tab.Other[2] then
		-- These are indices
		return CustomHealthAPI.Helper.GetSavedata(player).OtherHealthMasks[tab.Other[1]][tab.Other[2]]
	end
end

-- Given a healthOrder of either health tables or their indices, adds the health overlays for each index.
function CustomHealthAPI.Helper.AddOverlaysToHealthOrder(player, healthOrder)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	
	for overlayLayerIndex, overlayLayer in ipairs(data.OverlayHealthMaskLayers) do
		local overlayFlagSet = CustomHealthAPI.Helper.GetOverlayLayerFlags(overlayLayerIndex)
		local healthByPriority = {}
		local healthOrderIndexes = {}
		local stickyOverlays = {}
		local overlayedHealth = {}
		
		-- Step 1: Make a pass over any "sticky" overlays and store references to them to check later.
		for _, _, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, false) do
			if overlay.Sticky then
				stickyOverlays[overlay.Sticky] = overlay
			elseif overlay.StickFailed then
				table.insert(stickyOverlays, overlay)
			end
		end
		
		-- Step 2: Iterate over the hearts in order.
		-- Check if "sticky" overlays are still stuck to a valid, available heart.
		-- For hearts without sticky overlays, check if they are capable of being overlayed on this layer.
		-- If they can, organize them by overlay priority (ie, the order that the overlay tries to overlay health).
		for i = #healthOrder, 1, -1 do
			local tab = healthOrder[i]
			healthOrderIndexes[tab] = i
			if not tab.Overlays then
				tab.Overlays = {}
			end
			local health = GetHealthFromOrderEntry(player, tab)
			local key = health.Key
			local hasRed = tab.Red ~= nil
			if stickyOverlays[health] and CustomHealthAPI.Helper.CanOverlayHealthAtLayer(key, hasRed, CustomHealthAPI.PersistentData.HealthDefinitions[stickyOverlays[health].Key].OverlayLayerIndex) then
				-- This heart currently has a valid sticky overlay.
				table.insert(tab.Overlays, stickyOverlays[health])
				stickyOverlays[health] = nil
				overlayedHealth[tab] = true
			else
				local flagForHealth = CustomHealthAPI.Helper.GetOverlayFlagForHealth(key, hasRed)
				for overlayPriority, overlayFlags in ipairs(overlayFlagSet) do
					if overlayFlags & flagForHealth ~= 0 then
						-- This heart can be overlayed at this priority.
						if not healthByPriority[overlayPriority] then
							healthByPriority[overlayPriority] = {}
						end
						table.insert(healthByPriority[overlayPriority], tab)
						break
					end
				end
			end
		end
		
		-- Step 3: If there are any sticky overlays whose stick target is no longer available/valid, try to move them to a different nearby heart.
		for _, unstuckOverlay in pairs(stickyOverlays) do
			local prevIdx = unstuckOverlay.StickyIndex
			unstuckOverlay.Sticky = nil
			unstuckOverlay.StickFailed = true
			local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[unstuckOverlay.Key]
			local rightIdx = prevIdx or 0
			local leftIdx = prevIdx-1
			while overlayDef.OverlayMode == CustomHealthAPI.Enums.OverlayMode.STICKY_LITE and prevIdx and (healthOrder[leftIdx] or healthOrder[rightIdx]) do
				local left = healthOrder[leftIdx]
				local leftHealth = left and not overlayedHealth[left] and GetHealthFromOrderEntry(player, left)
				local leftCompat, leftPriority
				if leftHealth then
					leftCompat, leftPriority = CustomHealthAPI.Helper.CanOverlayHealthAtLayer(leftHealth.Key, left.Red ~= nil, overlayDef.OverlayLayerIndex)
				end
				
				local right = healthOrder[rightIdx]
				local rightHealth = right and not overlayedHealth[right] and GetHealthFromOrderEntry(player, right)
				local rightCompat, rightPriority
				if rightHealth then
					rightCompat, rightPriority = CustomHealthAPI.Helper.CanOverlayHealthAtLayer(rightHealth.Key, right.Red ~= nil, overlayDef.OverlayLayerIndex)
				end
				
				local chosen
				
				if leftCompat and rightCompat then
					if leftPriority <= rightPriority then
						chosen = leftIdx
					else
						chosen = rightIdx
					end
				elseif leftCompat then
					chosen = leftIdx
				elseif rightCompat then
					chosen = rightIdx
				end
				
				if chosen then
					local tab = healthOrder[chosen]
					unstuckOverlay.Sticky = GetHealthFromOrderEntry(player, tab)
					unstuckOverlay.StickyIndex = chosen
					unstuckOverlay.StickFailed = nil
					overlayedHealth[tab] = true
					table.insert(tab.Overlays, unstuckOverlay)
					break
				end
				
				leftIdx = leftIdx - 1
				rightIdx = rightIdx + 1
			end
		end
		
		-- Step 4: Go through the priority order of health able to be overlayed for this layer.
		-- Allocate the available overlays to the health, in order of priority and overlay ordering.
		local overlayIter = CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, false)
		for overlayPriority, overlayFlags in ipairs(overlayFlagSet) do
			local healthList = healthByPriority[overlayPriority] or {}
			local reversed = overlayFlags & CustomHealthAPI.Enums.OverlayFlags.REVERSE_ORDER ~= 0
			local startIdx = reversed and #healthList or 1
			local endIdx = reversed and 1 or #healthList
			local step = reversed and -1 or 1
			local noOverlaysLeft = false
			for i=startIdx, endIdx, step do
				local tab = healthList[i]
				if not overlayedHealth[tab] then
					local overlay
					while not overlay do
						local _, _, nextOverlay = overlayIter()
						if not nextOverlay then
							break
						end
						local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[nextOverlay.Key]
						if not nextOverlay.Sticky and not (nextOverlay.StickFailed and overlayDef.OverlayMode == CustomHealthAPI.Enums.OverlayMode.STICKY_STRICT) then
							overlay = nextOverlay
						end
					end
					if not overlay then
						noOverlaysLeft = true
						break
					end
					local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[overlay.Key]
					if overlayDef.OverlayMode == CustomHealthAPI.Enums.OverlayMode.STICKY_STRICT or overlayDef.OverlayMode == CustomHealthAPI.Enums.OverlayMode.STICKY_LITE then
						overlay.Sticky = GetHealthFromOrderEntry(player, tab)
						overlay.StickyIndex = healthOrderIndexes[tab]
						overlay.StickFailed = nil
					end
					table.insert(tab.Overlays, overlay)
					overlayedHealth[tab] = true
					if overlay.Key == "GOLDEN_HEART" then
						tab.IsGold = true
					end
				end
			end
			if noOverlaysLeft then
				break
			end
		end
	end
end

local function CreateHealthOrder(healthDefs)
	local healthOrder = {}
	
	-- Sort health definitions so that they are grouped together by mask.
	CustomHealthAPI.Helper.SortByAttributes(healthDefs, {"SortOrder", "Key"})
	
	local prev = nil
	for _, health in ipairs(healthDefs) do
		if #healthOrder == 0 or (prev and prev.SortOrder < health.SortOrder) then
			-- Start a new mask.
			table.insert(healthOrder, {health.Key})
		else
			table.insert(healthOrder[#healthOrder], health.Key)
		end
		health.MaskIndex = #healthOrder
		prev = health
	end
	
	return healthOrder
end

function CustomHealthAPI.Helper.InitializeRedHealthOrder()
	local redHealthDefs = CustomHealthAPI.Helper.QueryHealthDefinitions(function(health)
		return health.Type == CustomHealthAPI.Enums.HealthTypes.RED
	end)
	redHealthOrder = CreateHealthOrder(redHealthDefs)
	return redHealthOrder
end

function CustomHealthAPI.Helper.InitializeOtherHealthOrder()
	local otherHealthDefs = CustomHealthAPI.Helper.QueryHealthDefinitions(function(health)
		return health.Type == CustomHealthAPI.Enums.HealthTypes.SOUL or health.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER
	end)
	otherHealthOrder = CreateHealthOrder(otherHealthDefs)
	return otherHealthOrder
end

-- Initializes the individual "layers" of overlay health.
-- The "first" layer is the bottom one, both visually and functionally.
-- This construction also enforces layer sharing rules, preventing incompatable overlays from sharing the same layer.
function CustomHealthAPI.Helper.InitializeOverlayHealthLayerOrders()
	local overlayHealthDefs = CustomHealthAPI.Helper.QueryHealthDefinitions(function(health)
		return health.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY
	end)
	
	-- Sort the overlay definitions so that the overlays that should be on the same layer are grouped together.
	CustomHealthAPI.Helper.SortByAttributes(overlayHealthDefs, {"OverlayLayerOrder", "OverlayFlags", "AllowSharedOverlayLayer", "SortOrder", "Key"}, {false, true, true, false, false})
	
	local overlayLayers = {}
	overlayHealthLayerFlags = {}
	
	local prev = nil
	for i, health in ipairs(overlayHealthDefs) do
		if #overlayLayers == 0 or (prev and prev.OverlayLayerOrder < health.OverlayLayerOrder) or not health.AllowSharedOverlayLayer or CustomHealthAPI.Helper.CompareAny(prev.OverlayFlags, health.OverlayFlags) ~= nil then
			-- Start a new layer.
			table.insert(overlayLayers, {health})
			overlayHealthLayerFlags[#overlayLayers] = health.OverlayFlags
		else
			table.insert(overlayLayers[#overlayLayers], health)
		end
		health.OverlayLayerIndex = #overlayLayers
		prev = health
	end
	
	for i, healthDefs in ipairs(overlayLayers) do
		overlayLayers[i] = CreateHealthOrder(healthDefs)
	end
	
	overlayHealthLayerOrders = overlayLayers
	return overlayHealthLayerOrders
end

function CustomHealthAPI.Helper.InitializeAfterHealthIconOrder()
	local afterHealthIconDefs = CustomHealthAPI.Helper.QueryHealthDefinitions(function(health)
		return health.Type == CustomHealthAPI.Enums.HealthTypes.AFTER_HEALTH_ICON
	end)
	afterHealthIconOrder = CreateHealthOrder(afterHealthIconDefs)
	return afterHealthIconOrder
end

function CustomHealthAPI.Helper.InitializeBelowHealthIconOrder()
	local belowHealthIconDefs = CustomHealthAPI.Helper.QueryHealthDefinitions(function(health)
		return health.Type == CustomHealthAPI.Enums.HealthTypes.BELOW_HEALTH_ICON
	end)
	belowHealthIconOrder = CreateHealthOrder(belowHealthIconDefs)
	return belowHealthIconOrder
end

function CustomHealthAPI.Helper.GetOverlayLayerFlags(overlayLayerIndex)
	return overlayHealthLayerFlags[overlayLayerIndex]
end

function CustomHealthAPI.Helper.GetRedHealthOrder()
	if not redHealthOrder then
		CustomHealthAPI.Helper.InitializeRedHealthOrder()
	end
	return redHealthOrder
end

function CustomHealthAPI.Helper.GetOtherHealthOrder()
	if not otherHealthOrder then
		CustomHealthAPI.Helper.InitializeOtherHealthOrder()
	end
	return otherHealthOrder
end

function CustomHealthAPI.Helper.GetOverlayHealthLayerOrders()
	if not overlayHealthLayerOrders then
		CustomHealthAPI.Helper.InitializeOverlayHealthLayerOrders()
	end
	return overlayHealthLayerOrders
end

function CustomHealthAPI.Helper.GetAfterHealthIconOrder()
	if not afterHealthIconOrder then
		CustomHealthAPI.Helper.InitializeAfterHealthIconOrder()
	end
	return afterHealthIconOrder
end

function CustomHealthAPI.Helper.GetBelowHealthIconOrder()
	if not belowHealthIconOrder then
		CustomHealthAPI.Helper.InitializeBelowHealthIconOrder()
	end
	return belowHealthIconOrder
end

-- Deprecated for performance reasons
function CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	return
end
