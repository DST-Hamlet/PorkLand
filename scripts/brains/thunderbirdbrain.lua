require("behaviours/wander")
require("behaviours/runaway")
require("behaviours/doaction")
require("behaviours/panic")

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 80

local FACE_DIST = 16
local CHARGE_DIST = 10
local ATTACK_DIST = 6

local SEE_PLAYER_DIST = 5.9
local STOP_RUN_DIST = 25

local MAX_FLEE_TIME = 75
local SEE_IRON_DIST = 15

local CANT_TAGS = {"playerghost", "INLIMBO", "shadowcreature"}
local MUST_ONEOF_TAGS = {"player", "monster", "scarytoprey"}
local function GetTarget(inst, distance)
    local target = FindEntity(inst, distance, nil, nil, CANT_TAGS, MUST_ONEOF_TAGS)
    if target ~= nil then
        return target
    end
end

local function ValidateTarget(target)
    if target ~= nil and target.components.health ~= nil then
        local health = not target.components.health:IsDead()
        return not target:HasTag("notarget") and not target:IsInLimbo() and health
    end
end

local function HomePos(inst)
    if inst.components.homeseeker then
        return inst.components.homeseeker:GetHomePos()
    end

    return Vector3(0, 0, 0)
end

local function IsHome(inst)
    local target = inst.components.homeseeker and inst.components.homeseeker:GetHome()
    if target then
        return inst:GetDistanceSqToInst(target) <= 1
    end

    return false
end

local function IsNestEmpty(inst)
    if inst.components.health:IsDead() then
        return false
    end

    local nest = inst.components.homeseeker and inst.components.homeseeker:GetHome()
    if nest then
        return not nest.components.pickable:CanBePicked()
    end

    return false
end

local function ThreatInAttackRange(inst)
    if inst.components.health:IsDead() then
        return false
    end

    local target = GetTarget(inst, ATTACK_DIST)
    if ValidateTarget(target) then
        return true
    end

    return false
end

local function LightningAction(inst)
    local target = GetTarget(inst, ATTACK_DIST)
    if ValidateTarget(target) then
        inst.lightning_target = target
        return BufferedAction(inst, nil, ACTIONS.THUNDERBIRD_CAST)
    end
end

local function GoHomeAction(inst)
    if inst.components.homeseeker then
        return BufferedAction(inst, inst.components.homeseeker:GetHome(), ACTIONS.GOHOME, nil, HomePos(inst))
    end

    return nil
end

local function RunAwayAction(inst)
    if ThreatInAttackRange(inst) then
        inst.is_fleeing = true
        if inst.components.timer:TimerExists("fleeing_cd") then
            inst.components.timer:SetTimeLeft("fleeing_cd", MAX_FLEE_TIME)
        else
            inst.components.timer:StartTimer("fleeing_cd", MAX_FLEE_TIME)
        end

        inst.Transform:SetFourFaced()
        inst.lightning_target = nil
        return true
    end
    return inst.is_fleeing
end

local function ShouldReturnHome(inst)
    if inst.components.health:IsDead() then
        return false
    end

    return not IsHome(inst) and (not IsNestEmpty(inst) or inst.components.inventory:NumItems() > 0) and not inst.is_fleeing
end


-- Missing animation
local function PickIronAction(inst)
    local target = FindEntity(inst, SEE_IRON_DIST, function(item)
        local x,y,z = item.Transform:GetWorldPosition()
        local isValidPosition = x and y and z
        local inventoryitem = item.components.inventoryitem

        local isValidPickupItem =
            isValidPosition and
            inventoryitem and
            not inventoryitem:IsHeld() and
            inventoryitem.canbepickedup and
            item:IsOnValidGround() and
            not item:HasTag("trap") and
            item.prefab == "iron"

        return isValidPickupItem
    end)

    if target ~= nil then
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    end
end

local function TargetAtChargeDistance(inst)
    if inst.components.health:IsDead() then
        return false
    end

    local function ReturnToDefault()
        if inst.charging and inst.sg.currentstate.name ~= "charge_pst" then
            inst:PushEvent("cancel_charge")
        end
    end

    local target = GetTarget(inst, CHARGE_DIST)
    if ValidateTarget(target) and not inst.is_fleeing then
        local distsq = inst:GetDistanceSqToInst(target)
        local keep_target = distsq <= CHARGE_DIST * CHARGE_DIST and distsq > ATTACK_DIST * ATTACK_DIST

        if not keep_target then
            ReturnToDefault()
        end

       return keep_target
    end

    ReturnToDefault()
    return false
end

local function ChargeFn(inst)
    if not inst.charging then
        inst:PushEvent("start_charging")
    end
end

