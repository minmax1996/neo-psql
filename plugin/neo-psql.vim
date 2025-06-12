" Title:        NeoPsql Plugin
" Description:  A plugin to provide wrapper functionality for psql from neovim 
" Last Change:  31 February 2025
" Maintainer:   Maxim Minaev <https://github.com/minmax1996>

" Prevents the plugin from being loaded multiple times
if exists("g:loaded_neopsql")
    finish
endif
let g:loaded_neopsql = 1

" Load user configuration if it exists
lua << EOF
local user_config_path = vim.fn.expand("~/.config/nvim/lua/config/neo-psql.lua")

if vim.fn.filereadable(user_config_path) == 1 then
    require('neo-psql').setup(require('config.neo-psql'))
else
    require('neo-psql').setup()
end
EOF

" Register commands
command! -nargs=0 RunSQL lua require("neo-psql").run_sql({range = 0})
command! -range RunSQL lua require("neo-psql").run_sql({range = <range>, line1 = <line1>, line2 = <line2>})
command! -nargs=? DBSwitch lua require("neo-psql").list_connections({load_schema = vim.fn.expand("<args>") == "-load-schema"})
command! -nargs=0 LoadSchema lua require("neo-psql").load_schema(true)
command! -nargs=0 DBExplorer lua require("neo-psql").database_explorer()

