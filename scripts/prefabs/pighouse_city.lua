local assets = {
    Asset("ANIM", "anim/pig_townhouse1.zip"),
    Asset("ANIM", "anim/pig_townhouse5.zip"),
    Asset("ANIM", "anim/pig_townhouse6.zip"),

    Asset("ANIM", "anim/pig_townhouse1_pink_build.zip"),
    Asset("ANIM", "anim/pig_townhouse1_green_build.zip"),

    Asset("ANIM", "anim/pig_townhouse1_brown_build.zip"),
    Asset("ANIM", "anim/pig_townhouse1_white_build.zip"),

    Asset("ANIM", "anim/pig_townhouse5_beige_build.zip"),
    Asset("ANIM", "anim/pig_townhouse6_red_build.zip"),

    Asset("ANIM", "anim/pig_farmhouse_build.zip"),

    -- Asset("SOUND", "sound/pig.fsb"),
}

local city_1_citizens = {
    "pigman_banker",
    "pigman_beautician",
    "pigman_florist",
    "pigman_usher",
    "pigman_mechanic",
    "pigman_storeowner",
    "pigman_professor",
}

local city_2_citizens = {
    "pigman_collector",
    "pigman_erudite",
    "pigman_hatmaker",
    "pigman_hunter",
}

local city_citizens = {
    city_1_citizens,
    city_2_citizens,
}

local spawned_farm = {
    "pigman_farmer",
}

local spawned_mine = {
    "pigman_miner",
}

local house_builds = {
    "pig_townhouse1_pink_build",
    "pig_townhouse1_green_build",
    "pig_townhouse1_white_build",
    "pig_townhouse1_brown_build",
    "pig_townhouse5_beige_build",
    "pig_townhouse6_red_build",
}
local bank_build_map = {
    pig_townhouse1_pink_build = "pig_townhouse",
    pig_townhouse1_green_build = "pig_townhouse",
    pig_townhouse1_white_build = "pig_townhouse",
    pig_townhouse1_brown_build = "pig_townhouse",
    pig_townhouse5_beige_build = "pig_townhouse5",
    pig_townhouse6_red_build = "pig_townhouse6",
}

