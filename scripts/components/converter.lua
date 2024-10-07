local Converter = Class(function(self, inst)
    self.inst = inst
    self.convert_progress = 0
    self.targetprefab = nil
end)

function Converter:DoDelta(amount)
    self.convert_progress = self.convert_progress + amount
    self:CheckConvert()
end

function Converter:CheckConvert()
    if self.convert_progress >= 1 then
        local owner = self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner or nil
        local holder = owner ~= nil and (owner.components.inventory or owner.components.container) or nil
        local stacksize = self.inst.components.stackable:StackSize()
        local newitem = ReplacePrefab(self.inst, self.targetprefab)

        if newitem.components.stackable then
            if stacksize > newitem.components.stackable.maxsize then
                newitem.components.stackable:SetIgnoreMaxSize(true)
            end
            newitem.components.stackable:SetStackSize(stacksize)
        end

        if holder ~= nil then
            local slot = holder:GetItemSlot(self.inst)
            holder:GiveItem(newitem, slot)
        end
    end
end

function Converter:OnSave()
    local data = {}
    data.convert_progress = self.convert_progress
    return data
end

function Converter:OnLoad(data)
    if data and data.convert_progress then
        self.convert_progress = data.convert_progress
    end
end

return Converter
