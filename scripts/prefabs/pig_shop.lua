local GetPropDef = require("prefabs/interior_prop_defs")

local PIG_SHOP_TEXTURE = {
    DEFAULT = {
        FLOOR = "levels/textures/ground_noise_checkeredlawn.tex",
        WALL = "levels/textures/ground_noise_checkeredlawn.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_ACADEMY = {
        FLOOR   = "levels/textures/interiors/shop_floor_hexagon.tex",
        WALL    = "levels/textures/interiors/shop_wall_circles.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_ANTIQUITIES = {
        FLOOR   = "levels/textures/noise_woodfloor.tex",
        WALL    = "levels/textures/interiors/harlequin_panel.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_HATSHOP = {
        FLOOR   = "levels/textures/interiors/shop_floor_checkered.tex",
        WALL    = "levels/textures/interiors/shop_wall_floraltrim2.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_WEAPONS = {
        FLOOR   = "levels/textures/interiors/shop_floor_herringbone.tex",
        WALL    = "levels/textures/interiors/shop_wall_upholstered.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_ARCANE = {
        FLOOR = "levels/textures/interiors/shop_floor_octagon.tex",
        WALL = "levels/textures/interiors/shop_wall_moroc.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_FLORIST = {
        FLOOR = "levels/textures/noise_woodfloor.tex",
        WALL = "levels/textures/interiors/shop_wall_sunflower2.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_HOOFSPA = {
        FLOOR = "levels/textures/interiors/shop_floor_checker.tex",
        WALL = "levels/textures/interiors/shop_wall_marble.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_GENERAL = {
        FLOOR = "levels/textures/interiors/shop_floor_checker.tex",
        WALL = "levels/textures/interiors/shop_wall_woodwall.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_PRODUCE = {
        FLOOR = "levels/textures/noise_woodfloor.tex",
        WALL = "levels/textures/interiors/shop_wall_woodwall.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_DELI = {
        FLOOR = "levels/textures/interiors/shop_floor_sheetmetal.tex",
        WALL = "levels/textures/interiors/shop_wall_checkered_metal.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_CITYHALL = {
        FLOOR = "levels/textures/interiors/floor_cityhall.tex",
        WALL = "levels/textures/interiors/wall_mayorsoffice_whispy.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_CITYHALL_PLAYER = {
        FLOOR = "levels/textures/interiors/floor_cityhall.tex",
        WALL = "levels/textures/interiors/wall_mayorsoffice_whispy.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_BANK = {
        FLOOR = "levels/textures/interiors/shop_floor_hoof_curvy.tex",
        WALL = "levels/textures/interiors/shop_wall_fullwall_moulding.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_SHOP_TINKER = {
        FLOOR = "levels/textures/interiors/shop_floor_woodpaneling2.tex",
        WALL = "levels/textures/interiors/shop_wall_bricks.tex",
        MINIMAP = "levels/textures/map_interior/mini_ruins_slab.tex",
    },
    PIG_PALACE = {
        FLOOR = "levels/textures/interiors/floor_marble_royal.tex",
        WALL = "levels/textures/interiors/wall_royal_high.tex",
        MINIMAP = "levels/textures/map_interior/mini_floor_marble_royal.tex",
    },
}

local PIG_SHOP_COLOUR_CUBE = "images/colour_cubes/pigshop_interior_cc.tex"
local PIG_SHOP_REVERB = "inside"
local PIG_SHOP_AMBIENT_SOUND = "STORE"
local PIG_SHOP_FOOTSTEP = "WOOD"

local SHOPSOUND_ENTER1 = "dontstarve_DLC003/common/objects/store/door_open"
local SHOPSOUND_ENTER2 = "dontstarve_DLC003/common/objects/store/door_entrance"

