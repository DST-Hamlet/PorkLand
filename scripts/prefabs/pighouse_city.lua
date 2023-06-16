require "prefabutil"
require "recipes"

local assets =
{
	Asset("ANIM", "anim/pig_townhouse1.zip"),
    Asset("ANIM", "anim/pig_townhouse5.zip"),
    Asset("ANIM", "anim/pig_townhouse6.zip"),    

    Asset("ANIM", "anim/pig_townhouse1_pink_build.zip"),
    Asset("ANIM", "anim/pig_townhouse1_green_build.zip"),

    Asset("ANIM", "anim/pig_townhouse1_brown_build.zip"),
    Asset("ANIM", "anim/pig_townhouse1_white_build.zip"),

    Asset("ANIM", "anim/pig_townhouse5_beige_build.zip"),
    Asset("ANIM", "anim/pig_townhouse6_red_build.zip"),
    
    Asset("ANIM", "anim/pig_farmhouse_build.zip"),

    Asset("SOUND", "sound/pig.fsb"), 
}

local prefabs = 
{
    "pigman_collector",
    "pigman_banker",
    "pigman_beautician",
    "pigman_florist",
    "pigman_erudite",
    "pigman_hunter",
    "pigman_hatmaker",
    "pigman_usher",
    "pigman_mechanic",
    "pigman_storeowner",
    "pigman_professor",
}

local city_1_citizens = {
    "pigman_banker",
    "pigman_beautician",
    "pigman_florist",
    "pigman_usher",
    "pigman_mechanic",
    "pigman_storeowner",
    "pigman_professor",
}

local city_2_citizens = {
    "pigman_collector",
    "pigman_erudite",
    "pigman_hatmaker",
    "pigman_hunter",
}

local city_citizens = {
    city_1_citizens,
    city_2_citizens,
}

local spawned_farm = {
    "pigman_farmer"
}

local spawned_mine = {
    "pigman_miner"
}

local SCALEBUILD ={}
SCALEBUILD["pig_townhouse1_pink_build"] = true
SCALEBUILD["pig_townhouse1_green_build"] = true
SCALEBUILD["pig_townhouse1_white_build"] = true
SCALEBUILD["pig_townhouse1_brown_build"] = true

local SETBANK ={}
SETBANK["pig_townhouse1_pink_build"] = "pig_townhouse"
SETBANK["pig_townhouse1_green_build"] = "pig_townhouse"
SETBANK["pig_townhouse1_white_build"] = "pig_townhouse"
SETBANK["pig_townhouse1_brown_build"] = "pig_townhouse"
SETBANK["pig_townhouse5_beige_build"] = "pig_townhouse5"
SETBANK["pig_townhouse6_red_build"] = "pig_townhouse6"

local house_builds = {
   "pig_townhouse1_pink_build",
   "pig_townhouse1_green_build",
   "pig_townhouse1_white_build",
   "pig_townhouse1_brown_build",
   "pig_townhouse5_beige_build",
   "pig_townhouse6_red_build",   
}

local function setScale(inst,build)
    if SCALEBUILD[build] then
        inst.AnimState:SetScale(0.75,0.75,0.75)
    else
        inst.AnimState:SetScale(1,1,1)
    end
end

local function getScale(inst,build)
    if SCALEBUILD[build] then
        return {0.75,0.75,0.75}
    else
        return {1,1,1}
    end
end

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
          --  if child.components.citypossession
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

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
	if inst.components.spawner and inst.components.spawner:IsOccupied() then inst.components.spawner:ReleaseChild() end
	if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end
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
        if inst.lightson then
            inst.AnimState:PushAnimation("lit")
        else
            inst.AnimState:PushAnimation("idle")
        end
    end
end

local function paytax(inst)
    -- if inst.components.spawner.child and GetPlayer():HasTag("mayor") and inst:HasTag("paytax")  then
	
	local iMayorFound = 0
	for i, v in ipairs(AllPlayers) do
		if v:HasTag("mayor") then
			iMayorFound = true
			return
		end
	end
	
    if inst.components.spawner.child and iMayorFound and inst:HasTag("paytax")  then
        inst:DoTaskInTime(4, function()
            if inst.components.spawner.child then
                inst.components.spawner.child:AddTag("paytax")        
            end
            inst:RemoveTag("paytax")
        end)       
    end
