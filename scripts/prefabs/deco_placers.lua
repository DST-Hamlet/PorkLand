local function placer_override_testfn(inst)
    local can_build, mouse_blocked = true, false

    if inst.components.placer.testfn ~= nil then
        can_build, mouse_blocked = inst.components.placer.testfn(inst:GetPosition(), inst:GetRotation())
    end

    can_build = inst.accept_placement

    return can_build, mouse_blocked
end

local function placer_override_build_point(inst)
    return inst:GetPosition()
end

local function CreateMarkers(inst, pts)
    for _, subpt in pairs(pts) do
        local marker = SpawnPrefab(inst.prefab)
        marker.AnimState:SetBank(inst.animdata.bank)
        marker.AnimState:SetBuild(inst.animdata.build)

        local anim = inst.animdata.anim
        if subpt.anim then
            anim = anim .. subpt.anim
        end

        marker.AnimState:PlayAnimation(anim)

        if subpt.billboard then
            marker.Transform:SetTwoFaced()
            marker.Transform:SetRotation(-90)
        end

        marker.AnimState:SetAddColour(0.025, 0.075, 0.025, 1)
        marker.AnimState:SetMultColour(0.1, 0.1, 0.1, 0.1)
        marker.Transform:SetPosition(subpt.coord.x, subpt.coord.y, subpt.coord.z)
        if subpt.rot then
            marker.Transform:SetRotation(subpt.rot)
        end

        table.insert(inst.markers, marker)
    end
end

local function ClearMarkers(inst)
    if inst.markers then
        for _, marker in ipairs(inst.markers) do
            marker:Remove()
        end
    end
end

local function CornerPillarPlacerAnim(inst)
    inst.Transform:SetTwoFaced()
end

local function CornerPillarPlaceTest(inst)
    inst.Transform:SetTwoFaced()
    inst.Transform:SetRotation(-90)

    local pt = inst.components.placer.selected_pos or TheInput:GetWorldPosition()
    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(ThePlayer:GetPosition())
    if current_interior then
        local originpt = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dMax = originpt.x + depth/2
        local dMin = originpt.x - depth/2

        local wMax = originpt.z + width/2
        local wMin = originpt.z - width/2

        local pts = {}
        table.insert(pts, {coord = Vector3(dMax, 0, wMax), billboard = true})
        table.insert(pts, {coord = Vector3(dMin, 0, wMax), billboard = true})
        table.insert(pts, {coord = Vector3(dMax, 0, wMin), billboard = true})
        table.insert(pts, {coord = Vector3(dMin, 0, wMin), billboard = true})

        for i, subpt in ipairs(pts) do
            local rot = 90
            if subpt.coord.z < originpt.z then
                rot = -90
            end

            subpt.rot = rot
        end

        if not inst.markers then
            inst.markers = {}
            CreateMarkers(inst, pts)
        end

        for i, subpt in ipairs(pts) do
            if distsq(subpt.coord.x, subpt.coord.z, pt.x, pt.z) < 2 then
                inst.Transform:SetPosition(subpt.coord.x, subpt.coord.y, subpt.coord.z)
                inst.Transform:SetRotation(subpt.rot)

                inst.accept_placement = true
                return
            end
        end
    end

    inst.accept_placement = false
end

local function MakePillarPlacer(name, bank, build, anim)
    return MakePlacer(name, bank, build, anim, nil, nil, nil, nil, nil, nil, function(inst)
        inst.animdata = {
            build = build,
            anim = anim,
            bank = bank,
        }
        CornerPillarPlacerAnim(inst)
        inst.components.placer.onupdatetransform = CornerPillarPlaceTest
        inst.components.placer.override_build_point_fn = placer_override_build_point
        inst.components.placer.override_testfn = placer_override_testfn
        inst.accept_placement = false
        inst:ListenForEvent("onremove", ClearMarkers)
    end)
end

