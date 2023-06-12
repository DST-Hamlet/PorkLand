local SHAKE_DIST = 40
local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/metal_hulk_build.zip"),
	Asset("ANIM", "anim/metal_hulk_basic.zip"),
    Asset("ANIM", "anim/metal_hulk_attacks.zip"),
    Asset("ANIM", "anim/metal_hulk_actions.zip"),
    Asset("ANIM", "anim/metal_hulk_barrier.zip"),
    Asset("ANIM", "anim/metal_hulk_explode.zip"),    
    Asset("ANIM", "anim/metal_hulk_bomb.zip"),    
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),    

    Asset("ANIM", "anim/laser_explode_sm.zip"),  
    Asset("ANIM", "anim/smoke_aoe.zip"),
    Asset("ANIM", "anim/laser_explosion.zip"),
    --Asset("ANIM", "anim/ground_chunks_breaking.zip"),
    Asset("ANIM", "anim/ground_chunks_breaking_brown.zip"),

    --Asset("SOUND", "sound/bearger.fsb"),
}

local prefabs =
{
    "groundpound_fx",
    "groundpoundring_fx",
    "ancient_robots_assembly",
    "rock_basalt",
    "living_artifact",
    "ancient_hulk_orb_small",
    "infused_iron",
    "living_artifact_blueprint",
}

SetSharedLootTable('ancient_hulk',
{
    {'infused_iron',            1.0},
    {'infused_iron',            1.0},    
    {'infused_iron',            1.0},
    {'infused_iron',            1.0},
    {'infused_iron',            1.0},
    {'infused_iron',            1.0},
    {'infused_iron',            0.25},

    {'living_artifact_blueprint',   1},

    {'iron',            1.0},        
    {'iron',            1.0},        
    {'iron',            0.75},    
    {'iron',            0.25},
    {'iron',            0.25},
    {'iron',            0.25},


    {'gears',           1.0},
    {'gears',           1.0},
    {'gears',           0.75},
    {'gears',           0.30},    
})


local INTENSITY = .75
local function SetLightValue(inst, val1, val2, time)
    inst.components.fader:StopAll()
    if val1 and val2 and time then
        inst.Light:Enable(true)
        inst.components.fader:Fade(val1, val2, time, function(v) inst.Light:SetIntensity(v) end)
--[[
        if inst.Light ~= nil then
            inst.Light:Enable(true)
            inst.Light:SetIntensity(.6 * val)
            inst.Light:SetRadius(5 * val)
            inst.Light:SetFalloff(3 * val)
        end
        ]]
    else    
        inst.Light:Enable(false)
    end
end

local function SetFires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do 
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end

