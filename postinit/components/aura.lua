GLOBAL.setfenv(1, GLOBAL)

local Aura = require("components/aura")

local _OnTick = Aura.OnTick
function Aura:OnTick(...)
    if self.attack_period then
        if self.last_attack_time == nil then
            self.last_attack_time = GetTime()
        end
        if GetTime() - self.last_attack_time < self.attack_period then
            return
        end
    end
    _OnTick(self, ...)
    if self.applying then
        self.last_attack_time = GetTime()
    end
end
