class 'SmokeGrenade'

local m_DCExt = require "__shared/Util/DataContainerExt"

local isSmokeGrenadeCloned = false

local smoke = {
	instanceGuid = Guid("30AD5145-04AD-4C97-8D1B-B4FE0E1AD6F5"),
	instance = nil,
	isMeshLoaded = false,
	meshGuid = Guid("89A51D59-930C-40EE-B830-AD25C1ACC649"),
	isTrailEffectLoaded = false,
	trailEffectGuid = Guid("671A2448-09FF-A595-2FA6-FF450642FA9F"),
	isExplosionLoaded = false,
	explosionGuid = Guid("48BBE181-231E-4E7F-A959-10ECA1BCAF57"),
}

local originalGrenade = {
	weaponUnlockAssetGuid = Guid("9f789f05-ce7b-dadc-87d7-16e847dbdd09"),
	partitionGuid = Guid("31EBAC8C-F32E-11DF-8153-F8368A2EF9E0"),
	weaponUnlockAsset = nil,
	isWeaponUnlockAssetLoaded = false,

	soldierWeaponBlueprintGuid = Guid("C569F719-AB04-7BB0-2C08-B906DBC9FD3A"),
	isSoldierWeaponBlueprintLoaded = false,

	soldierWeaponDataGuid = Guid("793FC225-DC6A-974F-CBCA-E431F432756E"),
	isSoldierWeaponDataLoaded = false,

	weaponFiringGuid = Guid("7059DE8E-0A29-4BFC-991B-3BE2544DD391"),
	isWeaponFiringLoaded = false,

	firingFunctionDataGuid = Guid("04E1FA90-5B6E-4316-862C-15EB89652441"),
	isFiringFunctionDataLoaded = false,

	projectileBlueprintGuid = Guid("F39ED0C9-6A18-C1AE-1363-7F14B4A0F95A"),
	isProjectileBlueprintLoaded = false,

	grenadeEntityDataGuid = Guid("326152E6-0F84-430D-D2E3-19EBDA8266C4"),
	isGrenadeEntityDataLoaded = false,
}

local customGrenade = { -- made up guids and ids
	weaponUnlockAsset = nil,
	guid = Guid("6E52C5D6-0000-9B70-22AB-E3DC4613D1B7"),

	soldierWeaponBlueprintGuid = Guid("E823163C-0000-0363-3EB3-EFAA3D8384A6"),
	soldierWeaponBlueprint = nil,

	soldierWeaponData = nil,
	soldierWeaponDataGuid = Guid("A823163C-0000-0363-3EB3-EFAA3D8384A6"),

	weaponFiringGuid = Guid("B823163C-0000-0363-3EB3-EFAA3D8384A6"),

	firingFunctionDataGuid = Guid("C823163C-0000-0363-3EB3-EFAA3D8384A6"),

	projectileBlueprintGuid = Guid("D823163C-0000-0363-3EB3-EFAA3D8384A6"),
	projectileBlueprint = nil,

	grenadeEntityDataGuid = Guid("F823163C-0000-0363-3EB3-EFAA3D8384A6"),
	grenadeEntityData = nil,

	identifier = 6949314494,
	weaponIdentifier = 6960699348
}

function SmokeGrenade:__init()
	print("Initializing SmokeGrenade shared")
end



function SmokeGrenade:OnLoadBundles(p_Hook, p_Bundles, p_Compartment)

-- Catch the earliest possible bundle. Both server & client.
	if(p_Bundles[1] == "gameconfigurations/game" or p_Bundles[1] == "UI/Flow/Bundle/LoadingBundleMp") then 
	-- Mount your superbundle and bundles..

	Events:Dispatch('BundleMounter:LoadBundle', 'levels/sp_bank/sp_bank', {
		"levels/sp_bank/sp_bank",
		"weapons/gadgets/flashbang/flashbang_projectile_mesh",
		})
	end
end

function SmokeGrenade:OnExtensionUnloading()
	self:ResetVars()
end
function SmokeGrenade:OnLevelDestroyed()
	self:ResetVars()
end

function SmokeGrenade:OnLoadResources(p_MapName, p_GameModeName, p_DedicatedServer)
	self:ResetVars()
end

