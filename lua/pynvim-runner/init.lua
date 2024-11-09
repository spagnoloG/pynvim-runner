local M = {}

-- Configuration with terminal control settings
local config = {
    shell_cmd = "python",
    terminal_width = 80,
    auto_scroll = true,
    mappings = {
        open_shell = "<leader>ts",
        run_selection = "<leader>tr",
        chain_execute = "<leader>tc",
        send_function = "<leader>tf",
        toggle_terminal = "<leader>tt",
    },
}

-- Track the most recent terminal buffer and job ID
local term_bufnr = nil
local term_job_id = nil

function M.setup(user_config)
    config = vim.tbl_extend("force", config, user_config or {})
    M.setup_keymaps()
end

-- Configure key mappings
function M.setup_keymaps()
    for action, mapping in pairs(config.mappings) do
        if action == "run_selection" then
            vim.api.nvim_set_keymap("v", mapping, ":lua require('pynvim-runner')." .. action .. "()<CR>", { noremap = true, silent = true })
        else
            vim.api.nvim_set_keymap("n", mapping, ":lua require('pynvim-runner')." .. action .. "()<CR>", { noremap = true, silent = true })
        end
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
            break
        end
    end
end

-- Function to close all existing terminal windows
function M.close_existing_terminals()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
            vim.api.nvim_win_close(win, true)  -- Force close all terminal windows
        end
    end
end

function M.send_to_terminal(lines)
    if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) and term_job_id then
        for _, line in ipairs(lines) do
            vim.fn.chansend(term_job_id, line .. "\n")
        end
    else
        vim.notify("No active Python shell. Use <leader>ts to start a new one.", vim.log.levels.WARN)
    end
end

function M.run_selection()
    local selection = vim.fn.getline("'<", "'>")
    if #selection == 0 then
        vim.notify("No selection detected", vim.log.levels.WARN)
        return
    end
    M.send_to_terminal(selection)
end

function M.chain_execute()
    local start_line = vim.fn.search("^$", "bnW")
    local end_line = vim.fn.search("^$", "nW") - 1
    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)

    local chain = {}
    for _, line in ipairs(lines) do
        if line:find("[%.%+%|]$") then
            table.insert(chain, line)
        end
    end

    if #chain > 0 then
        M.send_to_terminal(chain)
    else
        vim.notify("No executable chain found", vim.log.levels.WARN)
    end
end

function M.send_function()
    local ts_utils = require("nvim-treesitter.ts_utils")
    local node = ts_utils.get_node_at_cursor()
    while node do
        if node:type() == "function_definition" then
            local start_row, _, end_row, _ = node:range()
            local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
            M.send_to_terminal(lines)
            return
        end
        node = node:parent()
    end
    vim.notify("No function found at cursor", vim.log.levels.INFO)
end

-- Toggle terminal width between configured size and 50% of the window width
function M.toggle_terminal()
    local current_width = vim.fn.winwidth(0)
    local new_width = current_width == config.terminal_width and math.floor(vim.fn.winwidth(0) * 0.5) or config.terminal_width
    vim.api.nvim_win_set_width(0, new_width)
    vim.notify("Toggled terminal width to " .. new_width, vim.log.levels.INFO)
end

return M

