local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Easing = require("easing")

local Widget = require "widgets/widget"
local Image = require "widgets/image"

local INTERIOR_MINIMAP_DOOR_SPACE = 3
local INTERIOR_MINIMAP_POSITION_SCALE = 3

local DIRECTION_VECTORS = {
    north = Vector3(-1, 0,  0),
    south = Vector3(1,  0,  0),
    east  = Vector3(0,  0,  1),
    west  = Vector3(0,  0, -1),
}

local half_x, half_y = RESOLUTION_X / 2, RESOLUTION_Y / 2
local screen_width, screen_height = TheSim:GetScreenSize()
local function WorldPosToScreenPos(position)
    local x, _, z = position:Get()
    local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    local screen_x = ((map_x * half_x) + half_x) / RESOLUTION_X * screen_width
    local screen_y = ((map_y * half_y) + half_y) / RESOLUTION_Y * screen_height
    return screen_x, screen_y
end

local function SizeToString(width, depth)
    if width == 15 and depth == 10
        or width == 18 and depth == 12
        or width == 24 and depth == 16
        or width == 26 and depth == 18 then
        return width.."x"..depth
    else
        return SizeToString(18, 12) -- default (not recommended)
    end
end

local function get_atlas(image_name)
    local atlas = GetMinimapAtlas_Internal(image_name)
    if atlas then
        return atlas
    end
    for _, atlases in ipairs(ModManager:GetPostInitData("MinimapAtlases")) do
        for _, path in ipairs(atlases) do
            if TheSim:AtlasContains(resolvefilepath(path), image_name) then
                return path
            end
        end
    end
end

local minimap_atlas_cache = {}
local function GetMinimapAtlas(image_name)
	local atlas = minimap_atlas_cache[image_name]
	if atlas then
		return atlas
	end

    atlas = get_atlas(image_name)

	if atlas ~= nil then
		minimap_atlas_cache[image_name] = atlas
	end

	return atlas
end

-- For data's structure, see scripts/prefabs/interiorworkblank.lua
-- {
--     width: number,
--     depth: number,
--     icons: { [id: number]: { icon: string, offset_x: number, offset_z: number, priority: number } }
--     doors: { target_interior: interiorID, direction: keyof DIRECTION_NAMES }[]
-- }
local function BuildInteriorMinimapLayout(widgets, data, visited_rooms, current_room_id, offset)
    visited_rooms[current_room_id] = true
    local room = data[current_room_id]
    local room_widgets = {
        backgrounds = {},
        tiles = {},
        icons = {},
        doors = {},
        offset = offset,
    }
    widgets[current_room_id] = room_widgets

    local room_background = Image("interior_minimap/interior_minimap.xml", "pl_frame_" .. SizeToString(room.width, room.depth) .. ".tex")
    room_background.position_offset = offset
    table.insert(room_widgets.backgrounds, room_background)

    local room_tiles = Image("levels/textures/map_interior/mini_ruins_slab.xml", "mini_ruins_slab.tex")
    room_tiles.position_offset = offset
    room_tiles.tile_width = room.width
    room_tiles.tile_depth = room.depth
    room_tiles.inst.ImageWidget:SetEffect(resolvefilepath("shaders/ui_fillmode.ksh"))
    table.insert(room_widgets.tiles, room_tiles)
    room_tiles:SetEffectParams(0, 0, 0, 0)

    for id, icon_data in pairs(room.icons) do
        local atlas = GetMinimapAtlas(icon_data.icon)
        if atlas then
            local icon = Image(atlas, icon_data.icon)
            icon.position_offset = offset + Vector3(icon_data.offset_x, 0, icon_data.offset_z)
            table.insert(room_widgets.icons, {widget = icon, id = id, priority = icon_data.priority})
        end
    end

    for _, door in ipairs(room.doors) do
        if not visited_rooms[door.target_interior] then
            local direction = DIRECTION_VECTORS[door.direction]
            local door_icon_offset
            if direction.x ~= 0 then
                door_icon_offset = direction * (room.depth / 2 + INTERIOR_MINIMAP_DOOR_SPACE)
            else
                door_icon_offset = direction * (room.width / 2 + INTERIOR_MINIMAP_DOOR_SPACE)
            end
            local door_icon = Image("interior_minimap/interior_minimap.xml", direction.x ~= 0 and "pl_interior_passage4.tex" or "pl_interior_passage3.tex")
            door_icon.position_offset = offset + door_icon_offset
            table.insert(room_widgets.doors, door_icon)

            local target_room = data[door.target_interior]
            if target_room then
                local target_interior_offset
                if direction.x ~= 0 then
                    target_interior_offset = direction * (room.depth / 2 + target_room.depth / 2 + INTERIOR_MINIMAP_DOOR_SPACE * 2)
                else
                    target_interior_offset = direction * (room.width / 2 + target_room.width / 2 + INTERIOR_MINIMAP_DOOR_SPACE * 2)
                end
                BuildInteriorMinimapLayout(widgets, data, visited_rooms, door.target_interior, offset + target_interior_offset)
            end
        end
    end
end

local function sort_priority(a, b)
    return a.priority < b.priority
end

