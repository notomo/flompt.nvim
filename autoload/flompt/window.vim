
function! flompt#window#new(bufnr) abort
    let window = {
        \ 'id': v:null,
        \ 'bufnr': a:bufnr,
    \ }

    function! window.open() abort
        if !empty(self.id) && nvim_win_is_valid(self.id)
            call nvim_set_current_win(self.id)
            return
        endif

        let column = &columns / 2
        let self.id = nvim_open_win(self.bufnr, v:true, {
            \ 'relative': 'editor',
            \ 'width': &columns / 2 - 3,
            \ 'height': 20,
            \ 'row': 3,
            \ 'col': column,
            \ 'anchor': 'NW',
            \ 'focusable': v:true,
            \ 'external': v:false,
        \ })
    endfunction

    function! window.close() abort
        if empty(self.id) || !nvim_win_is_valid(self.id)
            return
        endif
        call nvim_win_close(self.id, v:true)
    endfunction

    function! window.set_cursor(line_number) abort
        if empty(self.id) || !nvim_win_is_valid(self.id)
            return
        endif
        call nvim_win_set_cursor(self.id, [a:line_number, 0])
    endfunction

    function! window.cursor_line() abort
        let pos = nvim_win_get_cursor(self.id)
        return pos[0]
    endfunction

    return window
endfunction
