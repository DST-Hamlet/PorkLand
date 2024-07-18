local assets =
{
    Asset("ANIM", "anim/room_shelves.zip"),
}

local function MakeObstacle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:AddWall(x, y, z - 1)
    TheWorld.Pathfinder:AddWall(x, y, z)
    TheWorld.Pathfinder:AddWall(x, y, z + 1)
end

local function MakeShelf(name, physics_round, anim_data, slot_num)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if physics_round then
            MakeObstaclePhysics(inst, .5)
        else
            MakeInteriorPhysics(inst, 1.6, 1, 0.2)
            inst:DoTaskInTime(0, MakeObstacle)
        end

        inst.Transform:SetRotation(-90)

        inst.AnimState:SetBuild(anim_data.build or "room_shelves")
        inst.AnimState:SetBank(anim_data.bank or "bookcase")
        inst.AnimState:PlayAnimation(anim_data.animation, anim_data.loop)
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed) -- ds is ANIM_ORIENTATION.RotatingBillboard

        if anim_data.layer then
            inst.AnimState:SetLayer(anim_data.layer)
        end
        if anim_data.order then
            inst.AnimState:SetSortOrder(anim_data.order)
        end

        inst:AddTag("NOCLICK")
        inst:AddTag("wallsection")
        inst:AddTag("furniture")
        inst:AddTag("shelf")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)
        inst.components.container.Open = function() end
        inst.components.container.skipopensnd = true

        inst:AddComponent("visualshelf")

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeShelf("shelf_wood", nil, {animation = "wood", layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("shelf_ruins", true, {animation = "ruins"})
