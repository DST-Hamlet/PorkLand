local interiorspawner = require("components/interiorspawner")

local assets =
{
    Asset("ANIM", "anim/player_house_doors.zip"),
}

local DEPTH = 10
local WIDTH = 15

PLAYER_INTERIOR_EXIT_DIR_DATA =
{
    ["north"] = {
        anim = "north",
        door_tag = "door_north",
        my_door_id_dir = "_NORTH",
        target_door_id_dir = "_SOUTH",
        x_offset = -DEPTH/2,
        z_offset = 0,
        opposing_exit_dir = interiorspawner:GetSouth(),
        op_dir = "south",
        angle = 0,
        background = true,
    },

    ["south"] = {
        anim = "south",
        door_tag = "door_south",
        my_door_id_dir = "_SOUTH",
        target_door_id_dir = "_NORTH",
        x_offset = DEPTH/2,
        z_offset = 0,
        opposing_exit_dir = interiorspawner:GetNorth(),
        op_dir = "north",
        angle = 180,
        background = false,
    },

    -- Note that the anims for east and west are reversed.
    -- If we clean up the source assets we should only need to change these
    ["east"] = {
        anim = "west",
        door_tag = "door_east",
        my_door_id_dir = "_EAST",
        target_door_id_dir = "_WEST",
        x_offset = 0,
        z_offset = WIDTH/2,
        opposing_exit_dir = interiorspawner:GetWest(),
        op_dir = "west",
        angle = 90,
        background = true,
    },

    ["west"] = {
        anim = "east",
        door_tag = "door_west",
        my_door_id_dir = "_WEST",
        target_door_id_dir = "_EAST",
        x_offset = 0,
        z_offset = -WIDTH/2,
        opposing_exit_dir = interiorspawner:GetEast(),
        op_dir = "east",
        angle = 270,
        background = true,
    }
}

local function CheckForShadow(inst)
    inst:DoTaskInTime(0, function()
        if inst.baseanimname == "south" and not inst._house_door_shadow then
            inst._house_door_shadow = inst:AddChild(SpawnPrefab("house_door_shadow"))
        end
    end)
end

local function GetBaseAnimName(inst)
    local position = inst:GetPosition()
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    local origin = center:GetPosition()
    local delta = position - origin
    if math.abs(delta.x) > math.abs(delta.z) then
        -- north or south
        if delta.x > 0 then
            return "south"
        else
            return "north"
        end
    else
        -- east or west
        if delta.z < 0 then
            return "west"
        else
            return "east"
        end
    end
end

local function InitHouseDoorInteriorPrefab(inst, doer, prefab_definition, interior_definition)
    --If we are spawned inside of a building, then update our door to point at our interior

    local door_definition =
    {
        my_interior_name = interior_definition.unique_name,
        my_door_id = prefab_definition.my_door_id,
        target_door_id = prefab_definition.target_door_id,
        target_interior = prefab_definition.target_interior,
    }

    TheWorld.components.interiorspawner:AddDoor(inst, door_definition)
    if prefab_definition.animdata then
        if prefab_definition.animdata.bank then
            inst.AnimState:SetBank(prefab_definition.animdata.bank)
            inst.door_data_bank = prefab_definition.animdata.bank
        end

        if prefab_definition.animdata.build then
            inst.AnimState:SetBuild(prefab_definition.animdata.build)
            inst.door_data_build = prefab_definition.animdata.build
        end

        if prefab_definition.animdata.anim then
            inst.AnimState:PlayAnimation(prefab_definition.animdata.anim, true)
            inst.door_data_animstate = prefab_definition.animdata.anim
        end

        inst.baseanimname = GetBaseAnimName(inst)
        if prefab_definition.animdata.background then
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
            inst.components.rotatingbillboard:SetAnimation_Server(prefab_definition.animdata)
            inst.AnimState:SetSortOrder(3)
            inst.door_data_background = prefab_definition.animdata.background
        else
            inst.AnimState:SetLayer(LAYER_WORLD)
        end
    end

    if inst.components.door then
        inst.components.door:UpdateDoorVis()
    end
    inst.components.door:SetDoorDisabled(false, "house_prop")
    inst:AddTag("interior_door")
    inst:AddTag("client_forward_action_target")
    inst:RemoveTag("predoor")

    if prefab_definition.addtags then
        for _, tag in ipairs(prefab_definition.addtags) do
            inst:AddTag(tag)
        end
    end

    CheckForShadow(inst)
