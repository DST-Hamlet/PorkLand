local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Easing = require("easing")

local Widget = require "widgets/widget"
local Image = require "widgets/image"

local INTERIOR_MINIMAP_DOOR_SPACE = 5
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

local function get_atlas(imagename)
    local atlas = GetMinimapAtlas_Internal(imagename)
    if atlas then
        return atlas
    end
    for _, atlases in ipairs(ModManager:GetPostInitData("MinimapAtlases")) do
        for _, path in ipairs(atlases) do
            if TheSim:AtlasContains(resolvefilepath(path), imagename) then
                return path
            end
        end
    end
end

local minimapAtlasLookup = {}
local function GetMinimapAtlas(imagename)
	local atlas = minimapAtlasLookup[imagename]
	if atlas then
		return atlas
	end

    atlas = get_atlas(imagename)

	if atlas ~= nil then
		minimapAtlasLookup[imagename] = atlas
	end

	return atlas
end

-- For data's structure, see scripts/prefabs/interiorworkblank.lua
-- {
--     width: number,
--     depth: number,
--     icons: { icon: string, offset_x: number, offset_z: number, priority: number }[]
--     doors: { target_interior: interiorID, direction: keyof DIRECTION_NAMES }[]
-- }
local function BuildInteriorMinimapLayout(widgets, data, visited_rooms, current_room_id, offset)
    visited_rooms[current_room_id] = true

    local room = data[current_room_id]
    local room_widget = Image("interior_minimap/interior_minimap.xml", "pl_frame_" .. SizeToString(room.width, room.depth) .. ".tex")
    room_widget.position_offset = offset
    table.insert(widgets.backgrounds, room_widget)

    for _, icon_data in ipairs(room.icons) do
        local atlas = GetMinimapAtlas(icon_data.icon)
        if atlas then
            local icon = Image(GetMinimapAtlas(icon_data.icon), icon_data.icon)
            icon.position_offset = offset + Vector3(icon_data.offset_x, 0, icon_data.offset_z)
            table.insert(widgets.icons, icon)
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
            table.insert(widgets.doors, door_icon)

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

local MapWidget = require("widgets/mapwidget")

local on_update = MapWidget.OnUpdate
function MapWidget:OnUpdate(...)
    on_update(self, ...)

    -- if self.interior_map_widget then
    --     self.interior_map_widget:SetScale(1 - Easing.outExpo(TheWorld.minimap.MiniMap:GetZoom() - 1, 0, 0.75, 8))
    --     self.interior_map_widget:SetPosition(WorldPosToScreenPos(Vector3()))
    --     -- if TheWorld.minimap.MiniMap:IsVisible() then
    --     --     TheWorld.minimap.MiniMap:ToggleVisibility()
    --     -- end
    -- end
    if self.interior_map_widgets then
        for _, widget in ipairs(self.interior_map_widgets) do
            local zoomscale = 0.75 / self.minimap:GetZoom()
            widget:SetScale(zoomscale, zoomscale, 1)
            widget:SetPosition(WorldPosToScreenPos(widget.position_offset * INTERIOR_MINIMAP_POSITION_SCALE))
        end
    end
end

function MapWidget:OnEnterInterior()
    local data = self.owner.replica.interiorvisitor.interior_map
    local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.owner:GetPosition())
    if data[current_room_id] then
        local widgets = {
            backgrounds = {},
            icons = {},
            doors = {},
        }
        BuildInteriorMinimapLayout(widgets, data, {}, current_room_id, Vector3())
        self.interior_map_widgets = JoinArrays(widgets.backgrounds, widgets.icons, widgets.doors)
        for _, widget in ipairs(self.interior_map_widgets) do
            self:AddChild(widget)
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
