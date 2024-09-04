GLOBAL.setfenv(1, GLOBAL)

require("bufferedaction")

local _BufferedAction = BufferedAction._ctor
function BufferedAction:_ctor(doer, target, action, invobject, pos, recipe, distance, forced, rotation, ...)
    _BufferedAction(self, doer, target, action, invobject, pos, recipe, distance, forced, rotation, ...)
    if not self.distance and action then
        -- ATTACK action is kind of hacky
        if action == ACTIONS.ATTACK and doer.replica.combat then
            self.distance = doer.replica.combat:GetAttackRangeWithWeapon()
        end
    else
        -- Correct BUILD distance if necessary
        local rec = GetValidRecipe(recipe)
        if rec and rec.aquatic ~= nil then
            if rec.aquatic.distance then
                self.distance = rec.aquatic.distance
            end
            if (rec.aquatic.shore_distance or rec.aquatic.platform_distance) then
                local px, py, pz
                px, py, pz = doer.Transform:GetWorldPosition()
                if px and py and pz then
                    if rec.aquatic.platform_distance and TheWorld.Map:GetPlatformAtPoint(px, py, pz) then
                        self.distance = rec.aquatic.platform_distance
                    elseif rec.aquatic.shore_distance and TheWorld.Map:IsLandTileAtPoint(px, py, pz) then
                        self.distance = rec.aquatic.shore_distance + 0.5 --add 0.5 to account for cornered edges
                    end
                end
            end
        end
    end
end

local CITYALARM_TRIGGER_ACTIONS = {
    [ACTIONS.PAN] = true,
    [ACTIONS.LIGHT] = true,
    [ACTIONS.HARVEST] = true,
    [ACTIONS.PICK] = true,
    [ACTIONS.DIG] = true,
    [ACTIONS.HAMMER] = true,
    [ACTIONS.MINE] = true,
    [ACTIONS.CHOP] = true,
    [ACTIONS.PICKUP] = true,
    [ACTIONS.ATTACK] = true, -- for walls
}

local succeed = BufferedAction.Succeed
function BufferedAction:Succeed(...)
    local ret = { succeed(self, ...) }
    if TheWorld.components.cityalarms
        and self.target
        and self.target.components.citypossession
        and self.target.components.citypossession.enabled
        and self.target.components.citypossession.cityID then

        if CITYALARM_TRIGGER_ACTIONS[self.action] then
            TheWorld.components.cityalarms:TriggerAlarm(self.target.components.citypossession.cityID, self.doer)
            if self.action == ACTIONS.PICKUP then
                self.target.components.citypossession:Disable()
            end
        end
    end
    return unpack(ret)
end
