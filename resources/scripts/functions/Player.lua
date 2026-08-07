local mod = EdithRebuilt
local enums = mod.Enums
local challenges = enums.Challenge
local room = enums.Utils.Room
local misc = enums.Misc
local players = enums.PlayerType
local data = mod.DataHolder.GetEntityData
local Player = {}

---@param fn fun(player: EntityPlayer)
---@param type PlayerType
function Player.ForEachPlayerType(fn, type)
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if player:GetPlayerType() ~= type then goto continue end
		fn(player)
		::continue::
	end
end

---@param player EntityPlayer
---@return {up: number, down: number, left: number, right: number}
function Player.GetMovementInput(player)
    local ci = player.ControllerIndex
    return {
        up = Input.GetActionValue(ButtonAction.ACTION_UP, ci),
        down = Input.GetActionValue(ButtonAction.ACTION_DOWN, ci),
        left = Input.GetActionValue(ButtonAction.ACTION_LEFT, ci),
        right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, ci),
    }
end

---Basically makes both Edith's be less dragged by water currents
---@param player EntityPlayer
function Player.WaterCurrentManager(player)
	local current = room:GetWaterCurrent()
	local RoomHasWaterCurrent = not (current.X == 0 and current.Y == 0)

	if not RoomHasWaterCurrent then return end
	local modules = mod.Modules
	local TEdithParams = modules.TEDITH.GetHopParryParams(player)
	local isTEdithMoving = TEdithParams.IsHoping or TEdithParams.GrudgeDash
	local isMoving = isTEdithMoving or modules.JUMP.IsJumping(player)

	if isMoving and not data(player).IsRedirectioningMove then return end

	player.Velocity = player.Velocity * (current * 0.3)
end

---@param player EntityPlayer
function Player.CanUseBombs(player)
	return player:GetNumBombs() > 0 or player:HasGoldenBomb()
end

---@param player EntityPlayer
---@return boolean
function Player.HasBombTearItem(player)
	return (player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS))
end

---@param player EntityPlayer
---@return boolean
function Player.CanTriggerBombStomp(player)
	return Player.HasBombTearItem(player) or Player.CanUseBombs(player)
end	

---@param player EntityPlayer
---@return boolean
function Player.ShouldConsumeBomb(player)
	return player:GetNumBombs() > 0 and not player:HasGoldenBomb()
end

---Checks if player is Edith
---@param player EntityPlayer
---@param tainted boolean set it to `true` to check if player is Tainted Edith
---@return boolean
function Player.IsEdith(player, tainted)
	return player:GetPlayerType() == (tainted and players.PLAYER_EDITH_B or players.PLAYER_EDITH)
end

---Checks if any player is Edith
---@param p EntityPlayer
---@return boolean
function Player.IsAnyEdith(p)
	return Player.IsEdith(p, true) or Player.IsEdith(p, false)
end

function Player.AnyoneIsEdith()
    return PlayerManager.AnyoneIsPlayerType(enums.PlayerType.PLAYER_EDITH)
        or PlayerManager.AnyoneIsPlayerType(enums.PlayerType.PLAYER_EDITH_B)
end

---@param p EntityPlayer
---@return integer
function Player.GetNumTears(p)
	return p:GetMultiShotParams(WeaponType.WEAPON_TEARS):GetNumTears()
end

---@param player EntityPlayer
function Player.PlayerHasBirthright(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
end

---@param player EntityPlayer
function Player.ManageEdithWeapons(player)
	local weapon = player:GetWeapon(1)

	if not weapon then return end

	local weaponType = weapon:GetWeaponType()

	if not mod.Modules.HELPERS.When(weaponType, enums.Tables.OverrideWeapons, false) then return end

	Isaac.DestroyWeapon(weapon)

	if weaponType == WeaponType.WEAPON_LUDOVICO_TECHNIQUE then return end

	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)
end

---Changes `player`'s ANM2 file
---@param player EntityPlayer
---@param FilePath string
function Player.SetNewANM2(player, FilePath)
	local playerSprite = player:GetSprite()

	if not (playerSprite:GetFilename() ~= FilePath and not player:IsCoopGhost()) then return end
	playerSprite:Load(FilePath, true)
	-- playerSprite:Update()
end

---@param player EntityPlayer
---@return boolean
function Player.IsInTrapdoor(player)
	local grid = room:GetGridEntityFromPos(player.Position)
	return grid and grid:GetType() == GridEntityType.GRID_TRAPDOOR or false
end

