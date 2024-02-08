local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local ruins_statue = {
    "head",
    "mage",
}

local function OnDislodged(inst)
    local ruins_statue = SpawnPrefab(inst.prefab .. "_nogem")
    local x,y,z = inst.Transform:GetWorldPosition()
    ruins_statue.Transform:SetPosition(x,y,z)

    inst.persists = false
    inst:DoTaskInTime(0, inst.Remove)
end

local function CanBeDislodgedFn(inst)
    return inst.components.workable and inst.components.workable.workleft >= TUNING.MARBLEPILLAR_MINE*(1/3)
end

local function fn(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("dislodgeable")
    inst.components.dislodgeable:SetUp(inst.gemmed)
    inst.components.dislodgeable:SetDropFromSymbol("swap_gem")
    inst.components.dislodgeable:SetOnDislodgedFn(OnDislodged)
    inst.components.dislodgeable:SetCanBeDislodgedFn(CanBeDislodgedFn)
end

for _, v in pairs(ruins_statue) do
    AddPrefabPostInit("ruins_statue_" .. v, fn)
end
