local assets=
{
	Asset("ANIM", "anim/vines_rainforest_border.zip"),    
}


local prefabs =
{
}    

local function onsave(inst, data)
	data.animchoice = inst.animchoice
end

local function onload(inst, data)
    if data and data.animchoice then
        inst.animchoice = data.animchoice
	    inst.AnimState:PlayAnimation("idle_"..inst.animchoice)
	end
end


local function plantfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("ham_vine_rainforest_border")
    inst:AddTag("NOCLICK")
    inst.AnimState:SetBuild("vines_rainforest_border")

    local color = 0.7 + math.random() * 0.3
    inst.AnimState:SetMultColour(color, color, color, 1)    

    inst.animchoice = math.random(1,6)
    inst.AnimState:PlayAnimation("idle_"..inst.animchoice)
	
    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
  
    --------SaveLoad
    inst.OnSave = onsave 
    inst.OnLoad = onload 
    
    return inst
end



return Prefab( "forest/objects/jungle_border_vine", plantfn, assets, prefabs)
