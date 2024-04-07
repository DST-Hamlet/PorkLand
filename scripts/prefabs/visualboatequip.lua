local function MakeVisualBoatEquip(name, assets, prefabs, commonfn, masterfn, onreplicate)
    local function WaitForRotationSync(inst)
        inst:Hide()
        inst:DoTaskInTime(0, inst.Show)
    end

    local function onremove(inst)
        inst.boat.boatvisuals[inst] = nil
    end

    local function OnEntityReplicated(inst)
        WaitForRotationSync(inst)

        inst.boat = inst.entity:GetParent()
        inst.boat.boatvisuals[inst] = true
        inst:ListenForEvent("onremove", onremove)

        inst:StartUpdatingComponent(inst.components.boatvisualanims)

        if onreplicate then
            onreplicate(inst)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst:AddTag("can_offset_sort_pos")

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.Transform:SetFourFaced()

        inst:AddTag("NOCLICK")
        inst:AddTag("FX")
        inst:AddTag("nointerpolate")

        inst:AddComponent("boatvisualanims")
        inst:AddComponent("highlightchild")

        if commonfn then
            commonfn(inst)
        end

        inst.entity:SetPristine()

        if TheWorld.ismastersim then
            if not TheNet:IsDedicated() then
                WaitForRotationSync(inst)
            end
        else
            inst.OnEntityReplicated = OnEntityReplicated
            return inst
        end

        -- inst:AddComponent("bloomer")
        inst:AddComponent("colouradder")
        inst:AddComponent("eroder")

        if masterfn then
            masterfn(inst)
        end

        inst.persists = false

        return inst
    end
    return Prefab("visual_" .. name .. "_boat", fn, assets, prefabs)
end

return MakeVisualBoatEquip
