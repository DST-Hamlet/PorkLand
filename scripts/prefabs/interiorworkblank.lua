-- wall texture & floor texture & invisible physics walls of room
-- and also keep some usefull net vars

local function GetSkeletonPositions(w, h)
    return {
        LEFT_TOP     = Point(-h / 2, 0, -w / 2),
        RIGHT_TOP    = Point(-h / 2, 0,  w / 2),
        LEFT_BOTTOM  = Point( h / 2, 0, -w / 2),
        RIGHT_BOTTOM = Point( h / 2, 0,  w / 2),
        BOTTOM       = Point( h / 2, 0,      0),
        CENTER       = Point(     0, 0,      0),
    }
end

local function Clear(inst)
    for _, fx in pairs(inst.fx) do
        fx:Remove()
    end
    for _, boundary in ipairs(inst.boundaries) do
        boundary:Remove()
    end
    inst.fx = {}
    inst.boundaries = {}
end

local function OnRemove(inst)
    Clear(inst)
    TheWorld.components.interiorspawner:RemoveInteriorCenter(inst)
end

-- ROOM DIMENSIONS
--      +-------------+
--     /[height]      |\
--    / |_____________| \  _ _ _ ----> z-axis
--   /  /             \  \      \
--   | /       +       \ |       \ [depth]
--   |/_____[width]_____\|   _ _ _\ _ _
--   /
--  x-axis

local function SetUp(inst, data)
    Clear(inst)

    data = data or {}
    local width = data.width or inst._width:value()
    local depth = data.depth or inst._depth:value()
    inst:SetSize(width, depth)
    inst.height = data.height or inst.height
    inst.search_radius = inst:GetSearchRadius()

    if inst.components.interiorpathfinder then
        inst.components.interiorpathfinder:PopulateRoom()
    end

    if data.forceInteriorMinimap then
        inst:AddInteriorTags("FORCE_MINIMAP")
    end

    inst.walltexture = data.walltexture or inst.walltexture or "antcave_wall_rock"
    inst.floortexture = data.floortexture or inst.floortexture or "antcave_floor"
    inst.interiorID = data.interiorID or inst.interiorID
    inst.footstep_tile = data.footstep_tile or inst.footstep_tile or WORLD_TILES.DIRT
    inst._footstep_tile:set(inst.footstep_tile or WORLD_TILES.DIRT)
    inst.reverb = data.reverb or inst.reverb or "default"
    inst._reverb:set(inst.reverb or "default")
    inst.ambient_sound = data.ambient_sound or ""
    inst._ambient_sound:set(inst.ambient_sound or "")
    if inst.interiorID then
        TheWorld.components.interiorspawner:AddInteriorCenter(inst)
    end

    if data.minimaptexture then
        inst:SetFloorMinimapTex(data.minimaptexture or "mini_floor_wood.tex")
    else
        local interior_def = TheWorld.components.interiorspawner:GetInteriorDefine(inst.interiorID) -- 将旧存档中的floor_texture转移到实体上
        local floor_texture = interior_def and interior_def.minimaptexture or "mini_floor_wood.tex"
        inst:SetFloorMinimapTex(floor_texture)
    end

    local sp = GetSkeletonPositions(width, depth)
    local pos = inst:GetPosition()

    local left_top_pos = sp.LEFT_TOP + pos

    local floor = SpawnPrefab("interiorfloor")
    floor:SetSize(depth, width) -- depth => size_x, width => size_z
    floor:SetTexture(inst.floortexture)
    floor.Transform:SetPosition(left_top_pos:Get())

    local wall_bg = SpawnPrefab("interiorwall_z")
    wall_bg:SetSize(width)
    wall_bg.Transform:SetPosition(left_top_pos:Get())
    wall_bg:SetTexture(inst.walltexture)

    local wall_left = SpawnPrefab("interiorwall_x")
    wall_left:SetSize(depth)
    wall_left.Transform:SetPosition(left_top_pos:Get())
    wall_left:SetTexture(inst.walltexture)

    local right_top_pos = sp.RIGHT_TOP + pos

    local wall_right = SpawnPrefab("interiorwall_x")
    wall_right:SetSize(depth)
    wall_right.Transform:SetPosition(right_top_pos:Get())
    wall_right:SetTexture(inst.walltexture)

    -- for _, v in ipairs {floor, wall_bg, wall_left, wall_right} do -- 亚丹：SetParent 并且本地位置不为 000 的话，有时会出现网络传输的问题
    --     v.entity:SetParent(inst.entity)
    -- end

    inst.fx = {
        floor = floor,
        wall_bg = wall_bg,
        wall_left = wall_left,
        wall_right = wall_right,
    }

    local function wall(x, z)
        local wall = SpawnPrefab("invisiblewall")
        wall.persists = false
        wall.Physics:SetActive(true)
        wall.Physics:SetActive(false) -- use these wall for pathfinder only :p
        wall.Physics:Teleport(x + pos.x, 0, z + pos.z)
        -- wall:Debug()
        table.insert(inst.boundaries, wall)
    end

    local half_width = width / 2
    local half_depth = depth / 2
    for i = -half_width - 1, half_width + 1 do
        wall(half_depth, i)
        wall(-half_depth, i)
    end
    for i = -half_depth - 1, half_depth + 1 do
        wall(i, half_width)
        wall(i, -half_width)
    end

    -- real wall
    local wall = SpawnPrefab("invisiblewall_long")
    wall.width:set(width + 0.2)
    wall.depth:set(depth + 0.2)
    wall.Transform:SetPosition(pos.x, 0, pos.z)
    table.insert(inst.boundaries, wall)

    inst.interior_cc = data.interior_cc or data.cc or "images/colour_cubes/day05_cc.tex"
