GLOBAL.setfenv(1, GLOBAL)

local light_watcher_to_entity = {}

local function clean_up_mapping(inst)
    if inst.LightWatcher then
        light_watcher_to_entity[inst.LightWatcher] = nil
    end
end

local add_light_watcher = Entity.AddLightWatcher
function Entity:AddLightWatcher(...)
    local light_watcher = add_light_watcher(self, ...)

    local guid = self:GetGUID()
    local inst = Ents[guid]
    inst:AddComponent("lightwatcherproxy")
    light_watcher_to_entity[light_watcher] = inst
    inst:ListenForEvent("onremove", clean_up_mapping)

    return light_watcher
end

local get_light_value = LightWatcher.GetLightValue
LightWatcher.GetLightValue = function(self)
    local inst = light_watcher_to_entity[self]
    if inst:GetIsInInterior() then
        local x, y, z = inst.Transform:GetWorldPosition()
        return TheSim:GetLightAtPoint(x, y, z)
    else
        return get_light_value(self)
    end
end

local is_in_light = LightWatcher.IsInLight
LightWatcher.IsInLight = function(self)
    local inst = light_watcher_to_entity[self]
    if inst:GetIsInInterior() then
        return inst.components.lightwatcherproxy:IsInLight()
    else
        return is_in_light(self)
    end
end

local _SetDarkThresh = LightWatcher.SetDarkThresh
LightWatcher.SetDarkThresh = function(self, val, ...)
    local inst = light_watcher_to_entity[self]
    inst.components.lightwatcherproxy.darkthresh = val
    return _SetDarkThresh(self, val, ...)
end

local _SetLightThresh = LightWatcher.SetLightThresh
LightWatcher.SetLightThresh = function(self, val, ...)
    local inst = light_watcher_to_entity[self]
    inst.components.lightwatcherproxy.lightthresh = val
    return _SetLightThresh(self, val, ...)
end

local _GetTimeInLight = LightWatcher.GetTimeInLight
LightWatcher.GetTimeInLight = function(self, ...)
    local inst = light_watcher_to_entity[self]
    if inst:GetIsInInterior() then
        return inst.components.lightwatcherproxy:GetTimeInLight()
    else
        return _GetTimeInLight(self, ...)
    end
end

local _GetTimeInDark = LightWatcher.GetTimeInDark
LightWatcher.GetTimeInDark = function(self, ...)
    local inst = light_watcher_to_entity[self]
    if inst:GetIsInInterior() then
        return inst.components.lightwatcherproxy:GetTimeInDark()
    else
        return _GetTimeInDark(self, ...)
    end
end
