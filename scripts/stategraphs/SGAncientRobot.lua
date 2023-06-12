require("stategraphs/commonstates")

local actionhandlers = 
{
    --ActionHandler(ACTIONS.PICKUP, "doshortaction"),
    --ActionHandler(ACTIONS.EAT, "eat"),
    --ActionHandler(ACTIONS.CHOP, "chop"),
    --ActionHandler(ACTIONS.PICKUP, "pickup"),
    ActionHandler(ACTIONS.SPECIAL_ACTION, nil),
}

local SHAKE_DIST = 40
print("i work")
local function RemoveMoss(inst)
    inst.RemoveMoss(inst)
--[[
    if inst:HasTag("mossy") then           
        inst:RemoveTag("mossy")
        local x, y, z = inst.Transform:GetWorldPosition()
        for i=1,math.random(12,15) do
            inst:DoTaskInTime(math.random()*0.5,function()                
                local fx = SpawnPrefab("robot_leaf_fx")
                fx.Transform:SetPosition(x + (math.random()*4) -2 ,y,z + (math.random()*4) -2)
            end)
        end
    end    
    ]]
end

local function setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do 
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end
local function DoDamage(inst, rad)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
  
    setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do  --  { "_combat", "pickable", "campfire", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
        if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) and not v:HasTag("laser_immune") then            
            local vradius = 0
            if v.Physics then
                vradius = v.Physics:GetRadius()
            end

            local range = rad + vradius
            if v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
                local isworkable = false
                if v.components.workable ~= nil then
                    local work_action = v.components.workable:GetWorkAction()
                    --V2C: nil action for campfires
                    isworkable =
                        (   work_action == nil and v:HasTag("campfire")    ) or
                        
                            (   work_action == ACTIONS.CHOP or
                                work_action == ACTIONS.HAMMER or
                                work_action == ACTIONS.MINE or   
                                work_action == ACTIONS.DIG
                            )
                end
                if isworkable then
                    targets[v] = true
                    v:DoTaskInTime(0.6, function() 
                        if v.components.workable then
                            v.components.workable:Destroy(inst) 
                            local vx,vy,vz = v.Transform:GetWorldPosition()
                            v:DoTaskInTime(0.3, function() setfires(vx,vy,vz,1) end)
                        end
                     end)
                    if v:IsValid() and v:HasTag("stump") then
                       -- v:Remove()
                    end
                elseif v.components.pickable ~= nil
                    and v.components.pickable:CanBePicked()
                    and not v:HasTag("intense") then
                    targets[v] = true
                    local num = v.components.pickable.numtoharvest or 1
                    local product = v.components.pickable.product
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                    if product ~= nil and num > 0 then
                        for i = 1, num do
                            local loot = SpawnPrefab(product)
                            loot.Transform:SetPosition(x1, 0, z1)
                            targets[loot] = true
                        end
                    end

                elseif v.components.health then                    
                    inst.components.combat:DoAttack(v)                
                    if v:IsValid() then
                        if not v.components.health or not v.components.health:IsDead() then
                            if v.components.freezable ~= nil then
                                if v.components.freezable:IsFrozen() then
                                    v.components.freezable:Unfreeze()
                                elseif v.components.freezable.coldness > 0 then
                                    v.components.freezable:AddColdness(-2)
                                end
                            end
                            if v.components.temperature ~= nil then
                                local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                                local curtemp = v.components.temperature:GetCurrent()
                                if maxtemp > curtemp then
                                    v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                                end
                            end
                        end
                    end                   
                end
                if v:IsValid() and v.AnimState then
                    SpawnPrefab("laserhit"):SetTarget(v)
                end
            end
        end
    end
end

local function UpdateHit(inst)
    if inst:IsValid() then
        local oldflash = inst.flash
        inst.flash = math.max(0, inst.flash - .075)
        if inst.flash > 0 then
            local c = math.min(1, inst.flash)
            if inst.components.colouradder ~= nil then
                inst.components.colouradder:PushColour(inst, c, 0, 0, 0)
            else
                inst.AnimState:SetAddColour(c, 0, 0, 1)
            end
            if inst.flash < .3 and oldflash >= .3 then
                if inst.components.bloomer ~= nil then
                    inst.components.bloomer:PopBloom(inst)
                else
                    inst.AnimState:ClearBloomEffectHandle()
                end
            end
        else
            inst.flashtask:Cancel()
            inst.flashtask = nil
        end
    end
