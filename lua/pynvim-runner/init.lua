local M = {}

-- Configuration with terminal control settings
local config = {
    shell_cmd = "python",
    terminal_width = 80,
    auto_scroll = true,
    mappings = {
        open_shell = "<leader>to",
        run_selection = "<leader>ts",
        toggle_terminal = "<leader>tt",
    },
}

-- Track the most recent terminal buffer and job ID
local term_bufnr = nil
local term_job_id = nil

-- Setup function to apply user configuration and key mappings
function M.setup(user_config)
    config = vim.tbl_extend("force", config, user_config or {})
    M.setup_keymaps()
end

-- Configure default key mappings
function M.setup_keymaps()
    for action, mapping in pairs(config.mappings) do
        vim.api.nvim_set_keymap(
            action == "run_selection" and "v" or "n",
            mapping,
            ":lua require('pynvim-runner')." .. action .. "()<CR>",
            { noremap = true, silent = true }
        )
    end
end

-- Open a new Python shell in a split on the right
function M.open_shell()
    M.close_existing_terminals()

    vim.cmd("rightbelow vsplit | terminal " .. config.shell_cmd)
    vim.cmd("vertical resize " .. config.terminal_width)

    -- Identify and save the terminal buffer number and job ID
    local windows = vim.api.nvim_list_wins()
    for _, win in ipairs(windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
            term_bufnr = buf
            term_job_id = vim.b[buf].terminal_job_id
            M.set_terminal_keymaps()
            break
        end
    end
end

-- Close all existing terminal windows
function M.close_existing_terminals()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
            vim.api.nvim_win_close(win, true)
        end
    end
end

function M.send_to_terminal(lines)
    if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) and term_job_id then
        -- Function to check and remove common indentation
        local function remove_common_indentation(lines)
            local min_indent = math.huge
            for _, line in ipairs(lines) do
                if line:find("%S") then  -- Skip empty lines
                    local leading_spaces = line:match("^(%s*)")
                    min_indent = math.min(min_indent, #leading_spaces)
                end
            end

            -- Adjust lines by removing the minimum indentation
            local adjusted_lines = {}
            for _, line in ipairs(lines) do
                table.insert(adjusted_lines, line:sub(min_indent + 1))
            end
            return adjusted_lines
        end

        -- Adjust indentation and wrap in exec() to handle multiline blocks
        local adjusted_lines = remove_common_indentation(lines)
        local code_block = "exec('''\n" .. table.concat(adjusted_lines, "\n") .. "\n''')\n"

        vim.fn.chansend(term_job_id, code_block)
    else
        vim.notify("No active Python shell. Use <leader>to to start a new one.", vim.log.levels.WARN)
    end
end

-- Run selected lines in the Python shell
function M.run_selection()
    local selection = vim.fn.getline("'<", "'>")
    if #selection == 0 then
        vim.notify("No selection detected", vim.log.levels.WARN)
        return
    end
    M.send_to_terminal(selection)
end

-- Toggle terminal width between configured size and 50% of the window width
function M.toggle_terminal()
    if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
        local term_win = vim.fn.bufwinid(term_bufnr)
        if term_win ~= -1 then
            local current_width = vim.api.nvim_win_get_width(term_win)
            local new_width = current_width == config.terminal_width and math.floor(vim.fn.winwidth(0) * 0.5) or config.terminal_width
            vim.api.nvim_win_set_width(term_win, new_width)
            vim.notify("Toggled terminal width to " .. new_width, vim.log.levels.INFO)
        else
            vim.notify("Terminal window not found", vim.log.levels.WARN)
        end
    else
        vim.notify("No active terminal to toggle width. Open it with <leader>to.", vim.log.levels.WARN)
    end
end

-- Set up Esc mapping in terminal to focus back on the code window
function M.set_terminal_keymaps()
    vim.api.nvim_buf_set_keymap(term_bufnr, 't', '<Esc>', [[<C-\><C-n><C-w>p]], { noremap = true, silent = true })
end

return M

