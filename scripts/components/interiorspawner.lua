-- NOTE: Sweet House used -1900 < x < 2000 and 1100 < z < 2000
-- NOTE: Porkland Room will use BORDER < x < +2000 and BORDER < z < +2000
-- BORDER VALUE is world_size/2 + 120
--
--  +------[z]------+
--  |               |
-- [x] The constant |
--  |               |
--  +---------------+
--                   \
--                    \
--                     **************************
--                     *                        *
--                     * (place in this region) *
--                     *                        *
--                     **************************
--

-- 亚丹：实际上，在上方注释版本的代码中，z的范围是(+BORDER + 2000,+infinite)
-- 亚丹：将z的坐标范围修改为(-1000,+infinite)，注意当z小于-2000时渲染会因为超出TheSim:UpdateRenderExtents而出现问题


local SPACE = 120
local MAX_X_OFFSET = 2000
local MAX_Z_OFFSET = 2000
local PADDING = 30

local InteriorSpawner = Class(function(self, inst)
    self.inst = inst
    self.world_width = -1
    self.world_height = -1
    self.x_start = math.huge
    self.z_start = math.huge

    self.exteriors = {} -- {[exterior: string]: House}
    self.interiors = {} -- {[interior: string]: interiorworkblank}
    self.interior_defs = {} -- {[index: number]: InteriorDef}
    self.doors = {} -- {[index: string]: DoorDef}
    self.reuse_interior_ids = {} -- 记录那些生成后被删掉的室内 ID，以重复利用其空间
    self.next_interior_id = 0

    -- if value is redirected_id, then access twice
    -- if value is table, that's it!
    self.interior_layout_map = {} --{[id: interiorID]: MapData | redirected_id}
    self.interior_layout_dirty_keys = {} -- {[K in keyof self.interior_layout_map]: true}

    self.player_homes = {}

    inst:DoTaskInTime(0, function()
        self:SetInteriorPos() -- 保证室内位于渲染范围内
    end)

    self.destroyer = CreateEntity() -- for workable:Destroy()
end)

function InteriorSpawner:SetInteriorPos()
    if self.pos_set then
        return
    end
    local w, h = TheWorld.Map:GetSize()
    self.world_width = w * TILE_SCALE
    self.world_height = h * TILE_SCALE
    self.x_start = self.world_width / 2 + 120
    self.z_start = self.world_height / 2 + 120

    local max_size = math.max(self.x_start + MAX_X_OFFSET, self.z_start + MAX_Z_OFFSET)
    max_size = math.ceil(2 * (max_size + SPACE + PADDING))
    TheSim:UpdateRenderExtents(max_size) -- 设置底层引擎的渲染范围。需要注意，根据官方的说法，渲染范围太大会影响性能

    self.pos_set = true

    -- for i = 1, 500 do
    --     local pos = self:IndexToPosition(i)
    --     assert(self:PositionToIndex(pos) == i, "Index not match: ".. i)
    -- end
end

function InteriorSpawner:OnSave()
    local interior_defs = {}
    for interior_id, def in pairs(self.interior_defs) do
        interior_defs[interior_id] = def
    end
    return {
        interiors = interior_defs,
        next_interior_id = self.next_interior_id,
        reuse_interior_ids = self.reuse_interior_ids,
    }
end

function InteriorSpawner:OnLoad(data)
    if data then
        if data.interiors then
            for _, def in pairs(data.interiors) do
                self:AddInterior(def)
            end
        end
        if data.next_interior_id then
            self.next_interior_id = data.next_interior_id
        end
        if data.reuse_interior_ids then
            self.reuse_interior_ids = data.reuse_interior_ids
        end
    end
    self:SetInteriorPos()
end

-- WARNING: this mothod cannot be called before game load (interiorID is nil)
function InteriorSpawner:GetCurrentMaxId()
    local index = 0
    for id in pairs(self.interiors) do
        index = math.max(id, index)
    end
    self.next_interior_id = index
    return index
end