local function ApplyDamageToEnt(inst,ent, targets, rad, hit)
    local x, y, z = inst.Transform:GetWorldPosition()
    if hit then 
        targets = {}
    end    
    if not rad then 
        rad = 0
    end
    local v = ent
    if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) and not v:HasTag("laser_immune") then            
        local vradius = 0
        if v.Physics then
            vradius = v.Physics:GetRadius()
        end

        local range = rad + vradius
        if hit or v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
            local isworkable = false
            if v.components.workable ~= nil then
                local work_action = v.components.workable:GetWorkAction()
                --V2C: nil action for campfires
                isworkable =
                    (   work_action == nil and v:HasTag("campfire")    ) or
                    
                        (   work_action == ACTIONS.CHOP or
                            work_action == ACTIONS.HAMMER or
                            work_action == ACTIONS.MINE or   
                            work_action == ACTIONS.DIG or
                            work_action == ACTIONS.BLANK
                        )
            end
            if isworkable then
                targets[v] = true
                v:DoTaskInTime(0.6, function() 
                    if v.components.workable then
                        v.components.workable:Destroy(inst) 
                        local vx,vy,vz = v.Transform:GetWorldPosition()
                        v:DoTaskInTime(0.3, function() SetFires(vx,vy,vz,1) end)
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
    return targets   
end

local function DoDamage(inst, rad, startang, endang, spawnburns)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = nil
    if startang and endang then
        startang = startang + 90
        endang = endang + 90
        
        local down = TheCamera:GetDownVec()             
        angle = math.atan2(down.z, down.x)/DEGREES
    end

    SetFires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do  --  { "_combat", "pickable", "campfire", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
        local dodamage = true
        if startang and endang then
            local dir = inst:GetAngleToPoint(Vector3(v.Transform:GetWorldPosition())) 

            local dif = angle - dir         
            while dif > 450 do
                dif = dif - 360 
            end
            while dif < 90 do
                dif = dif + 360
            end                       
            if dif < startang or dif > endang then                
                dodamage = nil
            end
        end
        if dodamage then
            targets = ApplyDamageToEnt(inst,v, targets, rad)
        end
    end
end

---------------------------------------------------------------------------------------

-- Something went very wrong with your updating of these functions. The game got in to an infinite loop, using tens of GBs of RAM in seconds.
-- I replaced them with the originals, and all is fine. Need to look in to it deeper.

local function color(x,y,tiles,islands,value)
    tiles[y][x] = false
    islands[y][x] = value
end

local function check_validity(x,y,w,h,tiles,stack)
    if x >= 1 and y >= 1 and x <= w and y <= h and tiles[y][x] then
        stack[#stack+1] = {x=x,y=y}
    end
end

local function floodfill(x,y,w,h,tiles,islands,value)
--    Queue q
    local q = {}
--    q.push((x,y))
    q[#q+1] = {x=x,y=y}
--    while (q is not empty)
    while #q > 0 do
--       (x1,y1) = q.pop()
        local el = q[#q] 
        table.remove(q)
        local x1,y1 = el.x, el.y
--       color(x1,y1)         -- islandmap[x,y] = color
--print("Color",x1,y1)
        color(x1,y1,tiles,islands,value)
                            
        check_validity(x1+1,y1,w,h,tiles,q)
        check_validity(x1-1,y1,w,h,tiles,q)
        check_validity(x1,y1+1,w,h,tiles,q)
           check_validity(x1,y1-1,w,h,tiles,q)
        -- diagonals
        check_validity(x1-1,y1-1,w,h,tiles,q)
        check_validity(x1-1,y1+1,w,h,tiles,q)
        check_validity(x1+1,y1-1,w,h,tiles,q)
            check_validity(x1+1,y1+1,w,h,tiles,q)

--            q.push(x1,y1-1)    
    end
end

local function dofloodfillfromcoord(x,y,w, h, tiles, islands)
    local index = 3
    local rescan = true
    local val = tiles[y][x]
    if val then
        floodfill(x,y,w,h,tiles,islands,index)
        index = index + 1
    end
end

function getDropLocations(inst)
   local islands = {}
   local tiles = {}
   local w,h = TheWorld.Map:GetSize()

   for y = 1,h do
       tiles[y] = {}
       islands[y] = {}
       for x = 1, w do
           local tile = TheWorld.Map:GetTile(x-1,y-1)

           tiles[y][x] = (not IsOceanTile(tile)) and (not (tile == WORLD_TILES.IMPASSABLE))
       end
   end
   local x,y,z = inst.Transform:GetWorldPosition()

   x = math.floor(x/4+ (w/2))
   z = math.floor(z/4 + (h/2))
   dofloodfillfromcoord(x,z,w, h, tiles, islands)

   local locations = {}
   for z=1,h do
       for x=1,w do
           if islands[z][x] then
               table.insert(locations,{x=x,z=z})
           end
       end
   end

   return locations
end

---------------------------------------------------------------------------------------

local function DropParts(inst)
	print("DS - Hulk - Dropping parts after defeat...")
    local locations = getDropLocations(inst)
    local map = TheWorld.Map
    local w,h = map:GetSize()

    assert(#locations > 0,"NO LOCATIONS!?!?!?")

    local parts = {
        "ancient_robot_claw",
        "ancient_robot_claw",
        "ancient_robot_leg",
        "ancient_robot_leg",
        "ancient_robot_ribs",
    }

    for i, part in ipairs(parts) do        
		print("DS - Hulk - Dropping part", part)
        local partprop = SpawnPrefab(part)
		print("DS - Hulk - Part spawned")
        partprop.spawntask:Cancel()
        partprop.spawntask = nil
        partprop.spawned = true
        partprop:AddTag("dormant")                                                    
        partprop.sg:GoToState("idle_dormant")

        local idx = math.random(1,#locations)
        local sample = locations[idx]          
        local loc = sample            
		table.remove(locations,idx)
		print("DS - Hulk - IDX:", idx, "Sample:", sample, "loc:", loc)
		

        partprop.Transform:SetPosition( (loc.x-(w/2)) *4 -4,0, (loc.z-(h/2)) *4-4 )
        
        inst.DoDamage(partprop, 5)        
    end
end

local TARGET_DIST = 30

local function CalcSanityAura(inst, observer)
    if inst.components.combat.target then
        return -TUNING.SANITYAURA_HUGE
    end

    return -TUNING.SANITYAURA_LARGE
end

local function RetargetFn(inst)
    return FindEntity(inst, TARGET_DIST, function(guy)
        return inst.components.combat:CanTarget(guy)              
    end)
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnCollide(inst, other)
    local v = other

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
        v:DoTaskInTime(0.6, function() 
            if v.components.workable then
                v.components.workable:Destroy(inst)                 
            end
         end)
    elseif v.components.pickable ~= nil
        and v.components.pickable:CanBePicked()
        and not v:HasTag("intense") then

        local num = v.components.pickable.numtoharvest or 1
        local product = v.components.pickable.product
        local x1, y1, z1 = v.Transform:GetWorldPosition()
        v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
        if product ~= nil and num > 0 then
            for i = 1, num do
                local loot = SpawnPrefab(product)
                loot.Transform:SetPosition(x1, 0, z1)
            end
        end
    end    
    -- may want to do some charging damage?
end

local function LaunchProjectile(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()

    local projectile = SpawnPrefab("ancient_hulk_mine")

    projectile.primed = false
    projectile.AnimState:PlayAnimation("spin_loop",true)
    projectile.Transform:SetPosition(x, 1, z)

    --V2C: scale the launch speed based on distance
    --     because 15 does not reach our max range.
    local dx = targetpos.x - x
    local dz = targetpos.z - z
    local rangesq = dx * dx + dz * dz
    local maxrange = TUNING.FIRE_DETECTOR_RANGE
    local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(speed)
    projectile.components.complexprojectile:SetGravity(-25)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    projectile.owner = inst
end


local function ShootProjectile(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()

    local projectile = SpawnPrefab("ancient_hulk_orb")

    projectile.primed = false
    projectile.AnimState:PlayAnimation("spin_loop",true)

    local pt = inst.shotspawn:GetPosition()
    projectile.Transform:SetPosition(pt.x, pt.y, pt.z)
    --projectile.Transform:SetPosition(x, 4, z)

   -- inst.shotspawn:Remove()
   -- inst.shotspawn = nil

    local speed =  60 --  easing.linear(rangesq, 15, 3, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(speed)
    projectile.components.complexprojectile:SetGravity(25)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    projectile.owner = inst
end

local function SpawnBarrier(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local angle = 0
    local radius = 13
    local number = 32
    for i=1,number do        
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local newpt = pt + offset
        local tile = TheWorld.Map:GetTileAtPoint(newpt.x, newpt.y, newpt.z)

        if tile ~= GROUND.IMPASSABLE and tile ~= GROUND.INVALID and not TheWorld.Map:IsOceanTileAtPoint(newpt.x, newpt.y, newpt.z) then
            inst:DoTaskInTime(math.random()*0.3, function()            
                local rock = SpawnPrefab("rock_basalt")
                rock.AnimState:PlayAnimation("emerge")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rock")
                rock.AnimState:PushAnimation("full")

                rock.Transform:SetPosition(newpt.x, newpt.y, newpt.z)

            end)
        end
        angle = angle + (PI*2/number)
    end
end

local function CheckForAttacks(inst)
    -- mine
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, {"ancient_hulk_mine"})
    if #ents < 2 then 
        inst.wantstomine = true
    else
        inst.wantstomine = nil
    end
    -- lob
    if inst.orbs > 0 then
        if inst.components.combat.target and inst.components.combat.target:IsValid() then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist > 10*10  and dist < 25*25 then
                inst.wantstolob = true
            else
                inst.wantstolob = nil
            end
        end
    else
        inst.orbtime = inst.orbtime -1
        if inst.orbtime <= 0 then
            inst.orbtime = nil
            inst.orbs = 2
        end
    end

    -- teleport
    if inst.components.combat.target and inst.components.combat.target:IsValid() then
        local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
        if dist < 6*6 then
            if not inst.teleporttime then
                inst.teleporttime = 0
            end
            inst.teleporttime = inst.teleporttime + 1
            if inst.teleporttime > 5 then
                inst.wantstoteleport = true
            end
        else
            inst.teleporttime =  nil
        end
    end

    -- spin
    if inst.components.combat.target and inst.components.combat.target:IsValid() and inst.components.health:GetPercent() < 0.5  then
        if not inst.spintime or inst.spintime <=0 then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist < 6*6 then
                inst.wantstospin = true
            else            
                inst.wantstospin = nil
            end
        else
            inst.spintime = inst.spintime - 1            
        end
    end

    -- barrier?
    if inst.components.combat.target and inst.components.combat.target:IsValid() and inst.components.health:GetPercent() < 0.3  then
        if not inst.barriertime or inst.barriertime <=0 then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist < 6*6 then
                inst.wantstobarrier = true
            else            
                inst.wantstobarrier = nil
            end
        else
            inst.barriertime = inst.barriertime - 1            
        end
    end    
end

local function fn(Sim)
    local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()
    
    inst.Transform:SetSixFaced()
	inst.DynamicShadow:SetSize(6, 3.5)

	MakeCharacterPhysics(inst, 1000, 1.5)

    inst.Physics:SetCollisionCallback(OnCollide)

    inst.AnimState:SetBank("metal_hulk")
    inst.AnimState:SetBuild("metal_hulk_build")
    inst.AnimState:PlayAnimation("idle", true)
    
    inst.AnimState:AddOverrideBuild("laser_explode_sm")
    inst.AnimState:AddOverrideBuild("smoke_aoe")    
    inst.AnimState:AddOverrideBuild("laser_explosion")   
    inst.AnimState:AddOverrideBuild("ground_chunks_breaking")   
     
    ------------------------------------------

	inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("ancient_hulk") 
    inst:AddTag("laser_immune")   
    inst:AddTag("mech")

    ------------------------------------------
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------
    
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BEARGER_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health.fire_damage_scale = 0
    
    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_DAMAGE)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(TUNING.ANCIENT_HULK_ATTACK_RANGE, TUNING.ANCIENT_HULK_MELEE_RANGE)
    inst.components.combat:SetAreaDamage(5.5, 0.8)
    inst.components.combat.hiteffectsymbol = "segment01"
    inst.components.combat:SetAttackPeriod(TUNING.BEARGER_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    --inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/bearger/hurt")
    inst:ListenForEvent("killed", function(inst, data)
        if inst.components.combat and data and data.victim == inst.components.combat.target then
            inst.components.combat.target = nil
        end 
    end)


    inst.orbs = 2
    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ancient_hulk")
    
    ------------------------------------------

    inst:AddComponent("inspectable")

    ------------------------------------------

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 3
    inst.components.groundpounder.numRings = 3
    inst.components.groundpounder.groundpoundfx = "groundpound_fx_hulk"

    ------------------------------------------

    inst:ListenForEvent("attacked", OnAttacked)

    ------------------------------------------
    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()    
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(5)
    inst.glow:SetFalloff(3)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(false)

    inst.LaunchProjectile = LaunchProjectile
    inst.ShootProjectile = ShootProjectile
    inst.DoDamage = DoDamage
    inst.SpawnBarrier = SpawnBarrier
    inst.DropParts = DropParts
    inst.SetLightValue = SetLightValue

    inst:DoPeriodicTask(1, CheckForAttacks)

    inst:ListenForEvent("onremove", function() inst.SoundEmitter:KillSound("gears") end, inst )
    
    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.BEARGER_CALM_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.BEARGER_RUN_SPEED
    inst.components.locomotor:SetShouldRun(true)

    inst:SetStateGraph("SGancient_hulk")
    inst:SetBrain(require("brains/ancient_hulkbrain"))

    if not inst.shotspawn then
        inst.shotspawn = SpawnPrefab("ancient_hulk_marker" )        
        inst.shotspawn:Hide()
        inst.shotspawn.persists = false
        local follower = inst.shotspawn.entity:AddFollower()
        follower:FollowSymbol( inst.GUID, "hand01", 0,0,0 )
    end

    return inst
end

local function OnHit(inst, dist)    
    inst.AnimState:PlayAnimation("land")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step_wires")
    inst.AnimState:PushAnimation("open")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust")    
    inst:ListenForEvent("animover", function() 
        if inst.AnimState:IsCurrentAnimation("open") then
            inst.primed  = true
            inst.AnimState:PlayAnimation("green_loop",true)
        end
    end)
end

local function onnearmine(inst, ents)    
    local detonate = false
    for i,ent in ipairs(ents)do
        if not ent:HasTag("ancient_hulk") then
            detonate = true
            break
        end
    end
    if inst.primed and detonate then
        inst.SetLightValue(inst, 0,0.75,0.2 )
        inst.AnimState:PlayAnimation("red_loop", true)
        --start beep
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/active_LP","boom_loop")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro")
        inst:DoTaskInTime(0.8,function() 
            --explode, end beep
        inst.SoundEmitter:KillSound("boom_loop")
            local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
            if player then
                ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, .03, 2, inst, SHAKE_DIST)
            end
            inst:Hide()
            local ring = SpawnPrefab("laser_ring")
            ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) inst:Remove() end)    
            
            local explosion = SpawnPrefab("laser_explosion")
            explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_3")                          
        end)
    end
end

local function minefn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 75, 0.5)

    inst.AnimState:SetBank("metal_hulk_mine")
    inst.AnimState:SetBuild("metal_hulk_bomb")
    inst.AnimState:PlayAnimation("green_loop", true)

    inst:AddTag("ancient_hulk_mine")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.primed = true

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile.yOffset = 2.5

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE)
    --inst.components.combat.playerdamagepercent = .5

    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()    
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(2)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(false)

    inst.SetLightValue = SetLightValue

    inst:AddComponent("creatureprox")   
    inst.components.creatureprox.period = 0.01
    inst.components.creatureprox:SetDist(3.5,5) 
    inst.components.creatureprox:SetOnPlayerNear(onnearmine)

    return inst
end

local function OnHitOrb(inst, dist)    
    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    if player then
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.4, .03, 1.5, inst, SHAKE_DIST)
    end    
    inst.AnimState:PlayAnimation("impact")  
    inst:ListenForEvent("animover", function() 
        if inst.AnimState:IsCurrentAnimation("impact") then
           inst:Remove()
        end
    end)
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())     
    inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) end)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")    
