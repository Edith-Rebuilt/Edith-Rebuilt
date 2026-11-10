local referenceItems = {
    Actives = {
        {
            ID = EdithRebuilt.Enums.CollectibleType.COLLECTIBLE_SALTSHAKER,         
            Reference = "The Binding of Isaac: Antibirth" 
        }
    }
}

for i = 1, #referenceItems.Actives do
    table.insert(FiendFolio.ReferenceItems.Actives, referenceItems.Actives[i])
end
