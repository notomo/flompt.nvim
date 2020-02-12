
function! flompt#buffer#new(source_bufnr, source_cmd) abort
    let bufnr = nvim_create_buf(v:false, v:true)
    let buffer = {
        \ 'bufnr': bufnr,
        \ 'source_bufnr': a:source_bufnr,
        \ 'source_cmd': a:source_cmd,
        \ 'logger': flompt#logger#new('buffer'),
    \ }

    call nvim_buf_set_option(bufnr, 'filetype', 'flompt')
    call nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')

    function! buffer.send_line(cursor_line) abort
        let line = ["\<C-u>" . getbufline(self.bufnr, a:cursor_line)[0]] + self._new_line()
        call self._send(line)
    endfunction

    function! buffer.sync_line(cursor_line) abort
        let line = "\<C-u>" . getbufline(self.bufnr, a:cursor_line)[0]
        call self._send(line)
    endfunction

    function! buffer._send(data) abort
        let id = nvim_buf_get_option(self.source_bufnr, 'channel')
        if empty(id)
            return
        endif

        let running = jobwait([id], 0)[0] == -1
        if !running
            return
        endif

        call chansend(id, a:data)
    endfunction

    function! buffer._new_line() abort
        if self.source_cmd ==? 'cmd.exe'
            return ["\r"]
        endif
        return ['']
    endfunction

    function! buffer.append() abort
        call nvim_buf_set_lines(self.bufnr, -1, -1, v:true, [''])
    endfunction

    function! buffer.len() abort
        return nvim_buf_line_count(self.bufnr)
    endfunction

    return buffer
endfunction
