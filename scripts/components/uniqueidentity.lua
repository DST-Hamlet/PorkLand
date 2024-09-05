local UniqueIdentity = Class(function(self, inst)
    self.inst = inst
    self.uniqueid = nil
end)

function UniqueIdentity:GetID()
    if self.uniqueid == nil then
        self:SetRandomID()
    end
    return self.uniqueid or 0
end

function UniqueIdentity:SetRandomID()
    if not TheWorld.components.globalidentity then
        print("WARNING!!! This world don't have component named globalidentity")
        return
    end
    self.uniqueid = TheWorld.components.globalidentity:CraeteNewID()
end

function UniqueIdentity:SetID(id_number)
    if id_number == nil then
        print("WARNING!!! try to set a nil value to uniqueid")
        return
    end
    self.uniqueid = id_number
end

function UniqueIdentity:OnSave()
    local data = {}
    data.uniqueid = self.uniqueid
    return data
end

function UniqueIdentity:OnLoad(data)
    if data and data.uniqueid then
        self.uniqueid = data.uniqueid
    end
end

return UniqueIdentity
