local head_assets =
{
	Asset("ANIM", "anim/roc_head_build.zip"),
	Asset("ANIM", "anim/roc_head_basic.zip"),
	Asset("ANIM", "anim/roc_head_actions.zip"),
	Asset("ANIM", "anim/roc_head_attacks.zip"),
}

local leg_assets =
{
    Asset("ANIM", "anim/roc_leg.zip"),
}

local tail_assets =
{
	Asset("ANIM", "anim/roc_tail.zip"),
}

local function commonfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("roc")
	inst:AddTag("noteleport")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("knownlocations")

	inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 1

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(1000)

	inst:AddComponent("inspectable")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

	return inst
end

local function headfn()
    local inst = commonfn()

    inst.AnimState:SetBank("head")
	inst.AnimState:SetBuild("roc_head_build")
	inst.AnimState:PlayAnimation("idle_loop")

    inst.Transform:SetEightFaced()
    inst.Transform:SetScale(0.8, 0.8, 0.8)

    inst:AddTag("roc_head")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")

    inst.components.groundpounder.numRings = 3

    inst:SetStateGraph("SGroc_head")
end

local function legfn()
    local inst = commonfn()

    inst.AnimState:SetBank("foot")
    inst.AnimState:SetBuild("roc_leg")
    inst.AnimState:PlayAnimation("stomp_loop")

    inst.Transform:SetSixFaced()

    inst:AddTag("roc_leg")

    MakeObstaclePhysics(inst, 2)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.groundpounder.numRings = 2

    inst:SetStateGraph("SGroc_leg")

    return inst
end

local function tailfn()
    local inst = commonfn()

    inst.entity:AddDynamicShadow()

    inst.AnimState:SetBank("tail")
	inst.AnimState:SetBuild("roc_tail")
	inst.AnimState:PlayAnimation("tail_loop")

    inst.DynamicShadow:SetSize(8, 4)

	inst.Transform:SetSixFaced()

	inst:AddTag("roc_tail")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveComponent("groundpounder")

    inst:SetStateGraph("SGroc_tail")

    return inst
end

return  Prefab("roc_head", headfn, head_assets),
        Prefab("roc_leg", legfn, leg_assets),
        Prefab("roc_tail", tailfn, tail_assets)
