-- env
require("fns")
require("input")

local scripts_path = ds_path .. "/data/scripts"
package.path = package.path .. ";../?.lua"
package.path = package.path .. ";" .. scripts_path .. '/?.lua'
POT_GENERATION = true
require("strings")

-- local _require = require
-- function require(...)
--     local results = _require(...)

--     if type(results) ~= "table" then
--         return {}
--     end
--     return results
-- end

local translator = python.eval("lua_translator")

local languages = {
    -- en = "strings.pot",
	de = "german",  -- german
	es = "spanish",  -- spanish
	fr = "french",  -- french
	it = "italian",  -- italian
	ko = "korean",  -- korean
	pt = "portuguese_br",  -- portuguese and brazilian portuguese
	pl = "polish",  -- polish
	ru = "russian",  -- russian
	["zh-CN"] = "chinese_s",  -- chinese
	["zh-TW"] = "chinese_t",  -- traditional chinese
}

local characters = {
    "generic",  -- wilson
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
	"wormwood",
	"warly",
}

local ds_characters = {
	-- sw character
	"walani",
	-- "wilbur",  -- monkey,no speech
	"woodlegs",

	-- pork character
    "wheeler",
    "wilba",
    "wagstaff",
    -- "warbucks"  -- discard
}

local dst_new_character = {
    "winona",
    "wortox",
    "wurt",
    "walter",
    "wanda",
}

for _, character in pairs(ds_characters) do
    table.insert(characters, character)
end

for _, character in pairs(dst_new_character) do
    table.insert(characters, character)
end

local new_strings_language = new_strings.language
new_strings.language = nil

local new_en_strings = {}
local new_index_strs = table_index_to_str(new_strings, "STRINGS")
local new_en_index_strs = {}
if new_strings_language ~= "en" then
    new_en_strings = translate_table(deepcopy(new_strings), function(str) return translator(str, new_strings_language, "en") end)
    new_en_index_strs = table_index_to_str(new_en_strings, "STRINGS")
else
    new_en_strings = new_strings
    new_en_index_strs = new_index_strs
end

local ds_string = get_string(STRINGS, nil, string.upper(string_key))
ds_string.CHARACTERS = ds_string.CHARACTERS or {}
ds_string.CHARACTERS.WARBUCKS = nil

local common = require("common") or {}
merge_table(ds_string, common, not override)
for _, character in pairs(characters) do
    ds_string.CHARACTERS[character:upper()] = ds_string.CHARACTERS[character:upper()] or {}
    merge_table(ds_string.CHARACTERS[character:upper()], require(character) or {}, not override)
end

----- merge po file -----
local en_index_strs = table_index_to_str(ds_string, "STRINGS")
merge_table(en_index_strs, new_en_index_strs, override)

local translates = {}
for l, file_name in pairs(languages) do
    translates[l] = load_pofile(scripts_path .. "/languages/" .. file_name .. ".po", en_index_strs)
    merge_table(translates[l], load_pofile("../../scripts/languages/" .. "pl_" .. file_name .. ".po", en_index_strs), not override)
end

languages["en"] = "strings"
for l, file_name in pairs(languages) do
    local package = ""
    if l == "en" then  -- head
        package = package .. add_quotes("Application: Dont' Starve\\n") .. "\n"
        package = package .. add_quotes("POT Version: 2.0\\n") .. "\n" .. "\n"
    else
        package = package .. "msgid \"\"" .. "\n"
        package = package .. "msgstr \"\"" .. "\n"
        package = package .. add_quotes("Language: " .. l .. "\\n") .. "\n"
        package = package .. add_quotes("Content-Type: text/plain; charset=utf-8\\n") .. "\n"
        package = package .. add_quotes("Content-Transfer-Encoding: 8bit\\n") .. "\n"
        package = package .. add_quotes("POT Version: 2.0") .. "\n" .. "\n"
    end

    for index_str, msgid in pairs_by_keys(en_index_strs) do
        package = package .. "#. " .. index_str  .. "\n"
        package = package .. "msgctxt " .. add_quotes(index_str) .. "\n"
        package = package .. "msgid " .. add_quotes(msgid) .. "\n"

        local msgstr = translates[l] and translates[l][index_str] and translates[l][index_str].msgstr
        local _file_name = "pl_" .. file_name .. ".po"
        if not msgstr or msgid ~= translates[l][index_str].msgid then
            if l == "en" then -- pot
                msgstr = ""
                _file_name = file_name .. ".pot"
            else
                if l == new_strings_language and new_index_strs[index_str] then
                    msgstr = new_index_strs[index_str]
                else
                    print("could not find", index_str, file_name, "use Google Translate")
                    local soure = "en"
                    local strs = msgid
                    if l == "zh-TW" then
                        if translates["zh-CN"][index_str] or new_strings_language == "zh-CN" then
                            soure = "zh-CN"
                            strs = new_index_strs[index_str] or translates["zh-CN"][index_str].msgstr
                        end
                    end
                    msgstr = translator(strs, soure, l)
                end
            end
        end

        package = package .. "msgstr " .. add_quotes(msgstr) .. "\n" .. "\n"

        local pl_file = io.open("../../scripts/languages/" .. _file_name, "w+")
        pl_file:write(package)
        pl_file:close()
    end
end
----- merge po file -----


----- merge lua file -----
merge_table(ds_string, new_en_strings, override)

local CHARACTERS = nil
if ds_string.CHARACTERS and next(ds_string.CHARACTERS) then  -- separate
    CHARACTERS = ds_string.CHARACTERS
    ds_string.CHARACTERS = nil
else
    print("no characters string")
end

local common_file = io.open("../common.lua", "w+")
common_file:write("return " .. table_to_string(ds_string))
common_file:close()

if CHARACTERS then
    for _, character in pairs(characters) do
        local _character = string.upper(character)
        if CHARACTERS[_character] and next(CHARACTERS[_character]) then

            local originals = require(character) or {}
            merge_table(originals, CHARACTERS[_character], override)
            dumptable()

            local file = io.open("../" .. character .. ".lua", "w+")
            file:write("return " .. table_to_string(originals))
            file:close()
            print("success add " .. character .. " " .. string_key .. " string")
        else
            print("Waring! message " .. string_key .. " string in " .. character)
        end
    end
end
----- merge lua file -----
