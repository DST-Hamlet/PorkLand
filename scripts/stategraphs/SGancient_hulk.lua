require("stategraphs/commonstates")

local SHAKE_DIST = 40
local BEAMRAD = 7
local function onattackedfn(inst, data)
    if not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("hit")
    end
end

local function onattackfn(inst)
   inst.sg:GoToState("attack")
end

local function teleport(inst) 
    inst.teleporttime = nil
    local pt = Vector3(inst.Transform:GetWorldPosition())
    
    if inst.components.combat.target then
        pt = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
    end

    local theta = math.random() * 2 * PI

    local offset = nil
    while not offset do
        offset = FindWalkableOffset(pt, theta, 12 + math.random()*5, 12, true) --12
    end
    
    pt.x = pt.x + offset.x
    pt.z = pt.z + offset.z
    inst.Physics:SetActive(true)
    inst.Transform:SetPosition(pt.x,0,pt.z)
    inst.sg:GoToState("telportin")
end

local function launchprojectile(inst, dir)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    local theta = dir - (PI/6) + (PI/3*math.random())

    local offset = nil

        offset = FindWalkableOffset(pt, theta, 6 + math.random()*6, 12, true) --12

    if offset then
        pt.x = pt.x + offset.x
        pt.y=0
        pt.z = pt.z + offset.z
        inst.LaunchProjectile(inst,pt)
    end
end

local function spawnburns(inst,rad,startangle,endangle,num)
    startangle = startangle *DEGREES
    endangle = endangle *DEGREES
    local pt = Vector3(inst.Transform:GetWorldPosition()) 
    local down = TheCamera:GetDownVec()             
    local angle = math.atan2(down.z, down.x)

    local angle = angle + startangle
    local angdiff = (endangle-startangle)/num
    for i=1,num do
        local offset = Vector3(rad * math.cos( angle ), 0, rad * math.sin( angle ))
        local newpt = pt + offset      
        local fx = SpawnPrefab("laser")
        fx.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
        local burn =  SpawnPrefab("laserscorch")
        burn.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
        angle = angle + angdiff           
    end    
end

local actionhandlers = 
{    
    ActionHandler(ACTIONS.SPECIAL_ACTION, nil),
}

local events=
{
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", onattackfn),
    EventHandler("attacked", onattackedfn),
    EventHandler("activate", function(inst) inst.sg:GoToState("activate") end),    
}

local function ShakeIfClose(inst)
    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    if player then
        ShakeAllCameras(CAMERASHAKE.FULL, 0.7, .02, 3, inst, SHAKE_DIST)
    end
end

local function ShakeIfClose_Footstep(inst)
    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    if player then
        ShakeAllCameras(CAMERASHAKE.FULL, 0.35, .02, 1.25, inst, SHAKE_DIST)
    end
end

local function DoFootstep(inst)
    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step", {intensity=math.random()})
    -- inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/pangolden/walk", {timeoffset=math.random()})
end

local states=
{

    State{
        name = "idle",
        tags = {"idle"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
            
            if inst.wantstobarrier then
                inst.wantstobarrier = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("barrier")
                end
            elseif inst.wantstospin then
                inst.wantstospin = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("spin")
                end            
            elseif inst.wantstolob then
                inst.wantstolob = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("lob")
                end                
            elseif inst.wantstoteleport then
                inst.wantstoteleport = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("telportout_pre")
                end            
            elseif inst.wantstomine then
                inst.wantstomine = nil
                if inst.components.combat.target then                                    
                    inst.sg:GoToState("bomb_pre")
                end       
            end      

        end,

        timeline=
        {
    ----------gears loop--------------
            TimeEvent(19*FRAMES, function(inst) 
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )             
            end),
            TimeEvent(46*FRAMES, function(inst) 
                inst.SoundEmitter:SetParameter( "gears", "intensity", .5 )             
            end),

        },  

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),    
        },

    },

