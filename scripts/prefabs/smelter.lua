local assets =
{
    Asset("ANIM", "anim/smelter.zip"),
}

local prefabs =
{
    "collapse_small",
}

local function getstatus(inst)  -- we no character string
    return (inst:HasTag("burnt") and "BURNT")
        or (inst.components.stewer:IsDone() and "DONE")
        or (not inst.components.stewer:IsCooking() and "EMPTY")
        -- or (inst.components.stewer:GetTimeToCook() > 15 and "COOKING_LONG")
        or "COOKING_SHORT"
end

local function ShowProduct(inst)
    if not inst:HasTag("burnt") then
        local product = inst.components.stewer.product
        inst.AnimState:OverrideSymbol("swap_item", product, product)
    end
end

local function startcookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("smelting_pre")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/smelter/move_1")
        inst.AnimState:PushAnimation("smelting_loop", true)
        -- play a looping sound
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/smelt_LP", "snd")
        inst.Light:Enable(true)
    end
end

local function continuecookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("smelting_loop", true)
        -- play a looping sound
        inst.Light:Enable(true)

        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/smelt_LP", "snd")
    end
end

local function donecookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("smelting_pst")
        inst.AnimState:PushAnimation("idle_full")
        ShowProduct(inst)
        inst.SoundEmitter:KillSound("snd")
        inst.Light:Enable(false)
        inst:DoTaskInTime(FRAMES, function()
            if inst.AnimState:IsCurrentAnimation("smelting_pst") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_1")
            end
        end)
        inst:DoTaskInTime(8 * FRAMES, function()
            if inst.AnimState:IsCurrentAnimation("smelting_pst") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_2")
            end
        end)
        inst:DoTaskInTime(14 * FRAMES, function()
            if inst.AnimState:IsCurrentAnimation("smelting_pst") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/pour")
            end
        end)
        inst:DoTaskInTime(31 * FRAMES, function()
            if inst.AnimState:IsCurrentAnimation("smelting_pst") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/steam")
            end
        end)
        inst:DoTaskInTime(36 * FRAMES, function()
            if inst.AnimState:IsCurrentAnimation("smelting_pst") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/brick")
            end
        end)
        inst:DoTaskInTime(49 * FRAMES, function()
            if inst.AnimState:IsCurrentAnimation("smelting_pst") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_2")
            end
        end)
        -- play a one-off sound
    end
end

local function harvestfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("idle_empty")
    end
end

local function spoilfn(inst)
    if not inst:HasTag("burnt") then
        inst.components.stewer.product = inst.components.stewer.spoiledproduct
        ShowProduct(inst)
    end
end

local function continuedonefn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("idle_full")
        ShowProduct(inst)
    end
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        -- inst.AnimState:PlayAnimation("smelting_pre")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_3", "open")
        -- inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        if not inst.components.stewer:IsCooking() then
            inst.AnimState:PlayAnimation("idle_empty")
            inst.SoundEmitter:KillSound("snd")
        end
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_3", "close")
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_empty")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/build")
    inst:DoTaskInTime(FRAMES, function()
        if inst.AnimState:IsCurrentAnimation("place") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/brick")
        end
    end)
    inst:DoTaskInTime(4 * FRAMES, function()
        if inst.AnimState:IsCurrentAnimation("place") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/brick")
        end
    end)
    inst:DoTaskInTime(8 * FRAMES, function()
        if inst.AnimState:IsCurrentAnimation("place") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/brick")
        end
    end)
    inst:DoTaskInTime(12 * FRAMES, function()
        if inst.AnimState:IsCurrentAnimation("place") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/brick")
        end
    end)
    inst:DoTaskInTime(14 * FRAMES, function()
        if inst.AnimState:IsCurrentAnimation("place") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/brick")
        end
    end)
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    if not inst:HasTag("burnt") and inst.components.stewer.product ~= nil and inst.components.stewer:IsDone() then
        inst.components.stewer:Harvest()
    end

    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.stewer:IsCooking() then
            inst.AnimState:PlayAnimation("hit_smelting")
            inst.AnimState:PushAnimation("smelting_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_3", "close")
        elseif inst.components.stewer:IsDone() then
            inst.AnimState:PlayAnimation("hit_full")
            inst.AnimState:PushAnimation("idle_full", false)
        else
            if inst.components.container ~= nil and inst.components.container:IsOpen() then
                inst.components.container:Close()
                -- onclose will trigger sfx already
            else
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/smelter/move_3", "close")
            end

            inst.AnimState:PlayAnimation("hit_empty")
            inst.AnimState:PushAnimation("idle_empty", false)
        end
    end
end

local function returntointeriorscene(inst)
    if inst.components.stewer and inst.components.stewer:IsCooking() then
        inst.Light:Enable(true)
    else
        inst.Light:Enable(false)
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
        inst.Light:Enable(false)
    end
end

-- local function onFloodedStart(inst)
--     if inst.components.container then
--         inst.components.container.canbeopened = false
--     end
--     if inst.components.stewer then
--         if inst.components.stewer:IsCooking() then
--             inst.components.stewer.product = "wetgoop"
--         end
--     end
-- end

-- local function onFloodedEnd(inst)
--     if inst.components.container then
--         inst.components.container.canbeopened = true
--     end
-- end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("smelter.tex")

    inst.Light:Enable(false)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235 / 255, 62 / 255, 12 / 255)

    inst:AddTag("structure")
    inst:AddTag("stewer")  -- stewer (from stewer component) added to pristine state for optimization
    inst:AddTag("smelter")

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("smelter")
    inst.AnimState:SetBuild("smelter")
    inst.AnimState:PlayAnimation("idle_empty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("lootdropper")

    inst:AddComponent("stewer")
    inst.components.stewer.spoiledproduct = "alloy"
    inst.components.stewer.onstartcooking = startcookfn
    inst.components.stewer.oncontinuecooking = continuecookfn
    inst.components.stewer.oncontinuedone = continuedonefn
    inst.components.stewer.ondonecooking = donecookfn
    inst.components.stewer.onharvest = harvestfn
    inst.components.stewer.onspoil = spoilfn

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("smelter")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    -- inst:AddComponent("floodable")
    -- inst.components.floodable.onStartFlooded = onFloodedStart
    -- inst.components.floodable.onStopFlooded = onFloodedEnd
    -- inst.components.floodable.floodEffect = "shock_machines_fx"
    -- inst.components.floodable.floodSound = "dontstarve_DLC002/creatures/jellyfish/electric_land"

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)

    MakeSnowCovered(inst, .01)
	MakeMediumBurnable(inst, nil, nil, true)
	MakeSmallPropagator(inst)

	inst.returntointeriorscene = returntointeriorscene
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("smelter", fn, assets, prefabs),
    MakePlacer("smetler_placer", "smelter", "smelter", "idle_empty")
