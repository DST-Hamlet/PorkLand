local assets =
{
	Asset("ANIM", "anim/asparagus.zip"),
}

local prefabs =
{
	"asparagus",
}

local function onpickedfn(inst)
	inst:Remove()
end


local function fn(Sim)
    --Asparagus you eat is defined in veggies.lua
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(1.3,1.3,1.3)

    inst.AnimState:SetBank("asparagus")
    inst.AnimState:SetBuild("asparagus")
    inst.AnimState:PlayAnimation("planted")
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	
	
    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("asparagus", 10)
	inst.components.pickable.onpickedfn = onpickedfn

    inst.components.pickable.quickpick = true

	MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("common/inventory/asparagus_planted", fn, assets)
