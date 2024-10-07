local assets =
{
    Asset("ANIM", "anim/ant_cave_lantern.zip"),
}

local prefabs =
{
}

SetSharedLootTable("ant_cave_lantern", {
    {"honey", 1.0},
    {"honey", 1.0},
    {"honey", 1.0},
})

local function OnWorkCallback(inst, worker, work_left)
    if work_left <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot()
        inst:Remove()
    else
        if work_left < TUNING.HONEY_LANTERN_MINE * (1 / 3) then
            inst.AnimState:PlayAnimation("break")
        elseif work_left < TUNING.HONEY_LANTERN_MINE * (2 / 3) then
            inst.AnimState:PlayAnimation("hit")
        else
            inst.AnimState:PlayAnimation("idle")
        end
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
    local inst  = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("ant_cave_lantern")
    inst.AnimState:SetBuild("ant_cave_lantern")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetFalloff(0.4)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetRadius(2.5)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.Light:Enable(true)

    inst.MiniMapEntity:SetIcon("ant_cave_lantern.tex")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ant_cave_lantern")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.HONEY_LANTERN_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    MakeHauntable(inst)

    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)
    OnIsAporkalypse(inst, TheWorld.state.isaporkalypse)

    return inst
end

return Prefab("ant_cave_lantern", fn, assets, prefabs)
