if not CustomHealthAPI then return end
if not CustomHealthAPI.Library then return end

local mod = EdithRebuilt
local mainEnums = mod.Enums
local enums = EdithRebuilt_SaltHearts.Enums
local SubTypes = enums.HeartSubType
local sounds = mainEnums.SoundEffect
local saveManager = mod.SaveManager
local StatusEffect = mod.Modules.STATUS_EFFECTS
local effects = mainEnums.EdithStatusEffects

local flashColor = 170/255

CustomHealthAPI.Library.RegisterSoulHealth(
    "HEART_SALT",
    {
        AnimationFilename = "gfx/CRemix/ui_salt_hearts.anm2",
        AnimationName = {"SaltHeartOneThird", "SaltHeartTwoThirds", "SaltHeartFull"},
        SortOrder = 150,
        AddPriority = 175,
        HealFlashRO = flashColor,
        HealFlashGO = flashColor,
        HealFlashBO = flashColor,
        MaxHP = 3,
        CollectSound = { ID = sounds.SOUND_SALT_SHAKER, Volume = 1.0, Pitch = 1.0 },
	    PrioritizeHealing = true,
        PickupEntities = {
            {
                ID = EntityType.ENTITY_PICKUP,
                Var = PickupVariant.PICKUP_HEART,
                Sub = SubTypes.SALT_HEART
            },
            {
                ID = EntityType.ENTITY_PICKUP, 
                Var = PickupVariant.PICKUP_HEART, 
                Sub = SubTypes.SALT_HEART_2_THIRDS
            },
            {
                ID = EntityType.ENTITY_PICKUP, 
                Var = PickupVariant.PICKUP_HEART, 
                Sub = SubTypes.SALT_HEART_1_THIRD
            },
        },
        SumptoriumSubType = 20,  -- immortal heart clot
        SumptoriumSplatColor = Color(1.00, 1.00, 1.00, 1.00, 214/255, 228/255, 1.00),
        SumptoriumTrailColor = Color(1.00, 1.00, 1.00, 1.00, 214/255, 228/255, 1.00),
        SumptoriumCollectSoundSettings = {
            ID = SoundEffect.SOUND_MEAT_IMPACTS,
            Volume = 1.0,
            FrameDelay = 0,
            Loop = false,
            Pitch = 1.0,
            Pan = 0
        }
    }
)

local health = {
    [SubTypes.SALT_HEART] = 3,
    [SubTypes.SALT_HEART_2_THIRDS] = 2,
    [SubTypes.SALT_HEART_1_THIRD] = 1
}

for heart, amount in pairs(health) do
    CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, heart, {
        HealthKeys = {"HEART_SALT"},
        HealthAmount = amount,
        DropSound = sounds.SOUND_SALT_SHAKER,
        AllowCandyHeartSoulLocketBonus = true,
        AllowImmaculateConception = false,
        AllowMagneto = true,
    })
end


CustomHealthAPI.Library.AddCallback("EdithRebuilt", CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED, 0, function(player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
    if key ~= "HEART_SALT" then return end
    if not wasDepleted then return end

    StatusEffect.SetStatusEffect(effects.SALTED, player, 120, player)
end)

saveManager.InitCHAPI(CustomHealthAPI)