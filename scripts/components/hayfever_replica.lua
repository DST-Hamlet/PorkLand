local function OnHayfeverSneezetimeDirty(inst, self)
    local sneezetime = self._enabled:value() and self._sneezetime:value() or nil
    inst:PushEvent("updatepollen", {sneezetime = sneezetime})
end

local Hayfever = Class(function(self, inst)
    self.inst = inst

    self._enabled = net_bool(inst.GUID, "hayfever.enabled")
    self._sneezetime = net_byte(inst.GUID, "hayfever.sneezetime", "hayfeversneezetimedirty")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("hayfeversneezetimedirty", function(inst) OnHayfeverSneezetimeDirty(inst, self) end)
    end
end)

function Hayfever:SetSneezeTime(sneezetime)
    self._sneezetime:set(sneezetime)
end

function Hayfever:SetEnabled(val)
    self._enabled:set(val)
end

return Hayfever
