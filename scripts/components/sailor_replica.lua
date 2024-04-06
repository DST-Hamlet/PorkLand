local function OnBoatAttacked(inst)
    inst.replica.sailor.boatattackedevent:set_local(true)
    inst.replica.sailor.boatattackedevent:set(true)
end

local function OnBoatDirty(sailor)
    if not TheWorld.ismastersim then
        sailor.inst:PushEvent("disembarkboat")
    end

    if sailor._currentboat and sailor._currentboat:IsValid() then

        sailor._currentboat.prefab = sailor._currentboat.actualprefab
        sailor._currentboat.actualprefab = nil
        sailor._currentboat.nameoverride = nil

        -- RemoveLocalNOCLICK(sailor._currentboat)
    end
    if sailor._boat:value() then
        sailor._currentboat = sailor._boat:value()

        sailor._currentboat.actualprefab = sailor._currentboat.prefab
        sailor._currentboat.prefab = "player_"..sailor._currentboat.actualprefab
        sailor._currentboat.nameoverride = sailor._currentboat.actualprefab

        if sailor.inst == ThePlayer then
            -- LocalNOCLICK(sailor._currentboat)
        end

        if not TheWorld.ismastersim then
            sailor.inst:PushEvent("embarkboat", {target = sailor._currentboat})
        end
        if not TheNet:IsDedicated() and sailor.inst == ThePlayer then
            sailor.inst:PushEvent("playboatmusic")
        end
        -- if sailor.inst.components.locomotor and not sailor.inst.components.locomotor:IsAmphibious() then
        --     sailor.inst.components.locomotor.pathcaps = sailor.inst.components.locomotor.pathcaps or {}
        --     sailor.inst.components.locomotor.pathcaps.ignoreLand = true
        --     sailor.inst.components.locomotor.pathcaps.allowocean = true
        -- end
    else
        if not TheNet:IsDedicated() and sailor.inst == ThePlayer then
            sailor.inst:PushEvent("stopboatmusic")
        end
        -- if sailor.inst.components.locomotor and not sailor.inst.components.locomotor:IsAmphibious() then
        --     sailor.inst.components.locomotor.pathcaps = sailor.inst.components.locomotor.pathcaps or {}
        --     sailor.inst.components.locomotor.pathcaps.ignoreLand = false
        --     sailor.inst.components.locomotor.pathcaps.allowocean = false
        -- end
        sailor._currentboat = nil
    end
end

local function OnBoatDirty_inst(inst)
    return OnBoatDirty(inst.replica.sailor)
end

local Sailor = Class(function(self, inst)
    self.inst = inst

    self._boat = net_entity(inst.GUID, "sailor._boat", "boatdirty")
    --boatattacked event only on remote clients
    self.boatattackedevent = net_bool(inst.GUID, "boathealth.boatattackedevent", not TheWorld.ismastersim and "boatattacked" or nil)

    self.inst:DoTaskInTime(0, function()
        self.inst:ListenForEvent("boatdirty", function()
            OnBoatDirty(self)
            self.inst:DoTaskInTime(1, OnBoatDirty_inst)
        end)
        OnBoatDirty(self)
    end)

<<<<<<< Updated upstream
=======
    self._currentspeed = net_float(inst.GUID, "sailor._currentspeed")
    self._currentspeed:set(1)

>>>>>>> Stashed changes
    if TheWorld.ismastersim then
        inst:ListenForEvent("boatattacked", OnBoatAttacked)
    end
end)

-- not in use, but leaving here since it doesn't really cause problems
function Sailor:IsSailing()
    return self.inst:HasTag("sailing")
end

function Sailor:GetBoat()
    if self.inst.components.sailor then
        return self.inst.components.sailor:GetBoat()
    end

    return self._currentboat
end

function Sailor:GetBoatHealth()
    local boat = self:GetBoat()
    return boat and boat.replica.boathealth and boat.replica.boathealth:GetPercent() or nil
end

function Sailor:AlignBoat(direction)
    if self.inst.components.sailor then
        self.inst.components.sailor:AlignBoat(direction)
    else
        local boat = self:GetBoat()
        if boat then
            boat.Transform:SetRotation(direction or self.inst.Transform:GetRotation())
        end
    end
end

return Sailor
