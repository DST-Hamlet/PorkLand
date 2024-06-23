-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------

local function speed_coffee_beans_attach(inst, target)
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "CAFFEINE", TUNING.CAFFEINE_FOOD_BONUS_SPEED)
    end
end

local function speed_coffee_attach(inst, target)
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "CAFFEINE", TUNING.CAFFEINE_FOOD_BONUS_SPEED)
    end
end

local function speed_tea_attach(inst, target)
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "CAFFEINE", 1 + (TUNING.CAFFEINE_FOOD_BONUS_SPEED - 1)/2)
    end
end

local function speed_icedtea_attach(inst, target)
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "CAFFEINE", 1 + (TUNING.CAFFEINE_FOOD_BONUS_SPEED - 1)/3)
    end
end

local function speed_caffeine_detach(inst, target, data)
    if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "CAFFEINE")
    end
end

-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, prefabs)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        -- target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", duration)

        -- target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        -- target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_"..string.upper(name), priority = priority })
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", duration)
        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end

    return Prefab("buff_"..name, fn, nil, prefabs)
end

return  MakeBuff("speed_coffee_beans", speed_coffee_beans_attach, nil, speed_caffeine_detach, TUNING.FOOD_SPEED_AVERAGE, 1, {}),
        MakeBuff("speed_coffee", speed_coffee_attach, nil, speed_caffeine_detach, TUNING.FOOD_SPEED_LONG, 1, {}),
        MakeBuff("speed_tea", speed_tea_attach, nil, speed_caffeine_detach, TUNING.FOOD_SPEED_LONG / 2, 1, {}),
        MakeBuff("speed_icedtea", speed_icedtea_attach, nil, speed_caffeine_detach, TUNING.FOOD_SPEED_LONG / 3, 1, {})
