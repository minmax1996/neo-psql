local M = {}
local binder = require('neo-psql.binder')
local config_manager = require('neo-psql.config.manager')

-- Initialize configuration
config_manager.load_config()

-- Store database schema
M.database_schema = {}

-- Function to extract SQL query under cursor
local function extract_sql_under_cursor()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Find start of the SQL statement
    local start_row = cursor_row
    while start_row > 1 do
        if lines[start_row - 1]:find(";") then
            break
        end
        start_row = start_row - 1
    end
    -- Find end of the SQL statement
    local end_row = cursor_row
    while end_row <= #lines do
        if lines[end_row]:find(";") then
            break
        end
        end_row = end_row + 1
    end

    -- Extract the SQL query, ignoring comments
    local sql_lines = {}
    for i = start_row, end_row do
        local line = lines[i]
        -- Remove comments from the line
        line = line:gsub("%-%-.*", "")
        if line:match("%S") then  -- Ignore empty lines after removing comments
            table.insert(sql_lines, line)
        end
    end

    -- Concat lines to SQL query
    return table.concat(sql_lines, " ")
end

-- Function to show SQL output in a buffer
local function show_sql_output(output, source_bufnr)
    local source_bufname = vim.api.nvim_buf_get_name(source_bufnr)
    local config = config_manager.get_config()
    
    -- Find existing SQL output buffers
    local existing_output_buf = nil
    local last_n = 0

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local bufname = vim.api.nvim_buf_get_name(buf)
        local n = tonumber(bufname:match("%[SQL Output (%d+)%]"))
        if n then
            existing_output_buf = buf
            last_n = math.max(last_n, n)
        end
    end

    if existing_output_buf then
        -- Open a new tab with the source SQL file and a new SQL output buffer
        vim.cmd("tabnew " .. source_bufname)
        vim.cmd("botright new")
    else
        -- Open a horizontal split for the SQL output
        vim.cmd("botright new")
    end

    local buf = vim.api.nvim_get_current_buf()
    local new_bufname = string.format("[SQL Output %d]", last_n + 1)

    -- Set buffer options
    vim.cmd("setlocal buftype=nofile")
    vim.cmd("setlocal bufhidden=wipe")
    
    if vim.fn.bufexists(new_bufname) == 0 then
        vim.api.nvim_buf_set_name(buf, new_bufname)
    end

    -- Insert SQL output into the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.api.nvim_win_set_cursor(0, {1, 0})
end

-- Function to run SQL under cursor
function M.run_sql_under_cursor()
    local sql_query = extract_sql_under_cursor()
    if sql_query == "" then
        print("No SQL found under cursor")
        return
    end

    local config = config_manager.get_config()
    
    -- Create a prompt to ask the user if they want to execute the SQL
    if config.confirm_execution then
        vim.ui.input({
            prompt = sql_query .. '\n' .. "Press Enter to execute the SQL, or Esc to cancel:"
        }, function(input)
            if input then
                -- If Enter is pressed (input is not nil), execute the query
                local output = binder.execute_query(M.current_service, sql_query)
                show_sql_output(output, vim.api.nvim_get_current_buf())
            end
        end)
    else
        -- Execute query directly without confirmation
        local output = binder.execute_query(M.current_service, sql_query)
        show_sql_output(output, vim.api.nvim_get_current_buf())
    end
end

-- Function to list available database connections
function M.list_connections()
    local services = binder.parse_toml_service_conf()
    if not next(services) then
        print("No connections found in .pg_service.conf")
        return
    end

    -- Convert services table to array for telescope
    local service_entries = {}
    for name, config in pairs(services) do
        table.insert(service_entries, {
            name = name,
            config = config
        })
    end

    -- Use telescope for selection
    require('telescope.pickers').new({}, {
        prompt_title = "Select Database Connection",
        finder = require('telescope.finders').new_table({
            results = service_entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.name
                }
            end
        }),
        sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            map('i', '<CR>', function()
                local selection = require('telescope.actions.state').get_selected_entry()
                if selection then
                    M.current_service = selection.value.name
                    print("Switched to service:", selection.value.name)
                    -- Fetch schema in background
                    vim.schedule(function()
                        local config = config_manager.get_config()
                        if config.extensions.psql.after_selection then
                            config.extensions.psql.after_selection(selection.value)
                        end
                        M.database_schema = binder.fetch_database_schema(selection.value.name)
                        print("Database schema loaded for:", selection.value.name)
                    end)
                end
                actions.close(prompt_bufnr)
            end)
            map('i', '<Esc>', function()
                actions.close(prompt_bufnr)
            end)
            return true
        end
    }):find()
end

-- Database Explorer: List tables and allow expansion for columns
function M.database_explorer()
    if not M.database_schema[M.current_service] then
        print("No schema data available. Please select a database connection first.")
        return
    end

    local tables = {}
    for table_name, _ in pairs(M.database_schema[M.current_service]) do
        table.insert(tables, table_name)
    end

    if #tables == 0 then
        print("No tables found")
        return
    end

    require('telescope.pickers').new({}, {
        prompt_title = "Database Explorer",
        finder = require('telescope.finders').new_table({
            results = tables,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                    preview_command = function(entry)
                        local columns = M.database_schema[M.current_service][entry.value]
                        local output = {"=== Table: " .. entry.value .. " ===", ""}
                        for _, column in ipairs(columns) do
                            table.insert(output, string.format("%s (%s)", column.name, column.type))
                        end
                        return table.concat(output, "\n")
                    end
                }
            end
        }),
        sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
        previewer = require('telescope.previewers').new_buffer_previewer({
            define_preview = function(self, entry)
                local columns = M.database_schema[M.current_service][entry.value]
                local output = {"=== Table: " .. entry.value .. " ===", ""}
                for _, column in ipairs(columns) do
                    table.insert(output, string.format("%s (%s)", column.name, column.type))
                end
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, output)
            end
        }),
        attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            map('i', '<CR>', function()
                local selection = require('telescope.actions.state').get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                end
            end)
            map('i', '<Esc>', function()
                actions.close(prompt_bufnr)
            end)
            return true
        end
    }):find()
end

-- Register commands
vim.api.nvim_create_user_command("RunSQL", M.run_sql_under_cursor, {})
vim.api.nvim_create_user_command("DBSwitch", M.list_connections, {})
vim.api.nvim_create_user_command("DBExplorer", M.database_explorer, {})

-- Function to setup the plugin with custom configuration
function M.setup(user_config)
    config_manager.load_config(user_config)
end

return M

