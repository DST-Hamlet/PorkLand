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

    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("locomotor")

    inst:AddComponent("pl_complexprojectile")
    inst.components.pl_complexprojectile:SetOnHit(OnHit)
    inst.components.pl_complexprojectile.yOffset = 2.5

    inst:SetStateGraph("SGantlarva")

    return inst
end

return Prefab("antlarva", larava_fn, assets)
