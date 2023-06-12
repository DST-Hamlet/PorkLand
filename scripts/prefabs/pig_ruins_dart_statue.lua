require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/pig_ruins_dart_statue.zip"),     
    Asset("ANIM", "anim/pig_ruins_dart_statue_stage2.zip"),     
    Asset("ANIM", "anim/pig_ruins_dart_statue_stage3.zip"),         
}

local prefabs =
{
    "pig_ruins_dart",
}    

SetSharedLootTable( 'dart_thrower',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 0.4},
})


local function updateart(inst)    
    if not inst.components.disarmable.armed then
        inst.components.autodartthrower:TurnOff()
        inst.AnimState:PlayAnimation("disarmed")
    end

    if inst.components.workable.workleft == TUNING.ROCKS_MINE_GIANT then        
      inst.AnimState:SetBuild("pig_ruins_dart_statue")  
    elseif inst.components.workable.workleft > TUNING.ROCKS_MINE_GIANT * (2/3) then
        inst.AnimState:SetBuild("pig_ruins_dart_statue_stage2")  
    elseif inst.components.workable.workleft > TUNING.ROCKS_MINE_GIANT * (1/3) then
        inst.AnimState:SetBuild("pig_ruins_dart_statue_stage3")  
    end    
end

local function onsave(inst, data)    
    data.rotation = inst.Transform:GetRotation()
    data.ccw = inst.ccw
end

local function onload(inst, data)
    if data.rotation then
        inst.setrotation(inst,data.rotation)
    end
    inst.ccw = data.ccw
    updateart(inst)
end

local function launchdart(inst, angle)

    inst:DoTaskInTime( math.random()*0.3, function()
            local proj = SpawnPrefab("pig_ruins_dart")
            local x, y, z = inst.Transform:GetWorldPosition()
            local radius = 1
            local theta = angle*DEGREES         
            local pt = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))

            proj.Transform:SetPosition(x+pt.x, y, z+pt.z)        
            proj.Transform:SetRotation(angle)                        
            proj.Physics:SetMotorVel(30, 0, 0)
            proj.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/blowdart_fire")

            local fx = SpawnPrefab("circle_puff_fx")
			if fx then -- Another crash prevention, until we get the prefab working
				fx.Transform:SetPosition(x+pt.x, y+2, z+pt.z)                 
			end
        end)     
end

local function shoot(inst)
    if inst.components.disarmable.armed then
        local angle = inst.Transform:GetRotation()
        launchdart(inst, angle)     
    end
end

local function disarm(inst, doer) 
   
    local pt = Point(inst.Transform:GetWorldPosition())
    inst.components.lootdropper:SpawnLootPrefab("blowdart_pipe", pt)
    updateart(inst)
    inst.components.autodartthrower:TurnOff()
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_wall")
    
end

local function turnonfn(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/dart_statue_LP","rotate")
end

local function turnofffn(inst)
   inst.SoundEmitter:KillSound("rotate") 
   inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/dart_statue_stop")
end

local function setrotation(inst,rotation)
    if rotation < 0 then 
        rotation = rotation + 360
    end
    if rotation > 360 then 
        rotation = rotation - 360
    end    
    inst.Transform:SetRotation(rotation)
    rotation = Remap(rotation,0,360,1,0)

    inst.AnimState:SetPercent("CCW",rotation)
end

local function updaterotation(inst,dt)
    local inc = 360/10 * dt
    if not inst.ccw then
        inc = -inc
    end    
    setrotation(inst,inst.Transform:GetRotation() + inc)
    inst.darttimer = inst.darttimer + dt
    if inst.darttimer >= inst.shoottime then
        inst.shootdart(inst)
        inst.darttimer = 0
    end
end

local function fn(Sim)

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

	inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .25)   

    anim:SetBank("pig_ruins_dart_statue")
    anim:SetBuild("pig_ruins_dart_statue")

    anim:SetPercent("CCW",0)

    inst:AddTag("dartthrower")

    inst.Transform:SetRotation(0)

    inst.entity:AddSoundEmitter()    
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("inspectable")
    inst:AddComponent("disarmable")
    inst.components.disarmable.disarmfn = disarm

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('dart_thrower')

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_GIANT)
    
    inst.components.workable:SetOnWorkCallback(
        function(inst, worker, workleft)
            local pt = Point(inst.Transform:GetWorldPosition())
            inst.components.autodartthrower:TurnOn()
            inst:AddChild(SpawnPrefab("rock_hit_debris"))
            if workleft <= 0 then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
                inst.components.lootdropper:DropLoot(pt)
                SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
                inst:Remove()                           
            end
            updateart(inst)
        end)      

    --------------------
    inst.OnSave = onsave 
    inst.OnLoad = onload 
    inst.shootdart = shoot
    inst.updaterotation = updaterotation    
    inst.setrotation = setrotation
        
    inst.name = STRINGS.NAMES.PIG_RUINS_DART_STATUE

    if math.random() < 0.5 then
        inst.ccw = true
    end

    inst.darttimer = 0
    inst.shoottime = 0.4

    inst:AddComponent("autodartthrower")
    inst.components.autodartthrower.updatefn = updaterotation
    inst.components.autodartthrower.turnonfn = turnonfn
    inst.components.autodartthrower.turnofffn = turnofffn

    updateart(inst)

    setrotation(inst,math.random()*360)

    return inst
end


return  Prefab( "pig_ruins_dart_statue", fn, assets, prefabs)        

        