local assets =
{
	Asset("ANIM", "anim/lamp_post2.zip"),
    Asset("ANIM", "anim/lamp_post2_city_build.zip"),    
    Asset("ANIM", "anim/lamp_post2_yotp_build.zip"),
    Asset("INV_IMAGE", "city_lamp"),
}

local INTENSITY = 0.6

local LAMP_DIST = 16
local LAMP_DIST_SQ = LAMP_DIST * LAMP_DIST

local function UpdateAudio(inst)
    -- local player = ThePlayer

    -- local instPosition = Vector3(inst.Transform:GetWorldPosition())
    -- local playerPosition = Vector3(player.Transform:GetWorldPosition())
    -- local lampIsNearby = (distsq(playerPosition, instPosition) < LAMP_DIST_SQ)

    -- if GetClock():IsDusk() and lampIsNearby and not inst.SoundEmitter:PlayingSound("onsound") then
    if TheWorld.state.isdusk and not inst.SoundEmitter:PlayingSound("onsound") then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/city_lamp/on_LP", "onsound")
    -- elseif not lampIsNearby and inst.SoundEmitter:PlayingSound("onsound") then
    elseif inst.SoundEmitter:PlayingSound("onsound") then
        inst.SoundEmitter:KillSound("onsound")
    end
end

local function GetStatus(inst)
    return not inst.lighton and "ON" or nil
end

local function fadein(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("on")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/city_lamp/fire_on")
    inst.AnimState:PushAnimation("idle", true)
    inst.Light:Enable(true)

	if inst:IsAsleep() then
		inst.Light:SetIntensity(INTENSITY)
	else
		inst.Light:SetIntensity(0)
		inst.components.fader:Fade(0, INTENSITY, 3+math.random()*2, function(v) inst.Light:SetIntensity(v) end)
	end
end

local function fadeout(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("off")    
    inst.AnimState:PushAnimation("idle", true)

	if inst:IsAsleep() then
		inst.Light:SetIntensity(0)
	else
		inst.components.fader:Fade(INTENSITY, 0, .75+math.random()*1, function(v) inst.Light:SetIntensity(v) end)
	end
end

local phasefunctions = 
{
    day = function(inst)
        if inst.lighton then
            inst:DoTaskInTime(math.random()*2, function() 
                fadeout(inst)
            end)            
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end

        inst.AnimState:Hide("FIRE")
        inst.AnimState:Hide("GLOW")        

        inst.lighton = false
    end,

    dusk = function(inst) 
        if not inst.lighton then
            inst:DoTaskInTime(math.random()*2, function() 
                fadein(inst)
            end)

        else            
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
        inst.AnimState:Show("FIRE")
        inst.AnimState:Show("GLOW")        
        inst.lighton = true
    end,

    night = function(inst) 
        if not inst.lighton then
            inst:DoTaskInTime(math.random()*2, function() 
                fadein(inst)
            end)

        else            
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
        inst.AnimState:Show("FIRE")
        inst.AnimState:Show("GLOW")        
        inst.lighton = true
    end,
}

local function UpdateTime(inst)    
	local phase = TheWorld.state.phase
    if inst.Light then
        phasefunctions[phase](inst)
    end
end

local function updatelight(inst)
    -- if GetClock():IsDusk() or GetClock():IsNight() then
    if TheWorld.state.isnight or TheWorld.state.isdusk then
        if not inst.lighton then
            inst:DoTaskInTime(math.random()*2, function() 
                fadein(inst)
            end)

        else            
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
        inst.AnimState:Show("FIRE")
        inst.AnimState:Show("GLOW")        
        inst.lighton = true
    else
        if inst.lighton then
            inst:DoTaskInTime(math.random()*2, function() 
                fadeout(inst)
            end)            
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end

        inst.AnimState:Hide("FIRE")
        inst.AnimState:Hide("GLOW")        

        inst.lighton = false
    end
end


local function setobstical(inst)
    -- local ground = TheWorld
    local ground = TheWorld
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        ground.Pathfinder:AddWall(pt.x, pt.y, pt.z)
    end
end

local function clearobstacle(inst)
    -- local ground = TheWorld
    local ground = TheWorld
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z)
    end
end

local function onhammered(inst, worker)

    inst.SoundEmitter:KillSound("onsound")

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")

    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0.3, function() updatelight(inst) end)
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0, function() updatelight(inst) end)
end

