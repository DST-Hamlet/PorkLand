GLOBAL.setfenv(1, GLOBAL)

local icon_name = {}
local icon_priority = {}
local icon_can_use_cache = {}
local icon_offset = {}
local icon_is_proxy = {}
local icon_restriction = {}
local minimap_entity_to_entity = {}

local function cleanup_mapping(inst)
    icon_name[inst.MiniMapEntity] = nil
    icon_priority[inst.MiniMapEntity] = nil
    icon_can_use_cache[inst.MiniMapEntity] = nil
    icon_offset[inst.MiniMapEntity] = nil
    icon_is_proxy[inst.MiniMapEntity] = nil
    minimap_entity_to_entity[inst.MiniMapEntity] = nil
end

local add_minimap_entity = Entity.AddMiniMapEntity
function Entity:AddMiniMapEntity(...)
    local minimap_entity = add_minimap_entity(self, ...)

    local guid = self:GetGUID()
    local inst = Ents[guid]
    minimap_entity_to_entity[minimap_entity] = inst
    inst:ListenForEvent("onremove", cleanup_mapping)

    return minimap_entity
end

local _SetIcon = MiniMapEntity.SetIcon
function MiniMapEntity:SetIcon(icon, ...)
    icon_name[self] = icon
    return _SetIcon(self, icon, ...)
end

local _CopyIcon = MiniMapEntity.CopyIcon
function MiniMapEntity:CopyIcon(minimap_entity, ...)
    icon_name[self] = minimap_entity:GetIcon()
    return _CopyIcon(self, minimap_entity, ...)
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

local set_is_proxy = MiniMapEntity.SetIsProxy
function MiniMapEntity:SetIsProxy(is_proxy, ...)
    icon_is_proxy[self] = is_proxy
    if TheWorld.ismastersim and TheWorld.components.interiormaprevealer then
        local entity = minimap_entity_to_entity[self]
        if is_proxy then
            TheWorld.components.interiormaprevealer:TrackEntity(entity)
        else
            TheWorld.components.interiormaprevealer:UntrackEntity(entity)
        end
    end
    return set_is_proxy(self, is_proxy, ...)
end

function MiniMapEntity:GetIsProxy()
    return icon_is_proxy[self]
end

local set_restriction = MiniMapEntity.SetRestriction
function MiniMapEntity:SetRestriction(restriction, ...)
    if restriction == "" then
        icon_restriction[self] = nil
    else
        icon_restriction[self] = restriction
    end
    return set_restriction(self, restriction, ...)
end

function MiniMapEntity:GetRestriction()
    return icon_restriction[self]
end

function MiniMapEntity:SetIconOffset(x, y)
    icon_offset[self] = {x, y}
end

function MiniMapEntity:GetIconOffset()
    return unpack(icon_offset[self] or {})
end
