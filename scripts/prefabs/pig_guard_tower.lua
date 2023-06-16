require "prefabutil"
require "recipes"

local assets =
{

    Asset("ANIM", "anim/pig_shop.zip"),
    
    Asset("ANIM", "anim/flag_post_duster_build.zip"),
    Asset("ANIM", "anim/flag_post_perdy_build.zip"),
    Asset("ANIM", "anim/flag_post_royal_build.zip"),
    Asset("ANIM", "anim/flag_post_wilson_build.zip"), 
    Asset("ANIM", "anim/pig_tower_build.zip"),
    Asset("SOUND", "sound/pig.fsb"),
    Asset("MINIMAP_IMAGE", "pig_guard_tower"),    
    Asset("MINIMAP_IMAGE", "pig_palace"),        
    Asset("ANIM", "anim/pig_tower_royal_build.zip"),
    Asset("INV_IMAGE", "pighouse_city"),       

}

local prefabs = 
{
    "pigman_royalguard",
    "pigman_royalguard_2",
}

local function LightsOn(inst)
    if not inst:HasTag("burnt") then
        inst.Light:Enable(true)
        inst.AnimState:PlayAnimation("lit", true)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
        inst.lightson = true
    end
end

local function LightsOff(inst)
    if not inst:HasTag("burnt") then
        inst.Light:Enable(false)
        inst.AnimState:PlayAnimation("idle", true)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
        inst.lightson = false
    end
end

local function onfar(inst) 
    if not inst:HasTag("burnt") then
        if inst.components.spawner and inst.components.spawner:IsOccupied() then
            LightsOn(inst)
        end
    end
end

local function getstatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        if inst.lightson then
            return "FULL"
        else
            return "LIGHTSOUT"
        end
    end
end

local function onnear(inst) 
    if not inst:HasTag("burnt") then
        if inst.components.spawner and inst.components.spawner:IsOccupied() then
            LightsOff(inst)
        end
    end
end

local function onwere(child)
    if child.parent and not child.parent:HasTag("burnt") then
        child.parent.SoundEmitter:KillSound("pigsound")
        child.parent.SoundEmitter:PlaySound("dontstarve/pig/werepig_in_hut", "pigsound")
    end
end

local function onnormal(child)
    if child.parent and not child.parent:HasTag("burnt") then
        child.parent.SoundEmitter:KillSound("pigsound")
        child.parent.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/pig_in_house_LP", "pigsound")
    end
end

local function onoccupied(inst, child)
    if not inst:HasTag("burnt") then
    	inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/pig_in_house_LP", "pigsound")
        -- inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
    	
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
    	--inst.doortask = inst:DoTaskInTime(1, function() if not inst.components.playerprox:IsPlayerClose() then LightsOn(inst) end end)
        inst.doortask = inst:DoTaskInTime(1, function() LightsOn(inst) end)
    	if child then
    	    inst:ListenForEvent("transformwere", onwere, child)
    	    inst:ListenForEvent("transformnormal", onnormal, child)
    	end
    end
end

local function onvacate(inst, child)
    if not inst:HasTag("burnt") then
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        -- inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
        inst.SoundEmitter:KillSound("pigsound")
    	
    	if child then
    	    inst:RemoveEventCallback("transformwere", onwere, child)
    	    inst:RemoveEventCallback("transformnormal", onnormal, child)
            if child.components.werebeast then
    		    child.components.werebeast:ResetTriggers()
    		end
    		if child.components.health then
    		    child.components.health:SetPercent(1)
    		end
    	end    
    end
end
        
local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    inst.reconstruction_project_spawn_state = {
        bank = "pig_house",
        build = "pig_house",
        anim = "unbuilt",
    }

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
	if inst.components.spawner then inst.components.spawner:ReleaseChild() end

	SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function ongusthammerfn(inst)
    onhammered(inst, nil)
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
    	inst.AnimState:PlayAnimation("hit")
    	inst.AnimState:PushAnimation("idle")
    end
end

local function OnDay(inst)
    --print(inst, "OnDay")
    if not inst:HasTag("burnt") then
        if inst.components.spawner:IsOccupied() then
            LightsOff(inst)
            if inst.doortask then
                inst.doortask:Cancel()
                inst.doortask = nil
            end
            inst.doortask = inst:DoTaskInTime(1 + math.random()*2, function() inst.components.spawner:ReleaseChild() end)
        end
    end
end

