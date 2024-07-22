local Citypossession = Class(function(self, inst)
    self.inst = inst
    self.cityID = 1
    self.inst:AddTag("citypossession")
    self.inst:AddTag("city1")
    self.enabled = true
end)

function Citypossession:SetCity(cityID)
    self.inst:RemoveTag("city1")
    self.cityID = cityID
    self.inst:AddTag("city" .. cityID)
end

function Citypossession:Disable()
    self.inst:RemoveTag("citypossession")
    self.enabled = false
end

function Citypossession:OnSave(inst)
    local data = {}
    data.cityID = self.cityID
    data.enabled = self.enabled
    return data
end

function Citypossession:OnLoad(data)
    if data then
        if data.cityID then
            self.cityID = data.cityID
        end
        self:SetCity(self.cityID)
        if data.enabled ~= nil then
            self.enabled = data.enabled
        end
    end

    if not self.enabled then
        self:Disable()
    end
end 

return Citypossession