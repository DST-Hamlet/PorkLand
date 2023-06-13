require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/chaseandattack"

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5

local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_STOP = 6

local SEE_BAIT_DIST = 20
local MAX_WANDER_DIST = 20
local SEE_STOLEN_ITEM_DIST = 10

local MAX_CHASE_TIME = 8


local PikoBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GoHomeAction(inst)
    if inst.components.homeseeker and
    inst.components.homeseeker:HasHome() then
        if inst.components.homeseeker.home:HasTag("stump") or
        inst.components.homeseeker.home:HasTag("burnt") or
        inst.components.homeseeker.home:HasTag("fire") then
            inst.components.homeseeker.home:RemoveComponent( "spawner" )
            inst:RemoveComponent("homeseeker")
            return
        end

        if not inst.sg:HasStateTag("trapped") then
            return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
        end
    end
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_BAIT_DIST,
        function(item)
            return inst.components.eater:CanEat(item) and
            item.components.bait and
            not item:HasTag("planted") and
            not (item.components.inventoryitem and
                item.components.inventoryitem:IsHeld())
        end)
    if target then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function() return not (target.components.inventoryitem and target.components.inventoryitem:IsHeld()) end
        return act
    end
end

local function PickupAction(inst)
    if inst.components.inventory:NumItems() < 1 then
        local target = FindEntity(inst, SEE_STOLEN_ITEM_DIST,
            function(item)
                local x,y,z = item.Transform:GetWorldPosition()
                local isValidPosition = x and y and z
                local isValidPickupItem =
                    isValidPosition and
                    item.components.inventoryitem and
                    not item.components.inventoryitem:IsHeld() and
                    item.components.inventoryitem.canbepickedup and
                    item.components.container == nil and
                    item:IsOnValidGround() and
                    not item:HasTag("trap") and
                    not item:HasTag("irreplaceable")
                return isValidPickupItem
            end)

        if target then
            return BufferedAction(inst, target, ACTIONS.PICKUP)
        end
    end
end


local function findhome(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 30, {"teatree"},{"stump","burnt"})
    local home = nil
    for i, ent in ipairs(ents)do
        if not ent.components.spawner or not ent.components.spawner.child then
            home = ent
            break
        end
    end

    if home then
        if not home.components.spawner then
            home:AddComponent( "spawner" )
            home.setupspawner(home)
            home.components.spawner:CancelSpawning()
            home.components.spawner:TakeOwnership(inst)
            inst.findhometask:Cancel()
            inst.findhometask = nil
        end
    end
end

local function CheckForHome(inst)
    if not inst.components.homeseeker then
        if not inst.findhometask then
            inst.findhometask = inst:DoPeriodicTask(10,function() findhome(inst) end)
        end
        return true
    end
end

function PikoBrain:OnStart()
    local clock = TheWorld

    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        WhileNode(function() return self.inst.components.inventory:NumItems() > 0 and self.inst.components.homeseeker end, "run off with prize",
            DoAction(self.inst, GoHomeAction, "go home", true)),
        DoAction(self.inst, PickupAction, "searching for prize", true),
        WhileNode(function() return self.inst.currentlyRabid end, "IsRabid",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME)),
        RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
        RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST, nil, true),
            EventNode(self.inst, "gohome",
                DoAction(self.inst, GoHomeAction, "go home", true )),
        WhileNode(function() return clock and not TheWorld.state.isday and (not TheWorld.state.isnight or TheWorld.state.moonphase ~= "new" ) end, "IsNight",
            DoAction(self.inst, GoHomeAction, "go home", true )),
    --    WhileNode(function() return seasonmgr and seasonmgr:GetSeason() == SEASONS.SPRING end, "IsSpring",
    --        DoAction(self.inst, GoHomeAction, "go home", true )),
        DoAction(self.inst, EatFoodAction),
        WhileNode(function() return CheckForHome(self.inst) end, "wander to find home",
            Wander(self.inst)),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
    }, 0.25)
    self.bt = BT(self.inst, root)
end

return PikoBrain
