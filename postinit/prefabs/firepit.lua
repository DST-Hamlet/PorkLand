local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)


local function updatefuelrate(inst)
    local rate = 1
    if TheWorld.state.israining and not inst.components.rainimmunity then
        rate = rate + TUNING.FIREPIT_RAIN_RATE * TheWorld.state.precipitationrate or 1
    end
    if TheWorld.components.plateauwind and TheWorld.components.plateauwind:GetIsWindy() then
        rate = rate + TheWorld.components.plateauwind:GetWindSpeed() * TUNING.FIREPIT_WIND_RATE
    end
    inst.components.fueled.rate = rate
end

local function onupdatefueled(inst)
    if inst.components.burnable and inst.components.fueled then
        updatefuelrate(inst)
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end

AddPrefabPostInit("firepit", function(inst)
    inst.components.fueled:SetUpdateFn(onupdatefueled)
end)

AddPrefabPostInit("campfire", function(inst)
    inst.components.fueled:SetUpdateFn(onupdatefueled)
end)
