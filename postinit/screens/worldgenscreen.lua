local modname = modname
GLOBAL.setfenv(1, GLOBAL)

local WorldGenScreen = require("screens/worldgenscreen")

--THANKS FOR HALF

local assets = {
    Asset("ANIM", "anim/generating_hamlet.zip"),

    Asset("SOUND", "sound/DLC003_music_stream.fsb"),
    Asset("SOUND", "sound/DLC003_sfx.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
}

local PL_ASSET_PREFABS = {}

local function PL_WorldGenScreen_RegisterPrefabsResolveAssets(prefab, asset)
    --print(" - - RegisterPrefabsResolveAssets: " .. asset.file, debugstack())
    local resolvedpath = resolvefilepath(asset.file, prefab.force_path_search, prefab.search_asset_first_path)
    assert(resolvedpath, "Could not find "..asset.file.." required by "..prefab.name)
    TheSim:OnAssetPathResolve(asset.file, resolvedpath)
    asset.file = resolvedpath
end

local function PL_WorldGenScreen_LoadAssets(self)
    if PL_ASSET_PREFABS[self] == nil then
        PL_ASSET_PREFABS[self] = Prefab("MOD_WORLDGENSCREEN_LOAD_"..modname, nil, assets, nil)
        for i,asset in ipairs(PL_ASSET_PREFABS[self].assets) do
            if not ShouldIgnoreResolve(asset.file, asset.type) then
                PL_WorldGenScreen_RegisterPrefabsResolveAssets(PL_ASSET_PREFABS[self], asset)
            end
        end

        TheSim:RegisterPrefab(PL_ASSET_PREFABS[self].name, PL_ASSET_PREFABS[self].assets, PL_ASSET_PREFABS[self].deps)
        TheSim:LoadPrefabs({PL_ASSET_PREFABS[self].name})
    end
end

local function PL_WorldGenScreen_UnloadAssets(self)
    if PL_ASSET_PREFABS[self] ~= nil then
        self.worldanim:GetAnimState():SetBuild("generating_forest")
        self.worldanim:GetAnimState():SetBank("generating_forest")
        self.worldanim:GetAnimState():PlayAnimation("idle", true)
        TheFrontEnd:GetSound():KillSound("worldgensound")

        TheSim:UnloadPrefabs({PL_ASSET_PREFABS[self].name})
        TheSim:UnregisterPrefabs({PL_ASSET_PREFABS[self].name})
        PL_ASSET_PREFABS[self] = nil
    end
end

-- HAAACK (HALF): The loadingscreen still exists when this is called, so the game crashes shortly afterwards.
-- So I gotta either unload it here or in self.cb, decided to do it here since it seems safer.
-- 亚丹:worldgenscreen方面的代码均由Half提供, 希望有人能研究一下这些代码的原理
local _UnregisterAllPrefabs = Sim.UnregisterAllPrefabs
function Sim:UnregisterAllPrefabs(...)
    for worldgenscreen, _ in pairs(PL_ASSET_PREFABS) do
        PL_WorldGenScreen_UnloadAssets(worldgenscreen)
        TheFrontEnd:GetSound():OverrideSound("dontstarve/HUD/worldGen", nil)
    end
    return _UnregisterAllPrefabs(self, ...)
end

local __ctor = WorldGenScreen._ctor
function WorldGenScreen:_ctor(profile, cb, world_gen_data, hidden, ...)
    local location = world_gen_data and world_gen_data.level_data and world_gen_data.level_data and world_gen_data.level_data.location or nil

    print("TESTING WORLDGENSCREEN", location)
    if location == nil then -- 一般发生在服务器重置世界时的客机
        location = "porkland"
    end

    if not hidden then
        PL_WorldGenScreen_LoadAssets(self)
        if location == "porkland" or location == nil then
            TheFrontEnd:GetSound():OverrideSound("dontstarve/HUD/worldGen", "dontstarve_DLC003/HUD/worldGen")
        end
    end

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

    local location_data = location and PL_LOCATION_DATA[location] or nil
    if not location_data then return end

    print("LOCATION DATA FOUND")
    dumptable(location_data)

    self.bg:SetTint(unpack(location_data.colour))
    self.worldanim:GetAnimState():SetBuild(location_data.build)
    self.worldanim:GetAnimState():SetBank(location_data.anim)
    self.worldgentext:SetString(location_data.title)

    self.worldanim:GetAnimState():PlayAnimation("idle", true)

    -- self.verbs = shuffleArray(STRINGS.UI.WORLDGEN.VERBS) -- TODO (HALF): Custom verbs yes or no?
    self.nouns = shuffleArray(location_data.nouns)

    self.verbidx = 1
    self.nounidx = 1
    self:ChangeFlavourText()
end

local _OnDestroy = WorldGenScreen.OnDestroy
function WorldGenScreen:OnDestroy(...)
    _OnDestroy(self, ...)
    PL_WorldGenScreen_UnloadAssets(self)
    TheFrontEnd:GetSound():OverrideSound("dontstarve/HUD/worldGen", nil)
end
