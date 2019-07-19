class "DataContainerExt"

local stringExtensions = require "__shared/Util/StringExtensions"

local m_PrintedObjects = nil
local m_CopiedObjects = nil

function DataContainerExt:PrepareInstanceForEdit(p_Partition, p_Instance)
	if p_Partition == nil then
		error('Parameter p_Partition was nil. Instance type: ' .. p_Instance.typeInfo.name)
		return
	end

	if p_Instance == nil then
		error('Parameter p_Instance was nil.')
		return
	end

	if p_Instance.isLazyLoaded then
		error('The instance is being lazy loaded, thus it can\'t be prepared for editing. Instance type: "' .. p_Instance.typeInfo.name)-- maybe add callstack
		return _G[p_Instance.typeInfo.name](p_Instance)
	end

	if p_Instance.isReadOnly == nil then
		-- If .isReadOnly is nil it means that its not a DataContainer, it's a Structure. We return it casted
		print('The instance '..p_Instance.typeInfo.name.." is not a DataContainer, it's a Structure")
		return _G[p_Instance.typeInfo.name](p_Instance)
	end

	if not p_Instance.isReadOnly then
		return _G[p_Instance.typeInfo.name](p_Instance)
	end

	if p_Instance.instanceGuid == nil then
		error(' .instanceGuid is nil. Instance type: ' .. p_Instance.typeInfo.name)

		return nil
	end

	local s_Clone = p_Instance:Clone(p_Instance.instanceGuid)

	p_Partition:ReplaceInstance(p_Instance, s_Clone, true)

	local s_CastedClone = _G[s_Clone.typeInfo.name](s_Clone)

	if s_CastedClone ~= nil and s_CastedClone.typeInfo.name ~= s_Clone.typeInfo.name then
		error('Failed to prepare instance of type ' .. s_Clone.typeInfo.name)
		return nil
	end

	-- NOTE: if something is crashing this print can be useful to track it. Check if the latest output is this print and what instance it is
	-- print('Cloned instance '..p_Instance.typeInfo.name..", instance guid: "..tostring(p_Instance.instanceGuid))
	
	return s_CastedClone
end


function DataContainerExt:ShallowCopy(p_Instance, p_Guid)
	p_Guid = p_Guid or GenerateGuid()
	if p_Instance == nil then
		error('Parameter p_Instance was nil.')
		return
	end

	if p_Instance.isLazyLoaded then
		error('The instance is being lazy loaded, thus it can\'t be prepared for editing. Instance type: "' .. p_Instance.typeInfo.name)-- maybe add callstack
		return _G[p_Instance.typeInfo.name](p_Instance)
	end

	if p_Instance.isReadOnly == nil then
		-- If .isReadOnly is nil it means that its not a DataContainer, it's a Structure. We return it casted
		print('The instance '..p_Instance.typeInfo.name.." is not a DataContainer, it's a Structure")
		return _G[p_Instance.typeInfo.name](p_Instance)
	end

	if p_Instance.instanceGuid == nil then
		error('Instance.instanceGuid is nil. Instance type: ' .. p_Instance.typeInfo.name)

		return nil
	end

	local s_Clone = p_Instance:Clone(p_Guid)

	local s_CastedClone = _G[s_Clone.typeInfo.name](s_Clone)

	if s_CastedClone ~= nil and s_CastedClone.typeInfo.name ~= s_Clone.typeInfo.name then
		error('PrepareInstanceForEdit() - Failed to prepare instance of type ' .. s_Clone.typeInfo.name)
		return nil
	end

	-- NOTE: if something is crashing this print can be useful to track it. Check if the latest output is this print and what instance it is
	-- print('Cloned instance '..p_Instance.typeInfo.name..", instance guid: "..tostring(p_Instance.instanceGuid))
	
	return s_CastedClone
end

