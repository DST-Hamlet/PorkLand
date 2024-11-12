local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local ImageButton = require "widgets/imagebutton"

local MapScreen = require("screens/mapscreen")

local function FocusMapOnWorldPosition(mapscreen, worldx, worldz)
    if mapscreen == nil or mapscreen.minimap == nil then return nil end

    mapscreen:SetZoom(1)
    mapscreen.minimap.minimap:ResetOffset()

    local player_x, _, player_z = ThePlayer.Transform:GetWorldPosition()
    local dx, dy = worldx - player_x, worldz - player_z

    local angle_correction = (PI / 4) * (10 - (math.fmod(TheCamera:GetHeadingTarget() / 360, 1) * 8))
    local theta = math.atan2(dy, dx)
    local mag = math.sqrt(dx * dx + dy * dy)

    mapscreen.minimap:Offset(math.cos(theta + angle_correction) * mag, math.sin(theta + angle_correction) * mag)
end

-- TODO; 注意: 在房屋/商店室内移动时会导致地图的漂移

-- focus camera to exterior position (house)
function MapScreen:ApplyInteriorMinimap(room_center)
    if room_center:HasInteriorMinimap() then
        FocusMapOnWorldPosition(self, 0, 0)
        self.minimap:ApplyInteriorMinimap()
        self.interior_toggle_button:Show()
    else
        local pos = self.owner.replica.interiorvisitor:GetExteriorPos()
        FocusMapOnWorldPosition(self, pos.x, pos.z)
        self.minimap:ApplyExteriorDecorations()
        self.interior_toggle_button:Hide()
    end
end

function MapScreen:OnEnterInterior(center)
    if center then
        self:ApplyInteriorMinimap(center)
    end
end

function MapScreen:RefreshInteriorMinimap()
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(self.owner:GetPosition())
    if center then
        self:ApplyInteriorMinimap(center)
    end
end

-- reset focus point
function MapScreen:OnLeaveInterior()
    self.inst:DoTaskInTime(0, function()
        self.minimap.minimap:ResetOffset()
        self.minimap:ClearInteriorMinimap()
        self.interior_toggle_button:Hide()
    end)
end

AddClassPostConstruct("screens/mapscreen", function(self)
    self.interior_toggle_button = self.bottomright_root:AddChild(ImageButton("images/hud/pl_mapscreen_widgets.xml", "map_outside.tex"))
    self.interior_toggle_button:SetScale(.33, .33, .33)
    self.interior_toggle_button:SetPosition(-66, 150, 0)
    self.interior_toggle_button:SetOnClick(function()
        if self.minimap.interior_map_widgets then
            local pos = self.owner.replica.interiorvisitor:GetExteriorPos()
            FocusMapOnWorldPosition(self, pos.x, pos.z)
            self.interior_toggle_button:SetTextures("images/hud/pl_mapscreen_widgets.xml", "map_interior.tex")
        else
            FocusMapOnWorldPosition(self, 0, 0)
            self.interior_toggle_button:SetTextures("images/hud/pl_mapscreen_widgets.xml", "map_outside.tex")
        end
        self.minimap:ToggleInteriorMap()
    end)
    self.interior_toggle_button:Hide()

    if self.minimap.minimap == TheWorld.minimap.MiniMap then
        if TheCamera.inside_interior then
            self:OnEnterInterior(ThePlayer.replica.interiorvisitor:GetCenterEnt())
        end
    else
        print("Warning: Failed to find minimap c handler")
    end

    self.inst:ListenForEvent("enterinterior_client", function(_, data) self:OnEnterInterior(data and data.to) end, self.owner)
    self.inst:ListenForEvent("leaveinterior_client", function() self:OnLeaveInterior() end, self.owner)
    self.inst:ListenForEvent("interiorvisitor.exterior_pos", function() self:OnEnterInterior() end, self.owner)
    self.inst:ListenForEvent("refresh_interior_minimap", function() self:RefreshInteriorMinimap() end, self.owner)
end)
