function CustomHealthAPI.Helper.AddProcessTakeDamageCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.ProcessTakeDamageCallback, EntityType.ENTITY_PLAYER)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddProcessTakeDamageCallback)

function CustomHealthAPI.Helper.RemoveProcessTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.ProcessTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveProcessTakeDamageCallback)

function CustomHealthAPI.Helper.IsDebugThreeActive()
	local s = Isaac.ExecuteCommand("debug 3")
	Isaac.ExecuteCommand("debug 3")
	
	return s == "Disabled debug flag."
end

function CustomHealthAPI.Helper.RunPrePlayerDamageCallback(iter, player, amount, flags, source, countdown)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_PLAYER_DAMAGE)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, amount, flags, source, countdown)
			if type(ret) == "table" then
				if ret.Amount ~= nil then
					amount = ret.Amount
					returnTable.Amount = ret.Amount
				end
				if ret.Flags ~= nil then
					flags = ret.Flags
					returnTable.Flags = ret.Flags
				end
				if ret.Prevent ~= nil then
					returnTable.Prevent = true
					break
				end
			elseif ret ~= nil then
				returnTable.Prevent = true
				break
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_PLAYER_DAMAGE] = CustomHealthAPI.Helper.RunPrePlayerDamageCallback

function CustomHealthAPI.Mod:ProcessTakeDamageCallback(ent, amount, flags, source, countdown)
	if ent.Type ~= EntityType.ENTITY_PLAYER then
		return
	end
	
	local player = ent:ToPlayer()
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	if pdata.EnabledDebugThreeForDamage then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Disabled debug flag."
		pdata.EnabledDebugThreeForDamage = nil
	elseif CustomHealthAPI.Helper.IsDebugThreeActive() then
		return
	end
	
	local returnTable = CustomHealthAPI.Helper.RunPrePlayerDamageCallback(nil, player, amount, flags, source, countdown)
	if type(returnTable) == "table" then
		if returnTable.Amount ~= nil then
			amount = returnTable.Amount
		end
		if returnTable.Flags ~= nil then
			flags = returnTable.Flags
		end
		if returnTable.Prevent ~= nil then
			return false
		end
	elseif returnTable ~= nil then
		return false
	end
	
	if not player or
	   CustomHealthAPI.Helper.PlayerIsIgnored(player) or
	   math.floor(amount + 0.5) < 1.0 or
	   player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION) == 1 or
	   player:IsCoopGhost() or
	   CustomHealthAPI.Helper.GetTotalHP(player, true) <= 0
	then
		return
	end
	
	CustomHealthAPI.Helper.GetOtherData(player).InDamageCallback = nil
	
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	if player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B or
	   player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)
	then
		CustomHealthAPI.Helper.EmptyAllHealth(player)
		return
	elseif source.Entity and source.Entity.Type == EntityType.ENTITY_DARK_ESAU then
		return
	end
	
	CustomHealthAPI.Helper.GetOtherData(player).InDamageCallback = Isaac.GetFrameCount()
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_GLASS_CANNON) and
	   flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS and 
	   flags & DamageFlag.DAMAGE_NO_PENALTIES ~= DamageFlag.DAMAGE_NO_PENALTIES
	then
		for i = 2, 0, -1 do
			if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_GLASS_CANNON then
				player:RemoveCollectible(CollectibleType.COLLECTIBLE_GLASS_CANNON, true, i, true)
				CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible(player, 
				                                                                  CollectibleType.COLLECTIBLE_BROKEN_GLASS_CANNON, 
				                                                                  0, 
				                                                                  false, 
				                                                                  i, 
				                                                                  0,
				                                                                  ItemPoolType.POOL_TREASURE)
				CustomHealthAPI.Helper.GetSavedata(player).GlassCannonBroke = true
			end
		end
	end
	
	if flags & DamageFlag.DAMAGE_FAKE ~= DamageFlag.DAMAGE_FAKE then	
		local basegameHpTotalBefore = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true) +
		                              CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true) +
		                              CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
		local didDamage = CustomHealthAPI.Helper.HandleDamage(player, amount, flags, source, countdown)
		local basegameHpTotalAfter = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true) +
		                             CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true) +
		                             CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		if not data then
			CustomHealthAPI.Helper.CheckIfHealthOrderSet()
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
			data = CustomHealthAPI.Helper.GetSavedata(player)
		end
		data.HandlingDamageCanShackle = not (player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) or 
											 player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED))
		data.HandlingDamage = true
		data.HandlingDamageAmount = amount
		data.HandlingDamageFlags = flags
		data.HandlingDamageSource = source
		data.HandlingDamageCountdown = countdown
		
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MISSING_PAGE_2) then
			if REPENTOGON and not player:IsCollectibleBlocked(CollectibleType.COLLECTIBLE_MISSING_PAGE_2) then
				player:BlockCollectible(CollectibleType.COLLECTIBLE_MISSING_PAGE_2)
				data.BlockingMissingPage2 = true
				data.ShouldMissingPage2 = basegameHpTotalBefore > 2 and basegameHpTotalAfter <= 2
			end
		end
		
		CustomHealthAPI.Helper.GetOtherData(player).ShouldActivateScapular = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_SCAPULAR)
		
		return
	else
		CustomHealthAPI.Helper.GetOtherData(player).InDamageCallback = nil
		return
	end
end

function CustomHealthAPI.Helper.AddHandleBloodOathCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, -1 * math.huge, CustomHealthAPI.Mod.HandleBloodOathCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleBloodOathCallback)

function CustomHealthAPI.Helper.RemoveHandleBloodOathCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.HandleBloodOathCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleBloodOathCallback)

