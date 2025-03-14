local assets =
{

}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:SetCanSleep(false)
    --[[Non-networked entity]]

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.persists = false

    return inst
end

return Prefab("group_child", fn, assets)
