local assets =
{
    Asset("ANIM", "anim/thunderbird_basic.zip"),
    Asset("ANIM", "anim/thunderbird_build.zip"),
    Asset("ANIM", "anim/thunderbird_fx.zip"),
}

local prefabs =
{
    "drumstick",
    "feather_thunder",
    "thunderbird_fx",
}

local loot =
{
    "drumstick",
    "drumstick",
    "feather_thunder"
}

local LIGHTNING_COUNT = 3
local LIGHTNING_COUNT_APORKALYPSE = 10
local LIGHTNING_COOLDOWN = 60 -- seconds

local function OnTimerDone(inst, data)
    if data.name == "fleeing_cd" then
        inst.is_fleeing = false
    elseif data.name == "charge_cd" then
        inst.cooling_down = false
        inst.components.timer:SetTimeLeft("fleeing_cd", 0) -- stop fleeing
    end
end

local function DoLightning(inst, target)
    local num_strikes = TheWorld.state.isaporkalypse and LIGHTNING_COUNT_APORKALYPSE or LIGHTNING_COUNT
    local radius, angle, position

    for i = 1, num_strikes do
        inst:DoTaskInTime(0.4 * i, function()
            radius = math.random(4, 8)
            angle = i * ((4 * PI) / num_strikes)
            position = Vector3(target.Transform:GetWorldPosition()) + Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))
            TheWorld:PushEvent("ms_sendlightningstrike", position)
        end)
    end

    inst.cooling_down = true
    inst.components.timer:StartTimer("charge_cd", LIGHTNING_COOLDOWN)
end

local function SpawnFX(inst)
    if not inst.fx then
        inst.fx = inst:SpawnChild("thunderbird_fx")
        inst.fx.Transform:SetPosition(0, 0, 0)
   end
end

local brain = require("brains/thunderbirdbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetRadius(2.5)
    inst.Light:SetColour(120/255, 120/255, 120/255)
    inst.Light:Enable(true)

    inst.DynamicShadow:SetSize(1.5, 0.75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("thunderbird")
    inst.AnimState:SetBuild("thunderbird")
    inst.AnimState:Hide("hat")

    MakeCharacterPhysics(inst, 50, 0.5)

    inst:AddTag("animal")
    inst:AddTag("character")
    inst:AddTag("thunderbird")
    inst:AddTag("lightningblocker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.THUNDERBIRD_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.THUNDERBIRD_WALK_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.RAW, FOODTYPE.VEGGIE}, {FOODTYPE.RAW})

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.THUNDERBIRD_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:SetStateGraph("SGthunderbird")
    inst:SetBrain(brain)

    MakeMediumFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst, "body")
    MakePoisonableCharacter(inst)
    MakeHauntablePanic(inst)

    inst.DoLightning = DoLightning

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:DoTaskInTime(0, SpawnFX)

    -- inst.components.burnable.lightningimmune = true

    return inst
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("thunderbird_fx")

    inst.AnimState:SetBank("thunderbird_fx")
    inst.AnimState:SetBuild("thunderbird_fx")
    inst.AnimState:SetSortOrder(2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(math.random(), function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 0.5, {"thunderbird_fx"})
        for _, v in ipairs(ents)do
            if v ~= inst then
                v:Remove()
            end
        end
    end)

    return inst
end

return Prefab("thunderbird", fn, assets, prefabs),
       Prefab("thunderbird_fx", fx_fn, assets, prefabs)
