local game = Game()
local EdithPlayer = Isaac.GetPlayerTypeByName("Edith​​​", false)
local EdithBPlayer = Isaac.GetPlayerTypeByName("Edith​​​", true)
local edithJumpTag = "edithRebuilt_EdithJump"
local tedithJumpTag = "edithRebuilt_TaintedEdithJump"
local tedithHopTag = "edithRebuilt_TaintedEdithHop"
local edithHoodJumpTag = "edithRebuilt_EdithsHoodJump"
local enemyJumpTag = "edithRebuilt_EnemyJump"
local effigyHop = "edithRebuilt_EffigyHop"
local effigyJump = "edithRebuilt_EffigyJump"
local soulOfEdithJump = "edithRebuilt_SoulOfEdith"

local mortisBackdrops = {
	MORGUE = 1,
	MOIST = 2,
	FLESH = 3,
}

local jumpFlags = JumpLib.Flags

EdithRebuilt.Enums = {
	PlayerType = {
		PLAYER_EDITH = EdithPlayer,
		PLAYER_EDITH_B = EdithBPlayer,
	},
	CollectibleType = {
		-- Edith Items
		COLLECTIBLE_SALTSHAKER = Isaac.GetItemIdByName(Isaac.GetString("Items", "#SALT_SHAKER_NAME")),
		COLLECTIBLE_PEPPERGRINDER = Isaac.GetItemIdByName(Isaac.GetString("Items", "#PEPPER_GRINDER_NAME")),
		COLLECTIBLE_EDITHS_HOOD = Isaac.GetItemIdByName(Isaac.GetString("Items", "#EDITHS_HOOD_NAME")),
		COLLECTIBLE_SULFURIC_FIRE = Isaac.GetItemIdByName(Isaac.GetString("Items", "#SULFURIC_FIRE_NAME")),
		COLLECTIBLE_SAL = Isaac.GetItemIdByName(Isaac.GetString("Items", "#SAL_NAME")),
		COLLECTIBLE_MOLTEN_CORE = Isaac.GetItemIdByName(Isaac.GetString("Items", "#MOLTEN_CORE_NAME")),
		COLLECTIBLE_GILDED_STONE = Isaac.GetItemIdByName(Isaac.GetString("Items", "#GILDED_STONE_NAME")),
		COLLECTIBLE_FATE_OF_THE_UNFAITHFUL = Isaac.GetItemIdByName(Isaac.GetString("Items", "#FATE_OF_THE_UNFAITHFUL_NAME")),
		COLLECTIBLE_SALT_HEART = Isaac.GetItemIdByName(Isaac.GetString("Items", "#SALT_HEART_NAME")),
		COLLECTIBLE_DIVINE_RETRIBUTION = Isaac.GetItemIdByName(Isaac.GetString("Items", "#DIVINE_RETRIBUTION_NAME")),
		COLLECTIBLE_HYDRARGYRUM = Isaac.GetItemIdByName(Isaac.GetString("Items", "#HYDRARGYRUM_NAME")),
		COLLECTIBLE_SPICES_MIX = Isaac.GetItemIdByName(Isaac.GetString("Items", "#SPICES_MIX_NAME")),

		--- Tainted Edith Items
		COLLECTIBLE_BURNT_HOOD = Isaac.GetItemIdByName(Isaac.GetString("Items", "#BURNT_HOOD_NAME")),
		COLLECTIBLE_DIVINE_WRATH = Isaac.GetItemIdByName(Isaac.GetString("Items", "#DIVINE_WRATH_NAME")),

		COLLECTIBLE_EFFIGY = Isaac.GetItemIdByName(Isaac.GetString("Items", "#EFFIGY_NAME")),
		COLLECTIBLE_CHUNK_OF_BASALT = Isaac.GetItemIdByName(Isaac.GetString("Items", "#CHUNK_OF_BASALT_NAME")),
	},
	TrinketType = {
		TRINKET_GEODE = Isaac.GetTrinketIdByName(Isaac.GetString("Items", "#GEODE_NAME")),
		TRINKET_RUMBLING_PEBBLE = Isaac.GetTrinketIdByName(Isaac.GetString("Items", "#RUMBLING_PEBBLE_NAME")),
		TRINKET_PAPRIKA = Isaac.GetTrinketIdByName(Isaac.GetString("Items", "#PAPRIKA_NAME")),
		TRINKET_BURNT_SALT = Isaac.GetTrinketIdByName(Isaac.GetString("Items", "#BURNT_SALT_NAME")),
	},
	Card = {
		CARD_JACK_OF_CLUBS = Isaac.GetCardIdByName("Jack_of_Clubs"),
		CARD_SALT_ROCKS = Isaac.GetCardIdByName("SaltRocks"),
		CARD_SOUL_EDITH = Isaac.GetCardIdByName("SoulOfEdith"),
	},
	NullItemID = {
		EDITH = Isaac.GetNullItemIdByName("Edith_Rebuilt_Edith"),
		T_EDITH = Isaac.GetNullItemIdByName("Edith_Rebuilt_TEdith"),
		EFFIGY = Isaac.GetNullItemIdByName("Edith_Rebuilt_Effigy"),
	},
	EffectVariant = {
		EFFECT_EDITH_TARGET = Isaac.GetEntityVariantByName("Edith Target"),
		EFFECT_EDITH_B_TARGET = Isaac.GetEntityVariantByName("Edith Tainted Arrow"),
	},
	Challenge = {
		CHALLENGE_VESTIGE = Isaac.GetChallengeIdByName("[Edith: Rebuilt] Vestige"),
		CHALLENGE_GRUDGE = Isaac.GetChallengeIdByName("[Edith: Rebuilt] Grudge")
	},
	Callbacks = {
		-- Called everytime a Perfect Parry is triggered
		---* player `EntityPlayer`
		---* entity `Entity`
		---* params `TEdithHopParryParams`
		PERFECT_PARRY = "EdithRebuilt_PERFECT_PARRY",
		-- Called everytime an enemy is killed by a Perfect Parry is triggered
		---* player `EntityPlayer`
		---* entity `Entity`
		PERFECT_PARRY_KILL = "EdithRebuilt_PERFECT_PARRY_KILL",
		-- Called every time a parry land is triggered (there's no need to hit the parry)
		---* player `EntityPlayer`
		POST_PARRY_LAND = "EdithRebuilt_POST_PARRY_LAND",
		-- Called everytime Edith does an offensive stomp
		---* player `EntityPlayer`
		---* params `EdithJumpStompParams`
		OFFENSIVE_STOMP = "EdithRebuilt_OFFENSIVE_STOMP",
		-- Called everytime Edith does an offensive stomp and damages at least `One` Enemy
		---* player `EntityPlayer`
		---* entity `Entity`
		---* params `EdithJumpStompParams`
		OFFENSIVE_STOMP_HIT = "EdithRebuilt_OFFENSIVE_STOMP_HIT",
		-- Called everytime Edith does an offensive stomp and kills at least `One` Enemy
		---* player `EntityPlayer`
		---* entity `Entity`
		---* params `EdithJumpStompParams`
		OFFENSIVE_STOMP_KILL = "EdithRebuilt_OFFENSIVE_STOMP_KILL",
		-- Called everytime Edith's Target (or Tainted Edith's arrow) changes its design
		TARGET_SPRITE_CHANGE = "EdithRebuilt_TARGET_SPRITE_CHANGE",
		-- Called everytime Tainted Edith's trail sprite is changed
		TRAIL_SPRITE_CHANGE = "EdithRebuilt_TRAIL_SPRITE_CHANGE",
	},
	SubTypes = {
		SALT_CREEP = Isaac.GetEntitySubTypeByName("Salt Creep"),
		PEPPER_CREEP = Isaac.GetEntitySubTypeByName("Pepper Creep"),
		CINDER_CREEP = Isaac.GetEntitySubTypeByName("Cinder Creep"),
		OREGANO_CREEP = Isaac.GetEntitySubTypeByName("Oregano Creep"),
	},
	SoundEffect = {
		SOUND_EDITH_STOMP = Isaac.GetSoundIdByName("Edith Stomp"),
		SOUND_EDITH_STOMP_WATER = Isaac.GetSoundIdByName("Edith Stomp Water"),
		SOUND_WATERSPLASH = Isaac.GetSoundIdByName("Water Splash"),
		SOUND_PIZZA_TAUNT = Isaac.GetSoundIdByName("Taunt"),
		SOUND_FART_REVERB = Isaac.GetSoundIdByName("Fart Reverb"),
		SOUND_VINE_BOOM = Isaac.GetSoundIdByName("Vine Boom"),
		SOUND_SALT_SHAKER = Isaac.GetSoundIdByName("Salt Shaker"),
		SOUND_PEPPER_GRINDER = Isaac.GetSoundIdByName("Pepper Grinder"),
		SOUND_YIPPEE = Isaac.GetSoundIdByName("Yippee"),
		SOUND_SPRING = Isaac.GetSoundIdByName("Spring"),
		SOUND_SOLARIAN = Isaac.GetSoundIdByName("Solarian"),
		SOUND_MACHINE = Isaac.GetSoundIdByName("Machine"),
		SOUND_MECHANIC = Isaac.GetSoundIdByName("Mechanic"),
		SOUND_KNIGHT = Isaac.GetSoundIdByName("Knight"),
		SOUND_JACK_OF_CLUBS = Isaac.GetSoundIdByName("JackOfClubs"),
		SOUND_SOUL_OF_EDITH = Isaac.GetSoundIdByName("SoulOfEdith"),
		SOUND_BLOQUEO = Isaac.GetSoundIdByName("BLOQUEO"),
		SOUND_NAUTRASH = Isaac.GetSoundIdByName("Nautrash"),
		SOUND_HAWK_TUAH = Isaac.GetSoundIdByName("HawkTuah"),
		SOUND_CINNAMON_COUGH = Isaac.GetSoundIdByName("CinnamonCough"),
		SOUND_PEPPER_SNEEZE = Isaac.GetSoundIdByName("PepperSneeze"),
	},
	Achievements = {
		-- Edith unlocks
		ACHIEVEMENT_EDITH = Isaac.GetAchievementIdByName("Edith"),
		ACHIEVEMENT_SALT_SHAKER = Isaac.GetAchievementIdByName("Salt Shaker"),
		ACHIEVEMENT_PEPPER_GRINDER = Isaac.GetAchievementIdByName("Pepper Grinder"),
		ACHIEVEMENT_SAL = Isaac.GetAchievementIdByName("Sal"),
		ACHIEVEMENT_SALT_HEART = Isaac.GetAchievementIdByName("alt Heart"),
		ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL = Isaac.GetAchievementIdByName("Faith Of The Unfaithful"),
		ACHIEVEMENT_MOLTEN_CORE = Isaac.GetAchievementIdByName("Molten Core"),
		ACHIEVEMENT_GILDED_STONE = Isaac.GetAchievementIdByName("Gilded Stone"),
		ACHIEVEMENT_GEODE = Isaac.GetAchievementIdByName("Geode"),
		ACHIEVEMENT_SULFURIC_FIRE = Isaac.GetAchievementIdByName("Sulfuric Fire"),
		ACHIEVEMENT_RUMBLING_PEBBLE = Isaac.GetAchievementIdByName("Rumbling Pebble"),
		ACHIEVEMENT_DIVINE_RETRIBUTION = Isaac.GetAchievementIdByName("Divine Retribution"),
		ACHIEVEMENT_SPICES_MIX = Isaac.GetAchievementIdByName("SpicesMix"),
		ACHIEVEMENT_EDITHS_HOOD = Isaac.GetAchievementIdByName("Ediths Hood"),
		ACHIEVEMENT_HYDRARGYRUM = Isaac.GetAchievementIdByName("Hydrargyrum"),
		ACHIEVEMENT_TAINTED_EDITH = Isaac.GetAchievementIdByName("The Scorched"),
		-- Edith unlocks end

		-- Tainted Edith unlocks
		ACHIEVEMENT_SALT_ROCKS = Isaac.GetAchievementIdByName("Salt Rocks"),
		ACHIEVEMENT_BURNT_SALT = Isaac.GetAchievementIdByName("Burnt Salt"),
		ACHIEVEMENT_JACK_OF_CLUBS = Isaac.GetAchievementIdByName("Jack of Clubs"),
		ACHIEVEMENT_PAPRIKA = Isaac.GetAchievementIdByName("Paprika"),
		ACHIEVEMENT_BURNT_HOOD = Isaac.GetAchievementIdByName("Burnt Hood"),
		ACHIEVEMENT_SOUL_OF_EDITH = Isaac.GetAchievementIdByName("Soul of Edith"),
		ACHIEVEMENT_DIVINE_WRATH = Isaac.GetAchievementIdByName("Divine Wrath"),
		-- Tainted Edith unlocks end

		ACHIEVEMENT_VESTIGE = Isaac.GetAchievementIdByName("Vestige"),
		ACHIEVEMENT_EFFIGY = Isaac.GetAchievementIdByName("Effigy"),
		ACHIEVEMENT_GRUDGE = Isaac.GetAchievementIdByName("Grudge"),
		ACHIEVEMENT_CHUNK_OF_BASALT = Isaac.GetAchievementIdByName("Chunk of Basalt"),

		ACHIEVEMENT_THANK_YOU = Isaac.GetAchievementIdByName("Thank You"),
	},
	Giantbook = {
		PERFECT_PARRY = Isaac.GetGiantBookIdByName("ParryEffect")
	},
	Utils = {
		Game = game,
		SFX = SFXManager(),
		RNG = RNG(),
		Level = game:GetLevel(),
		PGD = Isaac.GetPersistentGameData(),
		ItemPool = game:GetItemPool(),
	},
	---@enum SaltTypes
	SaltTypes = {
		SALT_SHAKER = 1 << 0,
		SALT_SHAKER_JUDAS = 1 << 1,
		SAL = 1 << 2,
		SALT_HEART = 1 << 3,
		EDITHS_HOOD = 1 << 4,
		SALT_ROCKS = 1 << 5,
	},
	---@enum ParryTypes
	ParryTypes = {
		FAILED = 0,
		IMPRECISE = 1,
		PERFECT = 2
	},
	---@enum ConfigDataTypes
	ConfigDataTypes = {
		EDITH = "EdithData",
		TEDITH = "TEdithData",
		MISC = "MiscData",
	},
	---@enum EdithStatusEffects
	EdithStatusEffects = {
		SALTED = "Salt",
		GARLIC = "Garlic",
		OREGANO = "Oregano",
		CUMIN = "Cumin",
		TURMERIC = "Turmeric",
		CINNAMON = "Cinnamon",
		GINGER = "Ginger",
		PEPPERED = "Pepper",
		CINDER = "Cinder",
		HYDRARGYRUM_CURSE = "HydrargyrumCurse"
	},
		Tables = {
		OverrideActions = {
			[ButtonAction.ACTION_LEFT] = 0,
			[ButtonAction.ACTION_RIGHT] = 0,
			[ButtonAction.ACTION_UP] = 0,
			[ButtonAction.ACTION_DOWN] = 0,
		},
		OverrideWeapons = {
			[WeaponType.WEAPON_BRIMSTONE] = true,
			[WeaponType.WEAPON_KNIFE] = true,
			[WeaponType.WEAPON_LASER] = true,
			[WeaponType.WEAPON_BOMBS] = true,
			[WeaponType.WEAPON_ROCKETS] = true,
			[WeaponType.WEAPON_TECH_X] = true,
			[WeaponType.WEAPON_SPIRIT_SWORD] = true,
			[WeaponType.WEAPON_LUDOVICO_TECHNIQUE] = true,
		},
		ArrowSuffix = {
			[1] = "_arrow",
			[2] = "_grudge",
		},
		TargetVisualParams = {
			[1]  = { Suffix = "", LineColor = nil },
			[2]  = { Suffix = "_trans", LineColor = {R = 245/255, G = 169/255, B = 184/255} },
			[3]  = { Suffix = "_rainbow", LineColor = {R = 1, G = 0, B = 1 } },
			[4]  = { Suffix = "_lesbian", LineColor = {R = 1, G = 154/255, B = 86/255 } },
			[5]  = { Suffix = "_bisexual", LineColor = {R = 155/255, G = 79/255,  B = 150/255} },
			[6]  = { Suffix = "_gay", LineColor = {R = 123/255, G = 173/255, B = 226/255} },
			[7]  = { Suffix = "_ace", LineColor = {R = 128/255, G = 0, B = 128/255} },
			[8]  = { Suffix = "_enby", LineColor = {R = 154/255, G = 89/255,  B = 207/255} },
			[9]  = { Suffix = "_Venezuela", LineColor = {R = 0, G = 36/255, B = 125/255} },
			[10] = { Suffix = "_Chile", LineColor = {R = 213/255, G = 43/255,  B = 30/255 } },
			[11] = { Suffix = "_Mexico", LineColor = {R = 0, G = 104/255, B = 71/255 } },
		},
		FrameLimits = {
			["Idle"] = 12,
			["Blink"] = 2
		},
		BloodytearVariants = {
			[TearVariant.BLOOD] = true,
			[TearVariant.GLAUCOMA_BLOOD] = true,
			[TearVariant.CUPID_BLOOD] = true,
			[TearVariant.PUPULA_BLOOD] = true,
			[TearVariant.GODS_FLESH_BLOOD] = true,
			[TearVariant.NAIL_BLOOD] = true,
			[TearVariant.EYE_BLOOD] = true
		},
		BackdropColors = {
			[BackdropType.CORPSE3] = Color(0.75, 0.2, 0.2),
			[BackdropType.DROSS] = Color(92/255, 81/255, 71/255),
			[BackdropType.BLUE_WOMB] = Color(0, 0, 0, 1, 0.3, 0.4, 0.6),
			[BackdropType.CORPSE] = Color(0, 0, 0, 1, 0.62, 0.65, 0.62),
			[BackdropType.CORPSE2] = Color(0, 0, 0, 1, 0.55, 0.57, 0.55),
		},
		JumpTags = {
			EdithJump = edithJumpTag,
			TEdithHop = tedithHopTag,
			TEdithJump = tedithJumpTag,
			EdithsHoodJump = edithHoodJumpTag,
			SoulOfEdith = soulOfEdithJump,
			EnemyJump = enemyJumpTag,
			EffigyHop = effigyHop,
			EffigyJump = effigyJump,
		},
		JumpFlags = {
			EdithJump = (
				jumpFlags.DISABLE_SHOOTING_INPUT |
				jumpFlags.DISABLE_LASER_FOLLOW |
				jumpFlags.DISABLE_BOMB_INPUT |
				jumpFlags.FAMILIAR_FOLLOW_FOLLOWERS |
				jumpFlags.FAMILIAR_FOLLOW_ORBITALS |
				jumpFlags.FAMILIAR_FOLLOW_TEARCOPYING |
				jumpFlags.NO_HURT_PITFALL |
				jumpFlags.GRIDCOLL_NO_WALLS
			),
			TEdithHop = (
				jumpFlags.COLLISION_GRID |
				jumpFlags.COLLISION_ENTITY |
				jumpFlags.OVERWRITABLE |
				jumpFlags.DISABLE_COOL_BOMBS |
				jumpFlags.IGNORE_CONFIG_OVERRIDE |
				jumpFlags.FAMILIAR_FOLLOW_ORBITALS |
				jumpFlags.DAMAGE_CUSTOM
			),
			TEdithJump = (
				jumpFlags.COLLISION_GRID |
				jumpFlags.OVERWRITABLE |
				jumpFlags.DISABLE_COOL_BOMBS |
				jumpFlags.IGNORE_CONFIG_OVERRIDE |
				jumpFlags.FAMILIAR_FOLLOW_ORBITALS |
				jumpFlags.DISABLE_BOMB_INPUT |
				jumpFlags.DISABLE_TEARHEIGHT
			),
		},
		MovementBasedActives = {
			[CollectibleType.COLLECTIBLE_SUPLEX] = true,
			[CollectibleType.COLLECTIBLE_PONY] = true,
			[CollectibleType.COLLECTIBLE_WHITE_PONY] = true,
		},
		JumpParams = {
			EdithJump = {
				tag = edithJumpTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithPlayer,
			},
			TEdithJump = {
				tag = tedithJumpTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithBPlayer,
			},
			TEdithHop = {
				tag = tedithHopTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithBPlayer,
			},
			EdithsHoodJump = {
				tag = edithHoodJumpTag,
				type = EntityType.ENTITY_PLAYER,
			}
		},
		GridEntTypes = {
			[GridEntityType.GRID_TRAPDOOR] = true,
			[GridEntityType.GRID_STAIRS] = true,
			[GridEntityType.GRID_GRAVITY] = true,
		},
		Chap4Backdrops = {
			[BackdropType.WOMB] = true,
			[BackdropType.UTERO] = true,
			[BackdropType.SCARRED_WOMB] = true,
			[BackdropType.BLUE_WOMB] = true,
			[BackdropType.CORPSE] = true,
			[BackdropType.CORPSE2] = true,
			[BackdropType.CORPSE3] = true,
			[BackdropType.MORTIS] = true, --- Who knows
		},
		ImGuiTables = {
			TargetDesign = {
				"Choose Color",
				"Trans",
				"Rainbow",
				"Lesbian",
				"Bisexual",
				"Gay",
				"Ace",
				"Enby",
				"Venezuela",
				"Chile",
				"Mexico",
			},
			StompSound = {
				"Stone",
				"Antibirth",
				"Fart Reverb",
				"Vine Boom"
			},
			ArrowDesign = {
				"Arrow",
				"Grudge",
			},
			TrailDesign = {
				"Choose color",
				"Trans",
				"Rainbow",
				"Lesbian",
				"Bisexual",
				"Gay",
				"Ace",
				"Enby",
				"Pansexual",
				"Straight",
				"Commander Video",
				"Italy",
			},
			HopSound = {
				"Stone",
				"Yippee",
				"Spring",
			},
			ParrySound = {
				"Stone",
				"Taunt",
				"Vine Boom",
				"Fart Reverb",
				"Solarian",
				"Machine",
				"Mechanic",
				"Knight",
				"Bloqueo",
				"Nautrash",
				"Hawk",
			},
		},
		PhysicsFamiliar = {
			[FamiliarVariant.SAMSONS_CHAINS] = true,
			[FamiliarVariant.PUNCHING_BAG] = true,
			[FamiliarVariant.CUBE_BABY] = true,
		} --[[@as FamiliarVariant[]],
		CooldownSounds = {
			[1] = {
				SoundID = SoundEffect.SOUND_STONE_IMPACT,
				Pitch = 1.2,
			},
			[2] = {
				SoundID = SoundEffect.SOUND_BEEP,
				Pitch = 0.8
			}
		},
		RemoveTargetItems = {
			[CollectibleType.COLLECTIBLE_ESAU_JR] = true,
			[CollectibleType.COLLECTIBLE_CLICKER] = true,
		},
		DisableLandFeedbackGrids = {
			[GridEntityType.GRID_TRAPDOOR] = true,
			[GridEntityType.GRID_STAIRS] = true,
			[GridEntityType.GRID_GRAVITY] = true,
		},
		TEdithTrailParams = {
			[1] = { Suffix = "", Size = 2 },
			[2] = { Suffix = "_trans", Size = 2 },
			[3] = { Suffix = "_rainbow", Size = 2 },
			[4] = { Suffix = "_lesbian", Size = 2 },
			[5] = { Suffix = "_bi", Size = 1 },
			[6] = { Suffix = "_gay", Size = 1 },
			[7] = { Suffix = "_ace", Size = 1 },
			[8] = { Suffix = "_enby", Size = 1 },
			[9] = { Suffix = "_pan", Size = 1 },
			[10] = { Suffix = "_straight", Size = 1 },
			[11] = { Suffix = "_CommanderVideo", Size = 1 },
			[12] = { Suffix = "_italy", Size = 1 },
		},
		MortisBackdrop = {
			MORGUE = mortisBackdrops.MORGUE,
			MOIST = mortisBackdrops.MOIST,
			FLESH = mortisBackdrops.FLESH,
		},
		MortisBackdropColor = {
			[mortisBackdrops.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
			[mortisBackdrops.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
			[mortisBackdrops.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
		},
		TriggerDamageSlots = {
			[SlotVariant.BLOOD_DONATION_MACHINE] = true,
			[SlotVariant.DEVIL_BEGGAR] = true,
			[SlotVariant.CONFESSIONAL] = true,
		},
	},
	Misc = {
		TearPath = "gfx/tears/",
		HeadAdjustVec = Vector.Zero,
		TargetPath = "gfx/effects/EdithTarget/effect_000_edith_target",
		ArrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith",
		TrailPath = "gfx/effects/TaintedEdithTrail/trail",
		VestigeSpritePath = "gfx/characters/costumes/characterEdithVestige.png",
		GrudgeSpritePath = "gfx/characters/costumes/characterTaintedEdithGrudge.png",
		VestigeHoodPath = "gfx/characters/costumes/characterEdithVestigeHood.png",
		GrudgeHoodPath = "gfx/characters/costumes/characterTaintedEdithGrudgeHood.png",
		EdithHoodPath = "gfx/characters/costumes/characterEdithHood.png",
		TEdithHoodPath = "gfx/characters/costumes/characterTaintedEdithHood.png",
		TargetLineColor = Color(1, 1, 1),
		SaltShakerDist = Vector(0, 60),
		ColorDefault = Color(1, 1, 1, 1),
		JumpReadyColor = Color(1, 1, 1, 1, 0.5, 0.5, 0.5),
		PerfectParryRadius = 32,
		ImpreciseParryRadius = 45,
		BaseHopChargeAdder = 9,
		TearParryRadius = 35,
		BurntSaltColor = Color(0.3, 0.3, 0.3),
		ChargeBarleftVector = Vector(-8, 10),
		ChargeBarcenterVector = Vector(0, 10),
		ChargeBarrightVector = Vector(8, 10),
		PaprikaColor = Color(0.8, 0.2, 0),
		ParryPartitions = EntityPartition.ENEMY | EntityPartition.BULLET | EntityPartition.TEAR, --[[@as EntityPartition|integer]]
	},
}