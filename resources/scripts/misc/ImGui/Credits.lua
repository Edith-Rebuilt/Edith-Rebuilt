
local function AddContributors()
    local Menu = EdithRebuilt.ImGuiModules.ELEMENTS.Menu
	local CreditsTabBar = Menu.TabBars.Credits
	local CreditsTabs = Menu.Tabs.Credits

	ImGui.AddTabBar(Menu.Windows.Credits, CreditsTabBar)
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Resources, "Resources")
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Contributors, "Contributors")
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Testers, "Testers")
	ImGui.AddTab(CreditsTabBar, CreditsTabs.Team, "Team")

	ImGui.AddText(CreditsTabs.Resources,
	[[
	Used resources and utilities:

	- JumpLib (Kerkel)
	- Custom Shockwave API (Brakedude)
	- Pre NPC kill callback (Kerkel)
	- Isaac Save Manager (Catinsurance, Benny)
	- HudHelper (Benny, CatWizard)
	- Status Effect Library (Benny)
	- SaveData System (AgentCucco)
	- lhsx (Ilya Kolbin (iskolbin))
	- Salt Shaker Sound Effect (Joshua Hadley):
	- Edith water stomp sound effect (ArtNinja)
	- Nine Sols Perfect Parry sound effect (Red Candle Games)
	- Pizza Tower taunt sound effect (Tour De Pizza)
	- Ultrakill parry sound effect (New Blood, Arsi "Hakita" Patala)
	- Hollow Knight parry sound effect (Team Cherry)
	- Iconoclasts parry sound effect (Joakim Sandberg (Konjak))
	]],
	true)

	ImGui.AddText(CreditsTabs.Contributors,
	[[
	Contributors:

	- JJ: Inspiration to start this project
	- D!Edith team: Inspiration to resume this project
	- Skulldier: Sal concept
	- Marcy: Tainted Edith Birthright idea
	- Sr Kalaka: Edith Sprite
	- Yuls: Tainted Edith sprite base
	]],
	true)

	ImGui.AddText(CreditsTabs.Testers,
	[[
	Testers:

	- ottostrasse
	- Jozin191
	- Tibu
	- SethoJunk
	- Noirsight
	- Sylvy_owo
	- .radiox
	- Edith's No.1 Fan
	- Beth-Null
	]],
	true)

	ImGui.AddText(CreditsTabs.Team,
	[[
	Team:

	- gigamouse: finished Tainted Edith sprite, items sprites
	- Pattowolfx220: Testing, First Tainted Edith sprite, items sprites
	- River Moondrop (HOLA RIVERIO): Costumes sprites
	- Kotry: Project leader, coder, unlock sheets sprites
	]],
	true)
end

return {
	Add = AddContributors,
}