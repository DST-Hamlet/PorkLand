require("behaviours/doaction")
require("behaviours/standandattack")
require("behaviours/standstill")

local GO_HOME_DIST = 1
local EAT_DIST = 0.5

local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}

local function IsUp(inst)
    return inst.sg and inst.sg:HasStateTag("up")
end

local function GoHomeAction(inst)
    local home_pos = inst.components.knownlocations:GetLocation("home")
    if home_pos then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, home_pos, nil, 0.2)
    end
end

local function ShouldGoHome(inst)
    local home_pos = inst.components.knownlocations:GetLocation("home")
    local pos = inst:GetPosition()
    return (home_pos and distsq(home_pos, pos) > GO_HOME_DIST * GO_HOME_DIST) and not IsUp(inst)
end

local GrabbingvineBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function FoodNear(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5, nil, NO_TAGS)

    for i = #ents, 1, -1 do
        if not ents[i] or ents[i]:IsInLimbo() or not inst.components.eater:CanEat(ents[i]) then
            table.remove(ents,i)
        end
    end

    if #ents > 0 then
        return ents[1]
    end
end

local function GoEatFood(inst)
    if not IsUp(inst) then
        local target = inst.foodtarget
        if not target or not target:IsInLimbo() then
            target = FoodNear(inst)
        end
        if target and not target:IsInLimbo()  then
            inst.foodtarget = target
            local target_pos = target:GetPosition()
            local pos = inst:GetPosition()

            if target_pos and distsq(target_pos, pos) > EAT_DIST * EAT_DIST then
                return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, target_pos, nil, 0.2)
            else
                return BufferedAction(inst, target, ACTIONS.EAT)
            end
        end
    end
    return false
end

function GrabbingvineBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return ((self.inst.foodtarget and not self.inst.foodtarget:IsInLimbo()) or FoodNear(self.inst)) and not IsUp(self.inst) end, "GoEatFood",
            DoAction(self.inst, function() return GoEatFood(self.inst) end, "eat food", true, math.random(5, 8))),
        WhileNode(function() return not IsUp(self.inst) end, "StandAndAttack",
            StandAndAttack(self.inst)),
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, function() return GoHomeAction(self.inst) end, "go home", true)),
        WhileNode(function()
            if self.inst.near then
                if IsUp(self.inst) then
                    self.inst.sg:GoToState("down")
                    return true
                end
            elseif not IsUp(self.inst) then
                self.inst.sg:GoToState("up")
            end
        end, "near"),
        StandStill(self.inst, function() return self.inst.sg:HasStateTag("idle") end, nil),
    }, .25)

    self.bt = BT(self.inst, root)
end

return GrabbingvineBrain
