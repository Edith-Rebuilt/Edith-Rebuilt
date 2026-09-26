local enums = EdithRebuilt.Enums
local PlayerType = enums.PlayerType
local modules = EdithRebuilt.Modules
local Player = modules.PLAYER
local modifName = "EdithRebuilt Stomp synergy"

-- EID:addPlayerCondition(
--     CollectibleType.COLLECTIBLE_BRIMSTONE, PlayerType.PLAYER_EDITH, "MIERDAAAAAAAAAAAAAAAA"
-- )

local Items = {
    [CollectibleType.COLLECTIBLE_BRIMSTONE] = {
        ["en_us"] = {
            [true] = "Stomps spawns rotating 6 short range Brimstone lasers",
            [false] = "Stomps spawns rotating 4 short range Brimstone lasers"
        }
    }
}

-- EID:AddPlayerConditional(CollectibleType.COLLECTIBLE_BRIMSTONE, charIDs, modText, extraTable, includeTainted)

EID:addDescriptionModifier(modifName, function(descObj)
    if descObj.ObjType ~= EntityType.ENTITY_PICKUP then return false end
    if descObj.ObjVariant ~= PickupVariant.PICKUP_COLLECTIBLE then return false end

    local subType = descObj.SubType
    -- if not Player.AnyoneIsEdith() then return false end

    for k, v in pairs(descObj) do
        print(k, v)
    end

    -- return true
end, 
function(descObj)
    descObj.Description = descObj.Description .. Items[descObj.SubType]
    return descObj
end)