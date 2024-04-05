local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local function Shake(self, duration, speed, scale)
    if not self.inst.components.uianim then
        self.inst:AddComponent("uianim")
    end
    self.inst.components.uianim:Shake(duration, speed, scale)
end

AddClassPostConstruct("widgets/widget", function(self)
    self.Shake = Shake
end)
