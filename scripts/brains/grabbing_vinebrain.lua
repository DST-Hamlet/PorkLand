require("behaviours/doaction")
require("behaviours/standandattack")
require("behaviours/standstill")

local BrainCommon = require("brains/braincommon")

local GO_HOME_DIST = 1
-- local EAT_DIST = 0.5
local SEE_DIST = 5

local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}

local function IsUp(inst)
    return inst.sg:HasStateTag("up")
end

local function GoHomeAction(inst)
    local home_pos = inst.components.knownlocations:GetLocation("home")
    if home_pos and inst:GetDistanceSqToPoint(home_pos) > GO_HOME_DIST * GO_HOME_DIST and not IsUp(inst) then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, home_pos, nil, 0.2)
    end
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_DIST, function(item)
        return inst.components.eater:CanEat(item) and item:IsOnPassablePoint()
    end, nil, NO_TAGS, inst.components.eater:GetEdibleTags())

    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local GrabbingvineBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function GrabbingvineBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function() return not IsUp(self.inst) end, "GoEatFood",
            DoAction(self.inst, function() return EatFoodAction(self.inst) end, "eat food", true, math.random(5, 8))),
        WhileNode(function() return not IsUp(self.inst) end, "StandAndAttack",
            StandAndAttack(self.inst)),
        SelectorNode({
            DoAction(self.inst, function() return GoHomeAction(self.inst) end, "go home", true),
            WhileNode(function()
                local is_up = IsUp(self.inst)
                if self.inst.near then
                    if is_up then
                        self.inst.sg:GoToState("down")
                    end
                elseif not is_up then
                    self.inst.sg:GoToState("up")
                end
            end, "near"),
        }),
    }, .25)

    self.bt = BT(self.inst, root)
end

return GrabbingvineBrain
