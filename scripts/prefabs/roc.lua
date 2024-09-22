local assets =
{
    Asset("ANIM", "anim/roc_shadow.zip"),
}

local prefabs =
{
    "roc_leg",
    "roc_head",
    "roc_tail",
}

local RocGiantUtil = require("prefabs/roc_giant_util")

local HEADDIST = 17
local TAILDIST = 13
local LEGDIST = 6

local BODY_PARTS =
{
    ["head"] = {prefabname = "roc_head", offset = Vector3(HEADDIST, 0, 0)},
    ["tail"] = {prefabname = "roc_tail", offset = Vector3(-TAILDIST, 0, 0)},
    ["leg1"] = {prefabname = "roc_leg", offset = Vector3(0, 0, LEGDIST)},
    ["leg2"] = {prefabname = "roc_leg", offset = Vector3(0, 0, - LEGDIST)},
}

local function scalefn(inst,scale)
    inst.components.glidemotor.runspeed = TUNING.ROC_SPEED * scale
    inst.components.shadowcaster:SetRange(TUNING.ROC_SHADOWRANGE * scale)
end

local function OnRemoved(inst)
    TheWorld.components.rocmanager:RemoveRoc(inst)
end

local function OnPhaseChange(inst, phase)
    if phase == "day" then
        if not inst.components.areaaware:CurrentlyInTag("Canopy") then
            inst.components.colourtweener:StartTween({1, 1, 1, 0.5}, 3)
        end
    elseif phase == "night" then
        inst.components.colourtweener:StartTween({1, 1, 1, 0}, 3)
    end
end


local function ShowBodyParts(inst)
    local has_allbodyparts = true

    for k, v in pairs(BODY_PARTS) do
        if v and not inst.bodyparts[k] then
            has_allbodyparts = false
        end
    end

    if not has_allbodyparts then
        for k, v in pairs(BODY_PARTS) do
            if v and not inst.bodyparts[k] then
                local bodypart = SpawnPrefab(v.prefabname)
                inst.bodyparts[k] = bodypart
                bodypart.body = inst
            end
        end
    end

    for k, v in pairs(inst.bodyparts) do
        local x, y, z = inst.entity:LocalToWorldSpace(BODY_PARTS[k].offset:Get())
        v.Transform:SetPosition(x, y, z)
        v.offset = BODY_PARTS[k].offset
        local angle = inst.Transform:GetRotation()
        v.Transform:SetRotation(angle)
        v:Show()
        v.sg:GoToState("enter")
    end
end

local function HideBodyParts(inst)
    for k, v in pairs(inst.bodyparts) do
        v:Hide()
    end
end

local function OnSave(inst, data)
    local refs = {}
    if inst.bodyparts then
        refs.bodyparts = {}
        for k, v in pairs(inst.bodyparts) do
            refs.bodyparts[k] = v.GUID
        end
    end

    return refs
end


local function OnLoadPostPass(inst, newents, data)
    if not data then
        return
    end

    if data.bodyparts then
        inst.bodyparts = {}
        for k, v in pairs(data.bodyparts) do
            local bodypart = ents[v].entity
            if bodypart then
                inst.bodyparts[k] = bodypart
                bodypart.body = inst
                bodypart.offset = BODY_PARTS[k].offset
            end
        end
    end
end

local function SetFlySpeed(inst)
    inst.components.glidemotor.runspeed = TUNING.ROC_SPEED
    inst.components.glidemotor.runspeed_turnfast = TUNING.ROC_SPEED * 2 / 3
    inst.components.glidemotor.turnspeed = 10
    inst.components.glidemotor.turnspeed_fast = 60
end

local function SetLandSpeed(inst)
    inst.components.glidemotor.runspeed = TUNING.ROC_SPEED_LAND
    inst.components.glidemotor.runspeed_turnfast = 0
    inst.components.glidemotor.turnspeed = 20
    inst.components.glidemotor.turnspeed_fast = 60
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:SetCanSleep(false)

    inst.AnimState:SetBank("roc")
    inst.AnimState:SetBuild("roc_shadow")
    inst.AnimState:PlayAnimation("shadow")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)
    inst.AnimState:SetScale(1, -1, 1)

    inst.Physics:SetMass(9999999)
    inst.Physics:SetCapsule(1.5, 1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
    inst.Physics:ClearCollidesWith(COLLISION.VOID_LIMITS)

    inst.Transform:SetScale(1, 1, 1)

    inst:AddTag("roc")
    inst:AddTag("roc_body")
    inst:AddTag("canopytracker")
    inst:AddTag("noteleport")
    inst:AddTag("windspeedimmune")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.bodyparts = {}

    inst:AddComponent("knownlocations")

    inst:AddComponent("shadowcaster")

    inst:AddComponent("areaaware")

    inst:AddComponent("timer")

    inst:AddComponent("glidemotor")
    SetFlySpeed(inst)

    inst:AddComponent("giantbraincontroller")
    inst.components.giantbraincontroller.behaviors["idle"] = {updatefn = RocGiantUtil.FlyBehaviorUpdate}
    inst.components.giantbraincontroller.behaviors["land"] = {
        enterfn = RocGiantUtil.LandBehaviorEnter,
        updatefn = RocGiantUtil.LandBehaviorUpdate,
    }

    inst:AddComponent("colourtweener")

    inst:ListenForEvent("onremove", OnRemoved)
    inst:ListenForEvent("changearea", function()
        if inst.components.areaaware:CurrentlyInTag("Canopy") then
            inst.components.colourtweener:StartTween({1, 1, 1, 0}, 1)
        elseif not TheWorld.state.isnight then
            inst.components.colourtweener:StartTween({1, 1, 1, 0.5}, 1)
        end
    end)

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    inst.sound_distance = 0

    inst:SetStateGraph("SGroc")

    inst.roc_nest = TheSim:FindFirstEntityWithTag("roc_nest")

    inst.ShowBodyParts = ShowBodyParts
    inst.HideBodyParts = HideBodyParts
    inst.SetFlySpeed = SetFlySpeed
    inst.SetLandSpeed = SetLandSpeed

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("roc", fn, assets, prefabs)