local isCustomBloodOath = false
CustomHealthAPI.PersistentData.OverrideCustomBloodOathHandling = CustomHealthAPI.PersistentData.OverrideCustomBloodOathHandling or false
function CustomHealthAPI.Mod:HandleBloodOathCallback(ent, amount, flags, source, countdown)
	if CustomHealthAPI.PersistentData.OverrideCustomBloodOathHandling then
		return
	end

	local isBloodOath = source.Entity and 
	                    source.Entity.Type == EntityType.ENTITY_FAMILIAR and 
	                    source.Entity.Variant == FamiliarVariant.BLOOD_OATH
	
	if isBloodOath and not isCustomBloodOath then
		if ent.Type ~= EntityType.ENTITY_PLAYER then
			return
		end
		
		if CustomHealthAPI.Helper.IsDebugThreeActive() then
			-- NOTE: Probably needs special handling but for now it's at least functional
			return
		end
		
		local player = ent:ToPlayer()
		local prevent = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.PRE_BLOOD_OATH_DAMAGE, player:GetPlayerType(), player, amount, flags, source, countdown)
		if prevent ~= nil then
			return false
		end
	
		if not player or
		   CustomHealthAPI.Helper.PlayerIsIgnored(player) or
		   math.floor(amount + 0.5) < 1.0 or
		   player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION) == 1 or
		   player:IsCoopGhost() or
		   CustomHealthAPI.Helper.GetTotalHP(player, true) <= 0
		then
			return
		end
		
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		if not data then
			CustomHealthAPI.Helper.CheckIfHealthOrderSet()
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
			data = CustomHealthAPI.Helper.GetSavedata(player)
		end
		local eternalLayer = data.OverlayHealthMaskLayers[CustomHealthAPI.PersistentData.HealthDefinitions["ETERNAL_HEART"].OverlayLayerIndex]
		local eternalMaskIdx = CustomHealthAPI.PersistentData.HealthDefinitions["ETERNAL_HEART"].MaskIndex
		local cachedEternalMask = eternalLayer[eternalMaskIdx]
		eternalLayer[eternalMaskIdx] = {}
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		local bloodOath = source.Entity:ToFamiliar()
		bloodOath.Hearts = 0
		
		while not ( CustomHealthAPI.Helper.GetTotalRedHP(player, nil, nil, true) <= 0 or
		            (CustomHealthAPI.Helper.GetTotalRedHP(player, false, true, true) == 1 and
		             CustomHealthAPI.Helper.GetTotalSoulHP(player, nil, nil, true) <= 0 and
				     CustomHealthAPI.Helper.GetTotalBoneHP(player, nil, true) <= 0))
		do
			CustomHealthAPI.Helper.FinishDamageDesync(player)
			
			if player:GetDamageCooldown() > 0 then
				player:ResetDamageCooldown() -- WHY IS DAMAGE INVINCIBLE NOT WORKING
			end
			
			isCustomBloodOath = true
			local tookDamage = CustomHealthAPI.Helper.HookFunctions.TakeDamage(player,
			                                                                   1, 
			                                                                   DamageFlag.DAMAGE_NOKILL + 
			                                                                   DamageFlag.DAMAGE_RED_HEARTS +
			                                                                   DamageFlag.DAMAGE_ISSAC_HEART + 
			                                                                   DamageFlag.DAMAGE_INVINCIBLE + 
			                                                                   DamageFlag.DAMAGE_IV_BAG +
			                                                                   DamageFlag.DAMAGE_NO_MODIFIERS, 
			                                                                   source, 
			                                                                   countdown,
			                                                                   CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer,
			                                                                   true)
			isCustomBloodOath = false
			
			if not tookDamage then
				break
			end
			
			bloodOath.Hearts = bloodOath.Hearts + 1
		end
		
		CustomHealthAPI.Helper.FinishDamageDesync(player)
		eternalLayer[eternalMaskIdx] = cachedEternalMask
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		return false
	elseif not isBloodOath then
		isCustomBloodOath = false
	end
end

function CustomHealthAPI.Helper.AddEndTakeDamageCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, math.huge, CustomHealthAPI.Mod.EndTakeDamageCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddEndTakeDamageCallback)

function CustomHealthAPI.Helper.RemoveEndTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.EndTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveEndTakeDamageCallback)

function CustomHealthAPI.Mod:EndTakeDamageCallback(ent, amount, flags, source, countdown)
	if CustomHealthAPI.Helper.GetOtherData(ent).InDamageCallback then
		CustomHealthAPI.Helper.GetOtherData(ent).InDamageCallback = nil
	end
	
	local pdata = CustomHealthAPI.Helper.GetPersistentData(ent)
	if pdata and pdata.EnabledDebugThreeForDamage then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Enabled debug flag."
	end
end

function CustomHealthAPI.Helper.RunPreGenericHealCallback(callbackId, iter, player, key, hp)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(callbackId)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local newKey, newHP = callback.Function(callback.Mod, player, key, hp)
			if newKey == false then
				return false
			elseif newKey ~= nil or newHP ~= nil then
				key = newKey or key
				hp = newHP or hp
			end
		end
	end
	return key, hp
end

function CustomHealthAPI.Helper.RunPreNoKillHealCallback(iter, player, key, hp)
	return CustomHealthAPI.Helper.RunPreGenericHealCallback(CustomHealthAPI.Enums.Callbacks.PRE_NOKILL_HEAL, iter, player, key, hp)
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_NOKILL_HEAL] = CustomHealthAPI.Helper.RunPreNoKillHealCallback

function CustomHealthAPI.Helper.RunPreHeartbreakHealCallback(iter, player, key, hp)
	return CustomHealthAPI.Helper.RunPreGenericHealCallback(CustomHealthAPI.Enums.Callbacks.PRE_HEARTBREAK_HEAL, iter, player, key, hp)
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_HEARTBREAK_HEAL] = CustomHealthAPI.Helper.RunPreHeartbreakHealCallback

function CustomHealthAPI.Helper.RunPreSpiritShacklesHealCallback(iter, player, key, hp)
	return CustomHealthAPI.Helper.RunPreGenericHealCallback(CustomHealthAPI.Enums.Callbacks.PRE_SPIRIT_SHACKLES_HEAL, iter, player, key, hp)
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_SPIRIT_SHACKLES_HEAL] = CustomHealthAPI.Helper.RunPreSpiritShacklesHealCallback

function CustomHealthAPI.Helper.RunPreGlassCannonHealCallback(iter, player, key, hp)
	return CustomHealthAPI.Helper.RunPreGenericHealCallback(CustomHealthAPI.Enums.Callbacks.PRE_GLASS_CANNON_HEAL, iter, player, key, hp)
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_GLASS_CANNON_HEAL] = CustomHealthAPI.Helper.RunPreGlassCannonHealCallback

function CustomHealthAPI.Helper.RunPreEternalHealCallback(iter, player, key, hp)
	return CustomHealthAPI.Helper.RunPreGenericHealCallback(CustomHealthAPI.Enums.Callbacks.PRE_ETERNAL_HEAL, iter, player, key, hp)
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_ETERNAL_HEAL] = CustomHealthAPI.Helper.RunPreEternalHealCallback

