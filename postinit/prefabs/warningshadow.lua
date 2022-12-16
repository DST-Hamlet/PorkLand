local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function shrink(inst, time, startsize, endsize)
    inst.AnimState:SetMultColour(1,1,1,0.33)
    inst.Transform:SetScale(startsize, startsize, startsize)
    inst.components.colourtweener:StartTween({1,1,1,0.75}, time)
    inst.components.sizetweener:StartTween(.5, time, inst.Remove)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")
end

local function postinit(inst)
    inst.entity:AddSoundEmitter()

    if TheWorld.ismastersim then

        inst:AddComponent("sizetweener")
        inst:AddComponent("colourtweener")

        inst.shrink = shrink
    end
end

AddPrefabPostInit("warningshadow", postinit)