function DataContainerExt:FindLazyLoadedFields(p_Instance, p_Guid)
	p_Instance = _G[p_Instance.typeInfo.name](p_Instance)


	local s_TypeInfo = p_Instance.typeInfo

	-- We copy all fields
	local s_Fields = getFields(s_TypeInfo)
	for _, field in ipairs(s_Fields) do

		if field.typeInfo ~= nil then

			local s_Name = field.name:firstToLower()

			if field.typeInfo.array then

			elseif isPrintable(field.typeInfo.name) or field.typeInfo.enum then

			else
				if p_Instance[s_Name] ~= nil then
					if p_Instance[s_Name].instanceGuid ~= nil then
						if p_Instance[s_Name].isLazyLoaded then
							print("[FindLazyLoadedFields] Found lazy loaded field, name: "..s_Name..", intance: "..tostring(p_Instance[s_Name].instanceGuid)..", partition: "..tostring(p_Instance[s_Name].partitionGuid))
						end
					end
				end
			end
		else
			print("typeInfo nil ?")
		end

		::continue::
	end
end

function DataContainerExt:DeepCopy(p_Instance, p_CurrentDepth)
	p_CurrentDepth = p_CurrentDepth or 0

	if p_Instance == nil then
		error("instance nil")
		return
	end

	if m_CopiedObjects == nil then
		m_CopiedObjects = {}
	end

	local s_Clone = _G[p_Instance.typeInfo.name](p_Instance)

	-- Shallow copy p_Instance if it's a DataContainer, ignore if it's a structure
	if p_Instance.instanceGuid ~= nil then
		if p_Instance.isLazyLoaded then
			print("Instance is lazy loaded")
			return
		end
	
		if m_CopiedObjects[tostring(p_Instance.instanceGuid)] ~= nil then
			return m_CopiedObjects[tostring(p_Instance.instanceGuid)]
		end

		s_Clone = self:ShallowCopy(p_Instance)

		if s_Clone == nil then
			return
		end

		m_CopiedObjects[tostring(p_Instance.instanceGuid)] = s_Clone
	end
	
	local s_TypeInfo = p_Instance.typeInfo

	-- We look for fields that are DCs to clone them
	local s_Fields = getFields(s_TypeInfo)
	for _, field in ipairs(s_Fields) do

		if field.typeInfo ~= nil then

			local s_Name = field.name:firstToLower()

			if field.typeInfo.array then

				local s_Array = p_Instance[s_Name]
				if(s_Array~= nil) then
					for i = #s_Array, 1, -1 do
						local s_Member = s_Array[i]
						if s_Member ~= nil and not isPrintable(field.typeInfo.elementType.name) and not field.typeInfo.elementType.enum then
							-- Filter  DataContainer
							if s_Member.typeInfo.name ~= "DataContainer" then
								s_Clone[s_Name][i] = self:DeepCopy(s_Member, p_CurrentDepth + 1)
							end
						end
					end
				end
			-- It's an object
			elseif not isPrintable(field.typeInfo.name) and not field.typeInfo.enum then
				if p_Instance[s_Name] ~= nil then
					-- Filter  DataContainer
					if field.typeInfo.name ~= "DataContainer" then
						s_Clone[s_Name] = self:DeepCopy(p_Instance[s_Name], p_CurrentDepth + 1)
					end
				end
			end
		else
			print("typeInfo nil ?")
		end

		::continue::
	end

	if p_CurrentDepth == 0 then
		m_CopiedObjects = nil
	end

	return s_Clone
end


function DataContainerExt:MakeWritable(p_Instance)
	if p_Instance == nil then
		error('Parameter p_Instance was nil.')
		return
	end

	local s_Instance = _G[p_Instance.typeInfo.name](p_Instance)

	if p_Instance.isReadOnly == nil then
		-- If .isReadOnly is nil it means that its not a DataContainer, it's a Structure. We return it casted
		print('The instance '..p_Instance.typeInfo.name.." is not a DataContainer, it's a Structure")
		return s_Instance
	end

	if not p_Instance.isReadOnly then
		return s_Instance
	end

	s_Instance:MakeWritable()

	return s_Instance
end

function DataContainerExt:PrintFields(p_Instance, p_MaxDepth, p_Padding)
	if p_Instance == nil then
		error("instance nil")
		return
	end

	local s_TypeInfo = p_Instance.typeInfo

	if s_TypeInfo == nil then
		error("typeInfo nil")
		return
	end

	self:PrintFieldsInt(p_Instance, s_TypeInfo, p_Padding, 0, p_MaxDepth, nil)
