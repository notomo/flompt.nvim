
function! flompt#logger#clear() abort
    let s:logger_func = v:null
endfunction

call flompt#logger#clear()


function! flompt#logger#set_func(func) abort
    let s:logger_func = { message -> a:func(message) }
endfunction

function! flompt#logger#new(...) abort
    if empty(s:logger_func)
        return s:nop_logger()
    endif
    let logger = {
        \ 'func': s:logger_func,
        \ 'labels': a:000,
        \ '_label': join(map(copy(a:000), { _, v -> printf('[%s] ', v) }), ''),
    \ }

    function! logger.label(label) abort
        let labels = copy(self.labels)
        call add(labels, a:label)
        return call('flompt#logger#new', labels)
    endfunction

    function! logger.logs(messages) abort
        for msg in a:messages
            call self.log(msg)
        endfor
    endfunction

    function! logger.log(message) abort
        if type(a:message) == v:t_list || type(a:message) == v:t_dict
            let message = string(a:message)
        else
            let message = a:message
        endif
        call self.func(self._label . message)
    endfunction

    function! logger.buffer_log(bufnr) abort
        let lines = getbufline(a:bufnr, 1, '$')
        call self.logs(lines)
    endfunction

    return logger
endfunction

function! s:nop_logger(...) abort
    let logger = {}

    function! logger.label(label) abort
        return self
    endfunction

    function! logger.logs(messages) abort
    endfunction

    function! logger.log(message) abort
    endfunction

    function! logger.buffer_log(bufnr) abort
    endfunction

    return logger
endfunction
