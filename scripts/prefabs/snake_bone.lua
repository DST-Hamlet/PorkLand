local assets =
{
    Asset("ANIM", "anim/snake_bone.zip")
}

local function onspoiledhammered(inst, worker)
    local to_hammer = (inst.components.stackable and inst.components.stackable:Get(1)) or inst
    if to_hammer == inst then
        to_hammer.components.inventoryitem:RemoveFromOwner(true)
    end
    if to_hammer:IsInLimbo() then
        to_hammer:ReturnToScene()
    end

    to_hammer.Transform:SetPosition(inst:GetPosition():Get())
    to_hammer.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(to_hammer.Transform:GetWorldPosition())

    inst.components.workable:SetWorkLeft(1)

    to_hammer:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("snake_bone")
    inst.AnimState:SetBuild("snake_bone")
    inst.AnimState:PlayAnimation("idle", false)

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"boneshard", "boneshard"})

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onspoiledhammered)

    inst:AddComponent("stackable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("snake_bone", fn, assets)
