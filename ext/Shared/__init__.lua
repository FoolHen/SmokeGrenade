class 'shared'

local m_DCExt = require "__shared/Util/DataContainerExt"
local m_SmokeGrenade = require "__shared/SmokeGrenade"
local m_Spawn = require "__shared/Spawn"

local soldierAsset = nil
local soldierBlueprint = nil
local drPepper = nil

function shared:__init()
	print("Initializing shared __init")
	self:RegisterVars()
	self:RegisterEvents()
end


function shared:RegisterVars()
end


function shared:RegisterEvents()
	Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoaded)
	-- Events:Subscribe('Server:LevelLoaded', self, self.OnLevelLoaded)
	Events:Subscribe('Player:Chat', self, self.OnChat)
	Events:Subscribe('Level:LoadResources', self, self.OnLoadResources)
	Events:Subscribe('Extension:Unloading', self, self.OnExtensionUnloading)

	Events:Subscribe('Level:Destroy', self, self.OnLevelDestroyed)
	-- Hooks:Install('ResourceManager:LoadBundles',999, self, self.OnLoadBundles)
end

function shared:OnLoadBundles(p_Hook, p_Bundles, p_Compartment)
	m_SmokeGrenade:OnLoadBundles(p_Hook, p_Bundles, p_Compartment)
end


function shared:OnExtensionUnloading()
	m_SmokeGrenade:OnExtensionUnloading()
end
function shared:OnLevelDestroyed()
	m_SmokeGrenade:OnLevelDestroyed()
end

function shared:OnLoadResources(p_MapName, p_GameModeName, p_DedicatedServer)
	m_SmokeGrenade:OnLoadResources(p_MapName, p_GameModeName, p_DedicatedServer)
end

function shared:OnPartitionLoaded(p_Partition)
	if p_Partition == nil then
		print('Partition is nil')
		return
	end

	local s_Instances = p_Partition.instances

	for _, s_Instance in pairs(s_Instances) do
		if s_Instance ~= nil then
			m_SmokeGrenade:OnInstanceLoaded(p_Partition, s_Instance)
			m_Spawn:OnInstanceLoaded(p_Partition, s_Instance)
		end
	end
end

function shared:OnChat(player, recipientMask, message)
	m_Spawn:OnChat(player, recipientMask, message)
end

return shared()