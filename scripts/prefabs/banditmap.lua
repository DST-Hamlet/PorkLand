local assets =
{
    Asset("ANIM", "anim/messagebottle.zip"),
    Asset("ANIM", "anim/stash_map.zip"),
    Asset("ANIM", "anim/x_marks_spot_bandit.zip"),
}

local function GetRevealTarget(inst, doer)
    if not inst.treasure and inst.unique_id then
        inst.treasure = TheWorld.components.globalidentityinfo:GetRuntimeIndentityInfo(inst.unique_id).bandit_treasure
    end
    if inst.treasure and inst.treasure:IsValid() then
        return inst.treasure:GetPosition()
    else
        return nil, "ANNOUNCE_MESSAGEBOTTLE"
    end
end

local function OnRead(inst, targetpos)
    inst.components.inventoryitem:RemoveFromOwner(true)
    inst:Remove()
end

local function MapOnSave(inst, data)
    local refs = {}

    if inst.unique_id then
        data.unique_id = inst.unique_id
    end

    if inst.treasure then
        data.treasure = inst.treasure.GUID
        table.insert(refs, inst.treasure.GUID)
    end
    data.message = inst.message

    return refs
end

local function MapOnLoadPostPass(inst, newents, data)
    if not data then
        return
    end

    if data.treasure and newents[data.treasure] then
        inst.treasure = newents[data.treasure].entity
    end
    inst.message = data.message
end

local function MapOnLoad(inst, data)
    if not data then
        return
    end

    if data and data.unique_id then
        inst.unique_id = data.unique_id
    end
end

local function MapOnRemove(inst)
    if inst.treasure and inst.treasure:IsValid() and not inst.treasure.revealed then
        inst.treasure:Remove()
    end
end

local function banditmapfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("stash_map")
    inst.AnimState:SetBuild("stash_map")
    inst.AnimState:PlayAnimation("idle")

    -- waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")
    inst:AddTag("treasuremap")

    inst.no_wet_prefix = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("stash_map")

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("mapspotrevealer")
    inst.components.mapspotrevealer:SetGetTargetFn(GetRevealTarget)

    inst:AddComponent("erasablepaper")

    inst.treasure = nil

    inst.OnSave = MapOnSave
    inst.OnLoadPostPass = MapOnLoadPostPass
    inst.OnLoad = MapOnLoad

    inst:ListenForEvent("onremove", MapOnRemove)
    inst:ListenForEvent("on_reveal_map_spot_pre", function()
        inst.treasure:PushEvent("reveal")
    end)
    inst:ListenForEvent("on_reveal_map_spot_pst", OnRead)

    return inst
end

local function GetStatus(inst)
    if not inst.components.workable then
        return "DUG"
    end
end

local function TreasureOnSave(inst, data)
    if inst.unique_id then
        data.unique_id = inst.unique_id
    end

    if not inst.components.workable then
        data.dug = true
    end

    if inst.revealed then
        data.revealed = inst.revealed
    end
end

local function TreasureOnLoad(inst, data)
    if data and data.unique_id then
        inst.unique_id = data.unique_id
        TheWorld.components.globalidentityinfo:GetRuntimeIndentityInfo(inst.unique_id).bandit_treasure = inst
    end

    if data and data.dug or not inst.components.workable then
        inst:RemoveComponent("workable")
        inst:RemoveTag("NOCLICK")
    end

    if data and data.revealed == true then
        inst:PushEvent("reveal")
    end
end

local function SpawnTreasureChest(pt)
    local chest = SpawnPrefab("treasurechest")

    chest.Transform:SetPosition(pt.x, pt.y, pt.z)
    SpawnPrefab("collapse_small").Transform:SetPosition(pt.x, pt.y, pt.z)

    local loot_prefabs = TheWorld.components.banditmanager:GetLoot()

    for prefab, num_loot in pairs(loot_prefabs) do
        if num_loot > 0 then
            local loot = SpawnPrefab(prefab)
            if loot.components.stackable then
                loot.components.stackable:SetStackSize(num_loot)
            end

            chest.components.container:GiveItem(loot, nil, nil, true)
        end
    end

    TheWorld:PushEvent("bandittreasure_dug")
end

local function OnFinishCallback(inst, worker)
    inst.MiniMapEntity:SetEnabled(false)
    inst:RemoveComponent("workable")

    if worker then
        -- figure out which side to drop the loot
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local hispos = Vector3(worker.Transform:GetWorldPosition())

        local he_right = ((hispos - pt):Dot(TheCamera:GetRightVec()) > 0)

        if he_right then
            inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec() * (math.random() + 1)))
            inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec() * (math.random() + 1)))
        else
            inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec() * (math.random() + 1)))
            inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec() * (math.random() + 1)))
        end

        SpawnTreasureChest(Point(inst.Transform:GetWorldPosition()))
        inst:Remove()
    end
end

local function AfterBlink(inst)
    if inst.blink_task then
        inst.blink_task:Cancel()
        inst.blink_task = nil
    end

    inst.AnimState:PlayAnimation("idle")
    inst.blink_task = inst:DoTaskInTime(math.random() * 2 + 1, inst.blink)
end

local function Blink(inst)
    if inst.blink_task then
        inst.blink_task:Cancel()
        inst.blink_task = nil
    end
    inst.AnimState:PlayAnimation("blink")

    inst.blink_task = inst:DoTaskInTime(30 / 10, inst.after_blink)
end

local function bandittreasurefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("x_marks_spot_bandit")
    inst.AnimState:SetBuild("x_marks_spot_bandit")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("xspot.tex")
    inst.MiniMapEntity:SetEnabled(false)

    inst:AddTag("buriedtreasure")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function()
        if inst.unique_id then
            TheWorld.components.globalidentityinfo:GetRuntimeIndentityInfo(inst.unique_id).bandit_treasure = inst
        end
    end)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"peagawkfeather"})

    inst:ListenForEvent("reveal", function()
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnFinishCallback)

        inst:Show()
        inst.MiniMapEntity:SetEnabled(true)
        inst:RemoveTag("NOCLICK")
        inst.revealed = true
    end)

    inst.revealed = false

    inst.OnSave = TreasureOnSave
    inst.OnLoad = TreasureOnLoad

    inst.blink = Blink
    inst.after_blink = AfterBlink
    AfterBlink(inst)

    inst:Hide()

    return inst
end

return Prefab("banditmap", banditmapfn, assets),
       Prefab("bandittreasure", bandittreasurefn, assets)
