GLOBAL.setfenv(1, GLOBAL)

local Replicas = ToolUtil.GetUpvalue(EntityScript.ReplicateComponent, "Replicas")
local REPLICATABLE_COMPONENTS = ToolUtil.GetUpvalue(EntityScript.ReplicateEntity, "REPLICATABLE_COMPONENTS")
local LoadComponent = ToolUtil.GetUpvalue(EntityScript.AddComponent, "LoadComponent")

function EntityScript:SetReplaceReplicableComponent(replace_component, component)
    if not self.replace_components then
        self.replace_components = {}
    end

    self.replace_components[component] = replace_component
end

function EntityScript:AddReplaceComponent(replace_component, name)
    local lower_name = string.lower(name)
    if self.lower_components_shadow[lower_name] ~= nil then
        print("component ".. name .. " already exists on entity " .. tostring(self) .. "!" .. debugstack_oneline(3))
    end

    local cmp = LoadComponent(replace_component)
    if not cmp then
        moderror("component ".. replace_component .. " does not exist!")
    end

    self:ReplicateComponent(name)
    local loadedcmp = cmp(self)
    self.components[name] = loadedcmp
    self.lower_components_shadow[lower_name] = true

    local postinitfns = ModManager:GetPostInitFns("ComponentPostInit", replace_component)

    for i, fn in ipairs(postinitfns) do
        fn(loadedcmp, self)
    end

    self:RegisterComponentActions(name)

    return loadedcmp
end

local _ReplicateComponent = EntityScript.ReplicateComponent
function EntityScript:ReplicateComponent(component, ...)
    if not self.replace_components or self.replace_components[component] == nil then
        return _ReplicateComponent(self, component, ...)
    end

    local replace_component = self.replace_components[component]

    local filename = component .. "_replica"
    local replace_filename = replace_component .. "_replica"

    local cmp = Replicas[filename]
    local replicatable = REPLICATABLE_COMPONENTS[component]

    if Replicas[replace_filename] == nil then
        Replicas[replace_filename] = require("components/" .. replace_filename)
    end
    REPLICATABLE_COMPONENTS[component] = REPLICATABLE_COMPONENTS[replace_component]
    Replicas[filename] = Replicas[replace_filename]

    _ReplicateComponent(self, component, ...)

    REPLICATABLE_COMPONENTS[component] = replicatable
    Replicas[filename] = cmp
end

---@class entityscript
---@field pushevent_postfn table

---@param event string
---@param data any
function SilenceEvent(event, data, ...)
    return event .. "_silenced", data
end

---@param event string
---@param fn function
---@param source entityscript | nil
function EntityScript:AddPushEventPostFn(event, fn, source)
    source = source or self

    if not source.pushevent_postfn then
        source.pushevent_postfn = {}
    end

    source.pushevent_postfn[event] = fn
end

local _PushEvent = EntityScript.PushEvent
function EntityScript:PushEvent(event, data, ...)
    local eventfn = self.pushevent_postfn ~= nil and self.pushevent_postfn[event] or nil

    if eventfn ~= nil then
        local newevent, newdata = eventfn(event, data, ...)

        if newevent ~= nil then
            event = newevent
        end
        if newdata ~= nil then
            data = newdata
        end
    end

    _PushEvent(self, event, data, ...)
end

---@param event string
---@param source entityscript | nil
---@param source_file string | nil
function EntityScript:GetEventCallbacks(event, source, source_file)
    source = source or self

    assert(self.event_listening[event] and self.event_listening[event][source])

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and (info.source == source_file) then
                return fn
            end
        else
            return fn
        end
    end
end

function EntityScript:IsSailing()
    return (self.components.sailor ~= nil and self.components.sailor:IsSailing())
        or (self:HasTag("sailing") and self:HasTag("_sailor"))
end
