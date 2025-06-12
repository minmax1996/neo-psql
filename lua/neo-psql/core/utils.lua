local M = {}

-- Function to merge two tables
function M.merge_tables(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = M.merge_tables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Function to check if a string is empty
function M.is_empty(str)
    return str == nil or str == ""
end

-- Function to check if a table is empty
function M.is_table_empty(t)
    return next(t) == nil
end

return M 