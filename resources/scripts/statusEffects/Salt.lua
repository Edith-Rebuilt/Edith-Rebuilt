local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS

local data = mod.DataHolder.GetEntityData

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param Cooldown integer
---@return boolean|table?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, _, Cooldown)
    if not Status.EntHasStatusEffect(entity, effects.SALTED) then return end
    return {Damage = amount * 1.35, DamageFlags = flags, DamageCountdown = Cooldown}
end)

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if not Status.EntHasStatusEffect(npc, effects.SALTED) then return end
    if JumpLib:GetData(npc).Jumping then return end
    npc:MultiplyFriction(0.6)
end)

local SEL = StatusEffectLibrary
local SELCallbacks = SEL.Callbacks

---@param ent EntityNPC
SELCallbacks.AddCallback(SELCallbacks.ID.POST_REMOVE_ENTITY_STATUS_EFFECT, function (_, ent)
    local npcData = data(ent)
    local SaltType = npcData.SaltType ---@as SaltTypes

    if not SaltType then return end

    npcData.SaltType = mod.Modules.BIT_MASK.RemoveBitFlags(npcData.SaltType, SaltType)
end, Status.Flags.Salt)

---@param ent EntityNPC
SELCallbacks.AddCallback(SELCallbacks.ID.PRE_ADD_ENTITY_STATUS_EFFECT, function (_, ent)
    local npcData = data(ent)
    npcData.SaltType = npcData.SaltType or 0
end, Status.Flags.Salt)
