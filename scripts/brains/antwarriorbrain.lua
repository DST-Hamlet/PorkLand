require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
--require "behaviours/choptree"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local BrainCommon = require "brains/braincommon"
local MAX_CHASE_TIME = 40

local function HasValidHome(inst)
    return inst.components.homeseeker and
       inst.components.homeseeker.home and
       not inst.components.homeseeker.home:HasTag("fire") and
       not inst.components.homeseeker.home:HasTag("burnt") and
       inst.components.homeseeker.home:IsValid()
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetWanderPoint(inst)
    local player = GetClosestInstWithTag("player", inst, TUNING.ANTMAN_WARRIOR_ATTACK_ON_SIGHT_DIST)
    return GetHomePos(inst) or (player and player:GetPosition())
end

local function translationfn(inst)
    local player = GetClosestInstWithTag("player", inst, TUNING.ANTMAN_WARRIOR_ATTACK_ON_SIGHT_DIST)
    if player:HasTag("antlingual") then
        return true
    else
        return false
    end
end

local function makechatpackage(speech)
return {
        chatlines = speech,
        untranslated = STRINGS.ANT_TALK_UNTRANSLATED,
        translationfn = translationfn
    }
end

local function shouldPanic(inst)
    if inst.components.combat.target then
        local threat = inst.components.combat.target
        if threat then
            if threat.components.inventory then
                local equipped = threat.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                return equipped and equipped.prefab == "magnifying_glass"
            end
        end
    end

    return false
end

local AntWarriorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AntWarriorBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst) ),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        Wander(self.inst, GetWanderPoint, 20),

    }, .1)

    self.bt = BT(self.inst, root)
end

return AntWarriorBrain
