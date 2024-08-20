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
    return {
        cityID = self.cityID,
        enabled = self.enabled,
        add_component_if_missing = true,
    }
end

function Citypossession:OnLoad(data)
    if data then
        if data.cityID then
            self:SetCity(data.cityID)
        end
        if data.enabled ~= nil then
            self.enabled = data.enabled
        end
    end

    if not self.enabled then
        self:Disable()
    end
end

return Citypossession