local function CeilingLightPlaceTest(inst, pt)
    if inst.parent then
        local px, py, pz = inst.Transform:GetWorldPosition()
        inst.parent:RemoveChild(inst)
        inst.Transform:SetPosition(px,py,pz)
    end

    inst.Transform:SetTwoFaced()
    inst.Transform:SetRotation(-90)

    local interiorSpawner = TheWorld.components.interiorspawner
    if interiorSpawner.current_interior then

        local width = interiorSpawner.current_interior.width
        local depth = interiorSpawner.current_interior.depth
        local originpt = interiorSpawner:getSpawnOrigin()

        local dMax = originpt.x + depth/2
        local dMin = originpt.x - depth/2

        local wMax = originpt.z + width/2
        local wMin = originpt.z - width/2

        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 2, {"centerlight"})
        local inbounds = true

        if pt.x < dMin+1 or pt.x > dMax -1 or pt.z < wMin+1 or pt.z > wMax-1 then
            inbounds = false
        end

        if inbounds and #ents < 1 then
            return true
        end
    end
    return false
end

local function WallPlaceTest(inst, distance)
    local pt = inst.components.placer.selected_pos or TheInput:GetWorldPosition()

    inst.Transform:SetTwoFaced()
    inst.Transform:SetRotation(-90)

    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(ThePlayer:GetPosition())
    if current_interior then
        local originpt = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dist = 2
        local newpt = {}
        local backdiff =  pt.x < (originpt.x - depth/2 + dist)
        local frontdiff = pt.x > (originpt.x + depth/2 - dist)
        local rightdiff = pt.z > (originpt.z + width/2 - dist)
        local leftdiff =  pt.z < (originpt.z - width/2 + dist)

        local canbuild = true
        --local anim = "_front"
        local side = ""
        local rot = -90
        if backdiff and not rightdiff and not leftdiff then
            newpt = {x = originpt.x - depth/2, z=pt.z}
          --  anim = "_front"
            rot = -90
        elseif rightdiff and not backdiff and not frontdiff then
            newpt = {x = pt.x, z= originpt.z + width/2}
          --  anim = "_sidewall"
            side = "_side"
            rot = 90
        elseif leftdiff and not backdiff and not frontdiff then
            newpt = {x = pt.x, z= originpt.z - width/2}
           -- anim = "_sidewall"
            side = "_side"
            rot = -90
        else
            canbuild = false
        end

        if newpt.x and newpt.z then
            inst.Transform:SetPosition(newpt.x,0,newpt.z)
        end
        if canbuild then
            inst.Transform:SetRotation(rot)
        end

        inst.AnimState:PlayAnimation(inst.animdata.anim)
        inst.AnimState:SetBank(inst.animdata.bank .. side)
        inst.Transform:SetRotation(rot)

        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 7, {"fullwallsection"})
        if #ents > 0 then
            canbuild = false
        end

        local dist = distance or 3
        ents = TheSim:FindEntities(pt.x, pt.y, pt.z, dist, {"wallsection"})
        if #ents < 1 and canbuild then
            inst.accept_placement = true
            return
        end
    end

    inst.accept_placement = false
end

local function Wall4PlaceTest(inst)
    return WallPlaceTest(inst, 4)
end

local function MakeWallPlacer(name, bank, build, anim, on_update_transform)
    return MakePlacer(name, bank, build, anim, nil, nil, nil, nil, nil, nil, function(inst)
        inst.animdata = {
            build = build,
            anim = anim,
            bank = bank,
        }
        inst.components.placer.onupdatetransform = on_update_transform
        inst.components.placer.override_build_point_fn = placer_override_build_point
        inst.components.placer.override_testfn = placer_override_testfn
        inst.accept_placement = false
    end)
end

local function NoCurtainWindowPlacerAnim(inst)
    inst.AnimState:Hide("curtain")
    inst.Transform:SetTwoFaced()
end

local function CurtainWindowPlacerAnim(inst)
    inst.Transform:SetTwoFaced()
end

local function WindowPlacerAnim(inst)
    inst.Transform:SetTwoFaced()
    -- inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/animrotatingbillboard.ksh"))
end

