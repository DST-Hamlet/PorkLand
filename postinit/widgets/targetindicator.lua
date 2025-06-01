local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local TargetIndicator = require("widgets/targetindicator")

local MIN_SCALE = .5
-- local MIN_ALPHA = .35

local DEFAULT_ATLAS = "images/avatars.xml"
local DEFAULT_AVATAR = "avatar_unknown.tex"

local on_update = TargetIndicator.OnUpdate
function TargetIndicator:OnUpdate(...)
    if TheNet:IsServerPaused() then return end

    if not self.target:IsValid() then
        return
    end

    if self.target.prefab ~= "target_indicator_marker" then
        return on_update(self, ...)
    end

    local userflags = self.target.marker_data.userflags or 0
    if self.userflags ~= userflags then
        self.userflags = userflags
        self.isGhost = checkbit(userflags, USERFLAGS.IS_GHOST)
        self.isCharacterState1 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_1)
        self.isCharacterState2 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_2)
        self.isCharacterState3 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_3)
        self.headbg:SetTexture(DEFAULT_ATLAS, self.isGhost and "avatar_ghost_bg.tex" or "avatar_bg.tex")
        self.head:SetTexture(self:GetAvatarAtlas(), self:GetAvatar(), DEFAULT_AVATAR)
    end

    local center = TheWorld.components.interiorspawner:GetInteriorCenter(self.owner:GetPosition())
    if not center then
        return
    end

    local coord_x = self.target.marker_data.coord_x
    local coord_y = self.target.marker_data.coord_y
    local offset = CalculateInteriorOffset(center, coord_x, coord_y)
    local target_position = center:GetPosition() + offset + Vector3(self.target.marker_data.offset_x, 0, self.target.marker_data.offset_z)
    self.target.Transform:SetPosition(target_position:Get())

    local dist = center:GetDistanceSqToInst(self.target)
    local position = self.owner:GetPosition()
    dist = math.sqrt(dist)

    local alpha = self:GetTargetIndicatorAlpha(dist)
    self.headbg:SetTint(1, 1, 1, alpha)
    self.head:SetTint(1, 1, 1, alpha)
    self.headframe:SetTint(self.colour[1], self.colour[2], self.colour[3], alpha)
    self.arrow:SetTint(self.colour[1], self.colour[2], self.colour[3], alpha)
    self.name_label:SetColour(self.colour[1], self.colour[2], self.colour[3], alpha)

    if dist < TUNING.MIN_INDICATOR_RANGE then
        dist = TUNING.MIN_INDICATOR_RANGE
    elseif dist > TUNING.MAX_INDICATOR_RANGE then
        dist = TUNING.MAX_INDICATOR_RANGE
    end
    local scale = Remap(dist, TUNING.MIN_INDICATOR_RANGE, TUNING.MAX_INDICATOR_RANGE, 1, MIN_SCALE)
    self:SetScale(scale)

    local x, _, z = self.target.Transform:GetWorldPosition()
    self:UpdatePosition(x, z)
end

local update_position = TargetIndicator.UpdatePosition
function TargetIndicator:UpdatePosition(targX, targZ, ...)
    local position = self.owner:GetPosition()
    local roomcenter = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    if roomcenter and roomcenter:IsValid() then
        local w0, h0 = self.head:GetSize()
        local w1, h1 = self.arrow:GetSize()
        local scale = self:GetScale()
        local w = ((w0 or 0) + (w1 or 0)) * 0.5 * scale.x
        local h = ((h0 or 0) + (h1 or 0)) * 0.5 * scale.y
        local x, y, angle = GetIndicatorLocationAndAngle(roomcenter, targX, targZ, w, h)

        self:SetPosition(x, y, 0)
        self.x = x
        self.y = y
        self.angle = angle
        self:PositionArrow()
        self:PositionLabel()
    else
        return update_position(self, targX, targZ, ...)
    end
end

local get_avatar_atlas = TargetIndicator.GetAvatarAtlas
function TargetIndicator:GetAvatarAtlas(...)
    if self.target.prefab ~= "target_indicator_marker" then
        return get_avatar_atlas(self, ...)
    end

    if self.is_mod_character then
        local location = MOD_AVATAR_LOCATIONS["Default"]
        if MOD_AVATAR_LOCATIONS[self.target.marker_data.prefab] ~= nil then
            location = MOD_AVATAR_LOCATIONS[self.target.marker_data.prefab]
        end

        local starting = self.isGhost and "avatar_ghost_" or "avatar_"
        local ending =
            (self.isCharacterState1 and "_1" or "")..
            (self.isCharacterState2 and "_2" or "")..
            (self.isCharacterState3 and "_3" or "")

        return location..starting..self.target.marker_data.prefab..ending..".xml"
    end
    return self.config_data.atlas or DEFAULT_ATLAS
end

local get_avatar = TargetIndicator.GetAvatar
function TargetIndicator:GetAvatar(...)
    if self.target.prefab ~= "target_indicator_marker" then
        return get_avatar(self, ...)
    end

    local starting = self.isGhost and "avatar_ghost_" or "avatar_"
    local ending =
        (self.isCharacterState1 and "_1" or "")..
        (self.isCharacterState2 and "_2" or "")..
        (self.isCharacterState3 and "_3" or "")

    return starting .. self.target.marker_data.prefab .. ending .. ".tex"
end

AddClassPostConstruct("widgets/targetindicator", function(self)
    if self.target.prefab ~= "target_indicator_marker" then
        return
    end

    self.userflags = self.target.marker_data.userflags or 0
    self.isGhost = checkbit(self.userflags, USERFLAGS.IS_GHOST)
    self.isCharacterState1 = checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_1)
    self.isCharacterState2 = checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_2)
    self.isCharacterState3 = checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_3)

    self.is_mod_character = table.contains(MODCHARACTERLIST, self.target.marker_data.prefab)

    self.name = self.target.marker_data.display_name
    self.name_label:SetString(self.name)
end)
