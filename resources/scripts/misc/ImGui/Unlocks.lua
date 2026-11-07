local mod = EdithRebuilt
local enums = mod.Enums
local achievements = enums.Achievements
local pgd = enums.Utils.PGD

local function ResetUnlocks()
	for _, achievement in pairs(achievements) do
		Isaac.ExecuteCommand("lockachievement " .. tostring(achievement))
	end
end

local function isEdithUnlocked(tainted)
	local ach = tainted and achievements.ACHIEVEMENT_TAINTED_EDITH or achievements.ACHIEVEMENT_EDITH
	return pgd:Unlocked(ach)
end

return {
	ResetUnlocks = ResetUnlocks,
	IsEdithUnlocked = isEdithUnlocked,
}