function InteriorSpawner:GetNewID() -- 注意：每次该函数被调用，都会占用一个 interiorID 及其对应的室内区域，因此确定有使用需求再调用此函数
        -- 并且需要在该室内区域移除后需要触发回调，通过 reuse_interior_ids 来重复使用 interiorID
    local reuse_id = next(self.reuse_interior_ids)
    if reuse_id then
        self.reuse_interior_ids[reuse_id] = nil
        return reuse_id
    end
    self.next_interior_id = self.next_interior_id + 1
    return self.next_interior_id
end

-- function InteriorSpawner:Debug_CalculateNumSlots()
--     print(string.format("World size: %dx%d", self.world_width, self.world_height))
--     local x_size = math.floor(MAX_X_OFFSET / SPACE)
--     local y_size = math.floor((MAX_Z - MIN_Z) / SPACE)
--     print(string.format("InteriorSpawner can use %d slots (%dx%d)",
--         x_size * y_size,
--         x_size, y_size))
-- end

-- TODO: Make all x, z things take a Vector3 or x, y, z for easier access
function InteriorSpawner:IsInInteriorRegion(x, z)
    return x >= self.x_start - PADDING and x <= self.x_start + MAX_X_OFFSET + PADDING
        and z >= - 1000 -100 and z <= self.z_start + MAX_Z_OFFSET + PADDING -- 实际z坐标从-1000开始，因为在z<1000的位置，小地图同步会出现问题
end

function InteriorSpawner:IsInInteriorRoom(x, z, padding)
    padding = padding or 0
    local position = Vector3(x, 0, z)
    local ent = self:GetInteriorCenter(position)
    if ent ~= nil then
        local width, depth = ent:GetSize()
        local offset = ent:GetPosition() - position
        return math.abs(offset.x) < depth/2 + padding and math.abs(offset.z) < width/2 + padding
    end
end

function InteriorSpawner:IsInInterior(x, z)
    return self.world_width > 0 and self:IsInInteriorRegion(x, z) and self:IsInInteriorRoom(x, z)
end

-- Finds the interior center with position or index (interiorID)
-- Uses FindEntities on client, so only works if you're close to that interiorworkblank (center)
function InteriorSpawner:GetInteriorCenter(position_or_index)
    if not position_or_index then
        print("InteriorSpawner:GetInteriorCente the param position_or_index is nil!!!")
        return nil
    end
    local is_number = type(position_or_index) == "number"
    if TheWorld.ismastersim then
        local position = is_number and self:IndexToPosition(position_or_index) or position_or_index
        if not self:IsInInteriorRegion(position.x, position.z) then
            return
        end
        local index = is_number and position_or_index or self:PositionToIndex(position_or_index)
        return self.interiors[index]
    end

    local position = is_number and self:IndexToPosition(position_or_index) or position_or_index
    for _, v in ipairs(TheSim:FindEntities(position.x, 0, position.z, TUNING.ROOM_FINDENTITIES_RADIUS, {"pl_interiorcenter"})) do
        return v
    end
end

function InteriorSpawner:IndexToPosition(i)
    self:SetInteriorPos()
    local x_size = math.floor(MAX_X_OFFSET / SPACE)
    local x_index = i % x_size
    local z_index = math.floor(i / x_size)
    return Vector3(
        x_index * SPACE + self.x_start,
        0,
        z_index * SPACE - 1000) -- 实际z坐标从-1000开始，因为在z<1000的位置，小地图同步会出现问题
end

-- Doesn't check if the position is in the interior area or ont
function InteriorSpawner:PositionToIndex(pos)
    self:SetInteriorPos()
    local x_size = math.floor(MAX_X_OFFSET / SPACE)
    local x_index = math.floor((pos.x - self.x_start) / SPACE + 0.5)
    local z_index = math.floor((pos.z + 1000) / SPACE + 0.5) -- 实际z坐标从-1000开始，因为在z<1000的位置，小地图同步会出现问题
    return z_index * x_size + x_index
end

-- Get the interior define with position or index (interiorID)
function InteriorSpawner:GetInteriorDefine(position_or_id)
    local id = type(position_or_id) == "number" and position_or_id or self:PositionToIndex(position_or_id)
    return self.interior_defs[id]
end

