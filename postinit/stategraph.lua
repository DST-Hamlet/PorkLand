GLOBAL.setfenv(1, GLOBAL)

local _GoToState = StateGraphInstance.GoToState
StateGraphInstance.GoToState = function(self, statename, params, ...)
    self.nextstate = statename
    _GoToState(self, statename, params, ...)
    self.nextstate = nil
end
