local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local enums = mod.Enums
local sfx = enums.Utils.SFX
local effects = enums.EdithStatusEffects
local data = mod.DataHolder.GetEntityData
local StatusEffects = {}

local spritePath = "gfx/ui/StatusEffects/"

local Effects = {
    Salt = {
        ID = "EDITH_REBUILT_SALT",
        Sprite = Sprite(spritePath .. "EdithRebuiltSalted.anm2", true),
        Color = Color(1, 1, 1, 1, 0.3, 0.3, 0.3),
    },
    Pepper = {
        ID = "EDITH_REBUILT_PEPPERED",
        Sprite = Sprite(spritePath .. "EdithRebuiltPeppered.anm2", true),
        Color = Color(0.5, 0.5, 0.5),
    },
    Garlic = {
        ID = "EDITH_REBUILT_GARLIC",
        Sprite = Sprite(spritePath .. "EdithRebuiltGarlic.anm2", true),
        Color = Color(1, 1, 1, 1, 1, 238/255, 188/255),
    },
    Oregano = {
        ID = "EDITH_REBUILT_OREGANO",
        Sprite = Sprite(spritePath .. "EdithRebuiltOregano.anm2", true),
        Color = Color(1, 1, 1, 1, 113/255, 120/255, 82/255),
    },
    Cumin = {
        ID = "EDITH_REBUILT_CUMIN",
        Sprite = Sprite(spritePath .. "EdithRebuiltCumin.anm2", true),
        Color = Color(1, 1, 1, 1, 115/255, 84/255, 67/355),
    },
    Turmeric = {
        ID = "EDITH_REBUILT_TURMERIC",
        Sprite = Sprite(spritePath .. "EdithRebuiltTurmeric.anm2", true),
        Color = Color(1, 1, 1, 1, 250/255, 198/255, 49/255),
    },
    Cinnamon = {
        ID = "EDITH_REBUILT_CINNAMON",
        Sprite = Sprite(spritePath .. "EdithRebuiltCinnamon.anm2", true),
        Color = Color(1, 1, 1, 1, 210/255, 105/255, 30/255),
    },
    Ginger = {
        ID = "EDITH_REBUILT_GINGER",
        Sprite = Sprite(spritePath .. "EdithRebuiltGinger.anm2", true),
        Color = Color(1, 1, 1, 1, 239/255, 159/255, 89/255),
    },
    Cinder = {
        ID = "EDITH_REBUILT_CINDER",
        Sprite = Sprite(spritePath .. "EdithRebuiltCinder.anm2", true),
        Color = Color(0.3, 0.3, 0.3),
    },
    HydrargyrumCurse = {
        ID = "EDITH_REBUILT_HYDRARGYRUM_CURSE",
        Sprite = Sprite(spritePath .. "EdithRebuiltHydrargyrum.anm2", true),
        Color = Color(1, 1, 1, 1, 0.5, 0.06, 0.06, 0.91, 0.72, 0.72, 1)
    },
}

for _, Data in pairs(Effects) do
    Data.Sprite:Play("Idle", true)
    SEL.RegisterStatusEffect(Data.ID, Data.Sprite, Data.Color)
end

local Flags = {
    Salt = SEL.StatusFlag[Effects.Salt.ID],
    Pepper = SEL.StatusFlag[Effects.Pepper.ID],
    Garlic = SEL.StatusFlag[Effects.Garlic.ID],
    Oregano = SEL.StatusFlag[Effects.Oregano.ID],
    Cumin = SEL.StatusFlag[Effects.Cumin.ID],
    Turmeric = SEL.StatusFlag[Effects.Turmeric.ID],
    Cinnamon = SEL.StatusFlag[Effects.Cinnamon.ID],
    Ginger = SEL.StatusFlag[Effects.Ginger.ID],
    Cinder = SEL.StatusFlag[Effects.Cinder.ID],
    HydrargyrumCurse = SEL.StatusFlag[Effects.HydrargyrumCurse.ID],
}

---@class SpiceEffect
---@field ID string
---@field Duration integer
---@field Color Color
---@field Cooldown integer

