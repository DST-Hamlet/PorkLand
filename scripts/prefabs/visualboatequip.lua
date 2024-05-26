local function MakeVisualBoatEquipChild(name, assets, prefabs, commonfn, masterfn, onreplicate)
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

local function MakeVisualBoatEquip(name, assets, prefabs, commonfn, masterfn, onreplicate)
    local function WaitForRotationSync(inst)
        inst:Hide()
        inst:DoTaskInTime(0, inst.Show)
    end

    local function OnEntityReplicated(inst)
        WaitForRotationSync(inst)

        inst.boat = inst.entity:GetParent()
        inst.boat.boatvisuals[inst] = true
        inst:SetVisual(inst.boat)

        inst:StartUpdatingComponent(inst.components.boatvisualanims)

        if onreplicate then
            onreplicate(inst)
        end
    end

    local function OnRemove(inst)
        inst.boat.boatvisuals[inst] = nil
    end

    local function SetVisual(inst, boat)
        inst.boat = boat
        boat.boatvisuals[inst] = true
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

        inst:StartUpdatingComponent(inst.components.boatvisualanims)

        if inst.commonfn then
            inst:commonfn()
        end

        if TheWorld.ismastersim then
            if inst.masterfn then
                inst:masterfn()
            end
        end

    end

    local function fn()
        local inst = CreateEntity()

        inst:AddTag("can_offset_sort_pos")

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst.Transform:SetFourFaced()

        inst:AddTag("NOCLICK")
        inst:AddTag("FX")
        inst:AddTag("nointerpolate")

        inst:AddComponent("boatvisualanims")

        inst.boat = nil

        inst.SetVisual = SetVisual
        inst.commonfn = commonfn

        inst.entity:SetPristine()

        if TheWorld.ismastersim then
            if not TheNet:IsDedicated() then
                WaitForRotationSync(inst)
            end
        else
            inst.OnEntityReplicated = OnEntityReplicated
            return inst
        end

        inst.masterfn = masterfn

        inst.persists = false

        return inst
    end
    return Prefab("visual_" .. name .. "_boat", fn, assets, prefabs)
end

return {MakeVisualBoatEquip = MakeVisualBoatEquip,
    MakeVisualBoatEquipChild = MakeVisualBoatEquipChild}
