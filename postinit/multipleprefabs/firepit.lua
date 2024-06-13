local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function make_postinitfn(rain_rate)
    local function updatefuelrate(inst)
        local rate = 1
        if TheWorld.state.israining and not inst.components.rainimmunity then
            rate = rate + rain_rate * (TheWorld.state.precipitationrate or 1)
        end
        if TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy() then
            rate = rate + TheWorld.net.components.plateauwind:GetWindSpeed() * TUNING.FIREPIT_WIND_RATE
        end
        inst.components.fueled.rate = rate
    end

    local function onupdatefueled(inst)
        if inst.components.burnable and inst.components.fueled then
            updatefuelrate(inst)
            inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
        end
    end

    local function fn(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst.components.fueled:SetUpdateFn(onupdatefueled)
    end

    return fn
end

AddPrefabPostInit("campfire", make_postinitfn(TUNING.CAMPFIRE_RAIN_RATE))
AddPrefabPostInit("firepit", make_postinitfn(TUNING.FIREPIT_RAIN_RATE))
AddPrefabPostInit("cotl_tabernacle_level1", make_postinitfn(TUNING.COTL_TABERNACLE_1.RAIN_RATE))
AddPrefabPostInit("cotl_tabernacle_level2", make_postinitfn(TUNING.COTL_TABERNACLE_2.RAIN_RATE))
AddPrefabPostInit("cotl_tabernacle_level3", make_postinitfn(TUNING.COTL_TABERNACLE_3.RAIN_RATE))
