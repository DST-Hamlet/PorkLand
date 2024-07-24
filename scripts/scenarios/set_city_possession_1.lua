local function OnCreate(inst, scenariorunner)
    inst:AddComponent("citypossession")
    inst.components.citypossession:SetCity(1)
    if inst.OnCityPossession then
        inst:OnCityPossession()
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
