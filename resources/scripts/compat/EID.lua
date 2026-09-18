if not EID then return end

local enums = EdithRebuilt.Enums
local Collectibles = enums.CollectibleType
local Trinkets = enums.TrinketType
local Cards = enums.Card
local PlayerType = enums.PlayerType

---@param ID CollectibleType
---@return string
local function IDToMarkup(ID)
    return "{{Collectible" .. tostring(ID) .. "}} "
end

local ShakerIcon = IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER)

local IconsSprite = Sprite("gfx/ui/EID/EIDIcons.anm2", true)
EID:setModIndicatorName("Edith: Rebuilt")
EID:addIcon("Edith Rebuilt Icon", "ModIcon", 0, 32, 32, 0, -1, IconsSprite)
EID:setModIndicatorIcon("Edith Rebuilt Icon")

EID:addIcon("Player"..PlayerType.PLAYER_EDITH, "Player", 0, 15, 12, 2, 1, IconsSprite)
EID:addIcon("Player"..PlayerType.PLAYER_EDITH_B, "Player", 1, 15, 12, 2, 1, IconsSprite)

table.insert(EID.TextReplacementPairs, {"ERSalt",
    ShakerIcon ..
    "Any enemy that walks or pass over the salt will get salted #" ..
    ShakerIcon ..
    "Salted enemies will move slower and receive x1.2 times more damage"
})

EID:addBirthright(PlayerType.PLAYER_EDITH, [[Offensive Stomp's damage is increased
Stomp synergies are powered]], "Edith")
EID:addBirthright(PlayerType.PLAYER_EDITH_B, [[Hopdash charge can be overcharged to 200%
Overcharged hopdash can apply burn status effect
Cinder created by perfect parrying enemies will spawn fire jets below them
Parried projectiles and tears will have fire effects
]], "Tainted Edith")

EID:addCharacterInfo(PlayerType.PLAYER_EDITH, [[Unable to walk, spawns a target instead
Pressing {{ButtonRT}} will make her jump to the target
A Single Press will trigger an offensive stomp (trigger synergies)
Keeping pressed until she turns grey, it will be a defensive stomp (makes Edith invulnerable and applies salted status effect)
ERSalt
]], "Edith")
EID:addCharacterInfo(PlayerType.PLAYER_EDITH_B, [[Unable to walk, spawns an arrow instead
Trying to walk will charge a chargebar, the more charge the faster she'll move in the arrow's direction
Pressing {{ButtonRT}} will make her jump in place, performing a parry, its effect depends on enemy's distance
A Perfect Parry damage the enemy, increases the dash charge and gives 20 i-frames
]], "Tainted Edith")

EID:addBirthright(PlayerType.PLAYER_EDITH, "Edith's Stomps will have increased damage# Stomp synergies will be powered")
EID:addBirthright(PlayerType.PLAYER_EDITH_B, [[
Hopdash charge can be overcharged to 200%
Overcharged hopdash can apply burn status effect
Cinder created by perfect parrying enemies will spawn fire jets below them
Parried projectiles and tears will have fire effects
]])

local SpicesColors = {
    ["ColorSalted"] = KColor(1, 1, 1, 1),
    ["ColorPepper"] = KColor(0.5, 0.5, 0.5, 1),
    ["ColorGarlic"] = KColor(1, 238/255, 188/255, 1),
    ["ColorOregano"] = KColor(113/255, 120/255, 82/255, 1),
    ["ColorCumin"] = KColor(115/255, 84/255, 67/355, 1),
    ["ColorTurmeric"] = KColor(250/255, 198/255, 49/255, 1),
    ["ColorCinnamon"] = KColor(210/255, 105/255, 30/255, 1),
    ["ColorGinger"] = KColor(239/255, 159/255, 89/255, 1),
}

for markup, color in pairs(SpicesColors) do
    EID:addColor(markup, color)
end

