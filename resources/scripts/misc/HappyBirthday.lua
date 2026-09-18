local mod = EdithRebuilt
local Utils = mod.Enums.Utils
local game = Utils.Game
local sfx = Utils.SFX
local Music = MusicManager()
local modules = mod.Modules
local Player = modules.PLAYER
local HappyBirthday = Isaac.GetMusicIdByName("HappyBirthday")
local PartyHorn = Isaac.GetSoundIdByName("PartyHorn")

local date = os.date("*t")
local day = date.day
local month = date.month

---@param player EntityPlayer
local function MusicStart(player)
    if not Player.IsAnyEdith(player) then return end
    if game:GetFrameCount() ~= 1 then return end

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIREWORKS, 0, player.Position, Vector.Zero, nil)

    Music:PlayJingle(HappyBirthday, 720)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if not (day == 18 and month == 9) then return end

    MusicStart(player)

    if game:GetFrameCount() == 370 then
        sfx:Play(PartyHorn, 2, 0, false, 1.5)
    end
end)