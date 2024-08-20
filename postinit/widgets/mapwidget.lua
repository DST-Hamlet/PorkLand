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
    for _, atlases in ipairs(ModManager:GetPostInitData("MinimapAtlases")) do
        for _, path in ipairs(atlases) do
            if TheSim:AtlasContains(resolvefilepath(path), image_name) then
                return path
            end
        end
    end
end

local minimap_atlas_cache = {}
local function get_minimap_atlas(image_name)
	local atlas = minimap_atlas_cache[image_name] or GetMinimapAtlas(image_name)
	if atlas then
		return atlas
	end

    atlas = get_atlas(image_name)

	if atlas ~= nil then
		minimap_atlas_cache[image_name] = atlas
	end

	return atlas
end

local function sort_priority(a, b)
    return a.priority < b.priority
end

local function get_door_id(current_room_id, target_interior_id)
    if current_room_id < target_interior_id then
        return tostring(current_room_id) .. "-" .. tostring(target_interior_id)
    else
        return tostring(target_interior_id) .. "-" .. tostring(current_room_id)
    end
end

-- For data's structure, see scripts/prefabs/interiorworkblank.lua
-- {
--     width: number,
--     depth: number,
--     floor_texture: string,
--     icons: { [id: number]: { icon: string, offset_x: number, offset_z: number, priority: number } }
--     doors: { target_interior: interiorID, direction: keyof DIRECTION_NAMES }[]
-- }
local function BuildInteriorMinimapLayout(widgets, data, visited_rooms, current_room_id, offset)
    visited_rooms[current_room_id] = true
    local room = data[current_room_id]

    local room_tile = Image("levels/textures/map_interior/" .. room.floor_texture .. ".xml", room.floor_texture .. ".tex")
    room_tile.position_offset = offset
    room_tile.tile_width = room.width
    room_tile.tile_depth = room.depth
    room_tile.inst.ImageWidget:SetEffect(resolvefilepath("shaders/ui_fillmode.ksh"))
    room_tile:SetEffectParams(0, 0, 0, 0)

    local room_frame = Image("interior_minimap/interior_minimap.xml", "pl_frame_" .. SizeToString(room.width, room.depth) .. ".tex")
    room_frame.position_offset = offset

    local room_widgets = {
        tile = room_tile,
        frame = room_frame,
        icons = {},
        offset = offset,
    }
    widgets.rooms[current_room_id] = room_widgets

    for id, icon_data in pairs(room.icons) do
        local atlas = get_minimap_atlas(icon_data.icon)
        if atlas then
            local icon = Image(atlas, icon_data.icon)
            icon.position_offset = offset + Vector3(icon_data.offset_x, 0, icon_data.offset_z)
            table.insert(room_widgets.icons, {widget = icon, id = id, priority = icon_data.priority})
        end
    end
    table.sort(room_widgets.icons, sort_priority)

    for _, door in ipairs(room.doors) do
        local direction = DIRECTION_VECTORS[door.direction]

        local door_id = get_door_id(current_room_id, door.target_interior)
        if not widgets.doors[door_id] then
            local door_icon_offset
            if direction.x ~= 0 then
                door_icon_offset = direction * (room.depth / 2 + INTERIOR_MINIMAP_DOOR_SPACE)
            else
                door_icon_offset = direction * (room.width / 2 + INTERIOR_MINIMAP_DOOR_SPACE)
            end
            local door_icon = Image("interior_minimap/interior_minimap.xml", direction.x ~= 0 and "pl_interior_passage4.tex" or "pl_interior_passage3.tex")
            door_icon.position_offset = offset + door_icon_offset
            widgets.doors[door_id] = door_icon
        end

        if not visited_rooms[door.target_interior] then
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

local function DiffWidget(self, incoming_data, room_id)
    local incoming_icons = incoming_data[room_id]
    local current_data = self.interior_map_widgets.rooms[room_id]
    local current_icons = current_data.icons
    if not incoming_icons then
        return current_icons, false
    end

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

local function UpdateWidgetPositionScale(widget, scale)
    widget:SetScale(scale, scale, 1)
    widget:SetPosition(WorldPosToScreenPos(widget.position_offset * INTERIOR_MINIMAP_POSITION_SCALE))
end

local function UpdateTileWidgetPositionScale(widget, scale)
    local width = widget.tile_width
    local depth = widget.tile_depth
    widget:SetScale(scale * (width / INTERIOR_MINIMAP_POSITION_SCALE), scale * (depth / INTERIOR_MINIMAP_POSITION_SCALE), 1)
    widget:SetEffectParams((width / INTERIOR_MINIMAP_POSITION_SCALE) - 1, (depth / INTERIOR_MINIMAP_POSITION_SCALE) - 1, 0, 0)
    widget:SetPosition(WorldPosToScreenPos(widget.position_offset * INTERIOR_MINIMAP_POSITION_SCALE))
end

local on_update = MapWidget.OnUpdate
function MapWidget:OnUpdate(...)
    on_update(self, ...)

    if not self.interior_map_widgets then
        return
    end

    local interiorvisitor = self.owner.replica.interiorvisitor
    if interiorvisitor.interior_map_icons_override then
        local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.owner:GetPosition())
        local new_icons, has_new_icons = DiffWidget(self, interiorvisitor.interior_map_icons_override, current_room_id)
        self.interior_map_widgets.rooms[current_room_id].icons = new_icons
        if has_new_icons then
            for _, door in pairs(self.interior_map_widgets.doors) do
                door:MoveToFront()
            end
            for _, room in pairs(self.interior_map_widgets.rooms) do
                for _, icon_data in ipairs(room.icons) do
                    icon_data.widget:MoveToFront()
                end
            end
        end
        interiorvisitor.interior_map_icons_override = nil
    end

    local scale = 0.75 / self.minimap:GetZoom()
    for _, rooms in pairs(self.interior_map_widgets.rooms) do
        UpdateWidgetPositionScale(rooms.frame, scale * INTERIOR_BG_SCALE)
        UpdateTileWidgetPositionScale(rooms.tile, scale * INTERIOR_BG_SCALE)

        for _, icon_data in ipairs(rooms.icons) do
            UpdateWidgetPositionScale(icon_data.widget, scale)
        end
    end
    for _, door in pairs(self.interior_map_widgets.doors) do
        UpdateWidgetPositionScale(door, scale)
    end
end

function MapWidget:OnEnterInterior()
    local data = self.owner.replica.interiorvisitor.interior_map
    local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.owner:GetPosition())
    if data[current_room_id] then
        -- {
        --     rooms: {
        --         [room_id: number]: {
        --         tile: Image,
        --         frame: Image,
        --         icons: { widget: Image, id: number, priority: number }[],
        --         offset: Vector3,
        --         }
        --     },
        --     doors: {
        --         [door_id: string]: Image
        --     },
        -- }
        self.interior_map_widgets = {
            rooms = {},
            doors = {},
        }
        BuildInteriorMinimapLayout(self.interior_map_widgets, data, {}, current_room_id, Vector3())
        for _, room in pairs(self.interior_map_widgets.rooms) do
            self:AddChild(room.tile)
            self:AddChild(room.frame)
        end
        for _, door in pairs(self.interior_map_widgets.doors) do
            self:AddChild(door)
        end
        for _, room in pairs(self.interior_map_widgets.rooms) do
            for _, icon_data in ipairs(room.icons) do
                self:AddChild(icon_data.widget)
            end
        end
        -- Hide the normal minimap
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
