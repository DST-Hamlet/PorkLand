local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Easing = require("easing")

local Widget = require "widgets/widget"
local Image = require "widgets/image"

local INTERIOR_MINIMAP_DOOR_SPACE = 2
local INTERIOR_MINIMAP_POSITION_SCALE = 3
local INTERIOR_MINIMAP_TILE_SCALE = 6

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

local INACTIVE_TINT = BGCOLOURS.GREY

-- For data's structure, see scripts/prefabs/interiorworkblank.lua
-- also note that interior_id is added from scripts/components/interiorvisitor_replica.lua when receiving the data from server
-- {
--     interior_id: number,
--     group_id: number,
--     coord_x = number,
--     coord_y = number,
--     width: number,
--     depth: number,
--     minimap_floor_texture: string,
--     icons: { [id: number]: { icon: string, offset_x: number, offset_z: number, priority: number } }
--     doors: { target_interior: interiorID, direction: keyof DIRECTION_NAMES }[]
-- }
local function BuildInteriorMinimapLayout(widgets, data, visited_rooms, room_id, offset, current_room_id)
    visited_rooms[room_id] = true
    local room = data[room_id]
    local is_current_room = room_id == current_room_id

    -- Fallback to mini_floor_wood
    local minimap_floor_texture = room.minimap_floor_texture == "" and "mini_floor_wood" or room.minimap_floor_texture
    local room_tile = Image("levels/textures/map_interior/" .. minimap_floor_texture .. ".xml", minimap_floor_texture .. ".tex")
    room_tile.position_offset = offset
    room_tile.tile_scale_x = room.width / INTERIOR_MINIMAP_TILE_SCALE
    room_tile.tile_scale_y = room.depth / INTERIOR_MINIMAP_TILE_SCALE
    room_tile.inst.ImageWidget:SetEffect(resolvefilepath("shaders/ui_fillmode.ksh"))
    room_tile:SetEffectParams(0, 0, 0, 0)
    if not is_current_room then
        room_tile:SetTint(unpack(INACTIVE_TINT))
    end

    local room_frame = Image("interior_minimap/interior_minimap.xml", "pl_frame_" .. SizeToString(room.width, room.depth) .. ".tex")
    room_frame.position_offset = offset
    if not is_current_room then
        room_frame:SetTint(unpack(INACTIVE_TINT))
    end

    local room_widgets = {
        tile = room_tile,
        frame = room_frame,
        icons = {},
        offset = offset,
    }
    widgets.rooms[room_id] = room_widgets

    for id, icon_data in pairs(room.icons) do
        local atlas = get_minimap_atlas(icon_data.icon)
        if atlas then
            local icon = Image(atlas, icon_data.icon)
            if not is_current_room then
                icon:SetTint(unpack(INACTIVE_TINT))
            end
            icon.position_offset = offset + Vector3(icon_data.offset_x, 0, icon_data.offset_z)
            table.insert(room_widgets.icons, {widget = icon, id = id, priority = icon_data.priority})
        end
    end
    table.sort(room_widgets.icons, sort_priority)

    for _, door_data in ipairs(room.doors) do
        local direction = DIRECTION_VECTORS[door_data.direction]

        local door_id = get_door_id(room_id, door_data.target_interior)
        if not widgets.doors[door_id] then
            local connected_to_current_room = is_current_room or door_data.target_interior == current_room_id
            local door_icon_offset
            if direction.x ~= 0 then
                door_icon_offset = direction * (room.depth / 2 + INTERIOR_MINIMAP_DOOR_SPACE)
            else
                door_icon_offset = direction * (room.width / 2 + INTERIOR_MINIMAP_DOOR_SPACE)
            end
            local door_icon_container = Widget("InteriorDoor")
            local door_icon = Image("interior_minimap/interior_minimap.xml", direction.x ~= 0 and "pl_interior_passage4.tex" or "pl_interior_passage3.tex")
            if not connected_to_current_room then
                door_icon:SetTint(unpack(INACTIVE_TINT))
            end
            door_icon_container:AddChild(door_icon)
            door_icon_container.lock = door_icon_container:AddChild(Image("interior_minimap/interior_minimap.xml", "passage_blocked.tex"))
            door_icon_container.lock:ScaleToSize(128, 128)
            if not connected_to_current_room then
                door_icon_container.lock:SetTint(unpack(INACTIVE_TINT))
            end
            door_icon_container.position_offset = offset + door_icon_offset
            if door_data.hidden then
                door_icon_container:Hide()
            end
            if not door_data.disabled then
                door_icon_container.lock:Hide()
            end
            if door_data.unknown then
                door_icon_container.unknown = door_icon_container:AddChild(Image("interior_minimap/interior_minimap.xml", "passage_unknown.tex"))
                door_icon_container.unknown:ScaleToSize(128, 128)
                if not connected_to_current_room then
                    door_icon_container.unknown:SetTint(unpack(INACTIVE_TINT))
                end
            end
            widgets.doors[door_id] = door_icon_container
        end

        if not visited_rooms[door_data.target_interior] then
            local target_room = data[door_data.target_interior]
            if target_room then
                local target_interior_offset
                if direction.x ~= 0 then
                    target_interior_offset = direction * (room.depth / 2 + target_room.depth / 2 + INTERIOR_MINIMAP_DOOR_SPACE * 2)
                else
                    target_interior_offset = direction * (room.width / 2 + target_room.width / 2 + INTERIOR_MINIMAP_DOOR_SPACE * 2)
                end
                BuildInteriorMinimapLayout(widgets, data, visited_rooms, door_data.target_interior, offset + target_interior_offset, current_room_id)
            end
        end
    end
