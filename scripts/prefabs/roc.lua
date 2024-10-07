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

local function setstage(inst, stage)
    if stage == 1 then
        inst.Transform:SetScale(0.35, 0.35, 0.35)
        inst.components.locomotor.runspeed = 5
    elseif stage == 2 then
        inst.Transform:SetScale(0.65, 0.65, 0.65)
        inst.components.locomotor.runspeed = 7.5
    else
        inst.Transform:SetScale(1, 1, 1)
        inst.components.locomotor.runspeed = 10
    end
end

local function scalefn(inst,scale)
    inst.components.locomotor.runspeed = TUNING.ROC_SPEED * scale
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
    inst.AnimState:PlayAnimation("ground_loop")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)

    inst.Physics:SetMass(10)
    inst.Physics:SetCapsule(1.5, 1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:ClearCollidesWith(COLLISION.VOID_LIMITS)

    inst.Transform:SetScale(1.5, 1.5, 1.5)

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

    inst:AddComponent("knownlocations")

    inst:AddComponent("shadowcaster")

    inst:AddComponent("areaaware")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.ROC_SPEED

    inst:AddComponent("glidemotor")
    inst.components.glidemotor.runspeed = TUNING.ROC_SPEED
    inst.components.glidemotor.runspeed_turnfast = TUNING.ROC_SPEED * 2 / 3
    inst.components.glidemotor:EnableMove(false)

    inst:AddComponent("roccontroller")
    inst.components.roccontroller:Setup(TUNING.ROC_SPEED, 0.35, 3)
    inst.components.roccontroller:Start()
    inst.components.roccontroller.scalefn = scalefn

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

    inst:SetStateGraph("SGroc")

    inst.roc_nest = TheSim:FindFirstEntityWithTag("roc_nest")

    inst.setstage = setstage

    return inst
end

return Prefab("roc", fn, assets, prefabs)
