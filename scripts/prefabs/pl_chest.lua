require "prefabutil"

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")

        if inst.skin_open_sound then
            inst.SoundEmitter:PlaySound(inst.skin_open_sound)
        elseif inst.prefab == "corkchest" then
			inst.AnimState:PushAnimation("open_loop", true)
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/cork_chest/open")
		elseif inst.prefab == "antchest" then
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/honey_chest/open")
		elseif inst.prefab == "roottrunk_child" then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/root_trunk/open")
		else
            inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
        end
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)

        if inst.skin_close_sound then
            inst.SoundEmitter:PlaySound(inst.skin_close_sound)
		elseif inst.prefab == "corkchest" then
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/cork_chest/close")
		elseif inst.prefab == "antchest" then
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/honey_chest/open")			
		elseif inst.prefab == "roottrunk_child" then
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/root_trunk/open")
        else
            inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
        end
    end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
		if inst.components.container_proxy ~= nil then
			inst.components.container_proxy:Close()
		end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    if inst.skin_place_sound then
        inst.SoundEmitter:PlaySound(inst.skin_place_sound)
	elseif inst.prefab == "corkchest" then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/cork_chest/place")
	elseif inst.prefab == "roottrunk_child" then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/root_trunk/place")
    else
        inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
    end
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
	
	if inst.honeyWasLoaded then
		data.honeyWasLoaded = inst.honeyWasLoaded
	end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function MakeChest(name, bank, build, indestructible, master_postinit, prefabs, assets, common_postinit, force_non_burnable)
    local default_assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    assets = assets ~= nil and JoinArrays(assets, default_assets) or default_assets

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst:AddTag("structure")
        inst:AddTag("chest")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("closed")

		MakeSnowCoveredPristine(inst)

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
        inst.components.container.onopenfn = onopen
        inst.components.container.onclosefn = onclose
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true


        if not indestructible then
            inst:AddComponent("lootdropper")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetWorkLeft(2)
            inst.components.workable:SetOnFinishCallback(onhammered)
            inst.components.workable:SetOnWorkCallback(onhit)

            if not force_non_burnable then
                MakeSmallBurnable(inst, nil, nil, true)
                MakeMediumPropagator(inst)
            end
        end

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        inst:ListenForEvent("onbuilt", onbuilt)
        MakeSnowCovered(inst)

		-- Save / load is extended by some prefab variants
        inst.OnSave = onsave
        inst.OnLoad = onload

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

--------------------------------------------------------------------------
--[[ Cork chest ]]
--------------------------------------------------------------------------

local function cork_common_postinit(inst)
	inst.MiniMapEntity:SetIcon("cork_chest.tex")
    inst:AddTag("pogproof")
end

--------------------------------------------------------------------------
--[[ Ant chest ]]
--------------------------------------------------------------------------

local honey_assets = {
Asset("ANIM", "anim/ui_antchest_honeycomb.zip"),
Asset("ANIM", "anim/ant_chest_honey_build.zip"),
Asset("ANIM", "anim/ant_chest_nectar_build.zip"),
}

local function find_nectar(item)
	return item.prefab == "nectar_pod"
end
local function find_honey(item)
	return item.prefab == "honey"
end

local function LoadHoneyFirstTime(inst)
	if not inst.honeyWasLoaded then
		inst.honeyWasLoaded = true

		for i = 1, inst.components.container:GetNumSlots() do
			inst.components.container:GiveItem(SpawnPrefab("honey"), i, Vector3(inst.Transform:GetWorldPosition()))
		end
	end
end

local function RefreshAntChestBuild(inst)
	local containsHoney  = inst.components.container:FindItem(find_honey)
	local containsNectar = inst.components.container:FindItem(find_nectar)

	if containsHoney then
		inst.AnimState:SetBuild("ant_chest_honey_build")
		inst.MiniMapEntity:SetIcon("ant_chest_honey.tex")
	elseif containsNectar then
		inst.AnimState:SetBuild("ant_chest_nectar_build")
		inst.MiniMapEntity:SetIcon("ant_chest_nectar.tex")
	else
		inst.AnimState:SetBuild("ant_chest")
		inst.MiniMapEntity:SetIcon("ant_chest.tex")
	end
end
local function ant_master_postinit(inst)
	inst:ListenForEvent("itemget", RefreshAntChestBuild)
	inst:ListenForEvent("itemlose", RefreshAntChestBuild)
	inst:DoTaskInTime(0.01, LoadHoneyFirstTime)
end

--------------------------------------------------------------------------
--[[ Root trunk ]]
--------------------------------------------------------------------------

local function AttachRootContainer(inst)
	inst.components.container_proxy:SetMaster(TheWorld:GetPocketDimensionContainer("root"))
end

local function roottrunk_common_postinit(inst)
	inst.MiniMapEntity:SetIcon("root_chest_child.tex")
    inst:AddComponent("container_proxy")
end

local function roottrunk_master_postinit(inst)
	inst:RemoveComponent("container")
	inst.components.container_proxy:SetOnOpenFn(onopen)
	inst.components.container_proxy:SetOnCloseFn(onclose)
	
	inst.OnLoadPostPass = AttachRootContainer

	if not POPULATING then
		AttachRootContainer(inst)
	end
end

return MakeChest("corkchest", "treasure_chest_cork", "treasure_chest_cork", false, nil, { "collapse_small" }, { Asset("ANIM", "anim/ui_thatchpack_1x4.zip") }, cork_common_postinit),
    MakePlacer("corkchest_placer", "chest", "treasure_chest_cork", "closed"),
	MakeChest("antchest", "ant_chest", "ant_chest", true, ant_master_postinit, nil, honey_assets),
	MakeChest("roottrunk_child", "roottrunk", "treasure_chest_roottrunk", false, roottrunk_master_postinit, nil, nil, roottrunk_common_postinit),
	MakePlacer("roottrunk_child_placer", "roottrunk", "treasure_chest_roottrunk", "closed")
    