end
local function checktax(inst)

    -- a player build pighouse doesn't have a city possesion component.. so that's how I'm checking for tax paying houses right now
    -- if not inst.components.citypossession and inst.components.spawner.child and GetClock().numcycles%10 == 0 and inst.lasttaxday ~= GetClock().numcycles then        
    if not inst.components.citypossession and inst.components.spawner.child and TheWorld.state.cycles%10 == 0 and inst.lasttaxday ~= TheWorld.state.cycles then        
        -- inst.lasttaxday = GetClock().numcycles        
        inst.lasttaxday = TheWorld.state.cycles        
        inst:AddTag("paytax")
        paytax(inst)
    end
end

local function OnDay(inst)
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

    checktax(inst)    
end

local function UpdateTime(inst)    
	local phase = TheWorld.state.phase
    if phase == "day" then
		OnDay(inst)
	end
end

local function setcolor(inst,num)
    if not num then
        num = math.random()
    end
    local color = 0.5 + num * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)
    return num
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end
    data.build = inst.build
    data.animset = inst.animset
    data.colornum = inst.colornum
    data.paytax = inst:HasTag("paytax")
    data.lasttaxday = inst.lasttaxday
    if inst.components.spawner.childname then
        data.childname = inst.components.spawner.childname
    end
end

local function onload(inst, data)
    if data then

        if data.build then
            inst.build = data.build
            inst.AnimState:SetBuild(inst.build) 
            setScale(inst,inst.build)
        end

        if data.animset then
            inst.animset = data.animset
            inst.AnimState:SetBank( inst.animset )
        end    
        if data.colornum then
            inst.colornum = setcolor(inst, data.colornum)
        end
        if data.paytax then
            inst:AddTag("paytax")
        end
        if data.childname then
            inst.components.spawner:Configure( data.childname, TUNING.PIGHOUSE_CITY_RESPAWNTIME)
        end
        if data.burnt then
            inst.components.burnable.onburnt(inst)
        end
        if data.lasttaxday then
            inst.lasttaxday = data.lasttaxday
        end
    end
end

