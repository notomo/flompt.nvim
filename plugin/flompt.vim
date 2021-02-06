if exists('g:loaded_flompt')
    finish
endif
let g:loaded_flompt = 1

"" Open a floating window for terminal command input.
"
" Commands: ~
"  `open` or no: open a window for input
"  `send`: send line under the cursor to terminal
"  `close`: close the window
"  `sync_start`: sync input line to terminal
"  `sync_stop`: stop sync
command! -nargs=? Flompt lua require("flompt/command").main(<f-args>)
