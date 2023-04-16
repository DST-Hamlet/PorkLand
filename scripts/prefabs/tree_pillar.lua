local prefabs = {
    "glowfly",
    "glowfly_cocoon"
}

local assets = {
    Asset("ANIM", "anim/tree_pillar.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 3, 24)

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("tree_pillar.tex")

    -- THIS WAS COMMENTED OUT BECAUSE THE ROC WAS BUMPING INTO IT. BUT I'M NOT SURE WHY IT WAS SET THAT WAY TO BEGIN WITH.
    -- inst.Physics:SetCollisionGroup(COLLISION.GROUND)
    inst:AddTag("tree_pillar")

    inst.AnimState:SetBank("tree_pillar")
    inst.AnimState:SetBuild("tree_pillar")
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