local assets = {
    Asset("ANIM", "anim/pig_shop.zip"),
    Asset("ANIM", "anim/pig_shop_florist.zip"),
    Asset("ANIM", "anim/pig_shop_hoofspa.zip"),
    Asset("ANIM", "anim/pig_shop_produce.zip"),
    Asset("ANIM", "anim/pig_shop_general.zip"),
    Asset("ANIM", "anim/pig_shop_deli.zip"),
    Asset("ANIM", "anim/pig_shop_antiquities.zip"),

    Asset("ANIM", "anim/flag_post_duster_build.zip"),
    Asset("ANIM", "anim/flag_post_wilson_build.zip"),

    Asset("ANIM", "anim/pig_cityhall.zip"),
    Asset("ANIM", "anim/pig_shop_arcane.zip"),
    Asset("ANIM", "anim/pig_shop_weapons.zip"),
    Asset("ANIM", "anim/pig_shop_accademia.zip"),
    Asset("ANIM", "anim/pig_shop_millinery.zip"),
    Asset("ANIM", "anim/pig_shop_bank.zip"),
    Asset("ANIM", "anim/pig_shop_tinker.zip"),

    -- Palace
    Asset("ANIM", "anim/palace.zip"),
    Asset("ANIM", "anim/pig_shop_doormats.zip"),
    Asset("ANIM", "anim/palace_door.zip"),
    Asset("ANIM", "anim/interior_wall_decals_palace.zip"),
}

local prefabs = {
    "pigman_collector",
    "pigman_banker",
    "pigman_beautician",
    "pigman_florist",
    "pigman_erudite",
    "pigman_professor",
    "pigman_hunter",
    "pigman_hatmaker_shopkeep",
    "pigman_mayor",
    "pigman_mechanic",
    "pigman_storeowner",

    "window_round",
    --  "window_sunlight",
    "deco_wallpaper_rip1",
    "deco_wallpaper_rip2",
    "deco_wallpaper_rip_side1",
    "deco_wallpaper_rip_side2",
    "deco_wallpaper_rip_side3",
    "deco_wallpaper_rip_side4",
    "deco_wood_beam",
    "deco_wood_cornerbeam",
    "wall_light1",
    "swinging_light_floral_bloomer",
    "swinging_light_basic_metal",
    "swinging_light_chandalier_candles",
    "swinging_light_rope_1",
    "swinging_light_rope_2",
    "swinging_light_floral_bulb",
    "swinging_light_pendant_cherries",
    "swinging_light_floral_scallop",
    "swinglightobject",
    "deco_roomglow",
    "light_dust_fx",
    "rug_round",
    "rug_oval",
    "rug_square",
    "rug_rectangle",
    "rug_leather",
    "rug_fur",

    "shelves_wood",
    "shelves_marble",
    "shelves_glass",

    "deco_marble_cornerbeam",
    "deco_marble_beam",
    "deco_valence",
    "wall_light_hoofspa",

    "wall_mirror",

    "deco_chaise",
    "deco_lamp_hoofspa",

    "deed",
    "construction_permit",
    "demolition_permit",
    "securitycontract",

    -- Palace
    "trinket_giftshop_1",
    "trinket_giftshop_3",
    "trinket_giftshop_4",
    -- "grounded_wilba",
    "city_hammer",
}

