local assets =
{
    Asset("ANIM", "anim/room_shelves.zip"),
    Asset("ANIM", "anim/pedestal_crate.zip")
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

local function MakeShelf(name, physics_round, anim_def, slot_symbol_prefix)
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

        local animation = anim_def.animation or name

        inst.Transform:SetRotation(-90)

        inst.AnimState:SetBuild(anim_def.build or "room_shelves")
        inst.AnimState:SetBank(anim_def.bank or "bookcase")
        inst.AnimState:PlayAnimation(animation)
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed) -- ds is ANIM_ORIENTATION.RotatingBillboard

        if anim_def.layer then
            inst.AnimState:SetLayer(anim_def.layer)
        end
        if anim_def.order then
            inst.AnimState:SetSortOrder(anim_def.order)
        end

        inst.AnimState:SetFinalOffset(-1)

        inst.anim_def = anim_def
        inst.anim_def.slot_bank = animation .. "_visual_slot"
        inst.anim_def.slot_symbol_prefix = slot_symbol_prefix or "SWAP_img"
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

return MakeShelf("wood", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("basic", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("metal", false, {animation = "metalcrates", layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("marble", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("glass", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("ladder", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("industrial", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("adjustable", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("fridge", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("cinderblocks", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("midcentury", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("wallmount", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("aframe", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("crates", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    -- MakeShelf("hooks", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("pipe", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("hattree", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("pallet", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("floating", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("displaycase_wood", true, {animation = "displayshelf_wood"}),
    MakeShelf("displaycase_metal", true, {animation = "displayshelf_metal"}),
    MakeShelf("queen_display_1", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock19_east"}, "SWAP_SIGN"),
    MakeShelf("queen_display_2", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock17_east"}, "SWAP_SIGN"),
    MakeShelf("queen_display_3", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock12_west"}, "SWAP_SIGN"),
    MakeShelf("queen_display_4", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock12_west"}, "SWAP_SIGN"),
    MakeShelf("ruins", true, {animation = "ruins"})