end


-- Prints all members and child members of a given instance. Useful for debugging.
function DataContainerExt:PrintFieldsInt(p_Instance, p_TypeInfo, p_Padding, p_CurrentDepth, p_MaxDepth, p_FieldName)
-- local _PrintFields = function(p_Instance, p_TypeInfo, p_Padding, p_CurrentDepth, p_MaxDepth, p_FieldName)
	if p_Instance == nil then
		error("instance nil")
		return
	end

	p_TypeInfo = p_TypeInfo or p_Instance.typeInfo

	if p_TypeInfo == nil then
		error("typeInfo nil")
		return
	end

	if m_PrintedObjects == nil then
		m_PrintedObjects = {}
	end

	if p_FieldName == nil then
		p_FieldName = ""
	elseif p_FieldName ~= "" then
		p_FieldName = tostring(p_FieldName) .. " "
	end

	if p_CurrentDepth == nil then
		p_CurrentDepth = 0
	end

	if p_MaxDepth == nil then
		p_MaxDepth = -1
	end

	if(p_Padding == nil) then
		p_Padding = ""
	end

	if string.match(p_TypeInfo.name:lower(), "voice") or
		 string.match(p_TypeInfo.name:lower(), "sound") or
		 p_TypeInfo == MaterialContainerPair.typeInfo or
		 p_TypeInfo == MaterialContainerAsset.typeInfo then
		return
	end

	local p_Instance = _G[p_Instance.typeInfo.name](p_Instance)

	-- If it has a guid its an object, otherwise its a structure
	if p_Instance.instanceGuid == nil then
		print(p_Padding ..p_FieldName..'(Structure - '..p_TypeInfo.name..') {')
	else
		-- Not print it if we already printed this object
		if(m_PrintedObjects[tostring(p_Instance.instanceGuid)] ~= nil) then
			print(p_Padding ..p_FieldName..'(Object - '..p_TypeInfo.name..') instanceGuid: '.. tostring(p_Instance.instanceGuid).. ' (Printed above) {')
			return
		else
			m_PrintedObjects[tostring(p_Instance.instanceGuid)] = true
		end

		local s_LazyLoadedWarning = ''

		if p_Instance.isLazyLoaded then
			s_LazyLoadedWarning = 'LAZYLOADED!'
		end

		print(p_Padding ..p_FieldName..'(Object - '..p_TypeInfo.name..') instanceGuid: '.. tostring(p_Instance.instanceGuid).. ' '..s_LazyLoadedWarning..'{')
	end

	--Stop if we have reached max depth
	if p_MaxDepth ~= -1 and p_CurrentDepth > p_MaxDepth then
		return
	end

	p_Padding = p_Padding .. "  "

	local s_Fields = getFields(p_TypeInfo)
	for _, field in ipairs(s_Fields) do

		if field.typeInfo == nil then
			print("field.typeInfo == nil")
			goto continue
		elseif field.name == "MaterialPairs" then
			print("MaterialPairs isn't supported, ignoring.")
			goto continue
		end

		local s_Name = field.name:firstToLower()

		if isPrintable(field.typeInfo.name) then
			local s_Value = p_Instance[s_Name]
			print(p_Padding ..field.name..' ('..field.typeInfo.name..') : '.. tostring(s_Value))

		--Array
		elseif field.typeInfo.array then
			local s_Array = p_Instance[s_Name]

			if s_Array == nil then
				print(p_Padding ..field.name..' (Array), nil')
			else
				print(p_Padding ..field.name..' (Array), '..tostring(#s_Array)..' Members {')
				for i = 1, #s_Array, 1 do
					local s_Member = s_Array[i]

					if s_Member == nil then
						goto continue1
					end

					if isPrintable(field.typeInfo.elementType.name) then
						print(p_Padding .."[" .. i .. "] "..' ('..field.typeInfo.elementType.name..') : '.. tostring(s_Member))
					elseif field.typeInfo.elementType.enum then
						print(p_Padding .."[" .. i .. "] "..' (Enum) : '.. tostring(s_Member))
					else
						self:PrintFieldsInt(s_Member, s_Member.typeInfo, p_Padding, p_CurrentDepth + 1, p_MaxDepth)
					end

					::continue1::
				end

				print(p_Padding .. "}")
			end
			
		--Enum
		elseif field.typeInfo.enum then
			local s_Value = p_Instance[s_Name]
			print(p_Padding..field.name..' (Enum) : ' .. tostring(s_Value))

		--Object or Structure
		else
			if p_Instance[s_Name] ~= nil then
				-- local s_Value = p_Instance[s_Name]
				local i = _G[field.typeInfo.name](p_Instance[s_Name])
				if i ~= nil then
					-- p_Padding = p_Padding .. "	"
					self:PrintFieldsInt( i, i.typeInfo, p_Padding, p_CurrentDepth + 1, p_MaxDepth, field.name)
				end
			else
				print(p_Padding ..field.name..' (Object - '..field.typeInfo.name..') nil')
			end
		end

		::continue::
	end

	print (p_Padding:sub(1, -3) .. "}")

	-- Clear printed objects
	if p_CurrentDepth == 0 then
		m_PrintedObjects = nil
	end
end

-- Prints all members and child members of a given instance. Useful for debugging.
function DataContainerExt:PrintFieldsPow( instance, typeInfo, padding, currentDepth, maxDepth, parentField)
	if(instance.instanceGuid == nil) then
		print("FUCKING WHAT")
		return
	end
	if(instance.isLazyLoaded) then
		print("LazyLoaded sorri")
		return
	end
	
	-- if(self.m_Parsed[tostring(instance.instanceGuid)] ~= nil) then
	-- 	return
	-- else
	-- 	self.m_Parsed[tostring(instance.instanceGuid)] = true
	-- end
	if(currentDepth == nil) then
		currentDepth = 0
	end
	if(string.match(typeInfo.name:lower(), "voice") or string.match(typeInfo.name:lower(), "sound") or typeInfo == MaterialContainerPair.typeInfo or typeInfo == MaterialContainerAsset.typeInfo) then
		return
	end

	if(maxDepth == nil) then
		maxDepth = -1
	else
		if(maxDepth ~= -1 and currentDepth > maxDepth) then
			return
		end
	end

	if(typeInfo == nil) then
		print("No typeInfo???")
	end



	currentDepth = currentDepth + 1

	if(padding == nil) then
		padding = ""
	end 
	if(parentField ~= nil) then
		print(padding ..parentField.name..' (object - '..parentField.typeInfo.name..') '.. typeInfo.name .. ' {')

	else
		print(padding .. typeInfo.name .. ' {' .. tostring(instance.instanceGuid))
	end

	padding = padding .. "|"

	local s_Fields = getFields(typeInfo)
	for _, field in pairs(s_Fields) do
		if field.typeInfo ~= nil and field.name ~= "MaterialPairs" then

			local s_Name = FirstToLower(field.name)

			--Value that can be printed 
			--NOTE: these arent all possible types
			if isPrintable(field.typeInfo.name) then

				local s_Value = instance[s_Name]

				print(padding ..field.name..' ('..field.typeInfo.name..') : '.. tostring(s_Value))

			--Array
			elseif field.typeInfo.array and field.name ~= "MaterialPairs" then
				-- So UIBundlesAsset[uIBundleAssetStateList] returns nil even though it's not??
				if(instance[FirstToLower(field.name)] ~= nil) then
					local s_Count = #instance[FirstToLower(field.name)]
					print(padding ..field.name..' (Array), '..tostring(s_Count)..' Members {')

					if s_Count ~= 0 then
						s_Count = s_Count

						for i=1,s_Count,1 do 
							if(field == nil) then
								print("What the fuck")
								print(field.name .. " | " .. instance.typeInfo.name .. " | " .. tostring(instance.instanceGuid))
							else
								if isPrintable(field.typeInfo.elementType.name) or field.typeInfo.elementType.enum then
									print(padding .. "[" .. i .. "] " ..tostring(instance[FirstToLower(field.name)]:get(i)))
								else
									if(instance[FirstToLower(field.name)]:get(i).instanceGuid == nil) then
										print(padding .. "[" .. i .. "] " .."nil")
									elseif(instance[FirstToLower(field.name)]:get(i).isLazyLoaded) then
										print(padding .. "[" .. i .. "] " .."isLazyLoaded")
									else
										local s_MemberInstance = instance[FirstToLower(field.name)]:get(i)
										local s_Member = _G[s_MemberInstance.typeInfo.name](s_MemberInstance)

										if s_Member ~= nil then
											self:PrintFieldsPow(s_Member, s_Member.typeInfo, padding, currentDepth, maxDepth)
										end
									end
								end
							end
						end
					end
					print(padding .. "}")
				end
			--Enum
			elseif field.typeInfo.enum then
				local s_Value = instance[s_Name]
				print(padding..field.name..' (Enum) : ' .. tostring(s_Value))
			elseif field.typeInfo.name == "Guid" then
				local s_Value = instance[s_Name]
				print(padding..field.name..' (Guid) : ' .. tostring(s_Value))
			--Object
			else
				print(padding..s_Name .. " | " .. tostring(instance.instanceGuid))
				if instance[s_Name] ~= nil then 
					if(instance[s_Name].isLazyLoaded) then
						print(padding ..field.name..' (object - '..field.typeInfo.name..') '.. 'isLazyLoaded')
					else
						-- local s_Value = instance[s_Name]
						print(instance[s_Name].typeInfo.name)
						local i = _G[instance[s_Name].typeInfo.name](instance[s_Name])
						if i ~= nil then
							self:PrintFieldsPow( i, i.typeInfo, padding, currentDepth, maxDepth, field) 
						else
							print(padding ..field.name..' (object - '..field.typeInfo.name..') '.. 'nil')
						end
					end
				else
					print(padding ..field.name..' (Object - '..field.typeInfo.name..') ' .."nil")
				end
			end
		end
	end

	-- if typeInfo.super ~= nil then
	-- 	if typeInfo.super.name ~= "DataContainer" then
	-- 		local i = _G[typeInfo.super.name]()
	-- 		self:PrintFieldsPow( i, i.typeInfo, padding, currentDepth, maxDepth, typeInfo.super.name) 
	-- 	end
	-- end
	print (padding:sub(1, -2) .. "}")
end

function FirstToLower(str)
	return (str:gsub("^%L", string.lower))
end

function getFields( typeInfo )
	local s_Super = {}
	if typeInfo.super ~= nil then
		if typeInfo.super.name ~= "DataContainer" then
			for k,superv in pairs(getFields(typeInfo.super)) do
				table.insert(s_Super, superv)
			end
		end
	end
	for k,v in pairs(typeInfo.fields) do
		table.insert(s_Super, v)
	end
	return s_Super
end

function isPrintable( typ )
	if typ == "CString" or
	typ == "Float8" or
	typ == "Float16" or
	typ == "Float32" or
	typ == "Float64" or
	typ == "Int8" or
	typ == "Int16" or
	typ == "Int32" or
	typ == "Int64" or
	typ == "Uint8" or
	typ == "Uint16" or
	typ == "Uint32" or
	typ == "Uint64" or
	typ == "LinearTransform" or
	typ == "Vec2" or
	typ == "Vec3" or
	typ == "Vec4" or
	typ == "Boolean" or 
	typ == "Guid" then
		return true
	end
	return false
end

function h()
	local vars = {"A","B","C","D","E","F","0","1","2","3","4","5","6","7","8","9"}
	return vars[math.floor(MathUtils:GetRandomInt(1,16))]..vars[math.floor(MathUtils:GetRandomInt(1,16))]
end

-- Generates a random guid.
function GenerateGuid()
	return Guid(h()..h()..h()..h().."-"..h()..h().."-"..h()..h().."-"..h()..h().."-"..h()..h()..h()..h()..h()..h(), "D")
end

return DataContainerExt()