end

local function DiffWidget(self, current_data, incoming_data, room_id)
    local result_icons = {}
    local result_icons_set = {}
    local has_new_icons = false

    local incoming_icons = incoming_data.icons
    local current_icons = current_data.icons

    if incoming_data.minimap_floor_texture ~= "" then
        current_data.tile:SetTexture(
            "levels/textures/map_interior/" .. incoming_data.minimap_floor_texture .. ".xml",
            incoming_data.minimap_floor_texture .. ".tex"
        )
    end

    local current_room_data = self.owner.replica.interiorvisitor.interior_map[room_id]
    if current_room_data then
        for _, door in ipairs(current_room_data.doors) do
            local override_data = incoming_data.doors[door.direction]
            if override_data then
                local id = get_door_id(room_id, door.target_interior)
                local door_widget = self.interior_map_widgets.doors[id]
                if door_widget then
                    if override_data.hidden then
                        door_widget:Hide()
                    else
                        door_widget:Show()
                    end
                    if override_data.disabled then
                        door_widget.lock:Show()
                    else
                        door_widget.lock:Hide()
                    end
                end
            end
        end
    end

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
            local atlas = get_minimap_atlas(new_data.icon)
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
local INTERIOR_DOOR_SCALE = 0.8
local INTERIOR_TILE_SCALE = 2

local function UpdateWidgetPositionScale(widget, scale, offset_scale)
    widget:SetScale(scale, scale, 1)
    widget:SetPosition(WorldPosToScreenPos(widget.position_offset * (offset_scale or 1)))
end

local function UpdateInteriorWidgetPositionScale(widget, scale)
    UpdateWidgetPositionScale(widget, scale, INTERIOR_MINIMAP_POSITION_SCALE)
end

local function UpdateTileWidgetPositionScale(widget, scale)
    widget:SetScale(scale * widget.tile_scale_x, scale * widget.tile_scale_y, 1)
    widget:SetEffectParams(widget.tile_scale_x - 1, widget.tile_scale_y - 1, 0, 0)
    widget:SetPosition(WorldPosToScreenPos(widget.position_offset * INTERIOR_MINIMAP_POSITION_SCALE))
