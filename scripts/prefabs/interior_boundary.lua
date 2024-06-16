local function Debug(inst)
    inst.AnimState:SetBank("wall")
    inst.AnimState:SetBuild("wall_stone")
    inst.AnimState:PlayAnimation("broken")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()

    inst.Transform:SetEightFaced()

    MakeObstaclePhysics(inst, 0.5)
    inst.Physics:SetDontRemoveOnSleep(true)
    inst.Physics:SetActive(false)

    inst:AddTag("wall")
    inst:AddTag("noauradamage")
    inst:AddTag("pl_invisiblewall")
    inst:AddTag("NOBLOCK")

    inst:DoTaskInTime(0, function()
        -- TODO: remove this wall if not in interior
    end)

    inst:DoTaskInTime(0.5, function()
        TheWorld.Pathfinder:AddWall(inst:GetPosition():Get())
    end)

    inst:ListenForEvent("onremove", function()
        TheWorld.Pathfinder:RemoveWall(inst:GetPosition():Get())
    end)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.Debug = Debug
    inst.persists = false

    return inst
end

local function build_rectangle_collision_mesh(rad, height, width)
    local points = {
        Vector3(-width / 2, 0, -rad / 2),
        Vector3(width / 2, 0, -rad / 2),
        Vector3(width / 2, 0, rad / 2),
        Vector3(-width / 2, 0, rad / 2),
    }
    local triangles = {}
    local y0 = 0
    local y1 = height
    for i = 1, 4 do
        local p1 = points[i]
        local p2 = points[i == 4 and 1 or i + 1]

        table.insert(triangles, p1.x)
        table.insert(triangles, y0)
        table.insert(triangles, p1.z)

        table.insert(triangles, p1.x)
        table.insert(triangles, y1)
        table.insert(triangles, p1.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y0)
        table.insert(triangles, p2.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y0)
        table.insert(triangles, p2.z)

        table.insert(triangles, p1.x)
        table.insert(triangles, y1)
        table.insert(triangles, p1.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y1)
        table.insert(triangles, p2.z)
    end

    return triangles
end

local function MakeInteriorPhysics(inst, rad, height, width)
    height = height or 20

    inst:AddTag("blocker")
    inst.Physics = inst.Physics or inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetTriangleMesh(build_rectangle_collision_mesh(rad, height, width or rad))
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
end

local function init(inst)
    MakeInteriorPhysics(inst, inst.width:value(), nil, inst.depth:value())
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

    inst:DoTaskInTime(0.5, init)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return  Prefab("invisiblewall", fn),
        Prefab("invisiblewall_long", fn_long)