function InteriorSpawner:AddExterior(entity)
    entity:AddTag("exterior_door")
    local interior_id = entity.interiorID
    self.exteriors[interior_id] = entity
    entity.interiorspawner_exterior_on_remove_listener = function()
        if not entity.components.fixable and entity.prefab ~= "reconstruction_project" then
            self.exteriors[interior_id] = nil
            self:OnRemoveExterior(entity)
        end
    end
    entity:ListenForEvent("onremove", entity.interiorspawner_exterior_on_remove_listener)
end

function InteriorSpawner:TransferExterior(from_entity, to_entity)
    if from_entity.interiorspawner_exterior_on_remove_listener then
        from_entity:RemoveEventCallback("onremove", from_entity.interiorspawner_exterior_on_remove_listener)
        from_entity.interiorspawner_exterior_on_remove_listener = nil
    end
    from_entity:RemoveTag("exterior_door")
    self.exteriors[from_entity.interiorID] = nil

    self:AddExterior(to_entity)
end

function InteriorSpawner:OnRemoveExterior(entity)
    if entity.interiorID == nil then
        print("WARNING: remove exterior without interiorID: "..tostring(entity))
        return
    end

    local room = self:GetInteriorCenter(entity.interiorID)
    if room then
        local allrooms = self:GatherAllRooms_Impl(room, {})
        for center in pairs(allrooms) do
            self:ClearInteriorContents(center:GetPosition(), entity:GetPosition())
            if center.interiorID then
                self.interior_defs[center.interiorID] = nil
            end
        end
    end
end

function InteriorSpawner:GetExteriorById(id)
    assert(TheWorld.ismastersim, "This method must be called in server")
    local exterior = self.exteriors[id]
    if exterior and not exterior:IsValid() then
        self.exteriors[id] = nil
        return
    end
    return exterior
end

local EAST  = { x =  1, y =  0, label = "east" }
local WEST  = { x = -1, y =  0, label = "west" }
local NORTH = { x =  0, y =  1, label = "north" }
local SOUTH = { x =  0, y = -1, label = "south" }

-- local op_dir_str =
-- {
--     ["north"] = "south",
--     ["east"]  = "west",
--     ["south"] = "north",
--     ["west"]  = "east",
-- }

local dir = { EAST, WEST, NORTH, SOUTH }
local dir_opposite = { WEST, EAST, SOUTH, NORTH }

function InteriorSpawner:GetNorth()
    return NORTH
end
function InteriorSpawner:GetSouth()
    return SOUTH
end
function InteriorSpawner:GetWest()
    return WEST
end
function InteriorSpawner:GetEast()
    return EAST
end

function InteriorSpawner:GetDir()
    return dir
end

function InteriorSpawner:GetDirOpposite()
    return dir_opposite
end

function InteriorSpawner:GetOppositeFromDirection(direction)
    if direction == NORTH then
        return self:GetSouth()
    elseif direction == EAST then
        return self:GetWest()
    elseif direction == SOUTH then
        return self:GetNorth()
    else
        return self:GetEast()
    end
end

function InteriorSpawner:AddDoor(door, def)
    self.doors[def.my_door_id] = {
        inst = door,
        my_interior_name = def.my_interior_name,
        target_interior = def.target_interior,
    }

    local door_component = door.components.door or door:AddComponent("door")

    door_component.door_id = def.my_door_id
    door_component.interior_name = def.my_interior_name
    door_component.target_door_id = def.target_door_id
    door_component.target_interior = def.target_interior
    door_component.target_exterior = def.target_exterior
    door_component.is_exit = def.is_exit
end

function InteriorSpawner:RemoveDoor(door_id)
    if not self.doors[door_id] then
        print("ERROR: TRYING TO REMOVE A NON EXISTING DOOR DEFINITION")
        return
    end

    self.doors[door_id] = nil
end

function InteriorSpawner:SpawnObject(interiorID, prefab, offset)
    local object = SpawnPrefab(prefab)
    if not object then
        print("Error: Failed to spawn " .. prefab)
        return
    end

    local spawn_point = self:IndexToPosition(interiorID)
    if offset then
        spawn_point = spawn_point + offset
    end
    object.Transform:SetPosition(spawn_point:Get())
    return object