end

local function orbfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 75, 0.5)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst:AddTag("ancient_hulk_orb")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnHitOrb)
    inst.components.complexprojectile:SetHorizontalSpeed(60)
    inst.components.complexprojectile:SetGravity(25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.5

    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()    
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(3)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(true)

    inst.SetLightValue = SetLightValue

    return inst
end

local function OnCollidesmall(inst,other)
    ApplyDamageToEnt(inst,other,nil,nil,true)

    local explosion = SpawnPrefab("laser_explosion")
    explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())  
    explosion.Transform:SetScale(0.4,0.4,0.4)

    -- DANY SOUND          inst.SoundEmitter:PlaySound( smallexplosion )  
    inst:Remove()
end

local function orbsmallfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, 0.5)
	
    inst:AddTag("projectile")

	-- Don't collide with the land edge
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	-- inst.Physics:CollidesWith(COLLISION.WAVES)
    -- inst.Physics:CollidesWith(COLLISION.INTWALL)
    
    inst.Physics:SetCollisionCallback(OnCollidesmall)
    inst.Physics:SetMotorVelOverride(60,0,0)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)    

    inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("locomotor")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE/3)
    inst.components.combat.playerdamagepercent = 0.5

    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()    
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(3)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(true)

    inst.SetLightValue = SetLightValue

    inst:DoTaskInTime(2, int.Remove)

    inst.persists = false

    return inst