local function ConfigureSpawner(inst, selected_citizens)
if inst.components.spawner == nil then return end
    inst.spawnlist = selected_citizens
    inst.components.spawner:Configure(selected_citizens[math.random(1,#selected_citizens)], TUNING.PIGHOUSE_CITY_RESPAWNTIME, 1)
    
    -- inst:ListenForEvent("daytime", function() OnDay(inst) end, GetWorld())
	inst:WatchWorldState("isday", OnDay)
    --inst:WatchWorldState("phase", UpdateTime)
end

local function citypossessionfn( inst )
    local selected_citizens = {}
    if inst.components.citypossession and inst.components.citypossession.cityID then
        for i=1, inst.components.citypossession.cityID do
            selected_citizens = JoinArrays(selected_citizens, city_citizens[i])
        end
    else
        for i=1, 2 do
            selected_citizens = JoinArrays(selected_citizens, city_citizens[i])
        end
    end

    ConfigureSpawner(inst, selected_citizens)
end

local function reconstructed(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
    citypossessionfn(inst)
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/wood_2")
    inst.AnimState:PushAnimation("idle")
    citypossessionfn( inst )
end

local function makeobstacle(inst)

    -- local ground = GetWorld()
    local ground = TheWorld
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
    -- local ground = GetWorld()
    local ground = TheWorld
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

local function makefn(animset, setbuild, spawnList, minimapicon)
    local function fn(Sim)
    	local inst = CreateEntity()
		
    	inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
		
    	local anim = inst.entity:AddAnimState()
        local light = inst.entity:AddLight()

    	local minimap = inst.entity:AddMiniMapEntity()
    	minimap:SetIcon(minimapicon or "pig_townhouse.tex")
        --{anim="level1", sound="dontstarve/common/campfire", radius=2, intensity=.75, falloff=.33, colour = {197/255,197/255,170/255}},
        light:SetFalloff(1)
        light:SetIntensity(.5)
        light:SetRadius(1)
        light:Enable(false)
        light:SetColour(180/255, 195/255, 50/255)
        
        MakeObstaclePhysics(inst, 1)    

        local build = house_builds[math.random(1,#house_builds)]        
        if setbuild then
            build = setbuild
        end

        inst.build = build
        anim:SetBuild(build) 
        
        inst.animset = nil

        if animset then
            anim:SetBank(animset)
            inst.animset = animset
        else            
            anim:SetBank(SETBANK[build])            
            inst.animset = SETBANK[build]
        end

        setScale(inst, build)

        anim:PlayAnimation("idle", true)        

        inst.colornum = setcolor(inst)
        local color = 0.5 + math.random() * 0.5
        anim:SetMultColour(color, color, color, 1)

        anim:Hide("YOTP")

        inst:AddTag("bandit_cover")
        inst:AddTag("structure")
        inst:AddTag("city_hammerable")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

        inst:AddComponent("lootdropper")
        
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
    	inst.components.workable:SetOnFinishCallback(onhammered)
    	inst.components.workable:SetOnWorkCallback(onhit)
    	
        inst:AddComponent("spawner")
		inst.components.spawner.onoccupied = onoccupied
        inst.components.spawner.onvacate = onvacate										   
        if spawnList then
            ConfigureSpawner(inst, spawnList)           
        else
            inst.citypossessionfn = citypossessionfn 
            inst.OnLoadPostPass = citypossessionfn
        end

        -- inst:ListenForEvent("daytime", function() OnDay(inst) end, GetWorld())
		inst:WatchWorldState("isday", OnDay)

        inst:AddComponent("inspectable")
        
        inst.components.inspectable.getstatus = getstatus
    	
    	MakeSnowCovered(inst, .01)

        MakeLargeBurnable(inst, nil, nil, true)
        MakeLargePropagator(inst)
        
        inst:AddComponent("fixable")        
        inst.components.fixable:AddRecinstructionStageData("rubble","pig_townhouse",build,nil,getScale(inst,build))
        inst.components.fixable:AddRecinstructionStageData("unbuilt","pig_townhouse",build,nil,getScale(inst,build)) 

        inst.reconstructed = reconstructed

        inst:ListenForEvent("burntup", function(inst)
            inst.components.fixable:AddRecinstructionStageData("burnt","pig_townhouse",build,1,getScale(inst,build))
            if inst.doortask then
                inst.doortask:Cancel()
                inst.doortask = nil
            end
            inst:Remove()
        end)

        inst:ListenForEvent("onignite", function(inst)
            if inst.components.spawner and inst.components.spawner:IsOccupied() then
                inst.components.spawner:ReleaseChild()
            end
        end)

        inst.OnSave = onsave 
        inst.OnLoad = onload

    	inst:ListenForEvent("onbuilt", onbuilt)
        inst:DoTaskInTime(math.random(), function()
            if TheWorld.state.isday then 
                OnDay(inst)
            end 
        end)


        --inst:AddComponent("gridnudger")

        inst.setobstical = makeobstacle
        inst:ListenForEvent("onremove", function(inst) clearobstacle(inst) end)


        inst.OnEntityWake = function (_inst)
		-- DS - Fiesta not yet implemented on Jerry's side
        if TheWorld.components.aporkalypse and TheWorld.components.aporkalypse:GetFiestaActive() then
            inst.AnimState:Show("YOTP")
        else
            inst.AnimState:Hide("YOTP")
        end
    end
        return inst
    end
    return fn
end


local function placetestfn(inst)
    inst.AnimState:Hide("YOTP")
    inst.AnimState:Hide("SNOW")

    -- local pt = inst:GetPosition()
    -- local tile = GetWorld().Map:GetTileAtPoint(pt.x,pt.y,pt.z)
	
    -- local tile = GetWorld().Map:GetTileAtPoint(pt.x,pt.y,pt.z)
    -- if tile == WORLD_TILES.INTERIOR then
        -- return false
    -- end

    return true
end

local function house(name, anim, build, spawnList, minimapicon)
    return Prefab(name, makefn(anim, build, spawnList, minimapicon), assets, prefabs)
end

return house("pighouse_city",nil,nil),
       house("pighouse_farm","pig_shop","pig_farmhouse_build", spawned_farm, "pig_farmhouse.tex"),
       house("pighouse_mine","pig_shop","pig_farmhouse_build", spawned_mine, "pig_farmhouse.tex"),

       MakePlacer("pighouse_city_placer", "pig_shop", "pig_townhouse1_green_build", "idle", false, false, true, 0.75, nil, nil, placetestfn)

	  -- MakePlacer("pighouse_placer", "pig_house", "pig_house", "idle")  
