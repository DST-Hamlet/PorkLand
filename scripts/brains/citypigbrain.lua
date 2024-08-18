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
-- local MAX_CHASE_TIME = 10
-- local MAX_CHASE_DIST = 30

local SEE_LIGHT_DIST = 20
local TRADE_DIST = 20
local SEE_TREE_DIST = 15
-- local SEE_TARGET_DIST = 20
local SEE_FOOD_DIST = 10
-- local SEE_MONEY_DIST = 6

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

-- local STOP_CHASE_CHAT = 35

local FAR_ENOUGH = 40

--[[
local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end
]]

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

local function ShouldRunAway(inst, target)
    return not inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GetTraderFn(inst)
    return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end, {"player"})
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function FindFoodAction(inst)
    local target = nil

    if inst.sg:HasStateTag("busy") or inst:HasTag("shopkeep") then
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
        target = FindEntity(inst, SEE_FOOD_DIST,
            function(item)
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
        return BufferedAction(inst, target, ACTIONS.TAKEITEM)
    end
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
    return inst.components.homeseeker and inst.components.homeseeker.home and
           not inst.components.homeseeker.home:HasTag("fire") and not inst.components.homeseeker.home:HasTag("burnt") and
           inst.components.homeseeker.home:IsValid()
end


local function GoHomeAction(inst)
    if not inst.components.follower.leader and HasValidHome(inst) and not inst.components.combat.target then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
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

local CityPigBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function FixStructure(inst)
    if inst.components.fixer then
        return BufferedAction(inst, inst.components.fixer.target, ACTIONS.FIX)
    end
end

local function PoopTip(inst)
    inst.tipping = true
    return BufferedAction(inst, inst.poop_tip, ACTIONS.POOP_TIP)
end

local function PayTax(inst)
    local player = inst:GetNearestPlayer()
    if player then
        inst.taxing = true
        return BufferedAction(inst, player, ACTIONS.PAY_TAX)
    end
end

local function DailyGift(inst)
    local player = inst:GetNearestPlayer()
    if player then
        inst.daily_gifting = true
        return BufferedAction(inst, player, ACTIONS.DAILY_GIFT)
    end
end

local function ShopkeeperSitAtDesk(inst)
    if inst.components.homeseeker then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.SIT_AT_DESK)
    end
end

local function should_panic(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, {"hostile"}, {"city_pig", "INLIMBO", "shadowcreature", "bramble"})
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

local function shouldpanicwithspeech(inst)
    if should_panic(inst) then
        if math.random() < 0.01 then
            inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_FLEE"))
        end
        return true
    end
end

local function needlight(inst)
    if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "torch" then
        return false
    end
    return true
end

local function SafeLightDist(inst, target)
    return (target:HasTag("player") or target:HasTag("playerlight")
            or (target.inventoryitem and target.inventoryitem:GetGrandOwner() and target.inventoryitem:GetGrandOwner():HasTag("player")))
        and 4
        or target.Light:GetCalculatedRadius() / 3
end

local function ShouldGoHome(inst)
    local home_pos = inst.components.knownlocations:GetLocation("home")
    return home_pos and inst:GetDistanceSqToPoint(home_pos) > GO_HOME_DIST*GO_HOME_DIST
end

local function InCityLimits(inst)
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

local function ReplaceStockCondition(inst)
    if not inst:HasTag("shopkeep") then
        return false
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, FAR_ENOUGH / 2, {"shop_pedestal"}, {"justsellonce"})
    for _, ent in ipairs(ents) do
        if ent.components.shopped and ent.components.shopped:GetCost() and not ent.components.shopped:GetItemToSell() then
            inst.changestock = ent
            return true
        end
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

local function ReplenishStockAction(inst)
    if inst.changestock and inst.changestock:IsValid() then
        inst.sg:GoToState("idle")
        return BufferedAction(inst, inst.changestock, ACTIONS.STOCK)
    end
end

function getfacespeech()
    return function(inst)
        local econprefab = inst.econprefab or inst.prefab
        local desc = TheWorld.components.economy:GetTradeItemDesc(econprefab)
        local facing_player = GetFaceTargetFn(inst)
        local is_player_pig_loyalty = facing_player and facing_player:HasTag("pigroyalty")
        if desc then
            local speech = TheWorld.state.isnearaporkalypse
                and inst:GetSpeechType("CITY_PIG_TALK_APORKALYPSE_SOON")
                or is_player_pig_loyalty
                    and inst:GetSpeechType("CITY_PIG_TALK_LOOKATROYALTY_TRADER")
                    or inst:GetSpeechType("CITY_PIG_TALK_LOOKATWILSON_TRADER")
            inst:SayLine(speech, {line = desc})
        else
            if TheWorld.state.isnearaporkalypse then
                inst:SayLine("CITY_PIG_TALK_APORKALYPSE_SOON")
            end
            return is_player_pig_loyalty
                and inst:SayLine("CITY_PIG_TALK_LOOKATWILSON.ROYALTY")
                or inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_LOOKATWILSON"))
        end
    end
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

local function GoToIdleStateWrap(inst, fn)
    return function(...)
        local ret = fn(...)
        if ret and inst:HasTag("atdesk") then
            inst.sg:GoToState("idle")
        end

        return ret
    end
end

local function ChatterSay(str)
    return function(inst)
        inst:SayLine(inst:GetSpeechType(str))
    end
end

