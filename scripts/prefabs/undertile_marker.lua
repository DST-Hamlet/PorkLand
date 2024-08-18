local assets =
{

}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("tilemarker")

    inst._tile = net_int(inst.GUID, "_tile")

    inst.persists = false

    return inst
end

return Prefab("undertile_marker", fn, assets)
