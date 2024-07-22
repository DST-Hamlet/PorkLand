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


local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 30

local GO_HOME_DIST = 10

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 8

-- local START_RUN_DIST = 3
-- local STOP_RUN_DIST = 5

local MAX_CHASE_TIME = 10  
local MAX_CHASE_DIST = 30 

local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_FOOD_DIST = 10
local SEE_MONEY_DIST = 6

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

local FAR_ENOUGH = 40

local function getSpeechType(inst,speech)
    local line = speech.DEFAULT

    if inst.talkertype and speech[inst.talkertype] then
        line = speech[inst.talkertype]
    end
    return line
end

local function getString(speech)
    if type(speech) == "table" then
        return speech[math.random(#speech)]
    else
        return speech
    end 
end

local function GetFaceTargetFn(inst)
    if inst.components.follower.leader then
        return inst.components.follower.leader
    end
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
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

local function ShouldRunAway(inst, target)
    return not inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GetTraderFn(inst)
    return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end, {"player"})
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GreetAction(inst)
    if GetClosestInstWithTag("player", inst, START_FACE_DIST) then
        inst.sg:GoToState("greet")
        return true
    end
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

local function FindMoneyAction(inst)
    local target = FindEntity(inst, SEE_MONEY_DIST, function(item)
                if not item:IsOnValidGround() then
                    return false
                end            
               -- local itempos = Vector3(item.Transform:GetWorldPosition())
               -- local instpos = Vector3(inst.Transform:GetWorldPosition())
                --and GetWorld().Pathfinder:IsClear(itempos.x, itempos.y, itempos.z, instpos.x, instpos.y, instpos.z,  {ignorewalls = false})
                return item.prefab == "oinc" or item.prefab == "oinc10"
            end)    
    if target then        
        return BufferedAction(inst, target, ACTIONS.PICKUP)
    end
end

local function checknotangry(inst)
    return not inst:HasTag("angry_at_player") or inst:GetDistanceSqToInst(GetPlayer()) > 4*4  
end

local function KeepChoppingAction(inst)
    local keep_chop = inst.components.follower.leader and inst.components.follower.leader:GetDistanceSqToInst(inst) <= KEEP_CHOPPING_DIST*KEEP_CHOPPING_DIST
    local target = FindEntity(inst, SEE_TREE_DIST/3, function(item)
        return item.prefab == "deciduoustree" and item.monster and item.components.workable and item.components.workable.action == ACTIONS.CHOP 
    end)    
    if inst.tree_target ~= nil then target = inst.tree_target end

    return (keep_chop or target ~= nil)
end

local function StartChoppingCondition(inst)
    local start_chop = inst.components.follower.leader and inst.components.follower.leader.sg and inst.components.follower.leader.sg:HasStateTag("chopping")
    local target = FindEntity(inst, SEE_TREE_DIST/3, function(item) 
        return item.prefab == "deciduoustree" and item.monster and item.components.workable and item.components.workable.action == ACTIONS.CHOP 
    end)
    if inst.tree_target ~= nil then target = inst.tree_target end
    
    return (start_chop or target ~= nil)
end


local function FindTreeToChopAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, function(item) return item.components.workable and item.components.workable.action == ACTIONS.CHOP end)
    if target then
        local decid_monst_target = FindEntity(inst, SEE_TREE_DIST/3, function(item)
            return item.prefab == "deciduoustree" and item.monster and item.components.workable and item.components.workable.action == ACTIONS.CHOP 
        end)
        if decid_monst_target ~= nil then 
            target = decid_monst_target 
        end
        if inst.tree_target then 
            target = inst.tree_target
            inst.tree_target = nil 
        end
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

local function HasValidHome(inst)
    return inst.components.homeseeker and 
       inst.components.homeseeker.home and 
       not inst.components.homeseeker.home:HasTag("fire") and
       not inst.components.homeseeker.home:HasTag("burnt") and
       inst.components.homeseeker.home:IsValid()
end


local function GuardGoHomeAction(inst)
    
    local aporkalypse = GetAporkalypse()
    if aporkalypse and aporkalypse:IsActive() and HasValidHome(inst) then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end

    local homePos = inst.components.knownlocations:GetLocation("home")
    if homePos and 
       not inst.components.combat.target then
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


local function shouldPanic(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 20, {"hostile"}, {"city_pig", "INLIMBO", "shadowcreature", "bramble"}) 
    if #ents > 0 then
        return true
    end

    if inst.components.combat.target then
        local threat = inst.components.combat.target
        if threat then
            local dist = inst:GetHorzDistanceSqToInst(threat)

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
    local myPos = Vector3(inst.Transform:GetWorldPosition() )

    local aporkalypse = GetAporkalypse()

    -- eating food allows them to overide their home leash
    local action = inst:GetBufferedAction()
    if action and action.action.id ==  "EAT" then
        homePos =  nil
    end

    return (homePos and distsq(homePos, myPos) > GO_HOME_DIST*GO_HOME_DIST ) or (aporkalypse and aporkalypse:IsActive() and HasValidHome(inst))
end

