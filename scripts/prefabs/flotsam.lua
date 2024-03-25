local anim_appends =
{
    "",
    "2",
    "3",
    "4",
    "5",
}

local function Sink(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat/debris_submerge")
    inst.AnimState:PushAnimation("sink" .. inst.anim_append, false)
    inst:ListenForEvent("animover", inst.Remove)
end

local function MakeFlotsam(name)
    local assets =
    {
        Asset("ANIM", "anim/flotsam_debris_" .. name .. "_build.zip"),
        Asset("ANIM", "anim/flotsam_debris_sw.zip"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)

        -- just like Boat fragments, flotsam are always wet!
        inst:AddTag("wet")

        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat/debris_breakoff")

        inst.AnimState:SetBank("flotsam_debris_sw")
        inst.AnimState:SetBuild("flotsam_debris_" .. name .. "_build")
        inst.anim_append = anim_appends[math.random(#anim_appends)]
        inst.AnimState:PlayAnimation("idle" .. inst.anim_append, true)

        inst:DoTaskInTime(3 + math.random() * 4, Sink)

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        inst.persists = false

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.foodtype = FOODTYPE.WOOD
        inst.components.edible.healthvalue = 0
        inst.components.edible.hungervalue = 0

        return inst
    end

    return Prefab("flotsam_" .. name, fn, assets)
end

return MakeFlotsam("lograft"),
    MakeFlotsam("bamboo"),
    MakeFlotsam("rowboat"),
    MakeFlotsam("armoured"),
    MakeFlotsam("cargo"),
    MakeFlotsam("corkboat"),
    MakeFlotsam("surfboard")
