require("prefabutil")

local assets =
{
    Asset("ANIM", "anim/lifeplant.zip"),
    Asset("ANIM", "anim/lifeplant_fx.zip"),
}

local prefabs =
{
    "waterdrop",
}

local INTENSITY = 0.5

local function FadeIn(inst)
    inst.components.fader:StopAll()
    inst.Light:Enable(true)
    if inst:IsAsleep() then
        inst.Light:SetIntensity(INTENSITY)
    else
        inst.Light:SetIntensity(0)
        inst.components.fader:Fade(0, INTENSITY, 3 + math.random() * 2, function(v) inst.Light:SetIntensity(v) end)
    end
end

local function UpdateAnimations(inst)
    if not inst.reserrecting then
        local anim = math.random() < 0.5 and "idle_gargle" or  "idle_vanity"

        inst.AnimState:PlayAnimation(anim)
        inst.AnimState:PushAnimation("idle_loop", true)
    end

    inst:DoTaskInTime(8 + math.random() * 20, UpdateAnimations)
end

local function Sparkle(inst)
    local target = inst.components:GetNearestPlayer()

    local lifeplant_sparkle = SpawnPrefab("lifeplant_sparkle")
    lifeplant_sparkle.Transform:SetPosition(target.Transform:GetWorldPosition())
end

local function DrainHunger(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 6, true)
    for _, player in pairs(players) do
        player.components.hunger:DoDelta(-1)
    end
end

local function OnNear(inst)
    if not inst.reserrecting then
        inst.sparkle_task = inst:DoPeriodicTask(0.5, Sparkle)
        inst.drain_task = inst:DoPeriodicTask(2, DrainHunger)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/flower_of_life/fx_LP", "drainloop")
    end
end

local function OnFar(inst)
    if inst.sparkle_task then
        inst.sparkle_task:Cancel()
        inst.sparkle_task = nil

        inst.drain_task:Cancel()
        inst.drain_task = nil
        inst.SoundEmitter:KillSound("drainloop")
    end
end

local function OnBurnt(inst)
    local ash = SpawnPrefab("ash")
    ash.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function OnDug(inst, chopper)
    inst.components.lootdropper:SpawnLootPrefab("waterdrop")
    inst.SoundEmitter:KillSound("drainloop")
    inst.dug = true
    inst:Remove()
end

local function OnPlanted(inst, data)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle_loop",true)
    if data.fountain then
        inst.fountain = data.fountain
    end
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/flower_of_life/plant")
    inst.components.attunable:LinkToPlayer(data.deployer)
end

local function OnRemoved(inst)
    if inst.fountain and not inst.dug then
        inst.fountain:PushEvent("deactivate")
    end
    inst.SoundEmitter:KillSound("drainloop")
end

local function OnResurrect(inst, player)
    inst.reserrecting = true

    if inst.sparkle_task then
        inst.sparkle_task:Cancel()
        inst.sparkle_task = nil

        inst.drain_task:Cancel()
        inst.drain_task = nil
    end

    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    inst:AddTag("busy")

    inst:RemoveComponent("lootdropper")
    inst:RemoveComponent("workable")
    inst:RemoveComponent("inspectable")

    inst.MiniMapEntity:SetEnabled(false)
    RemovePhysicsColliders(inst)


    inst.persists = false

    inst.AnimState:PlayAnimation("transform")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/flower_of_life/rebirth")

    player.sg:GoToState("rebirth_floweroflife")

    player:DoTaskInTime(3, function()
        inst:RemoveTag("busy")
    end)

    inst:DoTaskInTime(7, function()
        --reset fountain
        if inst.fountain then
            inst.fountain:PushEvent("deactivate")
        end

        local tick_time = TheSim:GetTickTime()
        local time_to_erode = 4
        inst:StartThread( function()
            local ticks = 0
            while ticks * tick_time < time_to_erode do
                local erode_amount = ticks * tick_time / time_to_erode
                inst.AnimState:SetErosionParams( erode_amount, 0.1, 1.0 )
                ticks = ticks + 1
                Yield()
            end

            inst:Remove()
        end)
    end)
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end

    if inst.fountain and inst.fountain:IsValid() then
        data.fountainID = inst.fountain.GUID
        return {inst.fountain and inst.fountain.GUID}
    end
end

local function OnLoad(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.fountainID ~= nil then
        inst.fountain = newents[data.fountainID].entity
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lifeplant")
    inst.AnimState:SetBuild("lifeplant")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(0.9, 0.9, 0.9, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.Light:SetFalloff(0.9)
    inst.Light:SetRadius(2)
    inst.Light:Enable(true)

    inst.MiniMapEntity:SetIcon("lifeplant.tex")

    MakeObstaclePhysics(inst, 0.3)

    inst:AddTag("lifeplant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("attunable")
    inst.components.attunable:SetAttunableTag("remoteresurrector")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("fader")
    FadeIn(inst)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnDug)

    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:SetBurnTime(10)
    inst.components.burnable:AddBurnFX("fire", Vector3(0, 0, 0))
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_MED

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(6, 7)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)

    MakeLargePropagator(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    inst:ListenForEvent("activateresurrection", OnResurrect)
    inst:ListenForEvent("planted", OnPlanted)
    inst:ListenForEvent("onremove", OnRemoved)

    inst:DoTaskInTime(8 + math.random() * 20, UpdateAnimations)

    return inst
end

local function TestForPlant(inst)
    local ent = TheSim:FindFirstEntityWithTag("lifeplant")

    if ent and ent:GetDistanceSqToInst(inst) < 1 then
        inst:Remove()
    end
end

local function OnSparkleSpawned(inst)
    local ent = TheSim:FindFirstEntityWithTag("lifeplant") -- Assuming that there's only one lifeplant
    if ent then
        local x, y, z = ent.Transform:GetWorldPosition()
        local angle = inst:GetAngleToPoint(x, y, z)
        inst.Transform:SetRotation(angle)

        inst.components.locomotor:WalkForward()
        inst:DoPeriodicTask(0.1, TestForPlant)
    else
        inst:Remove()
    end
end

local function sparklefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lifeplant_fx")
    inst.AnimState:SetBuild("lifeplant_fx")
    inst.AnimState:PlayAnimation("single" .. math.random(1, 3), true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.3, 1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    RemovePhysicsColliders(inst)

    inst:AddTag("flying")
    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor:SetTriggersCreep(false)

    inst:DoTaskInTime(0, OnSparkleSpawned)

    inst.OnEntitySleep = inst.Remove

    return inst
end

return Prefab("lifeplant", fn, assets, prefabs),
       Prefab("lifeplant_sparkle", sparklefn, assets, prefabs)
