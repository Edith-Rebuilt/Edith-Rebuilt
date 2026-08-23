-- 0 = Red Heart
-- 1 = Soul Heart
-- 2 = Black Heart
-- 3 = Eternal Heart
-- 4 = Golden Heart
-- 5 = Bone Heart
-- 6 = Rotten Heart
-- 7 = Lil Clot

CustomHealthAPI.PersistentData.IgnoreSumptoriumHandling = CustomHealthAPI.PersistentData.IgnoreSumptoriumHandling or false
CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey or {}
CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType or {}
CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey or {}

function CustomHealthAPI.Helper.AddPreventSumptoriumReloadOnRecallBugCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.PreventSumptoriumReloadOnRecallBugCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreventSumptoriumReloadOnRecallBugCallback)

function CustomHealthAPI.Helper.RemovePreventSumptoriumReloadOnRecallBugCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Mod.PreventSumptoriumReloadOnRecallBugCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreventSumptoriumReloadOnRecallBugCallback)

function CustomHealthAPI.Mod:PreventSumptoriumReloadOnRecallBugCallback(shouldSave)
	-- fixin basegame bugs woooooooo
	for _, clot in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY)) do
		clot:ToFamiliar().State = 0
	end
end

function CustomHealthAPI.Helper.AddSumptoriumPreSpawnCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_ENTITY_SPAWN, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.SumptoriumPreSpawnCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSumptoriumPreSpawnCallback)

function CustomHealthAPI.Helper.RemoveSumptoriumPreSpawnCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, CustomHealthAPI.Mod.SumptoriumPreSpawnCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSumptoriumPreSpawnCallback)

