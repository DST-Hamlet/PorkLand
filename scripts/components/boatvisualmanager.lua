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
    visual:SetVisual(self.inst)
end

function BoatVisualManager:RemoveBoatEquipVisuals(item)
    item.visual = nil
    if self.visuals[item] then
        self.visuals[item]:Remove()
        self.visuals[item] = nil
    end
end

return BoatVisualManager
