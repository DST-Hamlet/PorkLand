local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local PlaySound = nil

AddStategraphPostInit("multiplayer_portal", function(sg)
    local _idle_onenter = sg.states["idle"].onenter
    PlaySound = ToolUtil.GetUpvalue(_idle_onenter, "PlaySound")

    sg.states["funnyidle"].timeline[1].fn = function() end
    sg.states["funnyidle"].timeline[13] = {fn = function(inst) PlaySound(inst, "scratch") end}
    sg.states["funnyidle"].timeline[27] = {fn = function(inst) PlaySound(inst, "scratch") end}
    sg.states["funnyidle"].timeline[41] = {fn = function(inst) PlaySound(inst, "scratch") end}
    sg.states["funnyidle"].timeline[59] = {fn = function(inst) PlaySound(inst, "blink") end}
end)
