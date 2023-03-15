GLOBAL.setfenv(1, GLOBAL)

function SilenceEvent(event, data, ...)
    return event .. "_silenced", data
end

function EntityScript:AddPushEventPostFn(event, fn, source)
    source = source or self

    if not source.pushevent_postfn then
        source.pushevent_postfn = {}
    end

    source.pushevent_postfn[event] = fn
end

local _PushEvent = EntityScript.PushEvent
if not IA_ENABLED then function EntityScript:PushEvent(event, data, ...)
    local eventfn = self.pushevent_postfn ~= nil and self.pushevent_postfn[event] or nil

    if eventfn ~= nil then
        local newevent, newdata = eventfn(event, data, ...)

        if newevent ~= nil then
            event = newevent
        end
        if newdata ~= nil then
            data = newdata
        end
    end

    _PushEvent(self, event, data, ...)
end end

function EntityScript:GetEventCallbacks(event, source, source_file)
    source = source or self

    assert(self.event_listening[event] and self.event_listening[event][source])

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                return fn
            end
        else
            return fn
        end
    end
end
