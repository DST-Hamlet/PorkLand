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

-- local _GetAttackTarget = PlayerController.GetAttackTarget
-- function PlayerController:GetAttackTarget(force_attack, force_target, isretarget, use_remote_predict)
--     local target = _GetAttackTarget(self, force_attack, force_target, isretarget, use_remote_predict)

--     if target and target.components.combatredirect then
--         return target.components.combatredirect:GetRedirect() or target
--     else
--         return target
--     end
-- end
