local isEvaluateCacheFunction = 0
local inHeartLimitCallback = 0

function CustomHealthAPI.Helper.AddPreEvaluateCacheCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, -1 * math.huge, CustomHealthAPI.Mod.PreEvaluateCacheCallback, -1) 
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreEvaluateCacheCallback)

function CustomHealthAPI.Helper.RemovePreEvaluateCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.PreEvaluateCacheCallback) 
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreEvaluateCacheCallback)

function CustomHealthAPI.Mod:PreEvaluateCacheCallback()
	isEvaluateCacheFunction = isEvaluateCacheFunction + 1
end

function CustomHealthAPI.Helper.AddPostEvaluateCacheCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, math.huge, CustomHealthAPI.Mod.PostEvaluateCacheCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostEvaluateCacheCallback)

function CustomHealthAPI.Helper.RemovePostEvaluateCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.PostEvaluateCacheCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostEvaluateCacheCallback)

function CustomHealthAPI.Mod:PostEvaluateCacheCallback()
	isEvaluateCacheFunction = isEvaluateCacheFunction - 1
end

function CustomHealthAPI.Helper.AddResetEvaluateCacheCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetEvaluateCacheCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddResetEvaluateCacheCallback)

function CustomHealthAPI.Helper.RemoveResetEvaluateCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetEvaluateCacheCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveResetEvaluateCacheCallback)

function CustomHealthAPI.Mod:ResetEvaluateCacheCallback()
	if isEvaluateCacheFunction ~= 0 then
		print("Custom Health API ERROR: Evaluate Items callback detection failed with value " .. isEvaluateCacheFunction .. ".")
		isEvaluateCacheFunction = 0
	end
	inHeartLimitCallback = 0
end

CustomHealthAPI.PersistentData.OverriddenFunctions = CustomHealthAPI.PersistentData.OverriddenFunctions or {}
CustomHealthAPI.Helper.HookFunctions = {}

local META, META0
local function BeginClass(T)
	META = {}
	if type(T) == "function" then
		META0 = getmetatable(T())
	else
		META0 = getmetatable(T).__class
	end
end

local function EndClass()
	local oldIndex = META0.__index
	local newMeta = META
		
	rawset(META0, "__index", function(self, k)
		return newMeta[k] or oldIndex(self, k)
	end)
end

----------------------
-- Entity Overrides --
----------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamageEntity == nil then
	BeginClass(Entity)
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamageEntity = META0.TakeDamage
	function META:TakeDamage(...)
		return CustomHealthAPI.Helper.HookFunctions.TakeDamageEntity(self, ...)
	end

	EndClass()
end

----------------------------
-- EntityPlayer Overrides --
----------------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts == nil or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible == nil) or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket == nil) or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetCollectibleNum == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffects == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts == nil or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.GetGreedsGulletHearts == nil) or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetTrinketMultiplier == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.HasCollectible == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts == nil or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.HasGoldenTrinket == nil) or
   CustomHealthAPI.PersistentData.OverriddenFunctions.HasTrinket == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart == nil or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.IsCollectibleBlocked == nil) or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.IsTrinketBlocked == nil) or
   CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.Revive == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer == nil or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible == nil) or
   (REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket == nil)
