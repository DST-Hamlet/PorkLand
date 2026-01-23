local function OnBoatDelta(boat, data) -- Listen for boat taking damage, talk if it is!
    if data and boat.components.sailable and boat.components.sailable.sailor then
        local sailor = boat.components.sailable.sailor
        local old = data.oldpercent
        local new = data.percent
        local message = nil
        for _, threshold in ipairs(sailor.components.sailor.warningthresholds) do
            if old > threshold.percent and new <= threshold.percent then
                message = threshold.string
            end
        end

        if message then
            boat.components.sailable.sailor:PushEvent("boat_damaged", {message = message})
        end
    end
end

local function OnBoostByWave(inst, data)
    if inst.sg:HasStateTag("boating") then

        local boost = TUNING.WAVEBOOST
        if inst.components.sailor and inst.components.sailor:GetBoat() then

            if inst.components.sailor:GetBoat().waveboost then
                boost = data.boost or inst.components.sailor:GetBoat().waveboost
            end
        end

        if inst.components.sailor then
            inst.components.sailor.boatspeed = inst.components.sailor.boatspeed + boost
        end
    end
end

local function onboat(self, boat)
    if self.inst.replica.sailor then
        self.inst.replica.sailor._boat:set(boat)
    end
end

local function onsailing(self, sailing)
    if sailing then
        self.inst:AddTag("sailor")
    else
        self.inst:RemoveTag("sailor")
    end
end

local Sailor = Class(function(self, inst)
    self.inst = inst
    self.boat = nil
    self.sailing = false

    self.durabilitymultiplier = 1.0
    self.warningthresholds =  -- Moved these back to sailor from wisecracker -Z
    {
        { percent = 0.5, string = "ANNOUNCE_BOAT_DAMAGED" },
        { percent = 0.3, string = "ANNOUNCE_BOAT_SINKING" },
        { percent = 0.1, string = "ANNOUNCE_BOAT_SINKING_IMMINENT" },
    }

    self.acceleration = 6 -- 目前是固定值
    self.deceleration = 6 -- 目前是固定值
    self.boatspeed = 0
    self.perdictframe = 0

    self.inst:ListenForEvent("boostbywave", OnBoostByWave)
end,
nil,
{
    boat = onboat,
    sailing = onsailing,
})

function Sailor:IsSailing()
    return self.sailing and self.boat ~= nil
end

function Sailor:GetBoat()
    return self.boat
end

function Sailor:AlignBoat(direction)
    if self.boat then
        self.boat.Transform:SetRotation(direction or self.inst.Transform:GetRotation())
    end
end

function Sailor:GetDeceleration()
    local modifier = 1 + self.boat.components.sailable:GetExternalAccelerationMultiplier()

    return self.deceleration * modifier
end

function Sailor:GetAcceleration()
    local modifier = 1 + self.boat.components.sailable:GetExternalAccelerationMultiplier()

    return self.acceleration * modifier
end

function Sailor:OnUpdate(dt)
    if self.boat ~= nil and self.boat:IsValid() then
        if self.boat.components.boathealth then
            self.boat.components.boathealth.depletionmultiplier = 1.0 / self.durabilitymultiplier
        end

        if self.boat.replica.sailable and self.inst.replica.sailor then
            local current_speed = self.boatspeed
            local target_speed = self.boat.components.sailable.externalspeedmultiplier + 6
            local deceleration = self:GetDeceleration()
            local acceleration = self:GetAcceleration()

            if not self.inst.sg:HasStateTag("boating") then
                self.perdictframe = self.perdictframe - 1
            else
                self.perdictframe = 1
            end
            if self.perdictframe <= 0 then
                self.perdictframe = 0
                target_speed = 1
            end

            if(target_speed > current_speed) then
                current_speed = current_speed + acceleration * dt
                if(current_speed > target_speed) then
                   current_speed = target_speed
               end
            elseif (target_speed < current_speed) then
                current_speed = current_speed - deceleration * dt
            end

            if(current_speed < 1) then
                current_speed = 1
            end

            self.boatspeed = current_speed
            self.inst.replica.sailor._currentspeed:set(current_speed)
        end

        local pos = self.inst:GetPosition()
        local x, y, z = pos:Get()
        if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) then
            self.last_pos = pos
        else
            local target_pos = Vector3(x, y, z)
            self:Disembark(target_pos, nil, true, self.last_pos)
        end
    else
        self.boatspeed = 0
    end
end

