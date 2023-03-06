local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

AddClassPostConstruct("widgets/uiclock", function(self)
    self._moon_builds.blood = "moon_aporkalypse_phases"
end)
