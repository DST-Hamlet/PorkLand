local function onarmed(self, armed)
    if armed then
        self.inst:AddTag("armed")
    else
        self.inst:RemoveTag("armed")
    end
end

local function onrearmable(self, rearmable)
    if rearmable then
        self.inst:AddTag("rearmable")
    else
        self.inst:RemoveTag("rearmable")
    end
end

local Disarmable = Class(function(self, inst)
    self.inst = inst
    self.armed = true

    self.inst:AddTag("disarmable")
end,
nil,
{
    armed = onarmed,
    rearmable = onrearmable,
})


function Disarmable:disarm(doer, item)
    if self.armed then
        self.armed = false

        if self.disarmfn then
            self.disarmfn(self.inst, doer)
        end

        return true
    end
end

function Disarmable:DoRearming(inst, doer)
    if not self.armed then
        self.armed = true
        if self.rearmfn then
            self.rearmfn(self.inst, doer)
        end
        return true
    end
end

function Disarmable:OnSave()
    return {armed = self.armed}
end

function Disarmable:OnLoad(data)
    if data and data.armed ~= nil then
        self.armed = data.armed
    end
end

return Disarmable
