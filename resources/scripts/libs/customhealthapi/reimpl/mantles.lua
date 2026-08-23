-- so as it turns out, mantles are incredibly buggy pieces of shit that are barely exposed in the base api and i officially hate them
-- i tried setting this up to touch the system as little as possible, but there's so many edgecases and problems with it that it's impossible
-- issues with console cmds, issues with stacking, issues with trinketmult, issues that make them even working in the first place inconsistent
-- and that's ignoring the obviously and extremely broken shit like holy card just straight up giving you a permanent mantle half the time rn
-- and dont even get me started on esau jr and tainted laz
-- and i cant do anything about it but remake the system for applying these items on room start from scratch
-- because all this stems from missing variables and broken callbacks and stuff that should be tempeffects but arent and so on
-- and because i need this to work even without rgon, i'm just shit-out-of-luck
-- so it's time to entirely remake yet another basegame system
-- its not like this is even a difficult system to remake it's only taken me like an hour
-- i just hate how much time ive wasted trying to avoid remaking it
-- all this just because they added some funnie icons and didnt expose wooden cross/holy mantle's variables at all
-- and as far as i can tell dogma isn't even included in this system in basegame, it's basically treated as a mantle with no item attached
-- it's not like it has it's own icon after all
-- and thank god it doesnt too cause i wouldn't be able to apply the shader to it if it did because no support in the base api
-- man i sure love modding this game

CustomHealthAPI.PersistentData.MantlesToBeReset = CustomHealthAPI.PersistentData.MantlesToBeReset or {}
CustomHealthAPI.PersistentData.MantlesToBeResetOnPeffect = CustomHealthAPI.PersistentData.MantlesToBeResetOnPeffect or {}

function CustomHealthAPI.Helper.AddStartMantleResetCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_ROOM, -1 * math.huge, CustomHealthAPI.Mod.StartMantleResetCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddStartMantleResetCallback)

function CustomHealthAPI.Helper.RemoveStartMantleResetCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Mod.StartMantleResetCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveStartMantleResetCallback)

local mantlesResettingOnNewRoom = true
function CustomHealthAPI.Mod:StartMantleResetCallback()
	playersOfTempEffects = {}
	mantlesResettingOnNewRoom = true
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local odata = CustomHealthAPI.Helper.GetOtherData(player)
		odata.PickedUpDogma = nil
		odata.HasBrokenHolyMantle = nil
		odata.HasBrokenBlanketMantle = nil
		CustomHealthAPI.PersistentData.MantlesToBeReset[player.Index] = true
	end
	for k, player in pairs(CustomHealthAPI.PersistentData.HiddenPlayers) do
		local player = player.Ref
		if player ~= nil then
			local odata = CustomHealthAPI.Helper.GetOtherData(player)
			odata.PickedUpDogma = nil
			odata.HasBrokenHolyMantle = nil
			odata.HasBrokenBlanketMantle = nil
		else
			CustomHealthAPI.PersistentData.HiddenPlayers[k] = nil
		end
	end
end

local playersOfTempEffects = {}
function CustomHealthAPI.Helper.ConnectTempEffectsToPlayer(player, effects)
	if mantlesResettingOnNewRoom then 
		playersOfTempEffects[GetPtrHash(effects)] = player
	end
end

function CustomHealthAPI.Helper.TrackHolyMantleOnAdd(effects, item, count)
	if mantlesResettingOnNewRoom and item == CollectibleType.COLLECTIBLE_HOLY_MANTLE and count > 0 then
		local player = playersOfTempEffects[GetPtrHash(effects)]
		if player then
			local odata = CustomHealthAPI.Helper.GetOtherData(player)
			odata.ModdedMantlesToReadd = (odata.ModdedMantlesToReadd or 0) + count
		end
	end
end

function CustomHealthAPI.Helper.TrackHolyMantleOnRemove(effects, item, count)
	if mantlesResettingOnNewRoom and item == CollectibleType.COLLECTIBLE_HOLY_MANTLE then
		local player = playersOfTempEffects[GetPtrHash(effects)]
		if player then
			local odata = CustomHealthAPI.Helper.GetOtherData(player)
			if count == -1 then
				odata.ModdedMantlesToReadd = nil
			else
				odata.ModdedMantlesToReadd = math.max((odata.ModdedMantlesToReadd or 0) - count, 0)
			end
		end
	end
end

function CustomHealthAPI.Helper.AddResetWoodenCrossCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_LEVEL, CustomHealthAPI.Mod.ResetWoodenCrossCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddResetWoodenCrossCallback)

