require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/pressure_plate.zip"),
    Asset("ANIM", "anim/pressure_plate_build.zip"),
}

local prefabs =
{
    "pig_ruins_dart",
}

local function onsave(inst, data)
    if inst:HasTag("trap_dart") then
        data.trap = "trap_dart"
    end
    if inst:HasTag("trap_spear") then
        data.trap = "trap_spear"
    end   
    if inst:HasTag("localtrap") then
        data.localtrap = true
    end    
    if inst:HasTag("reversetrigger") then
        data.reversetrigger = true
    end  
    if inst:HasTag("startdown") then
        data.startdown = true
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
    if data.reversetrigger then
        inst:AddTag("reversetrigger")
    end 
    if data.startdown then
        inst:AddTag("startdown")
    end
  end
end

local function trigger(inst)
    if inst:HasTag("trap_dart") then
        print("TRIGGER DARTS!")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, {"dartthrower"}, {"INTERIOR_LIMBO"})
        for i, ent in ipairs(ents) do
            if ent.components.autodartthrower then
                ent.components.autodartthrower:TurnOn()    
            elseif ent.shoot then
                ent.shoot(ent)
            end
        end
    elseif inst:HasTag("trap_spear") then
        print("TRIGGER SPEARS!")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local dist = 50
        if inst:HasTag("localtrap") then
            dist = 4
        end
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, dist, {"spear_trap"}, {"INTERIOR_LIMBO"})
        for i, ent in ipairs(ents) do
            ent:PushEvent("triggertrap")
        end         
    else
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, nil, {"INTERIOR_LIMBO"})
        for i, ent in ipairs(ents) do
            if ent:HasTag("lockable_door") then
                ent:PushEvent("open")
            end
        end
    end    
end

local function untrigger(inst)
    if inst:HasTag("trap_dart")  then
    elseif inst:HasTag("trap_spear") then
        print("TRIGGER SPEARS!")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local dist = 50
        if inst:HasTag("localtrap") then
            dist = 4
        end
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, dist, {"spear_trap"}, {"INTERIOR_LIMBO"})
        for i, ent in ipairs(ents) do
            ent:PushEvent("reset")
        end   
    else
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, nil, {"INTERIOR_LIMBO"})
        for i, ent in ipairs(ents) do

            if ent:HasTag("lockable_door") then
                ent:PushEvent("close")
            end
        end
    end
end

local function onnear(inst)
    print("TRIGGER")
  --  if inst.weights == 0 then
    if not inst:HasTag("INTERIOR_LIMBO") and inst.components.disarmable.armed and not inst.down then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/pressure_plate/hit")
        inst.AnimState:PlayAnimation("popdown")
        inst.AnimState:PushAnimation("down_idle")
        inst.down = true
        if inst:HasTag("reversetrigger") then
            untrigger(inst)
        else
            trigger(inst)
        end
    end
   -- end
   -- inst.weights = inst.weights +1
   -- print("near",inst.weights)
end

local function onfar(inst)
    --inst.weights = inst.weights -1
    --if  inst.weights == 0 then
    if not inst:HasTag("INTERIOR_LIMBO") and inst.components.disarmable.armed and inst.down then
        inst.AnimState:PlayAnimation("popup")
        inst.AnimState:PushAnimation("up_idle")
        inst.down = nil
        if inst:HasTag("reversetrigger") then
            trigger(inst)
        else
            untrigger(inst)
        end
    end
   -- end
  --  print("far",inst.weights)
end

local function testfn(testinst)
    return not testinst:HasTag("flying")
end

local function disarm(inst, doer)
   inst.AnimState:PlayAnimation("disarmed")
   inst.components.creatureprox:SetEnabled(false)
   inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_floor")
   inst.down = false
end

local function rearm(inst, doer)
    inst.AnimState:PlayAnimation("up_idle")
    inst.components.creatureprox:SetEnabled(true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_floor")
    if inst.components.creatureprox then
       inst.components.creatureprox:forcetest()
    end    
end

local function checkstartdown(inst)
    if inst:HasTag("startdown") then
        inst.down = true
        --inst.AnimState:PushAnimation("down_idle")
        inst.AnimState:PlayAnimation("down_idle")
    end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    anim:SetBank("pressure_plate")
    anim:SetBuild("pressure_plate_build")
    anim:PlayAnimation("up_idle")

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("structure")
    
    --inst:AddTag("NOCLICK")
    --------------------
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.weights = 0

    inst:AddComponent("disarmable")
    inst.components.disarmable.disarmfn = disarm
    inst.components.disarmable.rearmfn = rearm
    inst.components.disarmable.rearmable = true
    inst:AddTag("weighdownable")

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetOnPlayerNear(onnear)
    inst.components.creatureprox:SetOnPlayerFar(onfar)
    inst.components.creatureprox:SetTestfn(testfn)
    inst.components.creatureprox:SetDist(0.8, 0.9)
    inst.components.creatureprox.inventorytrigger = true
    inst.components.creatureprox.period = 0.01

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst:DoTaskInTime(0,function() checkstartdown(inst) end)
    --inst.OnLoadPostPass = OnLoadPostPass

    inst:AddComponent("hiddendanger")

    return inst
end

return  Prefab( "pig_ruins_pressure_plate", fn, assets, prefabs)