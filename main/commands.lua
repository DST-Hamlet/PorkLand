GLOBAL.setfenv(1, GLOBAL)

function c_gotostate(state)
    local player = ConsoleCommandPlayer()
    if type(state) == "string" then
        player.sg:GoToState(state)
    end
end
