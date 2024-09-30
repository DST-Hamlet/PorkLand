local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Grogginess = require("components/grogginess")

local _OnUpdate = Grogginess.OnUpdate
function Grogginess:OnUpdate(...)
    if self.grog_amount <= 0 and self.foggygroggy then  -- not TheCamera.interior
        if not self.inst:HasTag("groggy") then
            self.inst:AddTag("groggy")
        end

        if self.whilegroggyfn ~= nil then
            self.whilegroggyfn(self.inst)
        end
    else
        _OnUpdate(self, ...)
    end
end

local _RemoveEventCallback = Grogginess.OnRemoveFromEntity
function Grogginess:OnRemoveFromEntity(...)
    self.inst:RemoveEventCallback("equip", self.OnFogProofChange)
    self.inst:RemoveEventCallback("unequip", self.OnFogProofChange)
    self.inst:RemoveEventCallback("enterinterior", self.OnFogProofChange)
    self.inst:RemoveEventCallback("leaveinterior", self.OnFogProofChange)
    self.foggygroggy = false

    _RemoveEventCallback(self, ...)
end

function Grogginess:HasOverHeatinggear()
    if self.inst:HasTag("venting") then
        return
    elseif self.inst.components.inventory then
        if self.inst.components.inventory:EquipHasTag("venting") then
            return
        end

        local hotitems = {}
        for esslot, item in pairs(self.inst.components.inventory.equipslots) do
            if (esslot ~= EQUIPSLOTS.HANDS and esslot ~= EQUIPSLOTS.BEARD) and
            not (item:HasTag("vented") or item:HasTag("heavy")) then  -- Heacy item don't grogginess, Because had
                table.insert(hotitems, item)
            end
        end

        if #hotitems > 0 then
            return hotitems
        end
    end
end

function Grogginess.OnFogProofChange(inst, data)
    local self = inst.components.grogginess

    if not self then
        return
    end

    local hotitems = self:HasOverHeatinggear()

    if self.foggygroggy then
        self.foggygroggy = TheWorld.state.fullfog and hotitems ~= nil and not self.inst:GetIsInInterior()  -- if equip venting

        if not self.foggygroggy then
            if inst.components.talker then
                inst.components.talker:Say(GetString(inst, "ANNOUNCE_DEHUMID"))
            end
            return
        end
    end

    self.foggygroggy = TheWorld.state.fullfog and hotitems ~= nil and not self.inst:GetIsInInterior()

    if not self.foggygroggy then
        return
    end

    inst:StartUpdatingComponent(self)

    local name = hotitems[1]:GetBasicDisplayName()
    if hotitems then
        if data and data.item then
            name = nil
            for eslot, item in ipairs(hotitems) do
                if item == data.item then
                    name = item.name
                    break
                end
            end
        end
        if name and inst.components.talker then
            if name == "MISSING NAME" then
                name = hotitems[1]:GetDisplayName()
            end
            inst.components.talker:Say(string.format(GetString(inst, "ANNOUNCE_TOO_HUMID"), name))
        end
    end
end

function Grogginess.SetFogyGroggy(inst, enable)
    local self = inst.components.grogginess

    if not self then
        return
    end

    if enable then
        inst:ListenForEvent("equip", self.OnFogProofChange)
        inst:ListenForEvent("unequip", self.OnFogProofChange)
        inst:ListenForEvent("enterinterior", self.OnFogProofChange)
        inst:ListenForEvent("leaveinterior", self.OnFogProofChange)
        self.OnFogProofChange(inst)
    else
        inst:RemoveEventCallback("equip", self.OnFogProofChange)
        inst:RemoveEventCallback("unequip", self.OnFogProofChange)
        inst:RemoveEventCallback("enterinterior", self.OnFogProofChange)
        inst:RemoveEventCallback("leaveinterior", self.OnFogProofChange)
        self.OnFogProofChange(inst)
    end
end

AddComponentPostInit("grogginess", function(self, inst)
    self.foggygroggy = false

    inst:WatchWorldState("fullfog", self.SetFogyGroggy)
    self.SetFogyGroggy(self.inst, TheWorld.state.fullfog)
end)
