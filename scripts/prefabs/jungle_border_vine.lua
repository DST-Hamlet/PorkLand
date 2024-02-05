local assets =
{
    Asset("ANIM", "anim/vines_rainforest_border.zip"),
}

local function onsave(inst, data)
    data.animchoice = inst.animchoice
end

local function onload(inst, data)
    if data and data.animchoice then
        inst.animchoice = data.animchoice
        inst.AnimState:PlayAnimation("idle_" .. inst.animchoice)
    end
end

local function plantfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.animchoice = math.random(1, 6)
    local color = 0.7 + math.random() * 0.3
    inst.AnimState:SetBank("vines_rainforest_border")
    inst.AnimState:SetBuild("vines_rainforest_border")
    inst.AnimState:SetMultColour(color, color, color, 1)
    inst.AnimState:PlayAnimation("idle_" .. inst.animchoice)

    inst:AddTag("NOCLICK")

    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15,25)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("forest/objects/jungle_border_vine", plantfn, assets)
