local assets =
{
	Asset("ANIM", "anim/aloe.zip"),
}

local prefabs =
{
	"aloe",
}

local function onpickedfn(inst)
	inst:Remove()
end


local function fn(Sim)
    --Aloe you eat is defined in veggies.lua
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aloe")
    inst.AnimState:SetBuild("aloe")
    inst.AnimState:PlayAnimation("planted")
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("aloe", 10)
	inst.components.pickable.onpickedfn = onpickedfn

    inst.components.pickable.quickpick = true

	MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("aloe_planted", fn, assets) 
