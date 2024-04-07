local BoatVisualManager = Class(function(self, inst)
    self.inst = inst
    self.visuals = {}
end)

local function OnRemove(inst)
    inst.boat.boatvisuals[inst] = nil
end

function BoatVisualManager:SpawnBoatEquipVisuals(item, visualprefab)
    if self.inst.replica.boatvisualmanager then
        self.inst.replica.boatvisualmanager:SpawnBoatEquipVisuals(item, visualprefab)
    end
end

function BoatVisualManager:RemoveBoatEquipVisuals(item)
    if self.inst.replica.boatvisualmanager then
        self.inst.replica.boatvisualmanager:RemoveBoatEquipVisuals(item)
    end
end

return BoatVisualManager
