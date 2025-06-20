local M = {}
local parser = require('neo-psql.db.parser')
local cache = require('neo-psql.core.cache')

-- Function to fetch and store database schema
function M.fetch_database_schema(service, force_load)
    -- Check cache first if not forcing load
    if not force_load then
        local cached_schema = cache.load_schema(service)
        if cached_schema then
            return cached_schema, true
        end
    end

    local tables_cmd = string.format("psql service=%s -A -F, -c \"SELECT tablename FROM pg_tables WHERE schemaname = 'public';\"", service)
    local tables_output = parser.clean_psql_output(vim.fn.systemlist(tables_cmd))
    
    local schema_table = {}
    schema_table[service] = {}
    
    -- Skip header row and process each table
    for i = 3, #tables_output do
        local table_name = tables_output[i]
        local columns_cmd = string.format(
            "psql service=%s -A -F, -c \"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '%s';\"",
            service, table_name)
        local columns_output = parser.clean_psql_output(vim.fn.systemlist(columns_cmd))
        
        local columns = {}
        -- Skip header row and process each column
        for j = 3, #columns_output do
            local row = parser.parse_csv_line(columns_output[j])
            if #row >= 2 then
                table.insert(columns, {name = row[1], type = row[2]})
            end
        end
        schema_table[service][table_name] = columns
    end

    -- Save to cache
    cache.save_schema(service, schema_table)
    return schema_table, false
end

return M 