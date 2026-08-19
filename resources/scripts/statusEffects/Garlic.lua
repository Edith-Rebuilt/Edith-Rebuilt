local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if not Status.EntHasStatusEffect(npc, effects.GARLIC) then return end
    local player = Helpers.GetPlayerFromRef(Status.GetStatusEffectData(npc, effects.GARLIC).Source)

    if not player then return end
    if npc.Position:DistanceSquared(player.Position) > 6400 then return end
    Helpers.TriggerPush(npc, player, 2)
end)

---@param proj EntityProjectile
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function(_, proj)
    if not proj.SpawnerEntity then return end
    local npc = proj.SpawnerEntity:ToNPC()

    if not npc then return end
    if not Status.EntHasStatusEffect(npc, effects.GARLIC) then return end
    proj.Velocity = proj.Velocity + RandomVector() * 3
end)