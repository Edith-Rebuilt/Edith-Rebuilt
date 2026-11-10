local mod = EdithRebuilt
local enums = mod.Enums

local items = enums.CollectibleType

local modActiveItems = {
    items.COLLECTIBLE_SALTSHAKER,
    items.COLLECTIBLE_PEPPERGRINDER,
    items.COLLECTIBLE_SULFURIC_FIRE,
    items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL,
    items.COLLECTIBLE_DIVINE_RETRIBUTION,
    items.COLLECTIBLE_SPICES_MIX,
    items.COLLECTIBLE_DIVINE_WRATH,
    items.COLLECTIBLE_BURNT_HOOD,
    items.COLLECTIBLE_EFFIGY,
}

local existingSet = {}

for _, id in ipairs(FiendFolio.creativeAIValidItems) do
    existingSet[id] = true
end

for _, id in ipairs(modActiveItems) do
    if not existingSet[id] then
        table.insert(FiendFolio.creativeAIValidItems, id)
        existingSet[id] = true
    end
end

for _, id in ipairs(FiendFolio.creativeAIValidItems) do
    print(id, Isaac.GetItemConfig():GetCollectible(id).Name)
    
    -- existingSet[id] = true
end