end

local function InitHouseDoor(inst)
    local dir = GetBaseAnimName(inst)
    inst.door_data_animstate = inst.prefab .. "_open_" .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].anim
    inst.baseanimname = GetBaseAnimName(inst)

    inst.AnimState:PlayAnimation(inst.prefab .. "_opening_" .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].anim, false)
    inst.AnimState:PushAnimation(inst.door_data_animstate, true)

    if inst.baseanimname ~= "south" then
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
    else
        inst.AnimState:SetLayer(LAYER_WORLD)
    end

    inst.initialized = true
end

local function ActivateSelf(inst, target_interior, current_interior)
    inst.components.door:SetDoorDisabled(false, "house_prop")

    local door_def =
    {
        my_interior_name = current_interior,
        my_door_id = current_interior .. PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].my_door_id_dir,
        target_interior = target_interior,
        target_door_id =  target_interior .. PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].target_door_id_dir
    }

    TheWorld.components.interiorspawner:AddDoor(inst, door_def)
    inst:InitHouseDoor(inst.baseanimname)

    inst:AddTag("interior_door")
    inst:AddTag("client_forward_action_target")
    inst:RemoveTag("predoor")

    inst:RemoveComponent("inspectable")
    inst.checked_obstruction = true
end

local function DeactivateSelf(inst)
    inst.components.door:SetDoorDisabled(true, "house_prop")
    TheWorld.components.interiorspawner:RemoveDoor(inst.components.door.door_id)
    inst:AddTag("predoor")
    inst:RemoveTag("interior_door")
    inst:RemoveTag("client_forward_action_target")

    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
    end
    inst.AnimState:PlayAnimation(inst.prefab .. "_close_" .. PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].anim)

    -- clear door connectivity....
    inst.components.door.door_id = nil
    inst.components.door.interior_name = nil
    inst.components.door.target_door_id = nil
    inst.components.door.target_interior = nil
    -- ...and anim
    inst.door_data_animstate = nil
end

-- Used to remove things on the wall on the other side of a recently built door
-- Can also be used when hammering a door
local function ClearObstruction(inst)
    local pt = inst:GetPosition()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(pt.x, pt.y, pt.z)
    fx:SetMaterial("wood")

    inst.components.lootdropper:DropLoot()

    inst:Remove()
end

local function OnFinishCallback(inst, worker)
    if inst.components.door.target_interior then
        local room = TheWorld.components.interiorspawner:GetInteriorCenter(inst.components.door.target_interior)

        local target_door = room and room:GetDoorById(inst.components.door.target_door_id)
        if target_door then
            target_door:Remove() -- Remove door instance on the other side
        end

        TheWorld.components.interiorspawner:RemoveDoor(inst.components.door.target_door_id) -- Remove target door from interior_spawner
        TheWorld.components.interiorspawner:RemoveDoor(inst.components.door.door_id) -- Remove self from interior_spawner
    end

    ClearObstruction(inst) -- Destroy self and drop loot
end

local function WorkMultiplierFn(inst, worker, numworks)
    if worker:HasTag("player") or worker:HasTag("interior_destroyer") then -- only worked by the player
        return 1
    else
        return 0
    end
end

local function OnSave(inst, data)
    if inst.door_data_animstate then
        data.door_data_animstate = inst.door_data_animstate
    end

    if inst.door_data_background then
        data.door_data_background = inst.door_data_background
    end

    if inst.flipped then
        data.flipped = inst.flipped
    end

    if inst.checked_obstruction then
        data.checked_obstruction = inst.checked_obstruction
    end

    if inst.baseanimname then
        data.baseanimname = inst.baseanimname
    end
end

local function OnLoad(inst, data)
    inst.baseanimname = data.baseanimname or "north"

    if data.door_data_animstate then
        inst.AnimState:PlayAnimation(data.door_data_animstate, true)
        inst.door_data_animstate = data.door_data_animstate
    else
        inst.AnimState:PlayAnimation(inst.prefab .. "_close_" .. PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].anim, true)
    end

    -- alas, the background flag wasn't correctly set on old doors
    data.door_data_background = inst.baseanimname ~= "south"

    if data.door_data_background then
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.door_data_background = data.door_data_background
    else
        inst.AnimState:SetLayer(LAYER_WORLD)
    end

    if data.checked_obstruction then
        inst.checked_obstruction = data.checked_obstruction
    end
