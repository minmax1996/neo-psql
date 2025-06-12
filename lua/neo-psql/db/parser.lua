local M = {}

-- Function to parse CSV line
function M.parse_csv_line(line)
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
function M.clean_psql_output(output)
    local cleaned = {}
    for _, line in ipairs(output) do
        -- Skip empty lines and timing information
        if line ~= "" and not line:match("^Time:") and not line:match("^%(%d+ row") then
            table.insert(cleaned, line)
        end
    end
    return cleaned
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