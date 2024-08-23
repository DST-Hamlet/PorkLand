local assets =
{
    Asset("ANIM", "anim/shop_table.zip"),
}

local prefabs =
{
    "boards",
}

SetSharedLootTable("shopkeeper_desk",
{
    {"boards", 1.00},
    {"boards", 1.00},
    {"boards", 0.5},
})


local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function desk(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBuild("shop_table")
    inst.AnimState:SetBank("shop_table")
    inst.AnimState:PlayAnimation("idle", false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("shopkeeper_desk")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    --[[
    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ROCK"
    MakeSnowCovered(inst, .01)

    ]]
    return inst
end

return Prefab("pigman_shopkeeper_desk", desk, assets, prefabs)
