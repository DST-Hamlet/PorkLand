local GlobalIdentity = Class(function(self, inst)
    self.inst = inst
    self.used_ids = {}
end)

function GlobalIdentity:CraeteNewID()
    for i = 1,10000 do
        local new_id = math.random(1000000,9999999)
        if not self.used_ids[new_id] then
            self.used_ids[new_id] = true
            return new_id
        end
    end
    print("WARNING!!! GlobalIdentity: Can't create a new ID")
    return false
end

function GlobalIdentity:OnSave()
    local data = {}
    data.used_ids = self.used_ids
    return data
end

function GlobalIdentity:OnLoad(data)
    if data and data.used_ids then
        self.used_ids = data.used_ids
    end
end

return GlobalIdentity
