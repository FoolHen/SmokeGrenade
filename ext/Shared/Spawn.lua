class 'Spawn'

local soldierAsset = nil
local soldierBlueprint = nil
local drPepper = nil


function Spawn:OnInstanceLoaded(p_Partition, p_Instance)

	if p_Instance == nil then
		return
	end

	------------------------- Assets for spawning --------------------------

	if p_Instance.typeInfo.name == 'VeniceSoldierCustomizationAsset' then
		local asset = VeniceSoldierCustomizationAsset(p_Instance)

		if asset.name == 'Gameplay/Kits/RURecon' then
			print('Found soldier customization asset ' .. asset.name)
			soldierAsset = asset
		end
	end

	if p_Instance.typeInfo.name == 'SoldierBlueprint' then
		soldierBlueprint = SoldierBlueprint(p_Instance)
		print('Found soldier blueprint ' .. soldierBlueprint.name)
	end


	if p_Instance.typeInfo.name == 'UnlockAsset' then
		local asset = UnlockAsset(p_Instance)

		if asset.name == 'Persistence/Unlocks/Soldiers/Visual/MP/RU/MP_RU_Recon_Appearance_DrPepper' then
			print('Found appearance asset ' .. asset.name)
			drPepper = asset
		end
	end

end

function Spawn:OnChat(player, recipientMask, message)
	if message == '' then
		return
	end

	print('Chat: ' .. message)

	local parts = message:split(' ')

	if parts[1] == 'spawn' then
		self:SpawnPlayer(player)
	end
end

function Spawn:SpawnPlayer(player)
	if player == nil or player.soldier ~= nil then
		print('Player must be dead to spawn')
		return
	end

	local transform = LinearTransform(
		Vec3(1, 0, 0),
		Vec3(0, 1, 0),
		Vec3(0, 0, 1),
		Vec3(0, 16, 0)
	)

	local originalNadeUnlockAsset = ResourceManager:FindInstanceByGUID(Guid("31EBAC8C-F32E-11DF-8153-F8368A2EF9E0"), Guid("9f789f05-ce7b-dadc-87d7-16e847dbdd09"))
	local customNadeUnlockAsset = ResourceManager:FindInstanceByGUID(Guid("31EBAC8C-F32E-11DF-8153-F8368A2EF9E0", "D"), Guid("6E52C5D6-0000-9B70-22AB-E3DC4613D1B7"))

	print('Setting soldier primary weapon')
	-- print(customGrenade.weaponUnlockAsset.name)

	player:SelectWeapon(WeaponSlot.WeaponSlot_0, customNadeUnlockAsset, {  })
	player:SelectWeapon(WeaponSlot.WeaponSlot_1, originalNadeUnlockAsset, {  })

	print('Setting soldier class and appearance')
	player:SelectUnlockAssets(soldierAsset, { drPepper })

	print('Creating soldier')
	local soldier = player:CreateSoldier(soldierBlueprint, transform)

	if soldier == nil then
		print('Failed to create player soldier')
		return
	end

	print('Spawning soldier')
	player:SpawnSoldierAt(soldier, transform, CharacterPoseType.CharacterPoseType_Stand)

	print('Soldier spawned')
end

return Spawn()