function CustomHealthAPI.Helper.FinishDamageDesync(ent)
	local player = ent:ToPlayer()
	if not player then return end

	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.FinishDamageDesync(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	if pdata.EnabledDebugThreeForDamage ~= nil and pdata.EnabledDebugThreeForDamage ~= Isaac.GetFrameCount() then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Disabled debug flag."
		pdata.EnabledDebugThreeForDamage = nil
	end
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	if data and not data.HandlingDamage then
		CustomHealthAPI.Helper.HandleGlassCannonOnBreaking(player)
		
		if not REPENTOGON and player:GetExtraLives() > 0 then
			CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = Isaac.GetFrameCount()
		end
		
		return false
	end
	
	local amount = data.HandlingDamageAmount
	local flags = data.HandlingDamageFlags
	local source = data.HandlingDamageSource
	local countdown = data.HandlingDamageCountdown
	local canShackle = data.HandlingDamageCanShackle
	
	data.HandlingDamage = nil
	data.HandlingDamageAmount = nil
	data.HandlingDamageFlags = nil
	data.HandlingDamageSource = nil
	data.HandlingDamageCountdown = nil
	data.HandlingDamageCanShackle = nil
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	
	if REPENTOGON then
		if data.BlockingMissingPage2 then
			player:UnblockCollectible(CollectibleType.COLLECTIBLE_MISSING_PAGE_2)
		end
		data.BlockingMissingPage2 = nil
		if data.ShouldMissingPage2 then
			SFXManager():Play(SoundEffect.SOUND_DEATH_CARD)
			ItemOverlay.Show(Giantbook.MISSING_PAGE_2, 0, nil)
			player:UseActiveItem(CollectibleType.COLLECTIBLE_NECRONOMICON, UseFlag.USE_NOANIM)
		end
		data.ShouldMissingPage2 = nil
	end
	
	if flags & DamageFlag.DAMAGE_NOKILL == DamageFlag.DAMAGE_NOKILL and CustomHealthAPI.Helper.GetTotalHP(player, true) == 0 then
		local key, hp
		if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
			key = "RED_HEART"
			hp = 1
		elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
			key = "BONE_HEART"
			hp = 1
		elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
			key = "SOUL_HEART"
			hp = 1
		end
		
		if key ~= nil then
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
			local prevent = false
			local newKey, newHP = CustomHealthAPI.Helper.RunPreNoKillHealCallback(nil, player, key, hp)
			if newKey == false then
				prevent = true
			elseif newKey ~= nil or newHP ~= nil then
				key = newKey or key
				hp = newHP or hp
			end
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
			if not prevent then
				CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true, true)
			end
		end
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_HEARTBREAK) and CustomHealthAPI.Helper.GetTotalHP(player, true) == 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", 2)
		
		local limit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
		if limit > 0 then
			local key, hp
			if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
				key = "RED_HEART"
				hp = 1
			elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
				key = "BONE_HEART"
				hp = 1
			elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
				key = "SOUL_HEART"
				hp = 1
			end
		
			if key ~= nil then
				CustomHealthAPI.PersistentData.PreventGetHPCaching = true
				local prevent = false
				local newKey, newHP = CustomHealthAPI.Helper.RunPreHeartbreakHealCallback(nil, player, key, hp)
				if newKey == false then
					prevent = true
				elseif newKey ~= nil or newHP ~= nil then
					key = newKey or key
					hp = newHP or hp
				end
				CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
				if not prevent then
					CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true, true)
				end
			end
		end
	end
	
	if canShackle and player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) then
		local postBrokenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		local limit = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) + postBrokenHearts * 2
		
		if postBrokenHearts * 2 >= limit then
			if CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player) >= 1 then
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 1, false, false, true, false)
			end
		else
			local key, hp
			if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
				key = "RED_HEART"
				hp = 1
			elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
				key = "BONE_HEART"
				hp = 1
			elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
				key = "SOUL_HEART"
				hp = 1
			end
		
			if key ~= nil then
				CustomHealthAPI.PersistentData.PreventGetHPCaching = true
				local prevent = false
				local newKey, newHP = CustomHealthAPI.Helper.RunPreSpiritShacklesHealCallback(nil, player, key, hp)
				if newKey == false then
					prevent = true
				elseif newKey ~= nil or newHP ~= nil then
					key = newKey or key
					hp = newHP or hp
				end
				CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
				if not prevent then
					CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true, true)
				end
			end
		end
		
		CustomHealthAPI.Helper.GetOtherData(player).ShacklesDisabled = true
	end
	
	local remainingRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local remainingSoulHP = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_SCAPULAR) and remainingRedHP + remainingSoulHP == 1 then
		local otherdata = CustomHealthAPI.Helper.GetOtherData(player)
		
		if otherdata.ShouldActivateScapular and flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 2)
		end
		
		otherdata.ShouldActivateScapular = nil
	end
	
	if player:HasTrinket(TrinketType.TRINKET_FINGER_BONE) and not player:IsDead() then
		local fingerRNG = player:GetTrinketRNG(TrinketType.TRINKET_FINGER_BONE)
		local mult = (CustomHealthAPI.REPPLUS_V1_9_7_13 and player:GetTrinketMultiplier(TrinketType.TRINKET_FINGER_BONE)) or 1
		if fingerRNG:RandomFloat() <= 0.04 * mult then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 1)
		end
	end
	
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_DAMAGE, playerType, player, amount, flags, source, countdown)
	CustomHealthAPI.Helper.HandleGlassCannonOnBreaking(player)
	
	if player:GetExtraLives() > 0 then
		CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = Isaac.GetFrameCount()
	end
	
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
	if pdata.EnabledDebugThreeForDamage ~= nil then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Disabled debug flag."
		pdata.EnabledDebugThreeForDamage = nil
	end
	
	return true
end

