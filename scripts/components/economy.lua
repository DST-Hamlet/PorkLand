local TRADER = require("prefabs/pig_trades_defs").TRADER

local Economy = Class(function(self, inst)
    self.inst = inst
    self.cities = {}

    self:WatchWorldState("cycles", self.ProcessDelays)
end)

function Economy:OnSave()
    local refs = {}
    local data = {}

    data.cities = self.cities

    for city, data in pairs(self.cities) do
        for traderprefab, traderdata in pairs(data) do
            for guid, delaydata in pairs(traderdata.GUIDS) do
                table.insert(refs, guid)
            end
        end
    end

    return data, refs
end

function Economy:OnLoad(data)
    if data and data.cities then
        self.cities = data.cities
    end
end

function Economy:LoadPostPass(newents, savedata)
    for city, data in pairs(self.cities) do
        for traderprefab, traderdata in pairs(data) do
            local newguids = {}

            for guid, delaydata in pairs(traderdata.GUIDS) do
                local child = newents[guid]
                if child then
                    newguids[child.entity.GUID] = delaydata
                end
            end

            traderdata.GUIDS = newguids
        end
    end
end

function Economy:GetTradeItems(traderprefab)
    return TRADER[traderprefab] and TRADER[traderprefab].items or nil
end

-- This is different from Don't Starve Hamlet, we use thing like "CITY_PIG_BANKER_TRADE" instead of STRINGS.CITY_PIG_BANKER_TRADE
function Economy:GetTradeItemDesc(traderprefab)
    return TRADER[traderprefab] and TRADER[traderprefab].desc or nil
end

function Economy:GetDelay(traderprefab, city, inst)
    return self.cities[city][traderprefab].GUIDS[inst.GUID] or 0
end

-- function Economy:GetNumberWanted(traderprefab,city)
--     return self.cities[city][traderprefab].num - self.cities[city][traderprefab].current
-- end

function Economy:MakeTrade(traderprefab, city, inst)
    self.cities[city][traderprefab].GUIDS[inst.GUID] = TRADER[traderprefab].reset

    return TRADER[traderprefab].reward, TRADER[traderprefab].rewardqty
end

function Economy:ProcessDelays()
    print("Resetting trade delays")

    for c, city in ipairs(self.cities) do
        for i, trader in pairs(city) do
            for guid, data in pairs(trader.GUIDS) do
                if data > 0 then
                    data = data - 1
                    trader.GUIDS[guid] = data
                end
            end
        end
    end
end

function Economy:AddCity(city)
    self.cities[city] = {}

    for trader_prefab in ipairs(TRADER) do
        self.cities[city][trader_prefab] = {
            GUIDS = {},
        }
    end
end

return Economy
