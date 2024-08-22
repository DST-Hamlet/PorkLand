require("prefabs/walls")

local wallprefabs = {}

local walldata = {
    {
        name = "pig_ruins",
        material = "stone",
        tags = { "stone" },
        loot = "rocks",
        maxloots = 2,
        maxhealth = TUNING.STONEWALL_HEALTH,
        buildsound = "dontstarve/common/place_structure_stone",
    },
}

for _, v in ipairs(walldata) do
    local wall, item, placer = MakeWallType(v)
    table.insert(wallprefabs, wall)
    table.insert(wallprefabs, item)
    table.insert(wallprefabs, placer)
end

return unpack(wallprefabs)
