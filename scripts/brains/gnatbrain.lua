require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/panic")
require("behaviours/findlight")
require("behaviours/follow")

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 20
local AGRO_DIST = 5

local function ShouldChaseLight(inst)
    return TheWorld.state.isdusk or TheWorld.state.isnight or inst:GetCurrentInteriorID() ~= nil
end

local function GetLightTarget(inst)
    return inst:FindLight()
end

local function GetInfestTarget(inst)
    if inst.components.freezable:IsFrozen() then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRange(x, y, z, AGRO_DIST, true)

    -- hiding is for bush hat
    if not target or target:HasTag("hiding") or target:HasTag("notarget") or target:HasTag("playerghost") or inst.components.infester.infested then
        return false
    end

    return BufferedAction(inst, target, ACTIONS.INFEST)
end

local function MakeNest(inst)
    if not inst.components.timer:TimerExists("build_mount_cd") and not inst.components.homeseeker:HasHome() then
        local x, y, z = inst.Transform:GetWorldPosition()
        if not inst.CanBuildMoundAtPoint(x, y, z) then
            return
        end

        return BufferedAction(inst, nil, ACTIONS.BUILD_MOUND)
    end
end

local GnatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function GnatBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return not self.inst.components.infester.infested end, "not infesting",
            PriorityNode{
                BrainCommon.PanicTrigger(self.inst),

                WhileNode(function() return ShouldChaseLight(self.inst) end, "Chase Light",
                    Follow(self.inst, function() return GetLightTarget(self.inst) end, 0, 1, 1)),

                WhileNode(function() return not self.inst.components.infester.infested end, "not infesting",

                DoAction(self.inst, function() return GetInfestTarget(self.inst) end, "infest", true)),

                DoAction(self.inst, function() return MakeNest(self.inst) end, "make nest", true),

                Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
            } , 0.5)
    }, 1)


    self.bt = BT(self.inst, root)
end

return GnatBrain

