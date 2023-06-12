local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Equippable = require("components/equippable")

function Equippable:IsPoisonBlocker()
    return self.poisonblocker or false
end

function Equippable:IsPoisonGasBlocker()
    return self.poisongasblocker or false
end

function Equippable:ToggleOn()
    self.toggled = true 
    if self.toggledonfn then 
        self.toggledonfn(self.inst)
    end 
end

function Equippable:ToggleOff()
    self.toggled = false 
    if self.toggledofffn then 
        self.toggledofffn(self.inst)
    end 
end  

function Equippable:IsToggledOn()
    return self.toggled 
end 

local _OnSave = Equippable.OnSave
function Equippable:OnSave(...)
    local data = _OnSave and _OnSave(self, ...) or{}
    data.togglable = self.togglable
    data.toggled = self.toggled
    return data
end   

local _LoadPostPass = Equippable.LoadPostPass
function Equippable:LoadPostPass(ents, data, ...)
    if data and data.togglable then 
        self.togglable = data.togglable
        self.toggled = data.toggled
        if self.toggledon then 
            self:ToggleOn()
        else
            self:ToggleOff()
        end
    end
    if _LoadPostPass then 
        return _LoadPostPass(ents, data, ...)
    end
end   

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

local function onboatequipslot(self, boatequipslot)
    self.inst.replica.equippable:SetBoatEquipSlot(boatequipslot)
end

local function ontoggled(self, toggled)
    if toggled then
        self.inst:AddTag("toggled")
    else
        self.inst:RemoveTag("toggled")
    end
end

local function ontogglable(self, togglable)
    if togglable then
        self.inst:AddTag("togglable")
    else
        self.inst:RemoveTag("togglable")
    end
end

IAENV.AddComponentPostInit("equippable", function(cmp)
    addsetter(cmp, "boatequipslot", onboatequipslot)
    addsetter(cmp, "toggled", ontoggled)
    addsetter(cmp, "togglable", ontogglable)

    cmp.toggled = false
    cmp.togglable = false
end)
