local M = {}

-- Default configuration for Python shell integration
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

-- Track the current terminal buffer and job ID for Python shell
local term_bufnr = nil
local term_job_id = nil

--- Setup function to apply user-provided configurations
-- @param user_config table: user-defined configurations to override default settings
function M.setup(user_config)
    config = vim.tbl_extend("force", config, user_config or {})
    M.setup_keymaps()
end

--- Configure key mappings based on config.mappings
function M.setup_keymaps()
    for action, mapping in pairs(config.mappings) do
        local mode = action == "run_selection" and "v" or "n"
        vim.api.nvim_set_keymap(
            mode,
            mapping,
            ":lua require('pynvim-runner')." .. action .. "()<CR>",
            { noremap = true, silent = true }
        )
    end
end

--- Open a new Python shell in a vertical split, resizing to specified width
function M.open_shell()
    M.close_existing_terminals()
    vim.cmd("rightbelow vsplit | terminal " .. config.shell_cmd)
    vim.cmd("vertical resize " .. config.terminal_width)

    -- Identify and save terminal buffer and job IDs
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
            term_bufnr = buf
            term_job_id = vim.b[buf].terminal_job_id
            M.set_terminal_keymaps()
            break
        end
    end
end

--- Close all existing terminal windows
function M.close_existing_terminals()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
            vim.api.nvim_win_close(win, true)
        end
    end
end

--- Send selected lines to the Python terminal, adjusting indentation
-- @param lines table: lines of code to be executed in the terminal
function M.send_to_terminal(lines)
    if not (term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) and term_job_id) then
        vim.notify("No active Python shell. Use <leader>to to start one.", vim.log.levels.WARN)
        return
    end

    -- Remove common indentation from the selected lines
    local function remove_common_indentation(lines)
        local min_indent = math.huge
        for _, line in ipairs(lines) do
            local leading_spaces = line:match("^(%s*)")
            if line:find("%S") then
                min_indent = math.min(min_indent, #leading_spaces)
            end
        end

        local adjusted_lines = {}
        for _, line in ipairs(lines) do
            table.insert(adjusted_lines, line:sub(min_indent + 1))
        end
        return adjusted_lines
    end

    local adjusted_lines = remove_common_indentation(lines)
    local code_block = "exec('''\n" .. table.concat(adjusted_lines, "\n") .. "\n''')\n"
    vim.fn.chansend(term_job_id, code_block)

    -- Scroll terminal window to bottom if auto_scroll is enabled
    if config.auto_scroll then
        local term_win = vim.fn.bufwinid(term_bufnr)
        if term_win ~= -1 then
            vim.api.nvim_win_call(term_win, function()
                vim.cmd("normal! G")
            end)
        end
    end
end

--- Run the currently selected lines in the Python terminal
function M.run_selection()
    local selection = vim.fn.getline("'<", "'>")
    if #selection == 0 then
        vim.notify("No selection detected", vim.log.levels.WARN)
        return
    end
    M.send_to_terminal(selection)
end

--- Toggle the terminal width between default and half of window width
function M.toggle_terminal()
    if not (term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr)) then
        vim.notify("No active terminal to toggle width. Open it with <leader>to.", vim.log.levels.WARN)
        return
    end

    local term_win = vim.fn.bufwinid(term_bufnr)
    if term_win == -1 then
        vim.notify("Terminal window not found", vim.log.levels.WARN)
        return
    end

    local current_width = vim.api.nvim_win_get_width(term_win)
    local new_width = current_width == config.terminal_width and math.floor(vim.fn.winwidth(0) * 0.5) or config.terminal_width
    vim.api.nvim_win_set_width(term_win, new_width)
    vim.notify("Toggled terminal width to " .. new_width, vim.log.levels.INFO)
end

--- Set key mapping in terminal mode for exiting to code window
function M.set_terminal_keymaps()
    vim.api.nvim_buf_set_keymap(term_bufnr, 't', '<Esc>', [[<C-\><C-n><C-w>p]], { noremap = true, silent = true })
end

return M

