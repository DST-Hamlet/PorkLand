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
    if rets[1] == ACTIONS.PICKUP and TheWorld.items_pass_ground and not target:IsOnPassablePoint() and self.inst:IsOnPassablePoint()  and
        not TheWorld.Map:IsLandTileAtPoint(target.Transform:GetWorldPosition()) then --让物品在靠近岸边时被捡起而不是回收
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

local _RotLeft = PlayerController.RotLeft
function PlayerController:RotLeft(...)
    if TheCamera.pl_inside_interior then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative", nil, 0.4)
    end
    return _RotLeft(self, ...)
end

local _RotRight = PlayerController.RotRight
function PlayerController:RotRight(...)
    if TheCamera.pl_inside_interior then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative", nil, 0.4)
    end
    return _RotRight(self, ...)
end

local _OnMapAction = PlayerController.OnMapAction
function PlayerController:OnMapAction(actioncode, position)
    if actioncode == ACTIONS.BLINK_MAP.code and self.inst:HasTag("inside_interior") then
        if self.inst == ThePlayer and TheWorld.components.worldmapiconproxy:ShouldRemapPosition(self.inst) then
            -- convert interior map position to world (edge)
            local remap_pos = TheWorld.components.worldmapiconproxy:RemapSoulhopPosition(self.inst, position)
            if remap_pos ~= nil then
                self.interior_remapped = true
                _OnMapAction(self, actioncode, remap_pos) -- skip other remap
                self.interior_remapped = false
                return
            end
        end
    end
    return _OnMapAction(self, actioncode, position)
end

local _RemapMapAction = PlayerController.RemapMapAction
function PlayerController:RemapMapAction(act, position)
    if self.inst:HasTag("inside_interior") and act ~= nil and act.doer ~= nil
        and TheWorld.components.worldmapiconproxy:ShouldRemapPosition(act.doer) then
        if act.action.code == ACTIONS.BLINK.code then
            local remap_pos, data = TheWorld.components.worldmapiconproxy:RemapSoulhopPosition(act.doer, position, self.interior_remapped)
            if remap_pos ~= nil and data ~= nil and data.type == "interior" then
                local act_remap = BufferedAction(act.doer, nil, ACTIONS.BLINK_MAP, act.invobject, remap_pos)
                for k,v in pairs(data.data)do
                    act_remap[k] = v
                end
                return act_remap
            else
                return
            end
        end
    end
    return _RemapMapAction(self, act, position)
end