local function inCityLimits(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, FAR_ENOUGH, {"citypossession"},{"city_pig"}) 
    if #ents > 0 then
        return true
    end
    if inst.components.combat.target then

        local speechset = getSpeechType(inst,STRINGS.CITY_PIG_TALK_STAYOUT)
        local str = speechset[math.random(#speechset)]
        
        inst.sayline(inst, str)
        --inst.components.talker:Say(str)

        inst.components.combat:GiveUp()
    end
    return false
end

local function ExtinguishfireAction(inst)

    if not inst:HasTag("guard") then
        return false
    end

    -- find fire
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, FAR_ENOUGH/2, {"campfire"}) 
    if #ents == 0 then
        return false
    end

    local target = nil
    for i, ent in ipairs(ents) do
        if ent.components.burnable and ent.components.burnable:IsBurning() then
            local pt = inst:GetPosition()
            local tiletype = GetGroundTypeAtPosition(pt)

            if tiletype == GROUND.SUBURB or tiletype == GROUND.FOUNDATION or tiletype == GROUND.COBBLEROAD or tiletype == GROUND.LAWN or tiletype == GROUND.FIELDS then
                target = ent
                break
            end
        end
    end

    if target then
        return BufferedAction(inst, target, ACTIONS.MANUALEXTINGUISH)
    end
end

local function playersproblem(inst)
    if inst.components.combat.target and inst.components.combat.target:HasTag("scary_to_pig_guards") and 
        (not inst.components.follower.leader or inst.components.follower.leader ~= GetPlayer()) then 
        return true
    end
    return false        
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

function RoyalPigGuardBrain:OnStart()
    --print(self.inst, "RoyalPigGuardBrain:OnStart")
    local clock = GetClock()
      
    local day = WhileNode( function() return clock and clock:IsDay() end, "IsDay",
        PriorityNode{


            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FIND_MEAT),
                DoAction(self.inst, FindFoodAction )),
            IfNode(function() return StartChoppingCondition(self.inst) end, "chop", 
                WhileNode(function() return KeepChoppingAction(self.inst) end, "keep chopping",
                    LoopNode{ 
                        ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_HELP_CHOP_WOOD),
                            DoAction(self.inst, FindTreeToChopAction ))})),

            Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),

            IfNode(function() return not self.inst.alerted end, "greet",
                ChattyNode(self.inst, getfacespeech(self.inst),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn))),
            
            Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
        },.5)
        
    
    local night = WhileNode( function() return clock and not clock:IsDay() end, "IsNight",
        PriorityNode{
            
            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FIND_MEAT),
                DoAction(self.inst, FindFoodAction )),
            --RunAway(self.inst, "player", START_RUN_DIST, STOP_RUN_DIST, function(target) return ShouldRunAway(self.inst, target) end ),
            
            IfNode(function() return self.inst:HasTag("guard") end, "panic",
                Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)),
        },1)

    local root = 
        PriorityNode(
        {
            WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
                ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_PANICFIRE),
                    Panic(self.inst))),

            --AttackWall(self.inst),
            -- GUARD SECTION
            WhileNode(function() return checknotangry(self.inst) end, "not angry",
                ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FIND_MONEY),
                    DoAction(self.inst, FindMoneyAction ))),

            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_PROTECT),
                WhileNode( function() return (self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown()) and self.inst:HasTag("guard") and not playersproblem(self.inst) end, "AttackMomentarily", -- and inCityLimits(self.inst)
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST) )),

            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_GUARD_TALK_RESCUE),
                WhileNode( function() return GetLeader(self.inst) and GetLeader(self.inst).components.pinnable and GetLeader(self.inst).components.pinnable:IsStuck() end, "Leader Phlegmed",
                    DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true) )),

            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_EXTINGUISH),                
                    DoAction(self.inst, ExtinguishfireAction,"extinguish", true )),

            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FIGHT),
                WhileNode( function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() and self.inst:HasTag("guard") end, "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) ),"alarmed"),         

            -- FOLLOWER CODE
            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FOLLOWWILSON), 
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),
            IfNode(function() return GetLeader(self.inst) end, "has leader",
                ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FOLLOWWILSON),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn ))),
            -- END FOLLOWER CODE

            WhileNode(function() return ShouldGoHome(self.inst) and self.inst:HasTag("guard") end, "ShouldGoHome",
                ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_GUARD_TALK_GOHOME),
                    DoAction(self.inst, GuardGoHomeAction, "Go Home", true ) ) ),     
            -- END GUARD SECTION

            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_FLEE),
                WhileNode(function() return shouldPanic(self.inst)  end, "Threat Panic",
                    Panic(self.inst) ),"alarmed"),

            RunAway(self.inst, function(guy) return guy:HasTag("pig") and guy.components.combat and guy.components.combat.target == self.inst end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST ),

            ChattyNode(self.inst, getSpeechType(self.inst,STRINGS.CITY_PIG_TALK_ATTEMPT_TRADE),
                FaceEntity(self.inst, GetTraderFn, KeepTraderFn)),
            day,
            night
        }, .5)
    
    self.bt = BT(self.inst, root)
    
end

return RoyalPigGuardBrain