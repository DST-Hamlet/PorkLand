GLOBAL.setfenv(1, GLOBAL)

local icon_name = {}
local icon_priority = {}
local icon_offset = {}

local _SetIcon = MiniMapEntity.SetIcon
function MiniMapEntity:SetIcon(icon, ...)
    icon_name[self] = icon
    return _SetIcon(self, icon, ...)
end

function MiniMapEntity:GetIcon() -- TODO: compatible test
    return icon_name[self]
end

local _SetPriority = MiniMapEntity.SetPriority
function MiniMapEntity:SetPriority(priority, ...)
    icon_priority[self] = priority
    return _SetPriority(self, priority, ...)
end

function MiniMapEntity:GetPriority()
    return icon_priority[self]
end

function MiniMapEntity:SetIconOffset(x, y)
    icon_offset[self] = {x, y}
end

function MiniMapEntity:GetIconOffset()
    return unpack(icon_offset[self] or {})
end
