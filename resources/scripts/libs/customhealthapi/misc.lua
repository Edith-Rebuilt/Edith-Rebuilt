function CustomHealthAPI.Helper.PlayerIsHealthless(player, ignoreTaintedSoul)
	if REPENTOGON then
		local playerType = player:GetPlayerType()
		local healthtype = player:GetHealthType()
		return healthtype == HealthType.LOST and not (ignoreTaintedSoul and playerType == PlayerType.PLAYER_THESOUL_B)
	else
		local playerType = player:GetPlayerType()
		return playerType == PlayerType.PLAYER_THELOST or 
		       playerType == PlayerType.PLAYER_THELOST_B or 
		       (playerType == PlayerType.PLAYER_THESOUL_B and not ignoreTaintedSoul)
	end
end

function CustomHealthAPI.Helper.PlayerHasCoinHealth(player)
	if REPENTOGON then
		local healthtype = player:GetHealthType()
		return healthtype == HealthType.COIN
	else
		local playerType = player:GetPlayerType()
		return playerType == PlayerType.PLAYER_KEEPER or playerType == PlayerType.PLAYER_KEEPER_B
	end
end

function CustomHealthAPI.Helper.PlayerIsKeeper(player)
	-- Deprecated
	return CustomHealthAPI.Helper.PlayerHasCoinHealth(player)
end

function CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_THEFORGOTTEN
end

function CustomHealthAPI.Helper.PlayerIsTheSoul(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_THESOUL
end

function CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_MAGDALENE_B
end

function CustomHealthAPI.Helper.PlayerIsBethany(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_BETHANY
end

function CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_BETHANY_B
end

function CustomHealthAPI.Helper.IsFoundSoul(player)
	return player.Variant == 1 and player.SubType == BabySubType.BABY_FOUND_SOUL
end

function CustomHealthAPI.Helper.PlayerIsIgnored(player)
	if not player then return true end

	local playertype
	if REPENTOGON then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.LOST or 
		   healthtype == HealthType.COIN or 
		   CustomHealthAPI.Helper.IsFoundSoul(player) or
		   player:IsCoopGhost()
		then
			return true
		end
	else
		playertype = player:GetPlayerType()
		if playertype == PlayerType.PLAYER_THELOST or
		   playertype == PlayerType.PLAYER_THELOST_B or
		   playertype == PlayerType.PLAYER_KEEPER or
		   playertype == PlayerType.PLAYER_KEEPER_B or
		   playertype == PlayerType.PLAYER_THESOUL_B or
		   CustomHealthAPI.Helper.IsFoundSoul(player) or
		   player:IsCoopGhost()
		then
			return true
		end
	end
	
	playertype = playertype or player:GetPlayerType()
	if playertype == PlayerType.PLAYER_THEFORGOTTEN or playertype == PlayerType.PLAYER_THESOUL then
		local subplayer = player:GetSubPlayer()
		if subplayer then
			return subplayer:IsCoopGhost()
		else
			-- gotta assume this is the subplayer
			-- there's no good way to get this either
			-- man
			-- trying to do this in a minimal lag way
			
			local ptrhash = GetPtrHash(player)
			if REPENTOGON then
				for _, check in ipairs(PlayerManager.GetPlayers()) do
					if check:IsCoopGhost() then
						local subplayer = check:GetSubPlayer()
						if subplayer and ptrhash == GetPtrHash(subplayer) then
							return true
						end
					end
				end
			else
				for i = 1, game:GetNumPlayers() do
					local check = Isaac.GetPlayer(i - 1)
					if check:IsCoopGhost() then
						local subplayer = check:GetSubPlayer()
						if subplayer and ptrhash == GetPtrHash(subplayer) then
							return true
						end
					end
				end
			end
		end 
	end
	return false
end

function CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player, ignoreTheSoul)
	local playertype = player:GetPlayerType()
	
	if REPENTOGON and not (ignoreTheSoul and playertype == PlayerType.PLAYER_THESOUL) then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.SOUL then
			return true
		elseif playertype < 41 then -- Basegame characters that must have had their healthtype changed
			return false
		end
	end

	return CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] ~= nil
end

function CustomHealthAPI.Helper.PlayerIsRedHealthless(player, ignoreTheSoul)
	local playertype = player:GetPlayerType()
	
	if REPENTOGON and not (ignoreTheSoul and playertype == PlayerType.PLAYER_THESOUL) then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.SOUL then
			return true
		elseif playertype < 41 then -- Basegame characters that must have had their healthtype changed
			return false
		end
	end

	return CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playertype]
end

function CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player, ignoreTheSoul)
	local playertype = player:GetPlayerType()
	
	if REPENTOGON and not (ignoreTheSoul and playertype == PlayerType.PLAYER_THESOUL) then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.BONE then
			return true
		elseif playertype < 41 then -- Basegame characters that must have had their healthtype changed
			return false
		end
	end

	return CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
end

function CustomHealthAPI.Helper.GetConvertedMaxHealthType(player)
	if CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
		return "BONE_HEART"
	end
	
	local playertype = player:GetPlayerType()
	return CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] or "SOUL_HEART"
end

function CustomHealthAPI.Helper.GetPlayerIndex(player)
    local rng
    if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
        rng = player:GetCollectibleRNG(2) -- flip sucks
	else
        rng = player:GetCollectibleRNG(1)
    end
    if rng == nil then return "" end
    return tostring(rng:GetSeed())
end

function CustomHealthAPI.Helper.RunGetAlabasterBoxOwnerCallback(iter, player)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.GET_ALABASTER_BOX_OWNER)
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
			player = callback.Function(callback.Mod, player) or player
		end
	end
	return player
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.GET_ALABASTER_BOX_OWNER] = CustomHealthAPI.Helper.RunGetAlabasterBoxOwnerCallback

function CustomHealthAPI.Helper.GetAlabasterBoxOwner(p)
	return CustomHealthAPI.Helper.RunGetAlabasterBoxOwnerCallback(nil, p) or p
end

function CustomHealthAPI.Helper.AddHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheSoul(player) or CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)) then
		if amount > 0 then
			if CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player) then
				local desiredRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) + amount
				CustomHealthAPI.Helper.AddHeartsKissesFix(player, math.ceil(amount / 2))
				local actualRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
				CustomHealthAPI.Helper.AddHeartsKissesFix(player, desiredRed - actualRed)
			else
				CustomHealthAPI.Helper.AddHeartsKissesFix(player, amount)
			end
		else
			CustomHealthAPI.Helper.AddHeartsKissesFix(player, amount)
		end
	end
end

function CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheSoul(player) or CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)) then
		if amount > 0 then
			if CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player) then
				CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, math.ceil(amount / 2))
			else
				CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, amount)
			end
		else
			CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, amount)
		end
	end
end

function CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheForgotten(player) or CustomHealthAPI.Helper.PlayerIsBethany(player)) then
		CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, amount)
	end
end

function CustomHealthAPI.Helper.AddBlackHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheForgotten(player) or CustomHealthAPI.Helper.PlayerIsBethany(player)) then
		CustomHealthAPI.Helper.AddBlackHeartsKissesFix(player, amount)
	end
end

function CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, amount)
	if not CustomHealthAPI.Helper.PlayerIsTheSoul(player) then
		CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, amount)
	end
end

function CustomHealthAPI.Helper.AddBrokenHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddBrokenHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.GetGreedAndMotherContainers(player)
	local containers = 0

	if player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) then
		local coins = player:GetNumCoins()
		
		if coins > 99 then
			containers = containers + math.floor(coins / 100) + 3
		elseif coins == 99 then
			containers = containers + 4
		else
			containers = containers + math.max(0, math.floor(coins / 25))
		end
	end
	
	local numKisses = player:GetTrinketMultiplier(TrinketType.TRINKET_MOTHERS_KISS)
	containers = containers + numKisses
	
	return containers
end

function CustomHealthAPI.Helper.ClearBasegameHealth(player)
	local isTheForgotten = CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
	local isTheSoul = CustomHealthAPI.Helper.PlayerIsTheSoul(player)
	local isBethany = CustomHealthAPI.Helper.PlayerIsBethany(player)
	local isTaintedBethany = CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)
	local isSoulHeartOnly = CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player, true)

	local goldenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, -1 * goldenTotal)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	
	local eternalTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
	CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, -1 * eternalTotal)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	
	if not isTheSoul then
		if not isTaintedBethany then
			local redTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddHeartsKissesFix(player, -1 * redTotal)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		
		local maxTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		if not (isTheForgotten or isTheSoul or isSoulHeartOnly) then
			local greedAndMotherContainers = CustomHealthAPI.Helper.GetGreedAndMotherContainers(player)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, -1 * math.max(0, maxTotal - (greedAndMotherContainers * 2)))
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		else
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, -1 * maxTotal)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
	end
	
	local brokenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
	CustomHealthAPI.Helper.AddBrokenHeartsKissesFix(player, -1 * brokenTotal)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	
	if not isTheSoul then
		local boneTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		if isTheForgotten then
			local greedAndMotherContainers = CustomHealthAPI.Helper.GetGreedAndMotherContainers(player)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, -1 * math.max(0, boneTotal - greedAndMotherContainers))
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		else
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, -1 * boneTotal)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
	end
	
	if not (isTheForgotten or isBethany) then
		local soulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, -1 * soulTotal)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	end
