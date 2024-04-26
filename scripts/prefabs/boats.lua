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

local corkboatassets = JoinArrays(rowboat_basic_assets, {
    Asset("ANIM", "anim/corkboat.zip"),
    Asset("ANIM", "anim/coracle_boat_build.zip"),
    Asset("ANIM", "anim/flotsam_corkboat_build.zip"),
})

local cargo_assets = JoinArrays(rowboat_basic_assets, {
    Asset("ANIM", "anim/rowboat_cargo_build.zip"),
    Asset("ANIM", "anim/flotsam_cargo_build.zip"),
})


local prefabs = {
    "rowboat_wake",
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

local function OnHit(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("run_loop", true)
end

local function OnWorked(inst)
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

local function OnRepaired(inst, doer, repair_item)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boatrepairkit")
    end
end

local function OnDeployCorkBoat(inst, pt, deployer)
    local boat = inst.boat_data and SpawnSaveRecord(inst.boat_data) or SpawnPrefab("corkboat")

    if boat then
        boat.Physics:SetCollides(false)
        boat.Physics:Teleport(pt.x, 0, pt.z)
        boat.Physics:SetCollides(true)
        inst:Remove()
    end
end

local function OnDroppedCorkBoat(inst)
    -- If this is a valid place to be deployed, auto deploy yourself.
    if inst.components.deployable and inst.components.deployable:CanDeploy(inst:GetPosition()) then
        inst.components.deployable:Deploy(inst:GetPosition(), inst)
    end
end

local function OnPickupedCorkBoat(inst, doer)
    local boat_item = SpawnPrefab("corkboat_item")
    doer.components.inventory:GiveItem(boat_item)

    for _, item in pairs(inst.components.container.boatequipslots) do
        item.components.inventoryitem.ignoresound = true
        doer.components.inventory:GiveItem(item)
        item.components.inventoryitem.ignoresound = false
    end

    boat_item.boat_data = inst:GetSaveRecord()
    inst:Remove()

    return true
end

local function OnSaveCorkBoatItem(inst)
    if inst.boat_data then
        return {boat_data = inst.boat_data}
    end
end

local function OnLoadCorkBoatItem(inst, data)
    if data then
        inst.boat_data = data.boat_data
    end
end

local function DeployTestCorkBoat(inst, pt, mouseover, deployer, rot)
    return TheWorld.Map:IsOceanTileAtPoint(pt.x, pt.y, pt.z)
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
        function inst.OnEntityReplicated(inst)
            inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/bamboo"
            inst.replica.sailable.basicspeedbonus = TUNING.RAFT_SPEED
        end
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
    inst.components.sailable.flotsambuild = "flotsam_bamboo_build"

    inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/bamboo"
    inst.replica.sailable.basicspeedbonus = TUNING.RAFT_SPEED

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = "boat"
    inst.components.repairable.onrepaired = OnRepaired

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
            inst.replica.sailable.basicspeedbonus = TUNING.LOGRAFT_SPEED
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

    inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/log"
    inst.replica.sailable.basicspeedbonus = TUNING.LOGRAFT_SPEED

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
            inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat_creaks"
            inst.replica.sailable.basicspeedbonus = TUNING.ROWBOAT_SPEED
        end
        return inst
    end

    inst.landsound = "dontstarve_DLC002/common/boatjump_land_wood"
    inst.sinksound = "dontstarve_DLC002/common/boat/sinking/row"

    inst.components.container:WidgetSetup("boat_row")

    inst.components.boathealth:SetMaxHealth(TUNING.ROWBOAT_HEALTH)
    inst.components.boathealth:SetHealth(TUNING.ROWBOAT_HEALTH, TUNING.ROWBOAT_PERISHTIME)
    inst.components.boathealth.leakinghealth = TUNING.ROWBOAT_LEAKING_HEALTH
    inst.components.boathealth.damagesound = "dontstarve_DLC002/common/boat/damage/row"
    inst.components.boathealth.hitfx = "boat_hit_fx_rowboat"

    inst.components.sailable.flotsambuild = "flotsam_rowboat_build"

    inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat_creaks"
    inst.replica.sailable.basicspeedbonus = TUNING.ROWBOAT_SPEED

    inst.components.flotsamspawner.flotsamprefab = "flotsam_rowboat"

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
            inst.replica.sailable.basicspeedbonus = TUNING.CARGOBOAT_SPEED
        end
        return inst
    end

    inst.landsound = "dontstarve_DLC002/common/boatjump_land_wood"
    inst.sinksound = "dontstarve_DLC002/common/boat/sinking/log_cargo"

    inst.components.container:WidgetSetup("boat_cargo")

    inst.components.boathealth:SetMaxHealth(TUNING.CARGOBOAT_HEALTH)
    inst.components.boathealth:SetHealth(TUNING.CARGOBOAT_HEALTH, TUNING.CARGOBOAT_PERISHTIME)
    inst.components.boathealth.damagesound = "dontstarve_DLC002/common/boat/damage/cargo"
    inst.components.boathealth.hitfx = "boat_hit_fx_cargoboat"

    inst.components.sailable.flotsambuild = "flotsam_rowboat_build"

    inst.replica.sailable.creaksound = "dontstarve_DLC002/common/boat/creaks/cargo"
    inst.replica.sailable.basicspeedbonus = TUNING.CARGOBOAT_SPEED

    inst.components.flotsamspawner.flotsamprefab = "flotsam_cargo"

    return inst
end

local function corkboatfn()
    local inst = commonfn()

    inst.AnimState:SetBank("rowboat")
    inst.AnimState:SetBuild("coracle_boat_build")
    inst.AnimState:PlayAnimation("run_loop", true)

    inst.MiniMapEntity:SetIcon("coracle_boat.tex")

    if not TheWorld.ismastersim then
        function inst.OnEntityReplicated(inst)
            inst.replica.sailable.creaksound = "dontstarve_DLC003/common/objects/corkboat/creaks"
        end
        return inst
    end

    inst.landsound = "dontstarve_DLC002/common/boatjump_land_wood"
    inst.sinksound = "dontstarve_DLC002/common/boat_sinking_rowboat"

    inst.components.container:WidgetSetup("boat_cork")

    inst.components.boathealth:SetMaxHealth(TUNING.CORKBOAT_HEALTH)
    inst.components.boathealth:SetHealth(TUNING.CORKBOAT_HEALTH, TUNING.CORKBOAT_PERISHTIME)
    inst.components.boathealth.leakinghealth = TUNING.CORKBOAT_LEAKING_HEALTH
    inst.components.boathealth.damagesound = "dontstarve_DLC003/common/objects/corkboat/damage"
    inst.components.boathealth.hitfx = "boat_hit_fx_corkboat"

    inst.components.sailable.flotsambuild = "flotsam_corkboat_build"

    inst.components.flotsamspawner.flotsamprefab = "flotsam_corkboat"

    inst:AddComponent("pickupable")
    inst.components.pickupable:SetOnPickupFn(OnPickupedCorkBoat)
    inst:SetInherentSceneAltAction(ACTIONS.RETRIEVE)

    return inst
end

local function corkboatitemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()

    inst.AnimState:SetBank("corkboat")
    inst.AnimState:SetBuild("corkboat")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("coracle_boat.tex")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst:AddTag("small_boat")
    inst:AddTag("portableitem") -- for deploy string
    inst:AddTag("usedeployspacingasoffset") -- for deploy distance

    inst._custom_candeploy_fn = DeployTestCorkBoat
    inst.name = STRINGS.NAMES.CORKBOAT
    inst.overridedeployplacername = "corkboat_placer"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "corkboat"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDroppedCorkBoat)
    inst.components.inventoryitem:ChangeImageName("corkboat")

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = OnDeployCorkBoat
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM) -- total distance is 3.1

    inst.OnSave = OnSaveCorkBoatItem
    inst.OnLoad = OnLoadCorkBoatItem

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("boat_lograft", lograftfn, lograft_assets, prefabs),
    Prefab("boat_row", rowboatfn, rowboat_assets, prefabs),
    Prefab("boat_cargo", cargofn, cargo_assets, prefabs),
    Prefab("corkboat", corkboatfn, corkboatassets, prefabs),
    Prefab("corkboat_item", corkboatitemfn, corkboatassets, prefabs),
    MakePlacer("boat_lograft_placer", "raft", "raft_log_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2),
    MakePlacer("boat_row_placer", "rowboat", "rowboat_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2),
    MakePlacer("boat_cargo_placer", "rowboat", "rowboat_cargo_build", "run_loop", nil, nil, nil, nil, nil, nil, nil, 2),
    MakePlacer("corkboat_placer", "rowboat", "coracle_boat_build", "run_loop", false, false, false)
