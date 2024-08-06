local assets = {
    Asset("ANIM", "anim/pig_shop.zip"),

    Asset("ANIM", "anim/flag_post_duster_build.zip"),
    Asset("ANIM", "anim/flag_post_perdy_build.zip"),
    Asset("ANIM", "anim/flag_post_royal_build.zip"),
    Asset("ANIM", "anim/flag_post_wilson_build.zip"),
    Asset("ANIM", "anim/pig_tower_build.zip"),
    Asset("ANIM", "anim/pig_tower_royal_build.zip"),
}

local prefabs = {
    "pigman_royalguard",
    "pigman_royalguard_2",
}

local function LightsOn(inst)
    if not inst:HasTag("burnt") then
        inst.Light:Enable(true)
        inst.AnimState:PlayAnimation("lit", true)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
    end
end
local function LightsOff(inst)
    if not inst:HasTag("burnt") then
        inst.Light:Enable(false)
        inst.AnimState:PlayAnimation("idle", true)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
    end
end

local function OnVacate(inst, child)
    if not inst:HasTag("burnt") then
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.SoundEmitter:KillSound("pigsound")

        LightsOff(inst)

        if child and child.components.health then
            child.components.health:SetPercent(1)
        end
    end
end

local function OnOccupied(inst, child)
    if not inst:HasTag("burnt") then

        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/pig_in_house_LP", "pigsound")

        if inst.doortask then
            inst.doortask:Cancel()
        end
        inst.doortask = inst:DoTaskInTime(1, LightsOn)
    end
end

local function OnHit(inst, worker)
    if inst:HasTag("burnt") then
        return
    end
    inst.AnimState:PlayAnimation("hit")
    local animation = inst.Light:IsEnabled() and "lit" or "idle"
    inst.AnimState:PushAnimation(animation)
end

local function OnHammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end

    if inst.components.spawner then
        inst.components.spawner:ReleaseChild()
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function OnIsFiesta(inst, isfiesta)
    if isfiesta then
        inst.AnimState:Show("YOTP")
    else
        inst.AnimState:Hide("YOTP")
    end
end

local function OnDay(inst, isday)
    if inst:HasTag("burnt") then
        return
    end
    if not inst:HasTag("burnt") then
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, function()
            if inst.components.spawner:IsOccupied() then
                LightsOff(inst)
                inst.components.spawner:ReleaseChild()
                inst.doortask = nil
            end
        end)
    end
end

local function OnInit(inst)
    if inst.components.spawner
        and not inst.components.spawner.child
        and inst.components.spawner.childname and
        not inst.components.spawner:IsSpawnPending() then

        local child = SpawnPrefab(inst.components.spawner.childname)
        if child then
            inst.components.spawner:TakeOwnership(child)
            inst.components.spawner:GoHome(child)
        end
    end
    inst:WatchWorldState("isday", OnDay)
    OnDay(inst, TheWorld.state.isday)
end

local function OnBuilt(inst)
    inst:SetType("pigman_royalguard", "flag_post_wilson_build")

    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
end

local function SetTarget(pig, target)
    if pig.components.combat.target == nil then
        pig:DoTaskInTime(math.random(), pig.PushEvent, "atacked", {
            attacker = target,
            damage = 0,
            weapon = nil,
        })
    end
end

local function CallGuards(inst, threat)
    if inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end
    if inst.components.spawner.child then
        SetTarget(inst.components.spawner.child, threat)
    end
end

local function SetType(inst, childname, overridebuild)
    inst.components.spawner.childname = childname
    inst.components.fixable.overridebuild = overridebuild
    inst.AnimState:AddOverrideBuild(inst.components.fixable.overridebuild)
end

local function MakeCityPossession(inst)
    if inst:HasTag("palacetower") then
        inst:SetType("pigman_royalguard_2", "flag_post_royal_build")
    elseif inst.components.citypossession.cityID == 2 then
        inst:SetType("pigman_royalguard_2", "flag_post_perdy_build")
    else
        inst:SetType("pigman_royalguard", "flag_post_duster_build")
    end
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end
    data.overridebuild = inst.components.fixable.overridebuild
    if inst.components.spawner.childname then
        data.childname = inst.components.spawner.childname
    end
