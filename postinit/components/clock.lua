local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("clock", function(self, inst)
    self:MakeClock("plateau")
    self:AddMoonPhaseStyle("blood")

    if TheWorld.topology.pl_worldgen_version then
        self:SetClock("plateau")
    end
end)