local function WindowPlaceTest(inst)
    inst.Transform:SetRotation(-90)
    local pt = inst.components.placer.selected_pos or TheInput:GetWorldPosition()

    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(ThePlayer:GetPosition())
    if current_interior then
        local originpt = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dist = 2
        local newpt = {}
        local backdiff =  pt.x < (originpt.x - depth/2 + dist)
        local frontdiff = pt.x > (originpt.x + depth/2 - dist)
        local rightdiff = pt.z > (originpt.z + width/2 - dist)
        local leftdiff =  pt.z < (originpt.z - width/2 + dist)

        local canbuild = true
        local bank = ""
        local rot = -90
        if backdiff and not rightdiff and not leftdiff then
            newpt = {x = originpt.x - depth/2, z=pt.z}
            bank = ""
            rot = -90
        elseif rightdiff and not backdiff and not frontdiff then
            newpt = {x = pt.x, z= originpt.z + width/2}
            bank = "_side"
            rot = 90
        elseif leftdiff and not backdiff and not frontdiff then
            newpt = {x = pt.x, z= originpt.z - width/2}
            bank = "_side"
            rot = -90
        else
            newpt = pt
            canbuild = false
        end

        if canbuild then
            inst.Transform:SetPosition(newpt.x, 0, newpt.z)
            inst.Transform:SetRotation(rot)
        else
            inst.Transform:SetPosition(pt.x, pt.y, pt.z)
        end

        inst.AnimState:SetBank(inst.animdata.bank .. bank)
        inst.Transform:SetRotation(rot)


        local ents = TheSim:FindEntities(newpt.x, 0, newpt.z, 7, {"fullwallsection"})
        if #ents > 0 then
            canbuild = false
        end

        ents = TheSim:FindEntities(newpt.x, 0, newpt.z, 3, {"wallsection"})

        if #ents < 1 and canbuild then
            inst.accept_placement = true
            return
        end
    end
    inst.accept_placement = false
end

local function WindowWidePlaceTest(inst)
    inst.Transform:SetRotation(-90)
    local pt = inst.components.placer.selected_pos or TheInput:GetWorldPosition()

    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(ThePlayer:GetPosition())
    if current_interior then
        local originpt = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dist = 2
        local newpt = {}
        local backdiff =  pt.x < (originpt.x - depth/2 + dist)
        local frontdiff = pt.x > (originpt.x + depth/2 - dist)
        local rightdiff = pt.z > (originpt.z + width/2 - dist)
        local leftdiff =  pt.z < (originpt.z - width/2 + dist)

        local canbuild = true
        local bank = ""
        local rot = -90
        if backdiff and not rightdiff and not leftdiff then
            newpt = {x = originpt.x - depth/2, z=originpt.z}
            bank = ""
            rot = -90
        elseif rightdiff and not backdiff and not frontdiff then
            newpt = {x = originpt.x, z= originpt.z + width/2}
            bank = "_side"
            rot = 90
        elseif leftdiff and not backdiff and not frontdiff then
            newpt = {x = originpt.x, z= originpt.z - width/2}
            bank = "_side"
            rot = -90
        else
            newpt = pt
            canbuild = false
        end

        if canbuild then
            inst.Transform:SetPosition(newpt.x, 0, newpt.z)
            inst.Transform:SetRotation(rot)
        else
            inst.Transform:SetPosition(pt.x, pt.y, pt.z)
        end

        inst.AnimState:SetBank(inst.animdata.bank .. bank)
        inst.Transform:SetRotation(rot)

        local ents = TheSim:FindEntities(newpt.x, 0, newpt.z, 7, {"fullwallsection"})
        if #ents > 0 then
            canbuild = false
        end

        ents = TheSim:FindEntities(newpt.x, 0, newpt.z, 5, {"wallsection"})

        if #ents < 1 and canbuild then
            inst.accept_placement = true
            return
        end
    end
    inst.accept_placement = false
end

local function MakeWindowPlacer(name, bank, build, anim, animation_postinit, on_update_transform)
    return MakePlacer(name, bank, build, anim, nil, nil, nil, nil, nil, nil, function(inst)
        inst.animdata = {
            build = build,
            anim = anim,
            bank = bank,
        }
        animation_postinit(inst)
        inst.components.placer.onupdatetransform = on_update_transform
        inst.components.placer.override_build_point_fn = placer_override_build_point
        inst.components.placer.override_testfn = placer_override_testfn
        inst.accept_placement = false
    end)