function CustomHealthAPI.Helper.HandleGlassCannonOnBreaking(player)
	if CustomHealthAPI.Helper.GetSavedata(player).GlassCannonBroke then
		CustomHealthAPI.Helper.GetSavedata(player).GlassCannonBroke = nil
		
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.IMPACT, 0, player.Position, Vector.Zero, nil):Update()
		for i = 1, 8 do
			local randvec = Vector.FromAngle(math.random() * 360):Resized(1.0 + math.random() * 3.0)
			local glassshard = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 0, player.Position, randvec, nil):ToEffect()
			glassshard.m_Height = glassshard.FallingSpeed
		end
		SFXManager():Play(SoundEffect.SOUND_GLASS_BREAK)
		player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_ANEMIC, true)
		
		if CustomHealthAPI.Helper.GetTotalHP(player, true) > 0 then
			local glassFlags = DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_ISSAC_HEART | DamageFlag.DAMAGE_NO_MODIFIERS
			player:ResetDamageCooldown() -- WHY IS DAMAGE_INVINCIBLE NOT WORKING
			player:TakeDamage(2, glassFlags, EntityRef(player), 30)
			--CustomHealthAPI.Helper.FinishDamageDesync(player)
			player:ResetDamageCooldown() -- WHY IS DAMAGE_INVINCIBLE NOT WORKING
			player:TakeDamage(2, glassFlags, EntityRef(player), 30)
			--CustomHealthAPI.Helper.FinishDamageDesync(player)
			
			local data = CustomHealthAPI.Helper.GetSavedata(player)
			if not data then
				CustomHealthAPI.Helper.CheckIfHealthOrderSet()
				CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
				CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
				data = CustomHealthAPI.Helper.GetSavedata(player)
			end
			local redMasks = data.RedHealthMasks or {}
			local otherMasks = data.OtherHealthMasks or {}
			
			if CustomHealthAPI.Helper.GetTotalHP(player, true) <= 0 then
				local playerType = player:GetPlayerType()
				local key, hp
				if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
					key = "RED_HEART"
					hp = 1
				elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
					key = "BONE_HEART"
					hp = 1
				elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
					key = "SOUL_HEART"
					hp = 1
				end
			
				if key ~= nil then
					CustomHealthAPI.PersistentData.PreventGetHPCaching = true
					local prevent = false
					local newKey, newHP = CustomHealthAPI.Helper.RunPreGlassCannonHealCallback(nil, player, key, hp)
					if newKey == false then
						prevent = true
					elseif newKey ~= nil or newHP ~= nil then
						key = newKey or key
						hp = newHP or hp
					end
					CustomHealthAPI.PersistentData.PreventGetHPCaching = false
					
					if not prevent then
						CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
						CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					end
				end
			end
		end
	end
end

if REPENTOGON then

function CustomHealthAPI.Helper.AddPostTakeDamageCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_ENTITY_TAKE_DMG, CustomHealthAPI.Enums.CallbackPriorities.EARLY, CustomHealthAPI.Mod.PostTakeDamageCallback, EntityType.ENTITY_PLAYER)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostTakeDamageCallback)

function CustomHealthAPI.Helper.RemovePostTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.PostTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostTakeDamageCallback)

function CustomHealthAPI.Mod:PostTakeDamageCallback(ent, damage, flags, source, countdown)
	local player = ent:ToPlayer()
	if not player then return end

	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.FinishDamageDesync(player)
end

function CustomHealthAPI.Helper.AddPreNecronomiconCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, math.huge, CustomHealthAPI.Mod.PreNecronomiconCallback, CollectibleType.COLLECTIBLE_NECRONOMICON)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreNecronomiconCallback)

function CustomHealthAPI.Helper.RemovePreNecronomiconCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreNecronomiconCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreNecronomiconCallback)

function CustomHealthAPI.Mod:PreNecronomiconCallback(id, rng, player, flags, slot, vardata)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if data and data.BlockingMissingPage2 then
		player:UnblockCollectible(CollectibleType.COLLECTIBLE_MISSING_PAGE_2)
	end
end

function CustomHealthAPI.Helper.AddPostNecronomiconCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_ITEM, -1 * math.huge, CustomHealthAPI.Mod.PostNecronomiconCallback, CollectibleType.COLLECTIBLE_NECRONOMICON)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostNecronomiconCallback)

function CustomHealthAPI.Helper.RemovePostNecronomiconCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.PostNecronomiconCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostNecronomiconCallback)

function CustomHealthAPI.Mod:PostNecronomiconCallback(id, rng, player, flags, slot, vardata)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if data and data.BlockingMissingPage2 then
		player:BlockCollectible(CollectibleType.COLLECTIBLE_MISSING_PAGE_2)
	end
end

end

function CustomHealthAPI.Helper.AddHandleDebugThreeCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EXECUTE_CMD, CustomHealthAPI.Mod.HandleDebugThreeCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleDebugThreeCallback)

function CustomHealthAPI.Helper.RemoveHandleDebugThreeCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EXECUTE_CMD, CustomHealthAPI.Mod.HandleDebugThreeCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleDebugThreeCallback)

function CustomHealthAPI.Mod:HandleDebugThreeCallback(cmd, params)
	if cmd == "chapi" then
		if params:find("nodmg") then
			print(Isaac.ExecuteCommand("debug 3"))
		end
	end
end

function CustomHealthAPI.Helper.HandleDamageDesync(player) --, compensationFunc)
	--CustomHealthAPI.Helper.HandleBasegameHealthStateUpdate(player, compensationFunc)
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	local s = ""
	repeat
		s = Isaac.ExecuteCommand("debug 3")
	until s == "Enabled debug flag."
	CustomHealthAPI.Helper.GetPersistentData(player, true).EnabledDebugThreeForDamage = Isaac.GetFrameCount()
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	if CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true) > 0 and 
	   CustomHealthAPI.Helper.GetTotalHP(player, true) > 1 and 
	   not player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) and
	   player:HasCollectible(CollectibleType.COLLECTIBLE_SHARD_OF_GLASS)
	then
		CustomHealthAPI.Helper.GetSavedata(player).ShardBleedTimer = 1200
		CustomHealthAPI.Helper.GetOtherData(player).LastBleedTick = Game():GetFrameCount()
	else
		CustomHealthAPI.Helper.GetSavedata(player).ShardBleedTimer = nil
		CustomHealthAPI.Helper.GetOtherData(player).BleedSpriteFrame = nil
	end
end

-- Handles the odd behaviour of eternal hearts where they effectively "heal back" red/soul health when removed instead of actually blocking it.
-- IE, if you take damage with a rotten heart with an eternal heart, you end up with half a red heart.
-- Not utilized for custom overlays, because god
function CustomHealthAPI.Helper.HandleEternalDamage(player, eternalOverlay, heartsDamaged, heartsBroken, brokenOverlays, eternalHealKey)
	local key = eternalHealKey
	local prevent = false
	
	local hp = 1
	
	if key then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		
		local newKey, newHP = CustomHealthAPI.Helper.RunPreEternalHealCallback(nil, player, key, hp)
		if newKey == false then
			prevent = true
		elseif newKey ~= nil or newHP ~= nil then
			key = newKey or key
			hp = newHP or hp
		end
		
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
	end
	
	if prevent then return false end
	
	heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1
	
	if eternalOverlay then
		eternalOverlay.HP = 0
		table.insert(heartsDamaged, {Key = "ETERNAL_HEART", HP = 1, Broken = true})
		brokenOverlays[eternalOverlay] = true
	end
	
	if key then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		if not data then
			CustomHealthAPI.Helper.CheckIfHealthOrderSet()
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
			data = CustomHealthAPI.Helper.GetSavedata(player)
		end
		data.DidEternalHeal = data.DidEternalHeal or {}
		data.DidEternalHeal[key] = (data.DidEternalHeal[key] or 0) + 1
		
		CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
		
		return true
	end
	
	return false
