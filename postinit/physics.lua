GLOBAL.setfenv(1, GLOBAL)

local physics_to_entity = {}

local function clean_up_mapping(inst)
    if inst.Physics then
        physics_to_entity[inst.Physics] = nil
    end
end

local _AddPhysics = Entity.AddPhysics
function Entity:AddPhysics(...)
    local physics = _AddPhysics(self, ...)

    local guid = self:GetGUID()
    local inst = Ents[guid]
    physics_to_entity[physics] = inst
    inst:ListenForEvent("onremove", clean_up_mapping)

    return physics
end

Physics.Old_SetVel = Physics.SetVel

local _SetVel = Physics.SetVel
Physics.SetVel = function(self, x, y, z, ...)
    local inst = physics_to_entity[self]
    if inst and inst.components and inst.components.inventoryitem then
        if x ~= 0 or y ~= 0 or z~= 0 then
            inst.components.inventoryitem:SetLanded(false, true)
        end
    end
    return _SetVel(self, x, y, z, ...)
end