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

function Sailor:Embark(boat, nostate)
    if not boat or not boat.components.sailable then
        return
    end

    self.sailing = true
    self.boat = boat

    self.inst:AddChild(self.boat)

    -- if self.boat.components.sailable.flotsambuild then
    --     self.inst.AnimState:OverrideSymbol("flotsam", self.boat.components.sailable.flotsambuild, "flotsam")
    -- end

    if not nostate then
        self.inst.sg:GoToState("jumpboatland")
    end

    self.boat.components.sailable:OnEmbarked(self.inst)

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
end

return Sailor
