local UPDATETIME = 5

local assets=
{
	Asset("ANIM", "anim/metal_spider.zip"),
    Asset("ANIM", "anim/metal_claw.zip"),
    Asset("ANIM", "anim/metal_leg.zip"),
    Asset("ANIM", "anim/metal_head.zip"),
    Asset("MINIMAP_IMAGE", "metal_spider"),
    Asset("MINIMAP_IMAGE", "metal_leg"),
    Asset("MINIMAP_IMAGE", "metal_head"),
    Asset("MINIMAP_IMAGE", "metal_claw"),    
}

local prefabs =
{
    "iron",
    "sparks_fx",
    "sparks_green_fx",
    "laser_ring",
}

SetSharedLootTable( 'anchientrobot',
{
    {'iron',  1.00},
    {'iron',  1.00},
    {'iron',  1.00},
    {'iron',  0.33},
    {'iron',  0.33},
    {'iron',  0.33},
    {'gears', 1.00},
    {'gears', 0.33},
})

local function RemoveMoss(inst)
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
end

local function Retarget(inst)
    return FindEntity(inst, TUNING.ROBOT_TARGET_DIST, function(guy)
            return not guy:HasTag("ancient_robot") and
					inst.components.combat:CanTarget(guy) and
					not guy:HasTag("wall")
        end)
end

local function KeepTarget(inst, target)
    return true
end

local function PeriodicUpdate(inst)
    -- if TheWorld.components.aporkalypse and TheWorld.components.aporkalypse:IsActive() then
	-- Adapted to Jerry's rewritten Aporkalypse system
	
	-- Does this work at all right now?
    if TheWorld.components.aporkalypse and TheWorld.state.isaporkalypse then
        return
    end

    if inst.lifetime and inst.lifetime > 0 then
		-- print("DS - Robot - Timer counting down, from", inst.lifetime)
        inst.lifetime = inst.lifetime - UPDATETIME
		-- print("DS - Robot - Subtracted", UPDATETIME, "now", inst.lifetime)
    else       
		-- print("DS - Robot - ", inst, "wants to deactivate")
        inst.wantstodeactivate = true
        inst.updatetask:Cancel()
        inst.updatetask = nil
    end
end

local function OnLightning(inst, data)
	-- print("DS - Robot - Lightining event triggered, seems like a general wake-up one")
    inst.lifetime = 90
	-- print("DS - Robot - Lifetime set to", inst.lifetime)
    if inst:HasTag("dormant") then
		-- print("DS - Robot - Is dormant, wake it up")
        inst.wantstodeactivate = nil
        inst:RemoveTag("dormant")
        inst:PushEvent("shock")
        if not inst.updatetask then
			-- print("DS - Robot - Start update task at speed", UPDATETIME)
            inst.updatetask = inst:DoPeriodicTask(UPDATETIME, PeriodicUpdate)
        end
	else
		-- print("DS - Robot - Robot was not dormant, just reset its life, but don't wake it up")
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)

    local fx = SpawnPrefab("sparks_green_fx")
    local x, y, z= inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x,y+1,z)
end

local function GetStatus(inst)

end

local function OnSave(inst,data)
    local refs = {
        hits = inst.hits,
        dormant = inst:HasTag("dormant"),
        mossy = inst:HasTag("mossy"),
        lifetime = inst.lifetime,
        spawned = inst.spawned,
    }
  
    if refs and #refs >0 then
        return refs
    end
end

local function OnLoad(inst,data)
    if data then
        if data.hits then
            inst.hits = data.hits
        end
        if data.dormant then
            inst:AddTag("dormant")
        end
        if data.mossy then
            inst:AddTag("mossy")
        end
        if data.spawned then
            inst.spawned = true
        end
        if data.lifetime then
            inst.lifetime = data.lifetime
            inst.updatetask = inst:DoPeriodicTask(UPDATETIME, PeriodicUpdate)
        end
    end
    if inst:HasTag("dormant") then
        inst.sg:GoToState("idle_dormant")
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

local function MergeAction(act)
    if act.target then
        local target = act.target
        if not target:HasTag("ancient_robots_assembly") then
            local hulk = SpawnPrefab("ancient_robots_assembly")
            local x,y,z = act.doer.Transform:GetWorldPosition()
            hulk.Transform:SetPosition(x,y,z)
            target:MergeFunction(hulk)
            target = hulk
            act.target:Remove()
        end
        act.doer:MergeFunction(target)
        target:PushEvent("merge")
        act.doer:Remove()
    end
end

