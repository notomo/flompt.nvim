
let s:buf_prompts = {}
let s:source_buf_prompts = {}

function! flompt#prompt#get_or_create() abort
    if &filetype ==? 'flompt'
        return s:buf_prompts[bufnr('%')]
    endif

    let source_bufnr = bufnr('%')
    if has_key(s:source_buf_prompts, source_bufnr)
        return s:source_buf_prompts[source_bufnr]
    endif

    let buffer = flompt#buffer#new(source_bufnr, expand('%:t'))
    let prompt = {
        \ 'buffer': buffer,
        \ 'window': flompt#window#new(buffer.bufnr),
        \ 'logger': flompt#logger#new('prompt'),
    \ }

    function! prompt.open() abort
        call nvim_win_set_cursor(0, [line('$'), 0])
        call self.window.open()
    endfunction

    function! prompt.close() abort
        call self.window.close()
    endfunction

    function! prompt.send() abort
        call self.window.open()
        let cursor_line = self.window.cursor_line()
        call self.buffer.send_line(cursor_line)

        if cursor_line == self.buffer.len()
            call self.buffer.append()
            call self.window.set_cursor(cursor_line + 1)
        endif
    endfunction

    function! prompt.sync() abort
        let cursor_line = self.window.cursor_line()
        call self.buffer.sync_line(cursor_line)
    endfunction

    function! prompt.start_sync() abort
        call self.open()
        let group_name = self._group_name()
        execute 'augroup' group_name
            execute printf('autocmd %s TextChanged <buffer=%s> call s:on_text_changed("%s")', group_name, self.buffer.bufnr, self.buffer.bufnr)
            execute printf('autocmd %s TextChangedI <buffer=%s> call s:on_text_changed("%s")', group_name, self.buffer.bufnr, self.buffer.bufnr)
            execute printf('autocmd %s TextChangedP <buffer=%s> call s:on_text_changed("%s")', group_name, self.buffer.bufnr, self.buffer.bufnr)
        execute 'augroup END'
        call self.sync()
    endfunction

    function! prompt.stop_sync() abort
        let group_name = self._group_name()
        execute printf('autocmd! %s TextChanged', group_name, self.buffer.bufnr)
    endfunction

    function! prompt._group_name() abort
        return 'flompt:' . self.buffer.bufnr
    endfunction

    let s:buf_prompts[buffer.bufnr] = prompt
    execute printf('autocmd BufWipeout <buffer=%s> call s:on_wipe_bufnr("%s")', buffer.bufnr, buffer.bufnr)
    let s:source_buf_prompts[source_bufnr] = prompt
    execute printf('autocmd BufWipeout <buffer=%s> call s:on_wipe_source_bufnr("%s")', source_bufnr, source_bufnr)
    execute printf('autocmd TermClose <buffer=%s> call s:on_term_close("%s")', source_bufnr, buffer.bufnr)

    return prompt
endfunction

function! s:on_wipe_bufnr(bufnr) abort
    if !has_key(s:buf_prompts, a:bufnr)
        return
    endif

    let prompt = s:buf_prompts[a:bufnr]
    if has_key(s:source_buf_prompts, prompt.buffer.source_bufnr)
        call remove(s:source_buf_prompts, prompt.buffer.source_bufnr)
    endif
    call remove(s:buf_prompts, a:bufnr)
endfunction

function! s:on_wipe_source_bufnr(source_bufnr) abort
    if !has_key(s:source_buf_prompts, a:source_bufnr)
        return
    endif
    let prompt = s:source_buf_prompts[a:source_bufnr]
    call remove(s:buf_prompts, prompt.buffer.bufnr)
    call prompt.close()
    call remove(s:source_buf_prompts, a:source_bufnr)
endfunction

function! s:on_term_close(bufnr) abort
    if !has_key(s:buf_prompts, a:bufnr)
        return
    endif
    let prompt = s:buf_prompts[a:bufnr]
    call prompt.close()
    call s:on_wipe_bufnr(a:bufnr)
endfunction

function! s:on_text_changed(bufnr) abort
    if !has_key(s:buf_prompts, a:bufnr)
        return
    endif
    let prompt = s:buf_prompts[a:bufnr]
    call prompt.sync()
endfunction
