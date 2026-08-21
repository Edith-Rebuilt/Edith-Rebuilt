CustomHealthAPI.PersistentData.UsingGlowingHourglass = CustomHealthAPI.PersistentData.UsingGlowingHourglass or false
CustomHealthAPI.PersistentData.GlowingHourglassBackup = CustomHealthAPI.PersistentData.GlowingHourglassBackup or nil
CustomHealthAPI.PersistentData.GlowingHourglassBackup2 = CustomHealthAPI.PersistentData.GlowingHourglassBackup2 or nil

local isReversingTime = false

function CustomHealthAPI.Helper.AddUseGlowingHourglassCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseGlowingHourglassCallback, CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUseGlowingHourglassCallback)

function CustomHealthAPI.Helper.RemoveUseGlowingHourglassCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseGlowingHourglassCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUseGlowingHourglassCallback)

function CustomHealthAPI.Mod:UseGlowingHourglassCallback()
	if isReversingTime then
		CustomHealthAPI.PersistentData.UsingGlowingHourglass = true
	end
end

function CustomHealthAPI.Helper.AddPreUseGlowingHourglassCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseGlowingHourglassCallback, CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreUseGlowingHourglassCallback)

function CustomHealthAPI.Helper.RemovePreUseGlowingHourglassCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseGlowingHourglassCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreUseGlowingHourglassCallback)

function CustomHealthAPI.Mod:PreUseGlowingHourglassCallback(collectible, rng, player, useflags, activeslot, vardata)
	-- why does this not use vardata wtf
	if activeslot ~= -1 then
		isReversingTime = player:GetActiveCharge(activeslot) <= 0
	else
		isReversingTime = true
	end
end

function CustomHealthAPI.Helper.BackupHealthForGlowingHourglass(slot)
	if slot == 1 then
		CustomHealthAPI.PersistentData.GlowingHourglassBackup2 = CustomHealthAPI.Library.GetHealthBackup()
	else
		CustomHealthAPI.PersistentData.GlowingHourglassBackup = CustomHealthAPI.Library.GetHealthBackup()
	end
end

function CustomHealthAPI.Helper.LoadHealthForGlowingHourglass(slot)
	if slot == 1 then
		CustomHealthAPI.Library.LoadHealthFromBackup(CustomHealthAPI.PersistentData.GlowingHourglassBackup2)
	else
		CustomHealthAPI.Library.LoadHealthFromBackup(CustomHealthAPI.PersistentData.GlowingHourglassBackup)
	end
	
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.GetOtherData(player).LastValues = nil
	end
end
