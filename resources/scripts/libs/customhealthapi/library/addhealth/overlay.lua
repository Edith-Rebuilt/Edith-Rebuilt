function CustomHealthAPI.Helper.HandleEternalHearts(player)
	local key = "ETERNAL_HEART"
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maskLayer = CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	
	local singleEternals = {}
	
	local hpToAdd = 0
	
	for maskIdx, hpIdx, health in CustomHealthAPI.Helper.GetHealthMasksIterator(maskLayer, true) do
		if health.Key == key then
			if health.HP >= 2 then
				table.remove(maskLayer[maskIdx], hpIdx)
				hpToAdd = hpToAdd + 2
			elseif health.HP == 1 then
				table.insert(singleEternals, {maskIdx, hpIdx})
			end
		end
	end
	
	-- Shouldn't happen, but
	while #singleEternals > 1 do
		local first = table.remove(singleEternals, 1)
		local second = table.remove(singleEternals, 1)
		table.remove(maskLayer[first[1]], first[2])
		table.remove(maskLayer[second[1]], second[2])
		hpToAdd = hpToAdd + 2
	end
	
	if hpToAdd > 0 then
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, 2) -- Play eternal heart animation
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 2)
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", 2)
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 2)
		end
	end
end

function CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	return CustomHealthAPI.Helper.GetMaskSetForKey(player, key)
end

function CustomHealthAPI.Helper.GetRoomInOverlayLayer(player, key)
	local maskLayer = CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	local layerIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].OverlayLayerIndex
	
	local current = CustomHealthAPI.Helper.GetTotalKeysInAllMasks(player, maskLayer)
	local limit = CustomHealthAPI.Helper.GetNumOverlayableHearts(player, layerIndex)
	
	return limit - current
end

function CustomHealthAPI.Helper.TryReplacingOverlayHP(player, key, hpAddedByKey, overflowedHP)
	local convertingToHealthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maskLayer = CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	
	local healthToConvert = nil
	local healthToConvertDef = nil
	local healthMaskIndex = nil
	local healthIndexInMask = nil
	
	for maskIdx, hpIdx, health in CustomHealthAPI.Helper.GetHealthMasksIterator(maskLayer, true) do
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		
		if healthDef.Key ~= convertingToHealthDef.Key and healthDef.AddPriority <= convertingToHealthDef.AddPriority and
		   (healthToConvert == nil or healthDef.AddPriority < healthToConvertDef.AddPriority)
		then
			healthToConvert = health
			healthToConvertDef = healthDef
			healthMaskIndex = maskIdx
			healthIndexInMask = hpIdx
		end
	end
	
	if healthToConvert == nil then
		return overflowedHP
	end
	
	table.remove(maskLayer[healthMaskIndex], healthIndexInMask)
	CustomHealthAPI.Helper.TriggerOverlayBroken(player, healthToConvert.Key, math.max(1, healthToConvert.HP), false)
	
	return CustomHealthAPI.Helper.TryInsertingOverlayHP(player, key, hpAddedByKey, overflowedHP, false, true)
end

function CustomHealthAPI.Helper.TryInsertingOverlayHP(player, key, hpAddedByKey, overflowedHP, ignoreNoRoom, noConvert)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maxHP = healthDef.MaxHP
	local maskLayer = CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	local mask = maskLayer[healthDef.MaskIndex]
	
	if ignoreNoRoom or CustomHealthAPI.Helper.GetRoomInOverlayLayer(player, key) > 0 then
		local newHealth = {Key = key}
		
		if maxHP <= 0 then
			newHealth.HP = 0
		else
			newHealth.HP = hpAddedByKey
			if newHealth.HP < maxHP and overflowedHP > 0 then
				local overflowAdding = math.min(overflowedHP, maxHP - newHealth.HP)
				newHealth.HP = newHealth.HP + overflowAdding
				overflowedHP = overflowedHP - overflowAdding
			end
		end
		
		table.insert(mask, newHealth)
		
		return overflowedHP
	elseif not noConvert then
		return CustomHealthAPI.Helper.TryReplacingOverlayHP(player, key, hpAddedByKey, overflowedHP)
	end
end

