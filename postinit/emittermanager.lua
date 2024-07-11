GLOBAL.setfenv(1, GLOBAL)

local precipitation = {
    ["rain"] = true,
    ["snow"] = true,
    ["lunarhail"] = true,
    ["caverain"] = true,
    ["caveacidrain"] = true,
    ["pollen"] = true,
}

local fns = {}
local _PostUpdate = EmitterManager.PostUpdate
function EmitterManager:PostUpdate(...)
    for inst, data in pairs(self.awakeEmitters.infiniteLifetimes) do
        if precipitation[inst.prefab or ""] then
            if fns[inst.prefab] == nil then
                -- cache old fns on first update
                fns[inst.prefab] = data.updateFunc
            end
            local x, _, z = inst.Transform:GetWorldPosition()
            if TheWorld:HasTag("porkland") and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
                data.updateFunc = function() end
            else
                data.updateFunc = fns[inst.prefab]
            end
        end
    end
    return _PostUpdate(self, ...)
end
