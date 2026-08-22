if not CustomHealthAPI then return end
if not CustomHealthAPI.Library then return end

CustomHealthAPI.Library.RegisterSoulHealth(
    "HEART_SALT",
    {
        AnimationFilename = "gfx/ui/ui_remix_hearts.anm2",
        AnimationName = {"ImmortalHeartHalf", "ImmortalHeartFull"},
        SortOrder = 150,
        AddPriority = 175,
        HealFlashRO = 240/255, 
        HealFlashGO = 240/255,
        HealFlashBO = 240/255,
        MaxHP = 2,
        CollectSound = { ID = RestoredHearts.Enums.SFX.Hearts.IMMORTAL_PICKUP, Volume = 1.0, Pitch = 1.0 },
	    PrioritizeHealing = true,
        PickupEntities = {
            {ID = EntityType.ENTITY_PICKUP, Var = PickupVariant.PICKUP_HEART, Sub = RestoredHearts.Enums.Pickups.Hearts.HEART_IMMORTAL}
        },
        -- SumptoriumSubType = 20,  -- immortal heart clot
        -- SumptoriumSplatColor = Color(1.00, 1.00, 1.00, 1.00, 214/255, 228/255, 1.00),
        -- SumptoriumTrailColor = Color(1.00, 1.00, 1.00, 1.00, 214/255, 228/255, 1.00),
        -- SumptoriumCollectSoundSettings = {
        --     ID = SoundEffect.SOUND_MEAT_IMPACTS,
        --     Volume = 1.0,
        --     FrameDelay = 0,
        --     Loop = false,
        --     Pitch = 1.0,
        --     Pan = 0
        -- }
    }
)