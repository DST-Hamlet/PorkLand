require("prefabutil")

local assets_ant =
{
    Asset("ANIM", "anim/ant_chest.zip"),
    Asset("ANIM", "anim/ant_chest_honey_build.zip"),
    Asset("ANIM", "anim/ant_chest_nectar_build.zip"),
    Asset("ANIM", "anim/ui_chest_3x3.zip"),
}

local prefabs_ant =
{
    "collapse_small",
}

local assets_cork =
{
    Asset("ANIM", "anim/treasure_chest_cork.zip"),
    Asset("ANIM", "anim/ui_thatchpack_1x4.zip"),
}

local prefabs_cork =
{
    "collapse_small",
}

local assets_root =
{
    Asset("ANIM", "anim/treasure_chest_roottrunk.zip"),
    Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),
}

local prefabs_root =
{
    "roottrunk_container",
    "collapse_small",
}

local function OnOpen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        if inst.prefab == "corkchest" then
            inst.AnimState:PushAnimation("open_loop", true)
        end

        inst.SoundEmitter:PlaySound(inst.skin_open_sound or inst.open_sound or "dontstarve/wilson/chest_open")
    end
end

local function OnClose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)

        inst.SoundEmitter:PlaySound(inst.skin_close_sound or inst.close_sound or "dontstarve/wilson/chest_close")
    end
end

local function OnHammered(inst, worker)
    if inst.components.burnable and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()
    if inst.components.container then
        inst.components.container:DropEverything()
    end

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)

    inst.SoundEmitter:PlaySound(inst.skin_place_sound or inst.place_sound or "dontstarve/common/chest_craft")
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function MakeChest(name, bank, build, indestructible, master_postinit, prefabs, assets, common_postinit, force_non_burnable)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(name ..".tex")

        inst:AddTag("structure")
        inst:AddTag("chest")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("closed")

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)
        inst.components.container.onopenfn = OnOpen
        inst.components.container.onclosefn = OnClose
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        if not indestructible then
            inst:AddComponent("lootdropper")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetWorkLeft(2)
            inst.components.workable:SetOnFinishCallback(OnHammered)
            inst.components.workable:SetOnWorkCallback(OnHit)

            if not force_non_burnable then
                MakeSmallBurnable(inst, nil, nil, true)
                MakeMediumPropagator(inst)
            end
        end

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        inst:ListenForEvent("onbuilt", OnBuilt)

        -- Save / load is extended by some prefab variants
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

--[[ Honey Chest ]]--

local function AntOnSave(inst, data)
    if inst.spawned then
        data.spawned = true
    end
    OnSave(inst, data)
end

local function LoadHoneyFirstTime(inst)
    if inst.spawned then
        return
    end
    for index = 1, inst.components.container.numslots do
        inst.components.container:GiveItem(SpawnPrefab("honey"), index)
    end
    inst.spawned = true
end

local function AntOnLoad(inst, data)
    if data and data.spawned then
        inst.spawned = true
    end
    OnLoad(inst, data)
end

local function RefreshAntChestBuild(inst)
    local has_honey = false
    local has_nectar = false

    for _, item in pairs(inst.components.container.slots) do
        if item.prefab == "honey" then
            has_honey = true
            break
        elseif item.prefab == "nectar_pod" then
            has_nectar = true
        end
    end

    if has_honey then
        inst.AnimState:SetBuild("ant_chest_honey_build")
        inst.MiniMapEntity:SetIcon("ant_chest_honey.tex")
    elseif has_nectar then
        inst.AnimState:SetBuild("ant_chest_nectar_build")
        inst.MiniMapEntity:SetIcon("ant_chest_nectar.tex")
    else
        inst.AnimState:SetBuild("ant_chest")
        inst.MiniMapEntity:SetIcon("ant_chest.tex")
    end
end

local function ant_perish_rate_multiplier(inst, item)
    if item.prefab == "nectar_pod" then
        return 0
    end
end

local function ant_master_postinit(inst)
    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(ant_perish_rate_multiplier)

    inst.open_sound = "dontstarve_DLC003/common/objects/honey_chest/open"
    inst.close_sound = "dontstarve_DLC003/common/objects/honey_chest/open"

    inst.OnSave = AntOnSave
    inst.OnLoad = AntOnLoad

    inst:DoTaskInTime(0, LoadHoneyFirstTime)
    inst:ListenForEvent("itemget", RefreshAntChestBuild)
    inst:ListenForEvent("itemlose", RefreshAntChestBuild)
    RefreshAntChestBuild(inst)
end

--[[ Cork Barrel ]]--

local function cork_common_postinit(inst)
    inst:AddTag("pogproof")
end

local function cork_master_postinit(inst)
    inst.open_sound = "dontstarve_DLC003/common/crafted/cork_chest/open"
    inst.close_sound = "dontstarve_DLC003/common/crafted/cork_chest/close"
    inst.plcae_sound = "dontstarve_DLC003/common/crafted/cork_chest/place"
end

--[[ Root Trunk ]]--

local function AttachRootContainer(inst)
    inst.components.container_proxy:SetMaster(TheWorld:GetPocketDimensionContainer("root"))
end

local function roottrunk_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("root_chest.tex")

    inst:AddTag("structure")
    -- inst:AddTag("chest")

    inst.AnimState:SetBank("roottrunk")
    inst.AnimState:SetBuild("treasure_chest_roottrunk")
    inst.AnimState:PlayAnimation("closed")

    inst:AddComponent("container_proxy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst.components.container_proxy:SetOnOpenFn(OnOpen)
    inst.components.container_proxy:SetOnCloseFn(OnClose)

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst.open_sound = "dontstarve_DLC003/common/crafted/root_trunk/open"
    inst.close_sound = "dontstarve_DLC003/common/crafted/root_trunk/open"
    inst.place_sound = "dontstarve_DLC003/common/crafted/root_trunk/place"

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = AttachRootContainer

    if not POPULATING then
        AttachRootContainer(inst)
    end

    return inst
end

return MakeChest("antchest", "ant_chest", "ant_chest", false, ant_master_postinit, prefabs_ant, assets_ant, nil, false),
       MakeChest("corkchest", "treasure_chest_cork", "treasure_chest_cork", false, cork_master_postinit, prefabs_cork, assets_cork, cork_common_postinit, false),
       Prefab("roottrunk", roottrunk_fn, assets_root, prefabs_root),
       MakePlacer("corkchest_placer", "chest", "treasure_chest_cork", "closed"),
       MakePlacer("roottrunk_placer", "roottrunk", "treasure_chest_roottrunk", "closed")