local function commonfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.MiniMapEntity:SetIcon("metal_spider.png")

    inst.collisionradius = 1.2
    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst:AddTag("lightningrod")
    inst:AddTag("laser_immune")
    inst:AddTag("ancient_robot")
    inst:AddTag("mech")
    inst:AddTag("monster")

    inst.AnimState:SetBank("metal_spider")
    inst.AnimState:SetBuild("metal_spider")
    inst.AnimState:PlayAnimation("idle", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("timer")
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body01"
    inst.components.combat:SetDefaultDamage(TUNING.ROBOT_RIBS_DAMAGE)
    inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

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

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('anchientrobot')
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    
    inst:AddComponent("knownlocations")
    
    inst.lightningpriority = 1
    inst:ListenForEvent("lightningstrike", OnLightning)

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0, 0)
    inst.Light:Enable(false)
    
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 2
    
    inst:SetBrain(require("brains/ancientrobotbrain"))
    inst:SetStateGraph("SGAncientRobot")

    inst.PeriodicUpdate = PeriodicUpdate
    inst.UPDATETIME = UPDATETIME
    inst.hits = 0

    inst.SpecialAction = MergeAction
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.RemoveMoss = RemoveMoss

    inst.spawntask = inst:DoTaskInTime(0, function()
        if not inst.spawned then
            inst:AddTag("mossy")
            inst:AddTag("dormant")
            inst.sg:GoToState("idle_dormant")
            inst.spawned = true
        end            
    end)

    -- inst:ListenForEvent("beginaporkalypse", function(world) OnLightning(inst) end, TheWorld)
    inst:ListenForEvent("ms_startaporkalypse", function(world) OnLightning(inst) end, TheWorld)

    return inst
end

local function ribsfn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize( 6, inst.collisionradius )

    inst.collisionradius = 2

    inst:AddTag("beam_attack")
    inst:AddTag("robot_ribs")

    inst.AnimState:SetBank("metal_spider")
    inst.AnimState:SetBuild("metal_spider")
    inst.AnimState:PlayAnimation("idle", true)

	if not TheWorld.ismastersim then
		return inst
	end

    inst.MergeFunction = function(inst,hulk)
        hulk.spine = 1
    end

    return inst
end

local function armfn()
    local inst = commonfn()

    inst.MiniMapEntity:SetIcon( "metal_claw.tex" )

    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst.collisionradius = 1.2

    inst.AnimState:SetBank("metal_claw")
    inst.AnimState:SetBuild("metal_claw")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("beam_attack")
    inst:AddTag("robot_arm")
    inst:AddTag("IsSixFaced")
    inst:AddTag("noeightfaced")
    
    inst.Transform:SetSixFaced()

	if not TheWorld.ismastersim then
		return inst
	end
    
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    inst.MergeFunction = function(inst,hulk)
        hulk.arms = hulk.arms + 1
    end    

    return inst
end


local function legfn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize( 4, 2 )

    inst.MiniMapEntity:SetIcon( "metal_leg.tex" )

    MakeCharacterPhysics(inst, 99999, inst.collisionradius)
 
    inst.collisionradius = 1.2

    inst.Transform:SetSixFaced()
    
    inst:AddTag("jump_attack")
    inst:AddTag("lightning_taunt")
    inst:AddTag("robot_leg")
    inst:AddTag("IsSixFaced")
    inst:AddTag("noeightfaced")

    inst.AnimState:SetBank("metal_leg")
    inst.AnimState:SetBuild("metal_leg")
    inst.AnimState:PlayAnimation("idle", true)

	if not TheWorld.ismastersim then
		return inst
	end

    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 4

    inst.MergeFunction = function(inst,hulk)
        hulk.legs = hulk.legs + 1
    end 

    inst.components.combat:SetDefaultDamage(TUNING.ROBOT_LEG_DAMAGE)

    return inst
end

local function headfn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize( 4, 2 )

    inst.MiniMapEntity:SetIcon( "metal_head.tex" )

    MakeCharacterPhysics(inst, 99999, inst.collisionradius)

    inst.collisionradius = 2

    inst.Transform:SetSixFaced()

    inst:AddTag("jump_attack")
    inst:AddTag("robot_head")
    inst:AddTag("IsSixFaced")
    inst:AddTag("noeightfaced")
    
	if not TheWorld.ismastersim then
		return inst
	end

    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 4

    inst.AnimState:SetBank("metal_head")
    inst.AnimState:SetBuild("metal_head")
    inst.AnimState:PlayAnimation("idle", true)

    inst.components.combat:SetDefaultDamage(TUNING.ROBOT_LEG_DAMAGE)

    inst.MergeFunction = function(inst,hulk)
        hulk.head = 1
    end    

    return inst
end

return Prefab("ancient_robot_ribs", ribsfn, assets, prefabs),
       Prefab("ancient_robot_claw", armfn, assets, prefabs),
       Prefab("ancient_robot_leg", legfn, assets, prefabs),
       Prefab("ancient_robot_head", headfn, assets, prefabs)