local AddGlobalClassPostConstruct = AddGlobalClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

require("behaviours/runaway")

AddGlobalClassPostConstruct("behaviours/runaway", "RunAway", function(self)
    if not self.fix_overhang then
        self.fix_overhang = true
    end

    if self.hunternotags == nil then
        self.hunternotags = {"NOCLICK", "FX", "INLIMBO"}
    else
        table.insert(self.hunternotags, "FX")
        table.insert(self.hunternotags, "INLIMBO")
    end
end)
