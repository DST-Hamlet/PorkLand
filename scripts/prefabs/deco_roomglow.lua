local assets =
{

}

local prefabs =
{

}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()


    inst.Light:SetIntensity(0.8)
    inst.Light:SetColour(98.5 / 255, 98.5 / 255, 25 / 255)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(6)
    inst.Light:Enable(true)

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function fn_large()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()


    inst.Light:SetIntensity(0.8)
    inst.Light:SetColour(98.5 / 255, 98.5 / 255, 25 / 255)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(9)
    inst.Light:Enable(true)


    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("deco_roomglow", fn, assets, prefabs),
       Prefab("deco_roomglow_large", fn_large, assets, prefabs)
