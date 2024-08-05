-- wall texture & floor texture & invisible physics walls of room
-- and also keep some usefull net vars

local function GetSkeletonPositions(w, h)
    return {
        LEFT_TOP     = Point(-h/2, 0, -w/2),
        RIGHT_TOP    = Point(-h/2, 0,  w/2),
        LEFT_BOTTOM  = Point(h/2, 0, -w/2),
        RIGHT_BOTTOM = Point(h/2, 0,  w/2),
        BOTTOM       = Point(h/2, 0, 0),
        CENTER       = Point(0, 0, 0),
    }
end

local function Clear(inst)
    for _, fx in ipairs(inst.fx) do
        fx:Remove()
    end
    inst.fx = {}
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

    local sp = GetSkeletonPositions(inst.width, inst.depth)

    local left_top_pos = sp.LEFT_TOP + inst:GetPosition()

    local floor = SpawnPrefab("interiorfloor")
    floor:SetSize(inst.depth, inst.width) -- depth => size_x, width => size_z
    floor:SetTexture(inst.floortexture)
    floor.Transform:SetPosition(left_top_pos:Get())

    local wall_bg = SpawnPrefab("interiorwall_z")
    wall_bg:SetSize(inst.width)
    wall_bg.Transform:SetPosition(left_top_pos:Get())

    local wall_left = SpawnPrefab("interiorwall_x")
    wall_left:SetSize(inst.depth)
    wall_left.Transform:SetPosition(left_top_pos:Get())

    local right_top_pos = sp.RIGHT_TOP + inst:GetPosition()

    local wall_right = SpawnPrefab("interiorwall_x")
    wall_right:SetSize(inst.depth)
    wall_right.Transform:SetPosition(right_top_pos:Get())

    for _, v in ipairs {wall_bg, wall_left, wall_right} do
        v:SetTexture(inst.walltexture)
    end

    --for _, v in ipairs{floor, wall_bg, wall_left, wall_right}do -- 亚丹：SetParent并且本地位置不为000的话，有时会出现网络传输的问题
        --v.entity:SetParent(inst.entity)
    --end

    inst.fx = {
        floor,
        wall_bg,
        wall_left,
        wall_right,
    }

    local function wall(x, z)
        local wall = SpawnPrefab("invisiblewall")
        table.insert(inst.fx, wall)
        wall:DoTaskInTime(0, function()
            local pos = inst:GetPosition()
            wall.Physics:SetActive(true)
            wall.Physics:SetActive(false) -- use these wall for pathfinder only :p
            wall.Physics:Teleport(x + pos.x, 0, z + pos.z)
        end)
        wall.persists = false
        -- v:Debug()
    end

    for i = -inst.width/2 - 1, inst.width/2 + 1 do
        wall(inst.depth/2, i)
        wall(-inst.depth/2, i)
    end
    for i = -inst.depth/2 - 1, inst.depth/2 + 1 do
        wall(i, inst.width/2)
        wall(i, -inst.width/2)
    end

    -- real wall
    local wall = SpawnPrefab("invisiblewall_long")
    wall:DoTaskInTime(0, function()
        local pos = inst:GetPosition()
        wall.width:set(inst.width + 0.2)
        wall.depth:set(inst.depth + 0.2)
        wall.Transform:SetPosition(pos.x, 0, pos.z)
    end)
    table.insert(inst.fx, wall)

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

local function GetIsSingleRoom(inst, no_cache)
    if inst.cached_is_single ~= nil and no_cache ~= true then
        return unpack(inst.cached_is_single)
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})
    if #ents == 1 and ents[1]:HasTag("door_exit") then
        inst.cached_is_single = {true, ents[1]}
        return true, ents[1]
    end
    inst.cached_is_single = {false}
    return false
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

local function CollectMinimapData(inst)
    local center = inst:GetPosition()
    if not inst:HasInteriorMinimap() then
        return { center = center, no_minimap = true }
    end
    local radius = inst:GetSearchRadius()
    local result = {
        center = center,
        width = inst.width,
        depth = inst.depth,
        net_id = inst.Network:GetNetworkID(),
        interiorID = inst.interiorID,
        guid = inst.entity:GetGUID(),
        ents = {}
    }
    inst.net_id = result.net_id
    local ents = result.ents
    for _, v in ipairs(TheSim:FindEntities(center.x, 0, center.z, radius, nil, {"INLIMBO", "pl_mapicon", "pl_interior_no_minimap"})) do
        if v.MiniMapEntity ~= nil then
            local pos = v:GetPosition()
            local offset = pos - center
            -- check if entity is in room
            if math.abs(offset.z) < inst.width / 2 + 1 and math.abs(offset.x) < inst.depth / 2 + 1 then
                local icon = v.MiniMapEntity:GetIcon() -- see interior_map.lua
                local priority = v.MiniMapEntity:GetPriority() -- see interior_map.lua
                if icon ~= nil and icon ~= "" then
                    local list = ents[icon] or {}
                    table.insert(list, {offset.x, offset.z, priority or 0})
                    ents[icon] = list
                end
            end
        end
    end
    return result
    -- {
    --     center: Point,
    --     net_id: number,
    --     guid: number,
    --     width: number, depth: number,
    --     ents: {[icon: string]: Array<[x: number, z: number]>}
    -- }
