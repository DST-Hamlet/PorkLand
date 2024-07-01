local assets =
{
    Asset("ANIM", "anim/rugs.zip"),
    Asset("ANIM", "anim/interior_wall_decals_mayorsoffice.zip"),
    Asset("ANIM", "anim/interior_wall_decals_palace.zip"),
}

local prefabs =
{
}

local function OnWorkCallback(inst, worker, work_left)
    if work_left > 0 then
        return
    end

    if inst.components.lootdropper then
        inst.components.lootdropper:DropLoot()
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_small")
    fx:SetMaterial("wood")
    fx.Transform:SetPosition(x, y, z)

    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    end

    inst:Remove()
end

local function SetPlayerUncraftable(inst)
    inst.entity:AddSoundEmitter()

    inst:RemoveTag("NOCLICK")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()
    if inst.onbuilt then
        data.onbuilt = inst.onbuilt
    end
end

local function OnLoad(inst, data)
    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end
    if data.onbuilt then
        SetPlayerUncraftable(inst)
        inst.onbuilt = data.onbuilt
    end
end

local function OnBuilt(inst)
    SetPlayerUncraftable(inst)
    inst.onbuilt = true
end

local function MakeRug(rug_type)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild("rugs")
        inst.AnimState:SetBank("rugs")
        inst.AnimState:PlayAnimation(rug_type, true)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst:AddTag("OnFloor")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        inst:ListenForEvent("onbuilt", OnBuilt)

        return inst
    end

    return Prefab(rug_type, fn, assets, prefabs)
end

local function porcupus()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBuild("rugs")
    inst.AnimState:SetBank("rugs")
    inst.AnimState:PlayAnimation("rug_porcupuss")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("OnFloor")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("onbuilt", OnBuilt)

    return inst
end

local function cityhall_corners()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("interior_wall_decals_mayorsoffice")
    inst.AnimState:SetBank("wall_decals_mayorsoffice")
    inst.AnimState:PlayAnimation("corner_back", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function palace_corners()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("interior_wall_decals_palace")
    inst.AnimState:SetBank("wall_decals_palace")
    inst.AnimState:PlayAnimation("floortrim_corner", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return MakeRug("rug_round"),
       MakeRug("rug_oval"),
       MakeRug("rug_square"),
       MakeRug("rug_rectangle"),
       MakeRug("rug_leather"),
       MakeRug("rug_fur"),
       MakeRug("rug_circle"),
       MakeRug("rug_hedgehog"),
       MakeRug("rug_hoofprint"),
       MakeRug("rug_octagon"),
       MakeRug("rug_swirl"),
       MakeRug("rug_catcoon"),
       MakeRug("rug_rubbermat"),
       MakeRug("rug_web"),
       MakeRug("rug_metal"),
       MakeRug("rug_wormhole"),
       MakeRug("rug_braid"),
       MakeRug("rug_beard"),
       MakeRug("rug_nailbed"),
       MakeRug("rug_crime"),
       MakeRug("rug_tiles"),
       MakeRug("rug_palace_runner"),

       Prefab("rug_porcupuss", porcupus, assets, prefabs),
       Prefab("rug_cityhall_corners", cityhall_corners, assets, prefabs),
       Prefab("rug_palace_corners", palace_corners, assets, prefabs)