function SmokeGrenade:ResetVars()
	print("Resetting vars")
	customGrenade.soldierWeaponData = nil
	customGrenade.soldierWeaponBlueprint = nil
	customGrenade.weaponUnlockAsset = nil
	customGrenade.projectileBlueprint = nil
	customGrenade.grenadeEntityData = nil
	originalGrenade.weaponUnlockAsset = nil
end

function SmokeGrenade:OnInstanceLoaded(p_Partition, p_Instance)

	if p_Instance == nil then
		return
	end

	if p_Instance.typeInfo.name == "LevelData" then

		local a = LevelData(p_Instance)
		print("......................LevelData")
		print(a.name)
	end
	if p_Instance.typeInfo.name == "SubWorldData" then

		local a = SubWorldData(p_Instance)
		print("......................SubWorldData")
		print(a.name)
	end

	------------------------- HE grenade instances --------------------------

	-- We look for every original grenade instance before cloning the grenade, so we dont run into lazy loaded
	-- instances. Once every one of them is loaded we proceed to clone the weaponUnlockAsset down the path that
	-- leads to fields that contain values we want to modify (trailEffect, weapon ammo, mesh, projectile, etc)

	if p_Instance.instanceGuid == originalGrenade.weaponUnlockAssetGuid then
		local s_WeaponUnlockAsset = SoldierWeaponUnlockAsset(p_Instance)
		print('Found original grenade weaponUnlockAssetGuid')
		originalGrenade.weaponUnlockAsset = s_WeaponUnlockAsset
		originalGrenade.isWeaponUnlockAssetLoaded = true

		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == originalGrenade.soldierWeaponBlueprintGuid then
		print('Found original grenade soldierWeaponBlueprintGuid')
		originalGrenade.isSoldierWeaponBlueprintLoaded = true
		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == originalGrenade.soldierWeaponDataGuid then
		print('Found original grenade soldierWeaponDataGuid')
		originalGrenade.isSoldierWeaponDataLoaded = true
		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == originalGrenade.weaponFiringGuid then
		print('Found original grenade weaponFiringGuid')
		originalGrenade.isWeaponFiringLoaded = true
		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == originalGrenade.firingFunctionDataGuid then
		print('Found original grenade firingFunctionDataGuid')
		originalGrenade.isFiringFunctionDataLoaded = true
		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == originalGrenade.projectileBlueprintGuid then
		print('Found original grenade projectileBlueprintGuid')
		originalGrenade.isProjectileBlueprintLoaded = true
		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == originalGrenade.grenadeEntityDataGuid then
		print('Found original grenade grenadeEntityDataGuid')
		originalGrenade.isGrenadeEntityDataLoaded = true
		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end
	

	------------------------ RegistryContainer --------------------------

	-- Add new unlockAsset to RegistryContainer
	if p_Instance.typeInfo.name == "RegistryContainer" then
		local s_RegistryContainer = RegistryContainer(p_Instance)

		if s_RegistryContainer ~= nil then

			s_RegistryContainer:MakeWritable()

			if s_RegistryContainer.assetRegistry == nil or
					s_RegistryContainer.blueprintRegistry == nil or
					s_RegistryContainer.entityRegistry == nil then
				print("Registry fields are nil??")
				return
			end

			if customGrenade.weaponUnlockAsset ~= nil then
				s_RegistryContainer.assetRegistry:add(customGrenade.weaponUnlockAsset)
				print("WeaponUnlockAsset added to RegistryContainer ")
			else
				print("RegistryContainer loaded before WeaponUnlockAsset??")
			end

			if customGrenade.soldierWeaponBlueprint ~= nil then
				s_RegistryContainer.blueprintRegistry:add(customGrenade.soldierWeaponBlueprint)
				print("SoldierWeaponBlueprint added to RegistryContainer ")
			else
				print("RegistryContainer loaded before cloning SoldierWeaponBlueprint??")
			end

			if customGrenade.soldierWeaponData ~= nil then
				s_RegistryContainer.entityRegistry:add(customGrenade.soldierWeaponData)
				print("SoldierWeaponData added to RegistryContainer ")
			else
				print("RegistryContainer loaded before cloning SoldierWeaponData??")
			end

			if customGrenade.projectileBlueprint ~= nil then
				s_RegistryContainer.blueprintRegistry:add(customGrenade.projectileBlueprint)
				print("ProjectileBlueprint added to RegistryContainer ")
			else
				print("RegistryContainer loaded before cloning projectileBlueprint??")
			end


			if customGrenade.grenadeEntityData ~= nil then
				s_RegistryContainer.entityRegistry:add(customGrenade.grenadeEntityData)
				print("grenadeEntityData added to RegistryContainer ")
			else
				print("RegistryContainer loaded before cloning grenadeEntityData??")
			end

			-- Smoke grenade is finally cloned and added to registry.
			isSmokeGrenadeCloned = true
			-- self:ResetVars()
		end

		return
	end


	------------------------ Kits --------------------------
	-- Add new unlockAsset to kits (might not be necessary)