end

local function OnLoadPostPass(inst)
    if inst.components.door.target_door_id then
        inst:AddTag("interior_door")
        inst:AddTag("client_forward_action_target")
        inst:RemoveTag("predoor")
        inst:RemoveComponent("inspectable")
    end

    inst.baseanimname = GetBaseAnimName(inst)
    inst:AddTag(PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].door_tag)
end

local function OnEntityWake(inst)
    if not inst.checked_obstruction then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 3, {"wallsection"})
        if #ents >= 1 then
            for _, ent in pairs(ents) do
                if ent ~= inst then
                    ClearObstruction(ent)
                end
            end
        end
        inst.checked_obstruction = true
    end

    CheckForShadow(inst)
end

local function OnBuilt(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    local current_interior = interior_spawner:GetInteriorCenter(inst:GetPosition())
    local current_room_id = current_interior.interiorID

    local baseanimname = GetBaseAnimName(inst)
    inst.baseanimname = baseanimname
    inst:AddTag(PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].door_tag)
    CheckForShadow(inst)

    -- players can build a new door directly on the old door to change its look
    local replace_existing_door = false
    local cx, cy, cz = current_interior.Transform:GetWorldPosition()
    local doors = TheSim:FindEntities(cx, cy, cz, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})
    for i, door in ipairs(doors) do
        if door and door.baseanimname then
            -- Built a new door in the same direction of a previously built door (Multiple doors on a single wall)
            if door.baseanimname == baseanimname then
                ActivateSelf(inst, door.components.door.target_interior, current_room_id)
                door:Remove() -- Deletes an old door
                replace_existing_door = true
                break
            end
        end
    end

    if not replace_existing_door then
        local connecting_room = interior_spawner:GetRoomInDirection(current_interior, interior_spawner:GetDirByLabel(baseanimname))
        if connecting_room then
            local connecting_room_id = connecting_room.interiorID
            local interior_def = interior_spawner:GetInteriorDefinition(connecting_room_id)
            ActivateSelf(inst, connecting_room_id, current_room_id)

            local opposing_exit = PLAYER_INTERIOR_EXIT_DIR_DATA[baseanimname].op_dir
            local door_data = {
                name = inst.prefab,
                x_offset = PLAYER_INTERIOR_EXIT_DIR_DATA[opposing_exit].x_offset,
                z_offset = PLAYER_INTERIOR_EXIT_DIR_DATA[opposing_exit].z_offset,
                animdata = {
                    bank = "player_house_doors",
                    build = "player_house_doors",
                    anim = inst.prefab .. "_open_" .. PLAYER_INTERIOR_EXIT_DIR_DATA[opposing_exit].anim,
                    background = PLAYER_INTERIOR_EXIT_DIR_DATA[opposing_exit].background
                },
                my_interior_name = connecting_room_id,
                my_door_id = connecting_room_id .. PLAYER_INTERIOR_EXIT_DIR_DATA[baseanimname].target_door_id_dir,
                target_door_id = current_room_id .. PLAYER_INTERIOR_EXIT_DIR_DATA[baseanimname].my_door_id_dir,
                target_interior = current_room_id,
                rotation = -90,
                hidden = false,
                angle = 0,
                addtags = {"door_" .. opposing_exit},
            }

            local offset = Vector3(PLAYER_INTERIOR_EXIT_DIR_DATA[opposing_exit].x_offset, 0, PLAYER_INTERIOR_EXIT_DIR_DATA[opposing_exit].z_offset)
            local new_door = interior_spawner:SpawnObject(connecting_room_id, inst.prefab, offset)
            new_door:initInteriorPrefab(nil, door_data, interior_def)
            interior_spawner:AddDoor(new_door, door_data)

            -- if baseanimname == "north" then
            --     local prefabdata = {
            --         name = "house_door_shadow",
            --         x_offset = (DEPTH/2),
            --         z_offset = 0,
            --         animdata = {
            --             bank = "player_house_doors",
            --             build = "player_house_doors",
            --             anim = inst.prefab .. "_south_floor"
            --         }
            --     }
            --     interior_spawner:insertprefab(interior_def, prefabdata.name, {
            --         x_offset = prefabdata.x_offset,
            --         z_offset = prefabdata.z_offset
            --     }, prefabdata)
            -- end
        end
    end

    -- Replaces a door that hasn't been activated yet
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, {"wallsection"})
    if #ents >= 1 then
        for _, ent in pairs(ents) do
            if ent:HasTag("predoor") and ent ~= inst then
                ent:Remove()
                break
            end
        end
    end

    if not inst.initialized then
        inst.animdata.anim = inst.prefab .. "_close_" .. PLAYER_INTERIOR_EXIT_DIR_DATA[GetBaseAnimName(inst)].anim
        inst.animdata.animation = inst.animdata.anim
        inst.AnimState:PlayAnimation(inst.animdata.anim)
        inst.components.rotatingbillboard:SetAnimation_Server(inst.animdata)

        local background = PLAYER_INTERIOR_EXIT_DIR_DATA[inst.baseanimname].background
        if background then
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        else
            inst.AnimState:SetLayer(LAYER_WORLD)
        end
    end
