local assets =
{
    Asset("ANIM", "anim/pig_ruins_pot.zip"),
}

local prefabs =
{
    "collapse_small",
}

local rarity = {
    extreeme = 1,
    veryhigh = 4,
    high = 8,
    med = 16,
    low = 32,
    verylow = 64,
}

local function SetBroken(inst)
    inst.AnimState:PlayAnimation("broken")
    inst.broken = true
    inst.Physics:SetActive(false)
    inst.Physics:SetSphere(0)
    inst.Physics:Stop()

    if inst.MiniMapEntity then
        inst.MiniMapEntity:SetIcon("")
    end

    inst.components.workable:SetWorkable(false)
    inst.components.lootdropper:ClearRandomLoot()
end

local function OnHammered(inst, worker)
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_pot_bigger") -- TODO missing sound event
    SetBroken(inst)
end

local function OnHit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", false)
end

local function OnSave(inst, data)
    if inst.broken then
        data.broken = true
    end
end

local function OnLoad(inst, data)
    if data and data.broken then
       SetBroken(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.25)

    inst.hammer_sound = "dontstarve_DLC003/common/harvested/claypot/hit"

    inst.AnimState:SetBank("pig_ruins_pot")
    inst.AnimState:SetBuild("pig_ruins_pot")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("pig_ruins_pot.tex")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("thulecite", rarity.extreeme)

    inst.components.lootdropper:AddRandomLoot("bluegem", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("greengem", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("houndstooth", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("livinglog", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("nightmarefuel", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("orangegem", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("purplegem", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("redgem", rarity.veryhigh)
    inst.components.lootdropper:AddRandomLoot("yellowgem", rarity.veryhigh)

    inst.components.lootdropper:AddRandomLoot("goldnugget", rarity.high)
    inst.components.lootdropper:AddRandomLoot("rabid_beetle", rarity.high)
    inst.components.lootdropper:AddRandomLoot("rope", rarity.high)
    inst.components.lootdropper:AddRandomLoot("scorpion", rarity.high)
    inst.components.lootdropper:AddRandomLoot("silk", rarity.high)

    inst.components.lootdropper:AddRandomLoot("boneshard", rarity.med)
    inst.components.lootdropper:AddRandomLoot("fabric_blueprint", rarity.med)
    inst.components.lootdropper:AddRandomLoot("feather_crow", rarity.med)
    inst.components.lootdropper:AddRandomLoot("feather_robin_winter", rarity.med)
    inst.components.lootdropper:AddRandomLoot("feather_robin", rarity.med)
    inst.components.lootdropper:AddRandomLoot("meat_dried", rarity.med)
    inst.components.lootdropper:AddRandomLoot("seeds", rarity.med)

    inst.components.lootdropper:AddRandomLoot("bamboo", rarity.low)
    inst.components.lootdropper:AddRandomLoot("cutreeds", rarity.low)
    inst.components.lootdropper:AddRandomLoot("log", rarity.low)
    inst.components.lootdropper:AddRandomLoot("pigskin", rarity.low)
    inst.components.lootdropper:AddRandomLoot("spoiled_food", rarity.low)

    inst.components.lootdropper:AddRandomLoot("cutgrass", rarity.verylow)
    inst.components.lootdropper:AddRandomLoot("twigs", rarity.verylow)

    inst.components.lootdropper.numrandomloot = 1
    if math.random() < 0.2 then
       inst.components.lootdropper:ClearRandomLoot()
    elseif math.random() < 0.3 then
       inst.components.lootdropper.numrandomloot = 2
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)
    inst.components.workable.savestate = true

    inst:AddComponent("inspectable")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("smashingpot", fn, assets, prefabs)
