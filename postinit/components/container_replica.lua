local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container_replica")

function Container:ChangeBoatType(has_sailor)
    if self.type ~= "boat" and self.type ~= "boat_has_sailor" then
        return
    end
    if has_sailor then
        self.type = "boat_has_sailor"
    else
        self.type = "boat"
    end
end

function Container:GetItemInBoatSlot(eslot)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInBoatSlot(eslot)
    else
        if self.classified ~= nil then
            local slot = self.boatcontainerequips[eslot]
            if slot == nil then
                return
            end

            return self.classified:GetItemInSlot(slot)
        end
    end
end

local _GetWidget = Container.GetWidget
function Container:GetWidget(boatwidget)
    if not boatwidget then
        return _GetWidget(self)
    else
        return self.inspectwidget
    end
end

AddClassPostConstruct("components/container_replica", function(self)
    self._has_sailor = net_bool(self.inst.GUID, "container._has_sailor", TheWorld.ismastersim and "has_sailor_dirty" or nil)
    self.inst:ListenForEvent("has_sailor_dirty", function(inst, has_sailor) self:ChangeBoatType(self._has_sailor:value()) end)
end)