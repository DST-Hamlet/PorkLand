GLOBAL.setfenv(1, GLOBAL)

local Sanity = require("components/sanity")

local LIGHT_DRAIN_STATE =
{
    OUTSIDE = 0,
    INTERIOR = 1,
    HOUSE = 2,
    PLAYERHOUSE = 3,
}

local function GetLightDrainState(inst)
    local position = inst:GetPosition()
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    if not center or not inst:HasTag("inside_interior") then
        return LIGHT_DRAIN_STATE.OUTSIDE
    end

    local interiorID = inst:GetCurrentInteriorID()
    local is_playerhouse = TheWorld.components.interiorspawner:GetInteriorDefinition(interiorID).dungeon_name:find("playerhouse")
    local is_house = FindEntity(center, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"safelight"}, {"INLIMBO"}) ~= nil

    if is_playerhouse then
        return LIGHT_DRAIN_STATE.PLAYERHOUSE
    elseif is_house then
        return LIGHT_DRAIN_STATE.HOUSE
    else
        return LIGHT_DRAIN_STATE.INTERIOR
    end
end

local LIGHT_SANITY_DRAINS = ToolUtil.GetUpvalue(Sanity.Recalc, "LIGHT_SANITY_DRAINS")
local LIGHT_SANITY_DRAINS_INSANITY = shallowcopy(LIGHT_SANITY_DRAINS[SANITY_MODE_INSANITY])

local SANITY_MODE_INSANITY_OVERRIDE = {
    [LIGHT_DRAIN_STATE.OUTSIDE] = LIGHT_SANITY_DRAINS_INSANITY,
    [LIGHT_DRAIN_STATE.INTERIOR] =
    {
        DAY = TUNING.SANITY_DAY_GAIN,
        NIGHT_LIGHT = TUNING.SANITY_NIGHT_LIGHT,
        NIGHT_DIM = TUNING.SANITY_NIGHT_MID,
        NIGHT_DARK = TUNING.SANITY_NIGHT_DARK,
    },

    [LIGHT_DRAIN_STATE.HOUSE] =
    {
        DAY = TUNING.SANITY_HOUSE,
        NIGHT_LIGHT = TUNING.SANITY_HOUSE,
        NIGHT_DIM = TUNING.SANITY_HOUSE,
        NIGHT_DARK = TUNING.SANITY_HOUSE,
    },

    [LIGHT_DRAIN_STATE.PLAYERHOUSE] =
    {
        DAY = TUNING.SANITY_PLAYERHOUSE,
        NIGHT_LIGHT = TUNING.SANITY_PLAYERHOUSE,
        NIGHT_DIM = TUNING.SANITY_PLAYERHOUSE,
        NIGHT_DARK = TUNING.SANITY_PLAYERHOUSE,
    },
}

function Sanity:UpdateInteriorMode()
    local drainstate = GetLightDrainState(self.inst)
    LIGHT_SANITY_DRAINS[SANITY_MODE_INSANITY] = SANITY_MODE_INSANITY_OVERRIDE[drainstate]
    if TheWorld.state.isday and not TheWorld:HasTag("cave") and drainstate == LIGHT_DRAIN_STATE.INTERIOR then
        local lightval = CanEntitySeeInDark(self.inst) and .9 or self.inst.LightWatcher:GetLightValue()
        local light_rate =
            ((lightval > TUNING.SANITY_HIGH_LIGHT and LIGHT_SANITY_DRAINS[SANITY_MODE_INSANITY].NIGHT_LIGHT) or
            (lightval < TUNING.SANITY_LOW_LIGHT and LIGHT_SANITY_DRAINS[SANITY_MODE_INSANITY].NIGHT_DARK) or
            LIGHT_SANITY_DRAINS[SANITY_MODE_INSANITY].NIGHT_DIM) * self.night_drain_mult

        LIGHT_SANITY_DRAINS[SANITY_MODE_INSANITY].DAY = light_rate
    end
end

local _OnUpdate = Sanity.OnUpdate
function Sanity:OnUpdate(dt)
    self:UpdateInteriorMode()
    return _OnUpdate(self, dt)
end
