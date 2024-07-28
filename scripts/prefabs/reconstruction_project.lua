local assets = {
    Asset("ANIM", "anim/pighouse_rubble.zip"),
}

-- 30~60 seconds
-- local REBUILD_REACTION_TIME = TUNING.SEG_TIME
-- local REBUILD_REACTION_VARIANCE = TUNING.SEG_TIME

-- local OFF_SCREENDIST = 30
-- local AUTO_REPAIRDIST = 100
-- local AUTO_REPAIRDIST_SQ = AUTO_REPAIRDIST * AUTO_REPAIRDIST

local function SetConstructionPrefabName(inst, name)
    inst._name:set(name)
end

local function DisplayNameFn(inst)
    local name = inst._name:value()
    return name ~= "" and STRINGS.NAMES[name] or "MISSING NAME"
end

local function SetReconstructionStage(inst, stage)
    inst.reconstruction_stage = stage
    local reconstruction_stage = inst.reconstruction_stages[stage]

    inst.AnimState:SetBank(reconstruction_stage.bank)
    inst.AnimState:SetBuild(reconstruction_stage.build)
    inst.AnimState:PlayAnimation(reconstruction_stage.anim, true)

    local scale = reconstruction_stage.scale
    if scale then
        inst.AnimState:SetScale(unpack(scale))
    end
end

local function GetStatus(inst)
    if inst.reconstruction_stage == 2 then
        return "SCAFFOLD"
    else
        return "RUBBLE"
    end
end

local function Fix(inst, fixer)
    if fixer and fixer.components.fixer then -- covers the actual worker (possibly the player?)
        fixer.components.fixer:ClearTarget()
    end
    if inst.reconstruction_prefab then
        local reconstructed = SpawnPrefab(inst.reconstruction_prefab)
        reconstructed.Transform:SetPosition(inst.Transform:GetWorldPosition())

        reconstructed.interiorID = inst.interiorID
        if reconstructed.interiorID then
            TheWorld.components.interiorspawner:TransferExterior(inst, reconstructed)
        end

        local reconstruction_anims = inst.reconstruction_anims or {}
        reconstructed.AnimState:PlayAnimation(reconstruction_anims.play or "place")
        reconstructed.AnimState:PushAnimation(reconstruction_anims.push or "idle")

        if inst.reconstruction_overridebuild then
            reconstructed.AnimState:AddOverrideBuild(inst.reconstruction_overridebuild)
        end

        if inst.cityID then
            if not reconstructed.components.citypossession then
                reconstructed:AddComponent("citypossession")
            end
            reconstructed.components.citypossession:SetCity(inst.cityID)
        end

        if inst.spawner_data then
            reconstructed.components.spawner:Configure(inst.spawner_data.childname, inst.spawner_data.delay or 0, inst.spawner_data.delay or 0)
            if inst.spawner_data.child and inst.spawner_data.child:IsValid() then
                reconstructed.components.spawner:TakeOwnership(inst.spawner_data.child)
            end
        end

        if reconstructed.OnReconstructe then
            reconstructed:OnReconstructe()
        end
    end

    inst:Remove()
end

local function OnHammered(inst, worker)
    if worker and worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and
        worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("hammer") then
        local target = inst.reconstruction_stage + 1
        if inst.reconstruction_stages[target] then
            inst:SetReconstructionStage(target)
            inst.components.workable:SetWorkLeft(4)
        else
            Fix(inst, worker)
        end
    else
        inst.components.workable:SetWorkLeft(4)
    end
end

local function OnSave(inst, data)
    data.reconstruction_prefab = inst.reconstruction_prefab
    data.reconstruction_stage = inst.reconstruction_stage
    data.reconstruction_stages = inst.reconstruction_stages
    data.reconstruction_anims = inst.reconstruction_anims
    data.reconstruction_overridebuild = inst.reconstruction_overridebuild
    data.interiorID = inst.interiorID
    data.cityID = inst.cityID
    data.name = inst._name:value()

    if inst.spawner_data and inst.spawner_data.child and inst.spawner_data.child:IsValid() then
        data.childname = inst.spawner_data.childname
        data.child = inst.spawner_data.child.GUID
        data.delay = inst.spawner_data.delay

        return { data.child }
    end
end

local function OnLoad(inst, data)
    if data then
        inst.reconstruction_prefab = data.reconstruction_prefab
        inst.reconstruction_stages = data.reconstruction_stages
        inst.reconstruction_anims = data.reconstruction_anims
        inst.reconstruction_overridebuild = data.reconstruction_overridebuild
        inst.interiorID = data.interiorID
        inst.cityID = data.cityID

        inst:SetConstructionPrefabName(data.name)
        inst:SetReconstructionStage(data.reconstruction_stage)

        if data.childname then
            inst.spawner_data = {
                childname = data.childname,
                delay = data.delay,
            }
        end
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data.child then
        inst.spawner_data.child = newents[data.child].entity
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- inst.entity:AddPhysics()
    -- MakeObstaclePhysics(inst, .25)

    inst.AnimState:SetBank("pighouse_rubble")
    inst.AnimState:SetBuild("pighouse_rubble")
    inst.AnimState:PlayAnimation("unbuilt")

    inst._name = net_string(inst.GUID, "reconstruction_project._name")
    inst._name:set("")

    inst.displaynamefn = DisplayNameFn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.reconstruction_stage = 1
    inst.reconstruction_stages = {}

    -- inst:AddComponent("timer")

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.SetReconstructionStage = SetReconstructionStage
    inst.SetConstructionPrefabName = SetConstructionPrefabName

    MakeSnowCovered(inst, .01)

    return inst
end

return Prefab("reconstruction_project", fn, assets)
