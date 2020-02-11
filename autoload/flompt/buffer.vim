
function! flompt#buffer#new(source_bufnr) abort
    let bufnr = nvim_create_buf(v:false, v:true)
    let buffer = {
        \ 'bufnr': bufnr,
        \ 'source_bufnr': a:source_bufnr,
        \ 'logger': flompt#logger#new('buffer'),
    \ }

    call nvim_buf_set_option(bufnr, 'filetype', 'flompt')
    call nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')

    function! buffer.send_contents(cursor_line) abort
        let job_id = getbufvar(self.source_bufnr, 'terminal_job_id', v:null)
        if empty(job_id)
            return
        endif

        let lines = getbufline(self.bufnr, a:cursor_line) + ['']
        let sent = chansend(job_id, lines)
        if sent == 0
            throw printf('faield to chansend(%s, %s)', job_id, lines)
        endif
    endfunction

    function! buffer.append() abort
        call nvim_buf_set_lines(self.bufnr, -1, -1, v:true, [''])
    endfunction

    function! buffer.len() abort
        return nvim_buf_line_count(self.bufnr)
    endfunction

    return buffer
endfunction