end

local function OnLoad(inst, data)
    if data then
        if data.childname then
            inst.components.spawner.childname = data.childname
        end
        if data.burnt then
            inst.components.burnable.onburnt(inst)
        end
        if data.overridebuild then
            inst.components.fixable.overridebuild = data.overridebuild
            inst.AnimState:AddOverrideBuild(data.overridebuild)
        end
    end
end

local function OnReconstructe(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
end

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            local x, _, z = inst._pfpos:Get()
            for delta_x = 0, 1 do
                for delta_z = 0, 1 do
                    TheWorld.Pathfinder:AddWall(x + delta_x - 0.5, 0, z + delta_z - 0.5)
                end
            end
        end
    elseif inst._pfpos ~= nil then
        local x, _, z = inst._pfpos:Get()
        for delta_x = 0, 1 do
            for delta_z = 0, 1 do
                TheWorld.Pathfinder:RemoveWall(x + delta_x - 0.5, 0, z + delta_z - 0.5)
            end
        end
        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function MakeObstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

local function ClearObstacle(inst)
    inst.Physics:SetActive(false)
    inst._ispathfinding:set(false)
end

local function OnRemove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("pig_guard_tower.tex")

    inst:AddTag("guard_tower")
    inst:AddTag("structure")
    inst:AddTag("city_hammerable")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("pig_shop")
    inst.AnimState:SetBuild("pig_tower_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:Hide("YOTP")

    ------- Copied from prefabs/wall.lua -------
    inst._pfpos = nil
    inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
    MakeObstacle(inst)
    -- Delay this because makeobstacle sets pathfinding on by default
    -- but we don't to handle it until after our position is set
    inst:DoTaskInTime(0, InitializePathFinding)

    inst:ListenForEvent("onremove", OnRemove)
    --------------------------------------------

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("gridnudger")
    inst.components.gridnudger.snap_to_grid = true

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("fixable")
    inst.components.fixable:AddRecinstructionStageData("rubble", "pig_shop", "pig_tower_build")
    inst.components.fixable:AddRecinstructionStageData("unbuilt", "pig_shop", "pig_tower_build")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnHit)
    inst.components.workable:SetOnFinishCallback(OnHammered)

    inst:AddComponent("spawner")
    inst.components.spawner:Configure("pigman_royalguard", TUNING.GUARDTOWER_CITY_RESPAWNTIME, 1)
    inst.components.spawner:SetOnVacateFn(OnVacate)
    inst.components.spawner:SetOnOccupiedFn(OnOccupied)
    inst.components.spawner:SetWaterSpawning(false, true)
    inst.components.spawner:CancelSpawning()
    inst:DoTaskInTime(0, OnInit)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.SetType = SetType
    inst.CallGuards = CallGuards
    inst.OnReconstructe = OnReconstructe
    inst.OnCityPossession = MakeCityPossession

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:WatchWorldState("isfiesta", OnIsFiesta)
    OnIsFiesta(inst, TheWorld.state.isfiesta)

    MakeSnowCovered(inst, 0.01)
    MakeHauntableWork(inst)

    return inst
end

local function palacefn()
    local inst = fn()

    inst.AnimState:SetBuild("pig_tower_royal_build")

    inst.MiniMapEntity:SetIcon("pig_tower_royal.tex")

    inst:AddTag("palacetower")

    inst:SetPrefabNameOverride("pig_guard_tower")

    return inst
end

-- TODO: Make this work
local function PlaceTestFn(inst)
    inst.AnimState:Hide("YOTP")
    inst.AnimState:Hide("SNOW")

    local x, y, z = inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    if tile == WORLD_TILES.INTERIOR then
        return false
    end

    return true
end

return Prefab("pig_guard_tower", fn, assets, prefabs),
    Prefab("pig_guard_tower_palace", palacefn, assets, prefabs),
    MakePlacer("pig_guard_tower_placer", "pig_shop", "pig_tower_build", "idle", false, true)