function CustomHealthAPI.Helper.RemoveResetWoodenCrossCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_LEVEL, CustomHealthAPI.Mod.ResetWoodenCrossCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveResetWoodenCrossCallback)

function CustomHealthAPI.Mod:ResetWoodenCrossCallback()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local pdata = CustomHealthAPI.Helper.GetPersistentData(player)
		if pdata then pdata.WoodenCrossesBrokenThisFloor = 0 end
	end
	for k, player in pairs(CustomHealthAPI.PersistentData.HiddenPlayers) do
		local player = player.Ref
		if player ~= nil then
			local pdata = CustomHealthAPI.Helper.GetPersistentData(player)
			if pdata then pdata.WoodenCrossesBrokenThisFloor = 0 end
		else
			CustomHealthAPI.PersistentData.HiddenPlayers[k] = nil
		end
	end
	for _, backup in pairs(CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup) do
		local pdata = backup.Persist
		if pdata then pdata.WoodenCrossesBrokenThisFloor = 0 end
	end
end

function CustomHealthAPI.Helper.AddMantleBrokeCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_EFFECT_INIT, -1 * math.huge, CustomHealthAPI.Mod.MantleBrokeCallback, EffectVariant.POOF02)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddMantleBrokeCallback)

function CustomHealthAPI.Helper.RemoveMantleBrokeCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_EFFECT_INIT, CustomHealthAPI.Mod.MantleBrokeCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveMantleBrokeCallback)

local brokenMantles = {}
function CustomHealthAPI.Mod:MantleBrokeCallback(poof)
	if poof.SubType == 11 then
		table.insert(brokenMantles, poof)
	end
end

function CustomHealthAPI.Helper.ConnectBrokenMantlesToPlayers()
	for _, mantle in ipairs(brokenMantles) do
		if mantle.Parent and mantle.Parent.Type == EntityType.ENTITY_PLAYER then
			local odata = CustomHealthAPI.Helper.GetOtherData(mantle.Parent)
			odata.MantleBroke = true
		end
	end
	brokenMantles = {}
end

function CustomHealthAPI.Helper.UpdateMantleTrackers(player)
	local odata = CustomHealthAPI.Helper.GetOtherData(player)
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player)
	
	local effects = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffects(player)
	local hasBlanketMantle = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_BLANKET)
	local hadBlanketMantle = odata.HadBlanketMantle
	if hadBlanketMantle == nil then hadBlanketMantle = hasBlanketMantle end
	
	if odata.MantleBroke then
		local woodenMult = player:GetTrinketMultiplier(TrinketType.TRINKET_WOODEN_CROSS)
		local hasHolyMantle = player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
		if woodenMult > 0 and woodenMult > (pdata.WoodenCrossesBrokenThisFloor or 0) then
			pdata.WoodenCrossesBrokenThisFloor = (pdata.WoodenCrossesBrokenThisFloor or 0) + 1
		elseif hadBlanketMantle and not odata.HasBrokenBlanketMantle then
			odata.HasBrokenBlanketMantle = true
		elseif hasHolyMantle and not odata.HasBrokenHolyMantle then
			odata.HasBrokenHolyMantle = true
		end
	end
	odata.MantleBroke = nil
	odata.HadBlanketMantle = hasBlanketMantle
	
	if not pdata then return end
	local dogmaNum = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DOGMA)
	if (pdata.LastDogmaNum or 0) < dogmaNum then
		odata.PickedUpDogma = (odata.PickedUpDogma or 0) + 1
	end
	pdata.LastDogmaNum = dogmaNum
end

