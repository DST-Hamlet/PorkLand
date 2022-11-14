local assets=
{
	Asset("ANIM", "anim/fern_plant.zip"),
    Asset("ANIM", "anim/fern2_plant.zip"),
}


local prefabs =
{
}    

local function onsave(inst, data)
	data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
	    inst.AnimState:PlayAnimation("idle")
	end
end


local function plantfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    
    inst.entity:AddTag("NOCLICK")
    
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    inst.AnimState:SetBank("fern_plant")

    inst.AnimState:SetBuild("fern_plant")

        local color = 0.7 + math.random() * 0.3
        inst.AnimState:SetMultColour(color, color, color, 1)    

    if math.random()<0.5 then
        inst.AnimState:PlayAnimation("idle")
    else
        inst.AnimState:PlayAnimation("idle2")
    end
    --inst.AnimState:SetRayTestOnBB(true);

    inst:AddTag("fern_plant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --------SaveLoad
    inst.OnSave = onsave 
    inst.OnLoad = onload 
    
    return inst
end


local function round(x)
  x = x *10
  local num = x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  return num/10
end

local function placefernsoffgrids(inst)
    

    local plant = SpawnPrefab("deep_jungle_fern_noise_plant")

--[[
        local x,y,z = inst.Transform:GetWorldPosition()
        
        x = x+(math.random()*4) -2
        z = z+(math.random()*4) -2

        plant.Transform:SetPosition(x,y,z)   

]]
    local x,y,z = 0,0,0
    local offgrid = false
    local inc = 1
    while offgrid == false do

        x,y,z = inst.Transform:GetWorldPosition()
        
        x = x+(math.random()*4) -2
        z = z+(math.random()*4) -2


        local ents = TheSim:FindEntities(x,y,z, 1, {"fern_plant"})
        local test = true
        for i,ent in ipairs(ents) do
            local entx,enty,entz = ent.Transform:GetWorldPosition()
           -- print("checing round x:",round(x),round(entx),"z:", round(z), round(entz),"diff:",round(math.abs(entx-x)),round( math.abs(entz-z)) )
            if round(x) == round(entx) or round(z) == round(entz) or ( math.abs(round(entx-x)) == math.abs(round(entz-z)) )  then
                test = false
         --       print("test fail")
                break
            end           
        end
        
        offgrid = test
        inc = inc +1 
    end
    plant.Transform:SetPosition(x,y,z)    
    
end

local function spawnferns(inst)
    placefernsoffgrids(inst)
    inst:Remove()
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fern_plant")
    inst.AnimState:SetBuild("fern_plant")
    inst.AnimState:PlayAnimation("idle")
    --inst.AnimState:SetRayTestOnBB(true);

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --------SaveLoad
    inst.OnSave = onsave 
    inst.OnLoad = onload 
    
    inst:DoTaskInTime(0,function() spawnferns(inst) end)

    return inst
end

return Prefab( "forest/objects/deep_jungle_fern_noise", fn, assets, prefabs),
       Prefab( "forest/objects/deep_jungle_fern_noise_plant", plantfn, assets, prefabs)
