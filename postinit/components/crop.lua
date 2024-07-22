GLOBAL.setfenv(1, GLOBAL)

local Crop = require("components/crop")

local LIGHT_SOURCE_RADIUS = 30
local LIGHT_SOURCE_MUST_TAGS = {"daylight", "lightsource"}

local _DoGrow = Crop.DoGrow
function Crop:DoGrow(dt, no_wither, ...)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if not TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        _DoGrow(self, dt, no_wither, ...)
        return
    end

    if self.inst:HasTag("withered") then
        return
    end

    local should_grow = no_wither or not TheWorld.state.isnight
    if not should_grow then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        for _, v in ipairs(TheSim:FindEntities(x, 0, z, LIGHT_SOURCE_RADIUS, LIGHT_SOURCE_MUST_TAGS)) do
            local light_radius = v.Light:GetCalculatedRadius() * 0.7
            if v:GetDistanceSqToPoint(x, y, z) < light_radius * light_radius then
                should_grow = true
                break
            end
        end
    end

    if should_grow then
        local temp_rate = (TheWorld.state.israining and 1 + TUNING.CROP_RAIN_BONUS * TheWorld.state.precipitationrate)
        or (TheWorld.state.isspring and 1 + TUNING.SPRING_GROWTH_MODIFIER / 3) or 1
        self.growthpercent = math.clamp(self.growthpercent + dt * self.rate * temp_rate, 0, 1)
        self.cantgrowtime = 0
    else
        self.cantgrowtime = self.cantgrowtime + dt
        if self.cantgrowtime > TUNING.CROP_DARK_WITHER_TIME and self.inst.components.witherable ~= nil then
            self.inst.components.witherable:ForceWither()
            if self.inst:HasTag("withered") then
                return
            end
        end
    end

    if self.growthpercent < 1 then
        self.inst.AnimState:SetPercent("grow", self.growthpercent)
    else
        self.inst.AnimState:PlayAnimation("grow_pst")
        self:Mature()
        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end
    end
end