then
	BeginClass(EntityPlayer)

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts = META0.AddBlackHearts
		function META:AddBlackHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddBlackHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts = META0.AddBoneHearts
		function META:AddBoneHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddBoneHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts = META0.AddBrokenHearts
		function META:AddBrokenHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddBrokenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible = META0.AddCollectible
		function META:AddCollectible(...)
			CustomHealthAPI.Helper.HookFunctions.AddCollectible(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts = META0.AddEternalHearts
		function META:AddEternalHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddEternalHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts = META0.AddGoldenHearts
		function META:AddGoldenHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddGoldenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts = META0.AddHearts
		function META:AddHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts = META0.AddMaxHearts
		function META:AddMaxHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddMaxHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts = META0.AddRottenHearts
		function META:AddRottenHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddRottenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts = META0.AddSoulHearts
		function META:AddSoulHearts(...)
			CustomHealthAPI.Helper.HookFunctions.AddSoulHearts(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible = META0.BlockCollectible
		function META:BlockCollectible(...)
			CustomHealthAPI.Helper.HookFunctions.BlockCollectible(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket = META0.BlockTrinket
		function META:BlockTrinket(...)
			CustomHealthAPI.Helper.HookFunctions.BlockTrinket(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts = META0.CanPickBlackHearts
		function META:CanPickBlackHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.CanPickBlackHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts = META0.CanPickBoneHearts
		function META:CanPickBoneHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.CanPickBoneHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts = META0.CanPickGoldenHearts
		function META:CanPickGoldenHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.CanPickGoldenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts = META0.CanPickRedHearts
		function META:CanPickRedHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.CanPickRedHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts = META0.CanPickRottenHearts
		function META:CanPickRottenHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.CanPickRottenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts = META0.CanPickSoulHearts
		function META:CanPickSoulHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.CanPickSoulHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType = META0.ChangePlayerType
		function META:ChangePlayerType(...)
			return CustomHealthAPI.Helper.HookFunctions.ChangePlayerType(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems = META0.EvaluateItems
		function META:EvaluateItems(...)
			return CustomHealthAPI.Helper.HookFunctions.EvaluateItems(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts = META0.GetBlackHearts
		function META:GetBlackHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetBlackHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts = META0.GetBoneHearts
		function META:GetBoneHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetBoneHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts = META0.GetBrokenHearts
		function META:GetBrokenHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetBrokenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetCollectibleNum == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetCollectibleNum = META0.GetCollectibleNum
		function META:GetCollectibleNum(...)
			return CustomHealthAPI.Helper.HookFunctions.GetCollectibleNum(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts = META0.GetEffectiveMaxHearts
		function META:GetEffectiveMaxHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetEffectiveMaxHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffects == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffects = META0.GetEffects
		function META:GetEffects(...)
			return CustomHealthAPI.Helper.HookFunctions.GetEffects(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts = META0.GetEternalHearts
		function META:GetEternalHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetEternalHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts = META0.GetGoldenHearts
		function META:GetGoldenHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetGoldenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetGreedsGulletHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetGreedsGulletHearts = META0.GetGreedsGulletHearts
		function META:GetGreedsGulletHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetGreedsGulletHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit = META0.GetHeartLimit
		function META:GetHeartLimit(...)
			return CustomHealthAPI.Helper.HookFunctions.GetHeartLimit(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts = META0.GetHearts
		function META:GetHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts = META0.GetMaxHearts
		function META:GetMaxHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetMaxHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts = META0.GetRottenHearts
		function META:GetRottenHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetRottenHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts = META0.GetSoulHearts
		function META:GetSoulHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.GetSoulHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetTrinketMultiplier == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetTrinketMultiplier = META0.GetTrinketMultiplier
		function META:GetTrinketMultiplier(...)
			return CustomHealthAPI.Helper.HookFunctions.GetTrinketMultiplier(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.HasCollectible == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasCollectible = META0.HasCollectible
		function META:HasCollectible(...)
			return CustomHealthAPI.Helper.HookFunctions.HasCollectible(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts = META0.HasFullHearts
		function META:HasFullHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.HasFullHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts = META0.HasFullHeartsAndSoulHearts
		function META:HasFullHeartsAndSoulHearts(...)
			return CustomHealthAPI.Helper.HookFunctions.HasFullHeartsAndSoulHearts(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.HasGoldenTrinket == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasGoldenTrinket = META0.HasGoldenTrinket
		function META:HasGoldenTrinket(...)
			return CustomHealthAPI.Helper.HookFunctions.HasGoldenTrinket(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.HasTrinket == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasTrinket = META0.HasTrinket
		function META:HasTrinket(...)
			return CustomHealthAPI.Helper.HookFunctions.HasTrinket(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart = META0.IsBlackHeart
		function META:IsBlackHeart(...)
			return CustomHealthAPI.Helper.HookFunctions.IsBlackHeart(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart = META0.IsBoneHeart
		function META:IsBoneHeart(...)
			return CustomHealthAPI.Helper.HookFunctions.IsBoneHeart(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.IsCollectibleBlocked == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.IsCollectibleBlocked = META0.IsCollectibleBlocked
		function META:IsCollectibleBlocked(...)
			return CustomHealthAPI.Helper.HookFunctions.IsCollectibleBlocked(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.IsTrinketBlocked == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.IsTrinketBlocked = META0.IsTrinketBlocked
		function META:IsTrinketBlocked(...)
			return CustomHealthAPI.Helper.HookFunctions.IsTrinketBlocked(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart = META0.RemoveBlackHeart
		function META:RemoveBlackHeart(...)
			CustomHealthAPI.Helper.HookFunctions.RemoveBlackHeart(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.Revive == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.Revive = META0.Revive
		function META:Revive(...)
			CustomHealthAPI.Helper.HookFunctions.Revive(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts = META0.SetFullHearts
		function META:SetFullHearts(...)
			CustomHealthAPI.Helper.HookFunctions.SetFullHearts(self, ...)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer = META0.TakeDamage
		function META:TakeDamage(...)
			return CustomHealthAPI.Helper.HookFunctions.TakeDamagePlayer(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible = META0.UnblockCollectible
		function META:UnblockCollectible(...)
			CustomHealthAPI.Helper.HookFunctions.UnblockCollectible(self, ...)
		end
	end

	if REPENTOGON and CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket = META0.UnblockTrinket
		function META:UnblockTrinket(...)
			CustomHealthAPI.Helper.HookFunctions.UnblockTrinket(self, ...)
		end
	end

	EndClass()
end

-------------------
-- HUD Overrides --
-------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.RenderHUD == nil then
	BeginClass(HUD)

	CustomHealthAPI.PersistentData.OverriddenFunctions.RenderHUD = META0.Render
	function META:Render(...)
		CustomHealthAPI.Helper.HookFunctions.RenderHUD(self, ...)
	end

	EndClass()
end

--------------------------------
-- TemporaryEffects Overrides --
--------------------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectibleEffect == nil or 
   CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveCollectibleEffect == nil
then
	BeginClass(TemporaryEffects)

	CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectibleEffect = META0.AddCollectibleEffect
	function META:AddCollectibleEffect(...)
		CustomHealthAPI.Helper.HookFunctions.AddCollectibleEffect(self, ...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveCollectibleEffect = META0.RemoveCollectibleEffect
	function META:RemoveCollectibleEffect(...)
		CustomHealthAPI.Helper.HookFunctions.RemoveCollectibleEffect(self, ...)
	end

	EndClass()
end

-----------------------------
-- PlayerManager Overrides --
-----------------------------

if REPENTOGON and
   (CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasCollectible == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasTrinket == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasCollectible == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasTrinket == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.FirstCollectibleOwner == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.FirstTrinketOwner == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.GetNumCollectibles == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomCollectibleOwner == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomTrinketOwner == nil or 
    CustomHealthAPI.PersistentData.OverriddenFunctions.GetTotalTrinketMultiplier == nil)
then
	CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasCollectible = PlayerManager.AnyoneHasCollectible
	function PlayerManager.AnyoneHasCollectible(...)
		return CustomHealthAPI.Helper.HookFunctions.AnyoneHasCollectible(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasTrinket = PlayerManager.AnyoneHasTrinket
	function PlayerManager.AnyoneHasTrinket(...)
		return CustomHealthAPI.Helper.HookFunctions.AnyoneHasTrinket(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasCollectible = PlayerManager.AnyPlayerTypeHasCollectible
	function PlayerManager.AnyPlayerTypeHasCollectible(...)
		return CustomHealthAPI.Helper.HookFunctions.AnyPlayerTypeHasCollectible(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasTrinket = PlayerManager.AnyPlayerTypeHasTrinket
	function PlayerManager.AnyPlayerTypeHasTrinket(...)
		return CustomHealthAPI.Helper.HookFunctions.AnyPlayerTypeHasTrinket(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.FirstCollectibleOwner = PlayerManager.FirstCollectibleOwner
	function PlayerManager.FirstCollectibleOwner(...)
		return CustomHealthAPI.Helper.HookFunctions.FirstCollectibleOwner(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.FirstTrinketOwner = PlayerManager.FirstTrinketOwner
	function PlayerManager.FirstTrinketOwner(...)
		return CustomHealthAPI.Helper.HookFunctions.FirstTrinketOwner(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.GetNumCollectibles = PlayerManager.GetNumCollectibles
	function PlayerManager.GetNumCollectibles(...)
		return CustomHealthAPI.Helper.HookFunctions.GetNumCollectibles(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomCollectibleOwner = PlayerManager.GetRandomCollectibleOwner
	function PlayerManager.GetRandomCollectibleOwner(...)
		return CustomHealthAPI.Helper.HookFunctions.GetRandomCollectibleOwner(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomTrinketOwner = PlayerManager.GetRandomTrinketOwner
	function PlayerManager.GetRandomTrinketOwner(...)
		return CustomHealthAPI.Helper.HookFunctions.GetRandomTrinketOwner(...)
	end

	CustomHealthAPI.PersistentData.OverriddenFunctions.GetTotalTrinketMultiplier = PlayerManager.GetTotalTrinketMultiplier
	function PlayerManager.GetTotalTrinketMultiplier(...)
		return CustomHealthAPI.Helper.HookFunctions.GetTotalTrinketMultiplier(...)
	end
end

--------------------
-- Hook Functions --
--------------------

CustomHealthAPI.Helper.HookFunctions.AddBlackHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddBlackHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "BLACK_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddBoneHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddBoneHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "BONE_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddBrokenHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddBrokenHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "BROKEN_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddCollectible = function(player, item, charge, firstTimePickingUp, slot, varData, pool, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddCollectible(player:GetOtherTwin(), item, charge, firstTimePickingUp, slot, varData, pool, ...)
		end
	end
	
	if CustomHealthAPI then
		if not (CustomHealthAPI.Helper.PlayerIsIgnored(player) or REPENTOGON) then
			CustomHealthAPI.Helper.CheckIfHealthOrderSet()
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
		
		pdata.HasFunGuyTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_MUSHROOM)
		pdata.HasSeraphimTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_ANGEL)
		pdata.HasLeviathanTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_EVIL_ANGEL)
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible(player, 
	                                                                  item, 
	                                                                  charge or 0, 
	                                                                  firstTimePickingUp or firstTimePickingUp == nil, 
	                                                                  slot or ActiveSlot.SLOT_PRIMARY, 
	                                                                  varData or 0,
	                                                                  pool or ItemPoolType.POOL_TREASURE,
	                                                                  ...)
	
	if CustomHealthAPI then
		if not (CustomHealthAPI.Helper.PlayerIsIgnored(player) or REPENTOGON) and firstTimePickingUp then
			CustomHealthAPI.Helper.HandleCollectibleHP(player, item)
		end
		
		local pdata = CustomHealthAPI.Helper.GetPersistentData(player, true)
		
		pdata.HasFunGuyTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_MUSHROOM)
		pdata.HasSeraphimTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_ANGEL)
		pdata.HasLeviathanTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_EVIL_ANGEL)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddEternalHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddEternalHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "ETERNAL_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddGoldenHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddGoldenHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "GOLDEN_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddMaxHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddMaxHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "EMPTY_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddRottenHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddRottenHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "ROTTEN_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddSoulHearts = function(player, hp, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddSoulHearts(player:GetOtherTwin(), hp, ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "SOUL_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, hp, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickBlackHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickBlackHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "BLACK_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickBoneHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickBoneHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "BONE_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickGoldenHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickGoldenHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "GOLDEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickRedHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickRedHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "RED_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickRottenHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickRottenHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "ROTTEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickSoulHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickSoulHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "SOUL_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.ChangePlayerType = function(player, playertype, ...)
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.ChangePlayerType(player, playertype)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.EvaluateItems = function(player, ...)
	if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	end
	
	isEvaluateCacheFunction = isEvaluateCacheFunction + 1
	CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems(player, ...)
	isEvaluateCacheFunction = isEvaluateCacheFunction - 1
end

CustomHealthAPI.Helper.HookFunctions.GetBlackHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetBlackHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		local otherMasks = data.OtherHealthMasks or {}
		
		local blackHearts = 0
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					blackHearts = blackHearts << 1
					
					local key = health.Key
					if key == "BLACK_HEART" then
						blackHearts = blackHearts + 1
					end
				end
			end
		end
		
		return blackHearts
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetBoneHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetBoneHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player, ...)
	end
end

if REPENTOGON then
	function CustomHealthAPI.Helper.AddStartHeartLimitCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, -1 * math.huge, CustomHealthAPI.Mod.StartHeartLimitCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddStartHeartLimitCallback)

	function CustomHealthAPI.Helper.RemoveStartHeartLimitCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, CustomHealthAPI.Mod.StartHeartLimitCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveStartHeartLimitCallback)

	function CustomHealthAPI.Mod:StartHeartLimitCallback(ent, amount, flags, source, countdown)
		inHeartLimitCallback = inHeartLimitCallback + 1
	end
	
	function CustomHealthAPI.Helper.AddEndHeartLimitCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, math.huge, CustomHealthAPI.Mod.EndHeartLimitCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddEndHeartLimitCallback)

	function CustomHealthAPI.Helper.RemoveEndHeartLimitCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEART_LIMIT, CustomHealthAPI.Mod.EndHeartLimitCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveEndHeartLimitCallback)

	function CustomHealthAPI.Mod:EndHeartLimitCallback(ent, amount, flags, source, countdown)
		inHeartLimitCallback = inHeartLimitCallback - 1
	end
end

CustomHealthAPI.Helper.HookFunctions.GetBrokenHearts = function(player, ...)
	if inHeartLimitCallback > 0 then return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player, ...) end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetBrokenHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalBrokenHP(player)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetEffectiveMaxHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetEffectiveMaxHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player, true) then
			return 0
		end
	
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetRedCapacity(player)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetEternalHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetEternalHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		if data ~= nil then
			return CustomHealthAPI.Helper.GetTotalKeys(player, "ETERNAL_HEART")
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player, ...)
		end
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetGoldenHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetGoldenHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		if data ~= nil then
			return CustomHealthAPI.Helper.GetTotalKeys(player, "GOLDEN_HEART")
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player, ...)
		end
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetHeartLimit = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetHeartLimit(player:GetOtherTwin(), ...)
		end
	end
	
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalRedHP(player, true)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetMaxHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetMaxHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalMaxHP(player)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetRottenHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetRottenHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalKeys(player, "ROTTEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetSoulHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetSoulHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.HasFullHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.HasFullHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetRedCapacity(player) - CustomHealthAPI.Helper.GetTotalRedHP(player, true) <= 0
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.HasFullHeartsAndSoulHearts = function(player, ...)
	-- so this checks if red hp + soul hp > max hp (ignoring bone)
	-- ...what is the point of this?
	-- does anyone actually use this function?
	-- this isn't what i thought it would do at all
	-- i thought it would check if your red hp + soul hp fills the entire hp bar
	-- that would actually be useful
	-- and why does it ignore bone heart red capacity?
	-- hasfullhearts doesn't do that
	-- florian why
	-- nicalis why
	-- spider why
	-- kilburn why
	-- who do i blame for this
	-- why does this exist
	-- okay so apparently this is the check for regular challenge room doors???
	-- why is it not just called checkifchallengedoorshouldopen or something
	-- the current name is just confusing
	-- goddamnit
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.HasFullHeartsAndSoulHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalMaxHP(player) - (CustomHealthAPI.Helper.GetTotalRedHP(player, true) + CustomHealthAPI.Helper.GetTotalSoulHP(player, true)) <= 0
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.IsBlackHeart = function(player, heart, ...)
	--...why does this skip over the even numbers
	--it's not even a half heart thing
	--it just flat out skips the even numbers and returns false for them
	--wtf
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.IsBlackHeart(player:GetOtherTwin(), heart, ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		if heart % 2 == 0 or heart < 0 then
			return false
		end
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		local otherMasks = data.OtherHealthMasks or {}
		
		local soulHeartsToProcess = math.floor(heart / 2) + 1
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					soulHeartsToProcess = soulHeartsToProcess - 1
					
					local key = health.Key
					if soulHeartsToProcess == 0 then
						if key == "BLACK_HEART" then
							return true
						else
							return false
						end
					end
				end
			end
		end
		
		return false
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, heart, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.IsBoneHeart = function(player, heart, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.IsBoneHeart(player:GetOtherTwin(), heart, ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if heart < 0 then
			return false
		end
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		local otherMasks = data.OtherHealthMasks or {}
		
		local heartsToProcess = heart + 1
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					heartsToProcess = heartsToProcess - 1
					
					local key = health.Key
					if heartsToProcess == 0 then
						return false
					end
				elseif CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				       CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
				       CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") > 0
				then
					heartsToProcess = heartsToProcess - 1
					
					local key = health.Key
					if heartsToProcess == 0 then
						return true
					end
				end
			end
		end
		
		return false
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, heart, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.RemoveBlackHeart = function(player, heart, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.RemoveBlackHeart(player:GetOtherTwin(), heart, ...)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if heart < 0 then
			return
		end
		
		local data = CustomHealthAPI.Helper.GetSavedata(player)
		local otherMasks = data.OtherHealthMasks or {}
		
		local soulHeartsToProcess = math.floor(heart / 2) + 1
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					soulHeartsToProcess = soulHeartsToProcess - 1
					
					local key = health.Key
					if soulHeartsToProcess == 0 then
						if key == "BLACK_HEART" then
							health.Key = "SOUL_HEART"
							CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
							return
						end
					end
				end
			end
		end
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart(player, heart, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.Revive = function(player, ...)
	local data = CustomHealthAPI.Helper.GetPersistentData(player, true)
	if data then
		data.IsCustomRevive = true
	end
	CustomHealthAPI.PersistentData.OverriddenFunctions.Revive(player, ...)
end

CustomHealthAPI.Helper.HookFunctions.SetFullHearts = function(player, ...)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.SetFullHearts(player:GetOtherTwin(), ...)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "RED_HEART", 99, true, true)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts(player, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.RenderHUD = function(hud, ...)
	CustomHealthAPI.PersistentData.OverriddenFunctions.RenderHUD(hud, ...)
	
	if CustomHealthAPI and CustomHealthAPI.Mod and CustomHealthAPI.Mod.RenderCustomHealthCallback then
		for i = 0, Game():GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			CustomHealthAPI.Helper.UpdateMantles(player)
		end
		CustomHealthAPI.Mod:RenderCustomHealthCallback()
	end
end

CustomHealthAPI.Helper.HookFunctions.TakeDamage = function(ent, amount, flags, source, countdown, damageFunc, ignoreResync, ...)
	local alreadyInDamageCallback = (CustomHealthAPI.Helper.GetOtherData(ent) ~= nil and 
	                                CustomHealthAPI.Helper.GetOtherData(ent).InDamageCallback) or nil
	
	local alreadyEnabledDebugThreeForDamage = (CustomHealthAPI.Helper.GetPersistentData(ent) ~= nil and 
	                                          CustomHealthAPI.Helper.GetPersistentData(ent).EnabledDebugThreeForDamage) or nil
	
	local alreadyHandlingDamage = (CustomHealthAPI.Helper.GetSavedata(ent) ~= nil and 
	                               CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamage) or nil
	local alreadyHandlingDamageAmount = (CustomHealthAPI.Helper.GetSavedata(ent) ~= nil and 
	                                     CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageAmount) or nil
	local alreadyHandlingDamageFlags = (CustomHealthAPI.Helper.GetSavedata(ent) ~= nil and 
	                                    CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageFlags) or nil
	local alreadyHandlingDamageSource = (CustomHealthAPI.Helper.GetSavedata(ent) ~= nil and 
	                                     CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageSource) or nil
	local alreadyHandlingDamageCountdown = (CustomHealthAPI.Helper.GetSavedata(ent) ~= nil and 
	                                        CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageCountdown) or nil
	
	local returnVal = damageFunc(ent, amount, flags, source, countdown, ...)
	if not ignoreResync and 
	   CustomHealthAPI.Helper.GetSavedata(ent) and 
	   CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamage ~= nil 
	then
		CustomHealthAPI.Helper.FinishDamageDesync(ent)
	end
	
	if alreadyInDamageCallback ~= nil then
		CustomHealthAPI.Helper.GetOtherData(ent).InDamageCallback = alreadyInDamageCallback
	end
	
	if alreadyHandlingDamage ~= nil then
		CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamage = alreadyHandlingDamage
		CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageAmount = alreadyHandlingDamageAmount
		CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageFlags = alreadyHandlingDamageFlags
		CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageSource = alreadyHandlingDamageSource
		CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageCountdown = alreadyHandlingDamageCountdown
		
		CustomHealthAPI.Helper.GetSavedata(ent).HandlingDamageCanShackle = ent:ToPlayer() and
		                                                                 not (player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) or 
		                                                                      player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED))
		CustomHealthAPI.Helper.GetOtherData(ent).ShouldActivateScapular = ent:ToPlayer() and 
		                                                                ent:ToPlayer():GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_SCAPULAR)
	end
	
	if alreadyEnabledDebugThreeForDamage ~= nil then
		CustomHealthAPI.Helper.GetPersistentData(ent).EnabledDebugThreeForDamage = alreadyEnabledDebugThreeForDamage
		
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Enabled debug flag."
	end
	
	return returnVal
end

CustomHealthAPI.Helper.HookFunctions.TakeDamageEntity = function(ent, amount, flags, source, countdown, ...)
	return CustomHealthAPI.Helper.HookFunctions.TakeDamage(ent, 
	                                                       amount, 
	                                                       flags, 
	                                                       source, 
	                                                       countdown, 
	                                                       CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamageEntity,
	                                                       nil,
	                                                       ...)
end

CustomHealthAPI.Helper.HookFunctions.TakeDamagePlayer = function(ent, amount, flags, source, countdown, ...)
	return CustomHealthAPI.Helper.HookFunctions.TakeDamage(ent, 
	                                                       amount, 
	                                                       flags, 
	                                                       source, 
	                                                       countdown, 
	                                                       CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer,
	                                                       nil,
	                                                       ...)
end

CustomHealthAPI.Helper.HookFunctions.GetEffects = function(player, ...)
	local effects = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffects(player, ...)
	CustomHealthAPI.Helper.ConnectTempEffectsToPlayer(player, effects)
	return effects
end

CustomHealthAPI.Helper.HookFunctions.AddCollectibleEffect = function(effects, item, addCostume, count, ...)
	if addCostume == nil then
		addCostume = true
	end
	if count == nil then
		count = 1
	end
	CustomHealthAPI.Helper.TrackHolyMantleOnAdd(effects, item, count)
	return CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectibleEffect(effects, item, addCostume, count, ...)
end

CustomHealthAPI.Helper.HookFunctions.RemoveCollectibleEffect = function(effects, item, count, ...)
	if count == nil then
		count = 1
	end
	CustomHealthAPI.Helper.TrackHolyMantleOnRemove(effects, item, count)
	return CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveCollectibleEffect(effects, item, count, ...)
end

CustomHealthAPI.Helper.HookFunctions.HasCollectible = function(player, id, ...)
	if REPENTOGON then
		if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
			local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.HasCollectible(player, id, ...)
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
			return ret
		end
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.HasCollectible(player, id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetCollectibleNum = function(player, id, ...)
	if REPENTOGON then
		if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
			local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.GetCollectibleNum(player, id, ...)
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
			return ret
		end
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetCollectibleNum(player, id, ...)
end

CustomHealthAPI.Helper.HookFunctions.HasTrinket = function(player, id, ...)
	if REPENTOGON then
		if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id) 
			end
			local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.HasTrinket(player, id, ...)
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
			return ret
		end
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.HasTrinket(player, id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetTrinketMultiplier = function(player, id, ...)
	if REPENTOGON then
		if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id) 
			end
			local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.GetTrinketMultiplier(player, id, ...)
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
			return ret
		end
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetTrinketMultiplier(player, id, ...)
end

if REPENTOGON then
CustomHealthAPI.Helper.HookFunctions.HasGoldenTrinket = function(player, id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
			CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id) 
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.HasGoldenTrinket(player, id, ...)
		CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.HasGoldenTrinket(player, id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetGreedsGulletHearts = function(player, ...)
	return CustomHealthAPI.Helper.GetGreedsGulletHearts(player)
end

CustomHealthAPI.Helper.HookFunctions.BlockCollectible = function(player, id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		data.IsGreedsGulletBlocked = true
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.BlockTrinket = function(player, id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		data.IsMothersKissBlocked = true
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.UnblockCollectible = function(player, id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		data.IsGreedsGulletBlocked = nil
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.UnblockTrinket = function(player, id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		data.IsMothersKissBlocked = nil
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.IsCollectibleBlocked = function(player, id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		return data.IsGreedsGulletBlocked == true
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.IsCollectibleBlocked(player, id, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.IsTrinketBlocked = function(player, id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		return data.IsMothersKissBlocked == true
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.IsTrinketBlocked(player, id, ...)
	end
end

CustomHealthAPI.Helper.HookFunctions.AnyoneHasCollectible = function(id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasCollectible(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasCollectible(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.AnyoneHasTrinket = function(id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasTrinket(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.AnyoneHasTrinket(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.AnyPlayerTypeHasCollectible = function(playertype, id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasCollectible(playertype, id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasCollectible(playertype, id, ...)
end

CustomHealthAPI.Helper.HookFunctions.AnyPlayerTypeHasTrinket = function(playertype, id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasTrinket(playertype, id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.AnyPlayerTypeHasTrinket(playertype, id, ...)
end

CustomHealthAPI.Helper.HookFunctions.FirstCollectibleOwner = function(id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.FirstCollectibleOwner(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.FirstCollectibleOwner(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.FirstTrinketOwner = function(id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.FirstTrinketOwner(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.FirstTrinketOwner(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetNumCollectibles = function(id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.GetNumCollectibles(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetNumCollectibles(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetRandomCollectibleOwner = function(id, ...)
	if id == CollectibleType.COLLECTIBLE_GREEDS_GULLET then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsGreedsGulletBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockCollectible(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomCollectibleOwner(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockCollectible(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomCollectibleOwner(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetRandomTrinketOwner = function(id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomTrinketOwner(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetRandomTrinketOwner(id, ...)
end

CustomHealthAPI.Helper.HookFunctions.GetTotalTrinketMultiplier = function(id, ...)
	if (id & TrinketType.TRINKET_ID_MASK) == TrinketType.TRINKET_MOTHERS_KISS then
		local players = PlayerManager.GetPlayers()
		for _, player in ipairs(players) do
			if not CustomHealthAPI.Helper.GetOtherData(player).IsMothersKissBlocked then 
				CustomHealthAPI.PersistentData.OverriddenFunctions.UnblockTrinket(player, id)
			end
		end
		local ret = CustomHealthAPI.PersistentData.OverriddenFunctions.GetTotalTrinketMultiplier(id, ...)
		for _, player in ipairs(players) do
			CustomHealthAPI.PersistentData.OverriddenFunctions.BlockTrinket(player, id)
		end
		return ret
	end
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetTotalTrinketMultiplier(id, ...)
end
end