local keyOfNextOverlapClotSpawned = nil
function CustomHealthAPI.Mod:SumptoriumPreSpawnCallback(typ, var, subt, pos, vel, spawner, seed)
	if typ == EntityType.ENTITY_FAMILIAR and 
	   var == FamiliarVariant.BLOOD_BABY
	then
		if subt >= 900 and subt <= 906 then
			-- technical subtypes to handle case of basegame sumptorium clot subtypes being recalled
			keyOfNextOverlapClotSpawned = nil
			return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, subt - 900, seed}
		end
		
		if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[subt] then
			-- technical subtypes to handle case of basegame sumptorium clot subtypes that are actually custom hearts being recalled
			keyOfNextOverlapClotSpawned = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[subt]
			return {EntityType.ENTITY_FAMILIAR, 
			        FamiliarVariant.BLOOD_BABY, 
			        CustomHealthAPI.PersistentData.HealthDefinitions[keyOfNextOverlapClotSpawned].SumptoriumSubType, 
			        seed}
		end
		
		if CustomHealthAPI.PersistentData.IgnoreSumptoriumHandling then
			-- ignore all custom pre-spawn sumptorium behaviour if requested
			keyOfNextOverlapClotSpawned = nil
			return
		end
		
		-- handling for PRE_SUMPTORIUM_CLOT_SELECT callback
		local returnVals = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.PRE_SUMPTORIUM_CLOT_SELECT, subt, typ, var, subt, pos, vel, spawner, seed)
		if returnVals ~= nil then
			if returnVals.AllowBasegameHpChange == false then
				local player
				for i = 0, Game():GetNumPlayers() - 1 do
					local p = Isaac.GetPlayer(i)
					local subp = p:GetSubPlayer()
					if p.Index == spawner.Index and p.InitSeed == spawner.InitSeed then
						player = p
						break
					end
					if subp ~= nil and subp.Index == spawner.Index and subp.InitSeed == spawner.InitSeed then
						player = subp
							break
					end
				end
				
				if player ~= nil and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
					CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
				end
			end
			
			local newType = returnVals.Type
			local newVariant = returnVals.Variant
			local newSubType = returnVals.SubType
			local newSeed = returnVals or seed
			if newType == nil or newVariant == nil or newSubType == nil then
				newType = typ
				newVariant = var
				newSubType = subt
			end
			return {newType, newVariant, newSubType, newSeed}
		end
		
		if spawner and 
		   spawner.Type == EntityType.ENTITY_PLAYER and 
		   CustomHealthAPI.PersistentData.SaveDataLoaded
		then
			--WHY IS PLAYER:ISCOOPGHOST() NIL WHEN USING SPAWNER:TOPLAYER() HERE WHAT THE FUCK
			local player
			for i = 0, Game():GetNumPlayers() - 1 do
				local p = Isaac.GetPlayer(i)
				local subp = p:GetSubPlayer()
				if p.Index == spawner.Index and p.InitSeed == spawner.InitSeed then
					player = p
					break
				end
				if subp ~= nil and subp.Index == spawner.Index and subp.InitSeed == spawner.InitSeed then
					player = subp
					break
				end
			end
			
			if player ~= nil and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
				local data = CustomHealthAPI.Helper.GetSavedata(player)
				
				-- Check overlays first if not Lil Clot
				if subt ~= 7 then
					for i = #data.OverlayHealthMaskLayers, 1, -1 do
						local overlayLayer = data.OverlayHealthMaskLayers[i]
						for overlayMaskIndex, overlayIndexInMask, overlay in CustomHealthAPI.Helper.GetHealthMasksIterator(overlayLayer, true) do
							local eternalOrGold = false
							local newSubt = CustomHealthAPI.PersistentData.HealthDefinitions[overlay.Key].SumptoriumSubType
							if newSubt == nil then
								if overlay.Key == "ETERNAL_HEART" then
									newSubt = 3
									eternalOrGold = true
								elseif overlay.Key == "GOLDEN_HEART" then
									newSubt = 4
									eternalOrGold = true
								end
							end
							if newSubt ~= nil then
								overlay.HP = math.max(0, overlay.HP - 1)
								if overlay.HP <= 0 then
									table.remove(overlayLayer[overlayMaskIndex], overlayIndexInMask)
								end
								
								CustomHealthAPI.Helper.GetOtherData(player).SpawningSumptorium = true
								
								CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
								
								CustomHealthAPI.Helper.GetOtherData(player).SpawningSumptorium = nil
								
								if not eternalOrGold then
									keyOfNextOverlapClotSpawned = overlay.Key
								end
								return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, newSubt, seed}
							end
						end
					end
				end
				
				if subt == 0 or subt == 6 then
					-- select the red heart needed to replace red/rotten clot subtype with and update hp to match
					local redMasks = data.RedHealthMasks or {}
					
					local earliestKey
					for i = #redMasks, 1, -1 do
						local mask = redMasks[i]
						local doneSearching = false
						for j = #mask, 1, -1 do
							local health = mask[j]
							earliestKey = health.Key
							health.HP = health.HP - 1
							if health.HP <= 0 then
								table.remove(mask, j)
							end
							doneSearching = true
							break
						end
						if doneSearching then break end
					end
					
					CustomHealthAPI.Helper.GetOtherData(player).SpawningSumptorium = true
					
					CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					
					CustomHealthAPI.Helper.GetOtherData(player).SpawningSumptorium = nil
					
					if earliestKey == nil then
						-- for some reason no red hearts were found to adjust clot to
						keyOfNextOverlapClotSpawned = nil
						return
					end
					
					local newSubt = CustomHealthAPI.PersistentData.HealthDefinitions[earliestKey].SumptoriumSubType
					if newSubt ~= nil then
						-- set subtype of clot to the custom subtype for the selected red heart
						keyOfNextOverlapClotSpawned = nil
						if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[earliestKey] then
							keyOfNextOverlapClotSpawned = earliestKey
						end
						return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, newSubt, seed}
					else
						-- the red heart selected has no custom clot set, just default to the original subtype passed in
						keyOfNextOverlapClotSpawned = nil
						if earliestKey == "ROTTEN_HEART" then
							return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, 6, seed}
						else
							-- just default to RED_HEART
							return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, 0, seed}
						end
						return
					end
				elseif subt == 1 or subt == 2 or subt == 5 then
					-- select the soul/bone heart needed to replace soul/black/bone clot subtype with and update hp to match
					local otherMasks = data.OtherHealthMasks or {}
					
					local earliestKey
					for i = #otherMasks, 1, -1 do
						local mask = otherMasks[i]
						local doneSearching = false
						for j = #mask, 1, -1 do
							local health = mask[j]
							if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
								earliestKey = health.Key
								health.HP = health.HP - 1
								if health.HP <= 0 then
									table.remove(mask, j)
								end
								doneSearching = true
								break
							elseif CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
								   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP > 0 and
								   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
							then
								earliestKey = health.Key
								table.remove(mask, j)
								doneSearching = true
								break
							end
						end
						if doneSearching then break end
					end
					
					CustomHealthAPI.Helper.GetOtherData(player).SpawningSumptorium = true
					
					CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					
					CustomHealthAPI.Helper.GetOtherData(player).SpawningSumptorium = nil
					
					if earliestKey == nil then
						-- for some reason no soul/bone hearts were found to adjust clot to
						keyOfNextOverlapClotSpawned = nil
						return
					end
					
					local newSubt = CustomHealthAPI.PersistentData.HealthDefinitions[earliestKey].SumptoriumSubType
					if newSubt ~= nil then
						-- set subtype of clot to the custom subtype for the selected soul/bone heart
						keyOfNextOverlapClotSpawned = nil
						if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[earliestKey] then
							keyOfNextOverlapClotSpawned = earliestKey
						end
						return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, newSubt, seed}
					else
						-- the soul/bone heart selected has no custom clot set, just default to the original subtype passed in
						keyOfNextOverlapClotSpawned = nil
						if CustomHealthAPI.Library.GetInfoOfKey(earliestKey, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
							return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, 5, seed}
						elseif earliestKey == "BLACK_HEART" then
							return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, 2, seed}
						else
							-- just default to SOUL_HEART
							return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, 1, seed}
						end
						return
					end
				end
			end
		end
	end
