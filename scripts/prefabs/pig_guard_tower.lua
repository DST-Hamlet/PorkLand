local assets =
{
    Asset("ANIM", "anim/pig_shop.zip"),

    Asset("ANIM", "anim/flag_post_duster_build.zip"),
    Asset("ANIM", "anim/flag_post_perdy_build.zip"),
    Asset("ANIM", "anim/flag_post_royal_build.zip"),
    Asset("ANIM", "anim/flag_post_wilson_build.zip"),
    Asset("ANIM", "anim/pig_tower_build.zip"),
    Asset("ANIM", "anim/pig_tower_royal_build.zip"),
}

local prefabs =
{
    "pigman_royalguard",
    "pigman_royalguard_2",
}

local function LightsOn(inst)
    if inst:HasTag("burnt") then
        return
    end

    inst.Light:Enable(true)
    inst.AnimState:PlayAnimation("lit", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
    inst.lightson = true
end

local function LightsOff(inst)
    if inst:HasTag("burnt") then
        return
    end

    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
    inst.lightson = false
end

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        if inst.lightson then
            return "FULL"
        else
            return "LIGHTSOUT"
        end
    end
end

local function OnOccupied(inst, child)
    if inst:HasTag("burnt") then
        return
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/pig_in_house_LP", "pigsound")

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end

    inst.doortask = inst:DoTaskInTime(1, LightsOn)
end

local function OnVacated(inst, child)
    if inst:HasTag("burnt") then
        return
    end

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
    inst.SoundEmitter:KillSound("pigsound")

    if child and child.components.health then
        child.components.health:SetPercent(1)
    end
end

local function OnHammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    inst.reconstruction_project_spawn_state = {
        bank = "pig_house",
        build = "pig_house",
        anim = "unbuilt",
    }

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

local function OnHit(inst, worker)
    if inst:HasTag("burnt") then
        return
    end

    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function OnIsDay(inst, isday)
    if inst:HasTag("burnt") or not isday then
        return
    end

    if inst.components.spawner:IsOccupied() then
        LightsOff(inst)

        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, function() inst.components.spawner:ReleaseChild() end)
    end
end

local function MakeCityPossession(inst)
    if not inst.components.citypossession then -- player built
        inst.AnimState:AddOverrideBuild("flag_post_wilson_build")
        inst.components.spawner:Configure("pigman_royalguard", TUNING.GUARDTOWER_CITY_RESPAWNTIME, 1)
        return
    end

    if inst:HasTag("palacetower") then
        inst.AnimState:AddOverrideBuild("flag_post_royal_build")
        inst.components.spawner:Configure("pigman_royalguard_2", TUNING.GUARDTOWER_CITY_RESPAWNTIME, 1)
    elseif inst.components.citypossession.cityID == 2 then
        inst.AnimState:AddOverrideBuild("flag_post_perdy_build")
        inst.components.spawner:Configure("pigman_royalguard_2", TUNING.GUARDTOWER_CITY_RESPAWNTIME, 1)
    elseif inst.components.citypossession.cityID == 1 then
        inst.AnimState:AddOverrideBuild("flag_post_duster_build")
        inst.components.spawner:Configure("pigman_royalguard_2", TUNING.GUARDTOWER_CITY_RESPAWNTIME, 1)
    end
end

local function reconstructed(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
    MakeCityPossession(inst)
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/brick")
    inst.AnimState:PushAnimation("idle")
    MakeCityPossession(inst)
end

local function callguards(inst, threat)
    if inst.components.spawner then
        if inst.components.spawner:IsOccupied() then
            inst.components.spawner:ReleaseChild()
        end
        if inst.components.spawner.child then
            local pig = inst.components.spawner.child
            if pig.components.combat.target == nil then
                pig:DoTaskInTime(math.random()*1,function()
                    pig:PushEvent("atacked", {attacker = threat, damage = 0, weapon = nil})
                end)
            end
        end
    end
end

local function OnIsAporkalypse(inst, isaporkalypse)
    if isaporkalypse then
        inst.AnimState:Show("YOTP")
    else
        inst.AnimState:Hide("YOTP")
    end
end

local function MakeObstacle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:AddWall(x, y, z - 1)
    TheWorld.Pathfinder:AddWall(x, y, z)
    TheWorld.Pathfinder:AddWall(x, y, z + 1)

    TheWorld.Pathfinder:AddWall(x - 1, y, z - 1)
    TheWorld.Pathfinder:AddWall(x - 1, y, z)
    TheWorld.Pathfinder:AddWall(x - 1, y, z + 1)

    TheWorld.Pathfinder:AddWall(x + 1, y, z - 1)
    TheWorld.Pathfinder:AddWall(x + 1, y, z)
    TheWorld.Pathfinder:AddWall(x + 1, y, z + 1)
end

local function ClearObstacle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:RemoveWall(x, y, z - 1)
    TheWorld.Pathfinder:RemoveWall(x, y, z)
    TheWorld.Pathfinder:RemoveWall(x, y, z + 1)

    TheWorld.Pathfinder:RemoveWall(x - 1, y, z - 1)
    TheWorld.Pathfinder:RemoveWall(x - 1, y, z)
    TheWorld.Pathfinder:RemoveWall(x - 1, y, z + 1)

    TheWorld.Pathfinder:RemoveWall(x + 1, y, z - 1)
    TheWorld.Pathfinder:RemoveWall(x + 1, y, z)
    TheWorld.Pathfinder:RemoveWall(x + 1, y, z + 1)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("pig_shop")
    inst.AnimState:SetBuild("pig_tower_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:Hide("YOTP")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

    inst.MiniMapEntity:SetIcon("pig_guard_tower.tex")

    inst:AddTag("guard_tower")
    inst:AddTag("structure")
    inst:AddTag("city_hammerable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("gridnudger")

    inst:AddComponent("lootdropper")

    inst:AddComponent("fixable")
    inst.components.fixable:AddRecinstructionStageData("rubble", "pig_shop", "pig_tower_build")
    inst.components.fixable:AddRecinstructionStageData("unbuilt", "pig_shop", "pig_tower_build")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("spawner")
    inst.components.spawner.childname = "pigman_royalguard" -- Prevents a crash caused by destroying console spawned towers.
    inst.components.spawner:SetOnVacateFn(OnVacated)
    inst.components.spawner:SetOnOccupiedFn(OnOccupied)

    MakeSnowCovered(inst, 0.01)

    inst.onvacate = OnVacated
    inst.citypossessionfn = MakeCityPossession
    inst.OnLoadPostPass = MakeCityPossession
    inst.callguards = callguards
    inst.reconstructed = reconstructed
    inst.setobstical = MakeObstacle

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("onremove", ClearObstacle)

    inst:WatchWorldState("IsDay", OnIsDay)
    OnIsDay(inst, TheWorld.state.isday)
    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)
    OnIsAporkalypse(inst, TheWorld.state.isaporkalypse)

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
       MakePlacer("pig_guard_tower_placer", "pig_shop", "pig_tower_build", "idle", false, false, true, nil, nil, nil, nil, nil, nil, PlaceTestFn)
