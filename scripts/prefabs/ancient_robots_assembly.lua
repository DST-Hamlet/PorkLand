local UPDATETIME = 5

local assets=
{
	Asset("ANIM", "anim/metal_hulk_merge.zip"),
}

local prefabs =
{
    "iron",
    "sparks_fx",
    "sparks_green_fx",
    "laser_ring",
}

local function SpawnPart(inst, prefab, x,y,z,rotation)
    local part = SpawnPrefab(prefab)
    part.Transform:SetPosition(x,y,z)
    part.spawned = true
    part.Transform:SetRotation(rotation)     
    part:DoTaskInTime(math.random()*0.6,function()
        part:PushEvent("shock")
        part.lifetime = 20 + (math.random()*20)  --120 
        if not part.updatetask then
            part.updatetask = part:DoPeriodicTask(part.UPDATETIME, part.PeriodicUpdate)
        end  
    end)
    
    part.sg:GoToState("separate")
end

local function BreakApart(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local down = TheCamera:GetDownVec()             
    local angle = math.atan2(down.z, down.x) / DEGREES

    if inst.head == 1 then
        SpawnPart(inst, "ancient_robot_head",x+down.x,y,z+down.z, math.random()*360)
         
    end
    if inst.spine == 1 then
        SpawnPart(inst, "ancient_robot_ribs",x-down.x,y,z-down.z, math.random()*360)
    end  

    if inst.arms > 0 then
        for i=1, inst.arms do
            local sx = x - down.x
            local sz = z + down.z
            local sy = y
            local rotation = angle + 90

            if i==2 then
                sx = x + down.x
                sz = z - down.z      
                rotation = angle - 90                  
            end

            SpawnPart(inst, "ancient_robot_claw",sx,sy,sz, rotation)
        end        
    end     
    if inst.legs > 0 then
        for i=1,inst.legs do
            local sx = x - (2*down.x)
            local sz = z + down.z
            local sy = y
            local rotation = angle + 90

            if i==2 then
                sx = x + down.x
                sz = z - (2*down.z)
                rotation = angle - 90
            end

            SpawnPart(inst, "ancient_robot_leg",sx,sy,sz, rotation)            
        end
    end 
end 

local function OnMerge(inst)
    inst:RefreshArt()
    inst.AnimState:PlayAnimation("merge")
    inst.AnimState:PushAnimation("idle",true)  
    local pos = Vector3(inst.Transform:GetWorldPosition())
	TheWorld:PushEvent("ms_sendlightningstrike", pos)
    SpawnPrefab("laserhit"):SetTarget(inst)

    if inst.head == 1 and inst.arms > 1 and inst.legs > 1 and inst.spine == 1 then
        local hulk = SpawnPrefab("ancient_hulk")
        local x,y,z = inst.Transform:GetWorldPosition()
        hulk.Transform:SetPosition(x,y,z)
        hulk:PushEvent("activate")
        inst:Remove()
    end
end

local function OnLightning(inst, data)

end

local function RefreshArt(inst)
    if inst.legs == 0 then
        inst.AnimState:Hide("leg01")
        inst.AnimState:Hide("leg02")
    elseif inst.legs == 1 then
        inst.AnimState:Show("leg01")
        inst.AnimState:Hide("leg02")
    else
        inst.AnimState:Show("leg01")
        inst.AnimState:Show("leg02")
    end
    if inst.arms == 0 then
        inst.AnimState:Hide("arm01")
        inst.AnimState:Hide("arm02")
    elseif inst.arms == 1 then
        inst.AnimState:Show("arm01")
        inst.AnimState:Hide("arm02")
    else
        inst.AnimState:Show("arm01")
        inst.AnimState:Show("arm02")
    end
    if inst.head == 0 then
        inst.AnimState:Hide("head")
    else
        inst.AnimState:Show("head")
    end
    if inst.spine == 0 then
        inst.AnimState:Hide("spine")
    else
        inst.AnimState:Show("spine")
    end   
    if inst.spine == 1 and inst.head == 1 then
        inst.AnimState:Show("spine_head")
    else
        inst.AnimState:Hide("spine_head")
    end
end

local function OnAttacked(inst, data)
    inst.hits = inst.hits+ 1           

    if inst.hits > 2 then                
        if math.random()*inst.hits >= 2 then
            local x, y, z= inst.Transform:GetWorldPosition()
            inst.components.lootdropper:SpawnLootPrefab("iron", Vector3(x,y,z))
            inst.hits = 0

            if math.random() < 0.6 then
                inst.BreakApart(inst)                                                                        
                inst:Remove()
            end    
        end
    end

    inst.AnimState:PlayAnimation("merge")
    inst.AnimState:PushAnimation("idle",true)

    local fx = SpawnPrefab("sparks_green_fx")
    local x, y, z= inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x,y+1,z)
end

local function GetStatus(inst)

end

local function OnSave(inst,data)
    local refs = {}

    if inst.hits then
        data.hits = inst.hits
    end

    data.head = inst.head
    data.spine = inst.spine
    data.arms = inst.arms
    data.legs = inst.legs
end

local function OnLoad(inst,data)
    if data then
        if data.hits then
            inst.hits = data.hits
        end

        inst.head = data.head
        inst.spine = data.spine
        inst.arms = data.arms
        inst.legs = data.legs

        inst:RefreshArt()
    end
end

local function OnLoadPostPass(inst,data)
    if inst.spawned then
        if inst.spawntask then
            inst.spawntask:Cancel()
            inst.spawntask = nil
        end
    end
end

local function commonfn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("metal_spider.tex")

    inst:AddTag("lightningrod")
    inst:AddTag("laser_immune")
    inst:AddTag("ancient_robot")
    inst:AddTag("mech")
    inst:AddTag("monster")
    inst:AddTag("ancient_robots_assembly")

    inst.AnimState:SetBank("metal_hulk_merge")
    inst.AnimState:SetBuild("metal_hulk_merge")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Transform:SetFourFaced()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.collisionradius = 2
    MakeObstaclePhysics(inst, inst.collisionradius)

    inst:AddComponent("timer")
     
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(
        function(inst, worker, workleft)
            OnAttacked(inst, {attacker=worker})
            inst.components.workable:SetWorkLeft(1)
            inst:PushEvent("attacked")
        end)
    inst.components.workable.undestroyable = true

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    
    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")

    inst:AddComponent("locomotor")

    inst.lightningpriority = 1
    inst:ListenForEvent("lightningstrike", OnLightning)
    inst:ListenForEvent("merge", OnMerge)

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0, 0)
    inst.Light:Enable(false)
    
    inst.UPDATETIME = UPDATETIME
    inst.hits = 0

    inst.head = 0
    inst.spine = 0
    inst.arms = 0
    inst.legs = 0
    inst.RefreshArt = RefreshArt
    inst.BreakApart = BreakApart

    RefreshArt(inst)
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    
    inst:ListenForEvent("beginaporkalypse", OnLightning, TheWorld)

    return inst
end

return Prefab( "ancient_robots_assembly", commonfn, assets, prefabs)
       