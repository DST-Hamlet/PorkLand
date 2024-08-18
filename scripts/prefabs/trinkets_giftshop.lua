local function MakeTrinket(num)
    local assets =
    {
        Asset("ANIM", "anim/trinkets_giftshop.zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        PorkLandMakeInventoryFloatable(inst, tostring(num).."_water", tostring(num))

        inst.AnimState:SetBank("trinkets_giftshop")
        inst.AnimState:SetBuild("trinkets_giftshop")
        inst.AnimState:PlayAnimation(tostring(num))

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inventoryitem")
        inst:AddComponent("tradable")
        inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.TRINKETS[num] or 3
        -- inst.components.tradable.dubloonvalue = TUNING.DUBLOON_VALUES.TRINKETS[num] or 3

        -- inst:AddComponent("appeasement")
        -- local appeasementvalue = TUNING.APPEASEMENT_SMALL
        -- if num > 12 then
        --     appeasementvalue = TUNING.APPEASEMENT_LARGE
        -- end
        -- inst.components.appeasement.appeasementvalue = appeasementvalue

        inst:AddComponent("bait")
        inst:AddTag("molebait")
        inst:AddTag("cattoy")
        inst:AddTag("trinket")

        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("trinket_giftshop_"..tostring(num), fn, assets)
end

return MakeTrinket(1),
    MakeTrinket(3),
    MakeTrinket(4)
