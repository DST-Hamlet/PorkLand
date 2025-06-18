local DecoCreator = require("prefabs/deco_util")

local function on_wall_ornament_built(inst)
    if not DecoCreator:IsBuiltOnBackWall(inst) then
        local bank = inst.bank .. "_side"
        inst.AnimState:SetBank(bank)
        inst.animdata = {
            bank = bank,
        }
    end
end

return  DecoCreator:Create("deco_wallornament_photo",             "interior_wallornament", "interior_wallornament", "photo",             {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_fulllength_mirror", "interior_wallornament", "interior_wallornament", "fulllength_mirror", {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_embroidery_hoop",   "interior_wallornament", "interior_wallornament", "embroidery_hoop",   {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_mosaic",            "interior_wallornament", "interior_wallornament", "mosaic",            {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_wreath",            "interior_wallornament", "interior_wallornament", "wreath",            {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_axe",               "interior_wallornament", "interior_wallornament", "axe",               {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_hunt",              "interior_wallornament", "interior_wallornament", "hunt",              {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_periodic_table",    "interior_wallornament", "interior_wallornament", "periodic_table",    {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_gears_art",         "interior_wallornament", "interior_wallornament", "gears_art",         {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_cape",              "interior_wallornament", "interior_wallornament", "cape",              {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_no_smoking",        "interior_wallornament", "interior_wallornament", "no_smoking",        {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built}),
        DecoCreator:Create("deco_wallornament_black_cat",         "interior_wallornament", "interior_wallornament", "black_cat",         {decal = true, tags={"wallsection"}, onbuilt = true, on_built_fn = on_wall_ornament_built})
