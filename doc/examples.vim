nnoremap <Leader>f <Cmd>Flompt<CR>

augroup flompt
    autocmd!
    autocmd FileType flompt call s:settings()
augroup END

function! s:settings() abort
    inoremap <buffer> <CR> <Cmd>Flompt send<CR>
    nnoremap <buffer> <CR> <Cmd>Flompt send<CR>
    nnoremap <buffer> q <Cmd>Flompt close<CR>
endfunction
