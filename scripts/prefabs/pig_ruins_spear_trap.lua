require "prefabutil"
require "stategraphs/SGspear_trap"

local assets =
{
	Asset("ANIM", "anim/spear_trap.zip"), 
    Asset("MINIMAP_IMAGE", "spear_trap"),
}

local prefabs =
{

}    

local AREA = 1.3

local function inflictdamage(inst)
    local pt = Point(inst.Transform:GetWorldPosition())    
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, AREA, nil, {"spear_trap","INTERIOR_LIMBO"})
    for i, ent in ipairs(ents)do
        if ent.components.health then
            inst.components.combat:DoAttack(ent)
        elseif ent.components.workable and ent.components.workable.workleft > 0 then           
            ent.components.workable:Destroy(inst)                    
        end
    end
end

local function oncollide(inst, other)
    if other and other.components.health and inst.sg:HasStateTag("damage") then
        inst.components.combat:DoAttack(other)
    end    
end

local function setextendeddata(inst, extended)
    if extended then
        inst:RemoveTag("NOCLICK")    
        inst.extended = true
        inst:AddTag("hostile")  
        inst:RemoveTag("fireimmune")
        if inst.components.burnable then
            inst.components.burnable.disabled = nil
        end
        inst.components.health.vulnerabletoheatdamage = true        
        inst.name = STRINGS.NAMES.PIG_RUINS_SPEAR_TRAP_TRIGGERED
        inst.Physics:SetActive(true)       
        if inst.MiniMapEntity then
            inst.MiniMapEntity:SetIcon("spear_trap.png")          
        end
    else
        inst:AddTag("NOCLICK")
        inst.extended = nil
        inst:RemoveTag("hostile")    
        inst:AddTag("fireimmune")
        if inst.components.burnable then
            inst.components.burnable.disabled = true    
        end
        inst.components.health.vulnerabletoheatdamage = false     
        inst.name = STRINGS.NAMES.PIG_RUINS_SPEAR_TRAP       
        inst.Physics:SetActive(false)         
        if inst.MiniMapEntity then
            inst.MiniMapEntity:SetIcon("")          
        end        
    end
end

local function onsave(inst, data)    
    if inst.extended then
        data.extended = true
    end

    --if inst:HasTag("timed") then
    --    data.timed = true
    --end
    if inst:HasTag("up_3") then
        data.up_3 = true        
    end
    if inst:HasTag("down_6") then
        data.down_6 = true        
    end    
    if inst:HasTag("delay_3") then
        data.delay_3 = true
    end    
    if inst:HasTag("delay_6") then
        data.delay_6 = true
    end    
    if inst:HasTag("delay_9") then
        data.delay_9 = true
    end    

end

local function onload(inst, data)
    if data then
        if data.extended then      
            inst.sg:GoToState("extended")
        end
       -- if data.timed then
       --     inst:AddTag("timed")
       -- end
        if data.up_3 then 
            inst:AddTag("up_3")     
        end
        if data.down_6 then
            inst:AddTag("down_6")
        end
        if data.delay_3 then
            inst:AddTag("delay_3")
        end    
        if data.delay_6 then
            inst:AddTag("delay_6")
        end    
        if data.delay_9 then
           inst:HasTag("delay_9")
        end   
    end
end

local function disarm(inst, doer)    
    local pt = Point(inst.Transform:GetWorldPosition())
    inst.components.lootdropper:SpawnLootPrefab("blowdart_pipe", pt)
    --doer.components.inventory:GiveItem( SpawnPrefab("blowdart_pipe"))
end

local function OnKilled(inst)
    inst:PushEvent("dead")

    local debris = SpawnPrefab("pig_ruins_spear_trap_broken")
    debris.AnimState:PlayAnimation("breaking")
    debris.AnimState:PushAnimation("broken",true)
    debris.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/speartrap_break")    
    if inst:HasTag("INTERIOR_LIMBO") then
        local interiorSpawner = GetWorld().components.interiorspawner
        local interior = interiorSpawner:getPropInterior(inst)
        interiorSpawner:injectprefab(debris,interior)
    end

    inst:Remove()
end

local function burnt(inst)
  --  inst:AddTag("burnt")
   -- inst.AnimState:PlayAnimation("burnt")
   -- inst.Physics:SetActive(false)
    local debris = SpawnPrefab("pig_ruins_spear_trap_broken")
    debris.AnimState:PlayAnimation("burnt")
    debris.Transform:SetPosition(inst.Transform:GetWorldPosition())    
    if inst:HasTag("INTERIOR_LIMBO") then
        local interiorSpawner = GetWorld().components.interiorspawner
        local interior = interiorSpawner:getPropInterior(inst)
        interiorSpawner:injectprefab(debris,interior)
    end

    inst:Remove()

end

local function OnHit(inst)
    inst:PushEvent("hit")
end

local function cycletrap(inst)
    if not inst:HasTag("burnt") and not inst:HasTag("dead") then

        if inst.sg:HasStateTag("extended") then
            inst:PushEvent("reset")
        elseif inst.sg:HasStateTag("retracted") then
            inst:PushEvent("triggertrap")
        end
    end
