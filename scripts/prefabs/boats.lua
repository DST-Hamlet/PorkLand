local raft_basic_assets = {
    Asset("ANIM", "anim/raft_basic.zip"),
    Asset("ANIM", "anim/raft_idles.zip"),
}

local lograft_assets = JoinArrays(raft_basic_assets, {
    Asset("ANIM", "anim/raft_log_build.zip"),
})

local prefabs = {
}

local function OnWorked(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("run_loop", true)
end

local function OnHit(inst)
    inst.components.lootdropper:DropLoot()
    if inst.components.container then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.Physics:SetCylinder(0.25, 2)
    inst.Transform:SetFourFaced()
    inst.MiniMapEntity:SetPriority(5)

    inst:AddTag("small_boat")
    inst:AddTag("sailable")

    inst.no_wet_prefix = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst.waveboost = TUNING.WAVEBOOST
    -- inst.sailmusic = "sailing"

    inst:AddComponent("inspectable")

    inst:AddComponent("sailable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnWorked)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    return inst
end

local function lograftfn()
    local inst = commonfn()

    inst.AnimState:SetBuild("raft_log_build")
    inst.AnimState:SetBank("raft")
    inst.AnimState:PlayAnimation("run_loop", true)

    inst.MiniMapEntity:SetIcon("raft.tex")

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("lograft", lograftfn, lograft_assets, prefabs),
    MakePlacer("lograft_placer", "raft", "raft_log_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2)