end

local function DoorCanBeRemoved(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    local current_interior = interior_spawner:GetInteriorCenter(inst:GetCurrentInteriorID())
    return interior_spawner:ConnectedToExitAndNoUnreachableRooms(current_interior, inst.baseanimname)
end

local function RoomCanBeRemoved(inst)
    local interior_spawner = TheWorld.components.interiorspawner
    local current_interior = interior_spawner:GetInteriorCenter(inst:GetCurrentInteriorID())
    return interior_spawner:ConnectedToExitAndNoUnreachableRooms(current_interior, inst.baseanimname, inst.components.door.target_interior)
end

local function MakeHouseDoor(name)
    local function house_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.Transform:SetRotation(-90)

        local anim_data = {
            bank = "player_house_doors",
            build = "player_house_doors",
            animation = name .. "_close_" .. PLAYER_INTERIOR_EXIT_DIR_DATA["north"].anim,
        }

        inst.AnimState:SetBank(anim_data.bank)
        inst.AnimState:SetBuild(anim_data.build)
        inst.AnimState:PlayAnimation(anim_data.animation)
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst:AddTag("predoor")
        inst:AddTag("NOBLOCK")
        inst:AddTag("wallsection")
        inst:AddTag("house_door")

        inst:AddComponent("rotatingbillboard")
        inst.components.rotatingbillboard.animdata = anim_data

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("door")
        inst.components.door:SetDoorDisabled(true, "house_prop")

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnFinishCallback)
        inst.components.workable.workmultiplierfn = WorkMultiplierFn

        inst.animdata = anim_data

        MakeHauntable(inst)

        inst.DoorCanBeRemoved = DoorCanBeRemoved
        inst.RoomCanBeRemoved = RoomCanBeRemoved
        inst.InitHouseDoor = InitHouseDoor
        inst.initInteriorPrefab = InitHouseDoorInteriorPrefab
        inst.ActivateSelf = ActivateSelf
        inst.DeactivateSelf = DeactivateSelf
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnLoadPostPass = OnLoadPostPass
        -- Finds obstructions on the way of the new door and deconstructs them
        inst.OnEntityWake = OnEntityWake
        inst.OnBuilt = OnBuilt

        return inst
    end

    return Prefab(name, house_fn, assets)
end

