
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
        let cursor_line = self.window.cursor_line()
        call self.buffer.send_contents(cursor_line)

        if cursor_line == self.buffer.len()
            call self.buffer.append()
            call self.window.set_cursor(cursor_line + 1)
        endif
    endfunction

    let s:buf_prompts[buffer.bufnr] = prompt
    execute printf('autocmd BufWipeout <buffer=%s> call s:on_wipe_bufnr("%s")', buffer.bufnr, buffer.bufnr)
    let s:source_buf_prompts[source_bufnr] = prompt
    execute printf('autocmd BufWipeout <buffer=%s> call s:on_wipe_source_bufnr("%s")', source_bufnr, source_bufnr)

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
    call remove(s:buf_prompts, prompt.bufnr)
    call prompt.close()
    call remove(s:source_buf_prompts, a:source_bufnr)
endfunction
