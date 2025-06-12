local M = {}
local utils = require('neo-psql.core.utils')
local config = require('neo-psql.config.init')

-- Get cache directory path
local function get_cache_dir()
    local cache_dir = vim.fn.stdpath('cache') .. '/neo-psql'
    if vim.fn.isdirectory(cache_dir) == 0 then
        vim.fn.mkdir(cache_dir, 'p')
    end
    return cache_dir
end

-- Get schema cache file path for a service
local function get_schema_cache_path(service)
    return get_cache_dir() .. '/' .. service .. '_schema.json'
end

-- Check if cache file is valid (not too old)
local function is_cache_valid(cache_path)
    local config = config.get_config()
    local invalidate_days = config.cache.invalidate_after_days
    
    -- If invalidation is disabled (0 days), always consider cache valid
    if invalidate_days == -1 then
        return true
    end
    
    -- Get file modification time
    local file = io.open(cache_path, 'r')
    if not file then
        return false
    end
    file:close()
    
    local file_time = vim.fn.getftime(cache_path)
    local current_time = os.time()
    local max_age = invalidate_days * 24 * 60 * 60 -- convert days to seconds
    
    return (current_time - file_time) <= max_age
end

-- Save schema to cache
function M.save_schema(service, schema)
    local cache_path = get_schema_cache_path(service)
    local file = io.open(cache_path, 'w')
    if file then
        file:write(vim.fn.json_encode(schema))
        file:close()
    end
end

-- Load schema from cache
function M.load_schema(service)
    local cache_path = get_schema_cache_path(service)
    
    -- Check if cache exists and is valid
    if not is_cache_valid(cache_path) then
        -- Remove invalid cache file
        os.remove(cache_path)
        return nil
    end
    
    local file = io.open(cache_path, 'r')
    if file then
        local content = file:read('*all')
        file:close()
        return vim.fn.json_decode(content)
    end
    return nil
end

-- Check if schema cache exists
function M.has_schema_cache(service)
    local cache_path = get_schema_cache_path(service)
    return vim.fn.filereadable(cache_path) == 1 and is_cache_valid(cache_path)
end

return M 