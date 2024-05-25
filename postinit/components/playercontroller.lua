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

    local rets = {_GetPickupAction(self, target, tool, ...)}
    if rets[1] == ACTIONS.PICKUP and TheWorld.items_pass_ground and not target:IsOnPassablePoint() and self.inst:IsOnPassablePoint() then
        rets[1] = ACTIONS.RETRIEVE
    end
    return unpack(rets)
end
ToolUtil.SetUpvalue(PlayerController.GetActionButtonAction, GetPickupAction, "GetPickupAction")

-- local _GetGroundUseAction = PlayerController.GetGroundUseAction
-- function PlayerController:GetGroundUseAction(position, ...)
--     if self.inst:IsSailing() then
--         -- Check if the player is close to land and facing towards it
--         local angle = self.inst.Transform:GetRotation() * DEGREES
--         local x, y, z = self.inst.Transform:GetWorldPosition()
--         local target_x, target_z = VecUtil_Normalize(math.cos(angle), -math.sin(angle))
--         target_x, target_z = 5 * target_x + x, 5 * target_z + z

--         local can_hop, hop_x, hop_z, target_platform = self.inst.components.playeractionpicker:ScanForLandingPoint(target_x, target_z)
--         if can_hop then
--             return nil, BufferedAction(self.inst, nil, ACTIONS.DISEMBARK, nil, Vector3(hop_x, 0, hop_z))
--         end
--     end
--     return _GetGroundUseAction(self, position, ...)
-- end
