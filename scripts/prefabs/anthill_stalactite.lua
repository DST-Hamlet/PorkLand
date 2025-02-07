local assets = {
    Asset("ANIM", "anim/rock_antcave.zip")
}

local prefabs = {
    "rocks"
}

SetSharedLootTable("rock_antcave", {
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
})

local function OnWorkCallback(inst, worker, work_left)
    if work_left <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot()
        inst:Remove()
    else
        if work_left < TUNING.ROCKS_MINE * (1 / 3) then
            inst.AnimState:PlayAnimation("low")
        elseif work_left < TUNING.ROCKS_MINE * (2 / 3) then
            inst.AnimState:PlayAnimation("med")
        else
            inst.AnimState:PlayAnimation("full")
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("rock_antcave")
    inst.AnimState:SetBuild("rock_antcave")
    inst.AnimState:PlayAnimation("full", true)

    inst.MiniMapEntity:SetIcon("rock_antcave.tex")

    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("rock_antcave")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    MakeHauntable(inst)

    return inst
end

return Prefab("rock_antcave", fn, assets, prefabs)
