local function onsailing(self, sailing)
    if sailing then
        self.inst:AddTag("sailor")
    else
        self.inst:RemoveTag("sailor")
    end
end

local Sailor = Class(function(self, inst)
    self.inst = inst
    self.sailing = false
end,
nil,
{
    -- boat = onboat,
    sailing = onsailing,
})

function Sailor:IsSailing()
    return self.sailing
end

function Sailor:GetBoat()
    return self.boat
end

function Sailor:AlignBoat(direction)
    if self.boat then
        self.boat.Transform:SetRotation(direction or self.inst.Transform:GetRotation())
    end
end

function Sailor:Embark(boat, nostate)
    if not boat or not boat.components.sailable then
        return
    end

    self.sailing = true
    self.boat = boat

    -- if self.boat.components.sailable.flotsambuild then
    --     self.inst.AnimState:OverrideSymbol("flotsam", self.boat.components.sailable.flotsambuild, "flotsam")
    -- end

    self.inst:AddTag("sailing")
    if not nostate then
        self.inst.sg:GoToState("jumpboatland")
    end

    self.inst:AddChild(self.boat)
    if self.inst.components.colouradder then
        self.inst.components.colouradder:AttachChild(self.boat)
    end
    if self.inst.components.eroder then
        self.inst.components.eroder:AttachChild(self.boat)
    end

    local x, y, z = 0, -0.1, 0
    local offset = self.boat.components.sailable.offset
    if offset ~= nil then
        x = x + offset.x
        y = y + offset.y
        z = z + offset.z
    end

    if self.boat.Physics then
        self.boat.Physics:Teleport(x, y, z)
    else
        self.boat.Transform:SetPosition(x, y, z)
    end
    self.boat.Transform:SetRotation(0)

    if self.OnEmbarked then
        self.OnEmbarked(self.inst)
    end

    self.inst:PushEvent("embarkboat", {target = self.boat})

    if self.boat.components.sailable then
        self.boat.components.sailable:OnEmbarked(self.inst)
    end
end

function Sailor:Disembark(pos, boat_to_boat, nostate)
    self.sailing = false
    -- self.inst:StopUpdatingComponent(self)

    self.inst:RemoveChild(self.boat)

    if self.inst.components.colouradder then
        self.inst.components.colouradder:DetachChild(self.boat)
    end

    if self.inst.components.eroder then
        self.inst.components.eroder:DetachChild(self.boat)
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local offset = self.boat.components.sailable.offset
    if offset ~= nil then
        x = x + offset.x
        y = y + offset.y
        z = z + offset.z
    end
    if self.boat.Physics then
        self.boat.Physics:Teleport(x, y, z)
    else
        self.boat.Transform:SetPosition(x, y, z)
    end
    self:AlignBoat()

    self.inst:RemoveTag("sailing")

    if self.OnDisembarked then
        self.OnDisembarked(self.inst, boat_to_boat)
    end

    self.inst:PushEvent("disembarkboat", {target = self.boat, pos = pos, boat_to_boat = boat_to_boat})

    if self.boat.components.sailable then
        self.boat.components.sailable:OnDisembarked(self.inst)
    end

    self.boat = nil

    if not nostate then
        if pos then
            self.inst.sg:GoToState("jumpoffboatstart", pos)
        elseif boat_to_boat then
            self.inst.sg:GoToState("jumponboatstart")
        end
    end
end

return Sailor
