local function AddModCompat()
    local Menu = EdithRebuilt.ImGuiModules.ELEMENTS.Menu
	ImGui.AddText(Menu.Windows.ModCompat, [[
* Antibirth Runes:
	- Geode can spawn Antibirth runes

* EID:
	- Character descriptions
	- Character's birthright desriptions
	- Mod's Content Descriptions

* Birthcake: Rebaked: 
	- Salty Stomps (Edith effect):
		- Offensive Stomps have a 25% chance of apply Salted status effect
	- (T. Edith's effect)
		- Pending rework
* The Future:
	- Added Steven's dialogue for both Ediths

* Community Remix:
	- Added Salted Hearts:
		- Unlocked by beating Insane mod as any Edith
		- 25% chance of replace soul hearts
		- Can take 3 hits 
		- On depleting, Sets Isaac into Salted status effect

* Birthwrong:
	- Dissolution, flooded rooms (Edith Effect):
		- All rooms will get flooded
		- Edith will start losing speed slowly if she stands in water
		- If Speed goes below 0.75, she won't be able to shoot
		- Kill salted enemies to recover speed (Can't go up to your current max speed stat)

	- The skies breaks twice (T. Edith effect)
		- Every 3 frames a fire rock will fall from the ceiling
		- These fire rocks spawns fire jets on landing
		- 15% chance of spawing a fire jet wave instead of a single fire jet
		- These rocks and jets cand damage both Tainted Edith and the enemies

* Runic Tablet:
	- Increased Damage and Knockback od Soul of Edith's stomp

]], true)
end

return {
	Add = AddModCompat,
}