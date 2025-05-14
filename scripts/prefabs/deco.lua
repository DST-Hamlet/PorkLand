local DecoCreator = require("prefabs/deco_util")

local function on_window_built(inst)
    print("on_window_built", inst.Transform:GetRotation())
    if DecoCreator:IsBuiltOnBackWall(inst) then
        local bank = inst.bank:sub(1, -6) -- Remove _side
        inst.AnimState:SetBank(bank)
        inst.bank = bank
        inst.animdata = {
            bank = bank,
        }
        if inst.children_to_spawn then
            for i, children in ipairs(inst.children_to_spawn) do
                if children:sub(-8) ~= "backwall" then
                    inst.children_to_spawn[i] = children .. "_backwall"
                end
            end
        end
    end
end

local function on_window_built_with_curtain(inst)
    inst.AnimState:Show("curtain")
    inst.has_curtain = true
    on_window_built(inst)
end

local function make_on_beam_built(corner_beam_animation, background)
    return function(inst)
        local position = inst:GetPosition()
        local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(position)
        if current_interior then
            local originpt = current_interior:GetPosition()

            if position.z >= originpt.z then
                inst.Transform:SetRotation(90)
            else
                inst.Transform:SetRotation(-90)
            end

            if position.x <= originpt.x then
                local animdata = shallowcopy(inst.components.rotatingbillboard.animdata)
                animdata.anim = corner_beam_animation
                inst.animdata = animdata
                inst.components.rotatingbillboard:SetAnimation_Server(animdata)
                if not inst.AnimState:IsCurrentAnimation(corner_beam_animation) then
                    inst.AnimState:PlayAnimation(corner_beam_animation)
                end
                if background then
                    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
                    inst.AnimState:SetSortOrder(background)
                    inst.setbackground = background
                end
            end
        end
    end
end

