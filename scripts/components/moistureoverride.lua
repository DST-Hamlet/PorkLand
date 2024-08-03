local SourceModifierList = require("util/sourcemodifierlist")

local WETNESS_SOURCE_WEATHER = "plateauweather"

local MoistureOverride = Class(function(self, inst)
    self.inst = inst

    self.wetness = 0

    self.rate_add = SourceModifierList(self.inst, 0, SourceModifierList.additive)
    self.rate_mult = SourceModifierList(self.inst, 1)
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

function MoistureOverride:OnUpdate(dt)
    local wetrate = TheWorld.components.plateauweather:GetMoistureRate()
    self.rate_mult:SetModifier(WETNESS_SOURCE_WEATHER, wetrate)

    self.wetness = (self.wetness * self.rate_mult:Get()) + self.rate_add:Get() * dt
    if self.wetness < 0 then
        self.inst:RemoveComponent("moistureoverride")
    end
end

return MoistureOverride
