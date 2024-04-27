local function OnCreate(inst, scenariorunner)
    if inst.OnCreate then
        inst:OnCreate()
    end

    -- inst:AddComponent("citypossession")
    -- inst.components.citypossession:SetCity(2)
    -- if inst.citypossessionfn then
    -- 	inst.citypossessionfn(inst)
    -- end
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