end

-- [LEGACY] There is no freaking way that anyone was calling these functions but
local function HandleLegacyEternalDamage(player, heartsBroken, key)
	local numEternal = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ETERNAL_HEART", true)
	if numEternal > 0 and
	   (key == "RED_HEART" and (flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS) or CustomHealthAPI.Helper.GetTotalHP(player, true) == 0) and
	   CustomHealthAPI.Helper.HandleEternalDamage(player, nil, {}, heartsBroken, nil, key)
	then
		CustomHealthAPI.Library.AddHealth(player, "ETERNAL_HEART", -numEternal)
		return true
	end
	return false
end
function CustomHealthAPI.Helper.HandleRedEternalDamage(player, flags, heartsBroken)
	return HandleLegacyEternalDamage(player, heartsBroken, "RED_HEART")
end
function CustomHealthAPI.Helper.HandleSoulEternalDamage(player, heartsBroken)
	return HandleLegacyEternalDamage(player, heartsBroken, "SOUL_HEART")
end
function CustomHealthAPI.Helper.HandleBoneEternalDamage(player, heartsBroken, keyBroken)
	return HandleLegacyEternalDamage(player, heartsBroken, keyBroken)
end
function CustomHealthAPI.Helper.HandleGoldDamage(player, heartsBroken, isGold, inNormalContainer)
	if isGold and (inNormalContainer == nil or inNormalContainer == true) then 
		heartsBroken["GOLDEN_HEART"] = (heartsBroken["GOLDEN_HEART"] or 0) + 1 
		CustomHealthAPI.Library.AddHealth(player, "GOLDEN_HEART", -1)
	end
end

function CustomHealthAPI.Helper.GetHealthOrder(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	
	local redOrder = {}
	local index = 1
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, {i, j, index})
			index = index + 1
		end
	end
	
	local lastRed = nil
	local lastSoul = nil
	local lastBone = nil
	
	local healthOrder = {}
	local redIndex = 1
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local otherHealth = mask[j]
			local otherHealthDef = CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key]
			
			if otherHealthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
				local tab = {Red = nil, Other = {i, j}}
				if otherHealthDef.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and redOrder[redIndex] ~= nil then
					tab.Red = redOrder[redIndex]
					redIndex = redIndex + 1
					local redHealth = redMasks[tab.Red[1]][tab.Red[2]]
					local redHealthDef = CustomHealthAPI.PersistentData.HealthDefinitions[redHealth.Key]
					-- DamageGate: Prevent damage from bleeding into or out of this heart. (ie, Bone Hearts)
					tab.DamageGate = (otherHealthDef.DamageGate or (redHealthDef and redHealthDef.DamageGate)) and (otherHealth.HP > 0 or (redHealth and redHealth.HP > 0))
				else
					tab.DamageGate = otherHealthDef.DamageGate and otherHealth.HP > 0
				end
				if not lastRed and tab.Red then
					lastRed = tab
					tab.IsLastRed = true
				end
				if not lastBone and otherHealthDef.MaxHP > 0 then
					lastBone = tab
					tab.IsLastBone = true
				end
				table.insert(healthOrder, tab)
			elseif otherHealthDef.Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				local tab = {Red = nil, Other = {i, j}}
				if not lastSoul then
					lastSoul = tab
					tab.IsLastSoul = true
				end
				table.insert(healthOrder, tab)
			end
		end
	end
	
	CustomHealthAPI.Helper.AddOverlaysToHealthOrder(player, healthOrder)
	
	return healthOrder
end

-- Rotten hearts are removed AFTER red hearts for "forced red"???
-- rotten+eternal+bone = half red
-- Trigger eternal heart damage if forced red would go to zero even if non lethal
function CustomHealthAPI.Helper.GetDamageStreams(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	
	local healthOrder = CustomHealthAPI.Helper.GetHealthOrder(player)
	
	local streamOfHealth = {}
	local streamHasRedHP = false
	local streamHasSoulHP = false
	local streamHasContainerHP = false
	
	for i = #healthOrder, 1, -1 do
		local orderEntry = healthOrder[i]
		
		local otherIndices = orderEntry.Other
		local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
		local otherHealthDef = CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key]
		
		local overlays = orderEntry.Overlays
		
		if otherHealthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			if streamHasSoulHP then break end
			
			table.insert(streamOfHealth, orderEntry)
			if orderEntry.Red ~= nil then
				streamHasRedHP = true
			end
			if otherHealth.HP > 0 then
				streamHasContainerHP = true
			end
			
			if orderEntry.DamageGate and otherHealthDef.DamageGate and #streamOfHealth > 0 then
				break
			end
		elseif otherHealthDef.Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			if streamHasRedHP or streamHasContainerHP then break end
			table.insert(streamOfHealth, orderEntry)
			streamHasSoulHP = true
		end
		
		if orderEntry.DamageGate and #streamOfHealth > 0 then
			break
		end
	end

	local streamOfRed = {}
	local streamOfSouls = {}
	local streamOfBones = {}

	if streamHasRedHP then
		streamOfRed = streamOfHealth
	elseif streamHasSoulHP then
		streamOfSouls = streamOfHealth
	else
		streamOfBones = streamOfHealth
	end

	return streamOfRed, streamOfSouls, streamOfBones
end

function CustomHealthAPI.Helper.GetForcedRedDamageStream(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	
	local normalOrder = CustomHealthAPI.Helper.GetHealthOrder(player)
	
	local forcedRedOrder = {}
	local lastMaskIndex = 0
	for i = 1, #normalOrder do
		local orderEntry = normalOrder[i]
		local redIndices = orderEntry.Red
		
		if redIndices ~= nil then
			local health = redMasks[redIndices[1]][redIndices[2]]
			local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaskIndex
			
			forcedRedOrder[maskIndex] = forcedRedOrder[maskIndex] or {}
			table.insert(forcedRedOrder[maskIndex], 1, orderEntry)
			
			lastMaskIndex = math.max(maskIndex, lastMaskIndex)
		end
	end
	
	local streamOfRed = {}
	for i = 1, lastMaskIndex do
		local mask = forcedRedOrder[i]
		if mask then
			for j = 1, #mask do
				if mask[j].DamageGate then
					if #streamOfRed > 0 then
						return streamOfRed
					end
					return {mask[j]}
				end
				table.insert(streamOfRed, mask[j])
			end
		end
	end
	
	return streamOfRed
end

function CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redHealthIndex)
	local isTaintedMaggie = CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player)
	local isBleedingContainer = (redHealthIndex > 2 and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) or redHealthIndex > 3
	
	return isTaintedMaggie and isBleedingContainer