local function DiffWidget(self, incoming_data, room_id)
    local incoming_room_data = incoming_data[room_id]
    local current_data = self.interior_map_widgets[room_id]
    local current_icons = current_data.icons
    if not incoming_room_data then
        return current_icons, false
    end

    local incoming_icons = incoming_room_data.icons

    local result_icons = {}
    local result_icons_set = {}
    local has_new_icons = false

    for _, current_icon in ipairs(current_icons) do
        local incoming_icon = incoming_icons[current_icon.id]
        if incoming_icon then
            current_icon.widget.position_offset = current_data.offset + Vector3(incoming_icon.offset_x, 0, incoming_icon.offset_z)
            table.insert(result_icons, current_icon)
            result_icons_set[current_icon.id] = current_icon
        else
            current_icon.widget:Kill()
        end
    end

    for id, new_data in pairs(incoming_icons) do
        local current_icon = result_icons_set[id]
        if not current_icon then
            local atlas = GetMinimapAtlas(new_data.icon)
            if atlas then
                local icon = Image(atlas, new_data.icon)
                icon.position_offset = current_data.offset + Vector3(new_data.offset_x, 0, new_data.offset_z)
                self:AddChild(icon)
                table.insert(result_icons, {widget = icon, id = id, priority = new_data.priority})
                has_new_icons = true
            end
        end
    end
    if has_new_icons then
        table.sort(result_icons, sort_priority)
    end
    return result_icons, has_new_icons
end

local MapWidget = require("widgets/mapwidget")

local INTERIOR_BG_SCALE = 0.8
local INTERIOR_TILE_SCALE = 1

local function UpdateWidgetPositionScale(widget, scale)
    widget:SetScale(scale, scale, 1)
    widget:SetPosition(WorldPosToScreenPos(widget.position_offset * INTERIOR_MINIMAP_POSITION_SCALE))
end

local function UpdateWidgetPositionScale_Tile(widget, scale)
    if widget.tile_width then
        local width = widget.tile_width
        local depth = widget.tile_depth
        widget:SetScale(scale * (width / 4), scale * (depth / 4), 1)
        widget:SetEffectParams((width / 4) - 1, (depth / 4) - 1, 0, 0)
        widget:SetPosition(WorldPosToScreenPos(widget.position_offset * INTERIOR_MINIMAP_POSITION_SCALE))
    else
        UpdateWidgetPositionScale(widget, scale)
    end
end

local on_update = MapWidget.OnUpdate
function MapWidget:OnUpdate(...)
    on_update(self, ...)

    if not self.interior_map_widgets then
        return
    end

    if self.owner.replica.interiorvisitor.interior_map_dirty then
        local data = self.owner.replica.interiorvisitor.interior_map
        local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.owner:GetPosition())
        local new_icons, has_new_icons = DiffWidget(self, data, current_room_id)
        self.interior_map_widgets[current_room_id].icons = new_icons
        if has_new_icons then
            for _, widgets in pairs(self.interior_map_widgets) do
                for _, icon_data in ipairs(widgets.icons) do
                    icon_data.widget:MoveToFront()
                end
                for _, door in ipairs(widgets.doors) do
                    door:MoveToFront()
                end
            end
        end
        self.owner.replica.interiorvisitor.interior_map_dirty = false
    end

    local scale = 0.75 / self.minimap:GetZoom()
    for _, widgets in pairs(self.interior_map_widgets) do
        for _, background in ipairs(widgets.backgrounds) do
            UpdateWidgetPositionScale(background, scale * INTERIOR_BG_SCALE)
        end
        for _, tile in ipairs(widgets.tiles) do
            UpdateWidgetPositionScale_Tile(tile, scale * INTERIOR_TILE_SCALE)
        end
        for _, icon_data in ipairs(widgets.icons) do
            UpdateWidgetPositionScale(icon_data.widget, scale)
        end
        for _, door in ipairs(widgets.doors) do
            UpdateWidgetPositionScale(door, scale)
        end
    end
end

function MapWidget:OnEnterInterior()
    local data = self.owner.replica.interiorvisitor.interior_map
    local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.owner:GetPosition())
    if data[current_room_id] then
        self.interior_map_widgets = {}
        BuildInteriorMinimapLayout(self.interior_map_widgets, data, {}, current_room_id, Vector3())
        for _, widgets in pairs(self.interior_map_widgets) do
            for _, background in ipairs(widgets.backgrounds) do
                self:AddChild(background)
            end
            for _, tile in ipairs(widgets.tiles) do
                self:AddChild(tile)
            end
            for _, icon_data in ipairs(widgets.icons) do
                self:AddChild(icon_data.widget)
            end
            for _, door in ipairs(widgets.doors) do
                self:AddChild(door)
            end
        end
        self.img:Hide()
    end
end

AddClassPostConstruct("widgets/mapwidget", function(self)
    -- local interior_center = self.owner.replica.interiorvisitor:GetCenterEnt()
    -- if interior_center and interior_center:HasInteriorMinimap() then
    --     self.interior_map_widget = self:AddChild(Widget("interior map"))
    --     local data = self.owner.replica.interiorvisitor.interior_map
    --     local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.owner:GetPosition())
    --     if data[current_room_id] then
    --         BuildInteriorMinimapLayout(self.interior_map_widget, data, {}, current_room_id, Vector3())
    --     end
    -- end
end)
