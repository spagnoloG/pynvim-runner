# pynvim-runner

A simple plugin to run python code in a neovim buffer[WIP].

Use with packer.nvim:

```lua
use {'spagnoloG/pynvim-runner'}
```

## Keybindings

| Mapping       | Action Description                |
|---------------|-----------------------------------|
| `<leader>ts`  | Open terminal shell               |
| `<leader>tr`  | Run selected code in visual mode  |
| `<leader>tc`  | Chain multiple commands to execute|
| `<leader>tf`  | Send function to the terminal     |
| `<leader>tt`  | Toggle the terminal window        |

## Example usage
![Example usage of pynvim-runner](usage.gif)
