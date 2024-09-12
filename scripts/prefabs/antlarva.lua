local assets =
{
    Asset("ANIM", "anim/ant_larva.zip"),
}

local function OnHit(inst, dist)
    inst.sg:GoToState("land")
end

local function larava_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ant_larva")
    inst.AnimState:SetBuild("ant_larva")

    MakeThrowablePhysics(inst, 75, 0.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("locomotor")

    inst:AddComponent("throwable")
    inst.components.throwable:SetOnHitFn(OnHit)
    inst.components.throwable.yOffset = 4
    inst.components.throwable.speed = 10

    inst:SetStateGraph("SGantlarva")

    return inst
end

return Prefab("antlarva", larava_fn, assets)