local function OnEntitySleep(inst)
	if inst.audiotask then
		inst.audiotask:Cancel()
		inst.audiotask = nil
	end
end

local function OnEntityWake(inst)
	if inst.audiotask then
		inst.audiotask:Cancel()
	end
    inst.audiotask = inst:DoPeriodicTask(1.0, function() UpdateAudio(inst) end, math.random())

	local aporkalypse = TheWorld.components.aporkalypse

    -- if aporkalypse and aporkalypse:GetFiestaActive() then
    if aporkalypse and TheWorld.state.isaporkalypse then -- Test updated for Jerry's Hamlet, with rewritten Aporkalypse
        if inst.build == "lamp_post2_city_build" then
            inst.build = "lamp_post2_yotp_build"
            inst.AnimState:SetBuild(inst.build)
        end
    elseif inst.build == "lamp_post2_yotp_build" then
        inst.build = "lamp_post2_city_build"
        inst.AnimState:SetBuild(inst.build)
    end
end


local function makeobstacle(inst)

    -- local ground = TheWorld
    local ground = TheWorld
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        --print("    at: ", pt)
        ground.Pathfinder:AddWall(pt.x, pt.y, pt.z)
    end
end

local function clearobstacle(inst)

    -- local ground = TheWorld
    local ground = TheWorld
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z)
    end
end


local function fn(Sim)
	local inst = CreateEntity()
    local sound = inst.entity:AddSoundEmitter()

    inst:AddTag("CITY_LAMP")
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

    inst.entity:AddPhysics()
 
    MakeObstaclePhysics(inst, 0.25)   

    local light = inst.entity:AddLight()
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetColour(197/255, 197/255, 10/255)
    inst.Light:SetFalloff( 0.9 )
    inst.Light:SetRadius( 5 )
    inst.Light:Enable(false)
    
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    
    inst.build = "lamp_post2_city_build"
    inst.AnimState:SetBank("lamp_post")
    inst.AnimState:SetBuild(inst.build)
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:Hide("FIRE")
    inst.AnimState:Hide("GLOW")    

    inst.AnimState:SetRayTestOnBB(true);

    inst:AddTag("lightsource")

    inst:AddTag("city_hammerable")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus


    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)    

    inst:AddComponent("fader")

    -- inst:ListenForEvent( "daytime", function()
        -- inst:DoTaskInTime(1/30, function() updatelight(inst) end)
    -- end, TheWorld)
    -- inst:ListenForEvent( "dusktime", function()
        -- inst:DoTaskInTime(1/30, function() updatelight(inst) end)
    -- end, TheWorld)
	inst:WatchWorldState("phase", UpdateTime)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = function(inst, data)
        if inst.lighton then
            data.lighton = inst.lighton
        end
    end        

    inst.OnLoad = function(inst, data)    
        if data then
            if data.lighton then 
                fadein(inst)
                inst.Light:Enable(true)
                inst.Light:SetIntensity(INTENSITY)            
                inst.AnimState:Show("FIRE")
                inst.AnimState:Show("GLOW")        
                inst.lighton = true
            end
        end
    end

    inst.audiotask = inst:DoPeriodicTask(1.0, function() UpdateAudio(inst) end, math.random())
    
    inst:AddComponent("fixable")
    inst.components.fixable:AddRecinstructionStageData("rubble", "lamp_post", "lamp_post2_city_build")

    inst.setobstical = setobstical
    inst:AddComponent("gridnudger")

    inst.setobstical = makeobstacle
    inst:ListenForEvent("onremove", function(inst) clearobstacle(inst) end)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake    

    inst.returntointeriorscene = setobstical
   	inst.removefrominteriorscene = clearobstacle

	return inst
end

return Prefab( "city_lamp", fn, assets),
MakePlacer("city_lamp_placer", "lamp_post", "lamp_post2_city_build", "idle", false, false, true)