end

function CustomHealthAPI.Helper.RunPreHealthDamagedCallback(iter, player, flags, redKey, redHP, otherKey, otherHP, amountToRemove)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	for callback in iterator do
		if not callback.Param or callback.Param == redKey or callback.Param == otherKey or callback.Param == playerType then
			local newAmount = callback.Function(callback.Mod, player, flags, redKey, redHP, otherKey, otherHP, amountToRemove)
			if newAmount == true then
				return true
			elseif newAmount ~= nil then
				amountToRemove = newAmount
			end
		elseif type(callback.Param) == "table" then
			for _,v in pairs(callback.Param) do
				if v == redKey or v == otherKey or v == playerType then
					local newAmount = callback.Function(callback.Mod, player, flags, redKey, redHP, otherKey, otherHP, amountToRemove)
					if newAmount == true then
						return true
					elseif newAmount ~= nil then
						amountToRemove = newAmount
					end
					break
				end
			end
		end
	end
	return amountToRemove
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED] = CustomHealthAPI.Helper.RunPreHealthDamagedCallback

function CustomHealthAPI.Helper.RunPostHealthDamagedCallback(iter, player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED)
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
			callback.Function(callback.Mod, player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
		elseif type(callback.Param) == "table" then
			for _,v in pairs(callback.Param) do
				if v == key or v == playerType then
					callback.Function(callback.Mod, player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
					break
				end
			end
		end
	end
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED] = CustomHealthAPI.Helper.RunPostHealthDamagedCallback

function CustomHealthAPI.Helper.DamageHealthStream(player, amount, flags, source, countdown, prioritizeEternal, healthStream, isForcedRedDamage)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	local overlayMaskLayers = data.OverlayHealthMaskLayers or {}
	
	local toRemove = math.floor(amount + 0.5)
	
	local didDamage = false
	local didRedDamage = false
	local didSoulDamage = false
	local damagedDevilDeal = 0
	local heartsDamaged = {}
	local heartsBroken = {}
	
	if toRemove <= 0 then
		return didRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
	end
	
	local eternalDamaged = nil
	local eternalHealKey = nil
	local brokenOverlays = {}
	
	local amountToRemove = toRemove
	
	-- Logic to damage a particular key of health
	local tryDamageHealth = function(health, protectDealChance, containerDamageGate)
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		if healthDef.Key == "ETERNAL_HEART" and not prioritizeEternal then
			-- Eternal hearts are very very special
			eternalDamaged = eternalDamaged or health
			return
		elseif didDamage and (healthDef.DamageGate or containerDamageGate) then
			amountToRemove = 0
			return
		elseif healthDef.MaxHP <= 0 then
			return
		end
		if amountToRemove > 0 and eternalDamaged and (healthDef.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY or healthDef.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER) then
			-- Don't do the usual eternal heart nonsense for overlay/container health, just block a hit.
			amountToRemove = amountToRemove - 1
			CustomHealthAPI.Helper.HandleEternalDamage(player, eternalDamaged, heartsDamaged, heartsBroken, brokenOverlays, nil)
			eternalDamaged = nil
		end
		local hpLost = math.min(health.HP, amountToRemove)
		if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.RED and not protectDealChance then
			damagedDevilDeal = damagedDevilDeal + hpLost
		end
		local broken = health.HP <= hpLost
		if hpLost > 0 then
			amountToRemove = amountToRemove - hpLost
			health.HP = health.HP - hpLost
			table.insert(heartsDamaged, {Key = health.Key, HP = hpLost, Broken = broken})
			didDamage = true
			if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.RED then
				didRedDamage = true
			elseif healthDef.Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				didSoulDamage = true
			end
		end
		if healthDef.DamageGate or containerDamageGate then
			amountToRemove = 0
		end
		if broken then
			heartsBroken[health.Key] = (heartsBroken[health.Key] or 0) + 1
			if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
				-- Overlays are not removed immediately by index because we may need to make a second pass over them.
				brokenOverlays[health] = true
			end
		end
		return broken
	end
	
	-- If the player would take lethal damage, check to see if there are overlays with HP lying around to absorb some damage.
	-- Relevant, for example, for eternal hearts with forced red damage, or other situations where overlays aren't in the stream.
	local tryProtectLethalDamageWithOverlayHealth = function(health)
		if amountToRemove >= health.HP and CustomHealthAPI.Helper.GetTotalHP(player, true, false) <= health.HP then
			local buffer = health.HP-1
			amountToRemove = amountToRemove - buffer
			for i = #data.OverlayHealthMaskLayers, 1, -1 do
				for overlayMaskIndex, overlayIndexInMask, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(data.OverlayHealthMaskLayers[i], true) do
					tryDamageHealth(overlay)
				end
			end
			amountToRemove = amountToRemove + buffer
		end
	end
	
	for i = 1, #healthStream do
		local tab = healthStream[i]
		local maybeLethal = tab.IsLastRed or tab.IsLastBone or tab.IsLastSoul
		local redIndices = tab.Red
		local otherIndices = tab.Other
		local overlays = tab.Overlays
		
		local redHealth = redIndices and redMasks[redIndices[1]][redIndices[2]]
		local redHealthDef = redHealth and CustomHealthAPI.PersistentData.HealthDefinitions[redHealth.Key]
		local otherHealth = otherIndices and otherMasks[otherIndices[1]][otherIndices[2]]
		local otherHealthDef = otherHealth and CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key]
		
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		local prevent = false
		local newAmount = CustomHealthAPI.Helper.RunPreHealthDamagedCallback(nil, 
		                                                                     player, 
											                                 flags, 
											                                 redHealth and redHealth.Key,
											                                 redHealth and redHealth.HP, 
											                                 otherHealth and otherHealth.Key,
											                                 otherHealth and otherHealth.HP, 
											                                 amountToRemove)
		if newAmount == true then
			prevent = true
		elseif newAmount ~= nil then
			amountToRemove = newAmount
		end
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
		
		if prevent or amountToRemove <= 0 then
			break
		end
		
		local protectDealChance = (redHealthDef and redHealthDef.ProtectsDealChance) or
		   (otherHealthDef and otherHealthDef.ProtectsDealChance) or
		   (redIndices and CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3]))
		local brokeRed = false
		local brokeOther = false
		
		-- First, check for overlays with HP.
		if not isForcedRedDamage and overlays then
			for i = #overlays, 1, -1 do
				tryDamageHealth(overlays[i])
			end
		end
		
		-- Next, damage any red health.
		if amountToRemove > 0 and redHealth then
			if maybeLethal then
				tryProtectLethalDamageWithOverlayHealth(redHealth)
			end
			
			local containerDamageGate = otherHealthDef ~= nil and otherHealthDef.DamageGate
			if tryDamageHealth(redHealth, protectDealChance, containerDamageGate) then
				table.remove(redMasks[redIndices[1]], redIndices[2])
				brokeRed = true
			end
		end
		
		-- Finally, damage soul health or containers with HP such as bone hearts.
		-- Of course, you won't have both red and soul health at the same index, but we can easily cover both cases.
		if amountToRemove > 0 and not isForcedRedDamage and otherHealth and otherHealthDef.MaxHP > 0 then
			if maybeLethal then
				tryProtectLethalDamageWithOverlayHealth(otherHealth)
			end
			
			if tryDamageHealth(otherHealth) then
				table.remove(otherMasks[otherIndices[1]], otherIndices[2])
				brokeOther = true
			end
		end
		
		if overlays and (brokeRed or not redHealth) and (brokeOther or (not otherHealth or otherHealthDef.MaxHP <= 0)) then
			-- This heart has been broken. Break all the overlays currently on this heart without HP.
			for _, overlay in ipairs(overlays) do
				if overlay.HP <= 0 then
					brokenOverlays[overlay] = true
				end
			end
		end
		
		if amountToRemove <= 0 then
			break
		end
	end
	
	-- Handle vanilla eternal heart nonsense.
	if eternalDamaged and (didRedDamage or didSoulDamage) then
		local eternalHealKey = (didRedDamage and "RED_HEART") or (didSoulDamage and "SOUL_HEART")
		CustomHealthAPI.Helper.HandleEternalDamage(player, eternalDamaged, heartsDamaged, heartsBroken, brokenOverlays, eternalHealKey)
		damagedDevilDeal = damagedDevilDeal - 1
	end
	
	-- Actually remove broken overlays now.
	for overlayLayerIndex, overlayLayer in ipairs(overlayMaskLayers) do
		for overlayMaskIndex, overlayIndexInMask, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, true) do
			if brokenOverlays[overlay] then
				heartsBroken[overlay.Key] = (heartsBroken[overlay.Key] or 0) + 1
				table.remove(overlayLayer[overlayMaskIndex], overlayIndexInMask)
			end
		end
	end
	
	return didRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage, heartsDamaged