end

local function OnCollidecharge(inst,other)
    inst.Physics:SetMotorVelOverride(0,0,0)
    local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    if player then
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.4, .03, 1.5, inst, SHAKE_DIST)
    end    
    inst.AnimState:PlayAnimation("impact")  
    inst:ListenForEvent("animover", function() 
        if inst.AnimState:IsCurrentAnimation("impact") then
           inst:Remove()
        end
    end)
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())     
    inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) end)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")     
end

local function orbchargefn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, 0.5)
    
    inst.Physics:SetCollisionCallback(OnCollidecharge)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)    
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddTag("projectile")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE)
    inst.components.combat.playerdamagepercent = 0.5
 
    inst.Physics:SetMotorVelOverride(40,0,0)

    inst:DoTaskInTime(2, inst.Remove)

    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()    
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(3)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(true)

    inst.SetLightValue = SetLightValue

    return inst
end

local function markerfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
	inst.entity:AddNetwork()
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.persists = false

    return inst
end


return Prefab("ancient_hulk", fn, assets, prefabs),
       Prefab("ancient_hulk_mine", minefn, assets, prefabs),
       Prefab("ancient_hulk_orb", orbfn, assets, prefabs),
       Prefab("ancient_hulk_orb_small", orbsmallfn, assets, prefabs),
       Prefab("ancient_hulk_orb_charge", orbchargefn, assets, prefabs),
       Prefab("ancient_hulk_marker", markerfn, assets, prefabs)