function CustomHealthAPI.Helper.TryHealingOverlayHP(player, key, hp, overflowedHP, ignoreNoRoom, noConvert)
	for i, health in ipairs(CustomHealthAPI.Helper.GetMaskForKey(player, key)) do
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		if health.Key == key and health.HP < healthDef.MaxHP then
			local healed = math.min(hp, healthDef.MaxHP - health.HP)
			health.HP = health.HP + healed
			hp = hp - healed
			if hp <= 0 then
				break
			end
		end
	end
	
	if hp > 0 then
		return CustomHealthAPI.Helper.TryInsertingOverlayHP(player, key, hp, overflowedHP, ignoreNoRoom, noConvert)
	end
	
	return overflowedHP
end

function CustomHealthAPI.Helper.PlusOverlayMain(player, key, hp, ignoreNoRoom, noConvert)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maxHP = healthDef.MaxHP
	local maskLayer = CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	local mask = maskLayer[healthDef.MaskIndex]
	
	local hpToAdd = hp
	local keysToAdd = math.ceil(hp / math.max(1, maxHP))
	
	local overflowedHP = 0
	for i=1, keysToAdd do
		local hpAddedByKey = math.min(hpToAdd, math.max(1, maxHP))
		hpToAdd = hpToAdd - hpAddedByKey
		
		if hpAddedByKey < maxHP and overflowedHP > 0 then
			local movedOverflow = math.min(overflowedHP, maxHP - hpAddedByKey)
			hpAddedByKey = hpAddedByKey + movedOverflow
			overflowedHP = overflowedHP - movedOverflow
		end
		
		overflowedHP = CustomHealthAPI.Helper.TryHealingOverlayHP(player, key, hpAddedByKey, overflowedHP, ignoreNoRoom, noConvert)
	end
	
	if key == "ETERNAL_HEART" then
		CustomHealthAPI.Helper.HandleEternalHearts(player)
	end
	
	return math.max(0, overflowedHP)
end

function CustomHealthAPI.Helper.MinusOverlayMain(player, key, hp)
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local maxHP = healthDef.MaxHP
	local maskLayer = CustomHealthAPI.Helper.GetOverlayMaskLayer(player, key)
	local mask = maskLayer[healthDef.MaskIndex]
	
	for i = #mask, 1, -1 do
		local health = mask[i]
		
		if health.Key == key then
			if maxHP > 0 then
				local removed = math.min(health.HP, hp)
				health.HP = health.HP - removed
				hp = hp - removed
			else
				hp = hp - 1
			end
			if health.HP <= 0 then
				table.remove(mask, i)
			end
			if hp <= 0 then
				break
			end
		end
	end
	
	return -math.max(0, hp)
end

function CustomHealthAPI.Helper.AddOverlayMain(player, key, hp)
	if hp > 0 then
		return CustomHealthAPI.Helper.PlusOverlayMain(player, key, hp)
	elseif hp < 0 then
		return CustomHealthAPI.Helper.MinusOverlayMain(player, key, math.abs(hp))
	end
	return 0
end

function CustomHealthAPI.Helper.RunPostOverlayBrokenCallback(iter, player, key, amount, wasDamage)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_OVERLAY_BROKEN)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	for callback in iterator do
		if not callback.Param or callback.Param == key or callback.Param == playerType then
			callback.Function(callback.Mod, player, key, amount, wasDamage)
		elseif type(callback.Param) == "table" then
			for _,v in pairs(callback.Param) do
				if v == key or v == playerType then
					callback.Function(callback.Mod, player, key, amount, wasDamage)
					break
				end
			end
		end
	end
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.POST_OVERLAY_BROKEN] = CustomHealthAPI.Helper.RunPostOverlayBrokenCallback

function CustomHealthAPI.Helper.TriggerOverlayBroken(player, key, amount, wasDamage)
	if key == "GOLDEN_HEART" then
		CustomHealthAPI.Helper.TriggerGoldHearts(player, amount)
	end
	CustomHealthAPI.Helper.RunPostOverlayBrokenCallback(nil, player, key, amount, wasDamage)
end

