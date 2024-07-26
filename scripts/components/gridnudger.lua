local Gridnudger = Class(function(self, inst)
    self.inst = inst
    -- true to snap to grid, a.k.a. integer position, align with tiles
    -- false to snap to wall's grid, a.k.a. .5 position, align with walls
    self.snap_to_grid = false
    self.inst:ListenForEvent("onbuilt", function() self:Nudge() end)
end)

local function snap_to_grid(coord)
    return math.floor(coord + .5)
end

--- Nudge instance to nearest 0.5 grid
--- example:
---     x = 2.8, z = 3.3 -> x = 3.0, z = 3.5
--- copied from prefabs/wall.lua
local function snap_to_wall_grid(coord)
    local temp = coord % 0.5
    coord = coord + 0.5 - temp

    if coord % 1 == 0 then
        coord = coord - 0.5
    end

    return coord
end

function Gridnudger:Nudge()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if self.snap_to_grid then
        x = snap_to_grid(x)
        z = snap_to_grid(z)
    else
        x = snap_to_wall_grid(x)
        z = snap_to_wall_grid(z)
    end
    self.inst.Transform:SetPosition(x, y, z)
end

return Gridnudger