end

local function GetWidth(inst)
    return inst._width:value()
end

local function GetDepth(inst)
    return inst._depth:value()
end

local function GetSize(inst)
    return GetWidth(inst), GetDepth(inst)
end

local function SetSize(inst, width, depth)
    inst._width:set(width)
    inst._depth:set(depth)
end

local function SetFloorMinimapTex(inst, texture)
    inst._floor_minimaptex:set(texture)
end

local function GetFloorMinimapTex(inst)
    return inst._floor_minimaptex:value()
end

local function SetInteriorFloorTexture(inst, texture)
    inst.floortexture = texture
    local floor = inst.fx.floor
    if floor then
        floor:SetTexture(texture)
    end
end

local function SetInteriorWallsTexture(inst, texture)
    inst.walltexture = texture
    local wall_bg = inst.fx.wall_bg
    if wall_bg then
        wall_bg:SetTexture(texture)
    end
    local wall_left = inst.fx.wall_left
    if wall_left then
        wall_left:SetTexture(texture)
    end
    local wall_right = inst.fx.wall_right
    if wall_right then
        wall_right:SetTexture(texture)
    end
end

local function GetDoorById(inst, id)
    assert(TheWorld.ismastersim)
    local x, _, z = inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})) do
        if v.components.door.door_id == id then
            return v
        end
    end
end

