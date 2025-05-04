# Neo-Psql: A Neovim Plugin for PostgreSQL

Neo-Psql is a Neovim plugin that acts as a wrapper around `psql`, allowing you to execute SQL queries directly from your editor and explore your PostgreSQL database with ease.

## Features

- **Execute SQL Under Cursor**: Run the SQL statement under your cursor and see the results in a horizontal split.
- **Database Explorer**: View all tables in your database and expand them to see columns and data types.
- **Quick Connection Switching**: Easily switch between database connections using `.pgpass` and `.pg_service.conf`.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'minmax1996/neo-psql'
```

Then, add this to your `init.vim`:

```vim
source ~/.nvimrc
call plug#begin('~/.vim/plugged')
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'minmax1996/neo-psql'
call plug#end()
```

## Usage

### Running SQL Queries

Place your cursor inside an SQL statement and run:

```vim
:RunSQL
```

This will execute the SQL statement under your cursor and display the result in a horizontal split.

### Database Explorer

To explore your database tables:

```vim
:DBExplorer
```

Select a table to view its columns and data types.

### Switching Database Connections

To switch between different database connections:

```vim
:DBSwitch
```

This will list all available services from `.pg_service.conf` and allow you to select one.

## Requirements

- Neovim
- telescope.nvim (`Plug 'nvim-telescope/telescope.nvim'`)
- plenary.nvim (`Plug 'nvim-lua/plenary.nvim'`)
- PostgreSQL client (`psql`)
- A configured `.pg_service.conf` file for database connections

## Configuration

### Database Connections

Ensure you have your `.pg_service.conf` properly set up. Example:

```ini
[example]
host=localhost
dbname=mydatabase
user=myuser
```

### Plugin Configuration

The plugin uses default configuration, but you can override it by creating a custom configuration file. To create the default configuration:

```bash
# Create the configuration directory if it doesn't exist
mkdir -p ~/.config/nvim/lua/config

# Download the latest configuration file
wget -O ~/.config/nvim/lua/config/neo-psql.lua https://raw.githubusercontent.com/minmax1996/neo-psql/main/lua/neo-psql/config/default.lua
```

Available configuration options:

- `confirm_execution` (boolean):
  - `true`: Ask for confirmation before executing SQL (default)
  - `false`: Execute SQL immediately


- `extensions.psql.pre_selection` (function):
  - Called before a database is selected
  - Receives a `selection` object with:
    - `name`: Database name
    - `config`: Database configuration (host, port, user, etc.)
  - can be used for unset PGPASSWORD from other connection during 1 session

- `extensions.psql.after_selection` (function):
  - Called after a database is selected
  - Receives a `selection` object with:
    - `name`: Database name
    - `config`: Database configuration (host, port, user, etc.)
  - can be used for set PGPASSWORD from some sort of token-generational tools, for example `aws rds generate-db-auth-token` (see examples dir)

- `extensions.psql.settings` (table):
  - Placeholder for additional settings

The plugin will automatically use this configuration if the file exists. If the file doesn't exist, it will use the default configuration.

## Contributing

Feel free to open issues and submit pull requests to improve the plugin!

## License

GNU General Public v3.0 License