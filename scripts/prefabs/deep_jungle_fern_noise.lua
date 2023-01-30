local assets =
{
    Asset("ANIM", "anim/fern_plant.zip"),
    Asset("ANIM", "anim/fern2_plant.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    -- only for worldgen
    --[[Non-networked entity]]

    inst:DoTaskInTime(0, inst.Remove)

    return inst
end

local function onsave(inst, data)
    data.anim_name = inst.anim_name
end

local function onload(inst, data)
    if data and data.anim_name then
        inst.anim_name = data.anim_name
        inst.AnimState:PlayAnimation(inst.anim_name)
    end
end

local function plantfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    local color = 0.7 + math.random() * 0.3
    inst.AnimState:SetBank("fern_plant")
    inst.AnimState:SetBuild("fern_plant")
    inst.AnimState:SetMultColour(color, color, color, 1)

    if math.random() < 0.5 then
        inst.anim_name = "idle"
    else
        inst.anim_name = "idle2"
    end
    inst.AnimState:PlayAnimation(inst.anim_name)
    -- inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("NOCLICK")
    inst:AddTag("fern_plant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("forest/objects/deep_jungle_fern_noise", fn, assets),
       Prefab("forest/objects/deep_jungle_fern_noise_plant", plantfn, assets)