local function GetDoorToExterior(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door", "door_exit"})) do
        return v
    end
end

local function OnDoorChange(inst, door, add)
    if add then
        table.insert(inst.doors, door)
    else
        table.removearrayvalue(inst.doors, door)
    end
    inst:SetIsSingleRoom(#inst.doors == 1 and inst.doors[1]:HasTag("door_exit"))
end

local function GetIsSingleRoom(inst)
    return inst._is_single_room:value()
end

local function SetIsSingleRoom(inst, is_single)
    return inst._is_single_room:set(is_single)
end

local function OnIsSingleRoomChange(inst)
    if TheWorld.ismastersim then
        local x, y, z = inst.Transform:GetWorldPosition()
        local players = FindPlayersInRange(x, y, z, TUNING.ROOM_FINDENTITIES_RADIUS)
        if #players ~= 0 then
            local minimap_data = inst:CollectMinimapData()
            for _, player in ipairs(players) do
                if player.components.interiorvisitor then
                    player.components.interiorvisitor:RecordMap(inst.interiorID, minimap_data)
                end
            end
        end
    end
    if ThePlayer and ThePlayer:IsNear(inst, TUNING.ROOM_FINDENTITIES_RADIUS) then
        ThePlayer:PushEvent("refresh_interior_minimap")
    end
end

local function HasInteriorMinimap(inst)
    return inst:HasInteriorTag("FORCE_MINIMAP")
        or not inst:GetIsSingleRoom()
end

local function GetSearchRadius(inst)
    if inst.search_radius == nil then
        local width, depth = inst:GetSize()
        inst.search_radius = math.sqrt(width*width, depth*depth) + 2
    end
    return inst.search_radius
end

local DIRECTION_NAMES = {
    "north",
    "east",
    "south",
    "west"
}

local function sort_priority(a, b)
    return a.priority < b.priority
end

local function CollectLocalDoorMinimap(inst, ignore_non_cacheable)
    local position = inst:GetPosition()
    local radius = inst:GetSearchRadius()
    local doors = {}
    for _, door in ipairs(TheSim:FindEntities(position.x, 0, position.z, radius, {"interior_door"})) do
        local door_direction
        for _, direction in ipairs(DIRECTION_NAMES) do
            if door:HasTag("door_"..direction) then
                door_direction = direction
                break
            end
        end
        if door_direction then
            doors[door_direction] = {
                hidden = door:HasTag("door_hidden"),
                disabled = door:HasTag("door_disabled"),
            }
        else
            print("This door doesn't have a direction!", door)
        end
    end
    return doors
end

local function CollectMinimapIcons(inst, ignore_non_cacheable)
    local position = inst:GetPosition()
    local width = inst:GetWidth()
    local depth = inst:GetDepth()
    local radius = inst:GetSearchRadius()

    local icons = {}
    for _, ent in ipairs(TheSim:FindEntities(position.x, 0, position.z, radius, nil, {"INLIMBO", "pl_interior_no_minimap"})) do
        -- prop_door sets the minimap entity after the creation,
        -- and will cause ghost icons if set on client, so use a netvar instead
        if ent.prefab == "prop_door" or ent.MiniMapEntity and (not ignore_non_cacheable or ent.MiniMapEntity:GetCanUseCache()) then  -- see postinit/minimapentity.lua
            local pos = ent:GetPosition()
            local offset = pos - position
            -- check if entity is in room
            if math.abs(offset.z) < width / 2 + 1 and math.abs(offset.x) < depth / 2 + 1 then
                local icon = ent.prefab == "prop_door" and ent:GetMinimapIcon() or ent.MiniMapEntity:GetIcon() -- see postinit/minimapentity.lua
                local priority = ent.prefab == "prop_door" and 0 or ent.MiniMapEntity:GetPriority() -- see postinit/minimapentity.lua
                if icon ~= nil and icon ~= "" then
                    local id = ent.Network:GetNetworkID()
                    icons[id] = {
                        icon = icon,
                        offset_x = offset.x,
                        offset_z = offset.z,
                        priority = priority or 0,
                    }
                end
            end
        end
    end
    return icons
end

-- levels/textures/map_interior/mini_ruins_slab.tex -> mini_ruins_slab
local function basename(path)
    return string.match(path, "([^/]+)%.%w+$")
end

local function CollectMinimapData(inst, ignore_non_cacheable)
    if not inst:HasInteriorMinimap() then
        return
    end

    local position = inst:GetPosition()
    local width = inst:GetWidth()
    local depth = inst:GetDepth()
    local radius = inst:GetSearchRadius()

    local icons = CollectMinimapIcons(inst, ignore_non_cacheable)

    local doors = {}
    for _, door in ipairs(TheSim:FindEntities(position.x, 0, position.z, radius, {"interior_door"})) do
        local target_interior = door.components.door.target_interior
        if target_interior ~= "EXTERIOR" then
            local door_direction
            for _, direction in ipairs(DIRECTION_NAMES) do
                if door:HasTag("door_"..direction) then
                    door_direction = direction
                    break
                end
            end
            if door_direction then
                table.insert(doors, {
                    target_interior = target_interior,
                    direction = door_direction,
                    hidden = door:HasTag("door_hidden"),
                    disabled = door:HasTag("door_disabled"),
                    -- unknown = nil,
                })
            else
                print("This door doesn't have a direction!", door)
            end
        end
    end

    local minimap_floor_texture = inst:GetFloorMinimapTex()

    return {
        uuid = inst.uuid,
        width = width,
        depth = depth,
        minimap_floor_texture = basename(minimap_floor_texture),
        icons = icons,
        doors = doors,
    }
    -- {
    --     uuid: string,
    --     width: number,
    --     depth: number,
    --     minimap_floor_texture: string,
    --     icons: { [id: number]: { icon: string, offset_x: number, offset_z: number, priority: number } }
    --     doors: {
    --         target_interior: interiorID,
    --         direction: keyof DIRECTION_NAMES }[],
    --         hidden: boolean,
    --         disabled: boolean,
    --         unknown?: boolean,
    --     }
    -- }
end

local TAGS = {
    FORCE_MINIMAP = 1, -- always render minimap even if the room is single
    FORCE_VISITED = 2, -- show minimap of the room before visiting
    NO_LIGHT = 4, -- should trigger grue if no light in room
    HOME_PROTOTYPER = 8, -- player home prototype room
    PIG_RUINS = 16, -- pig ruins rooms
    PIG_SHOP = 32, -- pig shop rooms
    ANTQUEEN = 64, -- final chamber
    TEST = 1024,
}

local TAGS_VALUE_DESCENDING = {}
for k, v in pairs(TAGS) do
    table.insert(TAGS_VALUE_DESCENDING, {name = k, value = v})
end
table.sort(TAGS_VALUE_DESCENDING, function(a, b) return a.value > b.value end)

local function OnTagsMaskChange(inst)
    local mask = inst.interior_tags_mask:value()
    local tags = {}
    for _, v in ipairs(TAGS_VALUE_DESCENDING) do
        if mask >= v.value then
            mask = mask % v.value
            tags[v.name] = true
        end
    end
    inst.interior_tags = tags
end

local function OnSizeChange(inst)
    if inst.components.interiorpathfinder then
        inst.components.interiorpathfinder:PopulateRoom()
    end
end

local function OnTagsChange(inst)
    local sum = 0
    for k in pairs(inst.interior_tags) do
        sum = sum + TAGS[k]
    end
    inst.interior_tags_mask:set(sum)
end

local function AddInteriorTags(inst, ...)
    for _, tag in ipairs({...}) do
        tag = string.upper(tag)
        if not TAGS[tag] then
            print("WARNING: Invalid interior tag: "..tag)
        else
            inst.interior_tags[tag] = true
        end
    end
    OnTagsChange(inst)
end

local function RemoveInteriorTags(inst, ...)
    for _, v in ipairs({...}) do
        v = string.upper(v)
        inst.interior_tags[v] = nil
    end
    OnTagsChange(inst)
end

local function HasInteriorTag(inst, name)
    return inst.interior_tags[string.upper(name)] == true
end

local function AttachMinimapOverride(inst)
    local icon = SpawnPrefab("globalmapicon")
    icon:TrackEntity(inst, nil, "pl_frame_black.tex")
    icon.MiniMapEntity:SetPriority(100)
end

local function OnSave(inst, data)
    data.uuid = inst.uuid
    data.width = inst:GetWidth()
    data.depth = inst:GetDepth()
    data.height = inst.height
    data.walltexture = inst.walltexture
    data.floortexture = inst.floortexture
    data.interiorID = inst.interiorID
    data.interior_tags = inst.interior_tags
    data.interior_cc = inst.interior_cc
    data.cc = inst.interior_cc
    data.footstep_tile = inst.footstep_tile
    data.reverb = inst.reverb
    data.ambient_sound = inst.ambient_sound
    data.minimaptexture = inst:GetFloorMinimapTex()

    local doors = {}
    for _, door in ipairs(inst.doors) do
       table.insert(doors, door.GUID)
    end
    data.doors = doors

    return doors
end

local function OnLoad(inst, data)
    if data.uuid then
        inst.uuid = data.uuid
    end
    inst:SetUp(data)
    if data.interior_tags then
        inst:AddInteriorTags(unpack(table.getkeys(data.interior_tags)))
    end
end

local function MigrateDoors(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.doors = TheSim:FindEntities(x, y, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"}, {"predoor"})
    inst:SetIsSingleRoom(#inst.doors == 1 and inst.doors[1]:HasTag("door_exit"))
end

local function OnLoadPostPass(inst, newents, savedata)
    if savedata and savedata.doors then
        inst.doors = {}
        for _, door_guid in ipairs(savedata.doors) do
            local door = newents[door_guid]
            if door then
                inst:OnDoorChange(door.entity, true)
            end
        end
    else
        inst:DoStaticTaskInTime(0, MigrateDoors)
    end
end

local function generate_uuid(length)
    local chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local uuid = {}
    local random = math.random

    for i = 1, length do
        local rand_index = random(1, #chars)
        table.insert(uuid, chars:sub(rand_index, rand_index))
    end

    return table.concat(uuid)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    -- map:SetIcon("pl_black_bg.tex") -- TODO: use smaller one
    inst.MiniMapEntity:SetPriority(100)

    inst:AddTag("pl_interiorcenter")
    inst:AddTag("pl_interior_no_minimap")
    inst:AddTag("NOBLOCK")

    inst.fx = {}
    inst.boundaries = {}

    inst._width = net_byte(inst.GUID, "interiorworkblank.width", "sizedirty")
    inst._width:set_local(TUNING.ROOM_TINY_WIDTH)
    inst._depth = net_byte(inst.GUID, "interiorworkblank.depth", "sizedirty")
    inst._depth:set_local(TUNING.ROOM_TINY_DEPTH)
    inst.height = 5

    inst.GetWidth = GetWidth
    inst.GetDepth = GetDepth
    inst.GetSize = GetSize
    inst.SetSize = SetSize

    inst._reverb = net_string(inst.GUID, "_reverb")
    inst._footstep_tile = net_int(inst.GUID, "_footstep_tile")
    inst._ambient_sound = net_string(inst.GUID, "_ambient_sound")

    inst.cc_index = net_byte(inst.GUID, "cc_index", "cc_index")
    inst.interior_tags = {}
    inst.interior_tags_mask = net_ushortint(inst.GUID, "interior_tags_mask", "interior_tags_mask")

    inst.major_id = net_ushortint(inst.GUID, "major_id", "major_id")
    inst.minimap_coord_x = net_shortint(inst.GUID, "minimap_coord_x", "minimap_coord")
    inst.minimap_coord_z = net_shortint(inst.GUID, "minimap_coord_z", "minimap_coord")
    inst._floor_minimaptex = net_string(inst.GUID, "_floor_minimaptex", "_floor_minimaptex")

    inst.GetFloorMinimapTex = GetFloorMinimapTex

    inst._is_single_room = net_bool(inst.GUID, "interiorworkblank._is_single_room", "is_single_room_change")
    inst:ListenForEvent("is_single_room_change", OnIsSingleRoomChange)

    inst._isquaking = net_bool(inst.GUID, "interiorworkblank._isquaking")

    inst.GetSearchRadius = GetSearchRadius
    inst.GetDoorById = GetDoorById
    inst.GetDoorToExterior = GetDoorToExterior
    inst.GetIsSingleRoom = GetIsSingleRoom
    inst.HasInteriorMinimap = HasInteriorMinimap
    inst.CollectMinimapIcons = CollectMinimapIcons
    inst.CollectLocalDoorMinimap = CollectLocalDoorMinimap
    inst.HasInteriorTag = HasInteriorTag

    inst:AddComponent("interiorpathfinder")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("interior_tags_mask", OnTagsMaskChange)
        inst:ListenForEvent("sizedirty", OnSizeChange)
        return inst
    end

    -- Used for minimap data
    inst.uuid = generate_uuid(8)

    inst.SetUp = SetUp
    inst.CollectMinimapData = CollectMinimapData

    inst.walltexture = nil
    inst.floortexture = nil

    inst.SetFloorMinimapTex = SetFloorMinimapTex

    inst.SetInteriorFloorTexture = SetInteriorFloorTexture
    inst.SetInteriorWallsTexture = SetInteriorWallsTexture

    inst.doors = {}
    inst.OnDoorChange = OnDoorChange
    inst.SetIsSingleRoom = SetIsSingleRoom

    inst:ListenForEvent("onremove", OnRemove)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.AddInteriorTags = AddInteriorTags
    inst.RemoveInteriorTags = RemoveInteriorTags

    inst:DoTaskInTime(0, AttachMinimapOverride)

    return inst
end

return Prefab("interiorworkblank", fn)
