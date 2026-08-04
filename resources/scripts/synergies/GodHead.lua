local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
---@param isStomp boolean
local function SpawnGodTear(player, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then return end

    local hasBirthright = Player.PlayerHasBirthright(player)
    local scaleBase = (isStomp and hasBirthright and 2) or 1.5
    local godTear = player:FireTear(player.Position, Vector.Zero)

    godTear.Scale = scaleBase * player.SpriteScale.X
    godTear.CollisionDamage = 0
    godTear.Height = -10
    godTear:Update()
    godTear:AddTearFlags(TearFlags.TEAR_GLOW | TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)

    data(godTear).SynergyGodTear = isStomp and "stomp" or "parry"
    helpers.ChangeColor(godTear, nil, nil, nil, 0)
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) SpawnGodTear(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) SpawnGodTear(player, true)  end)

local count = 12

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local tearData = data(tear)
    if not tearData.SynergyGodTear then return end

    tear.Height = -10
    tear.Position = (tear.Parent or tear.SpawnerEntity).Position

    if tearData.SynergyGodTear == "stomp" then
        local player = helpers.GetPlayerFromTear(tear) --[[@as EntityPlayer]]
        count = Player.PlayerHasBirthright(player) and 24 or 12
    end

    if tear.FrameCount < count then return end
    tear:Remove()
end)
