local BoatVisualManager = Class(function(self, inst)
    self.inst = inst
    self.visuals = {}
end)

function BoatVisualManager:SpawnBoatEquipVisuals(item, visualprefab)
    assert(visualprefab and type(visualprefab) == "string", "item.visualprefab must be a valid string!")

    local visual = SpawnPrefab("visual_" .. visualprefab .. "_boat")
    visual.entity:SetParent(self.inst.entity)
    self.visuals[item] = visual

    item.visual = visual
    self.inst.boatvisuals[visual] = true
    visual:SetVisual(self.inst)
end

function BoatVisualManager:RemoveBoatEquipVisuals(item)
    item.visual = nil
    if self.visuals[item] then
        self.visuals[item]:Remove()
        self.visuals[item] = nil
    end
end

function BoatVisualManager:OnRemoveFromEntity()
    for item, visual in pairs(self.visuals) do
        visual:Remove()
        item.visual = nil
    end
    self.visuals = {}
end

BoatVisualManager.OnRemoveEntity = BoatVisualManager.OnRemoveFromEntity

return BoatVisualManager
