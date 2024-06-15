local DecoCreator = require("prefabs/deco_util")

return  DecoCreator:Create("deco_florist_vines1", "interior_wall_decals_florist", "interior_wall_decals_florist", "vines_1", {decal=true, background=2}),
        DecoCreator:Create("deco_florist_vines2", "interior_wall_decals_florist", "interior_wall_decals_florist", "vines_2", {decal=true, background=2}),
        DecoCreator:Create("deco_florist_vines3", "interior_wall_decals_florist", "interior_wall_decals_florist", "vines_3", {decal=true, background=2}),

        DecoCreator:Create("deco_florist_hangingplant1", "ceiling_decor", "ceiling_decor", "plant1_idle", {loopanim=true}),
        DecoCreator:Create("deco_florist_hangingplant2", "ceiling_decor", "ceiling_decor", "plant2_idle", {loopanim=true}),

        DecoCreator:Create("deco_florist_plantholder",    "interior_wall_decals_florist", "interior_wall_decals_florist", "plantstand"),
        DecoCreator:Create("deco_florist_latice_front",   "interior_wall_decals_florist", "interior_wall_decals_florist", "lattice_front"),
        DecoCreator:Create("deco_florist_latice_side",    "interior_wall_decals_florist", "interior_wall_decals_florist", "lattice_sidewall",     {decal=true}),
        DecoCreator:Create("deco_florist_pillar_front",   "interior_wall_decals_florist", "interior_wall_decals_florist", "pillar_front",         {decal=true}),
        DecoCreator:Create("deco_florist_pillar_side",    "interior_wall_decals_florist", "interior_wall_decals_florist", "pillar_sidewall",      {decal=true}),
        DecoCreator:Create("deco_florist_picture",        "interior_wall_decals_florist", "interior_wall_decals_florist", "pictureframe_front",   {decal=true, background=2}),
        DecoCreator:Create("deco_florist_cagedplant",     "interior_wall_decals_florist", "interior_wall_decals_florist", "cageplant_front",      {decal=true, background=2})