-- component that record infomations about player interior status
local CC_DEF_INDEX = require("main/interior_texture_defs").CC_DEF_INDEX

local function on_x(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_pos_x:set(math.floor(value + 0.5))
    end
end

local function on_z(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_pos_z:set(math.floor(value + 0.5))
    end
end

local function on_center_ent(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.center_ent:set(value)
    end
end

local function on_interior_cc(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.interior_cc:set(CC_DEF_INDEX[value] or 0)
    end
end

local InteriorVisitor = Class(function(self, inst)
    self.inst = inst
    self.exterior_pos_x = 0
    self.exterior_pos_z = 0
    self.interior_cc = "images/colour_cubes/day05_cc.tex"
    self.center_ent = nil
    self.visited_uuid = {}

    -- self.restore_physics_task = nil

    self.last_mainland_pos = nil

    -- for wortox
    inst:ListenForEvent("soulhop", function()
        if inst.replica.interiorvisitor then
            inst.replica.interiorvisitor.resetinteriorcamera:push()
        end
    end)
end, nil,
{
    exterior_pos_x = on_x,
    exterior_pos_z = on_z,
    center_ent = on_center_ent,
    interior_cc = on_interior_cc,
})

local function BitAND(a,b)
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra,rb = a%2,b%2
        if ra + rb >1 then c = c + p end
        a, b, p = (a-ra)/2, (b-rb)/2, p*2
    end
    return c
end

function InteriorVisitor:UpdatePlayerAndCreaturePhysics(ent)
    local center = ent:GetPosition()
    local radius = ent:GetSearchRadius()
    for _,v in ipairs(TheSim:FindEntities(center.x, 0, center.z, radius, nil, {"INLIMBO", "pl_invisiblewall"}))do
        if v.Physics ~= nil and v.Physics:GetCollisionGroup() ~= COLLISION.OBSTACLES then
            self:TunePhysics(v, ent)
        end
    end
end

function InteriorVisitor:TunePhysics(inst, ent)
    if inst and inst:IsValid() and inst.Physics ~= nil then
        local player_pos = inst:GetPosition()
        local center_pos = ent:GetPosition()
        local offset = center_pos - player_pos
        local size = { ent:GetSize() }
        if (math.abs(offset.x) > size[2]/2 + 1 or math.abs(offset.z) > size[1]/2 + 1)
            and #(TheSim:FindEntities(player_pos.x, 0, player_pos.z, 2, {"pl_invisiblewall"})) > 0 then
            local mask = inst.Physics:GetCollisionMask()
            if BitAND(mask, COLLISION.OBSTACLES) > 0 then
                inst.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
                self:DelayRestorePhysics(inst, .4)
            end
        end
    end
end


function InteriorVisitor:DelayRestorePhysics(inst, delay)
    if inst.interiorvisitor_restore_physics_task then
        inst.interiorvisitor_restore_physics_task:Cancel()
    end

    inst.interiorvisitor_restore_physics_task = inst:DoTaskInTime(delay or 1, function()
        if inst.Physics then
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        end
    end)
end

function InteriorVisitor:RecordUUID(id)
    self.visited_uuid[id] = true
end

function InteriorVisitor:IsVisited(id)
    return self.visited_uuid[id] == true
end

function InteriorVisitor:UpdateExteriorPos()
    local spawner = TheWorld.components.interiorspawner
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local ent = spawner:GetInteriorCenterAt_Generic(x, z)
    self.center_ent = ent

    local grue = self.inst.components.grue or {}

    if ent then
        self.inst:AddTag("inside_interior")
        self.interior_cc = ent.interior_cc
        grue.pl_no_light_interior = --[[ent:HasInteriorTag("NO_LIGHT") or]] true
        if grue.pl_no_light_interior then
            self.inst:AddTag("pl_no_light_interior")
            grue:Start()
        else
            self.inst:RemoveTag("pl_no_light_interior")
        end
        self:UpdatePlayerAndCreaturePhysics(ent)
        if ent.uuid then
            self:RecordUUID(ent.uuid)
        end

        local single, door = ent:GetIsSingleRoom() -- check if this room is single, if so, get the unique exit
        if single then
            local house = spawner:GetExteriorById(door.components.door.interior_name)
            if house ~= nil then
                local x, _, z = house.Transform:GetWorldPosition()
                -- when opening minimap inside a single room,
                -- focus on exterior house position
                self.exterior_pos_x = x
                self.exterior_pos_z = z
                return
            end
        end
    else
        self.inst:RemoveTag("inside_interior")
        grue.pl_no_light_interior = false
        self.inst:RemoveTag("pl_no_light_interior")

        if not spawner:IsInInteriorRegion(x, z) then
            self.last_mainland_pos = {x = x, z = z}
        end
    end

    self.exterior_pos_x = 0
    self.exterior_pos_z = 0
end

function InteriorVisitor:OnSave()
    return {
        visited_uuid = self.visited_uuid,
        last_mainland_pos = self.last_mainland_pos,
    }
end

function InteriorVisitor:OnLoad(data)
    if data.visited_uuid then
        self.visited_uuid = data.visited_uuid
    end
    if data.last_mainland_pos then
        self.last_mainland_pos = data.last_mainland_pos
    end

    -- restore player position if interior was destroyed
    if GetTick() > 0 and self.last_mainland_pos ~= nil then
        local x, _, z = self.inst.Transform:GetWorldPosition()
        if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
            and not TheWorld.components.interiorspawner:IsInInterior(x, z) then
            self.inst.Transform:SetPosition(self.last_mainland_pos.x, 0, self.last_mainland_pos.z)
        end
    end
end

return InteriorVisitor
