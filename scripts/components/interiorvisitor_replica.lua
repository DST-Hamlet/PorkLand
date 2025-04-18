
local CC_DEF = require("main/interior_texture_defs").CC_DEF

local InteriorVisitor = Class(function(self, inst)
    self.inst = inst

    self.center_ent = net_entity(inst.GUID, "interiorvisitor.center_ent")
    self.last_center_ent = nil
    self.exterior_pos_x = net_shortint(inst.GUID, "interiorvisitor.exterior_pos_x", "interiorvisitor.exterior_pos")
    self.exterior_pos_x:set_local(0)
    self.exterior_pos_z = net_shortint(inst.GUID, "interiorvisitor.exterior_pos_z", "interiorvisitor.exterior_pos")
    self.exterior_pos_z:set_local(0)
    self.exterior_icon = net_string(inst.GUID, "interiorvisitor.exterior_icon", "interiorvisitor.exterior_pos")
    self.exterior_icon:set_local("")
    self.interior_cc = net_smallbyte(inst.GUID, "interiorvisitor.interior_cc", "interiorvisitor.interior_cc")

    self.interior_map = {}
    self.interior_map_groups = {}
    self.local_interior_map_override = {}
    self.always_shown_interior_map = {}

    self.ininterior = false

    inst:StartUpdatingComponent(self)
end)

function InteriorVisitor:GetExteriorPos()
    return Point(
        self.exterior_pos_x:value(),
        0,
        self.exterior_pos_z:value()
    )
end

local function IsInInteriorRectangle(player_pos, ent)
    if ent == nil or not ent:IsValid() then
        return false
    end
    local w, d = ent:GetSize()
    local offset = ent:GetPosition() - player_pos
    return math.abs(offset.x) < d/2 + 2 and math.abs(offset.z) < w/2 + 2
end

-- function InteriorVisitor:Activate()
--     print("InteriorVisitor:Activate()")
-- end

-- function InteriorVisitor:Deactivate()
--     print("InteriorVisitor:Deactivate()")
-- end

function InteriorVisitor:ApplyInteriorCamera(interior_center)
    local cameraoffset = -2.5         --10x15
    local zoom = 23
    local depth = interior_center:GetDepth()

    if interior_center.cameraoffset and interior_center.zoom then
        cameraoffset = interior_center.cameraoffset
        zoom = interior_center.zoom
    elseif depth == 12 then    --12x18
        cameraoffset = -2
        zoom = 25
    elseif depth == 16 then --16x24
        cameraoffset = -1.5
        zoom = 30
    elseif depth == 18 then --18x26
        cameraoffset = -2 -- -1
        zoom = 35
    end

    -- custom value
    if interior_center.pl_interior_distance ~= nil then
        zoom = interior_center.pl_interior_distance
    end
    if interior_center.pl_interior_cameraoffset ~= nil then
        cameraoffset = interior_center.pl_interior_cameraoffset
    else
        cameraoffset = Vector3(cameraoffset, 0, 0)
    end

    local pos = interior_center:GetPosition()
    TheCamera.inside_interior = true
    TheCamera.pl_interior_currentpos = pos + cameraoffset
    TheCamera.pl_interior_distance = zoom
end

-- levels/textures/map_interior/mini_ruins_slab.tex -> mini_ruins_slab
local function basename(path)
    return string.match(path, "([^/]+)%.%w+$")
end

function InteriorVisitor:UpdateInteriorMinimap()
    local center = self.center_ent:value()
    if not center then
        self.local_interior_map_override = {}
        return
    end

    local current_room_id = TheWorld.components.interiorspawner:PositionToIndex(self.inst:GetPosition())
    if self.interior_map[current_room_id] then
        self.local_interior_map_override = {
            [current_room_id] = {
                icons = center:CollectMinimapIcons(),
                minimap_floor_texture = basename(center:GetFloorMinimapTex()),
                doors = center:CollectLocalDoorMinimap(),
            }
        }
    end
end