end

function CustomHealthAPI.Helper.ClearBasegameHealthNoOther(player)
	local isTheSoul = CustomHealthAPI.Helper.PlayerIsTheSoul(player)

	local goldenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, -1 * goldenTotal)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	
	local eternalTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
	CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, -1 * eternalTotal)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	
	if not isTheSoul then
		local redTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddHeartsKissesFix(player, -1 * redTotal)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	end
end

function CustomHealthAPI.Helper.ClearBasegameSoulHealth(player)
	local isTheForgotten = CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
	local isBethany = CustomHealthAPI.Helper.PlayerIsBethany(player)

	local goldenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, -1 * goldenTotal)
	CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	
	if not (isTheForgotten or isBethany) then
		local soulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		if soulTotal ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, -1 * soulTotal)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
	end
end

function CustomHealthAPI.Helper.HandleBasegameHealthStateUpdate(player, updateFunc)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	--local otherMasks = data.OtherHealthMasks or {} // Removed, not used
	
	-- before update
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
	
	for i = 2, 0, -1 do
		if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterPlayer:SetActiveCharge(0, i)
		end
	end
	
	--CustomHealthAPI.Helper.ClearBasegameHealth(player)
	CustomHealthAPI.Helper.ClearBasegameSoulHealth(player) -- Temporary handling of soul HP until something can be figured out in regards to soul/black health order
	                                                       -- that is compatible with the ADD_HEARTS functions; will probably be permanent for the non-REPENTOGON
	                                                       -- version of the code as well
	
	for i = 2, 0, -1 do
		if alabasterPlayer:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterPlayer:SetActiveCharge(24, i)
		end
	end
	
	-- update
	updateFunc(player)
	
	-- after update
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
end

function CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.UpdateBasegameHealthState(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local otherMasks = data.OtherHealthMasks or {}
	
	data.Cached = {}
	
	local maxHealth = CustomHealthAPI.Helper.GetTotalMaxHP(player, true) or 0
	local brokenHealth = CustomHealthAPI.Helper.GetTotalBrokenHP(player, true) or 0
	
	local redHealthTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true) or 0
	local rottenHealth = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART", true) or 0
	local redHealth = redHealthTotal - (rottenHealth * 2)
	
	local updateFunc = function(player)
		local brokenDiff = brokenHealth - CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		if brokenDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, brokenDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		
		local maxDiff = maxHealth - CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		if REPENTOGON and not REPENTANCE_PLUS and maxDiff < 0 and (CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player) or CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player)) then
			-- Incredibly niche fix for an oversight in early repentogon that can result in unremovable heart containers. Irrelevant as of repentogon+.
			local hash = GetPtrHash(player)
			local frame = Isaac.GetFrameCount()
			local callbackfn
			callbackfn = function(_, p)
				if Isaac.GetFrameCount() ~= frame then
					CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEALTH_TYPE, callbackfn)
				elseif GetPtrHash(p) == hash then
					return HealthType.RED
				end
			end
			CustomHealthAPI.Mod:AddPriorityCallback(ModCallbacks.MC_PLAYER_GET_HEALTH_TYPE, CustomHealthAPI.Enums.CallbackPriorities.FIRST, callbackfn, -1)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, maxDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEALTH_TYPE, callbackfn)
			maxDiff = 0
		end
		if maxDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, maxDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		
		--local soulToAdd = 0
		--local soulIndex = 0
		--local blackIndices = {}
		local bonesToAdd = 0
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				local key = health.Key
				local atMax = health.HP >= CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
				   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0
				then
					bonesToAdd = bonesToAdd + 1
				elseif key == "BLACK_HEART" then
					CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
					CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, (atMax and 2) or 1)
					CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
					--table.insert(blackIndices, soulIndex)
					
					--soulToAdd = soulToAdd + ((atMax and 2) or 1)
					--soulIndex = soulIndex + 1
				elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL and
					   key ~= "BLACK_HEART"
				then
					CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, (atMax and 2) or 1)
					CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
					--soulToAdd = soulToAdd + ((atMax and 2) or 1)
					--soulIndex = soulIndex + 1
				end
			end
		end
		
		local boneDiff = bonesToAdd - CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		if boneDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, boneDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		
		-- for some reason rotten hearts are very finicky when being removed through their dedicated function
		-- doing this heart-by-heart instead of one big go seems to fix it
		-- sometimes this leaves behind a half red heart but red diff after it should pick up on that and fix it
		repeat
			local rottenDiff = rottenHealth - CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
			if rottenDiff ~= 0 then
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
				CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, math.max(-2, math.min(rottenDiff * 2, 2)))
				CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
			end
		until (rottenDiff == 0)
		
		local redDiff = redHealth - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2))
		if redDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		
		local goldenDiff = CustomHealthAPI.Helper.GetTotalKeys(player, "GOLDEN_HEART", true) - CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
		if goldenDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
		
		local eternalDiff = CustomHealthAPI.Helper.GetTotalKeys(player, "ETERNAL_HEART", true) - CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
		if eternalDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalDiff)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
	end
	
	CustomHealthAPI.Helper.HandleBasegameHealthStateUpdate(player, updateFunc)
	
	data.Cached = {}
	
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_UPDATE_HEALTH_STATE, playerType, player, key, hp)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end