function CustomHealthAPI.Helper.HandleExcessOverlays(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	
	-- Only trigger the effect of gold hearts if our health is in a state where it wouldn't have been triggered by vanilla code.
	-- Generally this would mean that we have custom overlays occupying the same layer as the gold hearts.
	local allowGoldTrigger = CustomHealthAPI.Helper.GetTotalKeys(player, "GOLDEN_HEART", true) <= CustomHealthAPI.Helper.GetNumOverlayableHearts(player, "GOLDEN_HEART")
	
	local stickableHealth = {}
	for _, _, health in CustomHealthAPI.Helper.GetHealthMasksIterator(data.OtherHealthMasks, false) do
		stickableHealth[health] = true
	end
	
	local removed = {}
	
	for overlayLayerIndex, overlayLayer in ipairs(data.OverlayHealthMaskLayers) do
		-- Check for "sticky" overlays whose stick target has disappeared.
		for maskIdx, hpIdx, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, true) do
			local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[overlay.Key]
			
			if overlay.Sticky and not stickableHealth[overlay.Sticky] then
				overlay.Sticky = nil
				overlay.StickFailed = true
			end
			
			if overlay.StickFailed and overlayDef.OverlayMode == CustomHealthAPI.Enums.OverlayMode.STICKY_STRICT then
				removed[overlay.Key] = (removed[overlay.Key] or 0) + math.max(1, overlay.HP)
				table.remove(overlayLayer[maskIdx], hpIdx)
			end
		end
		
		-- Check for excess overlays.
		local limit = CustomHealthAPI.Helper.GetNumOverlayableHearts(player, overlayLayerIndex)
		
		while CustomHealthAPI.Helper.GetTotalKeysInAllMasks(player, overlayLayer) > limit do
			local overlayToRemove = nil
			local overlayToRemoveDef = nil
			local removeMaskIndex = nil
			local removeIndexInMask = nil
			
			for maskIdx, hpIdx, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, false) do
				local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[overlay.Key]
				
				if overlayToRemove == nil or overlayDef.AddPriority < overlayToRemoveDef.AddPriority then
					overlayToRemove = overlay
					overlayToRemoveDef = overlayDef
					removeMaskIndex = maskIdx
					removeIndexInMask = hpIdx
					if overlay.StickFailed then
						break
					end
				end
			end
			
			if not overlayToRemove then
				break
			end
			
			removed[overlayToRemove.Key] = (removed[overlayToRemove.Key] or 0) + math.max(1, overlayToRemove.HP)
			table.remove(overlayLayer[removeMaskIndex], removeIndexInMask)
		end
	end
	
	for key, amount in pairs(removed) do
		if allowGoldTrigger or key ~= "GOLDEN_HEART" then
			CustomHealthAPI.Helper.TriggerOverlayBroken(player, key, amount, false)
		end
	end
end


-- Legacy functions
function CustomHealthAPI.Helper.AddEternalMain(player, key, hp)
	CustomHealthAPI.Helper.AddOverlayMain(player, "ETERNAL_HEART", hp)
end
function CustomHealthAPI.Helper.AddGoldMain(player, key, hp)
	CustomHealthAPI.Helper.AddOverlayMain(player, key, hp)
end
function CustomHealthAPI.Helper.HandleGoldenRoom(player, doGoldEffects)
	CustomHealthAPI.Helper.HandleExcessOverlays(player)
end


