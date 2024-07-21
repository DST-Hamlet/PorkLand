GLOBAL.setfenv(1, GLOBAL)

function Vector3:IsInterior()
    return TheWorld and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(self.x, self.z)
end
