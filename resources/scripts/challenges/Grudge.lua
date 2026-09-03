local mod = EdithRebuilt
local enums = mod.Enums
local sfx = enums.Utils.SFX
local modules = mod.Modules
local Helpers = modules.HELPERS
local TEdithMod = modules.TEDITH
local Player = modules.PLAYER
local data = mod.DataHolder.GetEntityData

local function HandleFireplaceCollision(collider)
    if not (collider.Type == EntityType.ENTITY_FIREPLACE and collider.Variant ~= 4) then return end
    collider:Die()
end

---@param player EntityPlayer
---@param collider Entity
---@param hopParams TEdithHopParryParams
local function HandleGrudgeDashDamage(player, collider, hopParams)
    if not hopParams.GrudgeDash then return end
    if not Helpers.IsEnemy(collider) then return end
    if data(player).IsRedirectioningMove then return end

    local speed = player.Velocity:Length()
    local damage = (
        (player.Damage / 2) +
        (player.MoveSpeed) / 3 +
        (speed / 4) * ((TEdithMod.GetHopDashCharge(player, false, true) / 200) / 2)
    )

    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
    collider.Velocity = collider.Velocity + player.Velocity
    collider:TakeDamage(damage, DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(player), 0)
end

---@param player EntityPlayer
---@param collider Entity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function(_, player, collider)
    if not Player.IsEdith(player, true) then return end
    if not Helpers.IsGrudgeChallenge() then return end

    HandleFireplaceCollision(collider)
    HandleGrudgeDashDamage(player, collider, TEdithMod.GetHopParryParams(player))
end)