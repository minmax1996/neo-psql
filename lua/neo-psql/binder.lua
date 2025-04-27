local M = {}

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
    
    local schema_table = {}
    schema_table[service] = {}
    
    for _, table_name in ipairs(tables) do
        local columns_cmd = string.format(
            "psql service=%s -c \"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '%s';\"",
            service, table_name)
        local columns = clean_psql_output(vim.fn.systemlist(columns_cmd))
        schema_table[service][table_name] = columns
    end
    return schema_table
end

-- Function to execute SQL query
function M.execute_query(service, query)
    local cmd = string.format("psql service=%s -c \"%s\"", service, query)
    return vim.fn.systemlist(cmd)
end

return M 