function CustomHealthAPI.Helper.UpdateBasegameHealthStateNoOther(player)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	data.Cached = {}
	
	local addedWhoreOfBabylonPrevention = CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	local addedBloodyBabylonPrevention = CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	
	local challengeIsHaveAHeart = Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_NULL
	end
	
	--CustomHealthAPI.Helper.ClearBasegameHealthNoOther(player)
	
	local newTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local newRotten = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART", true)
	local newRed = newTotal - (newRotten * 2)
	
	-- for some reason rotten hearts are very finicky when being removed through their dedicated function
	-- doing this heart-by-heart instead of one big go seems to fix it
	-- sometimes this leaves behind a half red heart but red diff after it should pick up on that and fix it
	repeat
		local rottenDiff = newRotten - CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
		if rottenDiff ~= 0 then
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
			CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, rottenDiff * 2)
			CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
		end
	until (rottenDiff == 0)
	
	local redDiff = newRed - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2))
	if redDiff ~= 0 then
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redDiff)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	end
	
	local goldenDiff = CustomHealthAPI.Helper.GetTotalKeys(player, "GOLDEN_HEART", true) - CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	if goldenDiff ~= 0 then
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenDiff)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	end
	
	local eternalDiff = CustomHealthAPI.Helper.GetTotalKeys(player, "ETERNAL_HEART", true) - CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	if eternalDiff ~= 0 then
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth + 1
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalDiff)
		CustomHealthAPI.PersistentData.IsTechnicalAddHealth = CustomHealthAPI.PersistentData.IsTechnicalAddHealth - 1
	end
	
	if addedWhoreOfBabylonPrevention then CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player) end
	if addedBloodyBabylonPrevention then CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player) end
	
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_HAVE_A_HEART
	end
	
	data.Cached = {}
	
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_UPDATE_HEALTH_STATE, player:GetPlayerType(), player, key, hp)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end

function CustomHealthAPI.Helper.CanAffordPrice(player, price)
	if price > 0 then
		return player:GetNumCoins() >= price
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
		return true
	elseif price == PickupPrice.PRICE_ONE_HEART then
		--1 Red
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif price == PickupPrice.PRICE_TWO_HEARTS then
		--2 Red
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif price == PickupPrice.PRICE_THREE_SOULHEARTS then
		--3 soul
		return math.ceil(player:GetSoulHearts() / 2) >= 1
	elseif price == PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS then
		--1 Red, 2 Soul
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif price == PickupPrice.PRICE_ONE_SOUL_HEART then
		--1 Soul
		return math.ceil(player:GetSoulHearts() / 2) >= 1
	elseif price == PickupPrice.PRICE_TWO_SOUL_HEARTS then
		--2 Souls
		return math.ceil(player:GetSoulHearts() / 2) >= 1
	elseif price == PickupPrice.PRICE_ONE_HEART_AND_ONE_SOUL_HEART then
		--1 Red, 1 Soul
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif price == PickupPrice.PRICE_SOUL then
		return player:HasTrinket(TrinketType.TRINKET_YOUR_SOUL)
	else
		return true
	end
end

function CustomHealthAPI.Helper.CanAffordPickup(player, pickup)
	return CustomHealthAPI.Helper.CanAffordPrice(player, pickup.Price)
end

