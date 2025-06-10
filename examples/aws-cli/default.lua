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
            pre_selection = function(selection)
                os.execute('unset PGPASSWORD')
            end,

            ---@type fun(selection: {name: string, config: table}): nil
            ---Executes after a database selection is made
            ---@param selection table The selected database configuration
            ---@param selection.name string The name of the selected database
            ---@param selection.config table The configuration table containing database settings
            after_selection = function(selection)
                if string.match(selection.name, "aws%-cli$") then
                    -- Get password from AWS CLI
                    -- TODO handle error
                    local cmd = string.format('aws rds generate-db-auth-token --hostname %s --port %s --region %s --username %s',
                        selection.config.host, selection.config.port or "5432", "us-east-2", selection.config.user)
                    os.execute(string.format('export PGPASSWORD=$(%s)', cmd))
                end
            end,
            settings = {}
        }
    }
}

return M
