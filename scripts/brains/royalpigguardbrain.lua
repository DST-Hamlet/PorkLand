require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
-- require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

require("brains/citypigbrain") -- for getfacespeech

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 30

local GO_HOME_DIST = 10
local GO_HOME_COMBAT_DIST = 60

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 8

-- local START_RUN_DIST = 3
-- local STOP_RUN_DIST = 5

local MAX_CHASE_TIME = 100
local MAX_CHASE_DIST = 300

local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_FOOD_DIST = 10
local SEE_MONEY_DIST = 6
local CLOSE_ITEM_DIST = 1.5

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

local FAR_ENOUGH = 40

local function GetFaceTargetFn(inst)
    if inst.components.follower.leader then
        return inst.components.follower.leader
    end
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    if target and not target:HasTag("notarget") then
       -- inst.sg:GoToState("greet")
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    if inst.components.follower.leader then
        return inst.components.follower.leader == target
    end
    return inst:IsNear(target, KEEP_FACE_DIST) and not target:HasTag("notarget")
end

local function GetTraderFn(inst)
    return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end, {"player"})
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function FindFoodAction(inst)
    local target = nil

    if inst.sg:HasStateTag("busy") then
        return
    end

    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
    end

    local time_since_eat = inst.components.eater:TimeSinceLastEating()
    local noveggie = time_since_eat and time_since_eat < TUNING.PIG_MIN_POOP_PERIOD*4

    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD*2) then
        target = FindEntity(inst, SEE_FOOD_DIST, function(item)
                if item:GetTimeAlive() < 8 then return false end
                if item.prefab == "mandrake" then return false end
                if noveggie and item.components.edible and item.components.edible.foodtype ~= "MEAT" then
                    return false
                end
                if not item:IsOnValidGround() then
                    return false
                end
                return inst.components.eater:CanEat(item)
            end)
    end
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end

    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD*2) then
        target = FindEntity(inst, SEE_FOOD_DIST, function(item)
                if not item.components.shelf then return false end
                if not item.components.shelf.itemonshelf or not item.components.shelf.cantakeitem then return false end
                if noveggie and item.components.shelf.itemonshelf.components.edible and item.components.shelf.itemonshelf.components.edible.foodtype ~= "MEAT" then
                    return false
                end
                if not item:IsOnValidGround() then
                    return false
                end
                return inst.components.eater:CanEat(item.components.shelf.itemonshelf)
            end)
    end

    if target then
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    end
end

local PICKUP_OINC_MUST_TAGS = {"_inventoryitem", "oinc"}
local PICKUP_OINC_NO_TAGS = {"INLIMBO", "outofreach", "trap"}

local function OincNearby(inst, dist)
    return FindEntity(inst, dist or SEE_MONEY_DIST, function(item)
        return item.components.inventoryitem.canbepickedup and item:IsOnValidGround()
    end, PICKUP_OINC_MUST_TAGS, PICKUP_OINC_NO_TAGS)
end

local function FindMoneyAction(inst)
    local target = OincNearby(inst)

    if target then
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    end
end

local function checknotangry(inst)
    if IsTableEmpty(inst.angry_at_criminals) then
        return true
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4, {"_combat"}, {"FX", "NOCLICK", "DECOR", "INLIMBO"})
    for _, ent in ipairs(ents) do
        if ent.components.uniqueidentity
            and inst.angry_at_criminals[ent.components.uniqueidentity:GetID()]
            and inst.angry_at_criminals[ent.components.uniqueidentity:GetID()] > 0 then
            return false
        end
        if ent:HasTag("sneaky") then
            return false
        end
    end
    return true
end

local function HasValidHome(inst)
    return inst.components.homeseeker and
       inst.components.homeseeker.home and
       not inst.components.homeseeker.home:HasTag("fire") and
       not inst.components.homeseeker.home:HasTag("burnt") and
       inst.components.homeseeker.home:IsValid()
end


local function GuardGoHomeAction(inst)
    if TheWorld.state.isaporkalypse and HasValidHome(inst) then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end

    local homePos = inst.components.knownlocations:GetLocation("home")
    if homePos then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, homePos)
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetNoLeaderHomePos(inst)
    if GetLeader(inst) then
        return nil
    end
    return GetHomePos(inst)
end


local RoyalPigGuardBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


local function should_panic(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, {"monster", "bandit"}, {"city_pig", "INLIMBO", "shadowcreature", "bramble"})
    if #ents > 0 then
        return true
    end

    if inst.components.combat.target then
        local threat = inst.components.combat.target
        if threat then
            local dist = inst:GetDistanceSqToInst(threat)

            if dist >= FAR_ENOUGH * FAR_ENOUGH then
                inst.components.combat:GiveUp()

            elseif dist > STOP_RUN_AWAY_DIST * STOP_RUN_AWAY_DIST then
                -- Panic instead of running away.
                return true
            end
        end
    end

    return false
end

