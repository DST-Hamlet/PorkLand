local assets = {
    Asset("ANIM", "anim/grass_inwater.zip"),
    Asset("ANIM", "anim/reeds_water_build.zip"),
}

local prefabs = {
    "cutreeds",
}

local fn = function()
    local inst = Prefabs["reeds"].fn()

    inst.MiniMapEntity:SetIcon("reeds_in_water.tex")

    MakeObstaclePhysics(inst, .25)

    inst.AnimState:SetBank("grass_inwater")
    inst.AnimState:SetBuild("reeds_water_build")

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst:AddComponent("appeasement")
    -- inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL

    MakePickableBlowInWindGust(inst, TUNING.REEDS_WINDBLOWN_SPEED, TUNING.REEDS_WINDBLOWN_FALL_CHANCE)

    return inst
end

return Prefab("reeds_water", fn, assets, prefabs)
