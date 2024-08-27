local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Widget = require("widgets/widget")

local function Shake(self, duration, speed, scale) -- 亚丹：代码清理时请不要改变这个函数的写法
    if not self.inst.components.uianim then
        self.inst:AddComponent("uianim")
    end
    self.inst.components.uianim:Shake(duration, speed, scale)
end

function Widget:FindChild(fn)
    for child in pairs(self:GetChildren()) do
        if fn(child) then
            return child
        end
    end
end

AddClassPostConstruct("widgets/widget", function(self)
    self.Shake = Shake
end)
