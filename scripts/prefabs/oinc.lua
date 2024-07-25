local function shine(inst)
    inst.task = nil
    -- hacky, need to force a floatable anim change
    inst.components.floater:UpdateAnimations("idle_water", "idle")
    inst.components.floater:UpdateAnimations("sparkle_water", "sparkle")

    if inst.components.floater:IsFloating() then
        inst.AnimState:PushAnimation("idle_water")
    else
        inst.AnimState:PushAnimation("idle")
    end

    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4 + math.random() * 5, shine)
    end
end

local function onwake(inst)
    inst.task = inst:DoTaskInTime(4 + math.random() * 5, shine)
end

local function MakeOinc(name, build, value)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddPhysics()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "idle_water", "idle")
        MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

        inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )

        inst.AnimState:SetBank("coin")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("molebait")
        inst:AddTag("oinc")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
        inst.components.edible.hungervalue = 1

        inst:AddComponent("currency")

        inst:AddComponent("inspectable")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        -- inst:AddComponent("appeasement")
        -- inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_TINY

        inst:AddComponent("waterproofer")
        inst.components.waterproofer.effectiveness = 0
        inst:AddComponent("inventoryitem")

        inst:AddComponent("bait")
        inst.oincvalue = value

        inst:AddComponent("tradable")

        inst.OnEntityWake = onwake

        return inst
    end
    return Prefab(name, fn, assets)
end

return MakeOinc("oinc", "pig_coin", 1),
    MakeOinc("oinc10", "pig_coin_silver", 10),
    MakeOinc("oinc100", "pig_coin_jade", 100)

