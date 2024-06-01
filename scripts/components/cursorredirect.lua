local CursortRedirect = Class(function(self, inst)
    self.inst = inst

    self.redirects = {}
end)

function CursortRedirect:AddRedirectTarget(tbl)
    for _, entity in pairs(tbl) do
        self.redirects[entity.GUID] = net_entity(entity.GUID, "_entity" .. tostring(entity.GUID) .. tostring(self.inst.GUID))
        self.redirects[entity.GUID]:set(entity)
        entity:ListenForEvent("remove", function()
            self.redirects[entity.GUID]:set(nil)
            self.redirects[entity.GUID] = nil
        end)
    end
end

function CursortRedirect:GetRedirect()
    local closest
    local rangesq = math.huge
    local x, y, z = self.inst.Transform:GetWorldPosition()
    for GUID, ent in pairs(self.redirects) do
        if ent then
            local distsq = ent:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closest = ent
            end
        end
    end
    if closest ~= nil then
        closest.highlightforward = self.inst
    end
    return closest, closest ~= nil and rangesq
end

-- For pugalisk there's no need for save and load
-- consider adding them if using this component for other objects

return CursortRedirect
