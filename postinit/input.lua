GLOBAL.setfenv(1, GLOBAL)

local Input = Input

local _GetWorldEntityUnderMouse = Input.GetWorldEntityUnderMouse
Input.GetWorldEntityUnderMouse = function(self, ...)
    local targetent = _GetWorldEntityUnderMouse(self, ...)
    if targetent and targetent.components and targetent.components.combatredirect then
        return targetent.components.combatredirect:GetRedirect()
    end
    return targetent
end