end

function InteriorSpawner:AddInteriorCenter(center)
    self.interiors[center.interiorID] = center
end

function InteriorSpawner:RemoveInteriorCenter(center)
    self.interiors[center.interiorID] = nil
    self.interior_defs[center.interiorID] = nil
    self.reuse_interior_ids[center.interiorID] = true
end

local function CheckRoomSize(width, depth)
    assert(math.floor(width) == width, "Room width must be int")
    assert(math.floor(depth) == depth, "Room depth must be int")
    assert(width <= 64 and depth <= 64, "Room size must be smaller than 64")
    if width ~= TUNING.ROOM_TINY_WIDTH
        and width ~= TUNING.ROOM_SMALL_WIDTH
        and width ~= TUNING.ROOM_MEDIUM_WIDTH
        and width ~= TUNING.ROOM_LARGE_WIDTH then
        print("InteriorSpawner: warning: nonstandard room width")
    end
    if depth ~= TUNING.ROOM_TINY_DEPTH
        and depth ~= TUNING.ROOM_SMALL_DEPTH
        and depth ~= TUNING.ROOM_MEDIUM_DEPTH
        and depth ~= TUNING.ROOM_LARGE_DEPTH then
        print("InteriorSpawner: warning: nonstandard room depth")
    end
end

-- roomindex here is used as the interiorID on all the interiors in the room,
-- and also interior_name for the door component on prop_door prefab
function InteriorSpawner:CreateRoom(interior, width, height, depth, dungeon_name, roomindex, addprops, exits, walltexture, floortexture, minimaptexture, cityID, colour_cube, batted, playerroom, reverb, ambient_sound, footstep_tile, cameraoffset, zoom, forceInteriorMinimap)
    interior = interior or "generic_interior"
    width = width or 15
    depth = depth or 10
    CheckRoomSize(width, depth)
    assert(roomindex)
    colour_cube = colour_cube or "images/colour_cubes/day05_cc.tex"

    local interior_def =
    {
        unique_name = roomindex,
        dungeon_name = dungeon_name,
        width = width,
        height = height,
        depth = depth,
        prefabs = {},
        walltexture = walltexture,
        floortexture = floortexture,
        minimaptexture = minimaptexture,
        cityID = cityID,
        cc = colour_cube,
        visited = false,
        batted = batted,
        playerroom = playerroom,
        enigma = false,
        reverb = reverb, -- reverb preset for TheSim:SetReverbPreset
        ambient_sound = ambient_sound, -- The index of ambient sound defined in pl_ambientsound.lua, e.g. WORLD_TILES.DIRT
        footstep_tile = footstep_tile, -- The tile of the desired footstep sound, default to WORLD_TILES.DIRT in PlayFootstep function
        cameraoffset = cameraoffset,
        zoom = zoom,
        forceInteriorMinimap = forceInteriorMinimap
    }

    for _, prefab in ipairs(addprops) do
        if not prefab.chance or math.random() < prefab.chance then
            interior_def.prefabs[#interior_def.prefabs + 1] = prefab
        end
    end

    local prefab = {}

    for heading, exit in pairs(exits) do
        -- convert to number
        if type(exit.target_room) == "string" then
            print("WARNING: target_room is a string:", dungeon_name, exit.target_room)
            local index = assert(tonumber(select(3, exit.target_room:find("_(%d+)$"))), "Failed to convert to number: "..exit.target_room)
            exit.target_room = index
        end
        if not exit.house_door then
            if heading == NORTH then
                prefab = {
                    name = "prop_door",
                    x_offset = -depth/2,
                    z_offset = 0,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "north",
                        background = true
                    },
                    my_door_id = roomindex.."_NORTH",
                    target_door_id = exit.target_room.."_SOUTH",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 0,
                    addtags = {"lockable_door", "door_north"}
                }
            elseif heading == SOUTH then
                prefab = {
                    name = "prop_door",
                    x_offset = (depth/2),
                    z_offset = 0,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "south",
                        background = false
                    },
                    my_door_id = roomindex .. "_SOUTH",
                    target_door_id = exit.target_room .. "_NORTH",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 180,
                    addtags = {"lockable_door", "door_south"}
                }

                if not exit.secret then
                    table.insert(interior_def.prefabs, {
                        name = "prop_door_shadow",
                        x_offset = (depth / 2),
                        z_offset = 0,
                        animdata = {
                            bank = exit.bank,
                            build = exit.build,
                            anim = "south_floor",
                        },
                    })
                end
            elseif heading == EAST then
                prefab = {
                    name = "prop_door",
                    x_offset = 0,
                    z_offset = width / 2,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "east",
                        background = true,
                    },
                    my_door_id = roomindex .. "_EAST",
                    target_door_id = exit.target_room .. "_WEST",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 90,
                    addtags = {
                        "lockable_door",
                        "door_east",
                    },
                }
            elseif heading == WEST then
                prefab = {
                    name = "prop_door",
                    x_offset = 0,
                    z_offset = -width / 2,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "west",
                        background = true,
                    },
                    my_door_id = roomindex .. "_WEST",
                    target_door_id = exit.target_room .. "_EAST",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 270,
                    addtags = {
                        "lockable_door",
                        "door_west",
                    },
                }
            end
        else
            local doordata = player_interior_exit_dir_data[heading.label]
            prefab = {
                name = exit.prefab_name,
                x_offset = doordata.x_offset,
                z_offset = doordata.z_offset,
                sg_name = exit.sg_name,
                startstate = exit.startstate,
                animdata = {
                    minimapicon = exit.minimapicon,
                    bank = exit.bank,
                    build = exit.build,
                    anim = exit.prefab_name .. "_open_" .. doordata.anim,
                    background = doordata.background,
                },
                my_door_id = roomindex .. doordata.my_door_id_dir,
                target_door_id = exit.target_room .. doordata.target_door_id_dir,
                target_interior = exit.target_room,
                rotation = -90,
                hidden = false,
                angle = doordata.angle,
                addtags = {
                    "lockable_door",
                    doordata.door_tag,
                },
            }
        end

        if exit.vined then
            prefab.vined = true
        end

        if exit.secret then
            prefab.secret = true
            prefab.hidden = true
        end

        table.insert(interior_def.prefabs, prefab)
    end

    self:AddInterior(interior_def)

    return interior_def
