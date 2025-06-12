local M = {}

-- Database Explorer: List tables and allow expansion for columns
function M.show_database_explorer(database_schema, current_service)
    if not database_schema[current_service] then
        print("No schema data available. Please select a database connection first.")
        return
    end

    local tables = {}
    for table_name, _ in pairs(database_schema[current_service]) do
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
                        local columns = database_schema[current_service][entry.value]
                        local output = {"=== Table: " .. entry.value .. " ===", ""}
                        for _, column in ipairs(columns) do
                            table.insert(output, string.format("%s (%s)", column.name, column.type))
                        end
                        return table.concat(output, "\n")
                    end
                }
            end
        }),
        sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
        previewer = require('telescope.previewers').new_buffer_previewer({
            define_preview = function(self, entry)
                local columns = database_schema[current_service][entry.value]
                local output = {"=== Table: " .. entry.value .. " ===", ""}
                for _, column in ipairs(columns) do
                    table.insert(output, string.format("%s (%s)", column.name, column.type))
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

return M 