local modname = modname
local GetModConfigData = GetModConfigData
local Levels = require("map/levels")
GLOBAL.setfenv(1, GLOBAL)

local LEVELDATA_FILENAME = "../leveldataoverride.lua"
local WORLDGEN_FILENAME = "../worldgenoverride.lua"
local PORKLAND_PRESET = "PORKLAND_DEFAULT"

local function GetPersistentStringForShard(slot, shard, filename, cb)
    if shard ~= nil then
        TheSim:GetPersistentStringInClusterSlot(slot, shard, filename, cb)
    else
        TheSim:GetPersistentString(filename, cb)
    end
end

local function SetPersistentStringForShard(slot, shard, filename, data, cb)
    if shard ~= nil then
        TheSim:SetPersistentStringInClusterSlot(slot, shard, filename, data, false, cb)
    else
        TheSim:SetPersistentString(filename, data, false, cb)
    end
end

local function HasCustomPorklandLevelSettings(slot, shard, cb)
    GetPersistentStringForShard(slot, shard, LEVELDATA_FILENAME, function(load_success, str)
        if not (load_success and str and #str > 0) then
            cb(false)
            return
        end

        local success, leveldata = RunInSandboxSafe(str)
        if not (success and leveldata and leveldata.location == "porkland" and type(leveldata.overrides) == "table") then
            cb(false)
            return
        end

        local base_level = Levels.GetDataForSettingsID(leveldata.settings_id or leveldata.id)
            or Levels.GetDataForWorldGenID(leveldata.worldgen_id or leveldata.id)
            or Levels.GetDataForLocation(leveldata.location)

        local base_overrides = base_level and base_level.overrides or nil
        for name, value in pairs(leveldata.overrides) do
            local default_value = base_overrides and base_overrides[name] or nil
            if value ~= nil and value ~= "default" and value ~= default_value then
                cb(true)
                return
            end
        end

        cb(false)
    end)
end

-- see shardindex.lua line 528
function ShardIndex:GeneratePorklandWorldGenOverride(slot, shard, has_custom_settings, cb)
    local override_enabled = GetModConfigData("enable_porkland_preset")
    if has_custom_settings then
        print("Skip forcing Porkland preset because custom Porkland level settings already exist")
        if cb ~= nil then
            cb()
        end
        return
    end

    local onload = function(load_success, str)
        if load_success then
            -- this override config is rarely used, we still need to check if the Porkland preset is used
            print("Master Shard already exists " .. WORLDGEN_FILENAME)

            local success, worldgenoverride = RunInSandbox(str)
            if success and worldgenoverride then
                if not override_enabled then
                    print("Force Porkland Preset is disabled")
                else
                    if worldgenoverride.preset ~= PORKLAND_PRESET then
                        worldgenoverride.preset = PORKLAND_PRESET
                    end
                    local data = DataDumper(worldgenoverride, nil, false)
                    local onload = function(success, err)
                        if success then
                            print("Successfully overwrote " .. WORLDGEN_FILENAME .. " to Master Shard")
                        else
                            print("Failed to overwrite " .. WORLDGEN_FILENAME .. " to Master Shard \n Error: " .. tostring(err))
                        end
                        if cb ~= nil then
                            cb()
                        end
                    end

                    SetPersistentStringForShard(slot, shard, WORLDGEN_FILENAME, data, onload)
                end
            else
                if cb ~= nil then
                    cb()
                end
            end
        else
            if not override_enabled then
                print("Force Porkland Preset is disabled")
                if cb ~= nil then
                    cb()
                end
            else
                local data = "return {override_enabled = true, preset = \"" .. PORKLAND_PRESET .. "\",}"
                local onload = function(success, err)
                    if success then
                        print("Successfully wrote " .. WORLDGEN_FILENAME .. " to Master Shard")
                    else
                        print("Failed to write " .. WORLDGEN_FILENAME .. " to Master Shard \n Error: " .. tostring(err))
                    end
                    if cb ~= nil then
                        cb()
                    end
                end

                SetPersistentStringForShard(slot, shard, WORLDGEN_FILENAME, data, onload)
            end
        end
    end

    GetPersistentStringForShard(slot, shard, WORLDGEN_FILENAME, onload)
end

-- AddSimPostInit(function()
--     -- run only in the workshop version
--     local is_workshop_version = modname:find("workshop-")
--     -- run only on dedicated servers and master shard
--     if TheNet:IsDedicated() and not TheShard:IsSecondary() then -- and is_workshop_version Wait for test to be completed
--         ShardGameIndex:GeneratePorklandWorldGenOverride()
--     end
-- end)

-- Sydney: When setting up server shard data, GetLevelDataOverride checks worldgenoverride.lua once.
-- Generating worldgenoverride.lua before this check allows you to force the use of the Porkland preset.

local _SetServerShardData = ShardIndex.SetServerShardData
local GetLevelDataOverride, scope_fn, i = ToolUtil.GetUpvalue(_SetServerShardData, "GetLevelDataOverride")
local _GetLevelDataOverride = function(slot, shard, cb, ...)
    local ret = { GetLevelDataOverride(slot, shard, cb, ...) }
    print("trying Generate Porkland WorldGen Override...")
    local is_workshop_version = modname:find("workshop-")
    -- only running on master shard.
    if not TheNet:GetIsClient() and not TheShard:IsSecondary() then -- and is_workshop_version
        HasCustomPorklandLevelSettings(slot, shard, function(has_custom_settings)
            ShardGameIndex:GeneratePorklandWorldGenOverride(slot, shard, has_custom_settings, function()
                print("Huh? Generate Porkland WorldGen Override done?")
                return unpack(ret)
            end)
        end)
        return
    end
    return unpack(ret)
end

if i then
    debug.setupvalue(scope_fn, i, _GetLevelDataOverride)
end