end


local function cycleup(inst)
    if not inst:HasTag("INTERIOR_LIMBO") and not inst:Hastag("burnt") and not inst:Hastag("dead") then
        local time = 1
        if inst:HasTag("up_3") then
            time = 3
        end    
        --print("SETTING DOWN",time)
        if inst.cycletask then        
            inst.cycletask:Cancel()
            inst.cycletask = nil
        end
    --    inst.cycletask = inst:DoTaskInTime(time, function() inst.cycledown(inst) end)        
    end
end

local function cycledown(inst)
    if not inst:HasTag("INTERIOR_LIMBO") and not inst:Hastag("burnt") and not inst:Hastag("dead") then
    
        local time = 3
        if inst:HasTag("down_6") then
            time = 6
        end
        --print("SETTING UP",time) 
        if inst.cycletask then   
            inst.cycletask:Cancel()
            inst.cycletask = nil        
        end
      --  inst.cycletask = inst:DoTaskInTime(time, function() inst.cycleup(inst) end)                
    end
end

local function startcycle(inst)
    local time = 6                
    local delay = 3
    if inst:HasTag("delay_6") then
        delay = 6
    elseif inst:HasTag("delay_9") then
        delay = 9
    end
    if inst.cycletask then
        inst.cycletask:Cancel()
        inst.cycletask = nil  
    end
    if inst.sg:HasStateTag("retracted") then
        inst.cycletask = inst:DoTaskInTime(delay, function() cycleup(inst) end)
    elseif inst.sg:HasStateTag("extended") then
        inst.cycletask = inst:DoTaskInTime(delay, function() cycledown(inst) end)
    end
end


local function returntointeriorscene(inst)
    inst.components.cycletimer:Resume()
end

local function removefrominteriorscene(inst)
    inst.components.cycletimer:Pause()
end

local function canbeattackedfn(inst)
    local canbeattacked = true

    if inst:HasTag("burnt") or inst:HasTag("dead") then
        canbeattacked = false
    end

    return canbeattacked
end

local function fn(Sim)

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
	inst.entity:AddNetwork()
    
    MakeObstaclePhysics(inst, .5)
    inst.Physics:SetActive(false)
    
    inst.setextendeddata = setextendeddata
    --inst.Physics:SetCollisionCallback(oncollide)   

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst.components.combat:SetDefaultDamage(TUNING.SPEAR_TRAP_DAMAGE)
    inst.components.combat.canbeattackedfn = canbeattackedfn
    inst.inflictdamage = inflictdamage

    inst:ListenForEvent("death", OnKilled)
    inst:ListenForEvent("triggertrap", function(inst, data)
        inst.triggertask = inst:DoTaskInTime(math.random()*0.25,function()
            inst:PushEvent("spring")
        end)
    end)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SPEAR_TRAP_HEALTH)

    inst.entity:AddSoundEmitter()    

    anim:SetBank("spear_trap")
    anim:SetBuild("spear_trap")
    anim:PlayAnimation("idle_retract")
    inst:AddTag("spear_trap")
    inst:AddTag("tree")
    inst:AddTag("structure")

    inst:AddComponent("inspectable")
    
    inst:AddComponent("shearable")
    inst.onshear = function(inst, shearer)
        OnKilled(inst)
    end
    inst.canshear = function (inst)
        return true
    end,

    inst:SetStateGraph("SGspear_trap")

    MakeSmallBurnable(inst)
    inst.components.burnable.disabled = true
    MakeSmallPropagator(inst)
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetOnBurntFn(burnt)
    -- inst.components.burnable:MakeDragonflyBait(1) 
    --inst.components.burnable:SetOnIgniteFn(tree_lit) 

    inst.cycleup = cycleup
    inst.cycledown = cycledown
    inst.returntointeriorscene = returntointeriorscene
    inst.removefrominteriorscene = removefrominteriorscene

    inst.OnLoad = onload
    inst.OnSave = onsave

    inst:AddComponent("cycletimer")
   
    inst:DoTaskInTime(0,function()
            local time1 = 1
            if inst:HasTag("up_3") then
                time1 = 3
            end  

            local time2 = 3
            if inst:HasTag("down_6") then
                time2 = 6
            end 
            inst.components.cycletimer:setup(time1,time2,cycletrap,cycletrap)
            if inst:HasTag("timed") then

                local initialdelay = 3                
                if inst:HasTag("delay_6") then
                    initialdelay = 6
                elseif inst:HasTag("delay_9") then
                    initialdelay = 9
                end             
                --print("starting spears")
                inst.components.cycletimer:start(initialdelay)
               -- startcycle(inst)
            end
        end)

    inst:AddComponent("hiddendanger")

    return inst
end

local function debrisfn(Sim)

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    anim:SetBank("spear_trap")
    anim:SetBuild("spear_trap")
    anim:PlayAnimation("broken")
    
    inst:AddComponent("inspectable")

    return inst
end

return  Prefab( "pig_ruins_spear_trap", fn, assets, prefabs),
        Prefab( "pig_ruins_spear_trap_broken", debrisfn, assets, prefabs)