local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

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
function MapScreen:OnEnterInterior(ent)
    if ent ~= nil then
        if ent:HasInteriorMinimap() then
            FocusMapOnWorldPosition(self, 0, 0)
        else
            local pos = self.owner.replica.interiorvisitor:GetExteriorPos()
            FocusMapOnWorldPosition(self, pos.x, pos.z)
        end
    end
end

-- reset focus point
function MapScreen:OnLeaveInterior()
    self.inst:DoTaskInTime(0, function()
        self.minimap.minimap:ResetOffset()
    end)
end

AddClassPostConstruct("screens/mapscreen", function(self)
    if self.minimap.minimap == TheWorld.minimap.MiniMap then
        if TheCamera.inside_interior then
            self:OnEnterInterior(ThePlayer.replica.interiorvisitor:GetCenterEnt())
        end
    else
        print("Warning: Failed to find minimap c handler")
    end

    self.inst:ListenForEvent("enterinterior", function(_, data) self:OnEnterInterior(data and data.to) end, self.owner)
    self.inst:ListenForEvent("leaveinterior", function() self:OnLeaveInterior() end, self.owner)
    self.inst:ListenForEvent("interiorvisitor.exterior_pos", function() self:OnEnterInterior() end, self.owner)
    self.inst:ListenForEvent("interiorvisitor.resetinteriorcamera", function()
        -- TODO: 这里会有一帧的闪烁，以后可以优化一下
        self.inst:DoTaskInTime(0, function()
            local center = self.owner.replica.interiorvisitor:GetCenterEnt()
            if center then
                self:OnEnterInterior(center)
            end
        end)
    end, self.owner)
end)
