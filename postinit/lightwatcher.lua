GLOBAL.setfenv(1, GLOBAL)

local DEFAULT_DARK_THRESHOLD = 0.05
local DEFAULT_LIGHT_THRESHOLD = 0.1

local function LightWatcher_OnUpdate(data)
    local inst = data.inst
    if not (inst and inst:IsValid()) then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local light_value = TheSim:GetLightAtPoint(x, y, z)
    if data.inlight then
        if light_value < data.darkthresh then
            data.inlight = false
        end
    else
        if light_value > data.lightthresh then
            data.inlight = true
        end
    end
end

local function LightWatcher_fn(data, inst)
    data.inst = inst
    data.darkthresh = DEFAULT_DARK_THRESHOLD
    data.lightthresh = DEFAULT_LIGHT_THRESHOLD
    data.inlight = true
    data.OnUpdate = LightWatcher_OnUpdate
end

_AddLightWatcher = Entity.AddLightWatcher
function Entity:AddLightWatcher(...)
	local guid = self:GetGUID()
	local inst = Ents[guid]
    if not inst or not inst:IsValid() or inst.LightWatcher then return _AddLightWatcher(self, ...) end

	local lightwatcher = _AddLightWatcher(self, ...)
    local _lightwatcher_engine_ent = CreateEngineHookData(lightwatcher, inst, LightWatcher_fn)

    local _lightwatcher = getmetatable(lightwatcher).__index

    local old_GetLightValue = _lightwatcher.GetLightValue
    _lightwatcher.GetLightValue = function(self)
        local data = GetEngineHookData(self)
        local inst = data.inst
        local x, y, z = inst.Transform:GetWorldPosition()
        return TheSim:GetLightAtPoint(x, y, z)
    end

    _lightwatcher.IsInLight = function(self)
        local data = GetEngineHookData(self)
        if GetEngineHookData(self):IsUpdating() then
            return data.inlight
        else
            return self:GetLightValue() >= data.darkthresh
        end
    end

    _lightwatcher.SetDarkThresh = function(self, val)
        local data = GetEngineHookData(self)
        data.darkthresh = val
    end

    _lightwatcher.SetLightThresh = function(self, val)
        local data = GetEngineHookData(self)
        data.lightthresh = val
    end

    _lightwatcher.EnableUpdate = function(self, enable)
        local data = GetEngineHookData(self)
        data:EnableUpdate(enable)
    end
end
