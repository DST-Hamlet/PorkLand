local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Grue = require("components/grue")

local _AddImmunity = Grue.AddImmunity
function Grue:AddImmunity(source, ...)
    if source == "light" then -- 替换原本的light来源
        return
    end
    return _AddImmunity(self, source, ...)
end

AddComponentPostInit("grue", function(self)
    self.interior_task = self.inst:DoPeriodicTask(1 * FRAMES, function()
        --if self.inst:HasTag("inside_interior") then -- grue不会带来性能问题，因此改为无条件频繁检测，否则可能会因为进出室内的缘故导致错误的查理攻击
        if self.inst:IsInLight() then
            self:AddImmunity("real_light")
        else
            self:RemoveImmunity("real_light")
        end
        --end
    end)
end)