end

local function CalculateOffset(current_center, target_x, target_y)
    -- Convert the grid coordinates to positions
    -- as a compromise, we don't know the exact position,
    -- just use the current room's size as an estimate
    local current_x, current_y = current_center:GetCoordinates()
    local width, depth = current_center:GetSize()
    local offset_x = (target_x - current_x) * (width + INTERIOR_MINIMAP_DOOR_SPACE * 2)
    local offset_y = (target_y - current_y) * (depth + INTERIOR_MINIMAP_DOOR_SPACE * 2)
    return Vector3(-offset_y, 0, offset_x)
end

function MapWidget:ApplyInteriorMinimap()
    self:ClearInteriorMinimap()
    self:ClearExteriorDecorations()

    local interiorvisitor = self.owner.replica.interiorvisitor
    local data = interiorvisitor.interior_map
    local position = self.owner:GetPosition()
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    if not center then
        return
    end
    local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(position)

    -- {
    --     rooms: {
    --         [room_id: number]: {
    --             tile: Image,
    --             frame: Image,
    --             icons: { widget: Image, id: number, priority: number }[],
    --             offset: Vector3,
    --         }
    --     },
    --     doors: {
    --         [door_id: string]: Widget: {
    --             lock: Image
    --         }
    --     },
    --     always_shown_icons: {
    --         [id: number]: {
    --             widget: Image,
    --             priority: number,
    --             offset: Vector3,
    --         }
    --     },
    -- }
    self.interior_map_widgets = {
        rooms = {},
        doors = {},
        always_shown_icons = {},
    }

    -- This is so that it works on for ghost players
    -- ghost players don't discover map data,
    -- so we just show the existing map
    local starting_room_id = current_room_id
    local starting_offset = Vector3(0, 0, 0)
    if not data[current_room_id] then
        local group = interiorvisitor.interior_map_groups[center:GetGroupId()]
        if not group then
            return
        end
        local _, first_room_data = next(group)
        starting_room_id = first_room_data.interior_id
        starting_offset = CalculateOffset(center, first_room_data.coord_x, first_room_data.coord_y)
    end

    BuildInteriorMinimapLayout(self.interior_map_widgets, data, {}, starting_room_id, starting_offset, current_room_id)

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

    local values = {}
    for id, icon_data in pairs(interiorvisitor.always_shown_interior_map) do
        local atlas = get_minimap_atlas(icon_data.icon)
        if atlas then
            local room_offset = CalculateOffset(center, icon_data.coord_x, icon_data.coord_y)
            local offset = room_offset + Vector3(icon_data.offset_x, 0, icon_data.offset_z)
            local icon = Image(atlas, icon_data.icon)
            icon.position_offset = offset
            local new_data = {
                widget = icon,
                offset = offset,
                priority = icon_data.priority
            }
            table.insert(values, new_data)
            self.interior_map_widgets.always_shown_icons[id] = new_data
        end
    end
    table.sort(values, sort_priority)
    for _, v in ipairs(values) do
        v.widget = self:AddChild(v.widget)
    end

    -- Hide the normal minimap
    self.img:Hide()
    self.interior_frontend:MoveToFront()

    local local_interior_map_override = self.owner.replica.interiorvisitor.local_interior_map_override[current_room_id]
    if local_interior_map_override then
        local_interior_map_override.applied = nil
    end

    self:OnUpdate(0)
end

function MapWidget:ClearInteriorMinimap()
    if self.interior_map_widgets then
        for _, room in pairs(self.interior_map_widgets.rooms) do
            room.tile:Kill()
            room.frame:Kill()
        end
        for _, door in pairs(self.interior_map_widgets.doors) do
            door:Kill()
        end
        for _, room in pairs(self.interior_map_widgets.rooms) do
            for _, icon_data in ipairs(room.icons) do
                icon_data.widget:Kill()
            end
        end
        for _, icon_data in pairs(self.interior_map_widgets.always_shown_icons) do
            icon_data.widget:Kill()
        end
        self.interior_map_widgets = nil
    end
    self.img:Show()
