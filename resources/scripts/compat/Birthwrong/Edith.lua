---@diagnostic disable: undefined-global
if not Birthwrong then return end

local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local Status = modules.STATUS_EFFECTS
local Jump = modules.JUMP
local room = enums.Utils.Room
local saveManager = mod.SaveManager

local DISSOLUTION = {
    WATER_FILL_RATE = 0.05,
    SPEED_REDUCTION_RATE = 0.01,
    MIN_MOVE_SPEED = 0.1,
    SHOOT_SPEED_THRESHOLD = 0.7,
    SPEED_TICK_INTERVAL = 20,
    KILL_SPEED_RESTORE = -5,
}

Birthwrong.registerDescription(enums.PlayerType.PLAYER_EDITH, "Dissolution, flooded rooms", "Rooms will become flooded, Edith will lose speed when touching water")

local waterAmount = 0

---@param player EntityPlayer
---@return boolean
local function IsEdithBW(player)
    return Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH)
end

---@param player EntityPlayer
---@param amount integer
local function AddToSpeedReductionCounter(player, amount)
    local runSave = saveManager.GetRunSave(player)
    if not runSave then return end
    runSave.SpeedReduction = math.max(runSave.SpeedReduction + amount, 0)
end

---@return boolean
local function TryFillWater()
    if waterAmount >= 1 then return false end
    waterAmount = math.min(waterAmount + DISSOLUTION.WATER_FILL_RATE, 1)
    room:SetWaterAmount(waterAmount)
    return true
end

---@param player EntityPlayer
local function ManageSpeedReduction(player)
    if Jump.IsJumping(player) then return end
    if player.FrameCount % DISSOLUTION.SPEED_TICK_INTERVAL ~= 0 then return end
    if Maths.Round(player.MoveSpeed, 2) == DISSOLUTION.MIN_MOVE_SPEED then return end

    Helpers.SpawnSaltGib(player, 4, 2)
    player:SetCanShoot(player.MoveSpeed >= DISSOLUTION.SHOOT_SPEED_THRESHOLD)

    AddToSpeedReductionCounter(player, 1)
    player:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local runSave = saveManager.GetRunSave(player)
    if not runSave then return end
    if not IsEdithBW(player) then return end

    runSave.SpeedReduction = runSave.SpeedReduction or 0

    if TryFillWater() then return end
    ManageSpeedReduction(player)
end)

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
    local runSave = saveManager.GetRunSave(player)
    if not runSave then return end
    if not IsEdithBW(player) then return end

    player.MoveSpeed = player.MoveSpeed - (DISSOLUTION.SPEED_REDUCTION_RATE * runSave.SpeedReduction)
end, CacheFlag.CACHE_SPEED)

mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_KILL, function(_, player, ent)
    if not IsEdithBW(player) then return end
    if not Helpers.IsEnemy(ent) then return end
    if not Status.EntHasStatusEffect(ent, enums.EdithStatusEffects.SALTED) then return end

    AddToSpeedReductionCounter(player, DISSOLUTION.KILL_SPEED_RESTORE)
    player:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if not IsEdithBW(player) then goto continue end
        room:SetWaterAmount(1)
        ::continue::
    end
end)