end

local function powerglow(inst)
    
    if inst.components.bloomer ~= nil then
        inst.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
    else
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    inst.flash = 1.7 -- .8 + math.random() * .4
    inst.flashtask = inst:DoPeriodicTask(0, UpdateHit, nil, inst)
end

local function SpawnLaser(inst)
    assert(inst.sg.statemem.targetpos)
    local numsteps = 10   
    local x, y, z = inst.Transform:GetWorldPosition()

    --if inst.components.combat.target then
    --    x,y,z = inst.components.combat.target.Transform:GetWorldPosition()
    --end

    local xt = inst.sg.statemem.targetpos.x
    local yt = inst.sg.statemem.targetpos.y
    local zt = inst.sg.statemem.targetpos.z

    local dist =  math.sqrt(inst:GetDistanceSqToPoint(  Vector3(xt, yt, zt)  )) -3--  math.sqrt( ) ) - 2

    local angle = (inst:GetAngleToPoint(xt, yt, zt) +90)* DEGREES

    local step = .75   
    local ground = TheWorld.Map
    local targets, skiptoss = {}, {}
    local i = -1
    local noground = false
    local fx, delay, x1, z1
    while i < numsteps do
        i = i + 1
        dist = dist + step
        delay = math.max(0, i - 1)
        x1 = x + dist * math.sin(angle)
        z1 = z + dist * math.cos(angle)
        local tile = ground:GetTileAtPoint(x1, 0, z1)
        
        if tile == 255 or tile < 2 then
            if i <= 0 then
                return
            end
            noground = true
        end
        fx = SpawnPrefab(i > 0 and "laser" or "laserempty")
        fx.caster = inst
        fx.Transform:SetPosition(x1, 0, z1)
        fx:Trigger(delay * FRAMES, targets, skiptoss)
        if i == 0 then
        --    ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .6, fx, 30)
        end
        if noground then
            break
        end
    end
--[[
    if i < numsteps then
        dist = (i + .5) * step + offset
        x1 = x + dist * math.sin(angle)
        z1 = z + dist * math.cos(angle)
    end
    ]]

    local function delay_spawn(delay_offset)
        fx = SpawnPrefab("laser")
        fx.Transform:SetPosition(x1, 0, z1)
        fx:Trigger((delay + delay_offset) * FRAMES, targets, skiptoss)
    end

    delay_spawn(1)
    delay_spawn(2)
end

local function SetLightValue(inst, val)
    if inst.Light ~= nil then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
    end
end

local function SetLightValueAndOverride(inst, val, override)
    if inst.Light ~= nil then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
        inst.AnimState:SetLightOverride(override)
    end
end

local function SetLightColour(inst, val)
    if inst.Light ~= nil then
        inst.Light:SetColour(val, 0, 0)
    end
end