end

function MapWidget:ApplyExteriorDecorations()
    self:ClearInteriorMinimap()
    self:ClearExteriorDecorations()

    local interiorvisitor = self.owner.replica.interiorvisitor
    local icon = interiorvisitor.exterior_icon:value()
    local atlas = get_minimap_atlas(icon)
    if not atlas then
        return
    end
    local icon = self:AddChild(Image(atlas, icon))
    icon.position_offset = interiorvisitor:GetExteriorPos()
    local arrow = self:AddChild(Image("images/hud/pl_mapscreen_widgets.xml", "red_arrow.tex"))
    arrow.position_offset = icon.position_offset + Vector3(-9, 0, 0)
    self.exterior_decorations = {icon, arrow}
    self:OnUpdate(0)
end

function MapWidget:ClearExteriorDecorations()
    if self.exterior_decorations then
        for _, decoration in ipairs(self.exterior_decorations) do
            decoration:Kill()
        end
    end
    self.exterior_decorations = nil
end

function MapWidget:RefreshAlwaysShownInteriorMinimap(actions)
    if not self.interior_map_widgets then
        return
    end

    local position = self.owner:GetPosition()
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    if not center then
        return
    end

    local has_new_icons = false
    for _, action in ipairs(actions) do
        if action.type == "delete" then
            if self.interior_map_widgets.always_shown_icons[action.data] then
                self.interior_map_widgets.always_shown_icons[action.data].widget:Kill()
                self.interior_map_widgets.always_shown_icons[action.data] = nil
            end
        elseif action.type == "replace" then
            local icon_data = action.data
            local atlas = get_minimap_atlas(icon_data.icon)
            if atlas then
                local room_offset = CalculateOffset(center, icon_data.coord_x, icon_data.coord_y)
                local offset = room_offset + Vector3(icon_data.offset_x, 0, icon_data.offset_z)
                if self.interior_map_widgets.always_shown_icons[action.data.id] then
                    self.interior_map_widgets.always_shown_icons[action.data.id].widget:SetTexture(atlas, icon_data.icon)
                    self.interior_map_widgets.always_shown_icons[action.data.id].widget.position_offset = offset
                    self.interior_map_widgets.always_shown_icons[action.data.id].offset = offset
                    self.interior_map_widgets.always_shown_icons[action.data.id].priority = icon_data.priority
                else
                    local icon = self:AddChild(Image(atlas, icon_data.icon))
                    icon.position_offset = offset
                    local new_data = {
                        widget = icon,
                        offset = offset,
                        priority = icon_data.priority
                    }
                    has_new_icons = true
                    self.interior_map_widgets.always_shown_icons[action.data.id] = new_data
                end
            end
        elseif action.type == "clear" then
            for _, icon_data in pairs(self.interior_map_widgets.always_shown_icons) do
                icon_data.widget:Kill()
            end
            self.interior_map_widgets.always_shown_icons = {}
        end
    end
    if has_new_icons then
        self:UpdateInteriorMapIconPriorities()
    end
end

function MapWidget:ToggleInteriorMap()
    if self.interior_map_widgets then
        self:ApplyExteriorDecorations()
    else
        self:ApplyInteriorMinimap()
    end
end

function MapWidget:UpdateInteriorMapIconPriorities()
    for _, door in pairs(self.interior_map_widgets.doors) do
        door:MoveToFront()
    end
    for _, room in pairs(self.interior_map_widgets.rooms) do
        for _, icon_data in ipairs(room.icons) do
            icon_data.widget:MoveToFront()
        end
    end
    local values = {}
    for _, v in ipairs(self.interior_map_widgets.always_shown_icons) do
        table.insert(values, v)
    end
    table.sort(values, sort_priority)
    for _, v in ipairs(values) do
        v.widget:MoveToFront()
    end
