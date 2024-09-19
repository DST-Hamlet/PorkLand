local prefabs =
{
    "ash",
    "collapse_small",
}

local function onhammered(inst, worker)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = 1, math.random(3, 4) do
        local fx = SpawnPrefab("robot_leaf_fx")
        fx.Transform:SetPosition(x + (math.random() * 2) , y + math.random() * 0.5, z + (math.random() * 2))
        if math.random() < 0.5 then
            fx.Transform:SetScale(-1, 1, -1)
        end
    end

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_straw")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", false)

    local fx = SpawnPrefab("robot_leaf_fx")
    local x, y, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + math.random() * 0.5, z)

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")
end


local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end

local function makeitem(name, build, frame)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.entity:AddPhysics()
        MakeObstaclePhysics(inst, .25)

        local minimap = inst.entity:AddMiniMapEntity()
        minimap:SetIcon("topiary_".. frame ..".tex")

        inst.entity:AddSoundEmitter()
        inst:AddTag("structure")

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle", true)

        inst:SetPrefabNameOverride("topiary")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)

        if frame == "3" or frame == "4" then
            MakeLargeBurnable(inst, nil, nil, true)
            MakeLargePropagator(inst)
        else
            MakeMediumBurnable(inst, nil, nil, true)
            MakeMediumPropagator(inst)
        end

        inst:ListenForEvent("burntup", inst.Remove)

        inst:AddComponent("inspectable")

        MakeSnowCovered(inst)

        inst:AddComponent("fixable")
        inst.components.fixable:AddReconstructionStageData("burnt", build, build)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return makeitem("topiary_1", "topiary_pigman", "1"),
    makeitem("topiary_2", "topiary_werepig", "2"),
    makeitem("topiary_3", "topiary_beefalo", "3"),
    makeitem("topiary_4", "topiary_pigking", "4")

