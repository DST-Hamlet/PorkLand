GLOBAL.setfenv(1, GLOBAL)

local Sleeper = require("components/sleeper")

local _StandardSleepChecks = StandardSleepChecks
function StandardSleepChecks(inst, ...)
    if inst.components.sleeper.onlysleepsfromitems or
        (inst.components.teamattacker and inst.components.teamattacker.teamleader and inst.components.teamattacker.teamleader.threat) then
        return false
    end
    return _StandardSleepChecks(inst, ...)
end

local _StandardWakeChecks = StandardWakeChecks
function StandardWakeChecks(inst, ...)
    if inst.components.sleeper.onlysleepsfromitemsor or
    (inst.components.teamattacker and inst.components.teamattacker.teamleader and inst.components.teamattacker.teamleader.threat) then
        return true
    end
    if inst.components.poisonable ~= nil and inst.components.poisonable:IsPoisoned() then
        return true
    end
    return _StandardWakeChecks(inst, ...)
end

local _SetTest = Sleeper.SetTest
function Sleeper:SetTest(fn, time, ...)
    if self.testtask and self.testtask.fn == fn then
        return
    end

    return _SetTest(self, fn, time, ...)
end
