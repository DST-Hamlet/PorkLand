local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

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

AddComponentPostInit("wisecracker", function(cmp)
    cmp.inst:ListenForEvent("boat_damaged", boat_damaged)
    cmp.inst:ListenForEvent("boostbywave", boostbywave)
end)
