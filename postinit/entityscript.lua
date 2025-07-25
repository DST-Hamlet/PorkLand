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
function EntityScript:GetEventCallbacks(event, source, source_file, test_fn)
    source = source or self

    if not self.event_listening[event] or not self.event_listening[event][source] then
        return
    end

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and (info.source == source_file) and (not test_fn or test_fn(fn)) then
                return fn
            end
        elseif (not test_fn or test_fn(fn)) then
            return fn
        end
    end
end

function EntityScript:IsSailing()
    return (self.components.sailor ~= nil and self.components.sailor:IsSailing())
        or (self:HasTag("sailing") and self:HasTag("_sailor"))
end

function EntityScript:CanOnWater(allow_invincible)
    return self.components.amphibiouscreature ~= nil
        or (self.components.locomotor == nil or self.components.locomotor:CanPathfindOnWater())
        or self:HasTag("flying")
        or self:HasTag("ignorewalkableplatformdrowning")
        or self:HasTag("shadow")
        or self:HasTag("shadowminion")
        or (self:HasTag("player") and (self.components.drownable == nil or not self.components.drownable:CanDrownOverWater(allow_invincible)))
end

function EntityScript:CanOnLand(allow_invincible)
    return self.components.amphibiouscreature ~= nil
        or (self.components.locomotor == nil or self.components.locomotor:CanPathfindOnLand())
        or (self:HasTag("player") and self.components.drydrownable == nil or self.components.drydrownable ~= nil and not self.components.drydrownable:CanDrownOverLand(allow_invincible))
end

function EntityScript:CanOnImpassable(allow_invincible)
    return self:HasTag("shadow")
end

-- Returns the interiorID of the room this entity is in
function EntityScript:GetCurrentInteriorID() -- 亚丹：请暂时不要在客机使用这个函数
    if not self:IsValid() then
        return
    end
    local x, _, z = self.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        local interiorID = TheWorld.components.interiorspawner:PositionToIndex({x = x, z = z})
        return TheWorld.components.interiorspawner.interiors[interiorID] and interiorID
    end
end

function EntityScript:GetIsInInterior()
    if not self:IsValid() then
        return false
    end
    local x, _, z = self.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return true
    end
    return false
end

function EntityScript:Play2DSoundOutSide(path, soundname, distance, paramname, paramval)
    if not soundname then
        print("WARNING: EntityScript:Play2DSoundOutSide must have soundname")
    end
    if TheWorld.ismastersim then
        local pos = self:GetPosition()
        local followentity = self
        local areamode = AREAMODES.DISTANCE
        TheWorld.components.worldsoundmanager:PlayWorldSound(path, soundname, paramname, paramval, pos, followentity, areamode, distance)
    end
end

function EntityScript:Kill2DSound(soundname)
    if TheWorld.ismastersim then
        TheWorld.components.worldsoundmanager:KillWorldSound(self, soundname)
    end
end

function EntityScript:GetCurrentAnimation()
    local debug_string = self.entity:GetDebugString()
    if debug_string then
        return string.match(debug_string, "anim:%s+(%S+)%s+")
    end
end

function EntityScript:GetCurrentBank()
    local debug_string = self.entity:GetDebugString()
    if debug_string then
        return string.match(debug_string, "bank:%s+(%S+)%s+")
    end
end

local _GetIsWet = EntityScript.GetIsWet
function EntityScript:GetIsWet(...) -- 危险的写法
    local ret
    if self:GetIsInInterior() then
        local _iswet = TheWorld.state.iswet
        TheWorld.state.iswet = false
        ret = _GetIsWet(self, ...)
        TheWorld.state.iswet = _iswet
    else
        ret = _GetIsWet(self, ...)
    end

    return ret or self:HasTag("temporary_wet")
end

function EntityScript:GetShouldBrainStopped()
    local stopped = false
    if self.components.freezable and self.components.freezable:IsFrozen() then
        stopped = true
    end
    if self.components.sleeper and self.components.sleeper:IsAsleep() then
        stopped = true
    end
    return stopped
