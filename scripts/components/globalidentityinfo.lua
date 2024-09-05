local GlobalIdentityInfo = Class(function(self, inst)
    self.inst = inst
    self.idinfos = {}
    self.runtimeidinfos = {}
end)

function GlobalIdentityInfo:GetIndentityInfo(id)
    if self.idinfos[id] == nil then
        self.idinfos[id] = {}
    end
    return self.idinfos[id]
end

function GlobalIdentityInfo:GetRuntimeIndentityInfo(id) -- 这部分信息不会永久保存
    if self.runtimeidinfos[id] == nil then
        self.runtimeidinfos[id] = {}
    end
    return self.runtimeidinfos[id]
end

function GlobalIdentityInfo:OnSave()
    local data = {}
    data.idinfos = self.idinfos
    return data
end

function GlobalIdentityInfo:OnLoad(data)
    if data and data.idinfos then
        self.idinfos = data.idinfos
    end
end

return GlobalIdentityInfo
