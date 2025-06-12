local M = {}

-- Common function to extract SQL from lines
local function extract_sql_from_lines(lines, start_row, end_row)
    -- Extract the SQL query, ignoring comments
    local sql_lines = {}
    for i = start_row, end_row do
        local line = lines[i]
        -- Remove comments from the line and trim whitespace
        line = line:gsub("%-%-.*", ""):match("^%s*(.-)%s*$")
        if line:match("%S") then  -- Ignore empty lines after removing comments
            table.insert(sql_lines, line)
        end
    end

    -- Concat lines to SQL query
    return table.concat(sql_lines, " ")
end

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

    return extract_sql_from_lines(lines, start_row, end_row)
end

-- Function to extract SQL from line range
function M.extract_sql_from_range(start_line, end_line)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    
    -- If end_line is not provided, use start_line
    end_line = end_line or start_line 

    return extract_sql_from_lines(lines, start_line, end_line)
end

-- Placeholder for visual selection (to be implemented)
function M.extract_sql_from_visual_selection()
    -- TODO: Implement visual selection extraction
    return ""
end

return M 