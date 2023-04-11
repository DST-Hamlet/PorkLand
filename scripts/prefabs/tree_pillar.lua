local prefabs = {
    "glowfly",
    "glowfly_cocoon"
}

local assets = {
    Asset("ANIM", "anim/pillar_tree.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 3, 24)

    inst.MiniMapEntity:SetIcon("pillar_tree.tex")

    -- THIS WAS COMMENTED OUT BECAUSE THE ROC WAS BUMPING INTO IT. BUT I'M NOT SURE WHY IT WAS SET THAT WAY TO BEGIN WITH.
    -- inst.Physics:SetCollisionGroup(COLLISION.GROUND)
    inst:AddTag("tree_pillar")

    inst.AnimState:SetBank("pillar_tree")
    inst.AnimState:SetBuild("pillar_tree")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("glowflycocoonspawner")

    return inst
end

return Prefab("tree_pillar", fn, assets, prefabs)
