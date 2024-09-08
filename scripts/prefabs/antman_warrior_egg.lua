local assets =
{
    Asset("ANIM", "anim/antman_basic.zip"),
    Asset("ANIM", "anim/antman_attacks.zip"),
    Asset("ANIM", "anim/antman_actions.zip"),
    Asset("ANIM", "anim/antman_egghatch.zip"),
    Asset("ANIM", "anim/antman_guard_build.zip"),

    Asset("ANIM", "anim/antman_translucent_build.zip"),
}

local function dohatch(inst, hatch_time)
    inst.updatetask = inst:DoTaskInTime(hatch_time, function()
        inst.AnimState:PlayAnimation("hatch")
        inst.components.health:SetInvincible(true)

        inst.updatetask = inst:DoTaskInTime(11 * FRAMES, function()
            ChangeToInventoryPhysics(inst)

            local queen = inst.queen
            local warrior = ReplacePrefab(inst, "antman_warrior")
            warrior.sg:GoToState("hatch")

            if queen then
                warrior.queen = queen
            elseif TheWorld.state.isaporkalypse then
                warrior:AddTag("aporkalypse_cleanup")
            end

            -- warrior.components.combat:SetTarget(GetPlayer())

            if warrior.queen then
                warrior:ListenForEvent("death", function(warrior, data)
                    warrior.queen:WarriorKilled()
                end)
            end
        end)
    end)
end

local function ground_detection(inst)
    local pos = inst:GetPosition()

    if pos.y <= 0.2 then
        inst.Transform:SetPosition(pos.x, 0, pos.z)
        ChangeToObstaclePhysics(inst)
        inst.AnimState:PlayAnimation("land")
        inst.AnimState:PushAnimation("idle", true)

        if inst.updatetask then
            inst.updatetask:Cancel()
            inst.updatetask = nil
        end

        dohatch(inst, math.random(2, 6))
    end
end

local function start_grounddetection(inst)
    inst.updatetask = inst:DoPeriodicTask(FRAMES, ground_detection)
end

local function onremove(inst)
    if inst.updatetask then
        inst.updatetask:Cancel()
        inst.updatetask = nil
    end
end

local function OnSave(inst, data)
    if inst.queen then
        data.queen_guid = inst.queen.GUID
    end
end

local function OnLoadPostPass(inst, ents, data)
    if data.queen_guid and ents[data.queen_guid] then
        local queen = ents[data.queen_guid].entity
        queen.WarriorKilled()
    end

    inst:Remove()
end

local function OnEntityWake(inst)
    -- local centre = TheWorld.components.interiorspawner:GetInteriorCenter(inst:GetCurrentInteriorID())
    -- if centre and centre:HasInteriorTag("antqueen") then
    --     dohatch(inst, math.random(2, 4))
    -- else
    --     onremove(inst)
    -- end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("antman_egg")
    inst.AnimState:SetBuild("antman_guard_build")
    inst.AnimState:AddOverrideBuild("antman_egghatch")
    inst.AnimState:PlayAnimation("flying", true)
    inst.AnimState:SetRayTestOnBB(true)

    inst.Transform:SetScale(1.15, 1.15, 1.15)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(function()
        if inst.components.health:IsDead() then
            inst.AnimState:PlayAnimation("break")
            inst.queen:WarriorKilled()
            onremove(inst)
        elseif not inst.components.health:IsInvincible() then
            inst.AnimState:PlayAnimation("hit", false)
        end
    end)

    inst.OnRemoveEntity = onremove


    inst:ListenForEvent("animover", function (inst)
        if inst.AnimState:IsCurrentAnimation("hatch") then
            inst:Remove()
        end
    end)

    inst.OnEntityWake = OnEntityWake

    inst.start_grounddetection = start_grounddetection
    inst.eggify = function (inst)
        inst.AnimState:PlayAnimation("eggify", false)
        inst.AnimState:PushAnimation("idle", false)
        dohatch(inst, 1)
    end

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("antman_warrior_egg", fn, assets)
