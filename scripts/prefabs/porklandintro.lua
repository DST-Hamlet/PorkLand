local assets =
{
    Asset("ANIM", "anim/balloon_wreckage.zip"),
}

local prefabs = {

}

local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")

    inst:Remove()
end

local function MakeIntroDecor(name, anim, loot, onground, minimapicon, collision)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if collision then
            MakeObstaclePhysics(inst, 0.75)
        end

        inst.AnimState:SetBank("balloon_wreckage")
        inst.AnimState:SetBuild("balloon_wreckage")
        inst.AnimState:PlayAnimation(anim)

        -- at the momnent only the ground thing isn't workable.. this might change tho..
        if onground then
            inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.AnimState:SetSortOrder(3)
            if not loot then
                inst:AddTag("NOCLICK")
            end
        end

        if minimapicon then
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon(minimapicon .. ".tex")
        end

        inst:AddTag("notarget")
        inst:AddTag("porklandintro")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        if loot then
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnFinishCallback(onhammered)

            inst:AddComponent("lootdropper")
            for _, item in pairs(loot) do
                inst.components.lootdropper:AddChanceLoot(item, 1)
            end
        end

        MakeHauntable(inst)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeIntroDecor("porkland_intro_basket",   "basket",              {"boards"},    nil, "balloon_wreckage", true),
       MakeIntroDecor("porkland_intro_balloon",  "balloon",             {"fabric"},    nil, nil, true),
       MakeIntroDecor("porkland_intro_trunk",    "trunk",               {"trinket_8"}, nil, nil, true),
       MakeIntroDecor("porkland_intro_suitcase", "suitcase",            {"razor"},     nil, nil, true),
       MakeIntroDecor("porkland_intro_flags",    "flags",               {"rope"},      true),
       MakeIntroDecor("porkland_intro_sandbag",  "sandbag"             --[[{"sand"}]]), -- no use in hamlet
       MakeIntroDecor("porkland_intro_scrape",   "ground_scrape_decal", nil,           true)
