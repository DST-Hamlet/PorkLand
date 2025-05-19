GLOBAL.setfenv(1, GLOBAL)

local Rider_Replica = require("components/rider_replica")

local GetPickupAction, i, ActionButtonOverride = ToolUtil.GetUpvalue(Rider_Replica.SetActionFilter, "ActionButtonOverride.GetPickupAction")
if GetPickupAction then
    debug.setupvalue(ActionButtonOverride, i, function(self, target, tool, ...)
        if target:HasTag("smolder") then
            return ACTIONS.SMOTHER
        elseif tool ~= nil then
            for action, _ in pairs(TOOLACTIONS) do
                if target:HasTag(action .. "_workable") then
                    if tool:HasTag(action .. "_tool") then
                        return ACTIONS[action]
                    end
                    -- break
                end
            end
        end

        return GetPickupAction(self, target, tool, ...)
    end)
end

function Rider_Replica:GetMountSpeedMultiplier()
    local multiplier = 1
    local mount = self:GetMount()

    if mount and mount.components.locomotor ~= nil then
        multiplier = mount.components.locomotor:GetSpeedMultiplier()
    elseif self.classified ~= nil then
        multiplier = self.classified.riderspeedmultiplier:value()
    end

    return multiplier
end

function Rider_Replica:SetMountSpeedMultiplier(multiplier)
    if self.classified ~= nil then
        self.classified.riderspeedmultiplier:set(multiplier)
    end
end

local _SetMount = Rider_Replica.SetMount
function Rider_Replica:SetMount(mount)
    _SetMount(self, mount)

    if mount and mount.components.locomotor ~= nil then
        self:SetMountSpeedMultiplier(mount.components.locomotor:GetSpeedMultiplier())
    end
end
