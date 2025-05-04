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

local on_left_click = PlayerController.OnLeftClick
function PlayerController:OnLeftClick(down, ...)
    if down
        and self.casting_action_override_spell
        and not self.ismastersim
        and not TheInput:GetHUDEntityUnderMouse()
        and self:IsEnabled()
    then
        local act = self:GetLeftMouseAction()
        if act then
            local platform
            local pos_x
            local pos_z
            if act.pos then
                platform = act.pos.walkable_platform
                pos_x = act.pos.local_pt.x
                pos_z = act.pos.local_pt.z
            else
                local position = TheInput:GetWorldPosition()
                platform, pos_x, pos_z = self:GetPlatformRelativePosition(position.x, position.z)
            end
            local target = act.target or TheInput:GetWorldEntityUnderMouse()

            local spellbook = self.inst.HUD:GetCurrentOpenSpellBook()
            local spell_id
            if spellbook then
                spell_id = spellbook.components.spellbook:GetSelectedSpell()
            end

            local controlmods = self:EncodeControlMods()
            if self.locomotor == nil then
                self.remote_controls[CONTROL_PRIMARY] = 0
                SendRPCToServer(RPC.LeftClick, act.action.code, pos_x, pos_z, target, nil, controlmods, act.action.canforce, act.action.mod_name, platform, platform ~= nil, spellbook, spell_id)
            elseif act.action ~= ACTIONS.WALKTO and self:CanLocomote() then
                act.preview_cb = function()
                    self.remote_controls[CONTROL_PRIMARY] = 0
                    local isreleased = not TheInput:IsControlPressed(CONTROL_PRIMARY)
                    SendRPCToServer(RPC.LeftClick, act.action.code, pos_x, pos_z, target, isreleased, controlmods, nil, act.action.mod_name, platform, platform ~= nil, spellbook, spell_id)
                end
            end
            self:DoAction(act, spellbook)
            return
        end
    end

    if down
        and not TheInput:GetHUDEntityUnderMouse()
        and self:IsEnabled()
        and self:IsAOETargeting()
    then
        local spellbook = self:GetActiveSpellBook()
        if spellbook and spellbook.components.spellcommand then
            spellbook.components.spellcommand:ReselectSelectedSpellInSpellBook()
        end
    end

    local ret = { on_left_click(self, down, ...) }

    -- if down and not TheInput:GetHUDEntityUnderMouse() then
    --     self:CancelCastingActionOverrideSpell()
    -- end

    return unpack(ret)
end

local on_remote_left_click = PlayerController.OnRemoteLeftClick
function PlayerController:OnRemoteLeftClick(actioncode, position, target, isreleased, controlmodscode, noforce, mod_name, spellbook, spell_id, ...)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        if actioncode == ACTIONS.SPELL_COMMAND.code then
            if spellbook
                and spellbook.components.inventoryitem
                and spellbook.components.inventoryitem:GetGrandOwner() == self.inst
                and spellbook.components.spellbook
            then
                spellbook.components.spellbook:SelectSpell(spell_id)
            end
			self:DoAction(BufferedAction(self.inst, target, ACTIONS.SPELL_COMMAND, spellbook, position), spellbook)
            return
        end
    end
    return on_remote_left_click(self, actioncode, position, target, isreleased, controlmodscode, noforce, mod_name, spellbook, spell_id, ...)
end

local on_right_click = PlayerController.OnRightClick
function PlayerController:OnRightClick(down, ...)
    local ret = { on_right_click(self, down, ...) }
    if down then
        self:CancelCastingActionOverrideSpell()
    end
    return unpack(ret)
end

local start_aoe_targeting_using = PlayerController.StartAOETargetingUsing
function PlayerController:StartAOETargetingUsing(item, ...)
    self:CancelCastingActionOverrideSpell()
    return start_aoe_targeting_using(self, item, ...)
end

local has_aoe_targeting = PlayerController.HasAOETargeting
function PlayerController:HasAOETargeting(...)
    return self.casting_action_override_spell ~= nil or has_aoe_targeting(self, ...)
end

function PlayerController:StartCastingActionOverrideSpell(item, leftclickoverride)
    self:CancelCastingActionOverrideSpell()
    self:CancelAOETargeting()

    self.inst.components.playeractionpicker.leftclickoverride = leftclickoverride
    self.casting_action_override_spell = {
        item = item,
        leftclickoverride = leftclickoverride,
    }
end

function PlayerController:CancelCastingActionOverrideSpell()
    if self.casting_action_override_spell then
        if self.inst.components.playeractionpicker.leftclickoverride == self.casting_action_override_spell.leftclickoverride then
            self.inst.components.playeractionpicker.leftclickoverride = nil
        end
        self.casting_action_override_spell = nil
    end
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

        if self.casting_action_override_spell then
            if not self.casting_action_override_spell.item:IsValid() then
                self:CancelCastingActionOverrideSpell()
            else
                local inventoryitem = self.casting_action_override_spell.item.replica.inventoryitem
                if inventoryitem and not inventoryitem:IsGrandOwner(self.inst) then
                    self:CancelCastingActionOverrideSpell()
                end
            end
        end
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

AddComponentPostInit("playercontroller", function(self)
    self.lasttick_controlpressed = {}
    self.casting_action_override_spell = nil
end)
