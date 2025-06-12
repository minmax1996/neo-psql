local M = {}

-- Default configuration
M.default = {
    -- SQL execution settings
    confirm_execution = true,
    -- Custom extensions
    extensions = {
        psql = {
            ---@type fun(selection: {name: string, config: table}): nil
            ---Executes before a database selection is made
            ---@param selection table The selected database configuration
            ---@param selection.name string The name of the selected database
            ---@param selection.config table The configuration table containing database settings
            pre_selection = nil,
            
            ---@type fun(selection: {name: string, config: table}): nil
            ---Executes after a database selection is made
            ---@param selection table The selected database configuration
            ---@param selection.name string The name of the selected database
            ---@param selection.config table The configuration table containing database settings
            after_selection = nil,
            -- Example implementation:
            -- function(selection)
            --     if selection.config.password then
            --         vim.env.PGPASSWORD = selection.config.password
            --         if vim.fn.has('unix') == 1 then
            --             os.execute(string.format('export PGPASSWORD="%s"', selection.config.password))
            --         end
            --     end
            -- end,
            settings = {}
        }
    }
}

return M 