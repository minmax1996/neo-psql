local M = {}
local default_config = require('neo-psql.config.default')

-- Store the current configuration
M.current = {}

-- Function to merge two tables
local function merge_tables(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = merge_tables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Function to load configuration
function M.load_config(user_config)
    -- Start with default configuration
    M.current = vim.deepcopy(default_config.default)
    
    -- Merge with user configuration if provided
    if user_config then
        -- If user config has a default table, use that for merging
        if user_config.default then
            M.current = merge_tables(M.current, user_config.default)
        else
            M.current = merge_tables(M.current, user_config)
        end
    end
    
    return M.current
end

-- Function to get current configuration
function M.get_config()
    return M.current
end

-- Function to update configuration
function M.update_config(new_config)
    M.current = merge_tables(M.current, new_config)
    return M.current
end

return M 