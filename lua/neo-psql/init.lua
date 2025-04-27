local M = {}

-- Store selected database connection
M.current_service = "default"
-- Store database schema
M.database_schema = {}

-- Function to clean up psql output
local function clean_psql_output(output)
    local cleaned = {}
    for _, line in ipairs(output) do
        -- Skip header lines (containing dashes)
        if not line:match("^%-+$") then
            -- Skip empty lines and timing information
            if line ~= "" and not line:match("^Time:") and not line:match("^%(%d+ row") then
                -- Trim whitespace
                local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
                table.insert(cleaned, trimmed)
            end
        end
    end
    return cleaned
end

-- Function to fetch and store database schema
function M.fetch_database_schema(service)
    local tables_cmd = string.format("psql service=%s -c \"SELECT tablename FROM pg_tables WHERE schemaname = 'public';\"", service)
    local tables = clean_psql_output(vim.fn.systemlist(tables_cmd))
    
    M.database_schema[service] = {}
    
    for _, table_name in ipairs(tables) do
        local columns_cmd = string.format(
            "psql service=%s -c \"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '%s';\"",
            service, table_name)
        local columns = clean_psql_output(vim.fn.systemlist(columns_cmd))
        M.database_schema[service][table_name] = columns
    end
end

function M.run_sql_under_cursor()
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
    local sql_query = table.concat(sql_lines, " ")
    if sql_query == "" then
        print("No SQL found under cursor")
        return
    end

    -- Create a prompt to ask the user if they want to execute the SQL
    vim.ui.input({
        prompt = sql_query .. '\n' .. "Press Enter to execute the SQL, or Esc to cancel:"
    }, function(input)
        if input then
            -- If Enter is pressed (input is not nil), execute the query
            M.show_output(string.format("psql service=%s -c \"%s\"", M.current_service, sql_query), bufnr)
        end
    end)
end

function M.show_output(cmd, source_bufnr)
    local output = vim.fn.systemlist(cmd)
    local source_bufname = vim.api.nvim_buf_get_name(source_bufnr)
    
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

-- Function to list available database connections
function M.list_connections()
    local output = vim.fn.systemlist("grep '^\\[.*\\]' ~/.pg_service.conf | tr -d '[]'")
    if #output == 0 then
        print("No connections found in .pg_service.conf")
        return
    end
    -- Use telescope for selection
    require('telescope.pickers').new({}, {
        prompt_title = "Select Database Connection",
        finder = require('telescope.finders').new_table({
            results = output
        }),
        sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            map('i', '<CR>', function()
                local selection = require('telescope.actions.state').get_selected_entry()
                if selection then
                    M.current_service = selection.value
                    print("Switched to service:", selection.value)
                    -- Fetch schema in background
                    vim.schedule(function()
                        M.fetch_database_schema(selection.value)
                        print("Database schema loaded for:", selection.value)
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
                            table.insert(output, column)
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
                    table.insert(output, column)
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

return M