end

function InteriorSpawner:AddInterior(def)
    assert(self.interior_defs[def.unique_name] == nil, "THIS ROOM ALREADY EXISTS: "..def.unique_name)

    def.object_list = {}
    self.interior_defs[def.unique_name] = def

    -- if TheWorld.components.worldmapiconproxy then
    --     -- TODO: impl minimap
    --     TheWorld.components.worldmapiconproxy:RegisterInterior(def.unique_name)
    -- end

    if def.batted and TheWorld.components.batted then
        TheWorld.components.batted:RegisterBatCave(def.unique_name) -- unique_name is interiorID
    end
end

-- TODO: Doesn't work right now, see if we need it
-- function InteriorSpawner:GetInteriorByName(name)
--     if name == nil then
--         return nil
--     else
--         local interior = self.interior_defs[name]
--         if interior == nil then
--             print("!!ERROR: Unable To Find Interior Named:"..name)
--         end

--         return interior
--     end
-- end

function InteriorSpawner:ClearInteriorContents(pos, exterior_pos)
    assert(TheWorld.ismastersim)

    TheWorld:PushEvent("pl_clearinterior", {pos = pos})

    local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS, {"player"})
    for _, v in ipairs(ents) do
        v:PushEvent("pl_clearfrominterior", {exterior_pos = exterior_pos})
        if exterior_pos ~= nil then
            v.Physics:Teleport(exterior_pos:Get())
            v:SnapCamera()
        else
            TheWorld.components.playerspawner:SpawnAtNextLocation(v)
            v:SnapCamera()
        end
    end

    local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS)
    if #ents > 0 then
        print("WARNING: Find "..#ents.." entities around pt "..tostring(pos)
            .." [INDEX="..self:PositionToIndex(pos).."]")
        for _, v in ipairs(ents) do
            v:PushEvent("pl_clearfrominterior", {exterior_pos = exterior_pos})
            if v:HasTag("irreplaceable") then
                if exterior_pos ~= nil then
                    v.Transform:SetPosition(exterior_pos:Get())
                else
                    SinkEntity(v)
                end
            elseif v.components.workable and v.components.workable:GetWorkAction() == ACTIONS.HAMMER then
                v.components.workable:Destroy(self.destroyer)
            elseif v.components.health and v.components.combat then
                if v:HasTag("epic") or v:HasTag("companion") then
                    if exterior_pos ~= nil then
                        v.Physics:Teleport(exterior_pos:Get())
                    else
                        SinkEntity(v)
                    end
                else
                    v.components.health:Kill()
                end
            elseif v:IsValid() then
                v:Remove()
            end
        end
    end

    local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS)
    for _, v in ipairs(ents) do
        if v.components.inventoryitem then
            v:Remove()
        elseif v:IsValid() then
            v:Remove()
        end
    end
