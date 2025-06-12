local M = {}

-- Function to show SQL output in a buffer
function M.show_sql_output(output, source_bufnr)
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

return M 