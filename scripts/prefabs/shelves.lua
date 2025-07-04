local assets =
{
    Asset("ANIM", "anim/room_shelves.zip"),
    Asset("ANIM", "anim/room_shelves_front.zip"),
    Asset("ANIM", "anim/pedestal_crate.zip"),
    Asset("ANIM", "anim/pedestal_crate_cloche.zip"),
    Asset("ANIM", "anim/pedestal_crate_cost.zip"),
    Asset("ANIM", "anim/pedestal_crate_lock.zip"),
}

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            TheWorld.Pathfinder:AddWall(inst._pfpos:Get())
        end
    elseif inst._pfpos ~= nil then
        TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get())
        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function MakeObstacle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:AddWall(x, y, z)
end

local function OnRemove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

local function GetSlotSymbol(inst, slot)
    return inst.anim_def.slot_symbol_prefix .. slot
end

local function Curse(inst)
    if math.random() < 0.3 then
        local ghost = SpawnPrefab("pigghost")
        local x, y, z = inst.Transform:GetWorldPosition()
        ghost.Transform:SetPosition(x, y, z)
    end
end

local function OnFinish(inst, worker, workleft)
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())

    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    if inst.components.lootdropper then
        inst.components.lootdropper:DropLoot()
    end

    inst:Remove()
end

local function SetPlayerCraftable(inst)
    inst:AddTag("playercrafted")
    inst:RemoveTag("NOCLICK")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnFinish)
end

local function InitInteriorPrefab(inst)
    if inst:HasTag("playercrafted") then
        SetPlayerCraftable(inst)
    end
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()
    data.interiorID = inst.interiorID
    data.playercrafted = inst:HasTag("playercrafted")
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.rotation then
        if inst.components.rotatingbillboard == nil then
            -- this component handle rotation save/load itself
            inst.Transform:SetRotation(data.rotation)
        end
    end
    if data.interiorID then
        inst.interiorID  = data.interiorID
    end
    if data.playercrafted then
        SetPlayerCraftable(inst)
    end
end

local function CreateFrontVisual(inst, name, anim_def) -- 柜子前方用于遮挡的图片
    local frontvisual = SpawnPrefab("shelves_frontvisual")
    if anim_def.is_pedestal then
        frontvisual.AnimState:SetBuild(anim_def.build and anim_def.build .. "_cloche" or "pedestal_crate_cloche")
        frontvisual.AnimState:SetBank(anim_def.bank or "pedestal")
    else
        frontvisual.AnimState:SetBuild(anim_def.build and anim_def.build .. "_front" or "room_shelves_front")
        frontvisual.AnimState:SetBank(anim_def.bank or "bookcase")
    end
    local animation = anim_def.animation or name
    frontvisual.AnimState:PlayAnimation(animation)

    if anim_def.layer then
        frontvisual.AnimState:SetLayer(anim_def.layer)
    end
    if anim_def.order then
        frontvisual.AnimState:SetSortOrder(anim_def.order)
    end

    frontvisual.AnimState:SetFinalOffset(3)

    frontvisual.parentshelf = inst
    frontvisual.entity:SetParent(inst.entity)
    return frontvisual
end

local function frontvisual_fn(inst, name, anim_def)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.persists = false
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetFinalOffset(3)
    return inst
end

local function CreateLockVisual(inst, name, anim_def) -- 柜子前方用于遮挡的图片
    local lockvisual = SpawnPrefab("shelves_lockvisual")

    local animation = anim_def.animation or name
    lockvisual.AnimState:PlayAnimation(animation)

    if anim_def.layer then
        lockvisual.AnimState:SetLayer(anim_def.layer)
    end
    if anim_def.order then
        lockvisual.AnimState:SetSortOrder(anim_def.order)
    end

    lockvisual.AnimState:SetFinalOffset(4)

    lockvisual.parentshelf = inst
    lockvisual.entity:SetParent(inst.entity)
    return lockvisual
end

local function lockvisual_fn() -- 锁
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.persists = false

    inst.AnimState:SetBuild("pedestal_crate_lock")
    inst.AnimState:SetBank("pedestal")
    inst.AnimState:PlayAnimation("idle")
    return inst
end

local function OnVisualChange(inst)
    local frontvisual = inst._frontvisual and inst._frontvisual:value() or nil
    local lockvisual = inst._lockvisual and inst._lockvisual:value() or nil
    inst.highlightchildren = {}
    if frontvisual then
        table.insert(inst.highlightchildren, frontvisual)
    end
    if lockvisual then
        table.insert(inst.highlightchildren, lockvisual)
    end
end

local function IsHighPriorityAction(act, force_inspect)
    return act and act.action == ACTIONS.HAMMER
end

local function CanMouseThrough(inst)
    if not inst:HasTag("fire") and ThePlayer ~= nil and ThePlayer.components.playeractionpicker ~= nil then
        local force_inspect = ThePlayer.components.playercontroller ~= nil and ThePlayer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT)
        local lmb, rmb = ThePlayer.components.playeractionpicker:DoGetMouseActions(inst:GetPosition(), inst)
        return not IsHighPriorityAction(rmb, force_inspect)
    end
end

