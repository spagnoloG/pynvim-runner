-- lua/python-runner/init.lua

local M = {}

function M.open_python_shell()
    vim.cmd('split')
    vim.cmd('resize 15')
    vim.fn.termopen("python")
    vim.cmd('startinsert')
end

function M.run_selection()
    local selection = vim.fn.getline("'<", "'>")
    local shell_buf = vim.fn.bufnr('%')

    for _, line in ipairs(selection) do
        vim.fn.chansend(shell_buf, line .. '\n')
    end
end

function M.setup()
    vim.api.nvim_set_keymap('n', '<leader>ps', ':lua require("python-runner").open_python_shell()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('v', '<leader>pr', ':lua require("python-runner").run_selection()<CR>', { noremap = true, silent = true })
end

return M
