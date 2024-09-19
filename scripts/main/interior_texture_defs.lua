local Assets = {} -- for modmain
local TEXTURE_DEF = {}
local TEXTURE_DEF_INDEX = {}
local MINIMAP_DEF = {}
local MINIMAP_DEF_INDEX = {}
local CC_DEF = {}
local CC_DEF_INDEX = {}

for _, v in ipairs({
    "levels/textures/interiors/antcave_floor.tex",           "levels/textures/interiors/shop_floor_sheetmetal.tex",
    "levels/textures/interiors/antcave_wall_rock.tex",       "levels/textures/interiors/shop_floor_woodmetal.tex",
    "levels/textures/interiors/batcave_floor.tex",           "levels/textures/interiors/shop_floor_woodpaneling2.tex",
    "levels/textures/interiors/batcave_wall_rock.tex",       "levels/textures/interiors/shop_wall_bricks.tex",
    "levels/textures/interiors/floor_cityhall.tex",          "levels/textures/interiors/shop_wall_checkered.tex",
    "levels/textures/interiors/floor_gardenstone.tex",       "levels/textures/interiors/shop_wall_checkered_metal.tex",
    "levels/textures/interiors/floor_geometrictiles.tex",    "levels/textures/interiors/shop_wall_circles.tex",
    "levels/textures/interiors/floor_marble_royal.tex",      "levels/textures/interiors/shop_wall_floraltrim2.tex",
    "levels/textures/interiors/floor_shag_carpet.tex",       "levels/textures/interiors/shop_wall_fullwall_moulding.tex",
    "levels/textures/interiors/floor_transitional.tex",      "levels/textures/interiors/shop_wall_marble.tex",
    "levels/textures/interiors/floor_woodpanels.tex",        "levels/textures/interiors/shop_wall_moroc.tex",
    "levels/textures/interiors/ground_ruins_slab.tex",       "levels/textures/interiors/shop_wall_sunflower.tex",
    "levels/textures/interiors/ground_ruins_slab_blue.tex",  "levels/textures/interiors/shop_wall_sunflower2.tex",
    "levels/textures/interiors/harlequin_panel.tex",         "levels/textures/interiors/shop_wall_tiles.tex",
    "levels/textures/interiors/pig_ruins_panel.tex",         "levels/textures/interiors/shop_wall_upholstered.tex",
    "levels/textures/interiors/pig_ruins_panel_blue.tex",    "levels/textures/interiors/shop_wall_woodwall.tex",
    "levels/textures/interiors/shop_floor_checker.tex",      "levels/textures/interiors/wall_mayorsoffice_whispy.tex",
    "levels/textures/interiors/shop_floor_checkered.tex",    "levels/textures/interiors/wall_peagawk.tex",
    "levels/textures/interiors/shop_floor_herringbone.tex",  "levels/textures/interiors/wall_plain_DS.tex",
    "levels/textures/interiors/shop_floor_hexagon.tex",      "levels/textures/interiors/wall_plain_RoG.tex",
    "levels/textures/interiors/shop_floor_hoof_curvy.tex",   "levels/textures/interiors/wall_rope.tex",
    "levels/textures/interiors/shop_floor_marble.tex",       "levels/textures/interiors/wall_royal_high.tex",
    "levels/textures/interiors/shop_floor_octagon.tex",

    "levels/textures/noise_woodfloor.tex",
})
do
    table.insert(Assets, Asset("IMAGE", v))
    table.insert(TEXTURE_DEF, {
        name = string.sub(v, string.find(v, "[^/]*$")):gsub("%.tex", ""),
        path = v,
    })
end

for _, v in ipairs({
    "levels/textures/map_interior/exit.tex",                    "levels/textures/map_interior/mini_vamp_cave_noise.tex",
    "levels/textures/map_interior/frame.tex",                   "levels/textures/map_interior/passage.tex",
    "levels/textures/map_interior/mini_antcave_floor.tex",      "levels/textures/map_interior/passage_blocked.tex",
    "levels/textures/map_interior/passage_unknown.tex",
}) do
    table.insert(Assets, Asset("IMAGE", v))
    table.insert(MINIMAP_DEF, {
        name = string.sub(v, string.find(v, "[^/]*$")):gsub("%.tex", ""),
        path = v,
    })
    -- TODO: minimap entity asset
end

-- list of cc used in interior
for _, v in ipairs({
    "images/colour_cubes/day05_cc.tex",
    "images/colour_cubes/pigshop_interior_cc.tex",
}) do
    table.insert(Assets, Asset("IMAGE", v))
    table.insert(CC_DEF, {
        path = v,
    })
end

-- check index can be reinterpreted by net var
assert(#TEXTURE_DEF < 255) -- as net_byte
assert(#MINIMAP_DEF < 255) -- net_byte
assert(#CC_DEF < 63) -- as net_smallbyte

for i, v in ipairs(TEXTURE_DEF) do
    TEXTURE_DEF_INDEX[v.name] = i
    TEXTURE_DEF_INDEX[v.path] = i
end

for i, v in ipairs(MINIMAP_DEF) do
    MINIMAP_DEF_INDEX[v.name] = i
    MINIMAP_DEF_INDEX[v.path] = i
end

for i, v in ipairs(CC_DEF) do
    CC_DEF_INDEX[v.path] = i
end

return {
    TEXTURE_DEF = TEXTURE_DEF,
    MINIMAP_DEF = MINIMAP_DEF,
    TEXTURE_DEF_INDEX = TEXTURE_DEF_INDEX,
    MINIMAP_DEF_INDEX = MINIMAP_DEF_INDEX,
    CC_DEF = CC_DEF,
    CC_DEF_INDEX = CC_DEF_INDEX,
    Assets = Assets,
    ToPath = function(v) return "levels/textures/interiors/"..v..".tex" end,
}
