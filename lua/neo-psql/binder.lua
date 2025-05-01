local M = {}

-- Function to parse CSV line
local function parse_csv_line(line)
    local result = {}
    local field = ""
    local in_quotes = false
    
    for i = 1, #line do
        local char = line:sub(i, i)
        if char == '"' then
            in_quotes = not in_quotes
        elseif char == ',' and not in_quotes then
            table.insert(result, field)
            field = ""
        else
            field = field .. char
        end
    end
    table.insert(result, field)
    return result
end

-- Function to clean up psql output
local function clean_psql_output(output)
    local cleaned = {}
    for _, line in ipairs(output) do
        -- Skip empty lines and timing information
        if line ~= "" and not line:match("^Time:") and not line:match("^%(%d+ row") then
            table.insert(cleaned, line)
        end
    end
    return cleaned
end

-- Function to fetch and store database schema
function M.fetch_database_schema(service)
    local tables_cmd = string.format("psql service=%s -A -F, -c \"SELECT tablename FROM pg_tables WHERE schemaname = 'public';\"", service)
    local tables_output = clean_psql_output(vim.fn.systemlist(tables_cmd))
    
    local schema_table = {}
    schema_table[service] = {}
    
    -- Skip header row and process each table
    for i = 3, #tables_output do
        local table_name = tables_output[i]
        local columns_cmd = string.format(
            "psql service=%s -A -F, -c \"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '%s';\"",
            service, table_name)
        local columns_output = clean_psql_output(vim.fn.systemlist(columns_cmd))
        
        local columns = {}
        -- Skip header row and process each column
        for j = 3, #columns_output do
            local row = parse_csv_line(columns_output[j])
            if #row >= 2 then
                table.insert(columns, {name = row[1], type = row[2]})
            end
        end
        schema_table[service][table_name] = columns
    end
    return schema_table
end

-- Function to execute SQL query
function M.execute_query(service, query)
    local cmd = string.format("psql service=%s -c \"%s\"", service, query)
    return vim.fn.systemlist(cmd)
end

-- Function to parse TOML format
function M.parse_toml_service_conf()
    local file = io.open(os.getenv("HOME") .. "/.pg_service.conf", "r")
    if not file then
        return {}
    end

    local services = {}
    local current_service = nil

    for line in file:lines() do
        -- Skip comments and empty lines
        if not line:match("^%s*#") and not line:match("^%s*$") then
            -- Check for service section
            local service_name = line:match("^%s*%[(.-)%]%s*$")
            if service_name then
                current_service = service_name
                services[current_service] = {}
            elseif current_service then
                -- Parse key-value pairs
                local key, value = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
                if key and value then
                    services[current_service][key:gsub("^%s*(.-)%s*$", "%1")] = value:gsub("^%s*(.-)%s*$", "%1")
                end
            end
        end
    end

    file:close()
    return services
end

return M 