function CustomHealthAPI.Helper.ResetMantles(player)
	local odata = CustomHealthAPI.Helper.GetOtherData(player)
	local pdata = CustomHealthAPI.Helper.GetPersistentData(player)
	
	local effects = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffects(player)
	CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveCollectibleEffect(effects, CollectibleType.COLLECTIBLE_BLANKET, -1)
	
	local count = 0
	if player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE) and not odata.HasBrokenHolyMantle then
		count = count + 1
	end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BLANKET) and 
	   Game():GetRoom():GetType() == RoomType.ROOM_BOSS and 
	   not odata.HasBrokenBlanketMantle
	then
		count = count + 1
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectibleEffect(effects, CollectibleType.COLLECTIBLE_BLANKET, true, 1)
	end
	if effects:HasNullEffect(NullItemID.ID_HOLY_CARD) then
		count = count + 1
	end
	if odata.PickedUpDogma then
		count = count + 1
	end
	
	pdata.WoodenCrossesBrokenThisFloor = pdata.WoodenCrossesBrokenThisFloor or 0
	local currentWoodenCrosses = player:GetTrinketMultiplier(TrinketType.TRINKET_WOODEN_CROSS)
	if not CustomHealthAPI.REPPLUS_V1_9_7_13 then
		currentWoodenCrosses = math.min(1, currentWoodenCrosses)
	end
	local woodenCrossesBrokenThisFloor = pdata.WoodenCrossesBrokenThisFloor
	count = count + math.max(currentWoodenCrosses - woodenCrossesBrokenThisFloor, 0)
	
	if not ignoreModded then
		local odata = CustomHealthAPI.Helper.GetOtherData(player)
		count = count + (odata.ModdedMantlesToReadd or 0)
	end
	
	local basegameCount = effects:GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
	if count > basegameCount then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectibleEffect(effects, CollectibleType.COLLECTIBLE_HOLY_MANTLE, true, count - basegameCount)
	elseif count < basegameCount then
		CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveCollectibleEffect(effects, CollectibleType.COLLECTIBLE_HOLY_MANTLE, basegameCount - count)
	end
	
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RESET_HOLY_MANTLES, player:GetPlayerType(), player)
end

function CustomHealthAPI.Helper.UpdateMantles(player)
	CustomHealthAPI.Helper.ConnectBrokenMantlesToPlayers()
	CustomHealthAPI.Helper.UpdateMantleTrackers(player)
	
	if CustomHealthAPI.PersistentData.MantlesToBeReset[player.Index] then
		CustomHealthAPI.Helper.ResetMantles(player)
		CustomHealthAPI.PersistentData.MantlesToBeReset[player.Index] = nil
		
		local odata = CustomHealthAPI.Helper.GetOtherData(player)
		odata.ModdedMantlesToReadd = nil
	end
end

function CustomHealthAPI.Helper.AddHandleMantlesOnPeffectCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PEFFECT_UPDATE, -1 * math.huge, CustomHealthAPI.Mod.HandleMantlesOnPeffectCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleMantlesOnPeffectCallback)

function CustomHealthAPI.Helper.RemoveHandleMantlesOnPeffectCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHealthAPI.Mod.HandleMantlesOnPeffectCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleMantlesOnPeffectCallback)

function CustomHealthAPI.Mod:HandleMantlesOnPeffectCallback(player)
	if CustomHealthAPI.PersistentData.MantlesToBeResetOnPeffect[player.Index] and
	   not CustomHealthAPI.PersistentData.MantlesToBeReset[player.Index]
	then
		CustomHealthAPI.Helper.ConnectBrokenMantlesToPlayers()
		CustomHealthAPI.Helper.UpdateMantleTrackers(player)
		CustomHealthAPI.Helper.ResetMantles(player)
		CustomHealthAPI.PersistentData.MantlesToBeResetOnPeffect[player.Index] = nil
		
		local odata = CustomHealthAPI.Helper.GetOtherData(player)
		odata.ModdedMantlesToReadd = nil
	end
end

function CustomHealthAPI.Helper.AddHandleMantlesOnPrenderCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_RENDER, -1 * math.huge, CustomHealthAPI.Mod.HandleMantlesOnPrenderCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleMantlesOnPrenderCallback)

function CustomHealthAPI.Helper.RemoveHandleMantlesOnPrenderCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_RENDER, CustomHealthAPI.Mod.HandleMantlesOnPrenderCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleMantlesOnPrenderCallback)

local updatedThisFrame = {}
function CustomHealthAPI.Mod:HandleMantlesOnPrenderCallback(player)
	local ptrhash = GetPtrHash(player)
	if not updatedThisFrame[ptrhash] then
		CustomHealthAPI.Helper.UpdateMantles(player)
		updatedThisFrame[ptrhash] = true
	end
end

function CustomHealthAPI.Helper.AddHandleMantlesOnRenderCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_RENDER, -1 * math.huge, CustomHealthAPI.Mod.HandleMantlesOnRenderCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleMantlesOnRenderCallback)

function CustomHealthAPI.Helper.RemoveHandleMantlesOnRenderCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Mod.HandleMantlesOnRenderCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleMantlesOnRenderCallback)

function CustomHealthAPI.Mod:HandleMantlesOnRenderCallback()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local ptrhash = GetPtrHash(player)
		if not updatedThisFrame[ptrhash] then
			CustomHealthAPI.Helper.UpdateMantles(player)
			updatedThisFrame[ptrhash] = true
		end
	end
	CustomHealthAPI.PersistentData.MantlesToBeReset = {}
	mantlesResettingOnNewRoom = nil
	updatedThisFrame = {}
end