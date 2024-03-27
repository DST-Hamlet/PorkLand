local raft_basic_assets = {
    Asset("ANIM", "anim/raft_basic.zip"),
    Asset("ANIM", "anim/raft_idles.zip"),
    Asset("ANIM", "anim/raft_paddle.zip"),
}

local rowboat_basic_assets = {
    Asset("ANIM", "anim/rowboat_basic.zip"),
    Asset("ANIM", "anim/rowboat_idles.zip"),
    Asset("ANIM", "anim/rowboat_paddle.zip"),
}

local lograft_assets = JoinArrays(raft_basic_assets, {
    Asset("ANIM", "anim/raft_log_build.zip"),
    Asset("ANIM", "anim/flotsam_lograft_build.zip"),
})

local rowboat_assets = JoinArrays(rowboat_basic_assets, {
    Asset("ANIM", "anim/rowboat_build.zip"),
    Asset("ANIM", "anim/flotsam_rowboat_build.zip"),
})

local armouredboat_assets = JoinArrays(rowboat_basic_assets, {
    Asset("ANIM", "anim/rowboat_armored_build.zip"),
    Asset("ANIM", "anim/flotsam_rowboat_build.zip"),
})

local cargo_assets = JoinArrays(rowboat_basic_assets, {
    Asset("ANIM", "anim/rowboat_cargo_build.zip"),
    Asset("ANIM", "anim/flotsam_cargo_build.zip"),
})


local prefabs = {
    "rowboat_wake"
}

local function OnOpen(inst)
    if inst.components.sailable.sailor == nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat/inventory_open")
    end
end

local function OnClose(inst)
    if inst.components.sailable.sailor == nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat/inventory_close")
    end
end

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

local function Sink(inst)
    local sailor = inst.components.sailable:GetSailor()
    if sailor then
        sailor.components.sailor:Disembark(nil, nil, true)

        -- sailor:PushEvent("onsink", {ia_boat = inst})

        sailor.SoundEmitter:PlaySound(inst.sinksound)
    end
    if inst.components.container then
        inst.components.container:DropEverything()
    end

    inst:Remove()
end

local function OnDisEmbarked(inst)
    inst.components.workable:SetWorkable(false)
end

local function OnEmbarked(inst)
    inst.components.workable:SetWorkable(true)
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

    inst.AnimState:SetFinalOffset(FINALOFFSET_MIN) -- TODO causes minor visual issues find something better

    inst:AddTag("small_boat")
    inst:AddTag("sailable")

    inst.no_wet_prefix = true

    inst.boatvisuals = {}

    inst:AddComponent("highlightchild")

    inst:SetReplaceReplicableComponent("boatcontainer", "container")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.landsound = "dontstarve_DLC002/common/boatjump_land_bamboo"
    inst.sinksound = "dontstarve_DLC002/common/boat/sinking/bamboo"

    -- inst.waveboost = TUNING.WAVEBOOST

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("rowboatwakespawner")

    inst:AddComponent("boatvisualmanager")

    inst:AddComponent("sailable")

    inst:AddReplaceComponent("boatcontainer", "container")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnWorked)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("boathealth")
    inst.components.boathealth:SetDepletedFn(Sink)
    inst.components.boathealth:SetHealth(TUNING.RAFT_HEALTH, TUNING.RAFT_PERISHTIME)
    inst.components.boathealth.leakinghealth = TUNING.RAFT_LEAKING_HEALTH
    inst.components.boathealth.damagesound = "dontstarve_DLC002/common/boat_damage_rowboat"
    inst.components.boathealth.hitfx = "boat_hit_fx_raft_bamboo"

    inst:AddComponent("flotsamspawner")
    inst.components.flotsamspawner.flotsamprefab = "flotsam_bamboo"

    inst:ListenForEvent("embarked", OnEmbarked)
    inst:ListenForEvent("disembarked", OnDisEmbarked)

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
        function inst.OnEntityReplicated(inst)
            inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/log"
        end
        return inst
    end

    inst.landsound = "dontstarve_DLC002/common/boatjump_land_log"
    inst.sinksound = "dontstarve_DLC002/common/boat/sinking/log_cargo"

    inst.components.container:WidgetSetup("boat_lograft")

    inst.components.boathealth:SetHealth(TUNING.LOGRAFT_HEALTH, TUNING.LOGRAFT_PERISHTIME)
    inst.components.boathealth.leakinghealth = TUNING.LOGRAFT_LEAKING_HEALTH
    inst.components.boathealth.damagesound = "dontstarve_DLC002/common/boat/damage/log"
    inst.components.boathealth.hitfx = "boat_hit_fx_raft_log"

    inst.components.sailable.flotsambuild = "flotsam_lograft_build"

    inst.components.flotsamspawner.flotsamprefab = "flotsam_lograft"

    return inst