local function LightsOn(inst)
    if inst:HasTag("burnt") then
        return
    end

    inst.Light:Enable(true)
    inst.AnimState:PlayAnimation("lit", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
end

local function LightsOff(inst)
    if inst:HasTag("burnt") then
        return
    end

    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
end

local function OnVacate(inst, child)
    if not inst:HasTag("burnt") then
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.SoundEmitter:KillSound("pigsound")

        LightsOff(inst)

        if child and child.components.health then
            child.components.health:SetPercent(1)
        end
    end
end

local function OnOccupied(inst, child)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/pig_in_house_LP", "pigsound")

        if inst.doortask ~= nil then
            inst.doortask:Cancel()
        end
        inst.doortask = inst:DoTaskInTime(1, LightsOn)
    end
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        local animation = inst.Light:IsEnabled() and "lit" or "idle"
        inst.AnimState:PushAnimation(animation)
    end
end

local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_big")
    fx:SetMaterial("wood")
    fx.Transform:SetPosition(x, y, z)

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_" .. inst.break_sound_sufix)
    inst:Remove()
end

local function OnNight(inst, isnight)
    if inst:HasTag("burnt") then
        return
    end

    if isnight then
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        LightsOff(inst)

        if inst.prefab ~= "pig_shop_cityhall_player" and inst.prefab ~= "pig_palace" then
            inst.components.door:SetDoorDisabled(true, "close_store_at_night")
        end
    else
        if inst.doortask then
            inst.doortask:Cancel()
        end
        inst.doortask = inst:DoTaskInTime(1, LightsOn)

        if inst.prefab ~= "pig_shop_cityhall_player" and inst.prefab ~= "pig_palace" then
            inst.components.door:SetDoorDisabled(false, "close_store_at_night")
        end
    end
end

local function OnDay(inst, isday)
    if not isday then
        return
    end

    if not inst:HasTag("burnt") then
        inst:DoTaskInTime(1 + math.random() * 2, function()
            if inst.components.spawner:IsOccupied() then
                inst.components.spawner:ReleaseChild()
            end
        end)
    end
end

local function InitSpawner(inst)
    if not inst.components.spawner.child
        and inst.components.spawner.childname and
        not inst.components.spawner:IsSpawnPending() then

        local child = SpawnPrefab(inst.components.spawner.childname)
        if child then
            inst.components.spawner:TakeOwnership(child)
            inst.components.spawner:GoHome(child)
        end
    end
    inst:WatchWorldState("isday", OnDay)
    OnDay(inst, TheWorld.state.isday)
end

local function OnIsFiesta(inst, isfiesta)
    if isfiesta then
        inst.AnimState:Show("YOTP")
    else
        inst.AnimState:Hide("YOTP")
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/pighouse/wood_1")
    inst.AnimState:PushAnimation("idle")
end

local function InitShopped(room_id, shop_type)
    local room_position = TheWorld.components.interiorspawner:IndexToPosition(room_id)
    if shop_type then
        local pedestals = TheSim:FindEntities(room_position.x, room_position.y, room_position.z, 10, {"shop_pedestal"})
        for _, pedestal in ipairs(pedestals) do
            pedestal:InitShop(shop_type)
        end
    end
    local shelves = TheSim:FindEntities(room_position.x, room_position.y, room_position.z, 10, {"shelf"})
    for _, shelf in ipairs(shelves) do
        shelf:AddComponent("shopped")
        shelf.components.shopped:SetCost("oinc", 1)
    end
end

local function CreateInteriorPalace(inst, exterior_door_def)
    local interior_spawner = TheWorld.components.interiorspawner

    local gallery_id = interior_spawner:GetNewID()
    local giftshop_id = interior_spawner:GetNewID()

    local depth = 18
    local width = 26
    local height = 13

    local name = inst.prefab
    local city_id = inst.components.citypossession and inst.components.citypossession.cityID

    local floor_texture   = PIG_SHOP_TEXTURE.PIG_PALACE.FLOOR
    local wall_texture    = PIG_SHOP_TEXTURE.PIG_PALACE.WALL
    local minimap_texture = PIG_SHOP_TEXTURE.PIG_PALACE.MINIMAP

    local togallery_door_def =
    {
        my_door_id = "palace_courtroom_WEST",
        target_door_id = "palace_gallery_EAST",
        target_interior = gallery_id,
    }

    local palace_addprops = GetPropDef("pig_palace", depth, width, exterior_door_def, togallery_door_def)
    local def = interior_spawner:CreateRoom("generic_interior", width, height, depth, name, inst.interiorID, palace_addprops, {}, wall_texture, floor_texture, minimap_texture, city_id, PIG_SHOP_COLOUR_CUBE, nil, nil, "palace", "PALACE", "STONE")
    interior_spawner:SpawnInterior(def)
    InitShopped(inst.interiorID)

    -- CREATE GALLERY

    depth = 12
    width = 18
    height = 12

    local togiftshop_door_def =
    {
        my_door_id = "palace_gallery_WEST",
        target_door_id = "palace_giftshop_EAST",
        target_interior = giftshop_id,
    }
    local topalace_door_def =
    {
        my_door_id = "palace_gallery_EAST",
        target_door_id = "palace_courtroom_WEST",
        target_interior = inst.interiorID,
    }

    local gallery_addprops = GetPropDef("pig_palace_gallery", depth, width, togiftshop_door_def, topalace_door_def)
    def = interior_spawner:CreateRoom("generic_interior", width, height, depth, name, gallery_id, gallery_addprops, {}, wall_texture, floor_texture, minimap_texture, city_id ,PIG_SHOP_COLOUR_CUBE, nil, nil, "palace", "PALACE", "STONE")
    interior_spawner:SpawnInterior(def)
    InitShopped(gallery_id)

    -- CREATE GIFT SHOP

    depth = 10
    width = 15
    height = 11

    local toexit_door_def =
    {
        my_door_id = "palace_giftshop_SOUTH",
        target_door_id = exterior_door_def.my_door_id,
        target_exterior = inst.interiorID,
    }
    local togallery_door_def =
    {
        my_door_id = "palace_giftshop_EAST",
        target_door_id = "palace_gallery_WEST",
        target_interior = gallery_id,
    }

    local giftshop_addprops = GetPropDef("pig_palace_giftshop", depth, width, toexit_door_def, togallery_door_def)
    def = interior_spawner:CreateRoom("generic_interior", width, height, depth, name, giftshop_id, giftshop_addprops, {}, wall_texture, floor_texture, minimap_texture, city_id, PIG_SHOP_COLOUR_CUBE, nil, nil, "palace", "PALACE", "STONE")
    interior_spawner:SpawnInterior(def)
    InitShopped(giftshop_id)
end

local function CreateInterior(inst)
    local id = inst.interiorID
    local can_reuse_interior = id ~= nil

    local interior_spawner = TheWorld.components.interiorspawner
    if not can_reuse_interior then
        id = interior_spawner:GetNewID()
        inst.interiorID = id
        print("CreateInterior id:", id)
    end

    local name = inst.prefab .. id

    local exterior_door_def = {
        my_door_id = name .. "_door",
        target_door_id = name .. "_exit",
        target_interior = id,
    }
    interior_spawner:AddDoor(inst, exterior_door_def)
    interior_spawner:AddExterior(inst)

    if can_reuse_interior then
        -- Reuse old interior, but we still need to re-register the door
        return
    end

    if inst.prefab == "pig_palace" then
        return CreateInteriorPalace(inst, exterior_door_def)
    end

    local textures = PIG_SHOP_TEXTURE[string.upper(inst.prefab)]
    local floor_texture = textures and textures.FLOOR or PIG_SHOP_TEXTURE.DEFAULT.FLOOR
    local wall_texture = textures and textures.WALL or PIG_SHOP_TEXTURE.DEFAULT.WALL
    local minimap_texture = textures and textures.MINIMAP or PIG_SHOP_TEXTURE.DEFAULT.MINIMAP

    local width = TUNING.ROOM_TINY_WIDTH -- 15
    local depth = TUNING.ROOM_TINY_DEPTH -- 10
    local height = nil

    if inst:HasTag("pig_shop_bank") or inst:HasTag("pig_shop_tinker") then
        height = 6
    end

    local addprops = GetPropDef(inst.prefab, depth, width, exterior_door_def)

    local cityID = inst.components.citypossession and inst.components.citypossession.cityID

    local def = interior_spawner:CreateRoom("generic_interior", width, height, depth, name, id, addprops, {},
        wall_texture, floor_texture, minimap_texture, cityID, PIG_SHOP_COLOUR_CUBE, nil, nil, PIG_SHOP_REVERB,
        PIG_SHOP_AMBIENT_SOUND, PIG_SHOP_FOOTSTEP)
    interior_spawner:SpawnInterior(def)
    InitShopped(inst.interiorID, inst.prefab)
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") then
        data.burnt = true
    end
    data.interiorID = inst.interiorID
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.burnt then
        inst.components.burnable.onburnt(inst)
    end

    if data.interiorID then
        inst.interiorID = data.interiorID

        -- Checks if the cityhall has the construction_permit for sale, and if it doesn't, it patches it in
        --[[
        if inst.prefab == "pig_shop_cityhall" then
            inst:DoTaskInTime(0, function()

                local patched = false
                local interior_ents = {}

                local interior_spawner = GetInteriorSpawner()
                local interior = interior_spawner:GetInteriorByName(inst.interiorID)
                local inside_interior = interior == interior_spawner.current_interior
                local pt = interior_spawner:getSpawnOrigin()

                -- Gets the interior entities wether the interior has been visited or not
                local function GetInteriorEnts()
                    if inside_interior then
                        return TheSim:FindEntities(pt.x, pt.y, pt.z, 50, nil, {"INTERIOR_LIMBO", "INLIMBO"})
                    else
                        return interior.object_list
                    end
                end

                interior_ents = GetInteriorEnts()

                -- Checks if we have 3 pedestals, if we do, cancel the patching
                local buyer_count = 0
                for _, ent in pairs(interior_ents) do
                    if ent.prefab == "shop_buyer" then
                        buyer_count = buyer_count + 1
                        if buyer_count >= 4 then
                            patched = true
                            break
                        end
                    end
                end

                -- x_offset = 1.75,   z_offset =  width/2-5

                if not patched then

                    local saleitems =
                    {
                        {"construction_permit", "oinc", 50 },
                        {"demolition_permit",   "oinc", 10 },
                    }

                    local offsets =
                    {
                        { x_offset = 3.5, z_offset =  TUNING.ROOM_TINY_WIDTH/2-2 },
                        { x_offset = -1,  z_offset =  TUNING.ROOM_TINY_WIDTH/2-2 },
                    }

                    local animation = "idle_globe_bar"

                    if interior.visited then
                        for _, ent in pairs(interior_ents) do
                            if ent.prefab == "shop_buyer" and ent.components.shopdispenser.item_served == "deed" then
                                local x, y, z = ent.Transform:GetWorldPosition()
                                ent.Transform:SetPosition(x + 1.75, y, z -2)
                                c_select(ent)
                                break
                            end
                        end
                    else
                        for _, prefab in ipairs(interior.prefabs) do
                            if prefab.name == "shop_buyer" and prefab.saleitem[1] == "deed" then
                                prefab.x_offset = 1.75
                                prefab.z_offset = TUNING.ROOM_TINY_WIDTH/2-5
                            end
                        end
                    end

                    for i = 1, #saleitems do
                        local offset = offsets[i]
                        local saleitem = saleitems[i]
                        local prefab_data = {saleitem = saleitem, animation = animation }

                        -- If the interior has been visited we have to spawn the prefab, initialize it and put it in the interior
                        if interior.visited then
                            local pedestal = SpawnPrefab("shop_buyer")
                            -- Sets position, item and animation
                            pedestal.Transform:SetPosition(pt.x + offset.x_offset, 0, pt.z + offset.z_offset) -- HERE
                            pedestal.saleitem = saleitem -- HERE
                            pedestal.AnimState:PlayAnimation(animation)
                            pedestal.animation = animation

                            -- Shop spawner contains a bunch of info about the store itself, so we need it to initialize our pedestals
                            local shop_spawner = nil
                            for _, ent in pairs(interior_ents) do
                                if ent.prefab == "shop_spawner" then
                                    shop_spawner = ent
                                    break
                                end
                            end

                            -- This shouldn't happen
                            if not shop_spawner then
                                print ("ERROR: COULD NOT FIND SHOP SPAWNER")
                            else -- Sets the proper products and what not
                                local product = shop_spawner.components.shopinterior:GetNewProduct("pig_shop_cityhall")

                                pedestal.components.shopped:SetShop(shop_spawner, "pig_shop_cityhall")
                                pedestal:AddTag("pig_shop_item")
                                pedestal:SpawnInventory(saleitem[1], saleitem[2], saleitem[3]) -- HERE

                                -- If we're not currently in the interior, put the pedestal in limbo
                                if interior ~= interior_spawner.current_interior then
                                    interior_spawner:PutPropIntoInteriorLimbo(pedestal, interior)
                                end
                            end
                        else -- If the interior hasn't been visited, just insert the prefab. Easy.
                            interior_spawner:insertprefab(interior, "shop_buyer", offset, prefab_data) -- HERE
                        end
                    end
                end
            end)
        end
        ]]
    end
end

local function UseDoor(inst, data)
    if inst.use_sounds and data and data.doer and data.doer.SoundEmitter then
        for _, sound in ipairs(inst.use_sounds) do
            data.doer.SoundEmitter:PlaySound(sound)
        end
    end
end

local function OnBurntUp(inst, data)
    inst.components.fixable:AddRecinstructionStageData("burnt", inst.bank, inst.build, nil, 1)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
    inst:Remove()
end

local function canburn(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    if inst.components.door then
        local interior = inst.components.door.target_interior
        if interior_spawner:IsPlayerConsideredInside(interior) then
            -- try again in 2-5 seconds
            return false, 2 + math.random() * 3
        end
    end
    return true
end

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            local x, _, z = inst._pfpos:Get()
            for delta_x = 0, 1 do
                for delta_z = 0, 1 do
                    TheWorld.Pathfinder:AddWall(x + delta_x - 0.5, 0, z + delta_z - 0.5)
                end
            end
        end
    elseif inst._pfpos ~= nil then
        local x, _, z = inst._pfpos:Get()
        for delta_x = 0, 1 do
            for delta_z = 0, 1 do
                TheWorld.Pathfinder:RemoveWall(x + delta_x - 0.5, 0, z + delta_z - 0.5)
            end
        end
        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function MakeObstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

local function ClearObstacle(inst)
    inst.Physics:SetActive(false)
    inst._ispathfinding:set(false)
end

local function OnRemove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

local function MakeShop(name, build, bank, data)
    data = data or {}
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1.25)

        inst.bank = bank or "pig_shop"
        inst.build = build

        inst.AnimState:SetBank(inst.bank)
        inst.AnimState:SetBuild(inst.build)
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:Hide("YOTP")
        if name == "pig_shop_cityhall" then
            inst.AnimState:AddOverrideBuild("flag_post_duster_build")
        end
        if name == "pig_shop_cityhall_player" then
            inst.AnimState:AddOverrideBuild("flag_post_wilson_build")
        end

        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(0.5)
        inst.Light:SetRadius(1)
        inst.Light:Enable(false)
        inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

        if name == "pig_shop_cityhall_player" then
            inst.MiniMapEntity:SetIcon("pig_shop_cityhall.tex")
        else
            inst.MiniMapEntity:SetIcon(name .. ".tex")
        end

        inst:AddTag(name)
        inst:AddTag("structure")
        inst:AddTag("city_hammerable")

        if not data.no_shop_music then
            inst:AddTag("shop_music")
        end

        -- if name == "pig_shop_cityhall_player" then
        --     GetPlayer():AddTag("mayor")
        -- end

        ------- Copied from prefabs/wall.lua -------
        inst._pfpos = nil
        inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
        MakeObstacle(inst)
        -- Delay this because makeobstacle sets pathfinding on by default
        -- but we don't to handle it until after our position is set
        inst:DoTaskInTime(0, InitializePathFinding)

        inst:ListenForEvent("onremove", OnRemove)
        --------------------------------------------

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.use_sounds = data.sounds
        inst.break_sound_sufix = data.use_stone_break_sound and "stone" or "wood"

        inst:AddComponent("gridnudger")
        inst.components.gridnudger.snap_to_grid = true

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")

        inst:AddComponent("door")
        inst.components.door.outside = true

        inst:AddComponent("fixable")
        inst.components.fixable:AddRecinstructionStageData("rubble", inst.bank, inst.build)
        inst.components.fixable:AddRecinstructionStageData("unbuilt", inst.bank, inst.build)

        if not data.indestructable then
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetWorkLeft(4)
            inst.components.workable:SetOnWorkCallback(OnHit)
            inst.components.workable:SetOnFinishCallback(OnHammered)
        end

        if data.spawner then
            inst:AddComponent("spawner")
            inst.components.spawner:SetOnVacateFn(OnVacate)
            inst.components.spawner:SetOnOccupiedFn(OnOccupied)
            inst.components.spawner:SetWaterSpawning(false, true)
            inst.components.spawner:Configure(data.spawner.prefab, data.spawner.delay)
            inst:DoTaskInTime(0, InitSpawner)
        end

        inst:ListenForEvent("onbuilt", OnBuilt)
        inst:ListenForEvent("usedoor", UseDoor)
        inst:ListenForEvent("burntup", OnBurntUp)

        inst:WatchWorldState("isnight", OnNight)
        OnNight(inst, TheWorld.state.isnight)
        inst:WatchWorldState("isfiesta", OnIsFiesta)
        OnIsFiesta(inst, TheWorld.state.isfiesta)

        inst:DoTaskInTime(0, CreateInterior)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        if not data.unburnable then
            MakeLargeBurnable(inst, nil, nil, true)
            MakeLargePropagator(inst)
            -- inst.components.burnable:SetCanActuallyBurnFunction(canburn)
        end

        MakeSnowCovered(inst, 0.01)
        MakeHauntableWork(inst)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

-- TODO: Make this work
local function PlaceTestFn(inst)
    inst.AnimState:Hide("YOTP")
    inst.AnimState:Hide("SNOW")

    local x, y, z = inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    if tile == WORLD_TILES.INTERIOR then
        return false
    end

    return true
end

return MakeShop("pig_shop_deli",            "pig_shop_deli",        nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_general",         "pig_shop_general",     nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, use_stone_break_sound = true}),
       MakeShop("pig_shop_hoofspa",         "pig_shop_hoofspa",     nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_produce",         "pig_shop_produce",     nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_florist",         "pig_shop_florist",     nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_antiquities",     "pig_shop_antiquities", nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, use_stone_break_sound = true}),
       MakeShop("pig_shop_academy",         "pig_shop_accademia",   nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_arcane",          "pig_shop_arcane",      nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_weapons",         "pig_shop_weapons",     nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_hatshop",         "pig_shop_millinery",   nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}}),
       MakeShop("pig_shop_bank",            "pig_shop_bank",        nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, use_stone_break_sound = true}),
       MakeShop("pig_shop_tinker",          "pig_shop_tinker",      nil,            {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, use_stone_break_sound = true}),
       MakeShop("pig_shop_cityhall",        "pig_cityhall",         "pig_cityhall", {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, indestructable = true, unburnable = true, no_shop_music = true}),
       MakeShop("pig_shop_cityhall_player", "pig_cityhall",         "pig_cityhall", {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, use_stone_break_sound = true, unburnable = true, no_shop_music = true}),
       MakeShop("pig_palace",               "palace",               "palace",       {sounds = {SHOPSOUND_ENTER1, SHOPSOUND_ENTER2}, indestructable = true, unburnable = true, no_shop_music = true, spawner = {prefab = "pigman_banker", delay = TUNING.TOTAL_DAY_TIME * 4}}),

       MakePlacer("pig_shop_deli_placer",        "pig_shop",     "pig_shop_deli",        "idle", false, false, true),
       MakePlacer("pig_shop_general_placer",     "pig_shop",     "pig_shop_general",     "idle", false, false, true),
       MakePlacer("pig_shop_hoofspa_placer",     "pig_shop",     "pig_shop_hoofspa",     "idle", false, false, true),
       MakePlacer("pig_shop_produce_placer",     "pig_shop",     "pig_shop_produce",     "idle", false, false, true),
       MakePlacer("pig_shop_florist_placer",     "pig_shop",     "pig_shop_florist",     "idle", false, false, true),
       MakePlacer("pig_shop_antiquities_placer", "pig_shop",     "pig_shop_antiquities", "idle", false, false, true),
       MakePlacer("pig_shop_arcane_placer",      "pig_shop",     "pig_shop_arcane",      "idle", false, false, true),
       MakePlacer("pig_shop_weapons_placer",     "pig_shop",     "pig_shop_weapons",     "idle", false, false, true),
       MakePlacer("pig_shop_hatshop_placer",     "pig_shop",     "pig_shop_millinery",   "idle", false, false, true),
       MakePlacer("pig_shop_cityhall_placer",    "pig_cityhall", "pig_cityhall",         "idle", false, false, true),
       MakePlacer("pig_shop_bank_placer",        "pig_shop",     "pig_shop_bank",        "idle", false, false, true),
       MakePlacer("pig_shop_tinker_placer",      "pig_shop",     "pig_shop_tinker",      "idle", false, false, true)
