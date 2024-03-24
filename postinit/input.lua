GLOBAL.setfenv(1, GLOBAL)

-- NOTE(ziwbi): Do NOT modify the Input class, modify TheInput object instead, see V2C's comment in input.lua
local TheInput = TheInput

local _GetWorldEntityUnderMouse = TheInput.GetWorldEntityUnderMouse
function TheInput:GetWorldEntityUnderMouse(...)
    local targetent = _GetWorldEntityUnderMouse(self, ...)
    if targetent and targetent.components and targetent.components.cursorredirect then
        return targetent.components.cursorredirect:GetRedirect()
    else
        return targetent
    end
end
