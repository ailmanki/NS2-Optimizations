
local kTechId          = kTechId
local kTechId_None     = kTechId.None
local kTechDataMapName = assert(kTechDataMapName)
local kTechDataId      = assert(kTechDataId)
local kTechData       = table.array(#kTechId)
local kMapNameTechId  = {}
local kTechCategories = table.array(#kTechId)
local tech_data_src = BuildTechData()

_G.kTechData = kTechData

for i = 1, #kTechId do
	kTechData[i] = false
end

for i = #tech_data_src, 1, -1 do
	local e = tech_data_src[i]
	local id = e[kTechDataId]
	kTechData[id] = e
	local map = e[kTechDataMapName]
	if map ~= nil then
		kMapNameTechId[map] = id
	end
	local category = e[kTechDataCategory]
	if category ~= nil then
		local t = kTechCategories[category] or {}
		kTechCategories[category] = t
		table.insert(t, id)
	end
	local cost = e[kTechDataCostKey]
	if cost ~= nil then
		e[kTechDataOriginalCostKey] = cost
	end
end

kTechData[kTechId.Web][kTechDataCostKey]         = kWebBuildCost
kTechData[kTechId.Web][kTechDataOriginalCostKey] = kWebBuildCost

local function set(f, v)
	setupvalue(f, "actual", v)
end

set(LookupTechId_NS2Opti, function(data, field)
	if field == kTechDataMapName then
		local v = kMapNameTechId[data]
		if v == nil then return kTechId_None
		else             return v
		end
	end
end)

set(LookupTechData_NS2Opti, function(id, field, default)
	local e = kTechData[id]
	if not e then return default end

	local v = e[field]
	if v == nil then
		return default
	else
		return v
	end
end)

set(GetTechForCategory, function(techId)
	local v = kTechCategories[techId]
	if v == nil then
		return {}
	else
		return v
	end
end)

function ZeroCosts()
	Shared.Message "Zeroing costs!"
	for i = 1, #kTechId do
		local cost = kTechData[i] and kTechData[i][kTechDataOriginalCostKey]
		if cost then
			kTechData[i][kTechDataCostKey] = 0
		end
	end
end

function RestoreCosts()
	Shared.Message "Restorings costs!"
	for i = 1, #kTechId do
		local cost = kTechData[i] and kTechData[i][kTechDataOriginalCostKey]
		if cost then
			kTechData[i][kTechDataCostKey] = cost
		end
	end
end

if TechData_Initial_InWarmUp then
	ZeroCosts()
end

local function disable(name)
	_G[name] = function()
		error(("'%s' has been disabled!"):format(name))
	end
end

GetCachedTechData = LookupTechData
disable "ClearCachedTechData"
disable "SetCachedTechData"
