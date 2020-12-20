if exists('g:loaded_flompt')
    finish
endif
let g:loaded_flompt = 1

"" Open a floating window for terminal command input.
" ```
" :Flompt " open a window for input
" :Flompt send " send line under the cursor to terminal
" :Flompt close " close the window
" :Flompt sync_start " sync input line to terminal
" :Flompt sync_stop " stop sync
" ```
command! -nargs=? Flompt lua require("flompt/command").main(<f-args>)

if get(g:, 'flompt_debug', v:false)
    augroup flompt_dev
        autocmd!
        execute 'autocmd BufWritePost' expand('<sfile>:p:h:h') .. '/*' 'lua require("flompt/lib/cleanup")()'
    augroup END
endif
