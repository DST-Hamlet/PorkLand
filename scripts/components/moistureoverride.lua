local SourceModifierList = require("util/sourcemodifierlist")

local WETNESS_SOURCE_WEATHER = "plateauweather"
local DRY_THRESHOLD = TUNING.MOISTURE_DRY_THRESHOLD
local WET_THRESHOLD = TUNING.MOISTURE_WET_THRESHOLD

local function OnUpdate(inst, self)
    self:DoUpdate()
end

local MoistureOverride = Class(function(self, inst)
    self.inst = inst

    self.wetness = 0

    self.rate_add = SourceModifierList(self.inst, 0, SourceModifierList.additive)
    self.rate_mult = SourceModifierList(self.inst, 1)

    self.last_update_time = GetTime()
    self.task = self.inst:DoPeriodicTask(1, OnUpdate, math.random() * 1, self)
end)

---@param moisture number
function MoistureOverride:SetAddMoisture(source, moisture)
    self.rate_add:SetModifier(source, moisture)
end

function MoistureOverride:SetMultMoisture(source, moisture)
    self.rate_mult:SetModifier(source, moisture)
end

function MoistureOverride:RemoveAddMoisture(source)
    self.rate_add:RemoveModifier(source)
end

function MoistureOverride:RemoveMultMoisture(source)
    self.rate_mult:RemoveModifier(source)
end

function MoistureOverride:AddOnce(wetness)
    self.wetness = math.clamp(self.wetness + wetness, 0, TUNING.MAX_WETNESS)
end

function MoistureOverride:Stop()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

MoistureOverride.OnRemoveEntity = MoistureOverride.Stop
MoistureOverride.OnRemoveFromEntity = MoistureOverride.Stop

function MoistureOverride:DoUpdate(dt)
    if dt == nil then
        dt = GetTime() - self.last_update_time
    end
    self.last_update_time = GetTime()

    local rate_additive = self.rate_add:Get() * dt
    if rate_additive <= 0 then
        local wetrate = TheWorld.net.components.plateauweather:GetMoistureRate()
        self.rate_mult:SetModifier(WETNESS_SOURCE_WEATHER, wetrate)
    end

    self.wetness = math.clamp(self.wetness + self.rate_mult:Get() * dt + self.rate_add:Get() * dt, 0, TUNING.MAX_WETNESS)

    if self.wetness == 0 then
        self:Stop()
        self.inst:RemoveComponent("moistureoverride")
        return
    end

    if self.wetness > WET_THRESHOLD then
        self.inst:AddTag("temporary_wet")
    elseif self.wetness < DRY_THRESHOLD then
        self.inst:RemoveTag("temporary_wet")
    end
end

function MoistureOverride:LongUpdate(dt)
    self:DoUpdate(dt)
end

function MoistureOverride:OnSave()
    local savedata = {
        add_component_if_missing = true,
        wetness = self.wetness,
    }

    return savedata
end

function MoistureOverride:OnLoad(data)
    if data and data.wetness then
        self.wetness = data.wetness
    end
end

function MoistureOverride:GetDebugString()
    return string.format("Wetness: %2.2f Rate(additive): %2.2f Rate(multiply): %2.2f", self.wetness, self.rate_add:Get(), self.rate_mult:Get())
end

return MoistureOverride