---Helper function for Edith's cooldown color manager
---@param player EntityPlayer
---@param intensity number
---@param duration integer
function Player.SetColorCooldown(player, intensity, duration)
	local pcolor = player.Color
	local col = pcolor:GetColorize()
	local tint = pcolor:GetTint()
	local off = pcolor:GetOffset()
	local Red = off.R + (intensity + ((col.R + tint.R) * 0.2))
	local Green = off.G + (intensity + ((col.G + tint.G) * 0.2))
	local Blue = off.B + (intensity + ((col.B + tint.B) * 0.2))

	pcolor:SetOffset(Red, Green, Blue)
	player:SetColor(pcolor, duration, 100, true, false)
end

---Helper tears stat manager function
---@param firedelay number
---@param val number
---@param mult? boolean
---@return number
function Player.tearsUp(firedelay, val, mult)
    local currentTears = 30 / (firedelay + 1)
    local newTears = mult and (currentTears * val) or currentTears + val
    return math.max((30 / newTears) - 1, -0.75)
end

---Helper range stat manager function
---@param range number
---@param val number
---@return number
function Player.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

---Returns player's range stat as portrayed in Game's stat HUD
---@param player EntityPlayer
---@return number
function Player.GetPlayerRange(player)
	return player.TearRange / 40
end

---Returns player's tears stat as portrayed in game's stats HUD
---@param p EntityPlayer
---@return number
function Player.GetplayerTears(p)
    return mod.Modules.MATHS.Round(30 / (p.MaxFireDelay + 1), 2)
end

---Checks if player is shooting by checking if shoot inputs are being pressed
---@param p EntityPlayer
---@return boolean
function Player.IsPlayerShooting(p)
	local shoot = {
        l = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, p.ControllerIndex),
        r = Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, p.ControllerIndex),
        u = Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, p.ControllerIndex),
        d = Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, p.ControllerIndex)
    }
	return (shoot.l or shoot.r or shoot.u or shoot.d)
end

---Used to add some interactions to Judas' Birthright effect
---@param p EntityPlayer
function Player.IsJudasWithBirthright(p)
	return p:GetPlayerType() == PlayerType.PLAYER_JUDAS and Player.PlayerHasBirthright(p)
end

---@param p EntityPlayer
---@return boolean
function Player.HasTanukiStatueEffect(p)
---@diagnostic disable-next-line: undefined-field
	return p:GetGnawedLeafTimer() >= 60
end

---@param player EntityPlayer
---@param challenge Challenge
function Player.SetChallengeSprite(player, challenge)
	if challenge == Challenge.CHALLENGE_NULL then return end

	local spritePath = (
		challenge == challenges.CHALLENGE_GRUDGE and misc.GrudgeSpritePath or 
		challenge == challenges.CHALLENGE_VESTIGE and misc.VestigeSpritePath
	)

	if not spritePath then return end

	local playerSprite = player:GetSprite()

	for i = 0, 14 do
		playerSprite:ReplaceSpritesheet(i, spritePath, true)
	end
end

---@param player EntityPlayer
function Player.ResetPlayerSprite(player)
	local playerSprite = player:GetSprite()

	for i = 0, 14 do
		playerSprite:ReplaceSpritesheet(i, EntityConfig.GetPlayer(player:GetPlayerType()):GetSkinPath(), true)
	end
end

---@param player EntityPlayer
---@param path string
function Player.SetHoodSprite(player, path)
	local costumeDesc = player:GetCostumeSpriteDescs()[1]
	costumeDesc:GetSprite():ReplaceSpritesheet(0, path, true)
end

---@param player EntityPlayer
---@param tainted boolean
function Player.SetCustomSprite(player, tainted)
	if not mod.Modules.HELPERS.IsModChallenge() then return end

	local Helpers = mod.Modules.HELPERS

	local challenge = Isaac.GetChallenge()

	if Player.IsEdith(player, false) and Helpers.GetConfigData("EdithData").EnableVestigeMode == true then
		challenge = challenges.CHALLENGE_VESTIGE
	elseif Player.IsEdith(player, true) and Helpers.GetConfigData("TEdithData").EnableGrudgeMode == true then
		challenge = challenges.CHALLENGE_GRUDGE
	end

	if challenge ~= Challenge.CHALLENGE_NULL then
		local hoodPath = tainted and enums.Misc.GrudgeHoodPath or enums.Misc.VestigeHoodPath
	
		Player.SetChallengeSprite(player, challenge)
		Player.SetHoodSprite(player, hoodPath)
	end
end

return Player