function CustomHealthAPI.Helper.TriggerGoldHeartsOld(p, numTrigger)
	local player = p
	local originalPosition = player.Position
	if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
		if player:GetSubPlayer() ~= nil then
			originalPosition = player:GetSubPlayer().Position
			player:GetSubPlayer().Position = player.Position
			player = player:GetSubPlayer()
		else
			--idk fuck bone hearts in this specific scenario
			return
		end
	end
	
	local addedWhoreOfBabylonPrevention = CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	local addedBloodyBabylonPrevention = CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	
	local alabasterSlots = {[0] = false, [1] = false, [2] = false}
	local alabasterCharges = {[0] = 0, [1] = 0, [2] = 0}
	local alabasterPlayer = CustomHealthAPI.Helper.GetAlabasterBoxOwner(player)
	for i = 2, 0, -1 do
		if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterSlots[i] = true
			alabasterCharges[i] = alabasterPlayer:GetActiveCharge(i)
		end
	end
	
	local shacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	player:GetEffects():RemoveNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, shacklesDisabled)
	
	local challengeIsHaveAHeart = Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_NULL
	end
	
	local numRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local numRotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	local numSoul = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
	local blackMask = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts(player)
	local numMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local numBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
	local numGolden = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	
	if not (CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) or 
	        CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player))
	then
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, -99)
		CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, -99)
		CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, -99)
		CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, -99)
		for i = 1, numTrigger do
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, 1)
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, 1)
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, 99)
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, -1)
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, -1)
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
		end
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		
		for i = 2, 0, -1 do
			if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				alabasterPlayer:SetActiveCharge(24, i)
			end
		end
		
		local soulToAdd = numSoul
		local blackToMask = blackMask
		while soulToAdd > 0 do
			local soulAdding = 2
			if soulToAdd == 1 then
				soulAdding = 1
			end
			soulToAdd = soulToAdd - soulAdding
			
			if blackMask % 2 == 1 then
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
				CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, soulAdding)
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			else
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
				CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, soulAdding)
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			end
			blackMask = blackMask >> 1
		end
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, numBone)
		CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, numMax)
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, numRed - (numRotten * 2))
		CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, numRotten * 2)
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, numGolden)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	else
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
		CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, -99)
		CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, -99)
		for i = 1, numTrigger do
			CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, 1)
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, 99)
			CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, -1)
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
		end
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		
		for i = 2, 0, -1 do
			if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				alabasterPlayer:SetActiveCharge(24, i)
			end
		end
		
		local soulToAdd = numSoul
		local blackToMask = blackMask
		while soulToAdd > 0 do
			local soulAdding = 2
			if soulToAdd == 1 then
				soulAdding = 1
			end
			soulToAdd = soulToAdd - soulAdding
			
			if blackMask % 2 == 1 then
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
				CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, soulAdding)
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			else
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
				CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, soulAdding)
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			end
			blackMask = blackMask >> 1
		end
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, numBone)
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, numGolden)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	end
	
	player:GetEffects():AddNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, true, shacklesDisabled)
		
	for i = 2, 0, -1 do
		if alabasterSlots[i] then
			alabasterPlayer:SetActiveCharge(alabasterCharges[i], i)
		end
	end
	
	if addedWhoreOfBabylonPrevention then CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player) end
	if addedBloodyBabylonPrevention then CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player) end
	
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_HAVE_A_HEART
	end
	
	player.Position = originalPosition
end

function CustomHealthAPI.Helper.TriggerGoldHearts(p, numTrigger)
	local burst = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, p.Position, Vector(0, 0), p):ToEffect()
	local burstSprite = burst:GetSprite()
	burstSprite:Load("gfx/293.000_ultragreedcoins.anm2", true)
	burstSprite:Play("CrumbleNoDebris", true)
	burst:Update()
	
	local crater = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_CRATER, 0, p.Position, Vector(0, 0), p):ToEffect()
	local craterColor = Color(1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0)
	craterColor:SetColorize(10.0, 7.5, 0.0, 1.0)
	crater:SetColor(craterColor, 99999999, 1, false, false)
	crater:Update()
	
	local rng = p:GetDropRNG()
	for i = 1, numTrigger do
		Game():SpawnParticles(p.Position, EffectVariant.GOLD_PARTICLE, 10, 
		                      math.random() * 12.0 + 8.0, 
		                      Color(1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0), 
		                      0)
		
		for j = 1, rng:RandomInt(6) + 3 do
			local randvec = Vector.FromAngle(math.random() * 360) * (math.random() * 3.5 + 1.5)
			local coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, p.Position + randvec, randvec, p):ToPickup()
		end
	end
	
	local midasDuration = 180 * (p:GetTrinketMultiplier(TrinketType.TRINKET_SECOND_HAND) + 1)
	for _, ent in ipairs(Isaac.FindInRadius(p.Position, 80.0, EntityPartition.ENEMY)) do
		if ent:ToNPC() and 
		   not (ent:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS) or
		        ent:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
		then
			local alreadyHasMidas = ent:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE)
			ent:AddMidasFreeze(EntityRef(p), midasDuration)
			
			if ent:IsBoss() and
			   (alreadyHasMidas or not ent:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE))
			then
				-- fuck status resistance
			end
			
			local flashColor = Color(1.0, 1.0, 1.0, 1.0, 1.0, 0.9, 0.0)
			ent:SetColor(flashColor, 15, 255, true, true)
		end
	end
	
	SFXManager():Play(SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY)
end
