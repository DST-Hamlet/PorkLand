local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:SetCanSleep(false)
    --[[Non-networked entity]]

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED") -- 不应被非自身机制移除的实体

    inst.persists = false

    return inst
end

return Prefab("group_parent", fn)
