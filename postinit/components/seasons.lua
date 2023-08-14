local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("seasons", function(self)
    local _world = TheWorld

    self:MakeSeasons("plateau", {
        names = {
            "temperate",
            "humid",
            "lush",
            "aporkalypse",
        },
        segs = {
            temperate = {day = 10, dusk = 4, night = 2},
            humid = {day = 8, dusk = 5, night = 3},
            lush = {day = 8, dusk = 4, night = 4},
            aporkalypse = {day = 0, dusk = 0, night = 16}
        },
        lengths = {
            temperate = TUNING.TEMPERATE_LENGTH,
            humid = TUNING.HUMID_LENGTH,
            lush = TUNING.LUSH_LENGTH,
            aporkalypse = 0  -- change whit start
        }
    })

    if TheWorld.topology.pl_worldgen_version then
        self:SetSeasons("plateau")
    end
end)
