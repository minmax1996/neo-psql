local neo_psql = require("neo-psql")
local helpers = require("plenary.test_harness")

describe("neo-psql run_sql_under_cursor", function()
    before_each(function()
        -- Setup a new buffer for testing
        vim.cmd("enew")
    end)

    after_each(function()
        -- Cleanup buffers after each test
        vim.cmd("bwipeout!")
    end)

    it("should execute SQL under cursor and show results", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "SELECT 1 + 1 AS result;"
        })
        vim.api.nvim_win_set_cursor(0, {1, 1})
        
        -- Mock system execution to return fake SQL output
        vim.fn.systemlist = function(cmd)
            assert(cmd:match("psql service="))
            return {" result ", "------", " 2 "}
        end

        -- Mock user input (bypass confirmation prompt)
        vim.ui.input = function(_, callback)
            callback("") -- Simulate pressing Enter
        end
        
        neo_psql.run_sql_under_cursor()
        
        -- Verify if the output buffer contains expected result
        local buffers = vim.api.nvim_list_bufs()
        local found = false
        for _, buf in ipairs(buffers) do
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            if vim.tbl_contains(lines, " 2 ") then
                found = true
                break
            end
        end
        assert.is_true(found, "SQL output buffer should contain result")
    end)

    it("should ignore comments while executing SQL", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "-- This is a comment",
            "SELECT 2 + 2 AS result; -- Another comment"
        })
        vim.api.nvim_win_set_cursor(0, {2, 1})
        
        -- Mock system execution to return fake SQL output
        vim.fn.systemlist = function(cmd)
            assert(cmd:match("psql service="))
            return {" result ", "------", " 2 "}
        end

        -- Mock user input (bypass confirmation prompt)
        vim.ui.input = function(_, callback)
            callback("") -- Simulate pressing Enter
        end
        
        neo_psql.run_sql_under_cursor()
        
        -- Verify if the output buffer contains expected result
        local buffers = vim.api.nvim_list_bufs()
        local found = false
        for _, buf in ipairs(buffers) do
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            if vim.tbl_contains(lines, " 2 ") then
                found = true
                break
            end
        end
        assert.is_true(found, "SQL output buffer should contain result")
    end)
end)
