local AddClassPostConstruct = AddClassPostConstruct
local AddPrefabPostInit = AddPrefabPostInit
local Assets = Assets
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local MapScreen = require("screens/mapscreen")

local env = env
local GLOBAL = env.GLOBAL

GLOBAL.setfenv(1, GLOBAL)

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
    if ent == nil then
        ent = self.owner.replica.interiorvisitor:GetCenterEnt()
    end

    if ent ~= nil then
        if ent:HasInteriorMinimap() and TheWorld.components.worldmapiconproxy:UsingInteriorMinimap() then
            FocusMapOnWorldPosition(self, 0, 0)
            self.pl_exterior_switch:Show()
        else
            -- local pos = self.owner.replica.interiorvisitor:GetExteriorPos()
            local x,_,z = TheWorld.components.worldmapiconproxy:GetExteriorPosClient()
            x, z = x or 0, z or 0
            FocusMapOnWorldPosition(self, x, z)
            if ent:HasInteriorMinimap() then
                self.pl_exterior_switch:Show()
            else
                self.pl_exterior_switch:Hide()
            end
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
    -- 2024/7/13 add a switch for exterior map
    if self.mapcontrols then
        local switch = ImageButton(
            -- TODO: replace this for switch button
            "images/hud/switch_exterior.xml", "switch_exterior.tex", nil, nil, nil, nil, {1,1}, {0,0})
        switch:SetScale(0.3, 0.3, 0.3)
        switch:SetPosition(-100, 0)
        switch:Hide()
        switch:SetOnClick(function() 
            self.owner:PushEvent("pl_toggleminimapmode")
            self.owner:DoTaskInTime(0.1, function() self:OnEnterInterior() end)
        end)

        self.pl_exterior_switch = self.mapcontrols:AddChild(switch)
    else
        self.pl_exterior_switch = Widget()
    end

    self.owner:PushEvent("pl_toggleminimapmode", "interior")

    local minimap = self.minimap
    if minimap.minimap == TheWorld.minimap.MiniMap then
        if TheCamera.inside_interior then
            self:OnEnterInterior()
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
            local ent = self.owner.replica.interiorvisitor:GetCenterEnt()
            if ent ~= nil then
                self:OnEnterInterior(ent)
            end
        end)
    end, self.owner)
end)

-- TODO: replace this for switch button
table.insert(Assets, Asset("ATLAS", "images/hud/switch_exterior.xml"))