local events=
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    --EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() then 
       -- inst.sg:GoToState("attack", data.target) 
    --    end end),
    EventHandler("dobeamattack", function(inst, data) 
                    if not inst.sg:HasStateTag("activating") and not inst.sg:HasStateTag("busy") then
                        inst.sg:GoToState("laserbeam", data.target) 
                    end
        end),  
    EventHandler("doleapattack", function(inst,data)
                    if not inst.sg:HasStateTag("activating") and not inst.sg:HasStateTag("busy") then 
                        inst.sg:GoToState("leap_attack_pre", data.target)
                    end
         end),          
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("attacked", function(inst) 
            RemoveMoss(inst)
            inst.hits = inst.hits+ 1
           -- if inst.components.health:GetPercent() > 0 then                 

            if inst.hits > 2 then                
                if math.random()*inst.hits >= 2 then

                    local x, y, z= inst.Transform:GetWorldPosition()
                    inst.components.lootdropper:SpawnLootPrefab("iron", Vector3(x,y,z))
                    inst.hits = 0

                    if inst:HasTag("dormant") then
                        if  math.random() < 0.6 then
							-- print("DS - Robot - Waking up in Stategraph")
                            inst.wantstodeactivate = nil
                            inst:RemoveTag("dormant")                                
                            inst:PushEvent("shock")
                            inst.lifetime = 20 --120
                            if not inst.updatetask then
                                inst.updatetask = inst:DoPeriodicTask(inst.UPDATETIME, inst.PeriodicUpdate)
								-- I think you forgot to update this, Asura. It broke the sleep of the robots
                            end                                                                                                            
                        end
                    elseif not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("activating") then                        
                        inst.sg:GoToState("hit")
                    end
                end
            end

            if inst:HasTag("dormant") and not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("hit_dormant")       
            end
               
            --end
        end),
    EventHandler("shock", function(inst)
                inst.wantstodeactivate = nil
                inst:RemoveTag("dormant") 
                inst.sg:GoToState("shock") 
        end),
    EventHandler("activate", function(inst) 
            --    inst.components.health:StopRegen()
                inst.wantstodeactivate = nil
                inst:RemoveTag("dormant")                        
                inst.sg:GoToState("activate") 
        end),
    EventHandler("deactivate", function(inst) print("DEACTIVATE EVENT")
            if not inst:HasTag("dormant") then
             --   inst.components.health:StartRegen(1000, 5)
                inst.wantstodeactivate = nil
                inst:AddTag("dormant")  
                inst.sg:GoToState("deactivate") 
            end
        end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
            inst.sg:SetTimeout(2 + 2*math.random())
        end,
--------------------------------------------- arm/claw
--------------------------------------------- ribs
--------------------------------------------- leg
--------------------------------------------- head
        
        ontimeout=function(inst)
                inst.sg:GoToState("taunt")
        end,
    },

    State{
        name = "idle_dormant",
        tags = {"idle","dormant"},
        
        onenter = function(inst, pushanim)
            --inst.wantstodeactivate = nil
            inst.components.locomotor:StopMoving()
            inst.SoundEmitter:SetParameter("gears", "intensity", 1)
            inst.SoundEmitter:KillSound("gears")

            if inst:HasTag("mossy") then
                inst.AnimState:PlayAnimation("mossy_full")
            else
                inst.AnimState:PlayAnimation("full")
            end
        end,
        timeline=
        {
--------------------------------------------- leg
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(27*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo_small",nil,0.5)
                end
            end),
            TimeEvent(31*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo_small",nil,0.5)
                end
            end),
            TimeEvent(45*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo",nil,0.6)
                end
            end),
        },   
--------------------------------------------- arm/claw
--------------------------------------------- ribs
--------------------------------------------- head
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },           

    },  

    State{
        name = "fall",
        tags = {"busy"},
        
        onenter = function(inst, pushanim)
            print("HERE")
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0,-35,0) -- -20+math.random()*10
            inst.AnimState:PlayAnimation("idle_fall", true)
        end,

        onupdate = function(inst)
            local pt = Point(inst.Transform:GetWorldPosition())

            if pt.y < 2 then
                inst.Physics:SetMotorVel(0,0,0)
            end
            
            if pt.y <= 0.1 then
                print("LAND")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small",nil,.25)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step")
                pt.y = 0                
                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(pt.x,pt.y,pt.z)              
                inst.sg:GoToState("separate")
                local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
                if player then
                    ShakeAllCameras(CAMERASHAKE.FULL, 0.7, .02, 2, inst, SHAKE_DIST)
                end           

            end
        end,

        onexit = function(inst)
            local pt = inst:GetPosition()
            pt.y = 0
            inst.Transform:SetPosition(pt:Get())
        end,        
    },

    State{
        name = "separate",
        tags = {"busy","dormant"},
        
        onenter = function(inst, pushanim)
            print("SEPARATE")
            --inst.wantstodeactivate = nil
            inst.components.locomotor:StopMoving()          
            inst.AnimState:PlayAnimation("separate")          
        end,   
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },           

    },    

    State{
        name = "hit_dormant",
        tags = {"busy","dormant"},
        
        onenter = function(inst, pushanim)
            --inst.wantstodeactivate = nil
            inst.components.locomotor:StopMoving()          
            inst.AnimState:PlayAnimation("dormant_hit")          
        end,   
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },           

    },      

    State{
        name = "shock",
        tags = {"busy","activating"},
        
        onenter = function(inst, pushanim)
            --inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )
            RemoveMoss(inst) 
           -- inst:RemoveTag("dormant")      
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shock")
        end,
        
        timeline=
        {
--------------------------------------------- leg
            TimeEvent(6*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
--------------------------------------------- ribs
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
            TimeEvent(13*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
--------------------------------------------- arm
            TimeEvent(10*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
					print("Should be playing sound now, this is the arm")
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
				else
					print("This isn't the arm after all, don't play the sound")
                end
            end),
            TimeEvent(10*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
    --------------------------------------------- head
            TimeEvent(2*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
            TimeEvent(5*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(7*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,0.5)
                end
            end),
            TimeEvent(10*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("activate") 
            end),
        }, 
    },   

    State{
        name = "activate",
        tags = {"busy","activating"},
        
        onenter = function(inst, pushanim)
            RemoveMoss(inst)
            
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/gears_LP","gears")
            inst.SoundEmitter:SetParameter("gears", "intensity", .5)
            inst:AddTag("hostile")
        end,
        
        timeline=
        {
--------------------------------------------- arm/claw
            TimeEvent(3*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active")
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/start")
                end
            end),
            TimeEvent(4*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active")
                end
            end),
            TimeEvent(6*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") 
                end
            end),
            TimeEvent(8*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") 
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") 
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") 
                end
            end),

            TimeEvent(16*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") 
                end
            end),
            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(37*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") 
                end
            end),
            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(41*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(50*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(51*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") 
                end
            end),
            TimeEvent(53*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(62*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") 
                end
            end),
            TimeEvent(70*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") 
                end
            end),
--------------------------------------------- head
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/start")
                end
            end),

            TimeEvent(1*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(3*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(5*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(6*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(14*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(16*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
                end
            end),
            TimeEvent(17*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(27*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(37*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(40*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(54*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(57*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            
            --------------------------------------------- leg
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active")
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/start")
                end
            end),
            
            TimeEvent(4*FRAMES, function(inst)
				print("TAG TEST", inst:HasTag("robot_leg"))
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active")
                end
            end),
            TimeEvent(5*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active")
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active")
                end
            end),
            TimeEvent(13*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active")
                end
            end),
             TimeEvent(14*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(17*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(27*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(44*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(58*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step",nil,.06)
                end
            end),
            --------------------------------------------- ribs
            TimeEvent(2*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/start")
                end
            end),
            
            TimeEvent(4*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(6*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(8*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(10*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(13*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(14*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(16*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                end
            end),
            TimeEvent(18*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(21*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(33*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(36*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
            TimeEvent(39*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
                end
            end),
 
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst:RestartBrain()
                inst.sg:GoToState("taunt") 
            end),
        },        
    }, 

    State{
        name = "deactivate",
        tags = {"busy","deactivating"},
        
        onenter = function(inst, pushanim)
            --inst.AnimState:SetBloomEffectHandle( "" )
           -- inst.wantstodeactivate = nil
            --inst:StopBrain()
            inst.components.locomotor:StopMoving()
            --inst:AddTag("dormant")              
            inst.AnimState:PlayAnimation("deactivate")
            if inst:HasTag("robot_arm") then 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/stop")
                end
            if inst:HasTag("robot_head") then 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/stop")
                end
            if inst:HasTag("robot_leg") then 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/stop")
                end
            if inst:HasTag("robot_ribs") then 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/stop")
                end

            inst:RemoveTag("hostile")
        end,

        timeline=
        {
--------------------------------------------- arm/claw
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green")
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green")
                end
            end),
            TimeEvent(14*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green")
                end
            end),
            TimeEvent(21*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green")
                end
            end),
            TimeEvent(38*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green")
                end
            end),
            TimeEvent(36*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),
--------------------------------------------- head
            TimeEvent(5*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green")
                end
            end),
            TimeEvent(13*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green")
                end
            end),
            TimeEvent(19*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green")
                end
            end),
            TimeEvent(23*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green")
                end
            end),
            TimeEvent(38*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green")
                end
            end),
--------------------------------------------- leg
            TimeEvent(3*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green")
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green")
                end
            end),
            TimeEvent(16*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green")
                end
            end),
            TimeEvent(23*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green")
                end
            end),
            TimeEvent(31*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green")
                end
            end),
            TimeEvent(43*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step")
                end
            end),
    --------------------------------------------- ribs
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green")
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green")
                end
            end),
            TimeEvent(14*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green")
                end
            end),
            TimeEvent(21*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green")
                end
            end),

        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },        
    },            
    
    State{
        name = "taunt",
        tags = {"busy","canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },        


        timeline =
        {
--------------------------------------------- arm/claw
            TimeEvent(3*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),
            TimeEvent(7*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),
            TimeEvent(15*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/taunt")
                end
            end),
            TimeEvent(29*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),
            TimeEvent(33*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),

--------------------------------------------- ribs
            TimeEvent(4*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
                end
            end),
            TimeEvent(17*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
                end
            end),
            TimeEvent(21*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/taunt")
                end
            end),
            TimeEvent(45*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
                end
            end),

--------------------------------------------- leg
            TimeEvent(5*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(15*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(42*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            --------------------------------------------- head
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
            TimeEvent(2*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/taunt")
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", .05)

                end
            end),
            TimeEvent(17*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
            TimeEvent(19*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/taunt")
                end
            end),
            TimeEvent(24*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", .08)

                end
            end),
            TimeEvent(32*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
--------------------------------------------------

            TimeEvent(23 * FRAMES, function(inst)
                if inst:HasTag("lightning_taunt") then
                    -- GetClock():DoLightningLighting(.5)
					-- TheWorld:PushEvent("ms_sendlightningstrike", inst.Transform:GetWorldPosition())
					local pos = inst:GetPosition()
					TheWorld:PushEvent("ms_sendlightningstrike", pos)
                        -- GetPlayer().SoundEmitter:PlaySound("dontstarve/rain/thunder_close")
                        -- GetPlayer().components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, .5, 40)
                        inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close")
                        -- GetPlayer().components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, .5, 40)
                end
            end),
        },


    },

    State{
        name = "laserbeam",
        tags = { "busy","attack" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
            if not inst:HasTag("noeightfaced") then
                inst.Transform:SetEightFaced()
            end
     --       EnableEightFaced(inst)
            if target ~= nil and target:IsValid() then
                if inst.components.combat:TargetIs(target) then
                    inst.components.combat:StartAttack()
                end
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
            end

            inst.components.timer:StopTimer("laserbeam_cd")
            inst.components.timer:StartTimer("laserbeam_cd", TUNING.DEERCLOPS_ATTACK_PERIOD * (math.random(3) - .5))
        end,

        onupdate = function(inst)
            if inst.sg.statemem.target ~= nil then
                if inst.sg.statemem.target:IsValid() then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
                    local dx, dz = x1 - x, z1 - z
                    if dx * dx + dz * dz < 256 and math.abs(anglediff(inst.Transform:GetRotation(), math.atan2(-dz, dx) / DEGREES)) < 45 then
                        inst:ForceFacePoint(x1, y1, z1)
                        return
                    end
                end
                inst.sg.statemem.target = nil
            end
            if inst.sg.statemem.lightval ~= nil then
                inst.sg.statemem.lightval = inst.sg.statemem.lightval * .99
                SetLightValueAndOverride(inst, inst.sg.statemem.lightval, (inst.sg.statemem.lightval - 1) * 3)
            end
        end,

        timeline =
        {
            --------------------------------------------- arm/claw
            TimeEvent(3*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),
            -- TimeEvent(4*FRAMES, function(inst) 
            --     if inst:HasTag("robot_arm") then
            --        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
            --     end
            -- end),

            TimeEvent(7*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser_pre")
                end
            end),

            TimeEvent(19*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),

            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .12)
                end
            end),
            TimeEvent(32*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .24)
                end
            end),
            TimeEvent(34*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .48)
                end
            end),
            TimeEvent(36*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .60)
                end
            end),
            TimeEvent(38*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .72)
                end
            end),
            TimeEvent(40*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .84)
                end
            end),
            TimeEvent(42*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .96)
                end
            end),
            TimeEvent(44*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", 1)
                end
            end),
            TimeEvent(47*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/step")
                end
            end),
            --------------------------------------------- ribs
            TimeEvent(4*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
                end
            end),
            TimeEvent(4*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
                end
            end),

            TimeEvent(2*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser_pre")
                end
            end),

            TimeEvent(19*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
                end
            end),

            TimeEvent(22*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .12)
                end
            end),
            TimeEvent(24*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .24)
                end
            end),
            TimeEvent(26*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .48)
                end
            end),
            TimeEvent(28*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .60)
                end
            end),
            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .72)
                end
            end),
            TimeEvent(32*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .84)
                end
            end),
            TimeEvent(34*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", .96)
                end
            end),
            TimeEvent(36*FRAMES, function(inst) 
                if inst:HasTag("robot_ribs") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                   inst.SoundEmitter:SetParameter("laserfilter", "intensity", 1)
                end
            end),

            TimeEvent(6 * FRAMES, function(inst)
               -- TheCamera:Shake("VERTICAL",  .2,  .02, .5)
                SetLightValue(inst, .97)
            end),

            TimeEvent(8 * FRAMES, function(inst) inst.Light:Enable(true) 
                                                 SetLightValueAndOverride(inst, 0.05, .2) end),
            TimeEvent(9 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.1, .15) end),
            TimeEvent(10 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.15, .05) end),
            TimeEvent(11 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.20, 0) end),
            TimeEvent(12 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.25, .35) end),
            TimeEvent(13 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.30, .3) end),
            TimeEvent(14 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.35, .05) end),
            TimeEvent(15 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.40, 0) end),
            TimeEvent(16 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.45, .3) end),
            TimeEvent(17 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.50, .15) end),
            TimeEvent(18 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.55, .05) end),
            TimeEvent(19 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.60, 0) end),
            TimeEvent(20 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.65, .35) end),
            TimeEvent(21 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.70, .3) end),
            TimeEvent(22 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.75, .05) end),
            TimeEvent(23 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.80, 0) end),
            TimeEvent(24 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.85, .3) end),
            TimeEvent(25 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.90, .15) end),
            TimeEvent(26 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.95, .05) end),
            TimeEvent(27 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1, 0) end),
            TimeEvent(28 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.01, .35) end),

            TimeEvent(29 * FRAMES, function(inst)
                SetLightValueAndOverride(inst, .9, 0)                
            end),
            TimeEvent(30 * FRAMES, function(inst)
                SpawnLaser(inst)
                inst.sg.statemem.target = nil
                SetLightValueAndOverride(inst, 1.08, .7)
            end),
            TimeEvent(31 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.12, 1) end),
            TimeEvent(32 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.1, .9) end),
            TimeEvent(33 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.06, .4) end),
            TimeEvent(34 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.1, .6) end),
            TimeEvent(35 * FRAMES, function(inst) inst.sg.statemem.lightval = 1.1 end),
            TimeEvent(36 * FRAMES, function(inst) 
                inst.sg.statemem.lightval = 1.035
                SetLightColour(inst, .9)
            end),

            TimeEvent(37 * FRAMES, function(inst)
                inst.sg.statemem.lightval = nil
                SetLightValueAndOverride(inst, .9, 0)
                SetLightColour(inst, .9)
            end),
            TimeEvent(38 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                SetLightValue(inst, 1)
                SetLightColour(inst, 1)
                inst.Light:Enable(false)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.keepfacing = true
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if inst:HasTag("IsSixFaced") then 
                inst.Transform:SetSixFaced()
            else
                inst.Transform:SetFourFaced()
            end
            SetLightValueAndOverride(inst, 1, 0)
            SetLightColour(inst, 1)
            if not inst.sg.statemem.keepfacing then
      --          DisableEightFaced(inst)
            end
        end,
    },

    State{
            
        name = "leap_attack_pre",
        tags = {"attack", "canrotate", "busy","leapattack"},
        
        onenter = function(inst, target)
            inst.components.locomotor:Stop()                    
            inst.AnimState:PlayAnimation("atk_pre")
            inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
            inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
        end,

        timeline=
        {
--------------------------------------------- leg
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
--------------------------------------------- head
            TimeEvent(7*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
            TimeEvent(9*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
            TimeEvent(11*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
        },
            
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack",{startpos =inst.sg.statemem.startpos, targetpos =inst.sg.statemem.targetpos}) end),
        },
    },

    State{

        name = "leap_attack",
        tags = {"attack", "canrotate", "busy", "leapattack"},
        
        onenter = function(inst, data)
            inst.sg.statemem.startpos = data.startpos
            inst.sg.statemem.targetpos = data.targetpos
            inst.components.locomotor:Stop()
            inst.Physics:SetActive(false)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_loop")            
        end,



        timeline=
        {
--------------------------------------------- leg
            TimeEvent(18*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
--------------------------------------------- arm/claw
--------------------------------------------- ribs
--------------------------------------------- leg
--------------------------------------------- head
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
             TimeEvent(3*FRAMES, function(inst) 
                 if inst:HasTag("robot_head") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/attack")
                 end
             end),
             TimeEvent(25*FRAMES, function(inst) powerglow(inst) end), 
        },

        onupdate = function(inst)
            -- local percent = inst.AnimState:GetPercent()
            -- local percent = inst.AnimState:GetPercent()
			local length = inst.AnimState:GetCurrentAnimationLength()
			local current = inst.AnimState:GetCurrentAnimationTime()
			local percent = current / length
			
            local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
            local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z           

            inst.Transform:SetPosition(inst.sg.statemem.startpos.x+(xdiff*percent),0,inst.sg.statemem.startpos.z+(zdiff*percent))
        end,

        onexit = function(inst)
            inst.Physics:SetActive(true)
            --inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.sg.statemem.startpos = nil
            inst.sg.statemem.targetpos = nil
        end,
        
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack_pst") end),
        },
    },


    State{

        name = "leap_attack_pst",
        tags = {"busy"},
        
        onenter = function(inst, target)            
            --inst.components.groundpounder:GroundPound()

            -- local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
            -- if player then
                -- -- player.components.playercontroller:ShakeCamera(inst, "VERTICAL", 0.5, 0.03, 2, SHAKE_DIST)
                -- player:ShakeCamera(inst, "VERTICAL", 0.5, 0.03, 2, SHAKE_DIST)
            -- end
			ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .005, 2, inst, SHAKE_DIST)

            local ring = SpawnPrefab("laser_ring")
            ring.Transform:SetPosition(inst.Transform:GetWorldPosition())

            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pst")
        end,

        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)DoDamage(inst, 1.5) end), 
            TimeEvent(10*FRAMES, function(inst)DoDamage(inst, 2.5) end), 
            TimeEvent(15*FRAMES, function(inst)DoDamage(inst, 3.3) end),
