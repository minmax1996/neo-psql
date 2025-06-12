local M = {}

-- Function to show database connection picker
function M.show_connection_picker(services, on_select)
    if not next(services) then
        print("No connections found in .pg_service.conf")
        return
    end

    -- Convert services table to array for telescope
    local service_entries = {}
    for name, config in pairs(services) do
        table.insert(service_entries, {
            name = name,
            config = config
        })
    end

    -- Use telescope for selection
    require('telescope.pickers').new({}, {
        prompt_title = "Select Database Connection",
        finder = require('telescope.finders').new_table({
            results = service_entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.name
                }
            end
        }),
        sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
            local actions = require('telescope.actions')
            map('i', '<CR>', function()
                local selection = require('telescope.actions.state').get_selected_entry()
                if selection then
                    on_select(selection.value)
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