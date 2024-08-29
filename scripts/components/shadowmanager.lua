local SHADE = 0.4
local SHADETIME = 0.3

local ShadowManager = Class(function(self, inst)
    self.inst = inst
    self.shadowed = {}
    self.inst:StartUpdatingComponent(self)
end)

function ShadowManager:PushShadow(inst)
    if inst and inst.AnimState then
        if not inst:HasTag("shadow") then
            if not self.shadowed[inst.GUID] then
                local data1,data2,data3,data4 = inst.AnimState:GetMultColour()

                local r = data1 * SHADE
                local g = data2 * SHADE
                local b = data3 * SHADE

                local rrate = r/SHADETIME
                local grate = g/SHADETIME
                local brate = b/SHADETIME

                self.shadowed[inst.GUID] = {
                    sources = 0,
                    shade = {r = 0, g = 0, b = 0},
                    shadetotal = {r = r, g = g, b = b},
                    shaderate = {r = rrate, g = grate, b = brate}
                }
            end
            self.shadowed[inst.GUID].sources = self.shadowed[inst.GUID].sources + 1
        end
    end
end

function ShadowManager:PopShadow(inst)
    if inst then
        if self.shadowed[inst.GUID] and self.shadowed[inst.GUID].sources > 0 then
            self.shadowed[inst.GUID].sources = self.shadowed[inst.GUID].sources -1
        end
    end
end

local function GetShadeUp(dt,data,rate,shade,total)
    local delta = rate*dt
    delta = math.min(delta, total -shade)
    data = data-delta
    shade = shade + delta
    return data, shade
end

local function GetShadeDown(dt,data,rate,shade,total)
    local delta = rate*dt
    delta = math.min(delta, shade)
    data = data+delta
    shade = shade - delta
    return data, shade
end

function ShadowManager:OnUpdate(dt)
    for GUID, data in pairs(self.shadowed) do
        local inst = Ents[GUID]
        if inst then
            local data1,data2,data3,data4 = inst.AnimState:GetMultColour()
            if data.sources > 0 then -- should increase shade to full				
                if data.shade.r ~= data.shadetotal.r then
                    data1, data.shade.r = GetShadeUp(dt, data1, data.shaderate.r, data.shade.r, data.shadetotal.r)
                end
                if data.shade.g ~= data.shadetotal.g then
                    data2, data.shade.g = GetShadeUp(dt, data2, data.shaderate.g, data.shade.g, data.shadetotal.g)
                end
                if data.shade.b ~= data.shadetotal.b then
                    data3, data.shade.b = GetShadeUp(dt, data3, data.shaderate.b, data.shade.b, data.shadetotal.b)
                end
            else  -- decrease till none				
                if data.shade.r ~= 0 then
                    data1, data.shade.r = GetShadeDown(dt,data1,data.shaderate.r,data.shade.r, data.shadetotal.r)
                end
                if data.shade.g ~= 0 then
                    data2, data.shade.g = GetShadeDown(dt, data2, data.shaderate.g, data.shade.g, data.shadetotal.g)
                end
                if data.shade.b ~= 0 then
                    data3, data.shade.b = GetShadeDown(dt, data3, data.shaderate.b, data.shade.b, data.shadetotal.b)
                end
            end

            inst.AnimState:SetMultColour(data1, data2, data3, data4)
            data1, data2, data3, data4 = inst.AnimState:GetMultColour()

            if data.shade.r == 0 and data.shade.g == 0 and data.shade.b == 0 then
                self.shadowed[GUID] = nil
            end
        else
            self.shadowed[GUID] = nil
        end
    end
end

return ShadowManager