end

function MapWidget:UpdateInteriorWidgets()
    local owner_position = self.owner:GetPosition()
    -- Try to compensate map shifts from player movements
    -- This doesn't quite work, the map will be shaking
    -- if self.owner_last_position then
    --     self.minimap:Offset(owner_position.z - self.owner_last_position.z, self.owner_last_position.x - owner_position.x)
    -- end
    -- self.owner_last_position = owner_position

    local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(owner_position)
    local interiorvisitor = self.owner.replica.interiorvisitor
    -- Checking self.interior_map_widgets.rooms[current_room_id] here
    -- because we can get teleported out of the interior during debugging
    local current_data = self.interior_map_widgets.rooms[current_room_id]
    local local_interior_map_override = interiorvisitor.local_interior_map_override[current_room_id]
    if current_data and local_interior_map_override and not local_interior_map_override.applied then
        local new_icons, has_new_icons = DiffWidget(self, current_data, local_interior_map_override, current_room_id)
        current_data.icons = new_icons
        if has_new_icons then
            self:UpdateInteriorMapIconPriorities()
        end
        local_interior_map_override.applied = true
    end

    local scale = 0.75 / self.minimap:GetZoom()
    for _, rooms in pairs(self.interior_map_widgets.rooms) do
        UpdateInteriorWidgetPositionScale(rooms.frame, scale * INTERIOR_BG_SCALE)
        UpdateTileWidgetPositionScale(rooms.tile, scale * INTERIOR_BG_SCALE * INTERIOR_TILE_SCALE)

        for _, icon_data in ipairs(rooms.icons) do
            UpdateInteriorWidgetPositionScale(icon_data.widget, scale)
        end
    end
    for door_id, door in pairs(self.interior_map_widgets.doors) do
        UpdateInteriorWidgetPositionScale(door, scale * INTERIOR_DOOR_SCALE)
    end

    for id, icon_data in pairs(self.interior_map_widgets.always_shown_icons) do
        UpdateInteriorWidgetPositionScale(icon_data.widget, scale)
    end
end

function MapWidget:UpdateExteriorWidgets()
    local scale = 0.75 / self.minimap:GetZoom()
    for _, decoration in ipairs(self.exterior_decorations) do
        UpdateWidgetPositionScale(decoration, scale)
    end
end

-- Delay a frame so this is loaded after Global Positions to OnUpdate compatible with it
scheduler:ExecuteInTime(0, function()
    AddClassPostConstruct("widgets/mapwidget", function(self)
        self.bg.inst.ImageWidget:SetTexture("images/hud/pl_hud.xml", "blackbg.tex")
        self.bg:SetTint(0,0,0,1)

        self.interior_frontend = self:AddChild(Image("images/hud/pl_minimaphud.xml", "pl_minimaphud.tex"))
        self.interior_frontend:SetVRegPoint(ANCHOR_MIDDLE)
        self.interior_frontend:SetHRegPoint(ANCHOR_MIDDLE)
        self.interior_frontend:SetVAnchor(ANCHOR_MIDDLE)
        self.interior_frontend:SetHAnchor(ANCHOR_MIDDLE)
        self.interior_frontend:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.interior_frontend.inst.ImageWidget:SetBlendMode(BLENDMODE.Additive)
        self.interior_frontend:MoveToFront()
        self.interior_frontend:Show()

        self.bg:RemoveChild(self.centerreticle)
        self.interior_frontend:AddChild(self.centerreticle)
        self.centerreticle:MoveToFront()

        local on_update = self.OnUpdate
        self.OnUpdate = function(self, ...)
            on_update(self, ...)

            if not self.shown then
                return
            end

            if self.interior_map_widgets then
                self:UpdateInteriorWidgets()
            elseif self.exterior_decorations then
                self:UpdateExteriorWidgets()
            end
        end
        self.interior_frontend:MoveToFront()
    end)
end)
