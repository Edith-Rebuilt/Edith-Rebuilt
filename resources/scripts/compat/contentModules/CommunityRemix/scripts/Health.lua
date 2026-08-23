if not CustomHealthAPI then return end
if not CustomHealthAPI.Library then return end

local mod = EdithRebuilt
local enums = mod.Enums
local SubType = Isaac.GetEntitySubTypeByName("Salt Heart (pickup)")
local sounds = enums.SoundEffect
local saveManager = mod.SaveManager
local StatusEffect = mod.Modules.STATUS_EFFECTS
local effects = enums.EdithStatusEffects

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
            {ID = EntityType.ENTITY_PICKUP, Var = PickupVariant.PICKUP_HEART, Sub = SubType}
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

CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, SubType, {
	HealthKeys = {"HEART_SALT"},
	HealthAmount = 3,
	DropSound = sounds.SOUND_SALT_SHAKER,
	AllowCandyHeartSoulLocketBonus = true,
	AllowImmaculateConception = false,
    AllowMagneto = true,
})

CustomHealthAPI.Library.AddCallback("EdithRebuilt", CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED, 0, function(player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
    if key ~= "HEART_SALT" then return end
    if not wasDepleted then return end

    StatusEffect.SetStatusEffect(effects.SALTED, player, 120, player)
end)

saveManager.InitCHAPI(CustomHealthAPI)