function CustomHealthAPI.Helper.EmptyAllHealth(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			table.remove(mask, j)
		end
	end
	
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.remove(mask, j)
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
			then
				table.remove(mask, j)
			end
		end
	end
end

function CustomHealthAPI.Helper.GetRepentogonAddHealthType(key)
	if not REPENTOGON then return end
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local chapiHealthType = healthDef.Type
	if chapiHealthType == CustomHealthAPI.Enums.HealthTypes.RED then
		if key == "ROTTEN_HEART" then
			return AddHealthType.ROTTEN
		end
		return AddHealthType.RED
	elseif chapiHealthType == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if key == "BLACK_HEART" then
			return AddHealthType.BLACK
		end
		return AddHealthType.SOUL
	elseif chapiHealthType == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if healthDef.MaxHP > 0 then
			return AddHealthType.BONE
		elseif healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			return AddHealthType.BROKEN
		end
		return AddHealthType.MAX
	elseif key == "GOLDEN_HEART" then
		return AddHealthType.GOLDEN
	elseif key == "ETERNAL_HEART" then
		return AddHealthType.ETERNAL
	end
end

function CustomHealthAPI.Helper.PlaySound(sound)
	if sound then
		if type(sound) == "function" then
			sound()
		elseif type(sound) == "table" then
			SFXManager():Play(sound.ID,
				sound.Volume or 1.0,
				sound.FrameDelay or 2,
				sound.Loop or false,
				sound.Pitch or 1.0,
				sound.Pan or 0)
		else
			SFXManager():Play(sound, 1.0, 2, false, 1.0, 0)
		end
		return true
	end
end

function CustomHealthAPI.Helper.GetEntityData(entity)
	return (GetDataCache and GetDataCache.GetEntityData(entity)) or entity:GetData()
end

function CustomHealthAPI.Mod:ClearGetDataCache(entity)
	if GetDataCache then
		GetDataCache.ClearCache(entity)
	end
end

function CustomHealthAPI.Helper.GetSavedata(player, init)
	local data = CustomHealthAPI.Helper.GetEntityData(player)
	if init and not data.CustomHealthAPISavedata then
		data.CustomHealthAPISavedata = {}
	end
	return data.CustomHealthAPISavedata
end

function CustomHealthAPI.Helper.HasSavedata(player)
	return CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPISavedata ~= nil
end

function CustomHealthAPI.Helper.SetSavedata(player, savedata)
	CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPISavedata = savedata
end

function CustomHealthAPI.Helper.ClearSavedata(player)
	CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPISavedata = nil
end

function CustomHealthAPI.Helper.ResetSavedata(player, savedata)
	CustomHealthAPI.Helper.ClearSavedata(player)
	return CustomHealthAPI.Helper.GetSavedata(player, true)
end


function CustomHealthAPI.Helper.GetOtherData(player)
	local data = CustomHealthAPI.Helper.GetEntityData(player)
	if not data.CustomHealthAPIOtherData then
		data.CustomHealthAPIOtherData = {}
	end
	return data.CustomHealthAPIOtherData
end

function CustomHealthAPI.Helper.SetOtherData(player, data)
	CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPIOtherData = data
end

function CustomHealthAPI.Helper.ClearOtherData(player)
	CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPIOtherData = nil
end


function CustomHealthAPI.Helper.GetPersistentData(player, init)
	local data = CustomHealthAPI.Helper.GetEntityData(player)
	if init and not data.CustomHealthAPIPersistent then
		data.CustomHealthAPIPersistent = {}
	end
	return data.CustomHealthAPIPersistent
end

function CustomHealthAPI.Helper.SetPersistentData(player, data)
	CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPIPersistent = data
end

function CustomHealthAPI.Helper.ClearPersistentData(player)
	CustomHealthAPI.Helper.GetEntityData(player).CustomHealthAPIPersistent = nil
end

function CustomHealthAPI.Helper.HealthTypeIsIcon(healthType)
	return healthType == CustomHealthAPI.Enums.HealthTypes.AFTER_HEALTH_ICON or 
	       healthType == CustomHealthAPI.Enums.HealthTypes.BELOW_HEALTH_ICON
end

function CustomHealthAPI.Helper.RemoveAllHealth(player)
	local subplayer = player:GetSubPlayer()
	for key,info in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
		if typ ~= CustomHealthAPI.Enums.HealthTypes.AFTER_HEALTH_ICON and typ ~= CustomHealthAPI.Enums.HealthTypes.BELOW_HEALTH_ICON then
			local amount = (CustomHealthAPI.Helper.GetTotalHPOfKey(player, key) or 0) + ((subplayer and CustomHealthAPI.Helper.GetTotalHPOfKey(subplayer, key)) or 0);
			CustomHealthAPI.Library.AddHealth(player,key,-amount);
		end
	end
end