end

local function ShelfPlacerAnim(inst)
    inst.Transform:SetTwoFaced()
    inst.Transform:SetRotation(-90)
end

local function ShelfPlaceTest(inst)
    local pt = inst.components.placer.selected_pos or TheInput:GetWorldPosition()

    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(ThePlayer:GetPosition())
    if current_interior then
        local originpt = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dist = 2
        local newpt = {}
        local backdiff =  pt.x < (originpt.x - depth/2 + dist)
        -- local frontdiff = pt.x > (originpt.x + depth/2 - dist)
        local rightdiff = pt.z > (originpt.z + width/2 - dist)
        local leftdiff =  pt.z < (originpt.z - width/2 + dist)

        local canbuild = true
        local rot = -90
        if backdiff and not rightdiff and not leftdiff then
            newpt = {x = originpt.x - depth/2, z=pt.z}
            rot = -90
        else
            newpt = pt
            canbuild = false
        end

        inst.Transform:SetPosition(newpt.x, 0, newpt.z)
        if canbuild then
            inst.Transform:SetRotation(rot)
        end

        local ents = TheSim:FindEntities(newpt.x, 0, newpt.z, 7, {"fullwallsection"})
        if #ents > 0 then
            canbuild = false
        end

        local blockeddist = 4
        ents = TheSim:FindEntities(newpt.x, 0, newpt.z, blockeddist, nil, nil, {"furniture", "wallsection"})

        if canbuild and #ents < 1 then
            inst.accept_placement = true
            return
        end
    end
    inst.accept_placement = false
end

local function MakeShelfPlacer(name, bank, build, anim)
    return MakePlacer(name, bank, build, anim, nil, nil, nil, nil, nil, nil, function(inst)
        inst.animdata = {
            build = build,
            anim = anim,
            bank = bank,
        }
        ShelfPlacerAnim(inst)
        inst.components.placer.onupdatetransform = ShelfPlaceTest
        inst.components.placer.override_build_point_fn = placer_override_build_point
        inst.components.placer.override_testfn = placer_override_testfn
        inst.accept_placement = false
    end)
end

local function RugPropPlacerAnim(inst)
    inst.Transform:SetTwoFaced()
    inst.Transform:SetRotation(90)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
end

local function RugPropPlaceTest(inst, pt, distance)
    local interiorSpawner = TheWorld.components.interiorspawner
    if interiorSpawner.current_interior then

        local width = interiorSpawner.current_interior.width
        local depth = interiorSpawner.current_interior.depth
        local originpt = interiorSpawner:getSpawnOrigin()

        local dMax = originpt.x + depth/2
        local dMin = originpt.x - depth/2

        local wMax = originpt.z + width/2
        local wMin = originpt.z - width/2

        local dist = distance or 3

        local inbounds = true

        if pt.x < dMin+dist or pt.x > dMax -dist or pt.z < wMin+dist or pt.z > wMax-dist then
            inbounds = false
        end

        if inbounds then
            return true
        end
    end
    return false
end

local function RugPlacerAnim(inst)
    inst.flipsrotate = true
    inst.Transform:SetRotation(90)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
end

local function RugPlaceTestFn(inst, pt, distance)
    local interiorSpawner = TheWorld.components.interiorspawner
    if interiorSpawner.current_interior then

        local width = interiorSpawner.current_interior.width
        local depth = interiorSpawner.current_interior.depth
        local originpt = interiorSpawner:getSpawnOrigin()

        local dMax = originpt.x + depth/2
        local dMin = originpt.x - depth/2

        local wMax = originpt.z + width/2
        local wMin = originpt.z - width/2


        local dist = distance or 3

        --local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 2, {"furniture"})
        local inbounds = true

        if pt.x < dMin+dist or pt.x > dMax -dist or pt.z < wMin+dist or pt.z > wMax-dist then
            inbounds = false
        end

        if inbounds then
            return true
        end
    end
    return false
