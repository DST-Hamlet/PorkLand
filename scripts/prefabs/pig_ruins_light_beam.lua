require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ruins_light_beam.zip"),  
}

local prefabs =
{

}    

local function onsave(inst, data)    
    if inst:HasTag("trap_dart") then
        data.trap = "trap_dart"
    end
    if inst:HasTag("localtrap") then
        data.localtrap = true
    end
end

local function onload(inst, data)
  if data then
    if data.trap then
        inst:AddTag(data.trap)
    end
    if data.localtrap then
        inst:AddTag("localtrap")
    end
  end
end

local function trigger(inst)
    local range = 50
    if inst:HasTag("localtrap") then
        range = 4 
    end

    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, range, {"dartthrower"}, {"INTERIOR_LIMBO"})
    for i, ent in ipairs(ents) do
        if ent.components.autodartthrower then
            ent.components.autodartthrower:TurnOn()
        elseif ent.shoot then
            ent.shoot(ent)
        end
    end
  
    ents = TheSim:FindEntities(pt.x, pt.y, pt.z, range, {"spear_trap"}, {"INTERIOR_LIMBO"})
    for i, ent in ipairs(ents) do            
        ent:PushEvent("triggertrap")            
    end    
end

local function untrigger(inst)
   
end

local function onnear(inst)    
    if not inst:HasTag("INTERIOR_LIMBO") then
        -- if GetClock():GetPhase() ~= "" then -- Not sure EXACTLY what this is for, so... skip it, I guess?
            trigger(inst)
        -- end        
    end
end

local function onfar(inst)
    if not inst:HasTag("INTERIOR_LIMBO") then
        untrigger(inst)
    end
end

local function testfn(testinst)
    local result = true

    if not testinst:HasTag("locomotor") then
        result = false
    end
    return result
end

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
    inst.components.creatureprox:SetEnabled(false)
    inst:Hide()    
end

local function turnon(inst,light)
    inst.components.creatureprox:SetEnabled(true)
end

local phasefunctions = 
{
    day = function(inst, instant)
        inst.Light:Enable(true)
        inst:Show()
        local time = 2 
        if instant then 
            time = 0
        end
        if inst:HasTag("ruins_light") then
            inst.components.lighttweener:StartTween(nil, 1, .6, .7, {180/255, 195/255, 150/255}, time, turnon)
        elseif inst:HasTag("cave_light") then -- 0.6
            inst.components.lighttweener:StartTween(nil, 1*3, .8, .7, {180/255, 195/255, 150/255}, time, turnon)
        end
    end,

    dusk = function(inst, instant) 
        inst.Light:Enable(true)
        local time = 2 
        if instant then 
            time = 0
        end       
        if inst:HasTag("ruins_light") then
            inst.components.lighttweener:StartTween(nil, .75, .6, .7, {100/255, 100/255, 100/255}, time, turnon)
        elseif inst:HasTag("cave_light") then -- 0.6
            inst.components.lighttweener:StartTween(nil, .75*3, .8, .7, {100/255, 100/255, 100/255}, time, turnon)
        end
    end,

    night = function(inst, instant) 
        -- if GetWorld().components.clock:GetMoonPhase() == "full" then
        if TheWorld.state.isfullmoon then
            local time = 4 
            if instant then 
                time = 0
            end    
            if inst:HasTag("ruins_light") then
                inst.components.lighttweener:StartTween(nil, 1, .5, .6, {91/255, 164/255, 255/255}, time, turnon)
            elseif inst:HasTag("cave_light") then 
                inst.components.lighttweener:StartTween(nil, 1*3, .5, .6, {91/255, 164/255, 255/255}, time, turnon)
            end                    
            
        else
            local time = 6 
            if instant then 
                time = 0
            end
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0,0,0}, time, turnoff)            
        end    
    end,
}

-- local function timechange(inst, instant)
    -- -- local c = GetClock()
    -- -- local p = c:GetPhase()
    -- if not inst:HasTag("INTERIOR_LIMBO") then
        -- -- phasefunctions[p](inst, instant)        
		
		-- if TheWorld.state.isday then
			-- phasefunctions["day"](inst, instant)
		-- elseif TheWorld.state.isnight then
			-- phasefunctions["night"](inst, instant)
		-- elseif TheWorld.state.isdusk then
			-- phasefunctions["dusk"](inst, instant)
		-- end
    -- end
-- end

local function UpdateTime(inst, instant)    
	local phase = TheWorld.state.phase
	if not inst:HasTag("INTERIOR_LIMBO") then
		if inst.Light then
			phasefunctions[phase](inst, instant)
		end
	end
end


local function UpdateIsInInterior(inst)
     -- timechange(inst,true)
     UpdateTime(inst,true)
end  

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()    
	inst.entity:AddNetwork()

    anim:SetBank("ruins_light_cone")
    anim:SetBuild("ruins_light_beam")
    anim:PlayAnimation("idle_loop", true)

    inst.UpdateIsInInterior = UpdateIsInInterior    

    inst:AddTag("NOCLICK")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    --------------------

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetOnPlayerNear(onnear)
    inst.components.creatureprox:SetOnPlayerFar(onfar)
    inst.components.creatureprox:SetTestfn(testfn)    
    inst.components.creatureprox:SetDist(1.4, 1.5)
    inst.components.creatureprox.inventorytrigger = true
    
    --------------------

    -- inst:ListenForEvent("daytime", function() timechange(inst) end, GetWorld())
    -- inst:ListenForEvent("dusktime", function() timechange(inst) end, GetWorld())
    -- inst:ListenForEvent("nighttime", function() timechange(inst) end, GetWorld())
	-- inst:WatchWorldState("phase", timechange)
	inst:WatchWorldState("phase", UpdateTime)
    UpdateTime(inst, TheWorld.state.phase)

    --------------------

    inst.color= {255/255,177/255,32/255}

    inst.AnimState:SetMultColour(255/255,177/255,32/255,0)  

    inst.OnSave = onsave 
    inst.OnLoad = onload 

    return inst
end

local function ruinsfn(Sim)
    local inst = fn(Sim)
	-- inst.entity:AddNetwork()
    inst:AddTag("ruins_light")
    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.entity:AddLight(), 1, .6, .7, {180/255, 195/255, 150/255}, 0)

    return inst
end

local function cavefn(Sim)
    local inst = fn(Sim)
	-- inst.entity:AddNetwork()
    inst:AddTag("cave_light")
    inst:AddComponent("lighttweener") -- 0.6
    inst.components.lighttweener:StartTween(inst.entity:AddLight(), 1*3, .8, .7, {180/255, 195/255, 150/255}, 0)

    return inst
end

return  Prefab( "pig_ruins_light_beam", ruinsfn, assets, prefabs),
        Prefab( "roc_cave_light_beam", cavefn, assets, prefabs)        

