GLOBAL.setfenv(1, GLOBAL)

-- NOTE(ziwbi): Do NOT modify the Input class, modify TheInput object instead, see V2C's comment in input.lua
local TheInput = TheInput

local _GetWorldEntityUnderMouse = TheInput.GetWorldEntityUnderMouse
function TheInput:GetWorldEntityUnderMouse(...)
    local target_entity = _GetWorldEntityUnderMouse(self, ...)
    if target_entity and target_entity.components and target_entity.components.cursorredirect then
        return target_entity.components.cursorredirect:GetRedirect()
    else
        return target_entity
    end
end
