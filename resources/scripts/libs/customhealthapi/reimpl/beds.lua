if REPENTOGON then
-- need to use MC_PRE_TRIGGER_BED_SLEEP_EFFECT instead of MC_POST_TRIGGER_BED_SLEEP_EFFECT cause the latter is broken atm
function CustomHealthAPI.Helper.AddBedSleepEffectCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_TRIGGER_BED_SLEEP_EFFECT, math.huge, CustomHealthAPI.Mod.BedSleepEffectCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddBedSleepEffectCallback)

function CustomHealthAPI.Helper.RemoveBedSleepEffectCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_TRIGGER_BED_SLEEP_EFFECT, CustomHealthAPI.Mod.BedSleepEffectCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveBedSleepEffectCallback)

function CustomHealthAPI.Mod:BedSleepEffectCallback(player, bed)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return
	end
	
	if CustomHealthAPI.Helper.GetHealableRedHP(player) > 0 then
		-- full heal
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 99, true, false, false, true)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		SFXManager():Play(SoundEffect.SOUND_POWERUP1)
	end
end
end