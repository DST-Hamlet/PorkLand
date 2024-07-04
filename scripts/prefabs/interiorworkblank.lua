-- wall texture & floor texture & invisible physics walls of room
-- and also keep some usefull net vars

local function GetSkeletonPositions(w, h)
    return {
        LEFT_TOP     = Point(-h/2, 0, -w/2),
        RIGHT_TOP     = Point(-h/2, 0,  w/2),
        LEFT_BOTTOM  = Point(h/2, 0, -w/2),
        RIGHT_BOTTOM = Point(h/2, 0,  w/2),
        BOTTOM         = Point(h/2, 0, 0),
        CENTER         = Point(0, 0, 0),
    }
end

local function Clear(inst)
    for k in pairs(inst.fx)do
        k:Remove()
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
    inst.width = data.width or inst.width
    inst.height = data.height or inst.height
    inst.depth = data.depth or inst.depth
    inst.size_net:set(inst.width, inst.depth)
    inst.search_radius = inst:GetSearchRadius()

    if data.forceInteriorMinimap then
        inst:AddInteriorTags("FORCE_MINIMAP")
    end

    inst.walltexture = data.walltexture or inst.walltexture or "antcave_wall_rock"
    inst.floortexture = data.floortexture or inst.floortexture or "antcave_floor"
    inst.interiorID = data.interiorID or inst.interiorID

    local pos = inst:GetPosition()
    local sp = GetSkeletonPositions(inst.width, inst.depth)

    local floor = SpawnPrefab("interiorfloor")
    floor:SetSize(inst.depth, inst.width) -- depth => size_x, width => size_z
    floor:SetTexture(inst.floortexture)
    floor.Transform:SetPosition(sp.LEFT_TOP:Get())

    local wall_bg = SpawnPrefab("interiorwall_z")
    wall_bg:SetSize(inst.width)
    wall_bg.Transform:SetPosition(sp.LEFT_TOP:Get())

    local wall_left = SpawnPrefab("interiorwall_x")
    wall_left:SetSize(inst.depth)
    wall_left.Transform:SetPosition(sp.LEFT_TOP:Get())

    local wall_right = SpawnPrefab("interiorwall_x")
    wall_right:SetSize(inst.depth)
    wall_right.Transform:SetPosition(sp.RIGHT_TOP:Get())

    for _,v in ipairs{wall_bg, wall_left, wall_right}do
        v:SetTexture(inst.walltexture)
    end

    for _,v in ipairs{floor, wall_bg, wall_left, wall_right}do
        v.entity:SetParent(inst.entity)
    end

    inst.fx = {
        [floor] = true,
        [wall_bg] = true,
        [wall_left] = true,
        [wall_right] = true,
    }

    local temp = {}
    local function wall(x, z)
        local v = SpawnPrefab("invisiblewall")
        table.insert(temp, v)
        v:DoTaskInTime(0, function()
            local pos = inst:GetPosition()
            v.Physics:SetActive(true)
            v.Physics:SetActive(false) -- use these wall for pathfinder only :p
            v.Physics:Teleport(x + pos.x, 0, z + pos.z)
        end)
        v.persists = false
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

    for _,v in ipairs(temp)do
        inst.fx[v] = true
    end

    -- real wall
    local wall = SpawnPrefab("invisiblewall_long")
    wall:DoTaskInTime(0, function()
        local pos = inst:GetPosition()
        wall.width:set(inst.width + 0.2)
        wall.depth:set(inst.depth + 0.2)
        wall.Transform:SetPosition(pos.x, 0, pos.z)
    end)
    inst.fx[wall] = true

    inst.interior_cc = data.interior_cc or data.cc or "images/colour_cubes/day05_cc.tex"
end

local function GetSize(inst)
    return inst.size_net:value()
end