end

local function rowboatfn()
    local inst = commonfn()

    inst.AnimState:SetBank("rowboat")
    inst.AnimState:SetBuild("rowboat_build")
    inst.AnimState:PlayAnimation("run_loop", true)

    inst.MiniMapEntity:SetIcon("boat_row.tex")

    if not TheWorld.ismastersim then
        function inst.OnEntityReplicated(inst)
        end
        return inst
    end

    inst.landsound = "dontstarve_DLC002/common/boatjump_land_wood"
    inst.sinksound = "dontstarve_DLC002/common/boat/sinking/row"

    inst.components.container:WidgetSetup("boat_row")

    inst.components.boathealth:SetHealth(TUNING.ROWBOAT_HEALTH, TUNING.ROWBOAT_PERISHTIME)
    inst.components.boathealth.leakinghealth = TUNING.ROWBOAT_LEAKING_HEALTH
    inst.components.boathealth.damagesound = "dontstarve_DLC002/common/boat/damage/row"
    inst.components.boathealth.hitfx = "boat_hit_fx_rowboat"

    inst.components.sailable.flotsambuild = "flotsam_rowboat_build"

    inst.components.flotsamspawner.flotsamprefab = "flotsam_rowboat"

    return inst
end

local function armouredboatfn()
    local inst = commonfn()

    inst.AnimState:SetBank("rowboat")
    inst.AnimState:SetBuild("rowboat_armored_build")
    inst.AnimState:PlayAnimation("run_loop", true)
    inst.MiniMapEntity:SetIcon("boat_armoured.tex")

    if not TheWorld.ismastersim then
        function inst.OnEntityReplicated(inst)
            inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/armoured"
        end
        return inst
    end

    inst.components.container:WidgetSetup("boat_armoured")

    return inst
end

local function cargofn()
    local inst = commonfn()

    inst.AnimState:SetBank("rowboat")
    inst.AnimState:SetBuild("rowboat_cargo_build")
    inst.AnimState:PlayAnimation("run_loop", true)
    inst.MiniMapEntity:SetIcon("boat_cargo.tex")

    if not TheWorld.ismastersim then
        function inst.OnEntityReplicated(inst)
            inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/cargo"
        end
        return inst
    end

    inst.components.container:WidgetSetup("boat_cargo")

    inst.components.flotsamspawner.flotsamprefab = "flotsam_cargo"

    return inst
end

return Prefab("boat_lograft", lograftfn, lograft_assets, prefabs),
    Prefab("boat_row", rowboatfn, rowboat_assets, prefabs),
    Prefab("boat_armoured", armouredboatfn, armouredboat_assets, prefabs),
    Prefab("boat_cargo", cargofn, cargo_assets, prefabs),
    MakePlacer("boat_lograft_placer", "raft", "raft_log_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2),
    MakePlacer("boat_row_placer", "rowboat", "rowboat_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2),
    MakePlacer("boat_cargo_placer", "rowboat", "rowboat_cargo_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2)
