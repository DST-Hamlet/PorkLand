local function init(inst)
    MakeInteriorWallPhysics(inst, inst.width:value(), nil, inst.depth:value())
    inst.Physics:SetActive(true)
end

local function fn_long()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()

    inst.Physics:SetDontRemoveOnSleep(true)
    inst.Physics:SetActive(false)

    inst:AddTag("wall")
    inst:AddTag("noauradamage")
    inst:AddTag("pl_invisiblewall")
    inst:AddTag("NOBLOCK")

    inst.width = net_float(inst.GUID, "width", "width")
    inst.depth = net_float(inst.GUID, "depth", "depth")

    inst:DoTaskInTime(2 * FRAMES, init)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("invisiblewall_long", fn_long)

