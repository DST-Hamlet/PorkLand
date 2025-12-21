local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local WiseCracker = require("components/wisecracker")

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

local function boat_damaged(inst, data)
    inst.components.talker:Say(GetString(inst, data.message))
end

local function boostbywave(inst, data)
    if not inst.last_wave_boost_talk or GetTime() - inst.last_wave_boost_talk > TUNING.SEG_TIME * 3 then
        inst.last_wave_boost_talk = GetTime()
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_WAVE_BOOST"))
    end
end

local function gasdamage(inst, data)
    if not inst.last_in_gas_talk or GetTime() - inst.last_in_gas_talk > 5 then
        inst.last_in_gas_talk = GetTime()
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_GAS_DAMAGE"))
    end
end

local function OnNewDay(inst)
    if TheWorld.components.pigtaxmanager and TheWorld.components.pigtaxmanager:HasPlayerCityHall() and TheWorld.components.pigtaxmanager:IsTaxDay() then
        inst:DoTaskInTime(2, function()
            inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_TAXDAY"))
        end)
    end
end

local function canttrack(inst, data)
    if not inst.last_cant_track_talk or GetTime() - inst.last_cant_track_talk > 4 then
        inst.last_cant_track_talk = GetTime()
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_NOTHING_FOUND"))
    end
end

local function track_close(inst, data)
    inst.components.talker:Say(GetString(inst, "ANNOUNCE_TRACKER_FOUND"))
end

local function track_far(inst, data)
    inst.components.talker:Say(GetString(inst, "ANNOUNCE_TRACKER_FAR"))
end

AddComponentPostInit("wisecracker", function(cmp)
    cmp.inst:ListenForEvent("boat_damaged", boat_damaged)
    cmp.inst:ListenForEvent("boostbywave", boostbywave)
    cmp.inst:ListenForEvent("gasdamage", gasdamage)
    cmp.inst:ListenForEvent("trackitem_far", track_far)
    cmp.inst:ListenForEvent("trackitem_close", track_close)
    cmp.inst:ListenForEvent("canttrackitem", canttrack)
    cmp.inst:WatchWorldState("cycles", OnNewDay)
end)

local _OnUpdate = WiseCracker.OnUpdate
function WiseCracker:OnUpdate(dt)
    return _OnUpdate(self, dt)
end
