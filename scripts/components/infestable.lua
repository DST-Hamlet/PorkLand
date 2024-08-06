local Infestable = Class(function(self, inst)
    self.inst = inst
    self.infesters = {}
end)

function Infestable:Infest(infester)
    local found = false
    for _, v in ipairs(self.infesters)do
        if v == infester then
            found = true
        end
    end
    if not found then
        table.insert(self.infesters, infester)
    end
end

function Infestable:Uninfest(infester)
    RemoveByValue(self.infesters, infester)
end

function Infestable:OnSave()
    local data = {infesters = {}}
    local references = {}
    local refs = {}
    for k, v in pairs(self.infesters) do
        if v.persists then
            data.infesters[k], refs = v:GetSaveRecord()
            if refs then
                for _, vv in pairs(refs) do
                    table.insert(references, vv)
                end
            end

            data.infesters[k].GUID = v.GUID
            table.insert(references, data.infesters[k].GUID)

            if v.components.homeseeker then
                data.infesters[k].home =  v.components.homeseeker:GetHome().GUID
                table.insert(references, data.infesters[k].home)
            end
        end
    end

    return data, references
end

function Infestable:OnLoad(data, newents)
    self.home_hookup = {}

    if not data or not data.infesters then
        return
    end

    for k,v in pairs(data.infesters) do
        local inst = SpawnSaveRecord(v, newents)
        if inst then
            inst.components.infester:Infest(self.inst)
            if v.home then
                if not self.home_hookup[v.home] then
                    self.home_hookup[v.home] = {}
                end
                table.insert(self.home_hookup[v.home],inst)
            end
        end
    end
end

function Infestable:LoadPostPass(ents, data)
    if not data or not data.infesters then
        return
    end

    for k,v in pairs(data.infesters) do
        if v.home then
            local home = ents[v.home] and ents[v.home].entity
            if home then
                if self.home_hookup[v.home] then
                    for i,p in ipairs(self.home_hookup[v.home]) do
                        home.components.childspawner:TakeOwnership(p)
                    end
                end
            end
        end
    end
end

return Infestable
