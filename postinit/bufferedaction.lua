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
