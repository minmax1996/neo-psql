local M = {}

-- Import modules
local buffer = require('neo-psql.core.buffer')
local config = require('neo-psql.config.init')
local psql = require('neo-psql.db.psql')
local schema = require('neo-psql.db.schema')
local output = require('neo-psql.ui.output')
local explorer = require('neo-psql.ui.explorer')
local telescope = require('neo-psql.ui.telescope')

-- Store database schema
M.database_schema = {}
M.current_service = nil

function M.run_sql(opts) 
    local sql_query
    if opts.range ~= 0 then
        sql_query = buffer.extract_sql_from_range(opts.line1, opts.line2)
    else
        sql_query = buffer.extract_sql_under_cursor()
    end

    if sql_query == "" then
        print("No SQL found")
        return
    end

    local config = config.get_config()
    
    -- Create a prompt to ask the user if they want to execute the SQL
    if config.confirm_execution then
        vim.ui.input({
            prompt = sql_query .. '\n' .. "Press Enter to execute the SQL, or Esc to cancel:"
        }, function(input)
            if input then
                -- If Enter is pressed (input is not nil), execute the query
                local output_lines = psql.execute_query(M.current_service, sql_query)
                output.show_sql_output(output_lines, vim.api.nvim_get_current_buf())
            end
        end)
    else
        -- Execute query directly without confirmation
        local output_lines = psql.execute_query(M.current_service, sql_query)
        output.show_sql_output(output_lines, vim.api.nvim_get_current_buf())
    end
end

-- Function to load schema for current service
function M.load_schema(force)
    if not M.current_service then
        print("No database service selected")
        return
    end
    local loaded_from_cache = false
    M.database_schema, loaded_from_cache = schema.fetch_database_schema(M.current_service, force)
    if loaded_from_cache then
        print("Database schema loaded from cache for:", M.current_service)
    else
        print("Database schema loaded for:", M.current_service)
    end
end

-- Function to list available database connections
function M.list_connections(opts)
    local services = psql.get_services()
    
    telescope.show_connection_picker(services, function(selection)
        local config = config.get_config()
        if config.extensions.psql.pre_selection then
            config.extensions.psql.pre_selection(selection)
        end
        
        M.current_service = selection.name
        print("Switched to service:", selection.name)
        
        if config.extensions.psql.after_selection then
            config.extensions.psql.after_selection(selection)
        end

        -- Fetch schema in background
        vim.schedule(function()
            M.load_schema(opts and opts.load_schema)
        end)
    end)
end

-- Database Explorer: List tables and allow expansion for columns
function M.database_explorer()
    explorer.show_database_explorer(M.database_schema, M.current_service)
end

-- Function to setup the plugin with custom configuration
function M.setup(user_config)
    config.load_config(user_config)
end

-- Register commands
vim.api.nvim_create_user_command("RunSQL", function(opts)
    M.run_sql({range = opts.range, line1 = opts.line1, line2 = opts.line2})
end, { range = true })

vim.api.nvim_create_user_command("DBSwitch", function(opts)
    M.list_connections({load_schema = opts.args == "-load-schema"})
end, { nargs = "?" })

vim.api.nvim_create_user_command("LoadSchema", function(opts)
    M.load_schema(true)
end, {})

vim.api.nvim_create_user_command("DBExplorer", M.database_explorer, {})

return M

