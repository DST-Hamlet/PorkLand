local function OnSneezetimeDirty(inst)
    local sneezetime = inst.replica.hayfever._enabled:value() and inst.replica.hayfever._sneezetime:value() or nil
    inst:PushEvent("updatepollen", {sneezetime = sneezetime})
end

local Hayfever = Class(function(self, inst)
    self.inst = inst

    self._enabled = net_bool(inst.GUID, "hayfever.enabled")
    self._sneezetime = net_byte(inst.GUID, "hayfever.sneezetime", "sneezetimedirty")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("sneezetimedirty", OnSneezetimeDirty)
    end
end)

function Hayfever:SetSneezeTime(sneezetime)
    self._sneezetime:set(sneezetime)
end

function Hayfever:SetEnabled(val)
    self._enabled:set(val)
end

function Hayfever:OnRemoveEntity()
    if not TheNet:IsDedicated() then
        self.inst:RemoveEventCallback("hayfeversneezetimedirty", OnSneezetimeDirty)
    end
end

return Hayfever