local function place_door_test_fn(inst)
    inst.Transform:SetRotation(-90)
    local pt = inst.components.placer.selected_pos or TheInput:GetWorldPosition()

    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(ThePlayer:GetPosition())
    if current_interior then
        local center_pos = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dist = 2
        local newpt = {}
        local backdiff =  pt.x < (center_pos.x - depth/2 + dist)
        local frontdiff = pt.x > (center_pos.x + depth/2 - dist)
        local rightdiff = pt.z > (center_pos.z + width/2 - dist)
        local leftdiff =  pt.z < (center_pos.z - width/2 + dist)

        local name = string.gsub(inst.prefab, "_placer", "")

        local canbuild = true
        local rot = -90
        if backdiff and not rightdiff and not leftdiff then
            newpt = {x = center_pos.x - depth/2, y = 0, z = center_pos.z}
            inst.AnimState:PlayAnimation(name .. "_open_north")
        elseif frontdiff and not rightdiff and not leftdiff then
            newpt = {x = center_pos.x + depth/2, y = 0, z = center_pos.z}
            inst.AnimState:PlayAnimation(name .. "_open_south")
        elseif rightdiff and not backdiff and not frontdiff then
            newpt = {x = center_pos.x, y = 0, z = center_pos.z + width/2}
            inst.AnimState:PlayAnimation(name .. "_open_west")
        elseif leftdiff and not backdiff and not frontdiff then
            newpt = {x = center_pos.x, y = 0, z = center_pos.z - width/2}
            inst.AnimState:PlayAnimation(name .. "_open_east")
        else
            newpt = pt
            canbuild = false
        end

        if canbuild then
            inst.Transform:SetPosition(newpt.x, newpt.y, newpt.z)
            inst.Transform:SetRotation(rot)
        else
            inst.Transform:SetPosition(pt.x, pt.y, pt.z)
        end

        inst.Transform:SetRotation(rot)

        local ents = TheSim:FindEntities(newpt.x, newpt.y, newpt.z, 3, {}, {}, {"wallsection", "interior_door", "predoor"})
        if #ents >= 1 then
            for _, ent in pairs(ents) do
                if (ent:HasTag("predoor") or ent:HasTag("interior_door")) and ent.prefab ~= name and ent.prefab ~= "prop_door" then
                    inst.accept_placement = true
                    return
                end
            end
        end

        if #ents < 1 and canbuild then
            inst.accept_placement = true
            return
        end
    end

    inst.accept_placement = false
end

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

local function MakeHouseDoorPlacer(name, build, bank)
    return MakePlacer(name .. "_placer", bank, build, name .. "_open_north", nil, nil, nil, nil, nil, nil, function(inst)
        inst.components.placer.onupdatetransform = place_door_test_fn
        inst.components.placer.override_build_point_fn = placer_override_build_point
        inst.components.placer.override_testfn = placer_override_testfn
        inst.accept_placement = false
    end)
end

local function InitInteriorPrefab_shadow(inst, doer, prefab_definition, interior_definition)
    --If we are spawned inside of a building, then update our door to point at our interior
    if prefab_definition.animdata then
        if prefab_definition.animdata.bank then
            inst.AnimState:SetBank(prefab_definition.animdata.bank)
            inst.door_data_bank = prefab_definition.animdata.bank
        end
        if prefab_definition.animdata.build then
            inst.AnimState:SetBuild(prefab_definition.animdata.build)
            inst.door_data_build = prefab_definition.animdata.build
        end
        if prefab_definition.animdata.anim then
            inst.AnimState:PlayAnimation(prefab_definition.animdata.anim, true)
            inst.door_data_animstate = prefab_definition.animdata.anim
            -- this is for finding the right open and closed door animation.
            inst.baseanimname = inst.door_data_animstate
        end
    end
end

local function shadowfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("player_house_doors")
    inst.AnimState:SetBuild("player_house_doors")
    inst.AnimState:PlayAnimation("wood_door_south_floor")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("SELECT_ME")
    inst:AddTag("NOCLICK")  -- Note for future self: Was commented out, but not sure why.. if it's not there, the shadow eats the click on the door.
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.initInteriorPrefab = InitInteriorPrefab_shadow

    return inst
end

return MakeHouseDoor("wood_door"),
       MakeHouseDoor("stone_door"),
       MakeHouseDoor("organic_door"),
       MakeHouseDoor("iron_door"),
       MakeHouseDoor("pillar_door"),
       MakeHouseDoor("curtain_door"),
       MakeHouseDoor("round_door"),
       MakeHouseDoor("plate_door"),

       MakeHouseDoorPlacer("wood_door",    "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("stone_door",   "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("organic_door", "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("iron_door",    "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("pillar_door",  "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("curtain_door", "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("round_door",   "player_house_doors", "player_house_doors"),
       MakeHouseDoorPlacer("plate_door",   "player_house_doors", "player_house_doors"),

       Prefab("house_door_shadow", shadowfn, assets)
