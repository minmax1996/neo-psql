local M = {}

-- Function to extract SQL query under cursor
function M.extract_sql_under_cursor()
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

return M 