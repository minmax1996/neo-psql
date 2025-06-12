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

-- Function to run SQL under cursor
function M.run_sql_under_cursor()
    local sql_query = buffer.extract_sql_under_cursor()
    if sql_query == "" then
        print("No SQL found under cursor")
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

-- Function to list available database connections
function M.list_connections()
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
            M.database_schema = schema.fetch_database_schema(selection.name)
            print("Database schema loaded for:", selection.name)
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
vim.api.nvim_create_user_command("RunSQL", M.run_sql_under_cursor, {})
vim.api.nvim_create_user_command("DBSwitch", M.list_connections, {})
vim.api.nvim_create_user_command("DBExplorer", M.database_explorer, {})

return M

