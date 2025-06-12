local M = {}
local default_config = require('neo-psql.config.defaults')
local utils = require('neo-psql.core.utils')

-- Store the current configuration
M.current = {}

-- Function to load configuration
function M.load_config(user_config)
    -- Start with default configuration
    M.current = vim.deepcopy(default_config.default)
    
    -- Merge with user configuration if provided
    if user_config then
        -- If user config has a default table, use that for merging
        if user_config.default then
            M.current = utils.merge_tables(M.current, user_config.default)
        else
            M.current = utils.merge_tables(M.current, user_config)
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
    M.current = utils.merge_tables(M.current, new_config)
    return M.current
end

return M 