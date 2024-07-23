local Gridnudger = Class(function(self, inst)
    self.inst = inst
    self.inst:ListenForEvent("onbuilt", function() self:FixPosition() end)
end)

function Gridnudger:OnSave()
    return {no_nudge = true}
end

function Gridnudger:OnLoad(data)
    -- Only on initial load, aka after map generation
    if not (data and data.no_nudge) then
        self:FixPosition()
    end
end

--- Nudge instance to nearest 0.5 grid
--- example:
---     x = 2.8, z = 3.3 -> x = 3.0, z = 3.5
--- copied from prefabs/wall.lua
function Gridnudger:FixPosition()
    local function normalize(coord)
        local temp = coord % 0.5
        coord = coord + 0.5 - temp

        if coord % 1 == 0 then
            coord = coord - 0.5
        end

        return coord
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    x = normalize(x)
    z = normalize(z)
    self.inst.Transform:SetPosition(x, y, z)
end

return Gridnudger
