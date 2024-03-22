GLOBAL.setfenv(1, GLOBAL)
local PlayerController = require("components/playercontroller")

local _GetPickupAction = ToolUtil.GetUpvalue(PlayerController.GetActionButtonAction, "GetPickupAction")
local GetPickupAction = function(self, target, tool, ...)
    if target:HasTag("smolder") then
        return ACTIONS.SMOTHER
    elseif tool ~= nil then
        for action, _ in pairs(TOOLACTIONS) do
            if target:HasTag(action .. "_workable") then
                if tool:HasTag(action .. "_tool") then
                    return ACTIONS[action]
                end
                -- break
            end
        end
    end

    return _GetPickupAction(self, target, tool, ...)
end
ToolUtil.SetUpvalue(PlayerController.GetActionButtonAction, GetPickupAction, "GetPickupAction")