local build_scale_map = {
    pig_townhouse1_pink_build = 0.75,
    pig_townhouse1_green_build = 0.75,
    pig_townhouse1_white_build = 0.75,
    pig_townhouse1_brown_build = 0.75,
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

        if inst.doortask ~= nil then
            inst.doortask:Cancel()
        end
        inst.doortask = inst:DoTaskInTime(1, LightsOn)
    end
end


local function ConfigureSpawner(inst, selected_citizens)
    if inst.components.spawner then
        inst.components.spawner:Configure(selected_citizens[math.random(1, #selected_citizens)], TUNING.PIGHOUSE_CITY_RESPAWNTIME, 1)
    end
end

local function OnCityPossession(inst)
    local selected_citizens = {}
    local city_id = inst.components.citypossession and inst.components.citypossession.cityID or 2
    for i = 1, city_id do
        selected_citizens = JoinArrays(selected_citizens, city_citizens[i])
    end

    ConfigureSpawner(inst, selected_citizens)
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        local animation = inst.Light:IsEnabled() and "lit" or "idle"
        inst.AnimState:PushAnimation(animation)
    end
end

local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function OnIgnite(inst)
    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end
end

local function OnBurntUp(inst)
    inst.components.fixable:AddRecinstructionStageData("burnt", "pig_townhouse", inst.build, inst.scale, 1)
    inst:Remove()
end

local function OnDay(inst, isday)
    if not isday then
        return
    end

    if not inst:HasTag("burnt") then
        inst:DoTaskInTime(1 + math.random() * 2, function()
            if inst.components.spawner:IsOccupied() then
                inst.components.spawner:ReleaseChild()
            end
        end)
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/wood_2")
    inst.AnimState:PushAnimation("idle")
    OnCityPossession(inst)
end


local function OnSave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end
    data.build = inst.build
    data.bank = inst.bank
    data.color = inst.color
    if inst.components.spawner.childname then
        data.childname = inst.components.spawner.childname
    end
end

local function OnLoad(inst, data)
    if data then
        if data.build then
            inst.build = data.build
            inst.AnimState:SetBuild(inst.build)
        end
        if data.bank then
            inst.bank = data.bank
            inst.AnimState:SetBank(inst.bank)
        end
        if data.color then
            inst.color = data.color
            inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
        end
        if data.childname then
            inst.components.spawner.childname = data.childname
        end
        if data.burnt then
            inst.components.burnable.onburnt(inst)
        end
    end
end

local function OnEntityWake(inst)
    if TheWorld.state.isfiesta then
        inst.AnimState:Show("YOTP")
    else
        inst.AnimState:Hide("YOTP")
    end
end


local function OnReconstructe(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
    OnCityPossession(inst)
end

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            local x, _, z = inst._pfpos:Get()
            for delta_x = -1, 1 do
                for delta_z = -1, 1 do
                    TheWorld.Pathfinder:AddWall(x + delta_x, 0, z + delta_z)
                end
            end
        end
    elseif inst._pfpos ~= nil then
        local x, _, z = inst._pfpos:Get()
        for delta_x = -1, 1 do
            for delta_z = -1, 1 do
                TheWorld.Pathfinder:RemoveWall(x + delta_x, 0, z + delta_z)
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

local function MakePigHouse(name, bank, build, minimapicon, spawn_list)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(minimapicon or "pig_townhouse.tex")

        inst:AddTag("bandit_cover")
        inst:AddTag("structure")
        inst:AddTag("city_hammerable")

        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.5)
        inst.Light:SetRadius(1)
        inst.Light:Enable(false)
        inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

        MakeObstaclePhysics(inst, 1)

        inst.build = build
        if not inst.build then
            inst.build = house_builds[math.random(#house_builds)]
        end
        inst.bank = bank
        if not inst.bank then
            inst.bank = bank_build_map[inst.build]
        end

        inst.scale = build_scale_map[inst.build] or 1
        inst.color = 0.5 + math.random() * 0.5

        inst.AnimState:SetBank(inst.bank)
        inst.AnimState:SetBuild(inst.build)
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetScale(inst.scale, inst.scale, inst.scale)
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
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

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetOnWorkCallback(OnHit)
        inst.components.workable:SetOnFinishCallback(OnHammered)

        inst:AddComponent("fixable")
        inst.components.fixable:AddRecinstructionStageData("rubble", "pig_townhouse", inst.build, inst.scale)
        inst.components.fixable:AddRecinstructionStageData("unbuilt", "pig_townhouse", inst.build, inst.scale)

        inst:AddComponent("spawner")
        inst.components.spawner:SetOnVacateFn(OnVacate)
        inst.components.spawner:SetOnOccupiedFn(OnOccupied)
        inst.components.spawner:SetWaterSpawning(false, true)

        if spawn_list then
            ConfigureSpawner(inst, spawn_list)
        else
            inst.OnCityPossession = OnCityPossession
        end

        inst:WatchWorldState("isday", OnDay)
        OnDay(inst, TheWorld.state.isday)
        inst:ListenForEvent("burntup", OnBurntUp)
        inst:ListenForEvent("onignite", OnIgnite)
        inst:ListenForEvent("onbuilt", OnBuilt)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnEntityWake = OnEntityWake

        MakeSnowCovered(inst, .01)
        MakeLargeBurnable(inst, nil, nil, true)
        MakeLargePropagator(inst)

        return inst
    end

    return Prefab(name, fn, assets)
end

local function placetestfn(inst)
    inst.AnimState:Hide("YOTP")
    inst.AnimState:Hide("SNOW")

    local pt = inst:GetPosition()
    local tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
    if tile == WORLD_TILES.INTERIOR then
        return false
    end

    return true
end

return MakePigHouse("pighouse_city", nil, nil),
    MakePigHouse("pighouse_farm", "pig_shop", "pig_farmhouse_build", "pig_farmhouse.tex", spawned_farm),
    MakePigHouse("pighouse_mine", "pig_shop", "pig_farmhouse_build", "pig_farmhouse.tex", spawned_mine),

    MakePlacer("pighouse_city_placer", "pig_shop", "pig_townhouse1_green_build", "idle", nil, nil, true, 0.75)

-- MakePlacer("pighouse_placer", "pig_house", "pig_house", "idle")
