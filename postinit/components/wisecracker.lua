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

AddComponentPostInit("wisecracker", function(cmp)
    cmp.inst:ListenForEvent("boat_damaged", boat_damaged)
    cmp.inst:ListenForEvent("boostbywave", boostbywave)
    cmp.inst:ListenForEvent("gasdamage", gasdamage)

    cmp.pl_enterlight_time = math.huge
    cmp.pl_enterdark_time = math.huge
end)

local function GetTimeInDark(self)
    return GetTime() - self.pl_enterdark_time
end

local function GetTimeInLight(self)
    return GetTime() - self.pl_enterlight_time
end

local _OnUpdate = WiseCracker.OnUpdate
function WiseCracker:OnUpdate(dt)
    if not self.inst:HasTag("inside_interior") then
        self.pl_enterdark_time = math.huge
        self.pl_enterlight_time = math.huge
        _OnUpdate(self, dt)
        return
    end

    local night_vision = CanEntitySeeInDark(self.inst)
    if night_vision or self.inst:IsInLight() then
        if self.pl_enterlight_time == math.huge then
            self.pl_enterlight_time = GetTime(self)
            self.pl_enterdark_time = math.huge
        end
        if not self.inlight and (night_vision or GetTimeInLight(self) >= 0.5) then
            self.inlight = true
            if self.inst.components.talker ~= nil and not self.inst:HasTag("playerghost") then
                self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_ENTER_LIGHT"))
            end
        end
    elseif self.inlight and GetTimeInDark(self) >= 0.5 then
        self.inlight = false
        if self.inst.components.talker ~= nil then
            self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_ENTER_DARK"))
        end
    else
        if self.pl_enterdark_time == math.huge then
            self.pl_enterdark_time = GetTime(self)
            self.pl_enterlight_time = math.huge
        end
    end
end