end

function CustomHealthAPI.Helper.HandleForcedRedDamage(player, amount, flags, source, countdown, prioritizeEternal)
	local streamOfRed = CustomHealthAPI.Helper.GetForcedRedDamageStream(player)
	
	if #streamOfRed > 0 then
		return CustomHealthAPI.Helper.DamageHealthStream(player, amount, flags, source, countdown, prioritizeEternal, streamOfRed, true)
	else
		print("Custom Health API ERROR: CustomHealthAPI.Helper.HandleForcedRedDamage; No hearts to damage.")
	end
end

function CustomHealthAPI.Helper.HandleRegularDamage(player, amount, flags, source, countdown, prioritizeEternal)
	local streamOfRed, streamOfSouls, streamOfBones = CustomHealthAPI.Helper.GetDamageStreams(player)
	
	if #streamOfRed > 0 then
		return CustomHealthAPI.Helper.DamageHealthStream(player, amount, flags, source, countdown, prioritizeEternal, streamOfRed, false)
	elseif #streamOfSouls > 0 then
		return CustomHealthAPI.Helper.DamageHealthStream(player, amount, flags, source, countdown, prioritizeEternal, streamOfSouls, false)
	elseif #streamOfBones > 0 then
		return CustomHealthAPI.Helper.DamageHealthStream(player, amount, flags, source, countdown, prioritizeEternal, streamOfBones, false)
	else
		print("Custom Health API ERROR: CustomHealthAPI.Helper.HandleRegularDamage; No hearts to damage.")
	end
end

