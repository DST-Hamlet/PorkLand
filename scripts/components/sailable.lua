local function onsailor(self, sailor)
    if self.sailor == nil then
        self.inst:AddTag("sailable")
    else
        self.inst:RemoveTag("sailable")
    end
end

local Sailable = Class(function(self, inst)
    self.inst = inst
    self.sailor = nil
end, nil, {
    sailor = onsailor,
})

function Sailable:OnEmbarked(sailor)
    if not sailor then
        return
    end

    self.sailor = sailor
    self.isembarking = false

    if self.inst.MiniMapEntity then
        self.inst.MiniMapEntity:SetEnabled(false)
    end

    self.inst:PushEvent("embarked", {sailor = sailor})

    if self.inst.components.workable then
        self.inst.components.workable.workable = false
    end
end

function Sailable:OnDisembarked(sailor)
    if self.sailor == sailor then
        self.sailor = nil
    end

	if self.inst.MiniMapEntity then
		self.inst.MiniMapEntity:SetEnabled(true)
	end

    self.inst:PushEvent("disembarked", {sailor = sailor})

    if self.inst.components.workable then
        self.inst.components.workable.workable = true
    end
end

function Sailable:CanSail()
    return self.inst:HasTag("sailable")
end

return Sailable
