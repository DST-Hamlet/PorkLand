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
end

function Sailable:CanSail()
    return self.inst:HasTag("sailable")
end

return Sailable
