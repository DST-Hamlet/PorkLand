local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("witherable", function(self, inst)
    inst:DoTaskInTime(0.1, function(crop)
        local x, _, z = crop.Transform:GetWorldPosition()
        if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
            self:Enable(false)
        end
    end)
end)
