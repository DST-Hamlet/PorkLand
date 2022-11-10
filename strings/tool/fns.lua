---@diagnostic disable: lowercase-global

function deepcopy(object)
    local function Func(_object)
        if type(_object) ~= "table" then
            return _object
        end
        local NewTable = {}

        for k, v in pairs(_object) do
            NewTable[Func(k)] = Func(v)
        end

        return setmetatable(NewTable, getmetatable(_object))
    end

    return Func(object)
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

function pairs_string(str)
    local i = 0
    return function()
        i = i + 1
        if i <= #str then
            return i, str:sub(i,i)
        end
    end
end

function split_string(str, tag)
    local _start, _end = str:find(tag)
    if _start and _end then
        return str:sub(_end + 1)
    end
end

function remove_quotes(str)
    if str:sub(1, 1) == "\"" and str:sub(-1, -1) == "\"" then
        str = str:sub(2, -2)
    end

    return str
end

function add_quotes(str)
    if str:sub(1, 1) == "\"" and str:sub(-1, -1) == "\"" then
        return str
    end

    return "\"" .. str .. "\""
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

local function is_array(t)
    if type(t) ~= "table" then
        return false
    end

    if not next(t) then
        return false
    end

    local n = #t
    for i, v in pairs(t) do
        if type(i) ~= "number" then
            return false
        end

        if i > n then
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
			if is_array(target) then
				table.insert(target, v)
			elseif not target[k] or override then
				target[k] = v
			end
		end
	end
end

function get_string(target, new, key)
    new = new or {}
    for k, v in pairs(target) do
        if k == key then
            new[k] = v
        elseif type(v) == "table" then
            local _new = get_string(target[k], nil, key)
            if next(_new) then
                new[k] = _new
            end
        end
    end
    return new
end

function table_to_string(t, indent)
    indent = indent or 1
    local dent = ""
    for i = 1, indent do
        dent = dent .. "\t"
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
            str = str .. dent .. k .. " = " .. value .. "," .. "\n"
        end
    end

    local end_dent = ""
    for i = 1, indent - 1 do
        end_dent = end_dent .. "\t"
    end

    local pack = "{\n" .. str .. end_dent .. "}"
    if indent > 1 then
        pack = pack .. ","
    end

    return pack
end

function table_index_to_str(t, index_str)
    local package = {}
    for k, v in pairs_by_keys(t) do
        local _index_str = index_str  -- don't modify orange index_str
        _index_str = _index_str .. "."  .. k

        if type(v) == "table" then
            local _package = table_index_to_str(v, _index_str)
            merge_table(package, _package)
        else
            package[_index_str] = v
        end
    end

    return package
end

function index_str_to_table(index_str, str)
    index_str = remove_quotes(index_str)
    str = remove_quotes(str)

    local t = {}

    local indexs = {}
    local function get_indexs(s)
        for i, char in pairs_string(s) do
            if char == "." then
                table.insert(indexs, s:sub(1 , i - 1))
                get_indexs(s:sub(i + 1))
                index_str = index_str:sub(i + 1)
                return
            end
        end
    end
    get_indexs(index_str)
    table.insert(indexs, index_str)

    local len = #indexs
    local levels = t
    for i = 1, len - 1 do
        local index = indexs[i]
        if not levels[index] then
            levels[index] = {}
            levels = levels[index]
        end
    end
    levels[indexs[len]] = str
    return t
end

function load_file(file_path)
    local file = io.open(file_path, "r")
    local file_table = {}
    while true do
        local str = file:read()
        if not str then
            file:close()
            return file_table
        end

        table.insert(file_table, str)
    end
end

function load_pofile(file_path, indexs)
    local file_table = load_file(file_path)
    local po_table = {}
    for line, str in ipairs(file_table) do
        local index_str = split_string(str, "msgctxt ")
        if index_str then
            index_str = remove_quotes(index_str)
            if not indexs or indexs[index_str] then
                if index_str then
                    po_table[index_str] = {}
                    local i = 1
                    while true do
                        local _str = file_table[line + i]
                        if _str then
                            local msgid = split_string(_str, "msgid ")
                            if msgid then
                                po_table[index_str].msgid = remove_quotes(msgid)
                            end

                            local msgstr = split_string(_str, "msgstr ")
                            if msgstr then
                                po_table[index_str].msgstr = remove_quotes(msgstr)
                                break
                            end
                        else
                            break
                        end
                        i = i + 1
                    end
                end
            end
        end
    end

    return po_table
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