local Descs = {
    Items = {
        [Collectibles.COLLECTIBLE_SALTSHAKER] = {
            ["en_us"] = {
                Name = "",
                Desc =
                [[Creates a circle of salt around the player 
ERSalt
Killing a salted enemy will spawn salt creep below it]]
            },
        },
        [Collectibles.COLLECTIBLE_PEPPERGRINDER] = {
            ["en_us"] = {
                Name = "",
                Desc = [[Nearby enemies will get Peppered
Peppered enemies will spawn pepper creep every 2nd hit
Pepper creep deals 4 damage per tick and lasts 8 seconds]]
            }
        },
        [Collectibles.COLLECTIBLE_EDITHS_HOOD] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[{{ArrowUp}} {{Damage}} x1.35 Damage
Player now will shoot salt tears
Pressing the Drop button will make Isaac jump
The jump has a 3 seconds cooldown
Isaac will spawn a small circle of salt when landing
ERSalt
Killing a salted enemy will spawn tears in random directions]]
            }
        },
        [Collectibles.COLLECTIBLE_SULFURIC_FIRE] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[On use, nearby enemies will: 
{{Damage}} Get damaged (Formula: Isaac's Damage + 17.5% of Enemy's Max HP)
{{BrimstoneCurse}} Get Brimstone curse effect
If an enemy dies, it will spawn a brimstone ball]],
            }
        },
        [Collectibles.COLLECTIBLE_GILDED_STONE] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[{{Coin}} +5 Coins
{{Collectible592}} Chance of shoot rock tears (Depends on your {{Coin}} amount of coins)
Chance of receiving a prize by destroying a rock (Depends on your {{Luck}} luck and {{Coin}} amount of coins), the possible prizes are:
{{Coin}} Penny (75%)
{{Nickel}} Nickel (15%)
{{Dime}} Dime (5%)
{{Collectible74}} One Quarter (4%)
{{Collectible18}} One Dollar(1%)]]
            }
        },
        [Collectibles.COLLECTIBLE_HYDRARGYRUM] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[Damaging an enemy will make it to shoot Mercury tears in random directions every 15 frames for 4 seconds
Mercury tears will leave creep when they land or hit an enemy
Mercury creep deals fire damage]]
            }
        },
        [Collectibles.COLLECTIBLE_SAL] = {
            ["en_us"] = {
                Name = "", 
                Desc = IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. 
                [[Player will spawn salt on their position every 15 frames
ERSalt
Killing a salted enemy will make it shoot 4-6 tears in random directions]]
            }
        },
        [Collectibles.COLLECTIBLE_SALT_HEART] = {
            ["en_us"] = {
                Name = "",
                Desc = [[{{ArrowUp}} {{Damage}} x1.5 Damage#
When taking Damage: 
{{Heart}} All taken damage will be doubled 
Player will shoot 4-6 salt tears in random directions#]] .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. [[
Player will spawn salt in their position every 3 frames for 5 seconds
ERSalt
{{Heart}} Killing an enemy has a chance to spawn a random heart]]
            }
        },
        [Collectibles.COLLECTIBLE_MOLTEN_CORE] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[{{ArrowUp}} {{Damage}} +0.5 Damage
Nearby enemies will start to burn
If an enemy dies while being close to Isaac, a Fire jet will spawn in its position]],
            }
        },
        [Collectibles.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[On use:
{{ArrowUp}} {{Damage}} Damage +1.75
{{Burning}} Enemies will get burn
Deals Damage to enemies depending on their distance to Isaac
The closer, the bigger will be the damage
Nearby enemies will get pushed]],
            }
        },
        [Collectibles.COLLECTIBLE_DIVINE_RETRIBUTION] = {
            ["en_us"] = {
                Name = "", 
                Desc = [[On use:
{{ArrowUp}} 50% of dealing damage to all enemies in room and get a {{SoulHeart}} soul heart
{{ArrowDown}} 50% chance of Isaac getting damage]],
            }
        },
        [Collectibles.COLLECTIBLE_SPICES_MIX] = {
            ["en_us"] = {
                Name = "", 
                Desc =[[Pressing the Drop button ({{ButtonRT}}) will change bewteen 8 possible spices effects: {{ColorSalted}}Salt, {{ColorPepper}}Pepper, {{ColorTurmeric}}Turmeric, {{ColorCinnamon}}Cinnamon, {{ColorCumin}}Cumin, {{ColorGarlic}}Garlic, {{ColorGinger}}Ginger {{ColorWhite}}and {{ColorOregano}}Oregano
On use: 
Enemies close to Isaac will get the effect from the chosen spice]]
            }
        },
        [Collectibles.COLLECTIBLE_BURNT_HOOD] = { 
            ["en_us"] = {
                Name = "",
                Desc = [[On use:
Isaac will do a short jump in place
Landing in an enemy will trigger a parry, damaging the enemy
Perfectly performing a parry will recharge the item]],
            }
        },
        [Collectibles.COLLECTIBLE_DIVINE_WRATH] = { 
            ["en_us"] = {
                Name = "",
                Desc = [[On use:
Spawn 2 rock rings around Isaac
Shoot 8-12 arched fire rock tears in random directions]],
            }
        },
        [Collectibles.COLLECTIBLE_EFFIGY] = { 
            ["en_us"] = {
                Name = "",
                Desc = [[On use:
Isaac will change between Normal and Statue state
While being a statue, Isaac can't shoot and will have 2 types of jumps:
Small jump (Triggered when trying to move): consumes 1 charge on land, has a 20-frame cooldown.
Big jump (Triggered when pressing an Edith's jump button); consumes 5 charges on land, has a 4-second cooldown]]
            },
        },
        [Collectibles.COLLECTIBLE_CHUNK_OF_BASALT] = { 
            ["en_us"] = {
                Name = "",
                Desc = [[Press the Drop button ({{ButtonRT}}) while moving to perform a Dash
If Isaac collides with an enemy while dashing: 
{{Damage}} The enemy will be damaged
The enemy will be pushed
If the enemy is killed by the dash, it will shoot 5-8 basalt tears in random directions]],
            }
        },
    },
    Trinkets = {
        [Trinkets.TRINKET_RUMBLING_PEBBLE] = {
            ["en_us"] = {
                Name = "",
                Desc = [[{{Collectible592}} 50% chance of shooting a rock tear
On destroying a rock, this will shoot rock tears in random directions, these will always destroy rocks]],
            }
        },
        [Trinkets.TRINKET_GEODE] = {
            ["en_us"] = {
                Name = "",
                Desc = "{{Rune}} 2.5% chance to spawn a rune when killing an enemy#{{Rune}} 25% of destroy the geode and spawn 3 runes on taking damage"
            }
        },
        [Trinkets.TRINKET_PAPRIKA] = {
            ["en_us"] = {
                Name = "",
                Desc = "Enemies have a 50% of explode on death#{{Burning}} Nearby enemies will get burn, will be pushed and took 25% of explotion's damage"
            }
        },
        [Trinkets.TRINKET_BURNT_SALT] = {
            ["en_us"] = {
                Name = "",
                Desc = [[Every third shot tear will be a burnt salt tear, which will deal x1.5 Isaac's tear damage.
Dealing damage to an enemy with the burnt salt tear will apply the Cinder status effect.
Killing an enemy with Cinder will spawn a circle of Cinder creep around it]], 
            }
        },
    },
    Cards = {
        [Cards.CARD_SALT_ROCKS] = {
            ["en_us"] = {
                Name = "Salt rocks",
                Desc = [[On use, all enemies in room will get salted:
ERSalt
Killing a salted enemy will make it shoot arched tears in random directions and leave salt creep when falling]],
            }
        },
        [Cards.CARD_JACK_OF_CLUBS] = {
            ["en_us"] = {
                Name = "Jack of clubs",
                Desc = [[On use: 
enemies have a 60% chance of explode
{{Bomb}} If the enemy dies, there's a 50% chance of it dropping a bomb]],
            }
        },
        [Cards.CARD_SOUL_EDITH] = {
            ["en_us"] = {
                Name = "Soul of Edith",
                Desc = [[On use Isaac will jump, on landing: 
{{Damage}} Near enemies will be pushed and will receive damage
{{Collectible592}} Rock tears will fall from the ceiling in random positions]],
            }
        },
    }
}

local targetFunc = {
    ["Items"] = EID.addCollectible,
    ["Trinkets"] = EID.addTrinket,
    ["Cards"] = EID.addCard,
}

for kind, Desc in pairs(Descs) do
    for id, lang in pairs(Desc) do
        for lang, info in pairs(lang) do
            targetFunc[kind](EID, id, info.Desc, info.Name, lang)
        end
    end
end

local BookOfVirtuesSynergies = {
    [Collectibles.COLLECTIBLE_SALTSHAKER] = {
        ["en_us"] = "Wisps shot tears have a chance to apply Salted: spawns salt creep on hit or death, and disappears on room change"
    },
    [Collectibles.COLLECTIBLE_PEPPERGRINDER] = {
        ["en_us"] = "On being killed, the wisp will spawn a pepper cloud that applies Peppered status effect"
    },
    [Collectibles.COLLECTIBLE_SULFURIC_FIRE] = {
        ["en_us"] = "Up to 8 one-room wisps; triggers a low-radius Sulfuric fire effect without the fading damage"
    },
    [Collectibles.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL] = {
        ["en_us"] = "Wisps shot fire tears"
    },
    [Collectibles.COLLECTIBLE_DIVINE_RETRIBUTION] = {
        ["en_us"] = "Up to 8 one-room wisps with homing tears; 25% chance of Holy Light effect"
    },
    [Collectibles.COLLECTIBLE_SPICES_MIX] = {
        ["en_us"] = "Wisp color depends on the selected spice effect and applies that effect in a small radius"
    },
    [Collectibles.COLLECTIBLE_DIVINE_RETRIBUTION] = {
        ["en_us"] = "Fires rock tears with a 25% chance of burning rock tears; damage has a x0.75-1.5 multiplier"
    },
    [Collectibles.COLLECTIBLE_BURNT_HOOD] = {
        ["en_us"] = "Spawns a high-HP wisp on use: dies on a failed parry, keeps half HP on an imprecise parry, and full HP on a perfect parry"
    },
    [Collectibles.COLLECTIBLE_EFFIGY] = {
        ["en_us"] = "Spawns a ring of 6 high-HP wisps: lose HP on small jumps, destroyed on a big jump (shooting a tear burst on landing) or when returning to Normal state"
    },
}

local JudasBirthrightSynergies = {
    [Collectibles.COLLECTIBLE_SALTSHAKER] = {
        ["en_us"] = "The salt creep will be orange and spawn fire jets below enemies"
    },
    [Collectibles.COLLECTIBLE_PEPPERGRINDER] = {
        ["en_us"] = "Multiplied push damage by x1.5, nearby enemies will get burnt for 4 seconds"
    },
    [Collectibles.COLLECTIBLE_SULFURIC_FIRE] = {
        ["en_us"] = "Increased temporary damage duration and dealt damage to enemies"
    },
    [Collectibles.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL] = {
        ["en_us"] = "Multiplied both Damage and knockback by x1.25" 
    },
    [Collectibles.COLLECTIBLE_DIVINE_RETRIBUTION] = {
        ["en_us"] = "Increased damage, Judas will be healed by 1 black heart"
    },
    [Collectibles.COLLECTIBLE_SPICES_MIX] = {
        ["en_us"] = "Nearby enemies will get burnt"
    },
    [Collectibles.COLLECTIBLE_DIVINE_WRATH] = {
        ["en_us"] = "Increased burnt rock tears by 4, a third rockwave ring will spawn"
    },
    [Collectibles.COLLECTIBLE_BURNT_HOOD] = {
        ["en_us"] = "Perfect Parries will have a chance to spawn a fire jet, enemies will get burnt"
    },
    [Collectibles.COLLECTIBLE_EFFIGY] = {
        ["en_us"] = "Small jumps will spawn a ring of 4 fire jets, Big jumps will spawn a ring of 8 fire jets"
    },
}

for item, descTbl in pairs(BookOfVirtuesSynergies) do
    for lang, desc in pairs(descTbl) do
        EID:addToGeneralCondition(item, "bookOfVirtuesWisps", desc, nil, nil, lang)
    end
end

for item, descTbl in pairs(JudasBirthrightSynergies) do
    for lang, desc in pairs(descTbl) do
        EID:addToGeneralCondition(item, "bookOfBelialBuffs", desc, nil, nil, lang)
    end
end