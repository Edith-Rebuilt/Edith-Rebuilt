local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks
local modules = mod.Modules
local Player = modules.PLAYER
local helpers = modules.HELPERS
local TEdithMod = modules.TEDITH
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
local function SpawnLudoTear(player)
    local playerData = data(player)

    if playerData.LudoTear then return end
    local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position, Vector.Zero, player):ToTear() ---@cast tear EntityTear

    helpers.ForceSaltTear(tear, Player.IsEdith(player, true))
    tear:AddTearFlags(player.TearFlags | TearFlags.TEAR_BOUNCE)
    data(tear).FakeLudo = true
    playerData.LudoTear = tear
end

function KillLudoTear(player)
    local playerData = data(player)

    if not playerData.LudoTear then return end
    playerData.LudoTear:Remove()
    playerData.LudoTear = nil
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if not Player.IsAnyEdith(player) then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then return end
    SpawnLudoTear(player)
end)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local tearData = data(tear)

    if not tearData.FakeLudo then return end

    local player = helpers.GetPlayerFromTear(tear)

    if not player then return end

    tear.Height = -23
	tear.Scale = 1.55 * math.max((player.Damage / 3.5), 1)
    tear:MultiplyFriction(0.99)

    if tearData.HitByStomp then
        local velLength = tear.Velocity:Length()
        local damage = velLength + player.Damage * (Player.IsEdithBirthtight(player) and 2 or 1)

        tear.CollisionDamage = damage

        if velLength <= 0.5 then
            tearData.HitByStomp = false
            tear.CollisionDamage = 0
        end
    else
        local playerTearDist = tear.Position:Distance(player.Position)
        local playerTearGridDist = playerTearDist / 40

        tear.Velocity = tear.Velocity + (player.Position - tear.Position):Normalized() * (playerTearGridDist / 4)

        local atractStrenght = 0.4 * playerTearGridDist

        if playerTearDist <= 80 then
            tear:MultiplyFriction(math.min(atractStrenght, 0.95))
        end
    end    
end)

local function InitLudoPush(player, ents, knockback)
    for _, ent in ipairs(ents) do
        local tear = ent:ToTear()

        if not tear then goto continue end
        if not data(tear).FakeLudo then goto continue end

        data(tear).HitByStomp = true
        helpers.TriggerPush(tear, player, 10 + knockback)
        ::continue::
    end
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function(_, player, params)
    InitLudoPush(player, params.StompedEntities, params.Knockback)
end)

---@param player EntityPlayer
mod:AddCallback(Callbacks.POST_PARRY_LAND, function(_, player)
    local params = TEdithMod.GetHopParryParams(player)

    if TEdithMod.GetParryType(params) ~= 2 then return end

    -- print(params.ParriedEnemies[1].Type)

    InitLudoPush(player, params.ParriedEnemies, params.ParryKnockback)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        KillLudoTear(player)
    end
end) 