local CombatRedirect = Class(function(self, inst)
    self.inst = inst

    self.redirects = {}
end)

function CombatRedirect:AddRedirectTarget(tbl)
    for entity in pairs(tbl) do
        self.redirects[entity] = entity
        entity:ListenForEvent("remove", function()
            self.redirects[entity] = nil
        end)
    end
end

function CombatRedirect:GetRedirect()
    local closest
    local rangesq = math.huge
    local x, y, z = self.inst.Transform:GetWorldPosition()
    for ent in pairs(self.redirects) do
        if ent and ent:IsValid() then
            local distsq = ent:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closest = ent
            end
        end
    end
    return closest, closest ~= nil and rangesq
end

-- For pugalisk there's no need for save and load
-- consider adding them if using this component for other objects

return CombatRedirect