end

local _RestartBrain = EntityScript.RestartBrain
function EntityScript:RestartBrain(...)
    if self:GetShouldBrainStopped() then
        self:StopBrain()
        if self.brainfn ~= nil then
            self.brain = self.brainfn()
            if self.brain ~= nil then
                self.brain.inst = self
                self.brain:Stop()
            end
        end
        return
    end
    return _RestartBrain(self, ...)
end

local _GetAdjectivedName = EntityScript.GetAdjectivedName
function EntityScript:GetAdjectivedName(...)
    local name = self:GetBasicDisplayName()
    if self:HasTag("mystery") then
        name = ConstructAdjectivedName(self, name, STRINGS.MYSTERIOUS)
        return name
    end
    return _GetAdjectivedName(self, ...)
end

local _Remove = EntityScript.Remove
function EntityScript:Remove(...)
    if self.SoundEmitter then
        self.SoundEmitter:KillAllSounds()
    end
    return _Remove(self, ...)
end

function EntityScript:IsInSameIsland(target)
    if not (target and target:IsValid()) then
        return false
    end

    local x, _, z = self.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()

    local current_island = TheWorld.Map:GetIslandTagAtPoint(x, 0, z)
    local target_island = TheWorld.Map:GetIslandTagAtPoint(tx, ty, tz)

    return (current_island ~= nil) and current_island == target_island
end

function EntityScript:RunOnPostUpdate(fn)
    RunOnPostUpdate(function()
        if self:IsValid() then
            fn(self)
        end
    end)
end

function EntityScript:GetLightColour()
    local x, y, z = self.Transform:GetWorldPosition()
    local position = Vector3(x, y, z)

    local sum_r, sum_g, sum_b = 0, 0, 0
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"})) do
        if v ~= self and v.Light and v.Light:IsEnabled() then
            local _r, _g, _b = CalculateLight(v.Light, math.sqrt(v:GetPosition():DistSq(position)))
            sum_r = sum_r + _r
            sum_g = sum_g + _g
            sum_b = sum_b + _b
        end
    end
    if not self:GetIsInInterior() then
        local _r, _g, _b = TheSim:GetAmbientColour()
        sum_r = sum_r + _r / 255
        sum_g = sum_g + _g / 255
        sum_b = sum_b + _b / 255
    end

    return sum_r, sum_g, sum_b, 0.2126 * sum_r + 0.7152 * sum_g + 0.0722 * sum_b
end

function EntityScript:GetCurrentInteriorCenter()
    return TheWorld.components.interiorspawner:GetInteriorCenter(self:GetPosition())
end

function EntityScript:GetInteriorGroupID()
    local center = self:GetCurrentInteriorCenter()
    if center then
        return center:GetGroupId()
    end
end

function EntityScript:GetInteriorGroupPosition()
    local center = self:GetCurrentInteriorCenter()
    if center then
        local x, _, z = self.Transform:GetWorldPosition()
        local cx, _, cz = center.Transform:GetWorldPosition()

        local current_x, current_y = center:GetCoordinates()
        local width, depth = center:GetSize()

        local offset_x = current_x * (width + INTERIOR_SPACEING * 2)
        local offset_y = current_y * (depth + INTERIOR_SPACEING * 2)

        return Vector3(x - cx - offset_y, 0, z - cz + offset_x)
    end
end

function EntityScript:GetRelativePositionInRoom(target)
    return target:GetInteriorGroupPosition() - self:GetInteriorGroupPosition()
end

function EntityScript:IsInSameRoomGroup(target)
    if not (target and target:IsValid()) then
        return false
    end

    local current_group = self:GetInteriorGroupID()
    local target_group = target:GetInteriorGroupID()

    return (current_group ~= nil) and current_group == target_group
end

function EntityScript:IsInSameArea(target)
    return self:IsInSameIsland(target) or self:IsInSameRoomGroup(target)
end
