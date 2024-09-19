require("behaviours/chaseandattack")
require("behaviours/doaction")
require("behaviours/faceentity")
require("behaviours/follow")
require("behaviours/panic")
require("behaviours/wander")

local BrainCommon = require("brains/braincommon")

local EAT_FOOD_DIST = 30

local MAX_CHASE_TIME = 4
local MAX_CHASE_DIST = 25

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 12
local TARGET_FOLLOW_DIST = 6
local FOLLOWPLAYER_DIST = 30

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6

local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5
local BARK_AT_FRIEND_DIST = 12

local BARK_CHANCE = 0.01
local BARK_CHANCE_POG_PROOF = 0.05

local EAT_FOOD_NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "poisonous"}

local RANSACK_NO_TAGS = {"pogproof", "aquatic", "fire", "smolder", "bundle", "INLIMBO", "pocketdimension_container", "pogged"}
local RANSACK_ONE_OF_TAGS = {"structure", "portablestorage"}

local POG_TAGS = {"pog"}

local BRAK_AT_ONE_OF_TAGS = {"pog", "pogproof"}

local function EatFoodAction(inst)
    local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)

    if not target then
        target = FindEntity(inst, EAT_FOOD_DIST, function(item)
            return inst.components.eater:CanEat(item)
                and item:IsOnValidGround()
                and item:GetTimeAlive() > TUNING.POG_EAT_DELAY
        end, nil, EAT_FOOD_NO_TAGS)

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, EAT_FOOD_DIST, POG_TAGS)

        for _, ent in pairs(ents) do
            -- if another nearby pog is already going to this food, maybe go after it?
            if ((ent.components.locomotor.bufferedaction and ent.components.locomotor.bufferedaction.target and ent.components.locomotor.bufferedaction.target == target) or
                (inst.bufferedaction and inst.bufferedaction.target and inst.bufferedaction.target == target)) and ent ~= inst then
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

local function DoRansack(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, EAT_FOOD_DIST, nil, RANSACK_NO_TAGS, RANSACK_ONE_OF_TAGS, RANSACK_NO_TAGS)

    local containers = {}
    for _, ent in pairs(ents) do
        if ent.components.container or ent.components.container_proxy then
            containers[#containers + 1] = ent
        end
    end

    if next(containers) then
        local container = containers[math.random(1, #containers)]

        local master = container.components.container_proxy and container.components.container_proxy:GetMaster() or container
        if not master.components.container.canbeopened then
            return
        end

        local items = master.components.container:GetAllItems()
        if next(items) then
            return BufferedAction(inst, container, ACTIONS.RANSACK)
        end
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:IsNear(target, KEEP_FACE_DIST) and not target:HasTag("notarget")
end

local function GetWanderDistFn(inst)
    if TheWorld.state.isday then
        return WANDER_DIST_NIGHT
    else
        return WANDER_DIST_DAY
    end
end

local function GetHarassTarget(inst)
    local target
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, FOLLOWPLAYER_DIST, true)
    for _, player in pairs(players) do
        if player.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end) then
            target = player
            break
        end
    end

    if not target or target:HasTag("sailing") then
        return
    end

    return target
end

local function DoBark(inst)
    local target = FindEntity(inst, BARK_AT_FRIEND_DIST, function(ent)
        return (ent.sg and ent.sg:HasStateTag("idle")) or ent:HasTag("pogproof")
    end, nil, nil, BRAK_AT_ONE_OF_TAGS)

    if target and ((target:HasTag("pogproof") and math.random() < BARK_CHANCE_POG_PROOF) or math.random() < BARK_CHANCE) then
        return BufferedAction(inst, target, ACTIONS.BARK)
    end
end

local PogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function PogBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),

        DoAction(self.inst, function() return EatFoodAction(self.inst) end, "Eat", true),

        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),

        DoAction(self.inst, function() return DoRansack(self.inst) end, "ransack", true),

        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),

        Follow(self.inst, function() return GetHarassTarget(self.inst) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),

        DoAction(self.inst, function() return DoBark(self.inst) end, "Bark at friend", true),

        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("herd") end, GetWanderDistFn)
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return PogBrain
