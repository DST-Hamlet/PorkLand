local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local HIGHT_PRECISION_PREFABS =
{
    "creepyeyes",
    "shadowwatcher",
    "shadowhand_arm",
}

-- 对于特定实体使用低频刷新进行优化
local HIGHT_PRECISION_PREFABS_LOW =
{
    "flower_cave",
    "flower_cave_double",
    "flower_cave_triple",
    "lightflier_flower",
}

local function add_high_precision(inst)
    inst.components.lightwatcherproxy:UseHighPrecision()
end

local function add_high_precision_low(inst)
    inst.components.lightwatcherproxy:UseHighPrecision(true)
end

for _, prefab in ipairs(HIGHT_PRECISION_PREFABS) do
    AddPrefabPostInit(prefab, add_high_precision)
end

for _, prefab in ipairs(HIGHT_PRECISION_PREFABS_LOW) do
    AddPrefabPostInit(prefab, add_high_precision_low)
end
