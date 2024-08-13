local assets =
{
    Asset("ANIM", "anim/room_shelves.zip"),
    Asset("ANIM", "anim/room_shelves_front.zip"),
    Asset("ANIM", "anim/pedestal_crate.zip")
}

local function MakeObstacle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:AddWall(x, y, z)
end

local function GetSlotSymbol(inst, slot)
    return inst.anim_def.slot_symbol_prefix .. slot
end

local function Curse(inst)
    if math.random() < 0.3 then
        local ghost = SpawnPrefab("pigghost")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        ghost.Transform:SetPosition(pt.x,pt.y,pt.z)
    end
end

local function OnSave(inst, data)
    data.interiorID = inst.interiorID
end

local function OnLoad(inst, data)
    if data then
        if data.interiorID then
            inst.interiorID  = data.interiorID
        end
    end
end

local function CreateFrontVisual(inst, name, anim_def)
    local frontvisual = CreateEntity()
    --[[Non-networked entity]]
    frontvisual.entity:AddTransform()
    frontvisual.entity:AddAnimState()
    frontvisual.entity:AddFollower()

    frontvisual:AddTag("NOCLICK")
    frontvisual:AddTag("FX")
    frontvisual.entity:SetParent(inst.entity)
    frontvisual.persists = false
    frontvisual.Transform:SetTwoFaced()
    frontvisual.Transform:SetRotation(-90)

    frontvisual.AnimState:SetBuild(anim_def.build and anim_def.build .. "_front" or "room_shelves_front")
    frontvisual.AnimState:SetBank(anim_def.bank or "bookcase")
    local animation = anim_def.animation or name
    frontvisual.AnimState:PlayAnimation(animation)

    if anim_def.layer then
        frontvisual.AnimState:SetLayer(anim_def.layer)
    end
    if anim_def.order then
        frontvisual.AnimState:SetSortOrder(anim_def.order)
    end

    frontvisual.AnimState:SetFinalOffset(3)

    frontvisual.Follower:FollowSymbol(inst.GUID, nil, 0, 0, 0.002) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）

    return frontvisual
end

local function MakeShelf(name, physics_round, anim_def, slot_symbol_prefix, curse)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if physics_round then
            MakeObstaclePhysics(inst, .5)
            inst:DoTaskInTime(0, MakeObstacle)
        else
            -- MakeInteriorPhysics(inst, 2, 1, 0.5) -- 暂时取消这些贴边物体的碰撞体和寻路，以减少卡位的可能性
            -- inst:DoTaskInTime(0, MakeObstacle)
        end

        local animation = anim_def.animation or name

        inst.Transform:SetTwoFaced()
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

        inst.frontvisual = CreateFrontVisual(inst, name, anim_def)

        inst:DoStaticTaskInTime(0, function()
            inst.frontvisual.Follower:FollowSymbol(inst.GUID, nil, 0, 0, 0.0015) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）
        end)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        if physics_round then
            inst:AddComponent("gridnudger")
        end

        inst:AddComponent("container")
        inst.components.container:WidgetSetup("shelf_" .. name)
        inst.components.container.Open = function() end
        inst.components.container.skipopensnd = true

        inst:AddComponent("visualslotmanager")

        inst.Curse = curse

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

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
    MakeShelf("ruins", true, {animation = "ruins"}, nil, Curse)
