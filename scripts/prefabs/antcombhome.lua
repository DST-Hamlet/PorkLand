local assets =
{
    Asset("ANIM", "anim/ant_house.zip"),
}

local prefabs =
{
    "antman",
    "antlarva",
}

SetSharedLootTable("antcombhome", {
    {"honey",     1.0},
    {"honey",     1.0},
    {"honey",     1.0},
    {"honeycomb", 1.0},
})

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    end
end

local ANT_TAGS = {"ant"}
local FIND_ANT_RADIUS = 40
local MIN_ANT_COUNT = 3

local function LaunchProjectile(inst, targetpos)
    local projectile = SpawnPrefab("antlarva")
    projectile.owner = inst
    projectile.Transform:SetPosition(inst:GetPosition():Get())
    projectile.components.pl_complexprojectile:Launch(targetpos)
end

local function maintainantpop(inst)
    if inst:HasTag("burnt") then
        if inst.pop_task then
            inst.pop_task:Cancel()
            inst.pop_task = nil
        end
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, FIND_ANT_RADIUS, ANT_TAGS)
    if #ents < MIN_ANT_COUNT then
        local theta = math.random() * TWOPI
        local radius = math.random() * 4 + 4
        local pt = Vector3(x, y, z)
        local offset = FindWalkableOffset(pt, theta, math.random() * radius, 12, true) or Vector3(0, 0, 0) -- TODO?
        LaunchProjectile(inst, pt + offset)
    end
end

local function OnHammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function OnHit(inst, worker)
    if inst:HasTag("burnt") then
        return
    end

    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function OnIsAporkalypse(inst, isaporkalypse)
    if isaporkalypse then
        inst.Light:Enable(false)
    else
        inst.Light:Enable(true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("ant_house")
    inst.AnimState:SetBuild("ant_house")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)
    inst.Light:SetColour(185/255, 185/255, 20/255)

    inst.MiniMapEntity:SetIcon("ant_house.tex")

    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("antcombhome")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    MakeSnowCovered(inst, .01)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    MakeHauntable(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)
    OnIsAporkalypse(inst, TheWorld.state.isaporkalypse)

    inst.pop_task = inst:DoPeriodicTask(30, maintainantpop)

    return inst
end

return Prefab("antcombhome", fn, assets, prefabs),
       MakePlacer("antcombhome_placer", "ant_house", "ant_house", "idle")