-- This needs to save, because we're removing the boat from the scene
-- to prevent the player from dying upon logging back in.
function Sailor:OnSave()
    local data = {}
    if self.boat ~= nil and self.boat.persists then
        data.boat = self.boat:GetSaveRecord()
        data.boat.prefab = self.boat.actualprefab or self.boat.prefab
    end
    return data
end

function Sailor:OnLoad(data)
    if data and data.boat ~= nil then
        local boat = SpawnSaveRecord(data.boat)
        if boat then
            self:Embark(boat, true)
        end
    end
end

function Sailor:Embark(boat, nostate)
    if not boat or not boat.components.sailable then
        return
    end

    self.sailing = true
    self.boat = boat

    self.last_pos = boat:GetPosition()
    self.boatspeed = 0

    self.inst.AnimState:OverrideSymbol("droplet", "flotsam_debris_lograft_build", "droplet")
    if self.boat.components.sailable.flotsambuild then
        self.inst.AnimState:OverrideSymbol("flotsam", self.boat.components.sailable.flotsambuild, "flotsam")
    end

    self.inst:AddTag("sailing")
    if not nostate then
        self.inst.sg:GoToState("jumpboatland")
    end

    self.inst:AddChild(self.boat)
    if self.boat.components.highlightchild then
        self.boat.components.highlightchild:SetOwner(self.inst)
    end
    if self.inst.components.colouradder then
        self.inst.components.colouradder:AttachChild(self.boat)
    end
    if self.inst.components.eroder then
        self.inst.components.eroder:AttachChild(self.boat)
    end

    local x, y, z = 0, 0, 0
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

    UpdateSailorPathcaps(self.inst, true)

    self.inst:ListenForEvent("boathealthchange", OnBoatDelta, boat)

    if self.boat.components.boathealth then
        local percent = boat.components.boathealth:GetPercent()
        OnBoatDelta(boat, {oldpercent = 1, percent = percent})
    end

    -- dst no this
    -- if self.inst.components.farseer and boat.components.sailable and boat.components.sailable:GetMapRevealBonus() then
    --     self.inst.components.farseer:AddBonus("boat", boat.components.sailable:GetMapRevealBonus())
    -- end

    if self.OnEmbarked then
        self.OnEmbarked(self.inst)
    end

    self.inst:PushEvent("embarkboat", {target = self.boat})

    if self.boat.components.sailable then
        self.boat.components.sailable:OnEmbarked(self.inst)
    end

    self.inst:StartUpdatingComponent(self)
end

function Sailor:Disembark(pos, boat_to_boat, no_state, boat_pos)
    self.sailing = false
    self.boatspeed = 0

    self.inst:StopUpdatingComponent(self)

    self.last_pos = nil

    UpdateSailorPathcaps(self.inst, false)

    self.inst:RemoveEventCallback("boathealthchange", OnBoatDelta, self.boat)

    -- dst no this
    -- if self.inst.components.farseer then
    --     self.inst.components.farseer:RemoveBonus("boat")
    -- end

    if self.boat ~= nil then
        self.inst:RemoveChild(self.boat)
    
        if self.boat.components.highlightchild then
            self.boat.components.highlightchild:SetOwner(nil)
        end
        if self.inst.components.colouradder then
            self.boat.AnimState:SetAddColour(0, 0, 0, 0) -- clear freezable effects etc
            self.inst.components.colouradder:DetachChild(self.boat)
        end
        if self.inst.components.eroder then
            self.inst.components.eroder:DetachChild(self.boat)
        end

        local x, y, z = self.inst.Transform:GetWorldPosition()
        if boat_pos then
            x, y, z = boat_pos:Get()
        end
        self.inst.Physics:Stop()
        self.inst.components.locomotor:StopMoving()
        if no_state and pos then
            self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)
        else
            self.inst.Transform:SetPosition(x, y, z)
        end

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
    end

    self.inst:RemoveTag("sailing")

    if self.OnDisembarked then
        self.OnDisembarked(self.inst, boat_to_boat)
    end

    self.inst:PushEvent("disembarkboat", {target = self.boat, pos = pos, boat_to_boat = boat_to_boat})

    if self.boat and self.boat.components.sailable then
        self.boat.components.sailable:OnDisembarked(self.inst)
    end

    self.boat = nil

    if not no_state then
        if pos then
            self.inst.sg:GoToState("jumpoffboatstart", pos)
        elseif boat_to_boat then
            self.inst.sg:GoToState("jumponboatstart")
        end
    end
end

return Sailor
