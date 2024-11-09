# pynvim-runner

A simple Neovim plugin to run Python code in a terminal split, enabling you to interact with a Python REPL directly within Neovim. 
Run Neovim in your custom Python environment to have all packages available.


## Installation
Use with packer.nvim:

```lua
use {
    'spagnoloG/pynvim-runner',
    config = function()
        require('pynvim-runner').setup({
            shell_cmd = "python3",  -- Set the shell command to use
            terminal_width = 90,  -- Custom width for terminal window
            auto_scroll = false,  -- Disable auto-scroll
            mappings = {
                open_shell = "<leader>tp",      -- Remap open shell to <leader>tp
                run_selection = "<leader>tr",   -- Remap run selection to <leader>tr
                toggle_terminal = "<leader>tw", -- Remap toggle width to <leader>tw
            }
        })
    end
}
```

## Keybindings

| Mapping       | Action Description                |
|---------------|-----------------------------------|
| `<leader>to`  | Open terminal shell               |
| `<leader>ts`  | Run selected code in visual mode  |
| `<leader>tt`  | Toggle the terminal window        |

## Example usage
![Example usage of pynvim-runner](usage.gif)
