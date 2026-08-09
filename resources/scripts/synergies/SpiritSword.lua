local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param isStomp boolean
local function knifeManager(player, isStomp)
	local knife = player:FireKnife(player, 90, true, 0, KnifeVariant.SPIRIT_SWORD)
	local knifeData = data(knife)
	local knifeSprite = knife:GetSprite()
	local damageMult = (isStomp and Player.IsEdithBirthtight(player)) and 0.75 or 0.5
	local baseDamage = (player.Damage * 8) + 10

	knife.SpriteScale = knife.SpriteScale * 1.7
	knifeData.SynergySword = true
	knife.CollisionDamage = baseDamage * damageMult
	knifeSprite:Play("SpinDown", true)
	knife.Visible = false
end

---@param player EntityPlayer
local function effectManager(player)
	local effect = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.POOF01,
		0,
		player.Position,
		Vector.Zero,
		nil
	):ToEffect() ---@cast effect EntityEffect

	effect:FollowParent(player)
	local effectSprite = effect:GetSprite()
	effectSprite:Load("gfx/008.010_spirit sword.anm2", true)
	effectSprite:Play("SpinDown")
end

---@param player EntityPlayer
local function FireSpiritSword(player, isStomp)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end

	knifeManager(player, isStomp)
	effectManager(player)
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) FireSpiritSword(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) FireSpiritSword(player, true) end)

---@param knife EntityKnife
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, knife)
	local knifeSprite = knife:GetSprite()
	local knifeData = data(knife)

	if knife.Variant ~= KnifeVariant.SPIRIT_SWORD or not knifeData.SynergySword then return end
	if not (knifeSprite:GetAnimation() == "SpinDown" and knifeSprite:IsFinished()) then return end

	knife:Remove()
end)
