GLOBAL.setfenv(1, GLOBAL)

local obj_layout = require("map/object_layout")
local AllLayouts = require("map/layouts").Layouts

local function GetLayoutRadius(layout, prefabs)
    assert(layout ~= nil)
    assert(prefabs ~= nil)

    local extents = {xmin = 1000000, ymin = 1000000, xmax = -1000000, ymax = -1000000}
    for i = 1, #prefabs do
        -- print(string.format("Prefab %s (%4.2f, %4.2f)", tostring(prefabs[i].prefab), prefabs[i].x, prefabs[i].y))
        if prefabs[i].x < extents.xmin then extents.xmin = prefabs[i].x end
        if prefabs[i].x > extents.xmax then extents.xmax = prefabs[i].x end
        if prefabs[i].y < extents.ymin then extents.ymin = prefabs[i].y end
        if prefabs[i].y > extents.ymax then extents.ymax = prefabs[i].y end
    end

    local e_width, e_height = extents.xmax - extents.xmin, extents.ymax - extents.ymin
    local size = math.ceil(layout.scale * math.max(e_width, e_height))

    if layout.ground then
        size = math.max(size, #layout.ground)
    end

    -- print(string.format("Layout %s dims (%4.2f x %4.2f), size %4.2f", layout.name, e_width, e_height, size))
    return size
end

local function CheckTile(x, y, checkFn)
    return not WorldSim:IsTileReserved(x, y) and (checkFn == nil or checkFn(WorldSim:GetTile(x, y), x, y))
end

local function CheckAllTiles(checkFn, x1, y1, x2, y2)
    for j = y1, y2 do
        for i = x1, x2 do
            -- if not checkFn(WorldSim:GetTile(i, j), i, j) then
            if not CheckTile(i, j, checkFn) then
                return false, i, j
            end
        end
    end
    return true, 0, 0
end

local function FindLayoutPositions(radius, edge_dist, checkFn, count)
    local positions = {}
    local size = 2 * radius
    edge_dist = edge_dist or 0

    local width, height = WorldSim:GetWorldSize()
    local adj_width, adj_height = width - 2 * edge_dist - size, height - 2 * edge_dist - size
    local start_x, start_y = math.random(0, adj_width), math.random(0, adj_height)
    local i, j = 0, 0
    while j < adj_height and (count == nil or #positions < count) do
        local y = ((start_y + j) % adj_height) + edge_dist
        while i < adj_width and (count == nil or #positions < count) do
            -- check the corners first
            local x = ((start_x + i) % adj_width) + edge_dist
            local x2, y2 = x + size - 1, y + size - 1
            if CheckTile(x2, y, checkFn) and CheckTile(x2, y2, checkFn) then
                -- if checkFn(WorldSim:GetTile(x2, y), x2, y) and checkFn(WorldSim:GetTile(x2, y2), x2, y2) then
                if CheckTile(x, y, checkFn) and CheckTile(x, y2, checkFn) then
                    -- if checkFn(WorldSim:GetTile(x, y), x, y) and checkFn(WorldSim:GetTile(x, y2), x, y2) then
                    -- print("Found 4 corners", x, y, x2, y2)

                    -- check all tiles
                    local ok, last_x, last_y = CheckAllTiles(checkFn, x, y, x2, y2)
                    if ok == true then
                        -- fillAllTiles(checkFn, x, y, x2, y2)
                        -- bottom-left
                        -- print(string.format("Location found (%4.2f, %4.2f)", x, y))
                        -- local adj = 0.5 * (size - actualsize)
                        -- return {x + adj, y2 - adj} --{0.5 * (x + x2), 0.5 * (y + y2)}
                        -- table.insert(positions, {x = x + adj, y = y2 - adj})
                        table.insert(positions, {
                            x = x,
                            y = y,
                            x2 = x2,
                            y2 = y2,
                            size = size
                        })
                        i = i + size + 1
                    else
                        -- print(string.format("Failed at (%4.2f, %4.2f) skip, (%4.2f, %4.2f)", last_x, last_y, x, y))
                        i = i + last_x - x + 1
                    end
                else
                    i = i + 1
                end
            else
                -- print(string.format("Failed on x2, skip (%4.2f, %4.2f)", x, y))
                i = i + size + 1
            end
        end
        j = j + 1
        i = 0
    end

    return positions
end

function obj_layout.PlaceWaterLayout(layout, prefabs, add_entity, checkFn, radius)
    local layoutsize = GetLayoutRadius(layout, prefabs)
    local r = math.max(layoutsize, radius or 0)
    local positions = FindLayoutPositions(r, TUNING.MAPWRAPPER_WARN_RANGE + 8, checkFn, 1)
    if positions and #positions > 0 then
        local pos = math.random(1, #positions)
        local adj = 0.5 * (positions[pos].size - layoutsize)
        local x, y = positions[pos].x + adj, positions[pos].y + adj -- bottom-left
        -- print(string.format("PlaceWaterLayout (%f, %f) from %d of %d", x, y, pos, #positions))
        obj_layout.ReserveAndPlaceLayout("POSITIONED", layout, prefabs, add_entity, {x, y})

        for yy = positions[pos].y, positions[pos].y2, 1 do
            for xx = positions[pos].x, positions[pos].x2, 1 do
                WorldSim:ReserveTile(xx, yy)
            end
        end
    end
end

function obj_layout.AddLayoutToSanbox(sanboxfile, area, name)
    local choices = require(sanboxfile)
    local Sandbox = choices.Sandbox
    local Layouts = choices.Layouts
    local Layout = obj_layout.LayoutForDefinition(name)

    assert(Layout, "could not find layout whit " .. name)

    if not Sandbox[area] then
        Sandbox[area] = {}
    end

    Sandbox[area][name] = Layout
    Layouts[name] = Layout
end
