" plugin/python-runner.vim
if exists("g:loaded_python_runner")
    finish
endif
let g:loaded_python_runner = 1
lua require("python-runner").setup()
