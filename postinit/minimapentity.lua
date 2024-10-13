GLOBAL.setfenv(1, GLOBAL)

local icon_name = {}
local icon_priority = {}
local icon_can_use_cache = {}
local icon_offset = {}

function PorkLandOnMiniMapEntityRemove(inst)
    icon_name[inst.MiniMapEntity] = nil
    icon_priority[inst.MiniMapEntity] = nil
    icon_can_use_cache[inst.MiniMapEntity] = nil
    icon_offset[inst.MiniMapEntity] = nil
end

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

local _SetCanUseCache = MiniMapEntity.SetCanUseCache
function MiniMapEntity:SetCanUseCache(can_use, ...)
    icon_can_use_cache[self] = can_use
    return _SetCanUseCache(self, can_use, ...)
end

function MiniMapEntity:GetCanUseCache()
    -- Cacheable by default, so nil is true
    return icon_can_use_cache[self] ~= false
end

function MiniMapEntity:SetIconOffset(x, y)
    icon_offset[self] = {x, y}
end

function MiniMapEntity:GetIconOffset()
    return unpack(icon_offset[self] or {})
end