local function citypossessionfn(inst)    
    if inst.components.citypossession then    
        if inst:HasTag("palacetower") then
            inst.AnimState:AddOverrideBuild("flag_post_royal_build")
            local spawned = {"pigman_royalguard_2"}
            inst.components.spawner:Configure( spawned[math.random(1,#spawned)], TUNING.GUARDTOWER_CITY_RESPAWNTIME,1)              
        elseif inst.components.citypossession.cityID == 2 then
            inst.AnimState:AddOverrideBuild("flag_post_perdy_build")
            local spawned = {"pigman_royalguard_2"}
            inst.components.spawner:Configure( spawned[math.random(1,#spawned)], TUNING.GUARDTOWER_CITY_RESPAWNTIME,1)            
        elseif inst.components.citypossession.cityID == 1 then
            inst.AnimState:AddOverrideBuild("flag_post_duster_build")
            local spawned = {"pigman_royalguard"}
            inst.components.spawner:Configure( spawned[math.random(1,#spawned)], TUNING.GUARDTOWER_CITY_RESPAWNTIME,1)            
        end    
    else
        inst.AnimState:AddOverrideBuild("flag_post_wilson_build")
        local spawned = {"pigman_royalguard"}
        inst.components.spawner:Configure( spawned[math.random(1,#spawned)], TUNING.GUARDTOWER_CITY_RESPAWNTIME,1)         
    end
end

local function reconstructed(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
    citypossessionfn(inst)    
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
	inst.AnimState:PushAnimation("idle")
    citypossessionfn( inst )
end

local function onsave(inst, data)

end

local function onload(inst, data)

end

local function callguards(inst,threat)
    print("CALLING GUARD AT TOWER")
    if inst.components.spawner then
        if inst.components.spawner:IsOccupied() then
            print("RELEASING")
            inst.components.spawner:ReleaseChild()
        end
        if inst.components.spawner.child then
            local pig = inst.components.spawner.child            
            if pig.components.combat.target == nil then
                print("ALERTING PIG GUARD")
                pig:DoTaskInTime(math.random()*1,function()                 
                    pig:PushEvent("atacked", {attacker = threat, damage = 0, weapon = nil})
                end)
            end
        end
    end
end

local function makeobstacle(inst)

    local ground = GetWorld()
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        --print("    at: ", pt)
        ground.Pathfinder:AddWall(pt.x, pt.y, pt.z-1)
        ground.Pathfinder:AddWall(pt.x, pt.y, pt.z)
        ground.Pathfinder:AddWall(pt.x, pt.y, pt.z+1)
        
        ground.Pathfinder:AddWall(pt.x-1, pt.y, pt.z-1)
        ground.Pathfinder:AddWall(pt.x-1, pt.y, pt.z)
        ground.Pathfinder:AddWall(pt.x-1, pt.y, pt.z+1)

        ground.Pathfinder:AddWall(pt.x+1, pt.y, pt.z-1)
        ground.Pathfinder:AddWall(pt.x+1, pt.y, pt.z)
        ground.Pathfinder:AddWall(pt.x+1, pt.y, pt.z+1)
    end
end

local function clearobstacle(inst)

    local ground = GetWorld()
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z-1)
        ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z)
        ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z+1)
        
        ground.Pathfinder:RemoveWall(pt.x-1, pt.y, pt.z-1)
        ground.Pathfinder:RemoveWall(pt.x-1, pt.y, pt.z)
        ground.Pathfinder:RemoveWall(pt.x-1, pt.y, pt.z+1)

        ground.Pathfinder:RemoveWall(pt.x+1, pt.y, pt.z-1)
        ground.Pathfinder:RemoveWall(pt.x+1, pt.y, pt.z)
        ground.Pathfinder:RemoveWall(pt.x+1, pt.y, pt.z+1)        
    end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local light = inst.entity:AddLight()
    inst.entity:AddSoundEmitter()

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("pig_guard_tower.tex")

    light:SetFalloff(1)
    light:SetIntensity(.5)
    light:SetRadius(1)
    light:Enable(false)
    light:SetColour(180/255, 195/255, 50/255)
    
    MakeObstaclePhysics(inst, 1)

    anim:SetBank("pig_shop")
    anim:SetBuild("pig_tower_build")
    anim:PlayAnimation("idle", true)
    anim:Hide("YOTP")

    inst:AddTag("guard_tower")
    inst:AddTag("structure")
    inst:AddTag("city_hammerable")
    
    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
	

    inst.onvacate = onvacate

	inst:AddComponent( "spawner" )
    inst.components.spawner.onoccupied = onoccupied
    inst.components.spawner.onvacate = onvacate
    inst:ListenForEvent( "daytime", function() OnDay(inst) end, GetWorld()) 

    inst.citypossessionfn = citypossessionfn 
    inst.OnLoadPostPass = citypossessionfn

    inst:AddComponent("inspectable")
    
    inst.components.inspectable.getstatus = getstatus
	
	MakeSnowCovered(inst, .01)

    inst:AddComponent("fixable")
    inst.components.fixable:AddRecinstructionStageData("rubble","pig_shop","pig_tower_build")
    inst.components.fixable:AddRecinstructionStageData("unbuilt","pig_shop","pig_tower_build") 

    inst.OnSave = onsave 
    inst.OnLoad = onload
    inst.callguards = callguards
    inst.reconstructed = reconstructed

	inst:ListenForEvent( "onbuilt", onbuilt)
    inst:DoTaskInTime(math.random(), function() 
        --print(inst, "spawn check day")
        if TheWorld.state.isday then 
            OnDay(inst)
        end 
    end)

    inst:AddComponent("gridnudger")

    inst.setobstical = makeobstacle
    inst:ListenForEvent("onremove", function(inst) clearobstacle(inst) end)

    inst.OnEntityWake = function (_inst)
        -- if TheWorld.components.aporkalypse and TheWorld.components.aporkalypse:GetFiestaActive() then
            -- inst.AnimState:Show("YOTP")
        -- else
            inst.AnimState:Hide("YOTP")
        -- end
    end

    return inst
end

local function palacefn(Sim)
    local inst = fn(Sim)

    inst:AddTag("palacetower")
    inst.AnimState:SetBuild("pig_tower_royal_build")
    inst:SetPrefabNameOverride("pig_guard_tower")
    inst.MiniMapEntity:SetIcon("pig_palace.tex" )
    return inst
end

local function placetestfn(inst)
    inst.AnimState:Hide("YOTP")
    inst.AnimState:Hide("SNOW")

    --local pt = inst:GetPosition()
    --local tile = GetWorld().Map:GetTileAtPoint(pt.x,pt.y,pt.z)
    --if tile == WORLD_TILES.INTERIOR then
    --    return false
    --end
    
    return true
end

return Prefab( "pig_guard_tower", fn, assets, prefabs),
       Prefab( "pig_guard_tower_palace", palacefn, assets, prefabs),
	   MakePlacer("pig_guard_tower_placer", "pig_shop", "pig_tower_build", "idle", false, false, true, nil, nil, nil, placetestfn)
