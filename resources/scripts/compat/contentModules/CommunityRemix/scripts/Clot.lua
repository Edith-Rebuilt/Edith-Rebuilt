local mod = EdithRebuilt_SaltHearts
local enums = mod.Enums
local mainMod = EdithRebuilt

local saltTypes = mainMod.Enums.SaltTypes

local modules = mainMod.Modules
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local Creeps = modules.CREEPS

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local nearEnts = Isaac.FindInRadius(tear.Position - tear.Velocity, tear.Size, EntityPartition.FAMILIAR)

    local player = Helpers.GetPlayerFromTear(tear)

    if not player then return end

    local roundedPlayerDamage = Maths.Round(player.Damage, 2)
    local roundedTearDamage = Maths.Round(tear.BaseDamage, 2)

    if roundedPlayerDamage == roundedTearDamage then return end

    for _, ent in ipairs(nearEnts) do
        local fam = ent:ToFamiliar()

        if not fam then goto continue end
        if fam.Variant ~= FamiliarVariant.BLOOD_BABY then goto continue end
        if fam.SubType ~= enums.BloodClotSubtype.SALT then goto continue end

        mainMod.Modules.HELPERS.ForceSaltTear(tear, false)
        ::continue::
    end
end)

---@param familiar EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
    if familiar.SubType ~= enums.BloodClotSubtype.SALT then return end
    if familiar.FrameCount % 15 ~= 0 then return end

    local salt = Creeps.SpawnSaltCreep(familiar, familiar.Position, 0, 3, 1, 1, saltTypes.SAL)

    salt.SpriteScale = salt.SpriteScale / 2
    salt:Update()
end, FamiliarVariant.BLOOD_BABY)