--------------------------------------------- leg
            TimeEvent(2*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")
                end
            end),
            TimeEvent(12*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(18*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
            TimeEvent(28*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step",nil,.06)
                end
            end),
            TimeEvent(30*FRAMES, function(inst) 
                if inst:HasTag("robot_leg") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo")
                end
            end),
--------------------------------------------- head
            TimeEvent(0*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")
                end
            end),
            TimeEvent(13*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo")
                end
            end),
            TimeEvent(17*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step")
                end
            end),
            TimeEvent(31*FRAMES, function(inst) 
                if inst:HasTag("robot_head") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", .08)

                end
            end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)    
			inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk", false)
        end,        
        
        timeline=
        {
--------------------------------------------- arm/claw
--------------------------------------------- ribs
--------------------------------------------- leg
--------------------------------------------- head

        --    TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },    
    
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)            
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
    },
}

CommonStates.AddWalkStates(
    states,
    {
        walktimeline = 
        {
            --------------------------------------------
            -- TimeEvent(6*FRAMES, function(inst)       
            --     if inst:HasTag("robot_ribs") then
            --        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step" "steps")
            --        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            --     end
            -- end),
            -- TimeEvent(16*FRAMES, function(inst)       
            --     if inst:HasTag("robot_ribs") then
            --        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step" "steps")
            --        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            --     end
            -- end),
            -- TimeEvent(21*FRAMES, function(inst)       
            --     if inst:HasTag("robot_ribs") then
            --        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step" "steps")
            --        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            --     end
            -- end),
            -- TimeEvent(25*FRAMES, function(inst)       
            --     if inst:HasTag("robot_ribs") then
            --        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step" "steps")
            --        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            --     end
            -- end),
            -- TimeEvent(38*FRAMES, function(inst)       
            --     if inst:HasTag("robot_ribs") then
            --        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step" "steps")
            --        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            --     end
            -- end),
            
            -- TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),
            -- TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),
            -- TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),
            -- TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),    
            --------------------------------------------
        }
    })

