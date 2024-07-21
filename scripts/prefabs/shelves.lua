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

local function GetSlotSymbol(inst, slot)
    return inst.anim_def.slot_symbol_prefix .. slot
end

local function MakeShelf(name, physics_round, anim_def, slot_num)
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

        inst.AnimState:SetBuild(anim_def.build or "room_shelves")
        inst.AnimState:SetBank(anim_def.bank or "bookcase")
        inst.AnimState:PlayAnimation(anim_def.animation, anim_def.loop)
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed) -- ds is ANIM_ORIENTATION.RotatingBillboard

        if anim_def.layer then
            inst.AnimState:SetLayer(anim_def.layer)
        end
        if anim_def.order then
            inst.AnimState:SetSortOrder(anim_def.order)
        end

        inst.anim_def = anim_def
        inst.anim_def.slot_bank = anim_def.animation .. "_visual_slot"
        inst.anim_def.slot_symbol_prefix = "SWAP_img"
        inst.GetSlotSymbol = GetSlotSymbol

        inst:AddTag("NOCLICK")
        inst:AddTag("wallsection")
        inst:AddTag("furniture")
        inst:AddTag("shelf")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("container")
        inst.components.container:WidgetSetup("shelf_" .. name)
        inst.components.container.Open = function() end
        inst.components.container.skipopensnd = true

        inst:AddComponent("visualslotmanager")

        return inst
    end

    return Prefab("shelf_" .. name, fn, assets)
end

return MakeShelf("wood", nil, {animation = "wood", layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("displayshelf_wood", true, {animation = "displayshelf_wood"}),
    MakeShelf("ruins", true, {animation = "ruins"})
