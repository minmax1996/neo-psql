local M = {}
local parser = require('neo-psql.db.parser')

-- Function to execute SQL query
function M.execute_query(service, query)
    local cmd = string.format("psql service=%s -c \"%s\"", service, query)
    return vim.fn.systemlist(cmd)
end

-- Function to get available services
function M.get_services()
    return parser.parse_toml_service_conf()
end

return M 