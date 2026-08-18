local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local saveManager = mod.SaveManager
local achievements = enums.Achievements
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local pgd = utils.PGD
local room = utils.Room
local EdithStatusEffects = enums.EdithStatusEffects
local parryTypes = enums.ParryTypes
local modules = mod.Modules
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local StatusEffects = modules.STATUS_EFFECTS
local TEdithMod = modules.TEDITH
local callbacks = enums.Callbacks
local UnlockTable = {
    Edith = {
        [CompletionType.MOMS_HEART] = {
            Unlock = achievements.ACHIEVEMENT_GEODE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.ISAAC] = {
            Unlock = achievements.ACHIEVEMENT_SALT_SHAKER,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.SATAN] = {
            Unlock = achievements.ACHIEVEMENT_SULFURIC_FIRE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BOSS_RUSH] = {
            Unlock = achievements.ACHIEVEMENT_RUMBLING_PEBBLE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BLUE_BABY] = {
            Unlock = achievements.ACHIEVEMENT_PEPPER_GRINDER,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.LAMB] = {
            Unlock = achievements.ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.MEGA_SATAN] = {
            Unlock = achievements.ACHIEVEMENT_MOLTEN_CORE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.ULTRA_GREED] = {
            Unlock = achievements.ACHIEVEMENT_HYDRARGYRUM,
            Difficulty = Difficulty.DIFFICULTY_GREED,
        },
        [CompletionType.HUSH] = {
            Unlock = achievements.ACHIEVEMENT_SAL,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.DELIRIUM] = {
            Unlock = achievements.ACHIEVEMENT_SPICES_MIX,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.MOTHER] = {
            Unlock = achievements.ACHIEVEMENT_DIVINE_RETRIBUTION,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BEAST] = {
            Unlock = achievements.ACHIEVEMENT_EDITHS_HOOD,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
    },
    TEdith = {
        [CompletionType.MEGA_SATAN] = {
            Unlock = achievements.ACHIEVEMENT_SALT_ROCKS,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.MOTHER] = {
            Unlock = achievements.ACHIEVEMENT_PAPRIKA,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.DELIRIUM] = {
            Unlock = achievements.ACHIEVEMENT_BURNT_HOOD,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BEAST] = {
            Unlock = achievements.ACHIEVEMENT_DIVINE_WRATH,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        TaintedMarksGroup = {
            [TaintedMarksGroup.SOULSTONE] = achievements.ACHIEVEMENT_SOUL_OF_EDITH,
            [TaintedMarksGroup.POLAROID_NEGATIVE] = achievements.ACHIEVEMENT_BURNT_SALT
        }
    }
}

local GreedierUnlocks = {
    [players.PLAYER_EDITH] = {
        achievements.ACHIEVEMENT_HYDRARGYRUM,
        achievements.ACHIEVEMENT_GILDED_STONE,
    },
    [players.PLAYER_EDITH_B] = {
        achievements.ACHIEVEMENT_JACK_OF_CLUBS,
    }
}

local function ThankYou()
    local isComplete = true

    for _, v in pairs(achievements) do
        if v == achievements.ACHIEVEMENT_THANK_YOU then goto continue end
        if not pgd:Unlocked(v) then
            isComplete = false
            break
        end
        ::continue::
    end

    if not isComplete then return end
    pgd:TryUnlock(achievements.ACHIEVEMENT_THANK_YOU)
end
mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, ThankYou)

---@param player PlayerType
---@param difficulty Difficulty
local function GreedierUnlockManager(player, difficulty)
    if difficulty ~= Difficulty.DIFFICULTY_GREEDIER then return end

    local unlockTable = Helpers.When(player, GreedierUnlocks)

    if not unlockTable then return end

    for _, ach in ipairs(unlockTable) do
        pgd:TryUnlock(ach)
    end
end

local function TaintedMarksGroupUnlockManager()
    for group, ach in pairs(UnlockTable.TEdith.TaintedMarksGroup) do
        if Isaac.AllTaintedCompletion(players.PLAYER_EDITH_B, group) == 2 then
            pgd:TryUnlock(ach)
        end
    end
end

---@param mark CompletionType
---@param player PlayerType
---@return {Difficulty: Difficulty, Unlock: Achievement}?
local function GetUnlockTable(mark, player)
    local tableRef = (
        player == players.PLAYER_EDITH and UnlockTable.Edith or
        player == players.PLAYER_EDITH_B and UnlockTable.TEdith
    )

    if not tableRef then return end
    return Helpers.When(mark, tableRef)
end

---@param mark CompletionType
---@param player PlayerType
---@param difficulty Difficulty
local function TriggerMarkUnlock(mark, player, difficulty)
    local unlock = GetUnlockTable(mark, player)

    if not unlock then return end
    if difficulty ~= unlock.Difficulty then return end

    pgd:TryUnlock(unlock.Unlock)
end

---@param player PlayerType
local function CompletionBonusManager(player)
    if player == players.PLAYER_EDITH_B then
        TaintedMarksGroupUnlockManager()
    end

    if Isaac.AllMarksFilled(players.PLAYER_EDITH) == 2 then
        pgd:TryUnlock(achievements.ACHIEVEMENT_SALT_HEART)
    end
end

---@param mark CompletionType
---@param player PlayerType
mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARK_GET, function(_, mark, player)
    local difficulty = game.Difficulty

    GreedierUnlockManager(player, difficulty)
    TriggerMarkUnlock(mark, player, difficulty)
    CompletionBonusManager(player)
    ThankYou()
end)

mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, function(_, slot)
    local player = Isaac.GetPlayer()

    if not Player.IsEdith(player, false) then return end
    local playerConfig = EntityConfig.GetPlayer(player:GetPlayerType()):GetTaintedCounterpart()

    if not playerConfig then return end
    slot:GetSprite():ReplaceSpritesheet(0, playerConfig:GetSkinPath(), true)
end, SlotVariant.HOME_CLOSET_PLAYER)

---@param slot EntitySlot
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
    if not slot:IsDead() then return end
    if not slot:GetSprite():IsFinished() then return end
    if not Player.IsEdith(Isaac.GetPlayer(), false) then return end

    pgd:TryUnlock(achievements.ACHIEVEMENT_TAINTED_EDITH)
end, SlotVariant.HOME_CLOSET_PLAYER)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if level:GetStage() ~= LevelStage.STAGE8 then return end
    if level:GetCurrentRoomDesc().SafeGridIndex ~= 94 then return end
    if game:AchievementUnlocksDisallowed() then return end
    if not Player.IsEdith(Isaac.GetPlayer(), false) then return end
    if pgd:Unlocked(achievements.ACHIEVEMENT_TAINTED_EDITH) then return end
    if not room:IsFirstVisit() then return end

    for _, k in ipairs(Isaac.FindByType(17)) do k:Remove() end
    for _, i in ipairs(Isaac.FindByType(5)) do i:Remove() end

    Isaac.Spawn(6, 14, 0, room:GetCenterPos(), Vector.Zero, nil)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if player:GetNumBombs() < 25 then return end
    pgd:TryUnlock(achievements.ACHIEVEMENT_EDITH)
end)

local VestigeAch = achievements.ACHIEVEMENT_VESTIGE

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(callbacks.OFFENSIVE_STOMP_KILL, function (_, player, ent)
    if not Player.IsEdith(player, false) then return end
    if not StatusEffects.EntHasStatusEffect(ent, EdithStatusEffects.SALTED) then return end
    if pgd:Unlocked(VestigeAch) then return end

    local PersistentData = saveManager.GetPersistentSave()

    if not PersistentData then return end

    PersistentData.StompKills = (PersistentData.StompKills or 0) + 1

    if PersistentData.StompKills < 15 then return end

    pgd:TryUnlock(VestigeAch)
    PersistentData.StompKills = 0
end)

local GrudgeAch = enums.Achievements.ACHIEVEMENT_GRUDGE

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(callbacks.POST_PARRY_LAND, function (_, player, ent)
    if not Player.IsEdith(player, true) then return end
    if pgd:Unlocked(GrudgeAch) then return end

    local PersistentData = saveManager.GetPersistentSave()

	if not PersistentData then return end

    local parryType = TEdithMod.GetParryType(TEdithMod.GetHopParryParams(player))

    PersistentData.ConsecutiveParries = PersistentData.ConsecutiveParries or 0

    if parryType == parryTypes.PERFECT then
        PersistentData.ConsecutiveParries = PersistentData.ConsecutiveParries + 1
    else
        PersistentData.ConsecutiveParries = 0
    end

    if PersistentData.ConsecutiveParries < 5 then return end
    pgd:TryUnlock(GrudgeAch)
end)