function InteriorVisitor:OnUpdate()
    if self.inst.components.interiorvisitor then
        self.inst.components.interiorvisitor:UpdateExteriorPos()
    end

    if self.inst ~= ThePlayer then
        return
    end

    local ambientlighting = TheWorld.components.ambientlighting
    local last_center_ent = self.last_center_ent
    local room_center_ent = TheWorld.components.interiorspawner:GetInteriorCenter(self.inst:GetPosition())

    if IsInInteriorRectangle(self.inst:GetPosition(), room_center_ent) then
        self:ApplyInteriorCamera(room_center_ent)

        if not self.ininterior and self.inst:HasTag("inside_interior") then
            self.ininterior = true

            self.last_center_ent = room_center_ent
            self.inst:PushEvent("enterinterior_client", {from = last_center_ent, to = room_center_ent})

            if self.inst.MiniMapEntity then
                self.inst.MiniMapEntity:SetEnabled(false)
            end
            if ambientlighting then
                ambientlighting:Pl_Refresh()
            end

            if TheWorld and TheWorld.components.cloudmanager then
                TheWorld.components.cloudmanager:SetEnabled(false)
            end
        end

        if room_center_ent:HasInteriorMinimap() then
            self:UpdateInteriorMinimap()
        end
    else
        if TheCamera.inside_interior then
            TheCamera.inside_interior = false
            TheCamera:RestoreOutsideInteriorCamera()
        end
        self.last_center_ent = nil

        if self.ininterior and not self.inst:HasTag("inside_interior")  then
            self.ininterior = false

            self.inst:PushEvent("leaveinterior_client", {from = last_center_ent, to = nil})

            if self.inst.MiniMapEntity then
                self.inst.MiniMapEntity:SetEnabled(true)
            end
            if ambientlighting then
                ambientlighting:Pl_Refresh()
            end

            if TheWorld and TheWorld.components.cloudmanager then
                TheWorld.components.cloudmanager:SetEnabled(true)
            end
        end
    end
end

function InteriorVisitor:GetCenterEnt()
    local ent = self.center_ent:value()
    if ent and ent:IsValid() then
        return ent
    end
end

function InteriorVisitor:GetCCTable()
    local index = self.interior_cc:value()
    local cc = CC_DEF[index] and CC_DEF[index].path or "images/colour_cubes/day05_cc.tex"
    cc = resolvefilepath(cc) -- add prefix mod root
    return {
        day = cc, dusk = cc, night = cc, full_moon = cc
    }
end

-- Receiving from interior_map client RPC
function InteriorVisitor:OnNewInteriorMapData(data)
    for id, data in pairs(data) do
        data.interior_id = id
        self.interior_map[id] = data
        if not self.interior_map_groups[data.group_id] then
            self.interior_map_groups[data.group_id] = {}
        end
        local coord_key = TheWorld.components.interiorspawner:CoordinatesToKey(data.coord_x, data.coord_y)
        self.interior_map_groups[data.group_id][coord_key] = data
    end
    self.inst:PushEvent("refresh_interior_minimap")
end

-- Receiving from remove_interior_map client RPC
function InteriorVisitor:RemoveInteriorMapData(data)
    for _, id in ipairs(data) do
        local map_data = self.interior_map[id]
        if map_data then
            local coord_key = TheWorld.components.interiorspawner:CoordinatesToKey(map_data.coord_x, map_data.coord_y)
            self.interior_map_groups[map_data.group_id][coord_key] = nil
            if IsTableEmpty(self.interior_map_groups[map_data.group_id]) then
                self.interior_map_groups[map_data.group_id] = nil
            end
            self.interior_map[id] = nil
        end
    end
    self.inst:PushEvent("refresh_interior_minimap")
end

-- Receiving from always_shown_interior_map client RPC
function InteriorVisitor:OnAlwaysShownInteriorMapData(data)
    for _, action in ipairs(data) do
        if action.type == "delete" then
            self.always_shown_interior_map[action.data] = nil
        elseif action.type == "replace" then
            self.always_shown_interior_map[action.data.id] = action.data
        elseif action.type == "clear" then
            self.always_shown_interior_map = {}
        end
    end
    self.inst:PushEvent("refresh_always_shown_interior_minimap", {actions = data})
end

-- function InteriorVisitor:OnRemoveFromEntity()
--     self:Deactivate()
-- end

-- InteriorVisitor.OnRemoveEntity = InteriorVisitor.OnRemoveFromEntity

return InteriorVisitor