local function ShouldGoHome(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = inst:GetPosition()

    -- eating food allows them to overide their home leash
    local action = inst:GetBufferedAction()
    if action and action.action.id == "EAT" then
        homePos = nil
    end

    return (homePos and distsq(homePos, myPos) > GO_HOME_DIST*GO_HOME_DIST ) or (TheWorld.state.isaporkalypse and HasValidHome(inst))
end

local function ShouldGoHomeInCombat(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = inst:GetPosition()

    -- eating food allows them to overide their home leash
    local action = inst:GetBufferedAction()
    if action and action.action.id == "EAT" then
        homePos = nil
    end

    local target = inst.components.combat.target
    local istargetnear = target and inst.components.combat:CanHitTarget(target)

    return (TheWorld.state.isaporkalypse and HasValidHome(inst))
        or (homePos and distsq(homePos, myPos) > GO_HOME_COMBAT_DIST*GO_HOME_COMBAT_DIST and not istargetnear and not GetLeader(inst) )
end

local function KeepGoHomeInCombat(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = inst:GetPosition()

    -- eating food allows them to overide their home leash
    local action = inst:GetBufferedAction()
    if action and action.action.id == "EAT" then
        homePos = nil
    end

    local target = inst.components.combat.target
    local istargetnear = target and inst.components.combat:CanHitTarget(target)

    return (TheWorld.state.isaporkalypse and HasValidHome(inst))
        or (homePos and distsq(homePos, myPos) > GO_HOME_DIST*GO_HOME_DIST and not istargetnear and not GetLeader(inst) )
end

local function inCityLimits(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, FAR_ENOUGH, {"citypossession"}, {"city_pig"})
    if #ents > 0 then
        return true
    end
    if inst.components.combat.target then
        inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_STAYOUT"))
        inst.components.combat:GiveUp()
    end
    return false
end

local function ExtinguishfireAction(inst)
    if not inst:HasTag("guard") then
        return false
    end

    -- find fire
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, FAR_ENOUGH / 2, {"campfire"})
    for _, ent in ipairs(ents) do
        if ent.components.burnable and ent.components.burnable:IsBurning() then
            local tiletype = TheWorld.Map:GetTileAtPoint(x, y, z)
            if tiletype == WORLD_TILES.SUBURB or tiletype == WORLD_TILES.FOUNDATION or tiletype == WORLD_TILES.COBBLEROAD or tiletype == WORLD_TILES.LAWN or tiletype == WORLD_TILES.FIELDS then
                return BufferedAction(inst, ent, ACTIONS.MANUALEXTINGUISH)
            end
        end
    end
    return false
end

local function playersproblem(inst)
    if inst.components.combat.target and inst.components.combat.target:HasTag("scary_to_pig_guards") and
        (not inst.components.follower.leader or not inst.components.follower.leader:HasTag("player")) then
        return true
    end
    return false
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

local function ChatterSay(str)
    return function(inst)
        inst:SayLine(inst:GetSpeechType(str))
    end
end

function RoyalPigGuardBrain:OnStart()
    --print(self.inst, "RoyalPigGuardBrain:OnStart")
    local day = WhileNode( function() return TheWorld.state.isday end, "IsDay",
        PriorityNode {

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIND_MEAT"),
                DoAction(self.inst, FindFoodAction )),

            Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),

            IfNode(function() return not self.inst.alerted end, "greet",
                ChattyNode(self.inst, getfacespeech(),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn))),

            Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
        }, .5)


    local night = WhileNode( function() return not TheWorld.state.isday end, "IsNight",
        PriorityNode {

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIND_MEAT"),
                DoAction(self.inst, FindFoodAction )),
            IfNode(function() return self.inst:HasTag("guard") end, "panic",
                Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)),
        }, 1)

    local root =
        PriorityNode(
        {
            -- TODO: Add in custom panic speech
            WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FLEE"),
                    Panic(self.inst))),

            WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_PANICFIRE"),
                    Panic(self.inst))),

            IfNode(function() return ShouldGoHomeInCombat(self.inst) end, "ShouldGoHomeInCombat",
                WhileNode(function() return KeepGoHomeInCombat(self.inst) and self.inst:HasTag("guard") end, "KeepGoHomeInCombat",
                    ChattyNode(self.inst, ChatterSay("CITY_PIG_GUARD_TALK_GOHOME"),
                        DoAction(self.inst, GuardGoHomeAction, "Go Home", true )))),

            --AttackWall(self.inst),
            -- GUARD SECTION
            WhileNode(function() return checknotangry(self.inst) end, "not angry",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIND_MONEY"),
                    DoAction(self.inst, FindMoneyAction ))),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_PROTECT"),
                WhileNode( function() return (self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown()) and self.inst:HasTag("guard") and not playersproblem(self.inst) end, "AttackMomentarily", -- and inCityLimits(self.inst)
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST) )),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_GUARD_TALK_RESCUE"),
                WhileNode( function() return GetLeader(self.inst) and GetLeader(self.inst).components.pinnable and GetLeader(self.inst).components.pinnable:IsStuck() end, "Leader Phlegmed",
                    DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true) )),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_EXTINGUISH"),
                    DoAction(self.inst, ExtinguishfireAction,"extinguish", true )),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIGHT"),
                WhileNode( function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() and self.inst:HasTag("guard") end, "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) )--[[, "alarmed"]]),

            -- FOLLOWER CODE
            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FOLLOWWILSON"),
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),
            IfNode(function() return GetLeader(self.inst) end, "has leader",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FOLLOWWILSON"),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn ))),
            -- END FOLLOWER CODE

            WhileNode(function() return ShouldGoHome(self.inst) and self.inst:HasTag("guard") end, "ShouldGoHome",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_GUARD_TALK_GOHOME"),
                    DoAction(self.inst, GuardGoHomeAction, "Go Home", true ) ) ),
            -- END GUARD SECTION

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FLEE"),
                WhileNode(function() return should_panic(self.inst)  end, "Threat Panic",
                    Panic(self.inst) )--[[, "alarmed"]]),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_ATTEMPT_TRADE"),
                FaceEntity(self.inst, GetTraderFn, KeepTraderFn)),
            day,
            night
        }, .5)

    self.bt = BT(self.inst, root)

end

return RoyalPigGuardBrain
