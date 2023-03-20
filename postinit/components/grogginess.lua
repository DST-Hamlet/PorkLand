local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Grogginess = require("components/grogginess")

local _OnUpdate = Grogginess.OnUpdate
function Grogginess:OnUpdate(...)
    if self.grog_amount <= 0 and self.foggygroggy and self:HasOverHeatinggear() then  -- not TheCamera.interior
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

function Grogginess:HasOverHeatinggear()
    if self.inst:HasTag("venting") then
        return
    elseif self.inst.components.inventory then
        if self.inst.components.inventory:EquipHasTag("venting") then
            return
        end

        local hotitems = {}
        for esslot, item in pairs(self.inst.components.inventory.equipslots) do
            if esslot ~= EQUIPSLOTS.HANDS and not item:HasTag("vented") then
                table.insert(hotitems, item)
            end
        end

        if #hotitems > 0 then
            return hotitems
        else
            if self.inst:HasTag("groggy") then
                self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_DEHUMID"))
            end
        end
    end
end

function Grogginess:OnEquip(data)
    if not self.foggygroggy then
        return
    end

    self.inst:StartUpdatingComponent(self)

    local hotitems = self:HasOverHeatinggear()
    if hotitems and #hotitems > 0 then
        local string = hotitems[1].name
        if data and data.item then
            string = nil
            for eslot, item in ipairs(hotitems)do
                if item == data.item then
                    string = item.name
                    break
                end
            end
        end
        if string then
            self.inst.components.talker:Say(string.format(GetString(self.inst, "ANNOUNCE_TOO_HUMID"), string))
        end
    end
end

function Grogginess:SetFogyGroggy(enable)
    self.foggygroggy = enable
    if enable and not self.inst:HasTag("groggy") then
        self.inst:StartUpdatingComponent(self)
        self:OnEquip()
    end
end

AddComponentPostInit("grogginess", function(self, inst)
    self.foggygroggy = false

    inst:ListenForEvent("equip", function(inst, data) self:OnEquip(data) end)
    inst:WatchWorldState("fullfog", function(src, fullfog) self:SetFogyGroggy(fullfog) end)
    self:SetFogyGroggy(TheWorld.state.fullfog)
end)
