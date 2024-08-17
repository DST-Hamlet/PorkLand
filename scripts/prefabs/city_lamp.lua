local assets =
{
    Asset("ANIM", "anim/lamp_post2.zip"),
    Asset("ANIM", "anim/lamp_post2_city_build.zip"),
    Asset("ANIM", "anim/lamp_post2_yotp_build.zip"),
    Asset("INV_IMAGE", "city_lamp"),
}

local INTENSITY = 0.6

local LAMP_DIST = 16
local LAMP_DIST_SQ = LAMP_DIST * LAMP_DIST

local function UpdateAudio(inst)
    local is_near_player = inst:IsNearPlayer(LAMP_DIST_SQ)
    if TheWorld.state.isdusk and is_near_player and not inst.SoundEmitter:PlayingSound("onsound") then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/city_lamp/on_LP", "onsound")
    elseif not is_near_player and inst.SoundEmitter:PlayingSound("onsound") then
        inst.SoundEmitter:KillSound("onsound")
    end
end

local function GetStatus(inst)
    return not inst.lighton and "ON" or nil
end

local function fadein(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("on")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/city_lamp/fire_on")
    inst.AnimState:PushAnimation("idle", true)
    inst.Light:Enable(true)

    if inst:IsAsleep() then
        inst.Light:SetIntensity(INTENSITY)
    else
        inst.Light:SetIntensity(0)
        inst.components.fader:Fade(0, INTENSITY, 3+math.random()*2, function(v) inst.Light:SetIntensity(v) end)
    end
end

local function fadeout(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("off")
    inst.AnimState:PushAnimation("idle", true)

    if inst:IsAsleep() then
        inst.Light:SetIntensity(0)
    else
        inst.components.fader:Fade(INTENSITY, 0, .75+math.random()*1, function(v) inst.Light:SetIntensity(v) end)
    end
end

local function updatelight(inst, phase)
    local should_light = true
    if not TheWorld:HasTag("cave") then
        if phase then
            should_light = phase == "dusk" or phase == "night"
        else
            should_light = TheWorld.state.isdusk or TheWorld.state.isnight
        end
    end
    if should_light then
        if not inst.lighton then
            inst:DoTaskInTime(math.random()*2, function()
                fadein(inst)
            end)
        else
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
        inst.AnimState:Show("FIRE")
        inst.AnimState:Show("GLOW")
        inst.lighton = true
    else
        if inst.lighton then
            inst:DoTaskInTime(math.random()*2, function()
                fadeout(inst)
            end)
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end

        inst.AnimState:Hide("FIRE")
        inst.AnimState:Hide("GLOW")

        inst.lighton = false
    end
end

local function onhammered(inst, worker)

    inst.SoundEmitter:KillSound("onsound")

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")

    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0.3, updatelight)
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0, updatelight)
end

local function OnEntitySleep(inst)
    if inst.audiotask then
        inst.audiotask:Cancel()
        inst.audiotask = nil
    end
end

local function OnEntityWake(inst)
    if inst.audiotask then
        inst.audiotask:Cancel()
    end
    inst.audiotask = inst:DoPeriodicTask(1.0, UpdateAudio, math.random())

    if TheWorld.state.isfiesta then
        if inst.build == "lamp_post2_city_build" then
            inst.build = "lamp_post2_yotp_build"
            inst.AnimState:SetBuild(inst.build)
        end
    elseif inst.build == "lamp_post2_yotp_build" then
        inst.build = "lamp_post2_city_build"
        inst.AnimState:SetBuild(inst.build)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.entity:AddPhysics()

    MakeObstaclePhysics(inst, 0.25)

    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetColour(197/255, 197/255, 10/255)
    inst.Light:SetFalloff(0.9)
    inst.Light:SetRadius(5)
    inst.Light:Enable(false)

    inst:AddTag("CITY_LAMP")

    --inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )

    inst.build = "lamp_post2_city_build"
    inst.AnimState:SetBank("lamp_post")
    inst.AnimState:SetBuild(inst.build)
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:Hide("FIRE")
    inst.AnimState:Hide("GLOW")

    inst:AddTag("lightsource")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("city_hammerable")
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("fader")

    inst:WatchWorldState("phase", updatelight)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = function(inst, data)
        if inst.lighton then
            data.lighton = inst.lighton
        end
    end

    inst.OnLoad = function(inst, data)
        if data then
            if data.lighton then
                fadein(inst)
                inst.Light:Enable(true)
                inst.Light:SetIntensity(INTENSITY)
                inst.AnimState:Show("FIRE")
                inst.AnimState:Show("GLOW")
                inst.lighton = true
            end
        end
    end

    inst.audiotask = inst:DoPeriodicTask(1.0, UpdateAudio, math.random())

    inst:AddComponent("fixable")
    inst.components.fixable:AddRecinstructionStageData("rubble", "lamp_post", "lamp_post2_city_build")

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    MakeHauntableWork(inst)

    return inst
end

return Prefab("city_lamp", fn, assets),
    MakePlacer("city_lamp_placer", "lamp_post", "lamp_post2_city_build", "idle")