local function FixAngle(target_angle)
    if target_angle > 360 then
        return target_angle % 360
    elseif target_angle < 0 then
        while target_angle < 0 do
            target_angle = target_angle + 360
        end
        return target_angle
    end
    return target_angle
end

local function assign_origin(inst)
    local origin_percents = {
        [FACING_DOWN] = 0,
        [FACING_RIGHT] = 0.25,
        [FACING_UP] = 0.5,
        [FACING_LEFT] = 0.75
    }

    inst.origin = origin_percents[inst.AnimState:GetCurrentFacing()]
    inst.current_percent = inst.origin
    inst.Transform:SetNoFaced()
end

local function TargetAtLookDistance(inst)
    if inst.charging or inst.components.health:IsDead() then
        return false
    end

    local function ReturnToDefault()
        if inst.lightning_target then
            inst:PushEvent("threat_gone")
        end
    end

    local target = GetTarget(inst, FACE_DIST)
    if ValidateTarget(target) and not inst.is_fleeing then

        local dist = inst:GetDistanceSqToInst(target)
        local keep = dist <= FACE_DIST * FACE_DIST and dist > CHARGE_DIST * CHARGE_DIST

        if keep then
            if inst.lightning_target == nil or inst.lightning_target ~= target then
                inst.lightning_target = target
                assign_origin(inst)
            end
        else
            ReturnToDefault()
        end

        return keep
    end

    ReturnToDefault()

    return false
end

local function LookAtFn(inst)
    if inst.components.locomotor ~= nil and inst.sg:HasStateTag("moving") then
        inst.components.locomotor:Stop()
    end

    local x1, _, z1 = inst.Transform:GetWorldPosition()
    local x2, _, z2 = inst.lightning_target.Transform:GetWorldPosition()

    local angle = math.atan2(z2 - z1, x2 - x1)

    if angle < 0 then
        angle = (2 * PI + angle)
    end

    angle = angle * 360 / (2 * PI)

    angle = FixAngle(angle - TheCamera:GetHeadingTarget())
    local percent = angle / 360

    if not inst.current_percent then
        assign_origin(inst)
    end

    local diff = percent > inst.current_percent and percent - inst.current_percent or inst.current_percent - percent
    -- Minimum percent for us to change frames
    if diff > 0.02 then
        -- Determines the orientation we're supposed to rotate towards
        if percent > inst.origin then
            if percent - inst.origin > 0.5 then
                inst.current_percent = inst.current_percent - 0.02
            elseif percent - inst.origin < 0.5 then
                inst.current_percent = inst.current_percent + 0.02
            end
        elseif percent < inst.origin then
            if inst.origin - percent > 0.5 then
                inst.current_percent = inst.current_percent + 0.02
            elseif inst.origin - percent < 0.5 then
                inst.current_percent = inst.current_percent - 0.02
            end
        end

        -- if we've gone over the edge of the animation this fixes it before setting it
        if inst.current_percent < 0 then
            inst.current_percent = 1 + inst.current_percent
        elseif inst.current_percent > 1 then
            inst.current_percent = inst.current_percent - 1
        end

        inst.AnimState:SetPercent("CCW", inst.current_percent)
    else
        -- We've reached the target, so this is our new origin
        inst.origin = inst.current_percent
    end
end

local ThunderbirdBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function ThunderbirdBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        IfNode(function() return ThreatInAttackRange(self.inst) and not self.inst.cooling_down end, "ThreatInRange",
            DoAction(self.inst, LightningAction, "ThreatInRange", false)),

        RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, function() return RunAwayAction(self.inst) end),

        IfNode(function() return not ThreatInAttackRange(self.inst) and TargetAtChargeDistance(self.inst) and not self.inst.cooling_down end, "Charge",
            DoAction(self.inst, ChargeFn, "Charging")),

        WhileNode(function() return ShouldReturnHome(self.inst) end, "FarFromHome",
            DoAction(self.inst, GoHomeAction, "Go Home", false)),

        WhileNode(function() return not TargetAtChargeDistance(self.inst) and TargetAtLookDistance(self.inst) end, "LookAt",
            DoAction(self.inst, LookAtFn, "Looking")),

        --IfNode(function() return IsNestEmpty(self.inst) and not self.inst.is_fleeing and self.inst.components.inventory:NumItems() < 1 end, "PickIron",
            --DoAction(self.inst, PickIronAction, "PickIron", false )),

        IfNode(function() return IsNestEmpty(self.inst) and not self.inst.is_fleeing end, "Wander",
            Wander(self.inst, HomePos, MAX_WANDER_DIST)),
    }, 0.1)

    self.bt = BT(self.inst, root)
end

return ThunderbirdBrain
