local function MakePlantedVeggie(base_veggie, anim, animation, scale, regrow)
    anim = anim or base_veggie

    local assets = {
        Asset("ANIM", "anim/"..anim..".zip"),
    }

    local prefabs = {}
    table.insert(prefabs, base_veggie)

    local function fn()
        -- Aloe you eat is defined in veggies.lua
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(anim)
        inst.AnimState:SetBuild(anim)
        inst.AnimState:PlayAnimation(animation or "planted")
        inst.AnimState:SetRayTestOnBB(true)

        if scale then
            inst.Transform:SetScale(scale, scale, scale)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(base_veggie, 10)
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
        inst.components.pickable.onpickedfn = inst.Remove
        inst.components.pickable.quickpick = true

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntable(inst)
        if regrow then
            -- AddToRegrowthManager(inst)
        end

        return inst
    end

    return Prefab(base_veggie .. "_planted", fn, assets, prefabs)
end

return MakePlantedVeggie("aloe"),
    MakePlantedVeggie("radish"),
    MakePlantedVeggie("asparagus", "asparagus_planted", "idle", 1.3, true)
