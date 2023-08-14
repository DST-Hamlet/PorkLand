function deepcopy(object)
    local function fn(_object)
        if type(_object) ~= "table" then
            return _object
        end

        local newtable = {}
        for k, v in pairs(_object) do
            newtable[fn(k)] = fn(v)
        end

        return setmetatable(newtable, getmetatable(_object))
    end

    return fn(object)
end

function pairs_by_keys(t)
    local list = {}
    for k in pairs(t) do
        list[#list + 1] = k
    end

    table.sort(list, function(a, b)
        return string.upper(a) < string.upper(b)
    end)

    local i = 0
    return function()
        i = i + 1
        return list[i], t[list[i]]
    end
end

function dumptable(obj, indent, recurse_levels)
    indent = indent or 1
    local i_recurse_levels = recurse_levels or 10
    if obj then
        local dent = ""
        if indent then
            for i = 1, indent do
                dent = dent .. "\t"
            end
        end

        if type(obj) == "string" then
            print(obj)
            return
        end

        for k, v in pairs(obj) do
            if type(v) == "table" and i_recurse_levels > 0 then
                print(dent.."K: ",k)
                dumptable(v, indent + 1, i_recurse_levels - 1)
            else
                print(dent .. "K: ", k, " V: ", v)
            end
        end
    end
end

function is_array(t)
    if type(t) ~= "table" or not next(t) then
        return false
    end

    local n = #t
    for i, v in pairs(t) do
        if type(i) ~= "number" or i <= 0 or i > n then
            return false
        end
    end

    return true
end

function merge_table(target, add_table, override)
    target = target or {}

    for k, v in pairs(add_table) do
        if type(v) == "table" then
            if not target[k] then
                target[k] = {}
            elseif type(target[k]) ~= "table" then
                if override then
                    target[k] = {}
                else
                    error("Can not override" .. k .. " to a table")
                end
            end

            merge_table(target[k], v, override)
        else
            if is_array(target) and not override and target[k] ~= v then
                table.insert(target, v)
            elseif not target[k] or override then
                target[k] = v
            end
        end
    end
end

function get_string(target, key, over_key)
    local new = {}
    over_key = over_key or key
    for k, v in pairs(target) do
        if k == key then
            new[over_key] = v
        elseif type(v) == "table" then
            local _new = get_string(target[k], key, over_key)
            if next(_new) then
                new[k] = _new
            end
        end
    end
    return new
end

function table_to_string(t, indent)
    if not t or not next(t) then
        return "{},"
    end

    indent = indent or 1
    local dent = ""
    for i = 1, indent do
        dent = dent .. "    "
    end

    local str = ""
    for k, v in pairs_by_keys(t) do
        if type(v) == "table" then
            local _str = table_to_string(t[k], indent + 1)
            str = str .. dent .. k .. " = " .. _str .. "\n"
        else
            local value = ""
            if type(v) == "string" then
                value = "\"" .. v .. "\""
            end

            if type(k) == "number" then
                str = str .. dent .. value .. "," .. "\n"
            else
                str = str .. dent .. k .. " = " .. value .. "," .. "\n"
            end
        end
    end

    local end_dent = ""
    for i = 1, indent - 1 do
        end_dent = end_dent .. "    "
    end

    local pack = "{\n" .. str .. end_dent .. "}"
    if indent > 1 then
        pack = pack .. ","
    end

    return pack
end

function table_index_to_str(t, index_str)
    local package = {}
    for k, v in pairs(t) do
        local _index_str = index_str .. "."  .. k  -- don't modify orange index_str

        if type(v) == "table" then
            local _package = table_index_to_str(v, _index_str)
            merge_table(package, _package)
        else
            package["msgctxt \"" .. _index_str .. "\""] = v
        end
    end

    return package
end

function load_pofile(file_path, indexs)
    local file = io.open(file_path, "r")
    if not file then
        file = io.open(file_path, "w")
        file:close()
    end
    file = io.open(file_path, "r")

    local po_table = {}

    local started = false
    local workline = ""
    for line in file:lines() do
        if line:find("msgctxt") and (not indexs or indexs[line]) then
            workline = line
            started = true
        end

        if started then
            if line:find("msgstr") then
                po_table[workline] = line
                started = false
            end
        end
    end

    file:close()

    return po_table
end

function load_ds_string(path)
    local result = loadfile(path .. "common.lua")

    local data_strings = result and result() or {}

    data_strings.CHARACTERS = data_strings.CHARACTERS or {}

    for _, character in ipairs(characters) do
        local _result = loadfile(path .. character .. ".lua")
        if _result then
            data_strings.CHARACTERS[character:upper()] = _result()
        end
    end

    return data_strings
end

function translate_table(t, translate_fn)
    t = t or {}

    for k, v in pairs(t) do
        if type(v) == "table" then
            translate_table(v, translate_fn)
        else
            t[k] = translate_fn(v)
        end
    end

    return t
end

function write_lua_table(path, t)
    local file = io.open(path, "w+")
    file:write("return " .. table_to_string(t))
    file:write("\n")
    file:close()
end