end

function CustomHealthAPI.Helper.AddSumptoriumInitCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_FAMILIAR_INIT, CustomHealthAPI.Mod.SumptoriumInitCallback, FamiliarVariant.BLOOD_BABY)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSumptoriumInitCallback)

function CustomHealthAPI.Helper.RemoveSumptoriumInitCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_FAMILIAR_INIT, CustomHealthAPI.Mod.SumptoriumInitCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSumptoriumInitCallback)

function CustomHealthAPI.Helper.RunPreSumptoriumClotInitCallback(iter, fam, key)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_SUMPTORIUM_CLOT_INIT)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local skipSplat = nil
	for callback in iterator do
		if not callback.Param or callback.Param == key then
			local callbackSkipsSplat = callback.Function(callback.Mod, fam, key)
			if callbackSkipsSplat ~= nil then
				skipSplat = true
			end
		end
	end
	return skipSplat
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_SUMPTORIUM_CLOT_INIT] = CustomHealthAPI.Helper.RunPreSumptoriumClotInitCallback

function CustomHealthAPI.Mod:SumptoriumInitCallback(fam)
	local key = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType]
	local skipSplat = CustomHealthAPI.Helper.RunPreSumptoriumClotInitCallback(nil, fam, keyOfNextOverlapClotSpawned or key)
	if keyOfNextOverlapClotSpawned then
		CustomHealthAPI.Helper.GetEntityData(fam).TrueKeyOfClot = keyOfNextOverlapClotSpawned
		key = keyOfNextOverlapClotSpawned
	elseif key ~= nil and (not skipSplat) and CustomHealthAPI.PersistentData.SaveDataLoaded then
		local splatColor = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSplatColor
		if splatColor ~= nil then
			local splat = Isaac.Spawn(EntityType.ENTITY_EFFECT, 
									  EffectVariant.BLOOD_EXPLOSION, 
									  2, 
									  fam.Position, 
									  Vector.Zero, 
									  nil)
			
			splat:GetSprite().Color = splatColor
		end
	end
	keyOfNextOverlapClotSpawned = nil
	
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_INIT, key, fam, key)
end

function CustomHealthAPI.Helper.AddSumptoriumUpdateCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_FAMILIAR_UPDATE, CustomHealthAPI.Mod.SumptoriumUpdateCallback, FamiliarVariant.BLOOD_BABY)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSumptoriumUpdateCallback)

function CustomHealthAPI.Helper.RemoveSumptoriumUpdateCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_FAMILIAR_UPDATE, CustomHealthAPI.Mod.SumptoriumUpdateCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSumptoriumUpdateCallback)

