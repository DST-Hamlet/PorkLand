local assets =
{
    Asset("ANIM", "anim/poison.zip"),
}

local function kill(inst)
    if inst and inst:IsValid() then
        inst.SoundEmitter:KillSound("poisoned")
    end
    inst:Remove()
end

local function StopBubbles(inst)
    if inst and inst:IsValid() then
        inst.AnimState:PushAnimation("level" .. inst.level .. "_pst", false)
        inst:RemoveEventCallback("animqueueover", StopBubbles)
        inst:ListenForEvent("animqueueover", kill)
    end
end

local function common(level, loop)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("poison")
    inst.AnimState:SetBuild("poison")
    inst.AnimState:SetFinalOffset(2)

    inst:AddTag("fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.level = level or 2
    inst.loop = loop == nil and true or loop

    inst.AnimState:PlayAnimation("level" .. inst.level .. "_pre")
    inst.AnimState:PushAnimation("level" .. inst.level .. "_loop", inst.loop)
    if not inst.loop then
        inst:ListenForEvent("animqueueover", StopBubbles)
    end

    inst.SoundEmitter:PlaySound("ia/common/poisoned")

    inst.StopBubbles = StopBubbles

    return inst
end

function MakeBubble(name, level, loop)
    local function fn()
        local inst = common(2, true)
        return inst
    end

    local function shortfn()
        local inst = common(2, true)
        inst:DoTaskInTime(1, StopBubbles)
        return inst
    end

    local function lvl1()
        local inst = common(1, false)
        return inst
    end

    local function lvl1_loop()
        local inst = common(1, true)
        return inst
    end

    local function lvl2()
        local inst = common(2, false)
        return inst
    end

    local function lvl2_loop()
        local inst = common(2, true)
        return inst
    end

    local function lvl3()
        local inst = common(3, false)
        return inst
    end

    local function lvl3_loop()
        local inst = common(3, true)
        return inst
    end

    local function lvl4()
        local inst = common(4, false)
        return inst
    end

    local function lvl4_loop()
        local inst = common(4, true)
        return inst
    end

    local myFn = fn
    if level == 0 then
        myFn = shortfn
    elseif level == 1 then
        if loop then
            myFn = lvl1_loop
        else
            myFn = lvl1
        end
    elseif level == 2 then
        if loop then
            myFn = lvl2_loop
        else
            myFn = lvl2
        end
    elseif level == 3 then
        if loop then
            myFn = lvl3_loop
        else
            myFn = lvl3
        end
    elseif level == 4 then
        if loop then
            myFn = lvl4_loop
        else
            myFn = lvl4
        end
    end

    return Prefab( name, myFn, assets)
end

return MakeBubble("poisonbubble"),
    MakeBubble("poisonbubble_short", 0, true),
    MakeBubble("poisonbubble_level1", 1, false),
    MakeBubble("poisonbubble_level1_loop", 1, true),
    MakeBubble("poisonbubble_level2", 2, false),
    MakeBubble("poisonbubble_level2_loop", 2, false),
    MakeBubble("poisonbubble_level3", 3, false),
    MakeBubble("poisonbubble_level3_loop", 3, true),
    MakeBubble("poisonbubble_level4", 4, false),
    MakeBubble("poisonbubble_level4_loop", 4, true)
