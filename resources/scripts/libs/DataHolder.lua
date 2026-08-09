-- Script taken from Isaac Blue Prints (https://isaacblueprints.com/tutorials/concepts/entity_data/)
local mod = EdithRebuilt
local dataHolder = {}
local data = {}

---@param entity any
---@return table
function dataHolder.GetEntityData(entity)
    local ptrHash = GetPtrHash(entity)

    data[ptrHash] = data[ptrHash] or {}

    return data[ptrHash]
end

local ClearDataCallbacks = {
    ModCallbacks.MC_POST_NPC_INIT,
    ModCallbacks.MC_POST_PLAYER_INIT,
    ModCallbacks.MC_POST_TEAR_INIT,
    ModCallbacks.MC_POST_LASER_INIT,
    ModCallbacks.MC_POST_BOMB_INIT,
    ModCallbacks.MC_POST_KNIFE_INIT,
    ModCallbacks.MC_POST_PICKUP_INIT,
    ModCallbacks.MC_POST_EFFECT_INIT,
    ModCallbacks.MC_POST_SLOT_INIT,
    ModCallbacks.MC_POST_PROJECTILE_INIT,
    ModCallbacks.MC_FAMILIAR_INIT,
    ModCallbacks.MC_POST_ENTITY_REMOVE,
    ModCallbacks.MC_POST_NPC_DEATH,
}
---@cast ClearDataCallbacks ModCallbacks[]

local function ClearEntityData(_, ent)
    data[GetPtrHash(ent)] = nil
end

for _, callback in ipairs(ClearDataCallbacks) do
    mod:AddPriorityCallback(callback, CallbackPriority.IMPORTANT, ClearEntityData)
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
    data = {}
end)

return dataHolder