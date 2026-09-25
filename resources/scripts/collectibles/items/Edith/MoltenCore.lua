local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local MoltenCore = {}
local Helpers = mod.Modules.HELPERS
local data = mod.DataHolder.GetEntityData

local CORE = {
    RADIUS = 120,
    DAMAGE_MULT_MAX = 2,
    DAMAGE_SCALE = 50,
    DAMAGE_INTERVAL = 15,
    COLOR_SCALE = 125,
    KILL_DAMAGE_MULT = 2.5,
}

---@param player EntityPlayer
---@return number
local function GetMaxCoreDamage(player)
    return player.Damage * CORE.DAMAGE_MULT_MAX
end

---@param player EntityPlayer
---@param coreCount number
---@return number
local function GetCoreHeatFormula(player, coreCount)
    return math.min(player.Damage * (coreCount / CORE.DAMAGE_SCALE), GetMaxCoreDamage(player))
end

---@param enemy Entity
---@param coreCount number
local function ApplyCoreHeatColor(enemy, coreCount)
    local t = coreCount / CORE.COLOR_SCALE
    local color = enemy.Color
    color:SetOffset(0.5 * t, 0.125 * t, 0)

    enemy.Color = color
end

---@param player EntityPlayer
---@param enemy Entity
local function ProcessCoreHeat(player, enemy)
    local coreCount = data(enemy).CoreCount
    if not coreCount then return end

    local formula = GetCoreHeatFormula(player, coreCount)

    if formula < GetMaxCoreDamage(player) then
        ApplyCoreHeatColor(enemy, coreCount)
    end

    if coreCount % CORE.DAMAGE_INTERVAL == 0 then
        enemy:TakeDamage(formula, DamageFlag.DAMAGE_FIRE, EntityRef(player), 0)
    end
end

---@param player EntityPlayer
---@param value number
mod:AddCallback(ModCallbacks.MC_EVALUATE_STAT, function(_, player, _, value)
    local count = player:GetCollectibleNum(items.COLLECTIBLE_MOLTEN_CORE)
    if count < 1 then return end
    return value * (1.25 * count)
end, EvaluateStatStage.PRE_FLAT_DAMAGE)


mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not player:HasCollectible(items.COLLECTIBLE_MOLTEN_CORE) then return end

    for _, enemy in ipairs(Isaac.FindInRadius(player.Position, CORE.RADIUS, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(enemy) then goto continue end
        data(enemy).IsInCoreRadius = true
        ProcessCoreHeat(player, enemy)
        ::continue::
    end
end)

function MoltenCore:NPCUpdate(npc)
    local npcData = data(npc)

    if not npcData.IsInCoreRadius then
        npcData.CoreCount = 0
        npc.Color = Color.Default
        return
    end

    npcData.CoreCount = (npcData.CoreCount or 0) + 1
    npcData.IsInCoreRadius = false
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, MoltenCore.NPCUpdate)

function MoltenCore:KillingSalEnemy(entity, source)
    local player = Helpers.GetPlayerFromRef(source)
    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_MOLTEN_CORE) then return end
    if not Helpers.IsEnemy(entity) then return end
    if not data(entity).IsInCoreRadius then return end

    Helpers.SpawnFireJet(entity.Position, player.Damage * CORE.KILL_DAMAGE_MULT, 1, 2)
end
mod:AddCallback(PRE_NPC_KILL.ID, MoltenCore.KillingSalEnemy)