local Spices = {
    [effects.SALTED] = {
        ID = effects.SALTED,
        Duration = 120,
        Color = Color(1, 1, 1, 1, 1.1, 1.1, 1.1),
        Cooldown = 180,
    }, --[[@as SpiceEffect]]
    [effects.GARLIC] = {
        ID = effects.GARLIC,
        Duration = 120,
        Color = Effects.Garlic.Color,
        Cooldown = 120,
    }, --[[@as SpiceEffect]]
    [effects.GINGER] = {
        ID = effects.GINGER,
        Duration = 120,
        Color = Effects.Ginger.Color,
        Cooldown = 120,
    }, --[[@as SpiceEffect]]
    [effects.OREGANO] = {
        ID = effects.OREGANO,
        Duration = 150,
        Color = Effects.Oregano.Color,
        Cooldown = 150,
    }, --[[@as SpiceEffect]]
    [effects.CUMIN] = {
        ID = effects.CUMIN,
        Duration = 90,
        Color = Effects.Cumin.Color,
        Cooldown = 90,
    }, --[[@as SpiceEffect]]
    [effects.PEPPERED] = {
        ID = effects.PEPPERED,
        Duration = 150,
        Color = Effects.Pepper.Color,
        Cooldown = 180,
    }, --[[@as SpiceEffect]]
    [effects.TURMERIC] = {
        ID = effects.TURMERIC,
        Duration = 120,
        Color = Effects.Turmeric.Color,
        Cooldown = 150,
    }, --[[@as SpiceEffect]]
    [effects.CINNAMON] = {
        ID = effects.CINNAMON,
        Duration = 120,
        Color = Effects.Cinnamon.Color,
        Cooldown = 150,
    }, --[[@as SpiceEffect]]
} 

---@param status EdithStatusEffects
---@return SpiceEffect
function StatusEffects.GetSpiceEffectData(status)
    return mod.Modules.HELPERS.When(status, Spices)
end

local numSpices = {
    [1] = Spices[effects.SALTED],
    [2] = Spices[effects.PEPPERED],
    [3] = Spices[effects.GARLIC],
    [4] = Spices[effects.OREGANO],
    [5] = Spices[effects.CUMIN],
    [6] = Spices[effects.TURMERIC],
    [7] = Spices[effects.CINNAMON],
    [8] = Spices[effects.GINGER],
}

---@param num integer
---@return SpiceEffect
function StatusEffects.GetSpiceEffect(num)
    return mod.Modules.HELPERS.When(num, numSpices, Spices[effects.SALTED])
end

---@param ent Entity
---@param status EdithStatusEffects
---@return boolean
function StatusEffects.EntHasStatusEffect(ent, status)
    return SEL:HasStatusEffect(ent, Flags[status])
end

---@param status EdithStatusEffects
---@param ent Entity
---@param dur integer
---@param src Entity
function StatusEffects.SetStatusEffect(status, ent, dur, src)
    if StatusEffects.EntHasStatusEffect(ent, status) then return end
    SEL:AddStatusEffect(ent, Flags[status], dur, EntityRef(src))
end

---@param ent Entity
---@param status EdithStatusEffects
function StatusEffects.GetStatusEffectCountdown(ent, status)
    return SEL:GetStatusEffectCountdown(ent, Flags[status])
end

---@param ent Entity
---@param status EdithStatusEffects
function StatusEffects.GetStatusEffectData(ent, status)
    return SEL:GetStatusEffectData(ent, Flags[status])
end

---@param entity Entity
---@param rng RNG
---@return Entity
function StatusEffects.SpawnSpicePuff(entity, rng)
	sfx:Play(SoundEffect.SOUND_SUMMON_POOF, 1, 0, false, mod.Modules.RNG.RandomFloat(rng, 0.8, 1.2))
	return Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity)
end

---@param ent Entity
---@param spice SpiceEffect
---@param radius number
---@param knockback number
function StatusEffects.TriggerSpiceEffect(ent, spice, radius, knockback)
    local Helpers = mod.Modules.HELPERS

    local player = ent:ToPlayer()
    local JudasBR = player and mod.Modules.PLAYER.IsJudasWithBirthright(player) or false

    for _, enemy in ipairs(Isaac.FindInRadius(ent.Position, radius, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(enemy) then goto continue end
        Helpers.TriggerPush(enemy, ent, knockback)
        StatusEffects.SetStatusEffect(spice.ID, enemy, spice.Duration, ent)

        if player and JudasBR then
            enemy:TakeDamage(player.Damage, 0, EntityRef(player), 0)
            enemy:AddBurn(EntityRef(player), 120, 3.5)
        end

        ::continue::
    end
end

---@param ent EntityNPC
SEL.Callbacks.AddCallback(SEL.Callbacks.ID.POST_REMOVE_ENTITY_STATUS_EFFECT, function (_, ent)
    local npcData = data(ent)
    local SaltType = npcData.SaltType

    if not SaltType then return end

    npcData.SaltType = mod.Modules.BIT_MASK.RemoveBitFlags(npcData.SaltType, SaltType)
end, Flags.Salt)

---@param ent EntityNPC
SEL.Callbacks.AddCallback(StatusEffectLibrary.Callbacks.ID.PRE_ADD_ENTITY_STATUS_EFFECT, function (_, ent)
    local npcData = data(ent)
    npcData.SaltType = npcData.SaltType or 0
end, Flags.Salt)

return StatusEffects