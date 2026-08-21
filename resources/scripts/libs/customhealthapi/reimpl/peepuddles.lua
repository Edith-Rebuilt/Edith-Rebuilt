local game = Game()

function CustomHealthAPI.Helper.AddPeePuddleInitCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_EFFECT_INIT, -1 * math.huge, CustomHealthAPI.Mod.PeePuddleInitCallback, EffectVariant.BLOOD_SPLAT)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPeePuddleInitCallback)

function CustomHealthAPI.Helper.RemovePeePuddleInitCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_EFFECT_INIT, CustomHealthAPI.Mod.PeePuddleInitCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePeePuddleInitCallback)

function CustomHealthAPI.Mod:PeePuddleInitCallback(puddle)
	if game:GetRoom():GetFrameCount() == 0 then
		local players = Isaac.FindInRadius(puddle.Position, 1, EntityPartition.PLAYER)
		for _, player in ipairs(players) do
			if player.Position:Distance(puddle.Position) < 0.0001 then
				if CustomHealthAPI.Helper.GetTotalHP(player:ToPlayer()) > 1 then
					puddle:Remove()
					return
				end
			end
		end
	end
end