local function GetDoorById(inst, id)
    assert(TheWorld.ismastersim)
    local x,_,z = inst:GetPosition():Get()
    for _,v in ipairs(TheSim:FindEntities(x,0,z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"}))do
        if v.components.door.door_id == id then
            return v
        end
    end
end

local function GetDoorToExterior(inst)
    local x,_,z = inst:GetPosition():Get()
    for _,v in ipairs(TheSim:FindEntities(x,0,z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door", "door_exit"}))do
        return v
    end
end

local function GetIsSingleRoom(inst, no_cache)
    if inst.cached_is_single ~= nil and no_cache ~= true then
        return unpack(inst.cached_is_single)
    end
    local x,_,z = inst:GetPosition():Get()
    local ents = TheSim:FindEntities(x,0,z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})
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
    for _,v in ipairs(TheSim:FindEntities(center.x, 0, center.z, radius, nil, {"INLIMBO", "pl_mapicon", "pl_interior_no_minimap"}))do
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
for k,v in pairs(TAGS)do
    table.insert(TAGS_VALUE_DESCENDING, {name = k, value = v})
end
table.sort(TAGS_VALUE_DESCENDING, function(a, b) return a.value > b.value end)

local function OnTagsMaskChange(inst)
    local mask = inst.interior_tags_mask:value()
    local tags = {}
    for _,v in ipairs(TAGS_VALUE_DESCENDING)do
        if mask >= v.value then
            mask = mask % v.value
            tags[v.name] = true
        end
    end
    inst.interior_tags = tags
end

local function OnTagsChange(inst)
    local sum = 0
    for k in pairs(inst.interior_tags)do
        sum = sum + TAGS[k]
    end
    inst.interior_tags_mask:set(sum)
end

local function AddInteriorTags(inst, ...)
    for _,v in ipairs({...})do
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
    for _,v in ipairs({...})do
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
    data.width = inst.width
    data.height = inst.height
    data.depth = inst.depth
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

    inst.cc_index = net_byte(inst.GUID, "cc_index", "cc_index")
    inst.size_net = {
        width = net_byte(inst.GUID, "size.width"),
        depth = net_byte(inst.GUID, "size.depth"),
        set = function(self, w, d)
            self.width:set(w)
            self.depth:set(d)
        end,
        value = function(self)
            return self.width:value(), self.depth:value()
        end,
    }
    inst.interior_tags = {}
    inst.interior_tags_mask = net_ushortint(inst.GUID, "interior_tags_mask", "interior_tags_mask")

    inst.major_id = net_ushortint(inst.GUID, "major_id", "major_id")
    inst.minimap_coord_x = net_shortint(inst.GUID, "minimap_coord_x", "minimap_coord")
    inst.minimap_coord_z = net_shortint(inst.GUID, "minimap_coord_z", "minimap_coord")

    inst.GetSize = GetSize
    inst.GetDoorById = GetDoorById
    inst.GetDoorToExterior = GetDoorToExterior
    inst.GetIsSingleRoom = GetIsSingleRoom
    inst.HasInteriorMinimap = HasInteriorMinimap
    inst.HasInteriorTag = HasInteriorTag

    TheWorld.components.interiorspawner:AddInteriorCenter(inst)
    TheWorld.components.worldmapiconproxy:AddInteriorCenter(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("interior_tags_mask", OnTagsMaskChange)
        return inst
    end

    inst.width = TUNING.ROOM_TINY_WIDTH
    inst.height = 5
    inst.depth = TUNING.ROOM_TINY_DEPTH
    inst.SetUp = SetUp
    inst.GetSearchRadius = GetSearchRadius
    inst.CollectMinimapData = CollectMinimapData

    inst.walltexture = nil
    inst.floortexture = nil

    inst.fx = {}

    inst:ListenForEvent("onremove", Clear)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.AddInteriorTags = AddInteriorTags
    inst.RemoveInteriorTags = RemoveInteriorTags

    inst:DoTaskInTime(0, AttachMinimapOverride)

    return inst
end

return Prefab("interiorworkblank", fn)