-------------------ACTIVATE--------------

    State{
        name = "activate",
        tags = {"busy"},
        
        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/gears_LP","gears")
        end,
        
        timeline=
        {
            ----start---
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/start") end),
            -----------gears loop--------------------
            TimeEvent(0*FRAMES, function(inst)              
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.2 )
            end),
            TimeEvent(25*FRAMES, function(inst) 
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.3 )
            end),
            TimeEvent(50*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.4 )
            end),
            TimeEvent(75*FRAMES, function(inst) 
                inst.SoundEmitter:SetParameter( "gears", "intensity", 1 )
            end),

            TimeEvent(100*FRAMES, function(inst) 
                inst.SoundEmitter:SetParameter( "gears", "intensity", .7 )             
            end),

            ---------------electric--------------------
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(39*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(42*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(65*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(83*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(86*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(103*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(106*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.25) end),
            TimeEvent(113*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.25) end),
        ---------------green lights--------------------
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active",nil,.5) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/active") end),
            TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/active") end),
            TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(56*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
        -------------step---------------
            TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step") end),
            TimeEvent(101*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step") end),
        -------------servo---------------            
            TimeEvent(28*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(46*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(64*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(84*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(128*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
    -------------tanut---------------
            TimeEvent(106*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/taunt") end),
            
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

----------------------COMBAT------------------------

   
    State{
        name = "hit",
        tags = {"hit"},
        
        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/hit")
            inst.AnimState:PlayAnimation("hit")
        end,
        
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "canrotate"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_chomp")
        end,

        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/dig") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/drag") end),
            TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },
        
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",  
        tags = {"busy"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("death_explode")
            inst.Physics:ClearCollisionMask()
        end,

        timeline=
        {
                    -------------green_explotion---------------            
            TimeEvent(2*FRAMES, function(inst)
                 inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .2})
            end),
            TimeEvent(6*FRAMES, function(inst)
                 inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .3})
            end),
            TimeEvent(23*FRAMES, function(inst)
                 inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .4})
            end),
            TimeEvent(26*FRAMES, function(inst)
                 inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .6})
            end),
            TimeEvent(33*FRAMES, function(inst)
                 inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .8})
            end),
            TimeEvent(36*FRAMES, function(inst)
                 inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 1})
            end),
            ----gears loop_---
            TimeEvent(17*FRAMES, function (inst) inst.SoundEmitter:KillSound("gears") end),
            ----death voice----
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/death") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/death_taunt") end),
            ---- explode---
            TimeEvent(61*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small",nil,.5) end),
            TimeEvent(67*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small",nil,.6) end),
            TimeEvent(77*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small",nil,.7) end),
            TimeEvent(79*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small",nil,.6) end),
            TimeEvent(82*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode") end),

            TimeEvent(81*FRAMES, function(inst) 
                    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
                    if player then
                        ShakeAllCameras(CAMERASHAKE.FULL, 0.7, .02, 2, inst, SHAKE_DIST)
                    end           
                    local x,y,z = inst.Transform:GetWorldPosition()
                    SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z) 
                    SpawnPrefab("laserscorch").Transform:SetPosition(x+1, 0, z-1)    
                    SpawnPrefab("laserscorch").Transform:SetPosition(x-1, 0, z+1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x+1, 0, z)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z+1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z-1)
                    SpawnPrefab("laserscorch").Transform:SetPosition(x-1, 0, z)
                    
                    TheWorld:DoTaskInTime(2,function()
                            local head = SpawnPrefab("ancient_robot_head")
                            head.spawntask:Cancel()
                            head.spawntask = nil
                            head.spawned = true
                            head:AddTag("dormant")                                                    
                            head.Transform:SetPosition(x,y+8,z)
                            head.sg:GoToState("fall")
                        end)
                    inst.DoDamage(inst, 6)
                    inst.components.lootdropper:DropLoot()      
                    inst.DropParts(inst)
                end),
        },
    },

    ------------- TELEPORT ----------------------------

    State{
        name = "telportout_pre",  
        tags = {"busy"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out_pre")

        end,

        events =
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("telportout") end ),        
        },

        timeline=
        {
                        ---teleport---
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/teleport_out") end),
                    -------------step---------------
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
        },
    },

    State{
        name = "telportout",  
        tags = {"busy"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out")          
        end,            
        
        events =
        {   
            EventHandler("animover", function(inst)                
                inst:Hide()
                inst:DoTaskInTime(0.5,function() teleport(inst)  end)
            end ),        
        },

        timeline=
        {
                        -----------servo---------------            
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            ----steps---
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.15) end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step",nil,.25) end),
            TimeEvent(39*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step") end),
            ----------gears loop--------------
            TimeEvent(19*FRAMES, function(inst) 
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )             
            end),
            TimeEvent(5*FRAMES, function(inst)
                inst.DoDamage(inst,4)
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.Physics:SetActive(false)
                inst.DynamicShadow:Enable(false)
                --inst.Physics:ClearCollisionMask()        
                inst.DoDamage(inst,5)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.DoDamage(inst,5)
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.DoDamage(inst,4)
            end),
        },
    },

    State{
        name = "telportin",  
        tags = {"busy"},
        
        onenter = function(inst)
            inst:Show()
            inst.DynamicShadow:Enable(true)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_in")
        end,            
        
        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),        
        },

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/teleport_in") end),
            -----------step---------------
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5) end),
            TimeEvent(16*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
            end),
            TimeEvent(17*FRAMES, function(inst)    
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, .02, 2, inst, 40)
                inst.components.groundpounder:GroundPound()
            end),
            TimeEvent(19*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),
        },
    },

    --------------------- BOMBS -------------------------------

    State{
        name = "bomb_pre",  
        tags = {"busy"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pre")
        end,            

        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("bomb")
            end ),        
        },
        timeline=
        {   
            -----rust----
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            -----bomb ting----
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            ----electro-----
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
        },
    },

    State{
        name = "bomb",  
        tags = {"busy"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_loop")
        end,            
        
        timeline=
        {   ---mine shoot---
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),


            TimeEvent(1*FRAMES, function(inst)
                launchprojectile(inst, 0)
            end),
            TimeEvent(6*FRAMES, function(inst)    
                launchprojectile(inst, PI*0.5)
            end),
            TimeEvent(11*FRAMES, function(inst)    
                launchprojectile(inst, PI)
            end),
            TimeEvent(16*FRAMES, function(inst)    
                launchprojectile(inst, PI*1.5)
            end),
        },

        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("bomb_pst")
            end ),        
        },
    },

    State{
        name = "bomb_pst",  
        tags = {"busy"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pst")
        end,            

        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),        
        },
        
        timeline=
        {
            -----rust----
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            -----bomb ting----
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
             -----------servo---------------            
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()}) end),
        },
    },