end

local TAGS = {
    FORCE_MINIMAP = 1, -- always render minimap even if the room is single
    FORCE_VISITED = 2, -- show minimap of the room before visiting
    NO_LIGHT = 4, -- should trigger grue if no light in room
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
    for _, v in ipairs({...}) do
        v = string.upper(v)
        if not TAGS[v] then
            print("WARNING: Invalid interior tag: "..v)
        else
            inst.interior_tags[v] = true
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
    data.width = inst:GetWidth()
    data.depth = inst:GetDepth()
    data.height = inst.height
    data.walltexture = inst.walltexture
    data.floortexture = inst.floortexture
    data.interiorID = inst.interiorID
    data.interior_tags = inst.interior_tags
    data.uuid = inst.uuid
    data.interior_cc = inst.interior_cc
    data.cc = inst.interior_cc
end

local function OnLoad(inst, data)
    inst:SetUp(data)
    if data.uuid then
        inst.uuid = data.uuid
    end
    if data.interior_tags then
        inst:AddInteriorTags(unpack(table.getkeys(data.interior_tags)))
    end
end

local function UpdateState(inst)
    if ThePlayer and ThePlayer:IsNear(inst, 64) then
        for _, fx in ipairs(inst.fx) do
            if fx.OnThePlayerNear then
                fx:OnThePlayerNear()
            end
        end
    else
        for _, fx in ipairs(inst.fx) do
            if fx.OnThePlayerFar then
                fx:OnThePlayerFar()
            end
        end
    end
end

local function StartUpdateState(inst)
    if inst.updatefxtask == nil then
        inst.updatefxtask = inst:DoPeriodicTask(FRAMES, UpdateState)
    end
end

local function StopUpdateState(inst)
    UpdateState(inst)
    if inst.updatefxtask then
        inst.updatefxtask:Cancel()
        inst.updatefxtask = nil
    end
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

    inst._width = net_byte(inst.GUID, "interiorworkblank.width", "sizedirty")
    inst._width:set_local(TUNING.ROOM_TINY_WIDTH)
    inst._depth = net_byte(inst.GUID, "interiorworkblank.depth", "sizedirty")
    inst._depth:set_local(TUNING.ROOM_TINY_DEPTH)
    inst.height = 5

    inst.GetWidth = GetWidth
    inst.GetDepth = GetDepth
    inst.GetSize = GetSize
    inst.SetSize = SetSize

    inst.cc_index = net_byte(inst.GUID, "cc_index", "cc_index")
    inst.interior_tags = {}
    inst.interior_tags_mask = net_ushortint(inst.GUID, "interior_tags_mask", "interior_tags_mask")

    inst.major_id = net_ushortint(inst.GUID, "major_id", "major_id")
    inst.minimap_coord_x = net_shortint(inst.GUID, "minimap_coord_x", "minimap_coord")
    inst.minimap_coord_z = net_shortint(inst.GUID, "minimap_coord_z", "minimap_coord")

    inst.GetSearchRadius = GetSearchRadius
    inst.GetDoorById = GetDoorById
    inst.GetDoorToExterior = GetDoorToExterior
    inst.GetIsSingleRoom = GetIsSingleRoom
    inst.HasInteriorMinimap = HasInteriorMinimap
    inst.HasInteriorTag = HasInteriorTag

    TheWorld.components.worldmapiconproxy:AddInteriorCenter(inst)

    inst:AddComponent("interiorpathfinder")

    if not TheNet:IsDedicated() then
        inst.OnEntitySleep = StopUpdateState
        inst.OnEntityWake = StartUpdateState
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("interior_tags_mask", OnTagsMaskChange)
        inst:ListenForEvent("sizedirty", OnSizeChange)
        return inst
    end

    inst.SetUp = SetUp
    inst.CollectMinimapData = CollectMinimapData

    inst.walltexture = nil
    inst.floortexture = nil

    inst:ListenForEvent("onremove", Clear)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.AddInteriorTags = AddInteriorTags
    inst.RemoveInteriorTags = RemoveInteriorTags

    inst:DoTaskInTime(0, AttachMinimapOverride)

    return inst
end

return Prefab("interiorworkblank", fn)
