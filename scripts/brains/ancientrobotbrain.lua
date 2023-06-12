require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
--require "behaviours/runaway"
--require "behaviours/doaction"


local WANDER_DIST = 20
local START_FACE_DIST = 4

local KEEP_FACE_DIST = 6

local MAX_CHASE_TIME = 15

local MAX_BEAM_ATTACK_RANGE = 9
local MAX_JUMP_ATTACK_RANGE = 9


local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") then
    -- if target and not (target:HasTag("notarget") or target:HasTag("playerghost")) then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end


local function shouldbeamattack(inst)

    if inst.components.combat.target and not inst.components.timer:TimerExists("laserbeam_cd") and inst:HasTag("beam_attack") then
        local target = inst.components.combat.target
        local distsq = inst:GetDistanceSqToInst(target)    
        if distsq < MAX_BEAM_ATTACK_RANGE * MAX_BEAM_ATTACK_RANGE then
            return true
        end
    end
    return false
end

local function dobeamattack(inst)
    if inst.components.combat.target then
        local target = inst.components.combat.target
        inst:PushEvent("dobeamattack",{target=inst.components.combat.target})
    end
end

local function deactivate(inst)
    if not inst:HasTag("dormant") then
        inst.components.combat.target = nil
        inst:PushEvent("deactivate") 
    end
end

local MERGE_SCAN = 10
local MERGE_HULK = 15

local function shouldmerge(inst)    

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, MERGE_HULK, {'ancient_robot'})
    local mergetarget = nil
    local dist = 9999
    local hulk = nil
    for i, ent in ipairs(ents)do
        -- a valid merge target is when there is only one active bot. And a hulk should have priority
        if ent ~= inst then
            if ent:HasTag("ancient_robots_assembly") or (ent:HasTag("dormant") and not hulk) then
                if ent:HasTag("ancient_robots_assembly") then
                    if not hulk then
                        mergetarget = nil
                        dist = 9999
                    end
                    hulk = true
                end       
                local testdist = inst:GetDistanceSqToInst(ent)
                if ent:HasTag("ancient_robots_assembly") or testdist < MERGE_SCAN*MERGE_SCAN then
                    if testdist < dist then
                        mergetarget = ent
                        dist = testdist
                    end
                end
            end
            if not ent:HasTag("ancient_robots_assembly") and not ent:HasTag("dormant") then
                -- abort the merge
                inst.mergetarget = nil
                return false            
            end            
        end
    end     

    inst.mergetarget = mergetarget    
    if inst.mergetarget then
        return true
    end  
end

local function domerge(inst)
    local range = inst.collisionradius + inst.mergetarget.collisionradius + 0.1
    return BufferedAction(inst, inst.mergetarget, ACTIONS.SPECIAL_ACTION, nil,nil, nil, range)    
end

local AncientRobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function shouldjumpattack(inst)
    if not inst:HasTag("jump_attack") then
        return false
    end
    if  inst.sg:HasStateTag("leapattack") then
        return true
    end

    if inst.components.combat.target then
        local target = inst.components.combat.target
        if target then
            if target:IsValid() then
                local combatrange = inst.components.combat:CalcAttackRangeSq(target)
                local distsq = inst:GetDistanceSqToInst(target)
                if distsq < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE then
                    return true
                end
            else
                print("JUMP TARGET WASN'T THERE ANYMORE?",target.prefab)
                inst.components.combat.target = nil
            end
        end
    end
    return false
end

local function dojumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        inst:PushEvent("doleapattack", {target=target})

        inst:FacePoint(target.Transform:GetWorldPosition())
    end
end

function AncientRobotBrain:OnStart()
    local root = PriorityNode(
    {
        IfNode( function() return self.inst.wantstodeactivate or self.inst:HasTag("dormant") end, "deactivate test",  
            DoAction(self.inst, function() return deactivate(self.inst) end, "deactivate", true)
            ), 
        WhileNode(function() return not self.inst:HasTag("dormant") end, "activate",
            PriorityNode(
            {      
                WhileNode( function() return shouldmerge(self.inst) end, "merge",  
                    DoAction(self.inst, function() return domerge(self.inst) end, "merge", true)
                    ),                        
                WhileNode( function() return shouldbeamattack(self.inst) end, "beamattack",  
                    DoAction(self.inst, function() return dobeamattack(self.inst) end, "beam", true)
                    ),  
                WhileNode( function() return shouldjumpattack(self.inst) end, "jumpattack",  
                    DoAction(self.inst, function() return dojumpAttack(self.inst) end, "jump", true)
                    ),                            
                ChaseAndAttack(self.inst, MAX_CHASE_TIME),
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                Wander(self.inst)
            }, .25)
        )

    }, .25)
    
    self.bt = BT(self.inst, root)
    
end

return AncientRobotBrain