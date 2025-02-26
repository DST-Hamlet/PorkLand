local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local PlayerController = require("components/playercontroller")

local function get_tool_action(tool, target)
    if not tool then
        return
    end
    for action in pairs(TOOLACTIONS) do
        if target:HasTag(action .. "_workable") then
            if tool:HasTag(action .. "_tool") then
                return ACTIONS[action]
            end
            -- break
        end
    end
end

local _GetPickupAction, i = ToolUtil.GetUpvalue(PlayerController.GetActionButtonAction, "GetPickupAction")
local GetPickupAction = function(self, target, tool, ...)
    local action = _GetPickupAction(self, target, tool, ...)
    if not action then
        action = get_tool_action(tool, target)
    end
    if action == ACTIONS.PICKUP and TheWorld.items_pass_ground and not target:IsOnPassablePoint() and self.inst:IsOnPassablePoint()
        and not TheWorld.Map:IsLandTileAtPoint(target.Transform:GetWorldPosition()) then --让物品在靠近岸边时被捡起而不是回收
        action = ACTIONS.RETRIEVE
    end
    if (target:HasTag("interior_door") or target:HasTag("exterior_door")) and not target:HasTag("door_hidden") and not target:HasTag("door_disabled") then
        action = ACTIONS.USEDOOR
    end
    if action == ACTIONS.PICK and target:HasTag("pickable") and target:HasTag("unsuited") then
        action = nil
    end
    if action == ACTIONS.HAMMER and tool and tool:HasTag("fixable_crusher") and not target:HasTag("fixable") then
        action = nil
    end
    return action
end
debug.setupvalue(PlayerController.GetActionButtonAction, i, GetPickupAction)


local _GetActionButtonAction = PlayerController.GetActionButtonAction
function PlayerController:GetActionButtonAction(force_target, ...)
    local buffaction = _GetActionButtonAction(self, force_target, ...)
    if buffaction then
        local target = buffaction.target
        if target and (target:HasTag("interior_door") or target:HasTag("exterior_door")) and not target:HasTag("door_hidden") and not target:HasTag("door_disabled") then
            if buffaction.action.code == ACTIONS.HAUNT.code then
                return BufferedAction(self.inst, target, ACTIONS.USEDOOR)
            end
        end
    end
    return buffaction
end

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
    if TheCamera.inside_interior then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative", nil, 0.4)
    end
    return _RotLeft(self, ...)
end

local _RotRight = PlayerController.RotRight
function PlayerController:RotRight(...)
    if TheCamera.inside_interior then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative", nil, 0.4)
    end
    return _RotRight(self, ...)
end

-- local _OnMapAction = PlayerController.OnMapAction
-- function PlayerController:OnMapAction(actioncode, position)
--     if actioncode == ACTIONS.BLINK_MAP.code and self.inst:HasTag("inside_interior") then
--         if self.inst == ThePlayer and TheWorld.components.worldmapiconproxy:ShouldRemapPosition(self.inst) then
--             -- convert interior map position to world (edge)
--             local remap_pos = TheWorld.components.worldmapiconproxy:RemapSoulhopPosition(self.inst, position)
--             if remap_pos ~= nil then
--                 self.interior_remapped = true
--                 _OnMapAction(self, actioncode, remap_pos) -- skip other remap
--                 self.interior_remapped = false
--                 return
--             end
--         end
--     end
--     return _OnMapAction(self, actioncode, position)
-- end

-- local _RemapMapAction = PlayerController.RemapMapAction
-- function PlayerController:RemapMapAction(act, position)
--     if self.inst:HasTag("inside_interior") and act ~= nil and act.doer ~= nil
--         and TheWorld.components.worldmapiconproxy:ShouldRemapPosition(act.doer) then
--         if act.action.code == ACTIONS.BLINK.code then
--             local remap_pos, data = TheWorld.components.worldmapiconproxy:RemapSoulhopPosition(act.doer, position, self.interior_remapped)
--             if remap_pos ~= nil and data ~= nil and data.type == "interior" then
--                 local act_remap = BufferedAction(act.doer, nil, ACTIONS.BLINK_MAP, act.invobject, remap_pos)
--                 for k, v in pairs(data.data) do
--                     act_remap[k] = v
--                 end
--                 return act_remap
--             else
--                 return
--             end
--         end
--     end
--     return _RemapMapAction(self, act, position)
-- end

function PlayerController:ReleaseControlSecondary(x, z)
    if not self.ismastersim then
        SendModRPCToServer(MOD_RPC["Porkland"]["ReleaseControlSecondary"], x, z)
    end
    local position = Vector3(x, 0, z)
    if self.inst.sg ~= nil and self.inst.sg:HasStateTag("strafing") and self.inst.sg:HasStateTag("charge") then
        self.inst:PushBufferedAction(BufferedAction(self.inst, nil, ACTIONS.CHARGE_RELEASE, nil, position))
    end
end

function PlayerController:OnRemoteReleaseControlSecondary(x, z)
    local position = Vector3(x, 0, z)
    if self.inst.sg ~= nil and self.inst.sg:HasStateTag("strafing") and self.inst.sg:HasStateTag("charge") then
        self.inst:PushBufferedAction(BufferedAction(self.inst, nil, ACTIONS.CHARGE_RELEASE, nil, position))
    end
end

local _OnUpdate = PlayerController.OnUpdate
function PlayerController:OnUpdate(dt)
    local ret = {_OnUpdate(self, dt)}

    if self.handler then
        if self.lasttick_controlpressed[CONTROL_SECONDARY] ~= nil
            and self.lasttick_controlpressed[CONTROL_SECONDARY] == true
            and self:IsControlPressed(CONTROL_SECONDARY) == false then
            local x, z = TheInput:GetWorldXZWithHeight(1)
            self:ReleaseControlSecondary(x, z)
        end
        self.lasttick_controlpressed[CONTROL_SECONDARY] = self:IsControlPressed(CONTROL_SECONDARY)
    end

    return unpack(ret)
end

local Sim = getmetatable(TheSim).__index
local _FindEntities_Registered = Sim.FindEntities_Registered
local _GetAttackTarget = PlayerController.GetAttackTarget
function PlayerController:GetAttackTarget(force_attack, force_target, isretarget, use_remote_predict)

    function Sim:FindEntities_Registered(x, y, z, radius, registered_tags)
        local ents = _FindEntities_Registered(self, x, y, z, radius, TheSim:RegisterFindTags({"_combat"}, {"INLIMBO", "lastresort"}))
        return ents
    end

    local target = _GetAttackTarget(self, force_attack, force_target, isretarget, use_remote_predict)

    Sim.FindEntities_Registered = _FindEntities_Registered

    local hastarget = false
    if target == nil then
        if self.locomotor ~= nil then
            local buffaction = self.locomotor.bufferedaction
            if buffaction and buffaction.action == ACTIONS.ATTACK then
                hastarget = true
            end
        end
        if hastarget == false then
            target = _GetAttackTarget(self, force_attack, force_target, isretarget, use_remote_predict)
        end
    end

    return target
end

local _GetMapActions = PlayerController.GetMapActions
function PlayerController:GetMapActions(...)
    if self.inst:HasTag("inside_interior") then
        return nil
    end

    return _GetMapActions(self, ...)
end

local do_action = PlayerController.DoAction
function PlayerController:DoAction(buffaction, ...)
    if buffaction and buffaction.action == ACTIONS.DODGE and not self:CanLocomote() then
        self.inst.last_dodge_time = GetTime()
    end
    return do_action(self, buffaction, ...)
end

AddComponentPostInit("playercontroller", function(self)
    self.lasttick_controlpressed = {}
end)
