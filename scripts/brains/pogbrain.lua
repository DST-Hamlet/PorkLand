require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"
require "behaviours/runaway"
require "behaviours/leash"
require "behaviours/doaction"
require "behaviours/chaseandattack"

local BrainCommon = require "brains/braincommon"

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 12
local TARGET_FOLLOW_DIST = 6
local FOLLOWPLAYER_DIST = TUNING.POG_SEE_FOOD

local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5
local BARK_AT_FRIEND_DIST = 12

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6

local LEASH_RETURN_DIST = 15
local LEASH_MAX_DIST = TUNING.POG_SEE_FOOD

local MAX_CHASE_TIME = 4
local MAX_CHASE_DIST = 10

local AVOID_DIST = 3
local AVOID_STOP = 10

local NO_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "stump", "burnt"}
local PLAY_TAGS = {"cattoy", "cattoyairborne", "catfood"}

local PogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function EatFoodAction(inst)
    local target = nil

    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
    end
    if not target then
        local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
        target = FindEntity(inst, TUNING.POG_SEE_FOOD, function(item) return inst.components.eater:CanEat(item) and not item:HasTag("poisonous") and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.POG_EAT_DELAY end, nil, notags)

        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, TUNING.POG_SEE_FOOD, {"pog"})
        for i,ent in ipairs(ents)do

            -- if another nearby pog is already going to this food, maybe go after it?
            if ((ent.components.locomotor.bufferedaction and ent.components.locomotor.bufferedaction.target and ent.components.locomotor.bufferedaction.target == target) or
                (inst.bufferedaction and inst.bufferedaction.target and inst.bufferedaction.target == target) )
                and ent ~= inst then
                if math.random() < 0.9 then
                    return nil
                end
            end
        end
    end
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function GetWanderDistFn(inst)
    if TheWorld and not TheWorld:IsDay() then
        return WANDER_DIST_NIGHT
    else
        return WANDER_DIST_DAY
    end
end

local function barkatfriend(inst)

    local target = FindEntity(inst, BARK_AT_FRIEND_DIST, function(item) return (item.sg and item.sg:HasStateTag("idle")) or item:HasTag("pogproof") end, nil,nil,{"pog","pogproof"}) --  item:HasTag("pog") and
    if target and ((target:HasTag("pogproof") and math.random() < 0.05) or math.random() < 0.01) then
        return BufferedAction(inst, target, ACTIONS.BARK)
    end
end

local function ransack(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, TUNING.POG_SEE_FOOD, {"structure"},{"pogproof"})
    local containers = {}
    for i, ent in ipairs(ents) do
        if ent.components.container then
            table.insert(containers,ent)
        end
    end

    if #containers > 0 then
        local container = containers[math.random(1,#containers)]

        local items = container.components.container:FindItems(function() return true end)
        if #items > 0 then
            return BufferedAction(inst, container, ACTIONS.RANSACK)
        end
    end
end

local function harassPlayer(inst)
    local target = GetClosestInstWithTag("player", inst , 30)
    if target then
    local item = nil

    local p_pt = Vector3(target.Transform:GetWorldPosition())
    local m_pt = Vector3(inst.Transform:GetWorldPosition())

        if target then
            item = target.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end )
        end
                                                                                                                                                --还不能划船呢
        if item and distsq(p_pt, m_pt) < FOLLOWPLAYER_DIST * FOLLOWPLAYER_DIST then --and not (target and target.components.driver and target.components.driver:GetIsDriving()) then
            return target
        end
    end
end

local function SuggestTarget(inst)
    local player = GetClosestInstWithTag("player", inst, 15)
    if player then
        inst.components.combat:SuggestTarget(player)
    end
end

function PogBrain:OnStart()
    local root =
    PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function() return self.inst:HasTag("fire") or self.inst.components.health.takingfiredamage end, "Panic", Panic(self.inst)),
        DoAction(self.inst, function() return EatFoodAction(self.inst) end, "Eat", true),

        -- IfNode ( function() return GetAporkalypse() and GetAporkalypse():IsActive() end, "AporkalypseActive",
        -- DoAction(self.inst, function() SuggestTarget(self.inst) end)),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

        DoAction(self.inst, function() return ransack(self.inst) end, "ransack", true),

        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Follow(self.inst, function() return harassPlayer(self.inst) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),

        DoAction(self.inst, function() return barkatfriend(self.inst) end, "Bark at friend", true),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("herd") end, GetWanderDistFn)
    }, .25)
    self.bt = BT(self.inst, root)
end

return PogBrain
