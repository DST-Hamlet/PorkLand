require("behaviours/wander")
require("behaviours/runaway")
require("behaviours/doaction")
require("behaviours/panic")
require("behaviours/chaseandattack")

local BrainCommon = require("brains/braincommon")

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_STOP = 6
local SEE_BAIT_DIST = 20
local MAX_WANDER_DIST = 20
local SEE_STOLEN_ITEM_DIST = 10
local MAX_CHASE_TIME = 8
local FIND_HOME_DIST = 30

local function HasHome(inst)
    return inst.components.homeseeker and inst.components.homeseeker:HasHome() and not inst.components.homeseeker.home:HasTag("burnt")
end

local MUST_TAGS = {"teatree"}
local CANT_AGS = {"stump", "burnt"}
local function FindHome(inst)
    if HasHome(inst) then
        return false
    end

    local home = FindEntity(inst, FIND_HOME_DIST, function(item)
        return not (item.components.spawner and item.components.spawner.child ~= nil)
    end, MUST_TAGS, CANT_AGS)

    if home then
        home:MakePikoNest(inst)
    end

    return true
end

local function GoHomeAction(inst)
    if not inst.sg:HasStateTag("trapped") then
        if not HasHome(inst) then
            FindHome(inst)
        end
        return BufferedAction(inst, inst.components.homeseeker:GetHome(), ACTIONS.GOHOME, nil, nil, nil, 0)
    end
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_BAIT_DIST, function(item)
        return inst.components.eater:CanEat(item)
    end)

    if target then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function()
            return not (target.components.inventoryitem and target.components.inventoryitem.owner)
        end

        return act
    end
end

local PICKUP_MUST_TAGS = { "_inventoryitem" }
local NO_PICKUP_TAGS = { "INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider", "piko", "trap", "_container", "smolder" }
local function PickupAction(inst)
    if inst.components.inventory:NumItems() < 1 then
        local target = FindEntity(inst, SEE_STOLEN_ITEM_DIST, function(item)
            return item.components.inventoryitem
                and not item.components.inventoryitem.owner
                and item.components.inventoryitem.canbepickedup
                and item:IsOnValidGround()
        end, PICKUP_MUST_TAGS, NO_PICKUP_TAGS)

        if target then
            return BufferedAction(inst, target, ACTIONS.PICKUP)
        end
    end
end

local PikoBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function PikoBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),

        WhileNode(function() return self.inst.components.inventory:NumItems() > 0 and HasHome(self.inst) end, "run off with prize",
            DoAction(self.inst, GoHomeAction, "go home", true)),

        DoAction(self.inst, PickupAction, "searching for prize", true),

        WhileNode(function() return self.inst.is_rabid end, "IsRabid", ChaseAndAttack(self.inst, MAX_CHASE_TIME)),

        RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),

        RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, nil, true),
            EventNode(self.inst, "gohome", DoAction(self.inst, GoHomeAction, "go home", true)),

        WhileNode(function()
            if TheWorld.state.phase == "night" and (TheWorld.state.moonphase == "full" or TheWorld.state.moonphase == "blood") then
                return false
            end
            return not TheWorld.state.isday end, "IsNight",
            DoAction(self.inst, GoHomeAction, "go home", true)),

        DoAction(self.inst, EatFoodAction),

        WhileNode(function() return FindHome(self.inst) end, "wander to find home", Wander(self.inst)),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return PikoBrain