end

local function Rug2PlaceTest(inst, pt)
    return  RugPlaceTestFn(inst,pt,2)
end

local function Rug28PlaceTest(inst, pt)
    return  RugPlaceTestFn(inst,pt,2.8)
end

local function modifypillarfn(inst)
    local data = {}

    data.prefab_suffix = "_beam"

    local interiorSpawner = TheWorld.components.interiorspawner
    if interiorSpawner.current_interior then
        local originpt = interiorSpawner:getSpawnOrigin()
        local pt = Point(inst.Transform:GetWorldPosition())

        if pt.x <= originpt.x then
            data.prefab_suffix = "_cornerbeam"
        end
    end

    return data
end

return  MakePillarPlacer("deco_wood_cornerbeam_placer",       "wall_decals",           "interior_wall_decals",             "4"),
        MakePillarPlacer("deco_millinery_cornerbeam_placer",  "wall_decals_millinery", "interior_wall_decals_millinery",   "pillar_corner"),
        MakePillarPlacer("deco_round_cornerbeam_placer",      "wall_decals_accademia", "interior_wall_decals_accademia",   "pillar_round_corner"),
        MakePillarPlacer("deco_marble_cornerbeam_placer",     "wall_decals_hoofspa",   "interior_wall_decals_hoofspa",     "pillar_corner"),

        -- CHAIRS
        MakePlacer("chair_classic_placer",  "interior_chair", "interior_chair", "chair_classic",  nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_corner_placer",   "interior_chair", "interior_chair", "chair_corner",   nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_bench_placer",    "interior_chair", "interior_chair", "chair_bench",    nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_horned_placer",   "interior_chair", "interior_chair", "chair_horned",   nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_footrest_placer", "interior_chair", "interior_chair", "chair_footrest", nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_lounge_placer",   "interior_chair", "interior_chair", "chair_lounge",   nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_massager_placer", "interior_chair", "interior_chair", "chair_massager", nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_stuffed_placer",  "interior_chair", "interior_chair", "chair_stuffed",  nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_rocking_placer",  "interior_chair", "interior_chair", "chair_rocking",  nil, nil, nil, nil, nil, "two"),
        MakePlacer("chair_ottoman_placer",  "interior_chair", "interior_chair", "chair_ottoman",  nil, nil, nil, nil, nil, "two"),

        -- SHELF
        MakeShelfPlacer("shelf_wood_placer",         "bookcase", "room_shelves", "wood"),
        MakeShelfPlacer("shelf_basic_placer",        "bookcase", "room_shelves", "basic"),
        MakeShelfPlacer("shelf_cinderblocks_placer", "bookcase", "room_shelves", "cinderblocks"),
        MakeShelfPlacer("shelf_marble_placer",       "bookcase", "room_shelves", "marble"),
        MakeShelfPlacer("shelf_glass_placer",        "bookcase", "room_shelves", "glass"),
        MakeShelfPlacer("shelf_ladder_placer",       "bookcase", "room_shelves", "ladder"),
        MakeShelfPlacer("shelf_hutch_placer",        "bookcase", "room_shelves", "hutch"),
        MakeShelfPlacer("shelf_industrial_placer",   "bookcase", "room_shelves", "industrial"),
        MakeShelfPlacer("shelf_adjustable_placer",   "bookcase", "room_shelves", "adjustable"),
        MakeShelfPlacer("shelf_midcentury_placer",   "bookcase", "room_shelves", "midcentury"),
        MakeShelfPlacer("shelf_wallmount_placer",    "bookcase", "room_shelves", "wallmount"),
        MakeShelfPlacer("shelf_aframe_placer",       "bookcase", "room_shelves", "aframe"),
        MakeShelfPlacer("shelf_crates_placer",       "bookcase", "room_shelves", "crates"),
        MakeShelfPlacer("shelf_fridge_placer",       "bookcase", "room_shelves", "fridge"),
        MakeShelfPlacer("shelf_floating_placer",     "bookcase", "room_shelves", "floating"),
        MakeShelfPlacer("shelf_pipe_placer",         "bookcase", "room_shelves", "pipe"),
        MakeShelfPlacer("shelf_hattree_placer",      "bookcase", "room_shelves", "hattree"),
        MakeShelfPlacer("shelf_pallet_placer",       "bookcase", "room_shelves", "pallet"),

        -- HANGING LIGHTS
        MakePlacer("swinging_light_basic_bulb_placer",         "ceiling_lights", "ceiling_lights", "light_basic_bulb",             nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_floral_bloomer_placer",     "ceiling_lights", "ceiling_lights", "light_floral_bloomer",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_basic_metal_placer",        "ceiling_lights", "ceiling_lights", "light_basic_metal",            nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_chandalier_candles_placer", "ceiling_lights", "ceiling_lights", "light_chandelier_candles",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_rope_1_placer",             "ceiling_lights", "ceiling_lights", "light_rope1",                  nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_rope_2_placer",             "ceiling_lights", "ceiling_lights", "light_rope2",                  nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_floral_bulb_placer",        "ceiling_lights", "ceiling_lights", "light_floral_bulb",            nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_pendant_cherries_placer",   "ceiling_lights", "ceiling_lights", "light_pendant_cherries",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_floral_scallop_placer",     "ceiling_lights", "ceiling_lights", "light_floral_scallop",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_floral_bloomer_placer",     "ceiling_lights", "ceiling_lights", "light_floral_bloomer",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_tophat_placer",             "ceiling_lights", "ceiling_lights", "light_tophat",                 nil, nil, nil, nil, nil, "two"),
        MakePlacer("swinging_light_derby_placer",              "ceiling_lights", "ceiling_lights", "light_derby",                  nil, nil, nil, nil, nil, "two"),

        -- WINDOWS
        MakeWindowPlacer("window_round_curtains_nails_placer",  "interior_window", "interior_window", "day_loop",                             WindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_round_burlap_placer",          "interior_window_burlap", "interior_window_burlap", "day_loop",               WindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_small_peaked_curtain_placer",  "interior_window", "interior_window_small", "day_loop",                       NoCurtainWindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_small_peaked_placer",          "interior_window", "interior_window_small", "day_loop",                       NoCurtainWindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_large_square_placer",          "interior_window_large", "interior_window_large", "day_loop",                 NoCurtainWindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_tall_placer",                  "interior_window_tall", "interior_window_tall", "day_loop",                   NoCurtainWindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_large_square_curtain_placer",  "interior_window_large", "interior_window_large", "day_loop",                 CurtainWindowPlacerAnim, WindowPlaceTest),
        MakeWindowPlacer("window_tall_curtain_placer",          "interior_window_tall", "interior_window_tall", "day_loop",                   CurtainWindowPlacerAnim, WindowPlaceTest),

        MakeWindowPlacer("window_greenhouse_placer",            "interior_window_greenhouse", "interior_window_greenhouse_build", "day_loop", CurtainWindowPlacerAnim, WindowWidePlaceTest),

        MakePlacer("deco_lamp_fringe_placer",        "interior_floorlamp", "interior_floorlamp", "floorlamp_fringe",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_stainglass_placer",    "interior_floorlamp", "interior_floorlamp", "floorlamp_stainglass",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_downbridge_placer",    "interior_floorlamp", "interior_floorlamp", "floorlamp_downbridge",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_2embroidered_placer",  "interior_floorlamp", "interior_floorlamp", "floorlamp_2embroidered",   nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_ceramic_placer",       "interior_floorlamp", "interior_floorlamp", "floorlamp_ceramic",        nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_glass_placer",         "interior_floorlamp", "interior_floorlamp", "floorlamp_glass",          nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_2fringes_placer",      "interior_floorlamp", "interior_floorlamp", "floorlamp_2fringes",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_candelabra_placer",    "interior_floorlamp", "interior_floorlamp", "floorlamp_candelabra",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_elizabethan_placer",   "interior_floorlamp", "interior_floorlamp", "floorlamp_elizabethan",    nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_gothic_placer",        "interior_floorlamp", "interior_floorlamp", "floorlamp_gothic",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_orb_placer",           "interior_floorlamp", "interior_floorlamp", "floorlamp_orb",            nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_bellshade_placer",     "interior_floorlamp", "interior_floorlamp", "floorlamp_bellshade",      nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_crystals_placer",      "interior_floorlamp", "interior_floorlamp", "floorlamp_crystals",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_upturn_placer",        "interior_floorlamp", "interior_floorlamp", "floorlamp_upturn",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_2upturns_placer",      "interior_floorlamp", "interior_floorlamp", "floorlamp_2upturns",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_spool_placer",         "interior_floorlamp", "interior_floorlamp", "floorlamp_spool",          nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_edison_placer",        "interior_floorlamp", "interior_floorlamp", "floorlamp_edison",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_adjustable_placer",    "interior_floorlamp", "interior_floorlamp", "floorlamp_adjustable",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_rightangles_placer",   "interior_floorlamp", "interior_floorlamp", "floorlamp_rightangles",    nil, nil, nil, nil, nil, "two"),

        -- ROOM PROPS
        MakePlacer("deco_chaise_placer",             "interior_floor_decor", "interior_floor_decor", "chaise",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_lamp_hoofspa_placer",       "interior_floor_decor", "interior_floor_decor", "lamp",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_marble_placer", "interior_floor_decor", "interior_floor_decor", "plant",      nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_table_banker_placer",       "interior_table", "interior_table", "table_banker",           nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_table_round_placer",        "interior_table", "interior_table", "table_round",            nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_table_diy_placer",          "interior_table", "interior_table", "table_diy",              nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_table_raw_placer",          "interior_table", "interior_table", "table_raw",              nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_table_crate_placer",        "interior_table", "interior_table", "table_crate",            nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_table_chess_placer",        "interior_table", "interior_table", "table_chess",            nil, nil, nil, nil, nil, "two"),

        -- RUGS
        MakePlacer("rug_round_placer",     "rugs", "rugs", "rug_round",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_square_placer",    "rugs", "rugs", "rug_square",     nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_oval_placer",      "rugs", "rugs", "rug_oval",       nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_rectangle_placer", "rugs", "rugs", "rug_rectangle",  nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_leather_placer",   "rugs", "rugs", "rug_leather",    nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_fur_placer",       "rugs", "rugs", "rug_fur",        nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_circle_placer",    "rugs", "rugs", "half_circle",    nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_hedgehog_placer",  "rugs", "rugs", "rug_hedgehog",   nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_porcupuss_placer", "rugs", "rugs", "rug_porcupuss",  nil, nil, nil, nil, nil, nil, RugPropPlacerAnim),
        MakePlacer("rug_hoofprint_placer", "rugs", "rugs", "rug_hoofprints", nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_octagon_placer",   "rugs", "rugs", "rug_octagon",    nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_swirl_placer",     "rugs", "rugs", "rug_swirl",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_catcoon_placer",   "rugs", "rugs", "rug_catcoon",    nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_rubbermat_placer", "rugs", "rugs", "rug_rubbermat",  nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_web_placer",       "rugs", "rugs", "rug_web",        nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_metal_placer",     "rugs", "rugs", "rug_metal",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_wormhole_placer",  "rugs", "rugs", "rug_wormhole",   nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_braid_placer",     "rugs", "rugs", "rug_braid",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_beard_placer",     "rugs", "rugs", "rug_beard",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_nailbed_placer",   "rugs", "rugs", "rug_nailbed",    nil, nil, nil, nil, nil, nil, RugPropPlacerAnim),
        MakePlacer("rug_crime_placer",     "rugs", "rugs", "rug_crime",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),
        MakePlacer("rug_tiles_placer",     "rugs", "rugs", "rug_tiles",      nil, nil, nil, nil, nil, nil, RugPlacerAnim),

        -- PLANTHOLDERS
        MakePlacer("deco_plantholder_basic_placer",          "interior_plant", "interior_plant", "plant_basic",        nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_wip_placer",            "interior_plant", "interior_plant", "plant_wip",          nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_fancy_placer",          "interior_plant", "interior_plant", "plant_fancy",        nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_bonsai_placer",         "interior_plant", "interior_plant", "plant_bonsai",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_dishgarden_placer",     "interior_plant", "interior_plant", "plant_dishgarden",   nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_philodendron_placer",   "interior_plant", "interior_plant", "plant_philodendron", nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_orchid_placer",         "interior_plant", "interior_plant", "plant_orchid",       nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_draceana_placer",       "interior_plant", "interior_plant", "plant_draceana",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_xerographica_placer",   "interior_plant", "interior_plant", "plant_xerographica", nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_birdcage_placer",       "interior_plant", "interior_plant", "plant_birdcage",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_palm_placer",           "interior_plant", "interior_plant", "plant_palm",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_zz_placer",             "interior_plant", "interior_plant", "plant_zz",           nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_fernstand_placer",      "interior_plant", "interior_plant", "plant_fernstand",    nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_fern_placer",           "interior_plant", "interior_plant", "plant_fern",         nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_terrarium_placer",      "interior_plant", "interior_plant", "plant_terrarium",    nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_plantpet_placer",       "interior_plant", "interior_plant", "plant_plantpet",     nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_traps_placer",          "interior_plant", "interior_plant", "plant_traps",        nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_pitchers_placer",       "interior_plant", "interior_plant", "plant_pitchers",     nil, nil, nil, nil, nil, "two"),

        MakePlacer("deco_plantholder_winterfeasttreeofsadness_placer",   "interior_plant", "interior_plant", "plant_winterfeasttreeofsadness", nil, nil, nil, nil, nil, "two"),
        MakePlacer("deco_plantholder_winterfeasttree_placer",            "interior_floorlamp", "interior_floorlamp", "festivetree_idle",       nil, nil, nil, nil, nil, "two"),

        -- WALL ORNAMENTS

        -- WALL DECO
        MakeWallPlacer("deco_antiquities_wallfish_placer",             "interior_wallornament", "interior_wallornament", "fish",               WallPlaceTest),
        MakeWallPlacer("deco_antiquities_beefalo_placer",              "interior_wallornament", "interior_wallornament", "beefalo",            Wall4PlaceTest),
        MakeWallPlacer("deco_wallornament_photo_placer",               "interior_wallornament", "interior_wallornament", "photo",              WallPlaceTest),
        MakeWallPlacer("deco_wallornament_fulllength_mirror_placer",   "interior_wallornament", "interior_wallornament", "fulllength_mirror",  WallPlaceTest),
        MakeWallPlacer("deco_wallornament_embroidery_hoop_placer",     "interior_wallornament", "interior_wallornament", "embroidery_hoop",    WallPlaceTest),
        MakeWallPlacer("deco_wallornament_mosaic_placer",              "interior_wallornament", "interior_wallornament", "mosaic",             WallPlaceTest),
        MakeWallPlacer("deco_wallornament_wreath_placer",              "interior_wallornament", "interior_wallornament", "wreath",             WallPlaceTest),
        MakeWallPlacer("deco_wallornament_axe_placer",                 "interior_wallornament", "interior_wallornament", "axe",                WallPlaceTest),
        MakeWallPlacer("deco_wallornament_hunt_placer",                "interior_wallornament", "interior_wallornament", "hunt",               Wall4PlaceTest),
        MakeWallPlacer("deco_wallornament_periodic_table_placer",      "interior_wallornament", "interior_wallornament", "periodic_table",     Wall4PlaceTest),
        MakeWallPlacer("deco_wallornament_gears_art_placer",           "interior_wallornament", "interior_wallornament", "gears_art",          WallPlaceTest),
        MakeWallPlacer("deco_wallornament_cape_placer",                "interior_wallornament", "interior_wallornament", "cape",               WallPlaceTest),
        MakeWallPlacer("deco_wallornament_no_smoking_placer",          "interior_wallornament", "interior_wallornament", "no_smoking",         WallPlaceTest),
        MakeWallPlacer("deco_wallornament_black_cat_placer",           "interior_wallornament", "interior_wallornament", "black_cat",          WallPlaceTest)

--placeTestWallFlatFn
