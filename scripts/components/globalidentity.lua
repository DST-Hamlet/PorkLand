local GlobalIdentity = Class(function(self, inst)
    self.inst = inst
    self.nextid = 1000001
end)

function GlobalIdentity:CreateNewId()
    local new_id = self.nextid
    self.nextid = self.nextid + 1
    return new_id
end

function GlobalIdentity:OnSave()
    local data = {}
    data.nextid = self.nextid
    return data
end

function GlobalIdentity:OnLoad(data)
    if data and data.nextid then
        self.nextid = data.nextid
    end
end

return GlobalIdentity
