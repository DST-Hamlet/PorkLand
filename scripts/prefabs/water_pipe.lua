local assets =
{
    Asset("ANIM", "anim/sprinkler_pipes.zip")
}

local prefabs =
{
}

local function HideLayers(inst)
    local num_ray = 3
    for i = 1, num_ray do
        inst.AnimState:Hide("joint" .. i)
        inst.AnimState:Hide("pipe" .. i)
    end
end

local function ShowRandomLayers(inst)
    if not inst.joint_layer_shown then
        inst.joint_layer_shown = "joint" .. math.random(1, 3)
    end

    if not inst.pipe_layer_shown then
        inst.pipe_layer_shown = "pipe" .. math.random(1, 3)
    end

    inst.AnimState:Show(inst.joint_layer_shown)
    inst.AnimState:Show(inst.pipe_layer_shown)
end

local function OnSave(inst, data)
    data.joint_layer_shown = inst.joint_layer_shown
    data.pipe_layer_shown = inst.pipe_layer_shown
end

local function OnLoad(inst, data)
    inst.joint_layer_shown = data.joint_layer_shown
    inst.pipe_layer_shown = data.pipe_layer_shown

    HideLayers(inst)
    inst.AnimState:Show(inst.joint_layer_shown)
    inst.AnimState:Show(inst.pipe_layer_shown)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("sprinkler_pipes")
    inst.AnimState:SetBuild("sprinkler_pipes")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    HideLayers(inst)
    ShowRandomLayers(inst)

    inst:SetStateGraph("SGwater_pipe")

    return inst
end

return Prefab("water_pipe", fn, assets, prefabs)