---------------------------LOB---------------

    State{
        name = "lob",  
        tags = {"busy","canrotate"},
        
        onenter = function(inst)

            inst.AnimState:PlayAnimation("atk_lob")

            inst.lobtarget = nil
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst.lobtarget = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
            else
                local angle = inst.Transform:GetRotation() * DEGREES
                local offset = Vector3(15 * math.cos( angle ), 0, -15 * math.sin( angle ))
                local pt = Vector3(inst.Transform:GetWorldPosition())

                inst.lobtarget = Vector3(pt.x + offset.x,pt.y + offset.y,pt.z + offset.z)
            end        
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
        end,            

        timeline =
        {
            TimeEvent(30*FRAMES, function(inst)     
                local pt = inst.lobtarget
                if inst.components.combat.target and inst.components.combat.target:IsValid() then   
                    inst.lobtarget = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
                end                  
                inst.orbs = inst.orbs -1 
                if inst.orbs == 0 then
                    inst.orbtime = 10
                end
                inst.ShootProjectile(inst, inst.lobtarget)
            end),

            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser_pre") end),
            TimeEvent(30*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity=math.random()}) 
            end),
        },

        onupdate = function(inst)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then 
                inst:ForceFacePoint(Vector3(inst.components.combat.target.Transform:GetWorldPosition()))
            end
        end,

        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),        
        },
    },

----------------------SPIN--------------------

    State{
        name = "spin",  
        tags = {"busy"},
        
        onenter = function(inst)
            print("======= START ===============")
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_circle")
            inst.components.combat.playerdamagepercent = 1
        end,            
        
        timeline=
        {   
            -------------step---------------
            TimeEvent(10*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step",nil,.5) end),
            TimeEvent(68*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5) end),
            TimeEvent(70*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5) end),
            TimeEvent(82*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step",nil,.5) end),
            TimeEvent(90*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5) end),

            -----------servo---------------            
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(62*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            ----electro-----
            TimeEvent(14*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") 
            end),
            TimeEvent(21*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro")
            end),
            TimeEvent(26*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") 
            end),
            ---------spin laser--------
            TimeEvent(30*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/spin") 
            end),
            TimeEvent(30*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/burn_LP","laserburn") 
            end),
            TimeEvent(49*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("laserburn")
            end),
            ---mix---
            TimeEvent(49*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),
             ---------spin laser ground--------
            TimeEvent(37*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,0,45)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0})
                spawnburns(inst,BEAMRAD,0,45,5)
            end),
            TimeEvent(39*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,45,90)
                spawnburns(inst,BEAMRAD,45,90,5)
            end),
            TimeEvent(40*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,90,135)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .3})
                spawnburns(inst,BEAMRAD,90,135,5)
            end),
            TimeEvent(41*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,135,180)

                spawnburns(inst,BEAMRAD,135,180,5)
            end),
            TimeEvent(42*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,180,225)

                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0.5})
                spawnburns(inst,BEAMRAD,180,225,5)
            end),            
            TimeEvent(45*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,225,270)

                spawnburns(inst,BEAMRAD,225,270,5)
            end),
            TimeEvent(47*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,270,315)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0.7})
                spawnburns(inst,BEAMRAD,270,315,5)
            end),                                    
            TimeEvent(48*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,315,360)
                spawnburns(inst,BEAMRAD,315,360,5)
            end),
            TimeEvent(50*FRAMES, function(inst)
                inst.DoDamage(inst,BEAMRAD,0,45)

                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 1})
                spawnburns(inst,BEAMRAD,0,45,5)
            end),
            ---mix---
            TimeEvent(51*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),
        },


        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.spintime = 10            
            inst.components.combat.playerdamagepercent = .5
        end, 

        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),        
        },
    },

