local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local Helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local SaveManager = mod.SaveManager

local SULFURIC = {
    RADIUS_BASE = 100,
    RADIUS_JUDAS = 150,
    DAMAGE_SCALE = 0.175,
    PUSH_FORCE = 20,
    BRIMSTONE_DURATION = 150,
    DAMAGE_BOOST_BASE = 2.5,
    DAMAGE_BOOST_DUR = 120,
    JUDAS_MULT = 1.5,
    CAR_BATTERY_MULT = 1.25,
    SHAKE_INTENSITY = 12,
    IDENTIFIER = "EdithRebuilt_SulfuricFire",
    TEAR_COLOR = Color(1, 0.2, 0.2, 1, 0, 0, 0, 0, 0, 0, 0.34)
}

---@param player EntityPlayer
---@return boolean
local function HasSulfuricFireDamageBoost(player)
    return TempStatLib and TempStatLib:GetTempStat(player, SULFURIC.IDENTIFIER) ~= nil
end

---@param player EntityPlayer
---@return number, number
local function GetSulfuricMultipliers(player)
    local judasMult = Player.IsJudasWithBirthright(player) and SULFURIC.JUDAS_MULT or 1
    local carBatteryMult = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) and SULFURIC.CAR_BATTERY_MULT or 1
    return judasMult, carBatteryMult
end

---@param player EntityPlayer
---@param totalDamageBoost number
local function TriggerTempDamageUp(player, totalDamageBoost)
    TempStatLib:AddTempStat(player, {
        Amount = totalDamageBoost,
        Duration = SULFURIC.DAMAGE_BOOST_DUR,
        Stat = CacheFlag.CACHE_DAMAGE,
        Identifier = SULFURIC.IDENTIFIER,
    } --[[@as TempStatConfig]])
end

---@param player EntityPlayer
---@param flag UseFlag
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, flag)
    if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end

    local judasMult, carBatteryMult = GetSulfuricMultipliers(player)
    local radius = Player.IsJudasWithBirthright(player) and SULFURIC.RADIUS_JUDAS or SULFURIC.RADIUS_BASE
    local hitEnemies = Isaac.FindInRadius(player.Position, radius, EntityPartition.ENEMY)

    if #hitEnemies <= 0 then return end

    Helpers.TriggerSulfuricFireDamage(player, judasMult, carBatteryMult, EntityRef(player), hitEnemies)
    TriggerTempDamageUp(player, SULFURIC.DAMAGE_BOOST_BASE * judasMult * carBatteryMult * #hitEnemies)

    enums.Utils.Game:ShakeScreen(SULFURIC.SHAKE_INTENSITY)
    return true
end, items.COLLECTIBLE_SULFURIC_FIRE)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)
    if not player then return end
    if not HasSulfuricFireDamageBoost(player) then return end
    tear.Color = SULFURIC.TEAR_COLOR
end)

---@param ent Entity
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, ent, source)
    if not ent:ToNPC() then return end
    local player = Helpers.GetPlayerFromRef(source)
    if not player then return end
    if not HasSulfuricFireDamageBoost(player) then return end
    player:FireBrimstoneBall(ent.Position, Vector.Zero)
end)