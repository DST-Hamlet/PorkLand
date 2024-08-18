local function OnCreate(inst, scenariorunner)
    inst.components.uptile:FixAllTiles()
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
