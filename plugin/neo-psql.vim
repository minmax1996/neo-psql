" Title:        NeoPsql Plugin
" Description:  A plugin to provide wrapper functionality for psql from neovim 
" Last Change:  31 February 2025
" Maintainer:   Maxim Minaev <https://github.com/minmax1996>
" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_neopsql")
    finish
endif
let g:loaded_neopsql = 1

" Defines a package path for Lua. This facilitates importing the
" Lua modules from the plugin's dependency directory.
" let s:lua_rocks_deps_loc =  expand("<sfile>:h:r") . "/../lua/neo-psql/deps"
" exe "lua package.path = package.path .. ';" . s:lua_rocks_deps_loc . "/lua-?/init.lua'"

lua << EOF
local user_config_path = vim.fn.expand("~/.config/nvim/lua/config/neo-psql.lua")

if vim.fn.filereadable(user_config_path) == 1 then
    require('neo-psql').setup(require('config.neo-psql'))
end

EOF

command! -nargs=0 RunSQL lua require("neo-psql").run_sql_under_cursor()
command! -nargs=0 DBSwitch lua require("neo-psql").list_connections()
command! -nargs=0 DBExplorer lua require("neo-psql").database_explorer()

