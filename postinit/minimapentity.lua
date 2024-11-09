GLOBAL.setfenv(1, GLOBAL)

local icon_name = {}
local icon_priority = {}
local icon_can_use_cache = {}
local icon_offset = {}
local icon_can_draw_over_fog = {}
local minimap_entity_to_entity = {}

local function cleanup_mapping(inst)
    icon_name[inst.MiniMapEntity] = nil
    icon_priority[inst.MiniMapEntity] = nil
    icon_can_use_cache[inst.MiniMapEntity] = nil
    icon_offset[inst.MiniMapEntity] = nil
    icon_can_draw_over_fog[inst.MiniMapEntity] = nil
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

local set_draw_over_fog_of_war = MiniMapEntity.SetDrawOverFogOfWar
function MiniMapEntity:SetDrawOverFogOfWar(can_draw_over, ...)
    icon_can_draw_over_fog[self] = can_draw_over
    local entity = minimap_entity_to_entity[self]
    if can_draw_over then
        TheWorld.components.interiormaprevealer:TrackEntity(entity)
    else
        TheWorld.components.interiormaprevealer:UntrackEntity(entity)
    end
    return set_draw_over_fog_of_war(self, can_draw_over, ...)
end

-- function MiniMapEntity:GetCanDrawOverFogOfWar()
--     return icon_can_draw_over_fog[self]
-- end

function MiniMapEntity:SetIconOffset(x, y)
    icon_offset[self] = {x, y}
end

function MiniMapEntity:GetIconOffset()
    return unpack(icon_offset[self] or {})
end