function CityPigBrain:OnStart()
    --print(self.inst, "CityPigBrain:OnStart")
    local day = WhileNode( function() return TheWorld.state.isday end, "IsDay",
        PriorityNode{
            -- start of day, shopkeeper needs to go back this their desk
            WhileNode(function() return self.inst:HasTag("shopkeep") and not self.inst:HasTag("atdesk") and not self.inst.changestock end, "shopkeeper opening",
               DoAction(self.inst, ShopkeeperSitAtDesk, "SitAtDesk", true )  ),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIND_MEAT"),
                DoAction(self.inst, FindFoodAction )),

            IfNode(function() return StartChoppingCondition(self.inst) end, "chop",
                WhileNode(function() return KeepChoppingAction(self.inst) end, "keep chopping",
                    LoopNode{
                        ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_HELP_CHOP_WOOD"),
                            DoAction(self.inst, FindTreeToChopAction ))})),

            Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),

            IfNode(function() return not self.inst.alerted and not self.inst.daily_gifting end, "greet",
                ChattyNode(self.inst, getfacespeech(),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn))),

            Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
        },.5)

    local night = WhileNode( function() return not TheWorld.state.isday end, "IsNight",
        PriorityNode{
            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_RUN_FROM_SPIDER"),
                RunAway(self.inst, "spider", 4, 8)),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIND_MEAT"),
                DoAction(self.inst, FindFoodAction )),

            -- after hours shop pig wants you to leave
            IfNode(function() return (self.inst:HasTag("shopkeep") or self.inst:HasTag("pigqueen")) and self.inst:GetIsInInterior() and TheWorld.state.isnight end, "shopkeeper closing",
                Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)),

            IfNode(function() return not self.inst:HasTag("guard") and not self.inst:HasTag("shopkeep") and not TheWorld.state.isfiesta end, "gohome",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_GO_HOME"),
                    DoAction(self.inst, GoHomeAction, "go home"))),

            WhileNode(function() return needlight(self.inst) end, "NeedLight",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIND_LIGHT"),
                    FindLight(self.inst, SEE_LIGHT_DIST, SafeLightDist))),

            IfNode(function() return not self.inst:HasTag("guard") and not TheWorld.state.isfiesta end, "panic",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_PANIC"),
                Panic(self.inst))),
        },1)

    local root =
        PriorityNode(
        {
            -- TODO: Add in custom panic speech
            WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FLEE"),
                    Panic(self.inst))),

            WhileNode(GoToIdleStateWrap(self.inst, function() return self.inst.components.health.takingfiredamage end), "OnFire",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_PANICFIRE"),
                    Panic(self.inst))),

            -- FOLLOWER CODE
            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FOLLOWWILSON"),
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),
            IfNode(function() return GetLeader(self.inst) end, "has leader",
                ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FOLLOWWILSON"),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn ))),
            -- END FOLLOWER CODE

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FLEE"),
                WhileNode(GoToIdleStateWrap(self.inst, function() return shouldpanicwithspeech(self.inst) end), "Threat Panic",
                    Panic(self.inst) )--[[, "alarmed"]]),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FLEE"),
                WhileNode(GoToIdleStateWrap(self.inst, function() return (self.inst.components.combat.target and not self.inst:HasTag("guard")) end), "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) )--[[, "alarmed"]]),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FLEE"),
                RunAway(self.inst, GoToIdleStateWrap(self.inst, function(guy) return guy:HasTag("pig") and guy.components.combat and guy.components.combat.target == self.inst end), RUN_AWAY_DIST, STOP_RUN_AWAY_DIST )--[[, "alarmed"]]),

            WhileNode(function() return ReplaceStockCondition(self.inst) end, "replenish",
                DoAction(self.inst, ReplenishStockAction, "restock", true)),

            -- For the shop pig when they're at their desk.
            WhileNode(function() return self.inst:HasTag("atdesk") end, "AtDesk",
                ActionNode(function() end) ),

            IfNode( function() return self.inst.poop_tip and not self.inst.tipping and not self.inst:HasTag("pigqueen") end, "poop_tip",
                DoAction(self.inst, PoopTip, "poop_tip", true)),

            IfNode( function() return self.inst:HasTag("paytax") and not self.inst.taxing end, "pay_tax",
                DoAction(self.inst, PayTax, "pay_tax", true)),


            IfNode(
                function()
                    if self.inst:HasTag("shopkeep") or self.inst:HasTag("pigqueen") then
                        return false
                    end

                    local target = GetFaceTargetFn(self.inst)

                    if target and (target:HasTag("pigroyalty") or TheWorld.state.isfiesta )and
                       (not self.inst.daily_gift or (TheWorld.state.cycles - self.inst.daily_gift > (TUNING.TOTAL_DAY_TIME * 1.5))) then
                            self.inst.daily_gift = TheWorld.state.cycles
                            return math.random() < 0.3
                    end
                    return false

                end, "daily_gift",
                DoAction(self.inst, DailyGift, "daily_gift", true)
            ),

            -- for the mechanic pigs when they fix stuff
            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_FIX"),
                WhileNode( function() return self.inst.components.fixer and self.inst.components.fixer.target end, "RepairStructure",
                     DoAction(self.inst, FixStructure))),

            ChattyNode(self.inst, ChatterSay("CITY_PIG_TALK_ATTEMPT_TRADE"),
                FaceEntity(self.inst, GetTraderFn, KeepTraderFn)),

            day,

            night
        }, .5)

    self.bt = BT(self.inst, root)
end

return CityPigBrain
