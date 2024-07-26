local function OnCreate(inst, scenariorunner)
    inst:AddComponent("citypossession")
    inst.components.citypossession:SetCity(2)
    if inst.OnCityPossession then
        inst:OnCityPossession()
    end
    if inst.components.gridnudger then
        inst.components.gridnudger:Nudge()
    end
end

local function OnLoad(inst, scenariorunner)
end

local function OnDestroy(inst)
end

return
{
    OnCreate = OnCreate,
    OnLoad = OnLoad,
    OnDestroy = OnDestroy
}
