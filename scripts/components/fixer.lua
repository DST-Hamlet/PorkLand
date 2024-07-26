
local Fixer = Class(function(self, inst)
    self.inst = inst
    self.inst:AddTag("fixer")
end)

function Fixer:CanFix(target)
	if not target then
		return false
	end
    return true
end

function Fixer:SetTarget(target)
    if self:CanFix(target) then
        self.target = target
    end
end

function Fixer:ClearTarget()
    self.target = nil
end

function Fixer:OnSave()
    if self.target then
        return { target = self.target.GUID }, {self.target.GUID}
    end
end

function Fixer:GetDebugString()

    local str = ""

    if self.target then
        str = "Target: "..self.target.prefab
    end
    return str
end

return Fixer