function CustomHealthAPI.Helper.HandleDamage(player, amount, flags, source, countdown)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	local toRemove = math.floor(amount + 0.5)
	
	local currentCustomRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, false, nil, true)
	local currentBasegameRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local currentRedHP = math.max(currentCustomRedHP, currentBasegameRedHP)
	local forcedRedDamage = currentRedHP >= toRemove and 
	                        (flags & DamageFlag.DAMAGE_RED_HEARTS == DamageFlag.DAMAGE_RED_HEARTS or player:HasTrinket(TrinketType.TRINKET_CROW_HEART))
	
	local handleFunc = CustomHealthAPI.Helper.HandleRegularDamage
	if forcedRedDamage then
		handleFunc = CustomHealthAPI.Helper.HandleForcedRedDamage
	end
	local isRedDamage, damagedDevilDeal, heartsBroken, didDamage, heartsDamaged = handleFunc(player, amount, flags, source, countdown)
	
	if heartsBroken == nil then
		return false
	elseif not didDamage then
		return false
	end
	
	local redHealthLost = 0
	
	CustomHealthAPI.PersistentData.PreventGetHPCaching = true
	for i = 1, #heartsDamaged do
		local health = heartsDamaged[i]
		
		if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.RED then
			redHealthLost = redHealthLost + health.HP
		end
		
		CustomHealthAPI.Helper.RunPostHealthDamagedCallback(nil, player, flags, health.Key, health.HP, health.Broken, i == #heartsDamaged)
	end
	CustomHealthAPI.PersistentData.PreventGetHPCaching = false
	
	if REPENTOGON and redHealthLost > 0 then
		-- Red health damage is the ONLY one that actually calls the corresponding AddHearts function internally, and in turn triggers these callbacks. Cool!
		CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback + 1
		local result = Isaac.RunCallbackWithParam(ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS, AddHealthType.RED, player, -redHealthLost, AddHealthType.RED, false)
		if result then
			local diff = redHealthLost + result
			if diff ~= 0 then
				CustomHealthAPI.Library.AddHealth(player, "RED_HEART", diff, nil, nil, nil, nil, nil, nil, nil, nil, true)
				redHealthLost = -result
			end
		end
	end
	
	--handle desync
	CustomHealthAPI.Helper.HandleDamageDesync(player) --, compensationFunc)
	
	if REPENTOGON and redHealthLost ~= 0 then
		-- Red health damage is the ONLY one that actually calls the corresponding AddHearts function internally, and in turn triggers these callbacks. Cool!
		CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback + 1
		Isaac.RunCallbackWithParam(ModCallbacks.MC_POST_PLAYER_ADD_HEARTS, AddHealthType.RED, player, -redHealthLost, AddHealthType.RED, false)
	end
	
	--handle heart effects
	for i = 1, heartsBroken["BLACK_HEART"] or 0 do
		SFXManager():Play(SoundEffect.SOUND_DEATH_CARD)
		player:UseActiveItem(CollectibleType.COLLECTIBLE_NECRONOMICON, UseFlag.USE_NOANIM) -- this is literally how it works in basegame dont @ me
	end
	
	for key, healthDef in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
			local brokenAmount = heartsBroken[key] or 0
			if brokenAmount > 0 then
				CustomHealthAPI.Helper.TriggerOverlayBroken(player, key, brokenAmount, true)
			end
		end
	end
	
	local processedBrittleBones = false
	for i = 1, heartsBroken["BONE_HEART"] or 0 do
		for i = 1, 8 do
			local randvec = Vector.FromAngle(math.random() * 360):Resized(1.0 + math.random() * 3.0)
			local boneshard = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 0, player.Position, randvec, nil):ToEffect()
			boneshard.FallingSpeed = (3.0 + 9.0 * math.random()) * -1
			boneshard.m_Height = boneshard.FallingSpeed
			boneshard.FallingAcceleration = 1.3
			boneshard.Color = Color(0.7, 0.7, 0.65, 1.0, 0.0, 0.0, 0.0)
		end
		SFXManager():Play(SoundEffect.SOUND_BONE_SNAP)
		
		if player:HasCollectible(CollectibleType.COLLECTIBLE_BRITTLE_BONES) then
			CustomHealthAPI.Helper.HandleBrittleBonesOnBreak(player)
			processedBrittleBones = true
		end
		
		if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
			-- you'd think this would be tied to the healthtype but it's not in basegame
			-- still tempted to change that
			damagedDevilDeal = true
		end
	end
	
	if processedBrittleBones then
		player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
		player:EvaluateItems()
	end
	
	if damagedDevilDeal and
	   flags & DamageFlag.DAMAGE_RED_HEARTS == 0 and
	   flags & DamageFlag.DAMAGE_FAKE == 0 and
	   flags & DamageFlag.DAMAGE_NO_PENALTIES == 0
	then
		local game = Game()
		if CustomHealthAPI.REPPLUS_V1_9_7_13 and player:HasTrinket(TrinketType.TRINKET_CROW_HEART) then
			local crowRNG = player:GetTrinketRNG(TrinketType.TRINKET_CROW_HEART)
			local crowMult = player:GetTrinketMultiplier(TrinketType.TRINKET_CROW_HEART)
			if crowMult == 1 or crowRNG:RandomFloat() > 0.25 * (crowMult - 1) then
				game:GetRoom():SetRedHeartDamage()
				game:GetLevel():SetRedHeartDamage()
			end
		else
			game:GetRoom():SetRedHeartDamage()
			game:GetLevel():SetRedHeartDamage()
		end
	end
	
	return true
end

function CustomHealthAPI.Library.RemoveHealthInDamageOrder(player, amount, tryForceRedDamage, prioritizeEternal)
	if not (player and player:ToPlayer()) then
		return {}
	end
	
	if player:IsCoopGhost() then
		return {}
	end
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_THESOUL_B and player:GetOtherTwin() then
		return CustomHealthAPI.Library.RemoveHealthInDamageOrder(player:GetOtherTwin(), amount, tryForceRedDamage, prioritizeEternal)
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player) or CustomHealthAPI.Helper.IsFoundSoul(player) then
		local returnHearts = {}
		if CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player) > 0 then
			table.insert(returnHearts, {Key = "GOLDEN_HEART", HP = 1})
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, -99)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		table.insert(returnHearts, {Key = "SOUL_HEART", HP = 1})
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, -99)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		return returnHearts
	elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		local returnHearts = {}
		local toRemove = math.floor(amount + 0.5)
		while CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) > 0 and toRemove > 0 do
			local hearts = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) / 2)
			local goldenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
			
			if goldenHearts > hearts - 1 then
				table.insert(returnHearts, {Key = "GOLDEN_HEART", HP = 1})
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
				CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, -1)
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			end
			
			table.insert(returnHearts, {Key = "COIN_HEART", HP = 2})
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, -2)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			toRemove = toRemove - 2
		end
		return returnHearts
	end
	
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	local toRemove = math.floor(amount + 0.5)
	
	local currentCustomRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, false, nil, true)
	local currentBasegameRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local currentRedHP = math.max(currentCustomRedHP, currentBasegameRedHP)
	local forcedRedDamage = currentRedHP >= toRemove and 
	                        (tryForceRedDamage or player:HasTrinket(TrinketType.TRINKET_CROW_HEART))
	
	local handleFunc = CustomHealthAPI.Helper.HandleRegularDamage
	if forcedRedDamage then
		handleFunc = CustomHealthAPI.Helper.HandleForcedRedDamage
	end
	
	local flags = 0
	if tryForceRedDamage then
		flags = DamageFlag.DAMAGE_RED_HEARTS
	end
---@diagnostic disable-next-line: param-type-mismatch
	local isRedDamage, damagedDevilDeal, heartsBroken, didDamage, heartsDamaged = handleFunc(player, amount, flags, EntityRef(nil), 0, prioritizeEternal)
	
	if heartsBroken == nil then
		return {}
	elseif not didDamage then
		return {}
	end
	
	local returnHearts = {}
	for i = 1, #heartsDamaged do
		table.insert(returnHearts, heartsDamaged[i])
	end
	
	-- Handle zero-health overlays (like Gold Hearts) that can be broken but are never "damaged".
	for key, amount in pairs(heartsBroken) do
		local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
		if healthDef.Type == CustomHealthAPI.Enums.HealthTypes.OVERLAY and healthDef.MaxHP <= 0 then
			table.insert(returnHearts, {Key = key, HP = amount})
		end
	end
	
	--update hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	return returnHearts
end
