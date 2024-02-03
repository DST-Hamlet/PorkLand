require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"

local BrainCommon = require("brains/braincommon")

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5

local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_STOP = 6

local SEE_DUNG_DIST = 10
local MAX_WANDER_DIST = 50

local DungBeetleBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function DigDungAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target = FindEntity(inst, SEE_DUNG_DIST, function(item) return not inst:HasTag("hasdung") and item:HasTag("dungpile") end)
    if target ~= nil then
        local act = BufferedAction(inst, target, ACTIONS.DIGDUNG)
        act.validfn = function() return not inst:HasTag("hasdung") and target:HasTag("dungpile") end
        return act
    end
end

local function MountDungAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target = FindEntity(inst, SEE_DUNG_DIST, function(item)
        return not inst:HasTag("hasdung") and item:HasTag("dungball")
    end)

    if target ~= nil then
        inst.dung_target = target
        local act = BufferedAction(inst, target, ACTIONS.MOUNTDUNG)
        act.validfn = function() return not inst:HasTag("hasdung") and target:HasTag("dungball") end
        return act
    end
end

function DungBeetleBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function()
            return not self.inst.sg:HasStateTag("dungmounting") end, "Run Away",
            RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP)),
        WhileNode(function()
            return not self.inst.sg:HasStateTag("dungmounting") end, "Run Away",
            RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, nil, false)),
        DoAction(self.inst, MountDungAction, "Mount Dung"),
        DoAction(self.inst, DigDungAction, "Dig Dung"),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
    }, .25)

    self.bt = BT(self.inst, root)
end

return DungBeetleBrain
