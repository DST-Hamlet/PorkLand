local MODROOT = MODROOT
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)
require("translator")

local languages = {
    -- en = "strings.pot",

    -- de = "german",  -- german
    -- es = "spanish",  -- spanish
    -- fr = "french",  -- french
    -- it = "italian",  -- italian
    -- ko = "korean",  -- korean
    -- pt = "portuguese_br",  -- portuguese and brazilian portuguese
    -- br = "portuguese_br",  -- brazilian portuguese
    -- pl = "polish",  -- polish
    -- ru = "russian",  -- russian
    zh = "chinese_s", --Chinese for Steam
    zhr = "chinese_s", --Chinese for WeGame
    ch = "chinese_s", --Chinese mod
    chs = "chinese_s", --Chinese mod
    sc = "chinese_s", --simple Chinese
    zht = "chinese_s", --traditional Chinese for Steam
    tc = "chinese_s", --traditional Chinese
    cht = "chinese_s", --Chinese mod
}

local speech = {
    "generic",
    "willow",
    "wolfgang",
    "wendy",
    "wx78",
    "wickerbottom",
    "woodie",
    -- "wes",
    "waxwell",
    "wathgrithr",
    "webber",
    "winona",
    "wortox",
    "wormwood",
    "warly",
    "wurt",
    "walter",
    "wanda",
}

local newspeech = {
    -- ia character
    "walani",
    -- "wilbur",
    "woodlegs",

    -- pork character
    "wheeler",
    "wilba",
    "wagstaff",
    -- "warbucks"  -- discard
}

local function import(module_name)
    module_name = module_name .. ".lua"
    print("modimport (strings file): " .. MODROOT .. "strings/" .. module_name)
    local result = kleiloadlua(MODROOT .. "strings/" .. module_name)

    if result == nil then
        error("Error in custom import: Stringsfile " .. module_name .. " not found!")
    elseif type(result) == "string" then
        error("Error in custom import: Pork Land importing strings/" .. module_name .. "!\n" .. result)
    else
        setfenv(result, PLENV) -- in case we use mod data
        return result()
    end
end

ToolUtil.MergeTable(STRINGS, import("common"), true)

local IsTheFrontEnd = rawget(_G, "TheFrontEnd") and rawget(_G, "IsInFrontEnd") and IsInFrontEnd()
if not IsTheFrontEnd then
    -- add character speech
    for _, character in pairs(speech) do
        ToolUtil.MergeTable(STRINGS.CHARACTERS[string.upper(character)], import(character))
    end

    for _, character in pairs(newspeech) do
        STRINGS.CHARACTERS[string.upper(character)] = import(character)
    end
end

local desiredlang = LOC.GetLocaleCode()
if (IsTheFrontEnd and not desiredlang) and LanguageTranslator.defaultlang then  -- only use default in FrontEnd or if locale is not set
    desiredlang = LanguageTranslator.defaultlang
end

if desiredlang and languages[desiredlang] then
    print("LOAD PORKLAND LANGUAGE!!!", desiredlang)

    local temp_lang = desiredlang .. "_temp"
    LanguageTranslator:LoadPOFile("scripts/languages/pl_" .. languages[desiredlang] .. ".po", temp_lang)
    ToolUtil.MergeTable(LanguageTranslator.languages[desiredlang], LanguageTranslator.languages[temp_lang])
    TranslateStringTable(STRINGS)
    LanguageTranslator.languages[temp_lang] = nil
    LanguageTranslator.defaultlang = desiredlang
end