function CustomHealthAPI.Mod:SumptoriumUpdateCallback(fam)
	if CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType] ~= nil then
		local key = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType]
		
		if not CustomHealthAPI.Helper.GetEntityData(fam).Init then
			local splatColor = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSplatColor
			if splatColor ~= nil then
				fam.SplatColor = splatColor
			end
			
			CustomHealthAPI.Helper.GetEntityData(fam).Init = true
		end
		
		if fam.State >= 89 and 
		   fam.Player and 
		   (fam.Position - fam.Player.Position):Length() <= 20.0 
		then
			local skipAbsorb = false
			local callbackSkipsAbsorb = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.PRE_SUMPTORIUM_CLOT_ABSORB, key, fam, key)
			if callbackSkipsAbsorb ~= nil then
				skipAbsorb = true
			end
			
			if (not skipAbsorb) and CustomHealthAPI.Helper.CanPickKey(fam.Player, key) then
				local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
				local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
				
				if (typ == CustomHealthAPI.Enums.HealthTypes.RED or typ == CustomHealthAPI.Enums.HealthTypes.SOUL) and maxHP <= 1 then
					CustomHealthAPI.Library.AddHealth(fam.Player, key, 2)
				elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
					CustomHealthAPI.Library.AddHealth(fam.Player, key, maxHP)
				else
					CustomHealthAPI.Library.AddHealth(fam.Player, key, 1)
				end

				local def = CustomHealthAPI.PersistentData.HealthDefinitions[key]
				CustomHealthAPI.Helper.PlaySound(def.SumptoriumCollectSoundSettings or def.CollectSound)

				Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, key, fam, key)
				fam:Remove()
			end
		end
	elseif fam.SubType >= 0 and fam.SubType <= 6 then
		if fam.State == -2 or fam.State > 0 then
			if CustomHealthAPI.Helper.GetEntityData(fam).TrueKeyOfClot then
				fam.SubType = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[CustomHealthAPI.Helper.GetEntityData(fam).TrueKeyOfClot]
			else
				fam.SubType = fam.SubType + 900
			end
		elseif CustomHealthAPI.Helper.GetEntityData(fam).ReenableVisible then
			fam.Visible = true
			CustomHealthAPI.Helper.GetEntityData(fam).ReenableVisible = false
		end
	elseif (fam.SubType >= 900 and fam.SubType <= 906) or CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[fam.SubType] then
		if fam.State == -1000 then
			fam.SubType = (fam.SubType - 900) % 7
			fam.Visible = false
			CustomHealthAPI.Helper.GetEntityData(fam).ReenableVisible = true
		elseif fam.State >= 89 and 
		   fam.Player and 
		   (fam.Position - fam.Player.Position):Length() <= 20.0 
		then
			local overlapKey = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[fam.SubType]
			
			local skipAbsorb = false
			local keyForCallback = overlapKey
			if keyForCallback == nil then
				if fam.SubType == 900 then
					keyForCallback = "RED_HEART"
				elseif fam.SubType == 901 then
					keyForCallback = "SOUL_HEART"
				elseif fam.SubType == 902 then
					keyForCallback = "BLACK_HEART"
				elseif fam.SubType == 903 then
					keyForCallback = "ETERNAL_HEART"
				elseif fam.SubType == 904 then
					keyForCallback = "GOLDEN_HEART"
				elseif fam.SubType == 905 then 
					keyForCallback = "BONE_HEART"
				elseif fam.SubType == 906 then
					keyForCallback = "ROTTEN_HEART"
				end
			end
			local callbackSkipsAbsorb = Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.PRE_SUMPTORIUM_CLOT_ABSORB, keyForCallback, fam, keyForCallback)
			if callbackSkipsAbsorb ~= nil then
				skipAbsorb = true
			end
			
			if not skipAbsorb then
				if overlapKey and CustomHealthAPI.Helper.CanPickKey(fam.Player, overlapKey) then
					local maxHP = CustomHealthAPI.Library.GetInfoOfKey(overlapKey, "MaxHP")
					local typ = CustomHealthAPI.Library.GetInfoOfKey(overlapKey, "Type")
					
					if (typ == CustomHealthAPI.Enums.HealthTypes.RED or typ == CustomHealthAPI.Enums.HealthTypes.SOUL) and maxHP <= 1 then
						CustomHealthAPI.Library.AddHealth(fam.Player, overlapKey, 2)
					elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
						CustomHealthAPI.Library.AddHealth(fam.Player, overlapKey, maxHP)
					else
						CustomHealthAPI.Library.AddHealth(fam.Player, overlapKey, 1)
					end

					local def = CustomHealthAPI.PersistentData.HealthDefinitions[overlapKey]
					CustomHealthAPI.Helper.PlaySound(def.SumptoriumCollectSoundSettings or def.CollectSound)

					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, overlapKey, fam, overlapKey)
					fam:Remove()
				elseif fam.SubType == 900 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "RED_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "RED_HEART", 1)
					SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "RED_HEART", fam, "RED_HEART")
					fam:Remove()
				elseif fam.SubType == 901 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "SOUL_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "SOUL_HEART", 1)
					SFXManager():Play(SoundEffect.SOUND_HOLY, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "SOUL_HEART", fam, "SOUL_HEART")
					fam:Remove()
				elseif fam.SubType == 902 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "BLACK_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "BLACK_HEART", 1)
					SFXManager():Play(SoundEffect.SOUND_UNHOLY, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "BLACK_HEART", fam, "BLACK_HEART")
					fam:Remove()
				elseif fam.SubType == 903 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "ETERNAL_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "ETERNAL_HEART", 1)
					SFXManager():Play(SoundEffect.SOUND_SUPERHOLY, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "ETERNAL_HEART", fam, "ETERNAL_HEART")
					fam:Remove()
				elseif fam.SubType == 904 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "GOLDEN_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "GOLDEN_HEART", 1)
					SFXManager():Play(SoundEffect.SOUND_GOLD_HEART, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "GOLDEN_HEART", fam, "GOLDEN_HEART")
					fam:Remove()
				elseif fam.SubType == 905 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "BONE_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "BONE_HEART", 1)
					SFXManager():Play(SoundEffect.SOUND_BONE_HEART, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "BONE_HEART", fam, "BONE_HEART")
					fam:Remove()
				elseif fam.SubType == 906 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "ROTTEN_HEART") then
					CustomHealthAPI.Library.AddHealth(fam.Player, "ROTTEN_HEART", 2)
					SFXManager():Play(SoundEffect.SOUND_ROTTEN_HEART, 1, 0, false, 1.0)
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_SUMPTORIUM_CLOT_ABSORB, "ROTTEN_HEART", fam, "ROTTEN_HEART")
					fam:Remove()
				end
			end
		end
	end
	
	if fam.Child and fam.Child.Type == EntityType.ENTITY_EFFECT and fam.Child.Variant == EffectVariant.SPRITE_TRAIL then
		local trail = fam.Child
	
		local color
		if fam.SubType == 0 or fam.SubType == 900 then
			color = Color(0.85, 0.00, 0.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 1 or fam.SubType == 901 then
			color = Color(0.30, 0.80, 1.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 2 or fam.SubType == 902 then
			color = Color(0.10, 0.10, 0.10, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 3 or fam.SubType == 903 then
			color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 4 or fam.SubType == 904 then
			color = Color(1.00, 0.80, 0.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 5 or fam.SubType == 905 then
			color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 6 or fam.SubType == 906 then
			color = Color(0.85, 0.30, 0.20, 0.40, 0.00, 0.00, 0.00)
		elseif CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType] ~= nil then
			local key = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType]
			color = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumTrailColor
		elseif CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[fam.SubType] ~= nil then
			local basegameSubType = (fam.SubType - 900) % 7
			
			if basegameSubType == 0 then
				color = Color(0.85, 0.00, 0.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 1 then
				color = Color(0.30, 0.80, 1.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 2 then
				color = Color(0.10, 0.10, 0.10, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 3 then
				color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 4 then
				color = Color(1.00, 0.80, 0.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 5 then
				color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 6 then
				color = Color(0.85, 0.30, 0.20, 0.40, 0.00, 0.00, 0.00)
			end
		end
		
		if color ~= nil then
			trail:GetSprite().Color = color
		end
	end
end

if REPENTOGON then
function CustomHealthAPI.Helper.AddPreSumptoriumBandaidFixCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_ADD_EFFECT, -1 * math.huge, CustomHealthAPI.Mod.PreSumptoriumBandaidFixCallback, Isaac.GetItemConfig():GetNullItem(NullItemID.ID_BLOODY_BABYLON))
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreSumptoriumBandaidFixCallback)

function CustomHealthAPI.Helper.RemovePreSumptoriumBandaidFixCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_ADD_EFFECT, CustomHealthAPI.Mod.PreSumptoriumBandaidFixCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreSumptoriumBandaidFixCallback)

function CustomHealthAPI.Mod:PreSumptoriumBandaidFixCallback(player, config)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
end

function CustomHealthAPI.Helper.AddPostSumptoriumBandaidFixCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_ADD_EFFECT, math.huge, CustomHealthAPI.Mod.PostSumptoriumBandaidFixCallback, Isaac.GetItemConfig():GetNullItem(NullItemID.ID_BLOODY_BABYLON))
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostSumptoriumBandaidFixCallback)

function CustomHealthAPI.Helper.RemovePostSumptoriumBandaidFixCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_ADD_EFFECT, CustomHealthAPI.Mod.PostSumptoriumBandaidFixCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostSumptoriumBandaidFixCallback)

function CustomHealthAPI.Mod:PostSumptoriumBandaidFixCallback(player, config)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end
end