end

function InteriorSpawner:SpawnInterior(interior)
    -- this function only gets run once per room when the room is first called.
    -- if the room has a "prefabs" attribute, it means the prefabs have not yet been spawned.
    -- if it does not have a prefab attribute, it means they have bene spawned and all the rooms
    -- contents will now be in object_list

    local pt = self:IndexToPosition(interior.unique_name)
    self:ClearInteriorContents(pt)

    -- print("InteriorSpawner:SpawnInterior", pt)

    local center = SpawnPrefab("interiorworkblank")
    center.Transform:SetPosition(pt:Get())
    center.interiorID = interior.unique_name
    center:SetUp(interior)

    for _, prefab in ipairs(interior.prefabs) do

        if --[[ GetWorld():IsWorldGenOptionNever(prefab.name)]] false then
            -- TODO: 实现这个特性
            -- 例如，关闭树枝时，遗迹内也不产生树枝
            print("CANCEL SPAWN ITEM DUE TO WORLD GEN PREFS", prefab.name)
        else
            local object = SpawnPrefab(prefab.name)

            -- TODO: remove this assertion in prod
            if object == nil then
                if prefab.name:find("pigman_") then
                    -- TODO: defined in global????
                else
                    print("Failed to spawn `"..tostring(prefab.name).."`")
                end
            else
                object.Transform:SetPosition(pt.x + prefab.x_offset, 0, pt.z + prefab.z_offset)

                -- flips the art of the item. This must be manually saved on items it it's to persist over a save
                if prefab.flip then
                    object.flipped = true
                end

                -- guess door direction
                if prefab.name == "prop_door" then
                    local dir = nil
                    local x, z = prefab.x_offset * 2, prefab.z_offset * 2
                    if x == 0 then
                        dir = z == -interior.width and "west"
                            or z == interior.width and "east"
                            or nil
                    elseif z == 0 then
                        dir = x == -interior.depth and "north"
                            or x == interior.depth and "south"
                            or nil
                    end
                    if dir ~= nil then
                        -- NOTE: this tag can be saved by door component
                        object:AddTag("door_"..dir)
                    else
                        print("WARNING: failed to guess door direction")
                        print("x:", prefab.x_offset, "z:", prefab.z_offset)
                    end
                end

                -- sets the initial roation of an object, NOTE: must be manually saved by the item to survive a save
                if prefab.rotation ~= nil then
                    object.Transform:SetRotation(prefab.rotation + (object.flipped and 180 or 0))
                elseif object.flipped then
                    object.Transform:SetRotation(90)
                end

                -- adds tags to the object
                if prefab.addtags then
                    for _, tag in ipairs(prefab.addtags) do
                        object:AddTag(tag)
                    end
                end

                if prefab.hidden then
                    object.components.door.hidden = true
                end
                if prefab.angle then
                    object.components.door.angle = prefab.angle
                end

                -- saves the roomID on the object
                if object.components.shopped then
                    object.interiorID = interior.unique_name
                end

                -- sets an anim to start playing
                if prefab.animation then
                    object.AnimState:PlayAnimation(prefab.animation)
                    object.animation = prefab.animation
                    if object.frontvisual then
                        object.frontvisual.AnimState:PlayAnimation(prefab.animation)
                    end
                    if object.clochevisual then
                        object.clochevisual.AnimState:PlayAnimation(prefab.animation)
                    end
                    if object.costvisual then
                        object.costvisual:UpdateVisual(prefab.animation)
                    end
                end

                if prefab.usesounds then
                    object.usesounds = prefab.usesounds
                end

                if prefab.saleitem then
                    object.saleitem = prefab.saleitem
                end

                if prefab.justsellonce then
                    object:AddTag("justsellonce")
                end

                if prefab.startstate then
                    object.startstate = prefab.startstate
                    if object.sg == nil then
                        object:SetStateGraph(prefab.sg_name)
                        object.sg_name = prefab.sg_name
                    end

                    object.sg:GoToState(prefab.startstate)

                    if prefab.startstate == "forcesleep" then
                        object.components.sleeper.hibernate = true
                        object.components.sleeper:GoToSleep()
                    end
                end

                if prefab.shelfitems then
                    for _, data in ipairs(prefab.shelfitems) do
                        object.components.container:GiveItem(SpawnPrefab(data[2]), data[1])
                    end
                end

                -- this door should have vines
                if prefab.vined and object.components.vineable then
                    object.components.vineable:SetUpVine()
                end


                -- this function processes the extra data that the prefab has attached to it for interior stuff.
                if object.initInteriorPrefab then
                    -- object.initInteriorPrefab(object, GetPlayer(), prefab, interior)
                    object.initInteriorPrefab(object, --[[GetPlayer()]]nil , prefab, interior)
                    -- TODO: check who call it?
                end

                -- should the door be closed for some reason?
                -- needs to happen after the object initinterior so the door info is there.
                if prefab.door_closed then
                    for cause, setting in pairs(prefab.door_closed) do
                        object.components.door:SetDoorDisabled(setting, cause)
                    end
                end

                if prefab.secret then
                    object:AddTag("secret")
                    object:RemoveTag("lockable_door")
                    object:Hide()

                    self.inst:DoTaskInTime(0, function()
                        local crack = SpawnPrefab("wallcrack_ruins")
                        crack:SetCrack(object)
                    end)
                end

                -- needs to happen after the door_closed stuff has happened.
                if object.components.vineable then
                    object.components.vineable:InitInteriorPrefab()
                end

                if interior.cityID then
                    if not object.components.citypossession then
                        object:AddComponent("citypossession")
                    end
                    object.components.citypossession:SetCity(interior.cityID)
                end

                if object.decochildrenToRemove then
                    for _, child in ipairs(object.decochildrenToRemove) do
                        child.Transform:SetPosition(object.Transform:GetWorldPosition())
                        child.Transform:SetRotation(object.Transform:GetRotation())
                    end
                end
            end
        end
    end

    interior.visited = true