local function MakeShelf(name, physics_round, anim_def, slot_symbol_prefix, on_robbed, master_postinit)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if physics_round then
            inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
            MakeObstaclePhysics(inst, .5)
            inst:DoTaskInTime(0, InitializePathFinding)

            inst:ListenForEvent("onremove", OnRemove)
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

        if anim_def.has_front then
            inst._frontvisual = net_entity(inst.GUID, "_frontvisual", "frontvisualdirty")
        end

        if anim_def.is_pedestal then
            inst._lockvisual = net_entity(inst.GUID, "_lockvisual", "lockvisualdirty")
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

        if anim_def.name then
            inst.name = anim_def.name
        end

        inst.CanMouseThrough = CanMouseThrough

        if name:find("queen") then
            inst.name = STRINGS.NAMES.ROYAL_GALLERY
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst:ListenForEvent("frontvisualdirty", OnVisualChange)
            inst:ListenForEvent("lockvisualdirty", OnVisualChange)
            return inst
        end

        if anim_def.has_front then
            inst.frontvisual = CreateFrontVisual(inst, name, anim_def)
            inst._frontvisual:set(inst.frontvisual)
        end

        if anim_def.is_pedestal then
            inst.lockvisual = CreateLockVisual(inst, name, anim_def)
            inst._lockvisual:set(inst.lockvisual)
        end

        inst:DoStaticTaskInTime(0, function()
            if inst.frontvisual then
                inst.frontvisual.Follower:FollowSymbol(inst.GUID, nil, 0, 0, 0.0015) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）
            end
            if inst.lockvisual then
                inst.lockvisual.Follower:FollowSymbol(inst.GUID, nil, 0, 0, 0.002) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）
            end
        end)

        inst.highlightchildren = {}
        if inst.frontvisual then
            table.insert(inst.highlightchildren, inst.frontvisual)
        end
        if inst.lockvisual then
            table.insert(inst.highlightchildren, inst.lockvisual)
        end

        inst:AddComponent("inspectable")

        if physics_round then
            inst:AddComponent("gridnudger")
        end

        inst:AddComponent("container")
        inst.components.container:WidgetSetup("shelf_" .. name)
        inst.components.container.Open = function() end
        inst.components.container.canbeopened = false
        inst.components.container.skipopensnd = true

        inst:AddComponent("visualslotmanager")

        if on_robbed then
            inst:AddComponent("shopped")
            inst.components.shopped:SetOnRobbed(on_robbed)
        end

        MakeHauntable(inst)

        inst:ListenForEvent("onbuilt", SetPlayerCraftable)
        inst.initInteriorPrefab = InitInteriorPrefab

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        if master_postinit then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab("shelf_" .. name, fn, assets)
end

local function OnLock(inst)
    inst.AnimState:Show("LOCK")
    if inst.lockvisual then
        inst.lockvisual.AnimState:Show("LOCK")
    end
    inst:AddTag("locked")
    inst:RemoveTag("NOCLICK")
    inst.components.visualslotmanager:SetCanClick(false)
end

local function OnUnlock(inst, key, doer)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/royal_gallery/unlock")
    inst.AnimState:Hide("LOCK")
    if inst.lockvisual then
        inst.lockvisual.AnimState:Hide("LOCK")
    end
    inst:RemoveTag("locked")
    inst:AddTag("NOCLICK")
    inst.components.visualslotmanager:SetCanClick(true)
end

local function MakeLock(inst)
    inst:AddComponent("lock")
    inst.components.lock.locktype = LOCKTYPE.ROYAL
    inst.components.lock:SetOnLockedFn(OnLock)
    inst.components.lock:SetOnUnlockedFn(OnUnlock)
    inst.components.lock.islocked = false
    inst.components.lock:SetLocked(true)

    inst.components.inspectable.nameoverride = "royal_gallery"
end

return MakeShelf("wood", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("basic", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("metal", false, {animation = "metalcrates", layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("marble", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("glass", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("ladder", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("hutch", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("industrial", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("adjustable", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("fridge", false, {layer = LAYER_WORLD_BACKGROUND, order = 3, has_front = true}),
    MakeShelf("cinderblocks", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("midcentury", false, {layer = LAYER_WORLD_BACKGROUND, order = 3, has_front = true}),
    MakeShelf("wallmount", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("aframe", false, {layer = LAYER_WORLD_BACKGROUND, order = 3, has_front = true}),
    MakeShelf("crates", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    -- MakeShelf("hooks", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("pipe", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("hattree", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("pallet", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("floating", false, {layer = LAYER_WORLD_BACKGROUND, order = 3}),
    MakeShelf("displaycase_wood", true, {animation = "displayshelf_wood", has_front = true}),
    MakeShelf("displaycase_metal", true, {animation = "displayshelf_metal", has_front = true}),
    MakeShelf("queen_display_1", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock19_east", is_pedestal = true, name = STRINGS.NAMES.ROYAL_GALLERY, has_front = true}, "SWAP_SIGN", nil, MakeLock),
    MakeShelf("queen_display_2", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock17_east", is_pedestal = true, name = STRINGS.NAMES.ROYAL_GALLERY, has_front = true}, "SWAP_SIGN", nil, MakeLock),
    MakeShelf("queen_display_3", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock12_west", is_pedestal = true, name = STRINGS.NAMES.ROYAL_GALLERY, has_front = true}, "SWAP_SIGN", nil, MakeLock),
    MakeShelf("queen_display_4", true, {build = "pedestal_crate", bank = "pedestal", animation = "lock12_west", is_pedestal = true, name = STRINGS.NAMES.ROYAL_GALLERY, has_front = true}, "SWAP_SIGN", nil, MakeLock),
    MakeShelf("ruins", true, {animation = "ruins"}, nil, Curse),
    Prefab("shelves_lockvisual", lockvisual_fn, assets),
    Prefab("shelves_frontvisual", frontvisual_fn, assets)
