local CanopyTracker = Class(function(self, inst)
    self.inst = inst

    self._under_canopy = net_bool(inst.GUID, "canopytracker._under_canopy", "onchangecanopytrackerzone")
    
    if TheWorld.ismastersim then
        self.inst:DoTaskInTime(0, function()
            self:UpdateUnderCanopy()
            self.oncanopychanged = function() self:UpdateUnderCanopy() end
            self.inst:ListenForEvent("changearea", self.oncanopychanged)
        end)
    end
end)

function CanopyTracker:OnRemoveFromEntity()
    if self.oncanopychanged ~= nil then
        self.inst:RemoveEventCallback("changearea", self.oncanopychanged)
        self.oncanopychanged = nil
    end
end

function CanopyTracker:UpdateUnderCanopy()
    local under_canopy = self.inst.components.areaaware ~= nil and self.inst.components.areaaware:CurrentlyInTag("Canopy")
    print("try", not self:IsUnderCanopy(), under_canopy)
	if not self:IsUnderCanopy() and under_canopy then
        self._under_canopy:set(true)
        self.inst:PushEvent("canopyin")
		print("THIS WERY HARD MESSAGE IN CANOPY")
    elseif self:IsUnderCanopy() and not under_canopy then
        self._under_canopy:set(false)
        self.inst:PushEvent("canopyout")
    end
end

function CanopyTracker:IsUnderCanopy()
    return self._under_canopy:value()
end

function CanopyTracker:OnSave()
    local data = {}

    data.under_canopy = self:IsUnderCanopy()

    return data
end

function CanopyTracker:OnLoad(data)
    if data and data.under_canopy then
        self._under_canopy:set(true)
        self.inst:PushEvent("onchangecanopyzone", {instant=true})
        self.inst:PushEvent("canopyin", {instant=true})
    end
end

return CanopyTracker