GLOBAL.setfenv(1, GLOBAL)

local Container = require("components/container_replica")

function Container:GetItemInBoatSlot(eslot)
    if not self.hasboatequipslots then
        return
    end

    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInBoatSlot(eslot)
    else
        if self.classified ~= nil then
            if eslot == BOATEQUIPSLOTS.BOAT_SAIL then
                return self.classified:GetItemInSlot(1)
            elseif eslot == BOATEQUIPSLOTS.BOAT_LAMP then
                return self.classified:GetItemInSlot(2)
            end
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