return  DecoCreator:Create("window_round",                 "interior_window", "interior_window_side", "day_loop",          {loopanim=true, decal=true, background=3, dayevents=true,                children={"window_round_light"},          tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built_with_curtain}),
        DecoCreator:Create("window_round_backwall",        "interior_window", "interior_window", "day_loop",               {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_round", name_override="window_round"}),

        DecoCreator:Create("window_round_curtains_nails", "interior_window", "interior_window_side", "day_loop",           {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_round_curtains_nails_backwall", "interior_window", "interior_window", "day_loop",       {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_round_curtains_nails"}),

        DecoCreator:Create("window_round_burlap", "interior_window_burlap", "interior_window_burlap_side", "day_loop",     {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_round_burlap_backwall", "interior_window_burlap", "interior_window_burlap", "day_loop", {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_round_burlap"}),

        DecoCreator:Create("window_small_peaked", "interior_window_small", "interior_window_small_side", "day_loop",       {loopanim=true, decal=nil, background=3, dayevents=true, curtains=nil, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_small_peaked_backwall", "interior_window_small", "interior_window_small", "day_loop",   {loopanim=true, decal=nil, bckground=3, dayevents=true, curtains=nil, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_small_peaked"}),

        DecoCreator:Create("window_large_square", "interior_window_large", "interior_window_side", "day_loop",             {loopanim=true, decal=nil, background=3, dayevents=true, curtains=nil, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_large_square_backwall", "interior_window_large", "interior_window", "day_loop",         {loopanim=true, decal=nil, bckground=3, dayevents=true, curtains=nil, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_large_square"}),

        DecoCreator:Create("window_tall", "interior_window_tall", "interior_window_tall_side", "day_loop",                 {loopanim=true, decal=nil, background=3, dayevents=true, curtains=nil, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_tall_backwall", "interior_window_tall", "interior_window_tall", "day_loop",             {loopanim=true, decal=nil, bckground=3, dayevents=true, curtains=nil, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_tall"}),

        --DecoCreator:Create("window_arcane", "interior_window", "interior_window_side", "day_loop",                        {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_round_arcane", "window_arcane_build", "interior_window_large_side", "day_loop",         {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_round_arcane_backwall", "window_arcane_build", "interior_window_large", "day_loop",     {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_round_arcane"}),

        DecoCreator:Create("window_small_peaked_curtain", "interior_window_small", "interior_window_side", "day_loop",                      {loopanim=true, decal=nil, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_small_peaked_curtain_backwall", "interior_window_small", "interior_window", "day_loop",                  {loopanim=true, decal=nil, background=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_small_peaked_curtain"}),

        DecoCreator:Create("window_large_square_curtain", "interior_window_large", "interior_window_large_side", "day_loop",     {loopanim=true, decal=nil, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_large_square_curtain_backwall", "interior_window_large", "interior_window_large", "day_loop", {loopanim=true, decal=nil, bckground=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_large_square_curtain"}),

        DecoCreator:Create("window_tall_curtain", "interior_window_tall", "interior_window_tall_side", "day_loop",               {loopanim=true, decal=nil, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_tall_curtain_backwall", "interior_window_tall", "interior_window_tall", "day_loop",           {loopanim=true, decal=nil, bckground=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_tall_curtain"}),

        DecoCreator:Create("window_square_weapons", "window_weapons_build", "interior_window_large_side", "day_loop",            {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_square_weapons_backwall", "window_weapons_build", "interior_window_large", "day_loop",        {loopanim=true, decal=true, background=3, dayevents=true, curtains=true, children={"window_round_light_backwall"}, tags={"NOBLOCK","wallsection"}, onbuilt=true, recipeproxy="window_square_weapons"}),

        DecoCreator:Create("window_greenhouse", "interior_window_greenhouse_build", "interior_window_greenhouse_side", "day_loop",     {loopanim=true, decal=nil, background=3, dayevents=true, curtains=true, children={"window_big_light"}, tags={"NOBLOCK","wallsection","fullwallsection"}, onbuilt=true, on_built_fn = on_window_built}),
        DecoCreator:Create("window_greenhouse_backwall", "interior_window_greenhouse_build", "interior_window_greenhouse", "day_loop", {loopanim=true, decal=nil, background=3, dayevents=true, curtains=true, children={"window_big_light_backwall"}, tags={"NOBLOCK","wallsection","fullwallsection"}, onbuilt=true, recipeproxy="window_greenhouse"}),

        DecoCreator:Create("window_round_light", "interior_window", "interior_window_light_side", "day_loop",                    {loopanim=true, decal=true, light=true, dayevents=true, followlight ="natural", windowlight =true, dustzmod=1.3, tags={"NOBLOCK","NOCLICK"}}),
        DecoCreator:Create("window_round_light_backwall",  "interior_window", "interior_window_light", "day_loop",               {loopanim=true, decal=true, light=true, dayevents=true, followlight ="natural", windowlight =true, dustxmod=1.3, tags={"NOBLOCK","NOCLICK"}}),

        DecoCreator:Create("window_big_light", "interior_window_greenhouse_build", "interior_window_greenhouse_light_side", "day_loop",                    {loopanim=true, decal=true, light=true, dayevents=true, followlight ="natural", windowlight =true, dustzmod=1.3, tags={"NOBLOCK","NOCLICK"}}),
        DecoCreator:Create("window_big_light_backwall",  "interior_window_greenhouse_build", "interior_window_greenhouse_light", "day_loop",               {loopanim=true, decal=true, light=true, dayevents=true, followlight ="natural", windowlight =true, dustxmod=1.3, tags={"NOBLOCK","NOCLICK"}}),

        DecoCreator:Create("deco_wallpaper_rip1", "interior_wall_decals", "wall_decals", "1",       {decal=true, tags={"NOBLOCK"}}),
        DecoCreator:Create("deco_wallpaper_rip2", "interior_wall_decals", "wall_decals", "2",       {decal=true, tags={"NOBLOCK"}}),
        DecoCreator:Create("deco_wallpaper_rip_side1", "interior_wall_decals", "wall_decals", "10", {decal=true, tags={"NOBLOCK"}}),
        DecoCreator:Create("deco_wallpaper_rip_side2", "interior_wall_decals", "wall_decals", "11", {decal=true, tags={"NOBLOCK"}, background=3}),
        DecoCreator:Create("deco_wallpaper_rip_side3", "interior_wall_decals", "wall_decals", "8",  {tags={"NOBLOCK"}}),
        DecoCreator:Create("deco_wallpaper_rip_side4", "interior_wall_decals", "wall_decals", "9",  {tags={"NOBLOCK"}}),

        DecoCreator:Create("deco_wood_cornerbeam",  "interior_wall_decals", "wall_decals", "4", {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_wood", background=3 }),
        DecoCreator:Create("deco_wood_beam",        "interior_wall_decals", "wall_decals", "3", {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_wood", on_built_fn = make_on_beam_built("4", 3)}),

        DecoCreator:Create("deco_round_beam",       "interior_wall_decals_accademia", "wall_decals_accademia", "pillar_round_front",  {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_round", on_built_fn = make_on_beam_built("pillar_round_corner", 3)}),
        DecoCreator:Create("deco_round_cornerbeam", "interior_wall_decals_accademia", "wall_decals_accademia", "pillar_round_corner", {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_round", background=3 }),

        -- hat store
        DecoCreator:Create("deco_millinery_beam",        "interior_wall_decals_millinery", "wall_decals_millinery", "pillar_front",          {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_millinery", on_built_fn = make_on_beam_built("pillar_corner", 3)}),
        DecoCreator:Create("deco_millinery_beam2",       "interior_wall_decals_millinery", "wall_decals_millinery", "pillar_boxes_front",    {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),
        DecoCreator:Create("deco_millinery_beam3",       "interior_wall_decals_millinery", "wall_decals_millinery", "pillar_quilted_front",  {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),

        DecoCreator:Create("deco_millinery_cornerbeam",  "interior_wall_decals_millinery", "wall_decals_millinery", "pillar_corner",         {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_millinery", background=3 }),
        DecoCreator:Create("deco_millinery_cornerbeam2", "interior_wall_decals_millinery", "wall_decals_millinery", "pillar_boxes_corner",   {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, background=3 }),
        DecoCreator:Create("deco_millinery_cornerbeam3", "interior_wall_decals_millinery", "wall_decals_millinery", "pillar_quilted_corner", {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true, background=3 }),

        DecoCreator:Create("sewingmachine", "interior_wall_decals_millinery", "wall_decals_millinery", "sewingmachine", {decal=true, tags={"furniture"}, onbuilt=true}),
        DecoCreator:Create("worktable", "interior_wall_decals_millinery", "wall_decals_millinery", "worktable", {decal=true, tags={"furniture"}, onbuilt=true}),

        DecoCreator:Create("picture_1", "interior_wall_decals_millinery", "wall_decals_millinery", "picture1_sidewall", {decal=true}),
        DecoCreator:Create("picture_2", "interior_wall_decals_millinery", "wall_decals_millinery", "picture2_sidewall", {decal=true}),

        DecoCreator:Create("hat_lamp_side",  "interior_wall_decals_millinery", "wall_decals_millinery", "sconce_sidewall", {decal=true}),
        DecoCreator:Create("hat_lamp_front", "interior_wall_decals_millinery", "wall_decals_millinery", "sconce_backwall", {decal=true}),

        DecoCreator:Create("hatbox1",  "interior_wall_decals_millinery", "wall_decals_millinery", "hatbox1", {decal=true}),
        DecoCreator:Create("hatbox2",  "interior_wall_decals_millinery", "wall_decals_millinery", "hatbox2", {decal=true}),

        -- weapon store
        DecoCreator:Create("shield_axes", "interior_wall_decals_weapons", "wall_decals_weapons", "shield_axes", {decal=true}),
        DecoCreator:Create("shield_spears", "interior_wall_decals_weapons", "wall_decals_weapons", "shield_spears", {decal=true}),
        DecoCreator:Create("spears_sidewall", "interior_wall_decals_weapons", "wall_decals_weapons", "spears_sidewall", {decal=true}),
        DecoCreator:Create("shield_sidewall", "interior_wall_decals_weapons", "wall_decals_weapons", "shield_sidewall", {decal=true}),

        DecoCreator:Create("deco_weapon_beam1", "interior_wall_decals_weapons", "wall_decals_weapons", "pillar_front", {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),
        DecoCreator:Create("deco_weapon_beam2", "interior_wall_decals_weapons", "wall_decals_weapons", "pillar_corner", {decal=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),

        DecoCreator:Create("wall_light1", "interior_wall_decals", "wall_decals", "6",      {decal=true, light=true}),
        DecoCreator:Create("wall_deco_truss1", "interior_wall_decals", "wall_decals", "5", {scale={x=1.12, y=1, z=1}}),

        DecoCreator:Create("light_dust_fx", "light_dust_fx", "light_dust_fx", "idle", {loopanim=true, tags={"NOBLOCK"}}),

        -- hoofspa
        DecoCreator:Create("deco_marble_beam", "interior_wall_decals_hoofspa", "wall_decals_hoofspa", "pillar",                  {decal=true, loopanim=true, light=DecoCreator:GetLights().SMALL, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_marble", on_built_fn = make_on_beam_built("pillar_corner", 3)}),
        DecoCreator:Create("deco_marble_cornerbeam", "interior_wall_decals_hoofspa", "wall_decals_hoofspa", "pillar_corner",     {decal=true, loopanim=true, light=DecoCreator:GetLights().SMALL, tags={"NOBLOCK","cornerpost"}, onbuilt=true, name_override = "deco_marble", background=3 }),

        DecoCreator:Create("deco_valence", "interior_wall_decals_hoofspa", "wall_decals_hoofspa",  "vallance_1pc",  {decal=true, background=3}),
        DecoCreator:Create("wall_mirror",  "interior_wall_mirror",         "wall_mirror",          "idle",          {background=3, mirror=true}),
        DecoCreator:Create("deco_chaise",  "interior_floor_decor",         "interior_floor_decor", "chaise",        {physics="sofa_physics", tags={"furniture", "rotatableobject", "limited_chair"}, onbuilt=true, cansit = true}),

        DecoCreator:Create("wall_light_hoofspa", "interior_wall_decals_hoofspa", "wall_decals_hoofspa", "sconce_sidewall",       {light=DecoCreator:GetLights().SMALL}),
        DecoCreator:Create("wall_light_hoofspa", "interior_wall_decals_hoofspa", "wall_decals_hoofspa", "sconce_backwall",       {light=DecoCreator:GetLights().SMALL}),

        -- ruins
        DecoCreator:Create("deco_ruins_crack_roots1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "hole_1",            {decal=true, background=1}),
        DecoCreator:Create("deco_ruins_crack_roots2", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "hole_2",            {decal=true, background=1}),
        DecoCreator:Create("deco_ruins_crack_roots3", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "roots_1",           {decal=true, background=1}),
        DecoCreator:Create("deco_ruins_crack_roots4", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "roots_2",           {decal=true, background=1}),

        DecoCreator:Create("deco_ruins_roots1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "vines_1",                 {decal=true, background=2}),
        DecoCreator:Create("deco_ruins_roots2", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "vines_2",                 {decal=true, background=2}),
        DecoCreator:Create("deco_ruins_roots3", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "vines_3",                 {decal=true, background=2}),

        DecoCreator:Create("deco_ruins_pigking_relief", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_king",     {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigman_relief2", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_happy",    {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigqueen_relief", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_queen",   {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigman_relief1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_confused", {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigman_relief3", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_surprise", {decal=true, background=1, name_override="pig_ruins_dart_trap"}),

        DecoCreator:Create("deco_ruins_pigman_relief_side", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_sidewall",  {decal=true, background=1, name_override="pig_ruins_dart_trap"}),

        DecoCreator:Create("deco_ruins_pigman_relief4", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_head",        {decal=true, background=1, name_override="pig_ruins_dart_trap"}),

        DecoCreator:Create("deco_ruins_cornerbeam", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_corner",          {decal=true, background=3, tags={"cornerpost"}}),
        DecoCreator:Create("deco_ruins_cornerbeam_heavy", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_corner_lg", {decal=true, background=3, tags={"cornerpost"}}),

        DecoCreator:Create("deco_ruins_corner_tree", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "giant_roots",         {decal=true, background=3, finaloffset=5, physics="tree_physics"}),  -- , minimapicon="pig_ruins_tree_roots_int.tex"
        DecoCreator:Create("deco_ruins_beam_heavy", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_side_lg",       {decal=true, background=3}),
        DecoCreator:Create("deco_ruins_beam", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_front",               {decal=true}),

        DecoCreator:Create("deco_ruins_beam_room", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_front",          {decal=true, physics="post_physics", workable=true, minimapicon="pig_ruins_pillar.tex"}),
        DecoCreator:Create("deco_ruins_beam_room_broken", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_broken",  {decal=true, physics="post_physics", minimapicon="pig_ruins_pillar.tex"}),
        DecoCreator:Create("deco_ruins_beam_broken", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "pillar_broken",       {decal=true, background=3}),
        DecoCreator:Create("deco_ruins_wallstrut", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "support_side",          {decal=true}),
        DecoCreator:Create("deco_ruins_walltorch", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "sconce_metal_sidewall", {decal=true, background=3}),


                    -- THE BLUE RUINS ART
        DecoCreator:Create("deco_ruins_pigking_relief_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_king",     {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigman_relief2_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_happy",    {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigqueen_relief_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_queen",   {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigman_relief1_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_confused", {decal=true, background=1, name_override="pig_ruins_dart_trap"}),
        DecoCreator:Create("deco_ruins_pigman_relief3_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_surprise", {decal=true, background=1, name_override="pig_ruins_dart_trap"}),

        DecoCreator:Create("deco_ruins_pigman_relief_side_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_sidewall",  {decal=true, background=1, name_override="pig_ruins_dart_trap"}),

        DecoCreator:Create("deco_ruins_pigman_relief4_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_head",        {decal=true, background=1, name_override="pig_ruins_dart_trap"}),

        DecoCreator:Create("deco_ruins_cornerbeam_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_corner",          {decal=true, background=3, tags={"cornerpost"}}),
        DecoCreator:Create("deco_ruins_cornerbeam_heavy_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_corner_lg", {decal=true, background=3, tags={"cornerpost"}}),

        DecoCreator:Create("deco_ruins_beam_heavy_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_side_lg",       {decal=true, background=3}),
        DecoCreator:Create("deco_ruins_beam_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_front",               {decal=true}),

        DecoCreator:Create("deco_ruins_beam_room_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_front",          {decal=true, physics="post_physics", workable=true, minimapicon="pig_ruins_pillar.tex"}),
        DecoCreator:Create("deco_ruins_beam_room_broken_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_broken",  {decal=true, physics="post_physics", minimapicon="pig_ruins_pillar.tex"}),
        DecoCreator:Create("deco_ruins_beam_broken_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "pillar_broken",       {decal=true, background=3}),


     --   DecoCreator:Create("deco_ruins_fountain", "pig_ruins_well", "pig_ruins_well", "idle_full",                                      {loopanim=true, decal=true, physics="pond_physics", minimapicon="pig_ruins_well.tex"}),

        DecoCreator:Create("deco_ruins_wallcrumble_1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "2",                 {decal=true, background=1}),
        DecoCreator:Create("deco_ruins_wallcrumble_side_1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "1",            {decal=true}),

        DecoCreator:Create("deco_ruins_writing1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "latin_5",                {decal=true, background=1, prefabname="pig_latin_1" }),

        -- florist
        DecoCreator:Create("deco_wallpaper_florist_rip1", "interior_wall_decals_florist", "interior_wall_decals_florist", "hole_1",     {decal=true, background=1}),
        DecoCreator:Create("deco_wallpaper_florist_rip2", "interior_wall_decals_florist", "interior_wall_decals_florist", "hole_2",     {decal=true, background=1}),
        DecoCreator:Create("deco_wallpaper_florist_rip3", "interior_wall_decals_florist", "interior_wall_decals_florist", "hole_3",     {decal=true, background=1}),
        DecoCreator:Create("deco_wallpaper_florist_rip4", "interior_wall_decals_florist", "interior_wall_decals_florist", "hole_4",     {decal=true, background=1}),

        DecoCreator:Create("deco_wallpaper_florist_side_rip1", "interior_wall_decals_florist", "interior_wall_decals_florist", "hole_5_sidewall",    {decal=true}),
        DecoCreator:Create("deco_wallpaper_florist_side_rip2", "interior_wall_decals_florist", "interior_wall_decals_florist", "hole_6_sidewall",    {decal=true}),

        DecoCreator:Create("deco_deli_meatrack", "ceiling_decor", "ceiling_decor", "meatrack_idle",                                             {loopanim=true}),
        DecoCreator:Create("deco_deli_basket", "ceiling_decor", "ceiling_decor", "wire_basket_idle",                                            {loopanim=true}),

        DecoCreator:Create("deco_general_hangingscale", "ceiling_decor", "ceiling_decor", "scale_idle",                                         {loopanim=true}),
        DecoCreator:Create("deco_general_hangingpans", "ceiling_decor", "ceiling_decor", "pans_idle",                                           {loopanim=true}),
        DecoCreator:Create("deco_general_trough", "interior_wall_decals_florist", "interior_wall_decals_florist", "tiered_trough",              {decal=true}),

        --arcane
        DecoCreator:Create("closed_chest", "interior_wall_decals_arcane", "wall_decals_arcane", "chest_closed", {decal=true}),
        DecoCreator:Create("open_chest", "interior_wall_decals_arcane", "wall_decals_arcane", "chest_open", {decal=true}),
        DecoCreator:Create("containers", "interior_wall_decals_arcane", "wall_decals_arcane", "containers", {decal=true}),
        DecoCreator:Create("deco_arcane_bookshelf", "interior_wall_decals_arcane", "wall_decals_arcane", "bookcase_backwall", {decal=true}),
        DecoCreator:Create("mirror_backwall", "interior_wall_decals_arcane", "wall_decals_arcane", "mirror_backwall", {decal=true}),


        --BAT CAVE
        DecoCreator:Create("deco_cave_beam_room", "interior_wall_decals_batcave", "interior_wall_decals_cave", "pillar_front",                  {decal=true, physics="big_post_physics", workable=true, minimapicon="vamp_cave_pillar.tex"}),
        DecoCreator:Create("deco_cave_cornerbeam", "interior_wall_decals_batcave", "interior_wall_decals_cave", "pillar_corner",                {decal=true, background=3, tags={"cornerpost"}}),
        DecoCreator:Create("deco_cave_pillar_side", "interior_wall_decals_batcave", "interior_wall_decals_cave", "pillar_sidewall",             {decal=true}),
        DecoCreator:Create("deco_cave_ceiling_trim", "interior_wall_decals_batcave", "interior_wall_decals_cave", "ceiling_trim_1"),
        DecoCreator:Create("deco_cave_ceiling_trim_2", "interior_wall_decals_batcave", "interior_wall_decals_cave", "ceiling_trim_2",           {decal=true, background=3}),
        DecoCreator:Create("deco_cave_ceiling_trim_3", "interior_wall_decals_batcave", "interior_wall_decals_cave", "ceiling_trim_3"),
        DecoCreator:Create("deco_cave_floor_trim", "interior_wall_decals_batcave", "interior_wall_decals_cave", "floor_trim_1",                 {decal=true, background=3}),
        DecoCreator:Create("deco_cave_floor_trim_2", "interior_wall_decals_batcave", "interior_wall_decals_cave", "floor_trim_2",               {decal=true, background=3}),
        DecoCreator:Create("deco_cave_floor_trim_front", "interior_wall_decals_batcave", "interior_wall_decals_cave", "floor_trim_3"),
        DecoCreator:Create("deco_cave_stalactite", "interior_wall_decals_batcave", "interior_wall_decals_cave", "stalactite"),
        DecoCreator:Create("deco_cave_bat_burrow", "interior_wall_decals_batcave", "interior_wall_decals_cave", "bat_burrow",                   {decal=true, physics="pond_physics", prefabname="deco_cave_bat_burrow", minimapicon="vamp_cave_burrow.tex"}),
        DecoCreator:Create("deco_cave_bat_burrow_front", "interior_wall_decals_batcave_2", "interior_wall_decals_cave", "bat_burrow_front"),

        --ANT HIVE
        DecoCreator:Create("deco_hive_beam_room", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "pillar_front",               {decal=true, physics="big_post_physics", workable=true, minimapicon="vamp_cave_pillar.tex"}),
        DecoCreator:Create("deco_hive_cornerbeam", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "pillar_corner",             {decal=true, background=3, tags={"cornerpost"}}),
        DecoCreator:Create("deco_hive_pillar_side", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "pillar_sidewall",          {decal=true}),
        DecoCreator:Create("deco_hive_floor_trim", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "floor_trim_1"),
        DecoCreator:Create("deco_hive_beam_broken_room", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "pillar_front_crumble_idle",           {decal=true, physics="big_post_physics", minimapicon="vamp_cave_pillar.tex"}),
        DecoCreator:Create("deco_hive_stalactite", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "stalactite"),
        DecoCreator:Create("deco_hive_broken_pillar", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "pillar_broken"),
        DecoCreator:Create("deco_hive_debris", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "rock_debris"),

        DecoCreator:Create("deco_cave_honey_drip_1", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "honey_wall_1",                      {decal=true, background=3}),
        DecoCreator:Create("deco_cave_ceiling_drip_2", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "honey_floor_1",                   {decal=true, background=3}),
        DecoCreator:Create("deco_cave_honey_drip_side_1", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "honey_wall_2",                 {decal=true, background=3}),
        DecoCreator:Create("deco_cave_honey_drip_side_2", "interior_wall_decals_antcave", "interior_wall_decals_antcave", "honey_floor_2",                {decal=true, background=3}),

        --deli
        DecoCreator:Create("deco_deli_stove_metal_side", "interior_wall_decals_deli", "wall_decals_deli", "stove_sidewall",                               {decal=true}),
        DecoCreator:Create("deco_deli_wallpaper_rip_side1", "interior_wall_decals_deli", "wall_decals_deli", "hole_5",                                    {decal=true}),
        DecoCreator:Create("deco_deli_wallpaper_rip_side2", "interior_wall_decals_deli", "wall_decals_deli", "hole_6",                                    {decal=true}),

        DecoCreator:Create("deco_produce_menu_side", "interior_wall_decals_deli", "wall_decals_deli", "menu_sidewall",                                    {decal=true}),
        DecoCreator:Create("deco_produce_menu", "interior_wall_decals_deli", "wall_decals_deli", "menu_front",                                            {decal=true}),
        DecoCreator:Create("deco_produce_stone_cornerbeam", "interior_wall_decals_deli", "wall_decals_deli", "pillar_sidewall",                           {decal=true, light=DecoCreator:GetLights().SMALL_YELLOW}),-- loopanim=true,

        -- city hall
        DecoCreator:Create("deco_cityhall_picture1", "interior_wall_decals_mayorsoffice", "wall_decals_mayorsoffice", "picture1_sidewall",                {decal=true, background=3}),
        DecoCreator:Create("deco_cityhall_picture2", "interior_wall_decals_mayorsoffice", "wall_decals_mayorsoffice", "picture2_sidewall",                {decal=true, background=3}),
        DecoCreator:Create("deco_cityhall_bookshelf", "interior_wall_decals_mayorsoffice", "wall_decals_mayorsoffice", "bookcase_backwall",               {decal=true}),
        DecoCreator:Create("deco_cityhall_pillar", "interior_wall_decals_mayorsoffice", "wall_decals_mayorsoffice", "pillar_round_corner",                {decal=true, loopanim=true, light=DecoCreator:GetLights().SMALL}),
        DecoCreator:Create("deco_cityhall_cornerbeam", "interior_wall_decals_mayorsoffice", "wall_decals_mayorsoffice", "pillar_flag_corner",             {decal=true, tags={"cornerpost"}}),  -- , background=3
        DecoCreator:Create("window_mayorsoffice", "window_mayorsoffice", "window_mayorsoffice", "day_loop",                                               {loopanim=true, decal=true, background=3, curtains=true}),
        DecoCreator:Create("deco_cityhall_desk", "interior_wall_decals_mayorsoffice", "wall_decals_mayorsoffice", "desk",                                 {light=DecoCreator:GetLights().MED,physics="desk_physics"}),

        -- palace
        DecoCreator:Create("deco_palace_beam_room_tall", "interior_wall_decals_palace", "wall_decals_palace", "pillar_tall",                              {decal=true, physics="post_physics"}),
        DecoCreator:Create("deco_palace_beam_room_tall_lights", "interior_wall_decals_palace", "wall_decals_palace", "pillar_tall_lights",                {decal=true, physics="post_physics", light=DecoCreator:GetLights().SMALL}),

        DecoCreator:Create("deco_palace_beam_room_tall_corner", "interior_wall_decals_palace", "wall_decals_palace", "pillar_tall_corner",                {decal=true, background=3, physics="post_physics"}),
        DecoCreator:Create("deco_palace_beam_room_tall_corner_front", "interior_wall_decals_palace", "wall_decals_palace", "pillar_tall_front",           {decal=true, physics="post_physics"}),
        DecoCreator:Create("window_palace", "window_palace", "window_palace", "day_loop",                                                                 {loopanim=true, decal=true, background=3, curtains=true}),
        DecoCreator:Create("window_palace_stainglass", "window_palace_stainglass", "window_palace_stainglass", "day_loop",                                {loopanim=true, decal=true, background=3, curtains=true}),

        DecoCreator:Create("deco_palace_banner_big_front", "interior_wall_decals_palace", "wall_decals_palace", "banner_lg_front",                        {decal=true}),
        DecoCreator:Create("deco_palace_banner_big_sidewall", "interior_wall_decals_palace", "wall_decals_palace", "banner_lg_sidewall",                  {decal=true}),

        DecoCreator:Create("deco_palace_banner_small_front", "interior_wall_decals_palace", "wall_decals_palace", "banner_sml_front",                     {decal=true}),
        DecoCreator:Create("deco_palace_banner_small_sidewall", "interior_wall_decals_palace", "wall_decals_palace", "banner_sml_sidewall",               {decal=true}),

        DecoCreator:Create("deco_palace_throne", "interior_wall_decals_palace", "wall_decals_palace", "throne",                                           {decal=true, physics="chair_physics"}),

        DecoCreator:Create("deco_palace_beam_room_short_corner_lights", "interior_wall_decals_palace", "wall_decals_palace", "pillar_lights_corner",      {decal=true, physics="post_physics", light=DecoCreator:GetLights().SMALL}),
        DecoCreator:Create("deco_palace_beam_room_short_corner_front_lights", "interior_wall_decals_palace", "wall_decals_palace", "pillar_lights_front", {decal=true, physics="post_physics", light=DecoCreator:GetLights().SMALL}),
        DecoCreator:Create("deco_palace_beam_room_short", "interior_wall_decals_palace", "wall_decals_palace", "pillar",                                  {decal=true, physics="post_physics"}),

        DecoCreator:Create("deco_displaycase", "interior_wall_decals_antiquities", "wall_decals_antiquities", "displayshelf_corner",                      {decal=true, physics="post_physics"}),
        DecoCreator:Create("deco_palace_plant", "interior_wall_decals_palace", "wall_decals_palace", "plant",                                             {decal=true}),

        -- Bank
        DecoCreator:Create("deco_bank_clock1_side", "interior_decor", "interior_decor", "clock1_sidewall",                                                {decal=true}),
        DecoCreator:Create("deco_bank_clock2_side", "interior_decor", "interior_decor", "clock2_sidewall",                                                {decal=true}),
        DecoCreator:Create("deco_bank_clock3_side", "interior_decor", "interior_decor", "clock3_sidewall",                                                {decal=true}),
        DecoCreator:Create("deco_bank_marble_beam", "interior_pillar", "interior_pillar", "pillar_bank_front",                                            {decal=true, loopanim=true, light=DecoCreator:GetLights().SMALL, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),
        DecoCreator:Create("deco_bank_marble_cornerbeam", "interior_pillar", "interior_pillar", "pillar_bank_corner",                                     {decal=true, loopanim=true, light=DecoCreator:GetLights().SMALL, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),
        DecoCreator:Create("deco_bank_vault", "interior_unique", "interior_unique", "vault",                                                              {decal=true}),

        -- Tinker
        DecoCreator:Create("deco_tinker_beam", "interior_pillar", "interior_pillar", "basic_front",                                            {decal=true, loopanim=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),
        DecoCreator:Create("deco_tinker_cornerbeam", "interior_pillar", "interior_pillar", "basic_corner",                                     {decal=true, loopanim=true, tags={"NOBLOCK","cornerpost"}, onbuilt=true}),

        DecoCreator:Create("deco_rollholder",  "interior_floor_decor",         "interior_floor_decor", "rollholder",               {physics="post_physics", tags={"furniture"}, onbuilt=true }),
        DecoCreator:Create("deco_rollholder_front",  "interior_floor_decor",   "interior_floor_decor", "rollholder_front",         {physics="sofa_physics", tags={"furniture"}, onbuilt=true }),
        DecoCreator:Create("deco_filecabinet",  "interior_floor_decor",         "interior_floor_decor", "filecabinet",               {physics="post_physics", tags={"furniture"}, onbuilt=true }),
        DecoCreator:Create("deco_rollchest",  "interior_floor_decor",         "interior_floor_decor", "chest_open",               {physics="post_physics", tags={"furniture"}, onbuilt=true }),
        DecoCreator:Create("deco_worktable",  "interior_floor_decor",         "interior_floor_decor", "worktable",               {physics="sofa_physics", tags={"furniture"}, onbuilt=true })
