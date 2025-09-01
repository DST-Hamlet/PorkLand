local function MakeVisualBoatEquipChild(name, assets, prefabs)
    local function childfn()
        local inst = CreateEntity()

        inst:AddTag("can_offset_sort_pos")

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.Transform:SetFourFaced()

        inst:AddTag("NOCLICK")
        inst:AddTag("FX")
        inst:AddTag("nointerpolate")

        inst:AddComponent("highlightchild")

        inst.entity:SetPristine()

        -- inst:AddComponent("bloomer")
        inst:AddComponent("colouradder")
        inst:AddComponent("eroder")

        inst.persists = false

        return inst
    end

    return Prefab("visual_" .. name .. "_boat_child", childfn, assets, prefabs)
end

------------------------------------------------------------------------------------------

local function OnEntityReplicated(inst)
    inst.finish_replicated = true

    local boat = inst.entity:GetParent()
    boat.boatvisuals[inst] = true
    if boat.finish_replicated then
        inst:SetVisual(boat)
    end
end

local function OnRemove(inst)
    inst.boat.boatvisuals[inst] = nil
end

local function SetVisual(inst, boat) -- 初始化动画数据函数。在服务器端，此函数会在实体生成完后调用。在客户端，此函数会在船实体与自身实体创建且数据同步完成后被调用
    inst.boat = boat

    inst:ListenForEvent("onremove", OnRemove)
    inst.visualchild = SpawnPrefab(inst.prefab .. "_child")
    inst.visualchild.entity:SetParent(inst.entity)
    if inst.boat then
        if inst.visualchild.components.highlightchild then
            inst.visualchild.components.highlightchild:SetOwner(inst.boat)
        end

        if inst.boat.components.colouradder then
            inst.boat.components.colouradder:AttachChild(inst.visualchild)
        end
        if inst.boat.components.eroder then
            inst.boat.components.eroder:AttachChild(inst.visualchild)
        end
    end

    if inst.setupfn then
        inst:setupfn()
    end

    local startanim = "run_loop"

    local visual_prefab = boat

    for k, v in pairs(boat.boatvisuals) do
        if k ~= inst and k.visualchild ~= nil then
            visual_prefab = k.visualchild
            break
        end
    end
    for animname, _ in pairs(BOAT_ANIM_IDS) do
        if visual_prefab.AnimState then
            if visual_prefab.AnimState:IsCurrentAnimation(animname) then
                startanim = animname
                break
            end
        end
    end

    if LOOP_BOAT_ANIMS[startanim] then
        inst.visualchild.AnimState:PlayAnimation(startanim, true)
    else
        inst.visualchild.AnimState:PlayAnimation(startanim)
    end
    
    local startanimframe = visual_prefab.AnimState:GetCurrentAnimationFrame() or 0
    inst.visualchild.AnimState:SetFrame(startanimframe)

    inst:StartUpdatingComponent(inst.components.boatvisualanims)
end

local function MakeVisualBoatEquip(name, assets, prefabs, setupfn, commonfn)
    local function fn()
        local inst = CreateEntity()

        inst:AddTag("can_offset_sort_pos")

        inst.entity:AddTransform()
        inst.entity:AddAnimState() --虽然它没用，但是删掉会出C层相关的bug
        inst.entity:AddNetwork()

        inst.Transform:SetFourFaced()

        inst:AddTag("NOCLICK")
        inst:AddTag("FX")
        inst:AddTag("nointerpolate")

        inst:AddComponent("boatvisualanims")

        inst.boat = nil

        inst.SetVisual = SetVisual
        inst.setupfn = setupfn

        if commonfn then
            commonfn(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnEntityReplicated
            return inst
        end

        inst.persists = false

        return inst
    end
    return Prefab("visual_" .. name .. "_boat", fn, assets, prefabs)
end

return {MakeVisualBoatEquip = MakeVisualBoatEquip,
    MakeVisualBoatEquipChild = MakeVisualBoatEquipChild}
