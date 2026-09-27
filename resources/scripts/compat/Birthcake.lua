---@diagnostic disable: undefined-global
local function BirthcakeCompat()
    local mod = EdithRebuilt
    local enums = mod.Enums
    local players = enums.PlayerType
    local birthCakeAPI = BirthcakeRebaked.API
    local path = "gfx/items/trinkets/EdithRebuilt_"
    local EdithSuffix = "Edith_Birthcake.png"
    local TEdithSuffix = "T_Edith_Birthcake.png"
    local Info = {
        [players.PLAYER_EDITH] = { 
            Description = "Saltier stomps",
            SpriteInfo = {SpritePath = path .. EdithSuffix , PickupSpritePath = path .. EdithSuffix}
        },
        [players.PLAYER_EDITH_B] = {
            Description = "Stronger parry",
            SpriteInfo = {SpritePath = path .. TEdithSuffix, PickupSpritePath = path .. TEdithSuffix}
        }
    }

    for k, v in pairs(Info) do
        birthCakeAPI:AddBirthcakePickupText(k, v.Description)
        birthCakeAPI:AddBirthcakeSprite(k, v.SpriteInfo)
    end
end

EdithRebuilt.PatchesLoader.RegisterPatch("BirthcakeRebaked", BirthcakeCompat)