CommonStates.AddRunStates(
    states,
    {
        starttimeline = 
        {
            -- TimeEvent(0*FRAMES, function(inst)       
            --         if inst:HasTag("robot_leg") then
            --            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", "steps")
            --            inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            --         end
                    
            --     end),
--------------------------------------------- head
                TimeEvent(0*FRAMES, function(inst)                                          
                    if inst:HasTag("robot_head") then
                       inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),
--------------------------------------------- arm/claw
--------------------------------------------- ribs
                TimeEvent(1*FRAMES, function(inst)                                          
                    if inst:HasTag("robot_ribs") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    end
                end),

            TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
        },
        
        
runtimeline = 
        {
                TimeEvent(0*FRAMES, function(inst) 
                    inst.Physics:Stop() 
                    inst.components.locomotor:WalkForward()

                    if inst:HasTag("robot_arm") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/drag")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())                        
                    end
                end ),

                TimeEvent(1*FRAMES, function(inst)                                          
                    if inst:HasTag("robot_head") then
                        -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
                        -- inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),                

                TimeEvent(5*FRAMES, function(inst)    
                    if inst:HasTag("robot_leg") then
                       inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo",nil,0.8)
                    end
                end),

                TimeEvent(6*FRAMES, function(inst)   
                    if inst:HasTag("robot_arm") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    end                                                       
                    if inst:HasTag("robot_ribs") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),

                TimeEvent(14*FRAMES, function(inst)       
                    if inst:HasTag("robot_arm") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end                    
                    if inst:HasTag("robot_leg") then
                       inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", "steps") 
                       inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    end
     
                end),

                TimeEvent(16*FRAMES, function(inst)                                         
                    if inst:HasTag("robot_ribs") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step_wires","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),

                TimeEvent(17*FRAMES, function(inst)                                          
                    if inst:HasTag("robot_head") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    end
                end),

                TimeEvent(21*FRAMES, function(inst)        
                    if inst:HasTag("robot_ribs") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),

                TimeEvent(25*FRAMES, function(inst)                                          
                    if inst:HasTag("robot_arm") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    end
                    if inst:HasTag("robot_ribs") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
                    inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end                    
                end),

                TimeEvent(28*FRAMES, function(inst)                                          
                    if inst:HasTag("robot_arm") then
                       inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),

                TimeEvent(38*FRAMES, function(inst)       
                    if inst:HasTag("robot_ribs") then
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
                        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
                        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),


                
                TimeEvent(48*FRAMES, function(inst) 
                    inst.Physics:Stop() 
                end ),
        },

        endtimeline= 
        {
                TimeEvent(3*FRAMES, function(inst)       
                    if inst:HasTag("robot_ribs") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
                    inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
                    end
                end),
--------------------------------------------- arm/claw                
                TimeEvent(33*FRAMES, function(inst) 
                if inst:HasTag("robot_arm") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
                end
            end),

                TimeEvent(48*FRAMES, function(inst) 
                    inst.Physics:Stop() 
                end ),

        },

    },
    {startrun="walk_pre",run="walk_loop",stoprun="walk_pst"},
    true,
    {
        startenter = function(inst)
            if inst:HasTag("ribs") then
                print("CHECK 2")
                --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","robo_walk_LP")
            end
        end,
        --[[
        loopenter = function(inst)

        end,        
        endenter = function(inst)
            
        end,
        ]]
        startexit = function(inst)
            if not inst.cleantransition then
                inst.SoundEmitter:KillSound("robo_walk_LP")
            end            
        end,
        loopexit = function(inst)
            if not inst.cleantransition then
                inst.SoundEmitter:KillSound("robo_walk_LP")
            end 
        end,        
        endexit = function(inst)
           inst.SoundEmitter:KillSound("robo_walk_LP")
        end,
    })

CommonStates.AddSimpleState(states,"hit", "hit")
CommonStates.AddFrozenStates(states)
    
return StateGraph("ancientrobot", states, events, "idle", actionhandlers)


--------------------------------------------- arm/claw
--------------------------------------------- ribs
--------------------------------------------- leg
--------------------------------------------- head