end

function InteriorSpawner:GatherAllRooms_Impl(center, allrooms, usemap)
    -- WARNING: this method is quite expensive and server only
    if allrooms[center] then
        return
    end
    allrooms[center] = true
    local x, _, z = center.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})) do
        if v.prefab == "prop_door" then
            local target_interior = v.components.door.target_interior
            if target_interior ~= nil and target_interior ~= "EXTERIOR" then
                local room = self.interiors[target_interior] or self:GetInteriorCenter(target_interior)
                assert(room, "Room not exists: "..target_interior)
                self:GatherAllRooms_Impl(room, allrooms)
            end
        end
    end
    return allrooms
end

function InteriorSpawner:ForEachPlayerInRoom(interiorID, fn, ...)
    if not interiorID then
        return
    end

    local room = self:GetInteriorCenter(interiorID)
    if not room or not room:IsValid() then
        return
    end

    for _, player in pairs(AllPlayers) do
        local current_room = player:GetCurrentInteriorID()
        if current_room == interiorID then
            fn(player, ...)
        end
    end
end

function InteriorSpawner:IsAnyPlayerInRoom(interiorID)
    if not interiorID then
        return false
    end

    for _, player in pairs(AllPlayers) do
        if player:GetCurrentInteriorID() == interiorID then
            return true
        end
    end

    return false
end

return InteriorSpawner
