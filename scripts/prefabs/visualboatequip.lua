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

        inst:DoTaskInTime(0,function()
            inst.boat = inst.entity:GetParent()
            inst.boat.boatvisuals[inst] = true
            inst:SetVisual(inst.boat)

            inst:StartUpdatingComponent(inst.components.boatvisualanims)

            if onreplicate then
                onreplicate(inst)
            end
        end)
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

        if inst.commonfn then
            inst:commonfn()
        end

        local startanim = "idle_loop"
        local startanimframe
        if boat.replica.sailable._currentboatanim and boat.replica.sailable._currentboatanim:value() ~= "" then
            startanim = boat.replica.sailable._currentboatanim:value()
        end

        startanimframe = 0
        for k, v in pairs(boat.boatvisuals) do
            if k ~= inst and k.visualchild and k.visualchild.AnimState then
                if k.visualchild.AnimState:IsCurrentAnimation("idle_loop") then
                    startanim = "idle_loop"
                end
                if k.visualchild.AnimState:IsCurrentAnimation("run_loop") then
                    startanim = "run_loop"
                end
                startanimframe = k.visualchild.AnimState:GetCurrentAnimationFrame()
                break
            end
        end

        if startanim == "idle_loop_push" then
            inst.visualchild.AnimState:PlayAnimation("idle_loop", true)
        elseif startanim == "run_loop_push" then
            inst.visualchild.AnimState:PlayAnimation("run_loop", true)
        elseif startanim == "idle_loop" or
            startanim == "run_loop" or
            startanim == "row_loop" or
            startanim == "sail_loop" then
            inst.visualchild.AnimState:PlayAnimation(startanim, true)
        else
            inst.visualchild.AnimState:PlayAnimation(startanim)
        end
        print(startanim,startanimframe)
        inst.visualchild.AnimState:SetFrame(startanimframe)

        if TheWorld.ismastersim then
            if inst.masterfn then
                inst:masterfn()
            end
        end

        inst:StartUpdatingComponent(inst.components.boatvisualanims)

    end

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
