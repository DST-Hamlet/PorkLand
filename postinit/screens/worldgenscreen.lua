local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local WorldGenScreen = require("screens/worldgenscreen")

local __ctor = WorldGenScreen._ctor
function WorldGenScreen:_ctor(profile, cb, world_gen_data, hidden, ...)
    __ctor(self, profile, cb, world_gen_data, hidden, ...)
    print("GENSCREEN HUH?")
    if hidden then return end

    -- NOTE (HALF) Putting this here to others can override the strings easily
    local PL_LOCATION_DATA = {
        porkland = {
            colour = {87/255,164/255,86/255,1},
            build = "generating_hamlet",
            anim = "generating_hamlet",
            title = STRINGS.UI.WORLDGEN.TITLE,
            sound = "dontstarve_DLC003/HUD/worldGen",
            nouns = STRINGS.UI.WORLDGEN.NOUNS,
        },
    }

    local location = world_gen_data and world_gen_data.level_data and world_gen_data.level_data and world_gen_data.level_data.location or nil
    print("TESTING WORLDGENSCREEN", location)

    local location_data = location and PL_LOCATION_DATA[location] or nil
    if not location_data then return end

    print("LOCATION DATA FOUND")
    dumptable(location_data)

    self.bg:SetTint(unpack(location_data.colour))
    self.worldanim:GetAnimState():SetBuild(location_data.build)
    self.worldanim:GetAnimState():SetBank(location_data.anim)
    self.worldgentext:SetString(location_data.title)

    -- TheFrontEnd:GetSound():KillSound("worldgensound")
    -- TheFrontEnd:GetSound():PlaySound( location_data.sound, "worldgensound" )

    self.worldanim:GetAnimState():PlayAnimation("idle", true)

    -- self.verbs = shuffleArray(STRINGS.UI.WORLDGEN.VERBS) -- TODO (HALF): Custom verbs yes or no?
    self.nouns = shuffleArray(location_data.nouns)

    self.verbidx = 1
    self.nounidx = 1
    self:ChangeFlavourText()
end
