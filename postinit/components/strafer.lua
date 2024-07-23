GLOBAL.setfenv(1, GLOBAL)

local Strafer = require("components/strafer")

local _OnUpdate = Strafer.OnUpdate
function Strafer:OnUpdate(dt, ...)--基本上从原update函数中复制粘贴过来的
    if self.playercontroller:IsEnabled()
        and ((self.inst.sg and self.inst.sg:HasStateTag("strafing") and TheInput:IsControlPressed(CONTROL_SECONDARY))
        or not self.inst.sg)
        then
        local dir
        if TheInput:ControllerAttached() then
            local xdir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_LEFT)
            local ydir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_UP) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_DOWN)
            local deadzone = TUNING.CONTROLLER_DEADZONE_RADIUS
            if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
                dir = TheCamera:GetRightVec() * xdir - TheCamera:GetDownVec() * ydir
                dir = math.atan2(-dir.z, dir.x) * RADIANS
            end
        else
            local x, z = TheInput:GetWorldXZWithHeight(1)
            if x and z then
                dir = self.inst:GetAngleToPoint(x, 0, z)
            end
        end

        if dir then
            if self.inst.components.locomotor then
                self.inst.components.locomotor:OnStrafeFacingChanged(dir)
            end
            if not self.ismastersim and self.lastdir ~= dir then
                self.lastdir = dir
                SendModRPCToServer(MOD_RPC["Porkland"]["StrafeFacing_pl"], dir)
            end
        end
    else
        _OnUpdate(self, dt, ...)
    end
end
