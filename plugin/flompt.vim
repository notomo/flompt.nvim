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
command! -nargs=? Flompt call flompt#main(<q-args>)
