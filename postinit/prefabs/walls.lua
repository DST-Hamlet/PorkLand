local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function ongusthammerfn(inst)
    inst.components.health:DoDelta(-inst.windblown_damage, false, "wind")
end

AddPrefabPostInit("wall_wood", function(inst)
    inst.windblown_damage = TUNING.WALLWOOD_WINDBLOWN_DAMAGE
    inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.WALLWOOD_WINDBLOWN_SPEED)
    inst.components.blowinwindgust:SetDestroyChance(TUNING.WALLWOOD_WINDBLOWN_DAMAGE_CHANCE)
    inst.components.blowinwindgust:SetDestroyFn(ongusthammerfn)
    inst.components.blowinwindgust:Start()
end)

AddPrefabPostInit("wall_hay", function(inst)
    inst.windblown_damage = TUNING.WALLHAY_WINDBLOWN_DAMAGE
    inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.WALLHAY_WINDBLOWN_SPEED)
    inst.components.blowinwindgust:SetDestroyChance(TUNING.WALLHAY_WINDBLOWN_DAMAGE_CHANCE)
    inst.components.blowinwindgust:SetDestroyFn(ongusthammerfn)
    inst.components.blowinwindgust:Start()
end)