--[[    if p_Instance.typeInfo.name == "VeniceSoldierCustomizationAsset" then
		local s_VeniceSoldierCustomizationAsset = VeniceSoldierCustomizationAsset(p_Instance)
		if customGrenade.weaponUnlockAsset ~= nil then

			if s_VeniceSoldierCustomizationAsset ~= nil and s_VeniceSoldierCustomizationAsset.weaponTable ~= nil then
				local s_CustomizationTable = _G[s_VeniceSoldierCustomizationAsset.weaponTable.typeInfo.name](s_VeniceSoldierCustomizationAsset.weaponTable)

				-- Create CustomizationUnlockParts with the unlockAsset reference
				local s_CustomizationUnlockParts = CustomizationUnlockParts()

				s_CustomizationUnlockParts.selectableUnlocks:clear()
				s_CustomizationUnlockParts.selectableUnlocks:add(customGrenade.weaponUnlockAsset)

				--Add it to the CustomizationTable
				s_CustomizationTable:MakeWritable()
				s_CustomizationTable.unlockParts:add(s_CustomizationUnlockParts)
				print("Successfully added WeaponUnlockAsset to kit")
			end
		else
			print("Kit loaded before WeaponUnlockAsset??")
		end

		return
	end]]

	------------------------ Persistence --------------------------

	-- Add new unlockAsset to Persistence
--[[    if p_Instance.typeInfo.name == "StatsCategoryWeaponData" then
		local s_Instance = StatsCategoryWeaponData(p_Instance)
		-- print(a.nodeName)
		if s_Instance.nodeName == 'Explosives' then
			print("Found node")

			s_Instance:MakeWritable()

			local s_StatsCategoryWeaponData

			for _,v in pairs(s_Instance.baseSubCategories) do
				if v.nodeName == 'M67 Grenade' then
					print("Found grenade node, adding custom grenade guid")

					s_StatsCategoryWeaponData = m_DCExt:ShallowCopy(v)
					s_StatsCategoryWeaponData.objectInstanceGuids:clear()

					s_StatsCategoryWeaponData.objectInstanceGuids:add(customGrenade.guid)

					s_StatsCategoryWeaponData.soldierWeaponId = customGrenade.identifier
				end
			end

			if s_StatsCategoryWeaponData ~= nil then
				s_Instance.baseSubCategories:add(s_StatsCategoryWeaponData)
				print("Added custom node")
			end
		end

		return
	end]]

	------------------------ Smoke Effect --------------------------
	if p_Instance.instanceGuid == smoke.instanceGuid then
		print("Found smoke, saving")
		smoke.instance = p_Instance

		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end

	if p_Instance.instanceGuid == smoke.explosionGuid then
		print("Found smoke explosion")
		smoke.isExplosionLoaded = true

		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end
	if p_Instance.instanceGuid == smoke.meshGuid then
		print("Found smoke mesh")
		smoke.isMeshLoaded = true

		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end
	if p_Instance.instanceGuid == smoke.trailEffectGuid then
		print("Found smoke explosion")
		smoke.isTrailEffectLoaded = true

		if self:IsCloneReady() then self:CloneGrenade() end
		return
	end
end

function SmokeGrenade:IsCloneReady()
	return originalGrenade.isWeaponUnlockAssetLoaded and
			originalGrenade.isSoldierWeaponBlueprintLoaded and
			originalGrenade.isSoldierWeaponDataLoaded and
			originalGrenade.isWeaponFiringLoaded and
			originalGrenade.isFiringFunctionDataLoaded and
			originalGrenade.isProjectileBlueprintLoaded and
			originalGrenade.isGrenadeEntityDataLoaded and
			--smoke.isMeshLoaded and
			smoke.isTrailEffectLoaded and
			smoke.isExplosionLoaded and
			smoke.instance ~= nil and
	true