----------------------BARRIER--------------------

    State{
        name = "barrier",  
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_barrier")
        end,            
        
        timeline=
        {        
            --step---
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step") 
            end),
            ---barrier attack---
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/barrier") 
            end),

            TimeEvent(67*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
            end),
            
            TimeEvent(67*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),

            TimeEvent(90*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),

            TimeEvent(64*FRAMES, function(inst)                
                inst.components.groundpounder.damageRings = 4
                inst.components.groundpounder.destructionRings = 4
                inst.components.groundpounder.numRings = 4                
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, .02, 2, inst, 40)
                inst.components.groundpounder:GroundPound()
                local pt = Vector3(inst.Transform:GetWorldPosition())
                inst:DoTaskInTime(0.6, inst.SpawnBarrier)
                local fx = SpawnPrefab("metal_hulk_ring_fx")
                fx.Transform:SetPosition(pt.x,pt.y,pt.z)
            end),
        },

        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.barriertime = 10
            inst.components.groundpounder.damageRings = 2
            inst.components.groundpounder.destructionRings = 3
            inst.components.groundpounder.numRings = 3            
        end, 

        events =
        {   
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),        
        },
    },


---------------------------WALKING---------------

    State{
            name = "walk_start",
            tags = {"moving", "canrotate"},

            onenter = function(inst) 
                local anim = "walk_pre"
                inst.AnimState:PlayAnimation(anim)
            end,

            events =
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end ),        
            },
        },
        
    State{            
            name = "walk",
            tags = {"moving", "canrotate"},
            
            onenter = function(inst)
                local anim = "walk_loop"

                inst.AnimState:PlayAnimation(anim)

                inst.components.locomotor:WalkForward()
                if inst.components.combat and inst.components.combat.target and math.random() < .5 then
                    -- inst:DoTaskInTime(math.random(13)*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/grrrr") end)
                end
            end,

            onupdate = function(inst)
                if inst.wantstolob then
                    inst.wantstolob = nil
                    if inst.components.combat.target then                                    
                        inst.sg:GoToState("lob")
                    end
                end
            end,

            events=
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end ),        
            },

            timeline=
            {
                TimeEvent(12*FRAMES, function(inst)
                    DoFootstep(inst)
                end),
                TimeEvent(16*FRAMES, function(inst)
                    DoFootstep(inst)
                end),
                TimeEvent(20*FRAMES, function(inst) 
                    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/step", {intensity=math.random()}) end),
                TimeEvent(3*FRAMES, function(inst) 
                    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()}) end),
            
            },
        },        
    
    State{            
            name = "walk_stop",
            tags = {"canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()
                local anim = "walk_pst"
                DoFootstep(inst)
                inst.AnimState:PlayAnimation(anim)
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
            },
        },

    State{
            name = "run_start",
            tags = {"moving", "running", "atk_pre", "canrotate"},

            onenter = function(inst) 
                inst.components.locomotor:RunForward()
                -- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/taunt", "taunt")
                inst.AnimState:PlayAnimation("charge_pre")
            end,

            events =
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),        
            },
        },
        
    State{
            name = "run",
            tags = {"moving", "running", "canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:RunForward()
                -- if not inst.SoundEmitter:PlayingSound("taunt") then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/taunt", "taunt") end
                inst.AnimState:PlayAnimation("charge_roar_loop")
            end,

            timeline=
            {
                -- TimeEvent(12*FRAMES, function(inst)
                --     DoFootstep(inst)
                --     destroystuff(inst)
                -- end),
                -- TimeEvent(16*FRAMES, function(inst)
                --     DoFootstep(inst)
                --     destroystuff(inst)
                -- end),
                -- TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/step") end),
            },   

            onupdate = function(inst)
                if inst.wantstolob then
                    inst.wantstolob = nil
                    if inst.components.combat.target then                                    
                        inst.sg:GoToState("lob")
                    end
                end
            end,

            events=
            {   
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end ),        
            },
        },        
    
    State{
            name = "run_stop",
            tags = {"canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()
                local should_softstop = false
                inst.AnimState:PlayAnimation("charge_pst")          
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
            },
        },

}

CommonStates.AddFrozenStates(states)

return StateGraph("ancient_hulk", states, events, "idle", actionhandlers)


