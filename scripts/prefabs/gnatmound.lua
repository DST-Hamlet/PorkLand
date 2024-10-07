local assets =
{
    Asset("ANIM", "anim/gnat_mound.zip"),
}

local prefabs =
{
    "gnat",
}

SetSharedLootTable("gnatmound",
{
    {"rocks",  1.00},
    {"rocks",  0.25},
    {"flint",  0.25},
    {"iron",   0.25},
    {"nitre",  0.25},
})

local function UpdateAnimations(inst)
    if inst.components.workable.workleft > 4 then
        inst.AnimState:PlayAnimation("full", false)
    elseif inst.components.workable.workleft > 2 then
        inst.AnimState:PlayAnimation("med2", false)
    elseif inst.components.workable.workleft > 0 then
        inst.AnimState:PlayAnimation("low2", false)
    end
end

local function ExtraWorkDrop(inst)
    inst.components.lootdropper:DropLoot()
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst.components.childspawner:ReleaseAllChildren()
end

local function OnWorkCallback(inst)
    for k, v in pairs(inst.stageloots) do
        if inst.components.workable.workleft <= k and v then
            inst.stageloots[k] = nil
            ExtraWorkDrop(inst)
        end
    end

    UpdateAnimations(inst)
end

local function OnFinishedCallback(inst)
    inst.components.lootdropper:DropLoot()

    for k, v in pairs(inst.stageloots) do
        if inst.components.workable.workleft <= k and v then
            inst.stageloots[k] = nil
            ExtraWorkDrop(inst)
        end
    end

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function Rebuild(inst)
    if inst.components.workable.workleft >= inst.components.workable.maxwork then
        return
    end

    inst.components.workable:SetWorkLeft(inst.components.workable.workleft + 1)
    -- ziwbi: honestly could use some transition animation here
    UpdateAnimations(inst)
end

local function OnSave(inst, data)
    data.workleft = inst.components.workable.workleft
end

local function OnLoad(inst, data)
    if data and data.workleft then
        inst.components.workable.workleft = data.workleft
        if inst.components.workable.workleft < 4 then
            inst.stageloots[4] = nil
        elseif inst.components.workable.workleft < 2 then
            inst.stageloots[2] = nil
        end
    end
    UpdateAnimations(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("gnat_mound")
    inst.AnimState:SetBuild("gnat_mound")
    inst.AnimState:PlayAnimation("full")

    inst.MiniMapEntity:SetIcon("gnat_mound.tex")

    inst:AddTag("structure")
    inst:AddTag("gnatmound")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.stageloots = {}

    inst.stageloots[4] = true
    inst.stageloots[2] = true

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("gnatmound")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetMaxWork(TUNING.GNATMOUND_MAX_WORK)
    inst.components.workable:SetWorkLeft(TUNING.GNATMOUND_MAX_WORK)
    inst.components.workable:SetOnFinishCallback(OnFinishedCallback)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "gnat"
    inst.components.childspawner:SetRegenPeriod(TUNING.GNATMOUND_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.GNATMOUND_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.GNATMOUND_MAX_CHILDREN)
    inst.components.childspawner.canspawnfn = function() return not TheWorld.state.israining end
    inst.components.childspawner:StartSpawning()

    -- when child have parent, they can't be save right
    -- see scripts/components/infester.lua line 43
    local _OnSave = inst.components.childspawner.OnSave
    inst.components.childspawner.OnSave = function(self)
        local data, references = _OnSave(self)
        data.follow_parent_childs = {}
        for child in pairs(self.childrenoutside) do
            if child.entity:GetParent() then
                if data.childrenoutside then
                    table.removearrayvalue(data.childrenoutside, child.GUID)
                end
                table.removearrayvalue(references, child.GUID)

                local record, refs = child:GetSaveRecord()
                table.insert(data.follow_parent_childs, record)
                if refs then
                    for k, v in pairs(refs) do
                        table.insert(references, v)
                    end
                end
            end
        end
        return data, references
    end

    local _OnLoad = inst.components.childspawner.OnLoad
    inst.components.childspawner.OnLoad = function(self, data, newents)
        local ret = {_OnLoad(self, data, newents)}

        for _, record in ipairs(data.follow_parent_childs) do
            local child = SpawnSaveRecord(record, newents)
            if child then
                self:TakeOwnership(child)
            end
        end
        self:StartUpdate()
        self:TryStopUpdate()

        return unpack(ret)
    end

    inst.rebuild_task = inst:DoPeriodicTask(TUNING.TOTAL_DAY_TIME *1.5 + math.random() * TUNING.TOTAL_DAY_TIME * 0.5, Rebuild)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.UpdateAnimations = UpdateAnimations

    MakeSnowCovered(inst)
    MakeHauntable(inst)

    return inst
end

return Prefab("gnatmound", fn, assets, prefabs)