end

function SmokeGrenade:CloneGrenade()
	print("Ah shit, here we go again..")

	-- path: weaponUnlockAsset.weapon.object.weaponFiring.primaryFire.shot.projectile

	local s_WeaponUnlockAsset = m_DCExt:ShallowCopy(originalGrenade.weaponUnlockAsset, customGrenade.guid)

	s_WeaponUnlockAsset.name =                 'Weapons/M67/U_M67_Smoke'
	s_WeaponUnlockAsset.debugUnlockId =        "U_M67_Smoke"
	s_WeaponUnlockAsset.identifier =           customGrenade.identifier
	s_WeaponUnlockAsset.weaponIdentifier =     customGrenade.weaponIdentifier

	customGrenade.weaponUnlockAsset = s_WeaponUnlockAsset

	local s_SoldierWeaponBlueprint = m_DCExt:ShallowCopy(s_WeaponUnlockAsset.weapon, customGrenade.soldierWeaponBlueprintGuid)
	s_SoldierWeaponBlueprint.name = 'Weapons/M67/M67_Smoke'
	s_WeaponUnlockAsset.weapon = s_SoldierWeaponBlueprint
	customGrenade.soldierWeaponBlueprint = s_SoldierWeaponBlueprint

	local s_SoldierWeaponData = m_DCExt:ShallowCopy(s_SoldierWeaponBlueprint.object, customGrenade.soldierWeaponDataGuid)
	s_SoldierWeaponBlueprint.object = s_SoldierWeaponData
	customGrenade.soldierWeaponData = s_SoldierWeaponData

	local s_WeaponFiringData = m_DCExt:ShallowCopy(s_SoldierWeaponData.weaponFiring, customGrenade.weaponFiringGuid)
	s_SoldierWeaponData.weaponFiring = s_WeaponFiringData

	local s_FiringFunctionData = m_DCExt:ShallowCopy(s_WeaponFiringData.primaryFire, customGrenade.firingFunctionDataGuid)
	s_WeaponFiringData.primaryFire = s_FiringFunctionData

	local s_AmmoConfigData = s_FiringFunctionData.ammo
	--s_AmmoConfigData.autoReplenishMagazine = true
	s_AmmoConfigData.magazineCapacity = 5

	local s_ShotConfigData = s_FiringFunctionData.shot
	s_ShotConfigData = ShotConfigData(s_ShotConfigData)

	local s_ProjectileBlueprint = m_DCExt:ShallowCopy(s_ShotConfigData.projectile, customGrenade.projectileBlueprintGuid)
	s_ProjectileBlueprint.name = "Weapons/M67/M67_Projectile_Smoke"
	s_ShotConfigData.projectile = s_ProjectileBlueprint

	customGrenade.projectileBlueprint = s_ProjectileBlueprint

	local s_GrenadeEntityData = m_DCExt:ShallowCopy(s_ShotConfigData.projectileData, customGrenade.grenadeEntityDataGuid)
	customGrenade.grenadeEntityData = s_GrenadeEntityData

	local s_Smoke = _G[smoke.instance.typeInfo.name](smoke.instance)
	s_GrenadeEntityData.explosion = s_Smoke.explosion
	--s_GrenadeEntityData.mesh = s_Smoke.mesh
	s_GrenadeEntityData.trailEffect = s_Smoke.trailEffect

	s_ShotConfigData.projectileData = s_GrenadeEntityData
	s_ProjectileBlueprint.object = s_GrenadeEntityData
	--m_DCExt:PrintFields(s_WeaponUnlockAsset, 5)
	--m_DCExt:PrintFields(originalGrenade.weaponUnlockAsset, 5)


	-- Add instance to partition
	local s_Partition = ResourceManager:FindDatabasePartition(originalGrenade.partitionGuid)
	s_Partition:AddInstance(customGrenade.weaponUnlockAsset)
end

function SmokeGrenade:GetSmokeGrenadeInstance()
	return customGrenade.weaponUnlockAsset
end

return SmokeGrenade()