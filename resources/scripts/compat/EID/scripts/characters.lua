local enums = EdithRebuilt.Enums
local PlayerType = enums.PlayerType

EID:addCharacterInfo(PlayerType.PLAYER_EDITH, [[Unable to walk, spawns a target instead
Pressing {{ButtonRT}} will make her jump to the target
A Single Press will trigger an offensive stomp (trigger synergies)
Keeping pressed until she turns grey, it will be a defensive stomp (makes Edith invulnerable and applies salted status effect)
SaltedStatus
]], "Edith")
EID:addCharacterInfo(PlayerType.PLAYER_EDITH_B, [[Unable to walk, spawns an arrow instead
Trying to walk will charge a chargebar, the more charge the faster she'll move in the arrow's direction
Pressing {{ButtonRT}} will make her jump in place, performing a parry, its effect depends on enemy's distance
A Perfect Parry damage the enemy, increases the dash charge, gives 20 i-frames, and overheats Edith
If Edith is overheat, both damage and cooldown of the parry will be increased, heat will be lowered over time
]], "Tainted Edith")

EID:addBirthright(PlayerType.PLAYER_EDITH, "Edith's Stomps will have increased damage# Stomp synergies will be powered", "Edith")
EID:addBirthright(PlayerType.PLAYER_EDITH_B, [[
Hopdash charge can be overcharged to 200%
Overcharged hopdash can apply burn status effect
Cinder created by perfect parrying enemies will spawn fire jets below them
Parried projectiles and tears will have fire effects
]], "Tainted Edith")

