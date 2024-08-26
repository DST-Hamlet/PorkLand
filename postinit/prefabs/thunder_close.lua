local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local _ScreenFlash
local function ScreenFlash(self, ...)
    if ThePlayer and not ThePlayer:HasTag("inside_interior") then
        _ScreenFlash(self, ...)
    end
end

local _OnRandDirty
local function OnRandDirty(self, ...)
    if ThePlayer and not ThePlayer:HasTag("inside_interior") then
        _OnRandDirty(self, ...)
    end
end

AddPrefabPostInit("thunder_close", function(inst)
    for per, _ in pairs(inst.pendingtasks) do
        if per.fn ~= inst.Remove and per.period == 0 then --assume there's only the three vanilla tasks
            _ScreenFlash = per.fn
            per.fn = ScreenFlash
            break
        end
    end

    if inst.event_listeners and inst.event_listeners.randdirty and inst.event_listeners.randdirty[inst] then
        _OnRandDirty = inst.event_listeners.randdirty[inst][1]
        inst.event_listeners.randdirty[inst][1] = OnRandDirty
    end
end)
